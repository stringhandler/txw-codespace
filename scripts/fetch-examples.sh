#!/usr/bin/env bash
#
# Pull the tx-manifest-wallet example manifests into work/txmanifest-wallet/.
#
#   ./scripts/fetch-examples.sh          # clone, or update an existing copy
#
# The examples live upstream, not in this repo, so they never drift from the
# manifest format the installed wallet actually speaks. They land under work/,
# which is gitignored, so nothing here gets committed back.
#
# The upstream layout (examples/ next to schema/) is preserved on purpose: the
# manifests reference ../../schema/txmanifest.schema.json relative to
# themselves, and that only resolves if both directories come along.
#
# This is a blobless, sparse clone — a few hundred KB, not the whole history.

set -euo pipefail

REPO="https://github.com/stringhandler/txmanifest-wallet.git"
SPARSE_PATHS=(examples schema)

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="${repo_root}/work/txmanifest-wallet"

command -v git >/dev/null 2>&1 || { echo "git is not on PATH" >&2; exit 1; }

if [ -d "${dest}/.git" ]; then
	echo "updating ${dest}"
	git -C "$dest" sparse-checkout set "${SPARSE_PATHS[@]}"
	git -C "$dest" pull --ff-only
else
	echo "cloning ${REPO} into ${dest}"
	mkdir -p "$(dirname "$dest")"
	git clone --depth 1 --filter=blob:none --sparse "$REPO" "$dest"
	git -C "$dest" sparse-checkout set "${SPARSE_PATHS[@]}"
fi

echo
echo "examples in ${dest#"${repo_root}/"}/examples:"
ls -1 "${dest}/examples"

cat <<TIP

Try one:
  txw describe work/txmanifest-wallet/examples/p2pk/txmanifest.json
  txw validate work/txmanifest-wallet/examples/p2pk/txmanifest.json
TIP
