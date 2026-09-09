#!/usr/bin/env bash
#
# Provision the codespace: install asdf, add the tx-manifest-wallet plugin, and
# install the version pinned in .tool-versions.
#
# Nothing about the wallet itself is baked into the container image, so the
# version can be changed later with `asdf install`/`asdf set` (or
# scripts/set-wallet-version.sh) without rebuilding the codespace.

set -euo pipefail

# Keep a transcript of every run. The Codespaces creation log closes itself and
# a failed re-run scrolls away, so the output has to survive somewhere it can be
# opened afterwards. Re-exec once through `tee` rather than
# `exec > >(tee ...)`, which can drop the tail of the output when the script
# exits before tee has flushed.
LOG_FILE="${POST_CREATE_LOG:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/post-create.log}"
if [ -z "${POST_CREATE_LOGGING:-}" ]; then
	export POST_CREATE_LOGGING=1
	printf 'Logging this run to %s\n' "$LOG_FILE"

	# The pipeline's failure is handled below, so don't let `set -e` pre-empt
	# reading PIPESTATUS.
	set +e
	bash "${BASH_SOURCE[0]}" "$@" 2>&1 | tee "$LOG_FILE"
	status="${PIPESTATUS[0]}"
	set -e

	[ "$status" -eq 0 ] || printf '\nFull log: %s\n' "$LOG_FILE" >&2
	exit "$status"
fi

# Codespaces runs this in the creation log, which is easy to miss: a failure
# here leaves a container that looks fine until `txw` says "not found". Make it
# loud, and say how to get the same output back.
on_error() {
	local code=$? line=$1
	printf '\n\033[1;31m==> PROVISIONING FAILED\033[0m (exit %s at %s:%s)\n' \
		"$code" "$(basename "${BASH_SOURCE[0]}")" "$line" >&2
	printf 'tx-manifest-wallet is probably not installed. Re-run to retry:\n\n' >&2
	printf '    bash .devcontainer/post-create.sh\n\n' >&2
	exit "$code"
}
trap 'on_error $LINENO' ERR

ASDF_VERSION="${ASDF_VERSION:-0.20.0}"
PLUGIN_NAME="tx-manifest-wallet"
PLUGIN_REPO="${PLUGIN_REPO:-https://github.com/stringhandler/asdf-tx-manifest-wallet.git}"

# devcontainer.json exports ASDF_DATA_DIR, so an inherited value normally wins.
# Don't trust it blindly: a variable substitution there that expands to the
# empty string leaves a root-owned path like /.asdf, and provisioning then dies
# halfway through on "Permission denied". Fall back to the per-user default
# whenever the inherited path is not one this user could actually create.
asdf_data_dir_usable() {
	local dir="$1"
	[ -n "$dir" ] || return 1
	# Walk up to the nearest ancestor that exists; anything below it is just a
	# `mkdir -p` away.
	while [ ! -e "$dir" ] && [ "$dir" != "/" ] && [ "$dir" != "." ]; do
		dir="$(dirname "$dir")"
	done
	[ -d "$dir" ] && [ -w "$dir" ]
}

if ! asdf_data_dir_usable "${ASDF_DATA_DIR:-}"; then
	[ -z "${ASDF_DATA_DIR:-}" ] || printf \
		'\n\033[1;33m==>\033[0m Ignoring unusable ASDF_DATA_DIR=%s (using %s)\n' \
		"$ASDF_DATA_DIR" "$HOME/.asdf" >&2
	ASDF_DATA_DIR="$HOME/.asdf"
fi
export ASDF_DATA_DIR

SHIMS_DIR="${ASDF_DATA_DIR}/shims"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }

# --- asdf itself ------------------------------------------------------------

install_asdf() {
	local arch asset url tmp
	case "$(uname -m)" in
	x86_64 | amd64) arch="amd64" ;;
	aarch64 | arm64) arch="arm64" ;;
	*)
		echo "Unsupported architecture: $(uname -m)" >&2
		exit 1
		;;
	esac

	asset="asdf-v${ASDF_VERSION}-linux-${arch}.tar.gz"
	url="https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/${asset}"

	log "Installing asdf ${ASDF_VERSION} (${arch})"
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' RETURN

	curl -fsSL "$url" -o "${tmp}/${asset}"
	tar -xzf "${tmp}/${asset}" -C "$tmp"

	if [ -w /usr/local/bin ] || sudo -n true 2>/dev/null; then
		sudo install -m 0755 "${tmp}/asdf" /usr/local/bin/asdf
	else
		mkdir -p "$HOME/.local/bin"
		install -m 0755 "${tmp}/asdf" "$HOME/.local/bin/asdf"
	fi
}

# Look in both possible install locations before deciding to re-download, so a
# re-run of this script (or a container restart) is a no-op.
export PATH="$HOME/.local/bin:${SHIMS_DIR}:${PATH}"

if command -v asdf >/dev/null 2>&1 &&
	[ "$(asdf version 2>/dev/null | sed 's/^v//;s/ .*//')" = "$ASDF_VERSION" ]; then
	log "asdf ${ASDF_VERSION} already installed"
else
	install_asdf
fi

# --- shell integration ------------------------------------------------------

# asdf 0.16+ needs no `source` line — only ASDF_DATA_DIR and the shims on PATH.
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
	[ -f "$rc" ] || continue
	grep -q '# >>> asdf (tx-manifest-wallet codespace)' "$rc" && continue
	cat >>"$rc" <<-RC

		# >>> asdf (tx-manifest-wallet codespace)
		export ASDF_DATA_DIR="\$HOME/.asdf"
		export PATH="\$HOME/.local/bin:\$ASDF_DATA_DIR/shims:\$PATH"
		# <<< asdf (tx-manifest-wallet codespace)
	RC
	log "Added asdf to $(basename "$rc")"
done

# --- txw alias --------------------------------------------------------------

# A wrapper script rather than a shell alias, so `txw` also works in
# non-interactive shells, VS Code tasks and scripts. It resolves the shim at
# call time, so switching versions with asdf needs no change here.
install_txw() {
	local tmp
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' RETURN

	cat >"${tmp}/txw" <<-'WRAPPER'
		#!/usr/bin/env bash
		# Short alias for tx-manifest-wallet (see .devcontainer/post-create.sh).
		# Same guard as post-create.sh above: an ASDF_DATA_DIR inherited from a
		# bad devcontainer.json substitution points somewhere that does not exist.
		[ -d "${ASDF_DATA_DIR:-}/shims" ] || ASDF_DATA_DIR="$HOME/.asdf"
		export ASDF_DATA_DIR
		export PATH="$HOME/.local/bin:${ASDF_DATA_DIR}/shims:${PATH}"

		# `exec` on a missing shim gives a bare "not found" that says nothing
		# about why. The wrapper is installed before the wallet, so this fires
		# both while provisioning is still running and after it has failed.
		if ! command -v tx-manifest-wallet >/dev/null 2>&1; then
			echo "txw: tx-manifest-wallet is not installed." >&2
			echo >&2
			echo "The container's provisioning step is still running or it failed." >&2
			echo "Re-run it (it is idempotent) to install the wallet and see any error:" >&2
			echo >&2
			echo "    bash .devcontainer/post-create.sh" >&2
			echo >&2
			exit 127
		fi

		exec tx-manifest-wallet "$@"
	WRAPPER

	if [ -w /usr/local/bin ] || sudo -n true 2>/dev/null; then
		sudo install -m 0755 "${tmp}/txw" /usr/local/bin/txw
	else
		mkdir -p "$HOME/.local/bin"
		install -m 0755 "${tmp}/txw" "$HOME/.local/bin/txw"
	fi
}

log "Installing txw alias for tx-manifest-wallet"
install_txw

# --- plugin + tool ----------------------------------------------------------

if asdf plugin list 2>/dev/null | grep -qx "$PLUGIN_NAME"; then
	log "Updating asdf plugin ${PLUGIN_NAME}"
	asdf plugin update "$PLUGIN_NAME" || true
else
	log "Adding asdf plugin ${PLUGIN_NAME}"
	asdf plugin add "$PLUGIN_NAME" "$PLUGIN_REPO"
fi

log "Installing $(cat .tool-versions)"
asdf install
asdf reshim "$PLUGIN_NAME" || true

# --- verify -----------------------------------------------------------------

log "Installed version"
asdf current "$PLUGIN_NAME" || true

# `asdf install` can report success while leaving no shim behind (a plugin that
# installed to an unexpected path, an interrupted reshim). Check for the shim
# explicitly so the failure names itself here rather than surfacing later as
# `txw: tx-manifest-wallet: not found`.
if [ ! -x "${SHIMS_DIR}/tx-manifest-wallet" ]; then
	echo "No shim at ${SHIMS_DIR}/tx-manifest-wallet after 'asdf install'." >&2
	echo "Installed versions:" >&2
	asdf list "$PLUGIN_NAME" >&2 || true
	exit 1
fi

if ! "${SHIMS_DIR}/tx-manifest-wallet" --version 2>/dev/null; then
	"${SHIMS_DIR}/tx-manifest-wallet" --help | head -5
fi

command -v txw >/dev/null 2>&1 && log "txw alias -> $(command -v txw)"

cat <<'DONE'

Ready. tx-manifest-wallet is managed by asdf.

  txw --help                                # run it (alias for tx-manifest-wallet)
  asdf list all tx-manifest-wallet          # available versions
  ./scripts/set-wallet-version.sh 0.1.2     # switch version (no rebuild needed)

DONE
