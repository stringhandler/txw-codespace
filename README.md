# txw-codespace

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/stringhandler/txw-codespace)

**A one-click sandbox for [`tx-manifest-wallet`](https://github.com/stringhandler/txmanifest-wallet)**,
the transaction-manifest CLI for Liquid and Bitcoin. Open a codespace and you get a terminal with
the wallet (`txw`) installed and working [Simplicity](https://simplicity-lang.org) examples for both
chains. Nothing to install locally.

## Start

Click the badge above. The first build takes a couple of minutes, and the log ends with `Ready.`. Then:

```sh
txw --version
```

Next, pick a chain. Both paths run the **same Simplicity program** (pay-to-public-key), so start with
whichever one you care about.

| | **Liquid testnet** | **Bitcoin signet** |
|---|---|---|
| Example | [`examples/p2pk`](examples/p2pk) | [`examples/bitcoin_covenant`](examples/bitcoin_covenant) |
| Actions | `Pay` → `Receive` | `Lock` → `Unlock` |
| Faucet | <https://liquidtestnet.com/faucet> | <https://signet.simplicity-lang.org> |
| Config | none, it's the wallet default | bundled `config.json` |
| Wallet version | any | 0.3.0 or later |

Do everything inside `work/`. It is gitignored, so wallets and keys can't be committed by accident.

### Liquid testnet

```sh
mkdir -p work/liquid && cd work/liquid
cp -r ../../examples/p2pk .

txw create-wallet --out wallet.json   # Liquid testnet by default
txw info --wallet wallet.json         # receive address + "Wallet Signing Key"
# fund the address from the faucet, then:
txw sync --wallet wallet.json

txw describe p2pk/txmanifest.json                           # see the actions and their params
txw prepare  p2pk/txmanifest.json Pay --wallet wallet.json  # split UTXOs if needed
txw run      p2pk/txmanifest.json Pay --wallet wallet.json  # resolve → build → sign → broadcast
```

Use your own **Wallet Signing Key** as `pubkey` in `Pay`, so you can spend the output back with
`Receive`. `Receive` finds that output through the state file `Pay` wrote.

### Bitcoin signet

```sh
mkdir -p work/signet && cd work/signet
cp -r ../../examples/bitcoin_covenant .
cp bitcoin_covenant/config.json .     # must sit beside the wallet file

txw create-wallet --out wallet.json   # picks up bitcoin-signet from config.json
txw info --wallet wallet.json
# fund from the faucet, put your "Wallet Signing Key" into bitcoin_covenant/params.json as PUB_KEY, then:
txw sync --wallet wallet.json

txw run bitcoin_covenant/txmanifest.json Lock \
  --wallet wallet.json --params bitcoin_covenant/params.json --state-out cov.state.json
# wait for a confirmation, then:
txw run bitcoin_covenant/txmanifest.json Unlock \
  --wallet wallet.json --params bitcoin_covenant/params.json \
  --state cov.state.json --state-out cov.state.2.json
```

The [bitcoin_covenant README](examples/bitcoin_covenant/README.md) explains what happens at each
step and lists Bitcoin-specific limits.

## FAQ

<details>
<summary><b>Liquid or Bitcoin signet: which should I try?</b></summary>

Liquid testnet is the wallet's default and supports the full set of Simplicity jets, so most upstream
examples target it. On Bitcoin signet, Simplicity is a covenant the node itself runs. It's newer, and
only a few jets work there so far: `p2pk` does, most richer contracts don't. Pick signet if Bitcoin is
what you care about, otherwise start with Liquid.
</details>

<details>
<summary><b>Can I use both chains in one codespace?</b></summary>

Yes. Keep each wallet in its own directory (`work/liquid`, `work/signet`). The wallet reads the
`config.json` **beside the wallet file**, or one you pass with `--config`, so each directory keeps
its own network settings. The same program and key give a different covenant address on each chain.
</details>

<details>
<summary><b>Where are the other examples (dex, lending, last_will, …)?</b></summary>

They live upstream so they don't drift from the manifest format. Fetch them with:

```sh
./scripts/fetch-examples.sh   # sparse clone into work/txmanifest-wallet/, run again to update
txw describe work/txmanifest-wallet/examples/<name>/txmanifest.json
```
</details>

<details>
<summary><b>Why copy examples into <code>work/</code> instead of running them in place?</b></summary>

`run` writes `*.state.json` next to the manifest. In `work/` those files are gitignored. As a fallback,
`wallet*.json`, `*.state.json` and `*.instance.json` are ignored everywhere in the repo.
</details>

<details>
<summary><b>What commands are there?</b></summary>

| Command | What it does |
|---------|--------------|
| `create-wallet` | Generate a new wallet JSON file. |
| `info` | Fingerprint, xpub, oracle key, signing key, receive address. |
| `sync` / `get-balance` | Sync with Esplora and show the balance / show the last-synced balance. |
| `describe` / `validate` | Explore a manifest interactively / run static checks. |
| `prepare <manifest> <action>` | Make sure the wallet holds the UTXOs the action needs (may broadcast a split). |
| `run <manifest> <action>` | Resolve → build → sign → broadcast. |
| `split` | Split a wallet asset into N equal UTXOs. |
| `config` | Show or change `default_network` / `default_esplora`. |

`txw <command> --help` has every flag. `txw` and `tx-manifest-wallet` are interchangeable.
</details>

<details>
<summary><b>Could I lose real money?</b></summary>

Not unless you switch to mainnet. Testnet and signet coins have no value, and the defaults stay on
test networks. Only `txw config default_network mainnet` (or a mainnet `config.json`) uses real funds.
</details>

<details>
<summary><b>How do I change the wallet version?</b></summary>

```sh
./scripts/set-wallet-version.sh 0.3.0    # or: latest
```

You don't need to rebuild. The script updates `.tool-versions` (committed, so the next codespace gets
the same version). Each wallet release supports one manifest format, so an old wallet will reject
newer manifests. If a new release isn't listed, run `asdf plugin update tx-manifest-wallet`.
</details>

<details>
<summary><b>Can I run this without Codespaces?</b></summary>

Yes. Clone the repo, open it in VS Code with the
[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
extension, and choose **Reopen in Container**. The host must be x86_64, because release binaries are
only published for linux x86_64 and windows msvc.
</details>

<details>
<summary><b>What's in the container?</b></summary>

An Ubuntu 24.04 devcontainer base image plus `gh`.
[post-create.sh](.devcontainer/post-create.sh) installs a pinned `asdf`, the wallet's prebuilt release
binary at the version in [.tool-versions](.tool-versions), and the `txw` wrapper. The wallet isn't baked
into the image, which is why you can change its version without a rebuild. If setup fails, the log is
in `.devcontainer/post-create.log`.
</details>

<details>
<summary><b>I want to hack on the wallet itself</b></summary>

This repo only installs released binaries. Clone
[txmanifest-wallet](https://github.com/stringhandler/txmanifest-wallet) and use `cargo run --`.
</details>

## License

MIT. See [LICENSE](LICENSE).
