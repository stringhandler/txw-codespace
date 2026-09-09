#!/usr/bin/env bash
#
# Switch the tx-manifest-wallet version used in this codespace.
#
#   ./scripts/set-wallet-version.sh 0.1.2     # a specific release
#   ./scripts/set-wallet-version.sh latest    # newest stable release
#
# Installs the version if needed, pins it in .tool-versions, and reshims.
# No container rebuild required.

set -euo pipefail

TOOL="tx-manifest-wallet"

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
export PATH="$HOME/.local/bin:${ASDF_DATA_DIR}/shims:${PATH}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ $# -ne 1 ]; then
	echo "usage: $(basename "$0") <version|latest>" >&2
	echo >&2
	echo "available versions:" >&2
	asdf list all "$TOOL" >&2
	exit 2
fi

version="$1"

command -v asdf >/dev/null 2>&1 || {
	echo "asdf is not on PATH. Open a new terminal, or re-run .devcontainer/post-create.sh" >&2
	exit 1
}

if [ "$version" = "latest" ]; then
	version="$(asdf latest "$TOOL")"
	echo "latest stable is ${version}"
fi

# Refresh the plugin so newly published releases show up.
asdf plugin update "$TOOL" >/dev/null 2>&1 || true

asdf install "$TOOL" "$version"
asdf set "$TOOL" "$version"
asdf reshim "$TOOL" || true

echo
asdf current "$TOOL"
tx-manifest-wallet --version 2>/dev/null || tx-manifest-wallet --help | head -3
