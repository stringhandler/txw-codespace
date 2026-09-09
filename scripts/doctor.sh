#!/usr/bin/env bash
#
# Report where asdf, the tx-manifest-wallet shim and txw actually live, for the
# current user and for root. `txw: not found` in one shell while
# post-create.sh reports success in another usually means the two ran as
# different users, with a different $HOME and therefore a different
# ASDF_DATA_DIR.
#
#   ./scripts/doctor.sh

set -uo pipefail

hr() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

hr "identity"
printf 'whoami            %s\n' "$(whoami)"
printf 'HOME              %s\n' "${HOME:-<unset>}"
printf 'ASDF_DATA_DIR     %s\n' "${ASDF_DATA_DIR:-<unset>}"
printf 'shell             %s\n' "${SHELL:-<unset>}"

hr "PATH"
printf '%s\n' "${PATH//:/$'\n'}"

hr "binaries on PATH"
for cmd in asdf txw tx-manifest-wallet; do
	printf '%-20s %s\n' "$cmd" "$(command -v "$cmd" 2>/dev/null || echo '<not found>')"
done

hr "asdf data dirs that exist"
for d in "${ASDF_DATA_DIR:-}" "$HOME/.asdf" /root/.asdf /home/vscode/.asdf /home/codespace/.asdf; do
	[ -n "$d" ] || continue
	if [ -d "$d" ]; then
		printf '%s\n' "$d"
		printf '  shim:      %s\n' \
			"$([ -e "$d/shims/tx-manifest-wallet" ] && echo present || echo MISSING)"
		printf '  installs:  %s\n' \
			"$(ls "$d/installs/tx-manifest-wallet" 2>/dev/null | tr '\n' ' ' || echo none)"
		printf '  owner:     %s\n' "$(stat -c '%U:%G %a' "$d" 2>/dev/null)"
	else
		printf '%s  <absent>\n' "$d"
	fi
done

hr "root's view (via sudo)"
if sudo -n true 2>/dev/null; then
	sudo -n bash -c 'echo "root HOME=$HOME"; ls -d /root/.asdf 2>/dev/null || echo "no /root/.asdf"'
else
	echo "passwordless sudo unavailable; skipped"
fi

hr "asdf state for this user"
asdf current tx-manifest-wallet 2>&1 || true
asdf list tx-manifest-wallet 2>&1 || true

hr "txw wrapper contents"
if w="$(command -v txw 2>/dev/null)"; then
	printf '%s:\n' "$w"
	cat "$w"
else
	echo "txw not on PATH"
fi

hr "smoke test: validate examples/p2pk"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${repo_root}/examples/p2pk/txmanifest.json"
if ! command -v txw >/dev/null 2>&1; then
	echo "txw not on PATH; skipped"
elif [ ! -f "$manifest" ]; then
	printf '%s missing; skipped\n' "$manifest"
elif out="$(cd "$(dirname "$manifest")" && txw validate ./txmanifest.json 2>&1)"; then
	echo "OK — the installed wallet validates the vendored manifest"
	[ -n "$out" ] && printf '%s\n' "$out"
else
	echo "FAILED — txw validate exited non-zero:"
	printf '%s\n' "$out"
	echo
	echo "If the wallet itself is fine, the vendored copy may be stale for this"
	echo "release; compare against ./scripts/fetch-examples.sh output."
fi
