# txw-codespace

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/stringhandler/txw-codespace)

A ready-to-run [dev container](https://containers.dev) / GitHub Codespace for
[`tx-manifest-wallet`](https://github.com/stringhandler/txmanifest-wallet), the
Liquid/Elements transaction-manifest CLI. The container has the wallet and
nothing else.

## Quick start

You have a terminal with **`txw`** on `PATH` — shorthand for
`tx-manifest-wallet`; the two are interchangeable everywhere.

```sh
./scripts/doctor.sh    # prove the install works, end to end
txw --help             # every command and flag
```

Do your own work in **`work/`**. It is entirely gitignored, so wallets, keys and
state files cannot be committed by accident.

```sh
cd work
txw create-wallet --out wallet.json    # Liquid testnet by default
txw info --wallet wallet.json          # prints a receive address — go fund it
txw sync --wallet wallet.json          # pull the funding in, show the balance
```

Then drive a manifest. Copy it into `work/` first — `run` writes
`*.state.json` beside the manifest, and you don't want that inside `examples/`:

```sh
cp -r ../examples/p2pk .
txw describe p2pk/txmanifest.json                          # explore it interactively
txw validate p2pk/txmanifest.json                          # static checks
txw prepare  p2pk/txmanifest.json Pay --wallet wallet.json # split UTXOs if needed
txw run      p2pk/txmanifest.json Pay --wallet wallet.json # build → sign → broadcast
```

> **Testnet is the default — keep it that way** unless you mean it.
> `txw config default_network mainnet` switches to real money.

### Commands

| Command | What it does |
|---------|--------------|
| `create-wallet` | Generate a new wallet JSON file. |
| `info` | Wallet fingerprint, xpub, oracle key, and a receive address. |
| `sync` | Sync against an Esplora server and show the balance. |
| `get-balance` | Last-synced balance, no network call. |
| `describe <manifest>` | Interactively explore a manifest's classes and actions. |
| `validate <manifest>` | Static schema/sanity checks. |
| `prepare <manifest> <action>` | Ensure the wallet holds the UTXOs the action needs; broadcasts a split tx if not. |
| `run <manifest> <action>` | Walk an action through resolve → build → sign → broadcast. |
| `split` | Split a wallet asset into N equal UTXOs. |
| `config` | Show or change `default_network` / `default_esplora`. |

`txw <command> --help` has the full flag detail.

## More examples

[examples/p2pk](examples/p2pk) is vendored here as the "hello world" — a
Simplicity pay-to-public-key — purely so a fresh codespace can prove itself.
The full set (dex, lending, last_will, deadcat, …) lives in the
[txmanifest-wallet](https://github.com/stringhandler/txmanifest-wallet) repo
rather than being copied here, where it would drift from the manifest format
the installed wallet actually speaks. Fetch it on demand:

```sh
./scripts/fetch-examples.sh
```

That puts a sparse clone in `work/txmanifest-wallet/` (gitignored, a few
hundred KB, no history), keeping upstream's `examples/` + `schema/` layout so
the manifests' relative `$schema` references still resolve.

## Where to put your work

`work/` is a scratch directory that is **entirely gitignored** — manifests,
wallets, state files, whatever. Working there means nothing of yours can be
committed to this repo by accident.

The root `.gitignore` also catches `wallet*.json`, `*.state.json` and
`*.instance.json` anywhere in the tree, but that is a safety net matching on
filename. `work/` is the belt.

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

The manifest **format** version is tied to the wallet version: the wallet
refuses a `txmanifest.json` whose `manifest_version` it does not speak. The
vendored example tracks the pinned release, so downgrading far enough will stop
it validating — that is what `./scripts/doctor.sh` catches.

### If a brand new release doesn't show up

The plugin lists versions from the upstream repo's git tags:

```sh
asdf plugin update tx-manifest-wallet
asdf list all tx-manifest-wallet
```

## Opening this in a codespace

Click the badge at the top, or from the repo page: **Code ▸ Codespaces ▸ Create
codespace on main**. Nothing needs enabling first — Codespaces works on any
public repo, and creation is billed to whoever opens it, against their own
free-tier hours.

First creation takes a couple of minutes: the image pulls, then
`postCreateCommand` installs asdf and the wallet. Watch the creation log; it
ends with `Ready.`. If you miss it, the same output is kept in
`.devcontainer/post-create.log`.

To run it locally instead of on GitHub, clone the repo, open it in VS Code with
the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
extension, and choose **Reopen in Container**.

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
the only place the version is declared — which is why the wallet can be
upgraded or downgraded inside a running codespace without rebuilding it.

`ASDF_VERSION` at the top of [.devcontainer/post-create.sh](.devcontainer/post-create.sh)
pins asdf itself. Changing that one does require a rebuild (or just re-running
the script).

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
