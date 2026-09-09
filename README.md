# txmanifest-codespace

A [dev container](https://containers.dev) / GitHub Codespace that comes with the
[`tx-manifest-wallet`](https://github.com/stringhandler/txmanifest-wallet) CLI
installed — nothing else. The wallet is managed by
[asdf](https://asdf-vm.com) via the
[`asdf-tx-manifest-wallet`](https://github.com/stringhandler/asdf-tx-manifest-wallet)
plugin, so **the version can be upgraded or downgraded inside a running
codespace without rebuilding it**.

## What's in the container

| Piece | Where it comes from |
|-------|---------------------|
| Base image | `mcr.microsoft.com/devcontainers/base:ubuntu-24.04` (matches the glibc of the published Linux release binaries) |
| `asdf` | Pinned Go binary, installed by [.devcontainer/post-create.sh](.devcontainer/post-create.sh) into `/usr/local/bin` |
| `tx-manifest-wallet` | asdf plugin, prebuilt release binary from GitHub — version pinned in [.tool-versions](.tool-versions) |
| `txw` | Wrapper script in `/usr/local/bin`, installed by [.devcontainer/post-create.sh](.devcontainer/post-create.sh) |
| `gh` | devcontainer feature |

The wallet is **not** baked into the image. `postCreateCommand` installs asdf,
adds the plugin, and runs `asdf install`, which reads `.tool-versions`. That is
the only place the version is declared.

## Usage

`txw` is a shorthand for `tx-manifest-wallet` — the two are interchangeable
everywhere. It's a wrapper script, not a shell alias, so it also works from
scripts, VS Code tasks and `bash -c`.

```sh
txw --help

# Create a wallet (defaults to Liquid testnet)
txw create-wallet --out wallet.json
txw info --wallet wallet.json

# Work with a manifest
txw validate ./txmanifest.json
txw describe ./txmanifest.json
txw run ./txmanifest.json <Action> --wallet wallet.json
```

Stay on Liquid testnet (the default), and keep keys out of version control.

## Where to put your work

`work/` is a scratch directory that is **entirely gitignored** — manifests,
wallets, state files, whatever. Working there means nothing of yours can be
committed to this repo by accident:

```sh
cd work
txw create-wallet --out wallet.json
txw run ./txmanifest.json Pay --wallet wallet.json
```

The root `.gitignore` also catches `wallet*.json`, `*.state.json` and
`*.instance.json` anywhere in the tree, but that is a safety net matching on
filename. `work/` is the belt.

## Examples


The full set (dex, lending, last_will, styx, deadcat, …) lives in the
[txmanifest-wallet](https://github.com/stringhandler/txmanifest-wallet) repo
rather than being copied here, where it would drift from the manifest format
the installed wallet actually speaks. Fetch it on demand:

```sh
./scripts/fetch-examples.sh
```

That puts a sparse clone in `work/txmanifest-wallet/` (gitignored, a few
hundred KB, no history), keeping upstream's `examples/` + `schema/` layout so
the manifests' relative `$schema` references still resolve.

## Checking the install

```sh
./scripts/doctor.sh
```

Reports where `asdf`, the shim and `txw` resolve for the current user, then
finishes by validating `examples/p2pk` with the installed wallet — an
end-to-end check that the codespace actually works, not just that a binary
exists on PATH.

## Changing the wallet version (no rebuild)

```sh
./scripts/set-wallet-version.sh 0.1.2     # downgrade
./scripts/set-wallet-version.sh latest    # upgrade to newest stable
```

That installs the version, rewrites `.tool-versions`, and reshims. Equivalent
manual steps:

```sh
asdf list all tx-manifest-wallet     # what's available
asdf install tx-manifest-wallet 0.1.2
asdf set tx-manifest-wallet 0.1.2    # writes ./.tool-versions
asdf current tx-manifest-wallet
```

`txw` resolves the wallet through the asdf shim on every call, so it always
points at whatever version is currently set — switching versions needs no
change to the alias.

Because `.tool-versions` is committed, the version you land on is what the next
codespace gets. Multiple versions can be installed side by side; switching
between them is just an `asdf set`.

### If a brand new release doesn't show up

The plugin lists versions from the upstream repo's git tags:

```sh
asdf plugin update tx-manifest-wallet
asdf list all tx-manifest-wallet
```

## Bumping asdf itself

`ASDF_VERSION` at the top of [.devcontainer/post-create.sh](.devcontainer/post-create.sh)
pins asdf. Changing it does require a rebuild (or just re-running the script).

## Notes / limits

- The upstream release workflow publishes **linux x86_64** and **windows msvc**
  binaries. Codespaces are Linux x86_64, so that's covered; an arm64 codespace
  would have no binary to install.
- Only released versions are installable — this plugin does not build from
  source. To hack on the wallet itself, clone
  [txmanifest-wallet](https://github.com/stringhandler/txmanifest-wallet) and use
  `cargo run --` instead.

## License

MIT — see [LICENSE](LICENSE).
