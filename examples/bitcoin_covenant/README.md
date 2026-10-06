# bitcoin_covenant

A Simplicity covenant on **Bitcoin signet**: coins locked under a program the
node itself executes, then spent by satisfying it.

The program is `p2pk.simf`, byte-identical to [../p2pk](../p2pk), which runs on
Liquid:

```
fn main() {
    let sig: Signature = witness::SIGNATURE;
    jet::bip_0340_verify((param::PUB_KEY, jet::sig_all_hash()), sig);
}
```

The same source and key still give a **different address on each chain**: jet
CMRs and the taproot tags are domain-separated between Bitcoin and Elements.

Two actions:

- **`Lock`** — pay into the covenant. To the chain it is an ordinary P2TR output.
- **`Unlock`** — spend it. The wallet builds the transaction, computes
  `sig_all_hash`, signs with your key and assembles the Simplicity witness. The
  node then *runs the program*.

Needs `tx-manifest-wallet` 0.3.0 or later (`txw --version`).

## Which network

[config.json](config.json) points at the public **Simplicity signet**, the only
public network where Simplicity is active:

```json
"default_network": "bitcoin-signet",
"default_esplora": "https://signet.simplicity-lang.org/explorer/api",
"simplicity_activated": true
```

Your normal wallet config (Liquid testnet) is left alone. The wallet uses the
`config.json` that sits **beside the wallet file**, so keeping the signet wallet
in its own directory with this config next to it is all it takes. `--config`
works too.

## Running it

From the repo root, set up a signet workspace in `work/` (gitignored):

```sh
mkdir -p work/signet
cp -r examples/bitcoin_covenant work/signet/
cp examples/bitcoin_covenant/config.json work/signet/   # config beside the wallet
cd work/signet

txw create-wallet --out wallet.json   # records network: bitcoin-signet
txw info --wallet wallet.json         # receive address + "Wallet Signing Key"
```

Fund the receive address from the faucet at
<https://signet.simplicity-lang.org>, then check it arrived:

```sh
txw sync --wallet wallet.json
```

Put the **Wallet Signing Key** from `info` into
`bitcoin_covenant/params.json` as `PUB_KEY`. That is the key the covenant
demands, so it must be one this wallet can sign with. The key shipped in
`params.json` belongs to someone else's wallet, and coins locked to it are gone.

Lock, then unlock:

```sh
txw run bitcoin_covenant/txmanifest.json Lock \
  --wallet wallet.json --params bitcoin_covenant/params.json \
  --state-out cov.state.json

# wait for the lock to confirm, then:
txw run bitcoin_covenant/txmanifest.json Unlock \
  --wallet wallet.json --params bitcoin_covenant/params.json \
  --state cov.state.json --state-out cov.state.2.json
```

`Lock` records the covenant UTXO in the state file so that `Unlock` can find it.
On success you'll see:

```
· Covenant input 'vault_in' — satisfying… OK
```

and a ~142-vbyte transaction whose witness has four items: the Simplicity
witness, the program, its CMR and the control block.

## Limits worth knowing

- **Pinning the covenant input by hand needs its amount.** `--input
  vault_in=<txid>:0` alone leaves `amount_sat` at zero, so `vault_in.amount_sat -
  fee` goes negative. Use the state file, or `--inputs-file`.
- **Only some jets work on Bitcoin.** About 27 of 428 have their FFI wired in
  `rust-simplicity`. `p2pk` needs `bip_0340_verify` and `sig_all_hash`, which
  both work. Most richer covenants don't yet.
- Output lines say `sat lbtc`. That label is left over from Elements: on Bitcoin
  the only asset is BTC.

Vendored from
[txmanifest-wallet/examples/bitcoin_covenant](https://github.com/stringhandler/txmanifest-wallet/tree/main/examples/bitcoin_covenant).
Upstream also has `config.regtest.json` for a local Docker node, which isn't
included here.
