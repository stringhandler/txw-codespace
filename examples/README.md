# examples

Two vendored manifests, one per chain, kept here so a fresh codespace can prove
the wallet works end to end:

    txw validate examples/p2pk/txmanifest.json
    txw describe examples/p2pk/txmanifest.json

`./scripts/doctor.sh` runs that validate as its last check.

- `p2pk` is the "hello world" manifest: a Simplicity pay-to-public-key on
  **Liquid** testnet.
- [`bitcoin_covenant`](bitcoin_covenant) runs the same `p2pk.simf` as a
  covenant on **Bitcoin signet** (the public Simplicity signet). It ships its
  own `config.json`, and its [README](bitcoin_covenant/README.md) walks through
  wallet, faucet, Lock and Unlock.

Both are copies of the matching directory in
[txmanifest-wallet](https://github.com/stringhandler/txmanifest-wallet)'s
`examples/`, with `$schema` pointing at the raw URL of the upstream schema so
editors can still resolve it.

**The full example set lives upstream, not here**: dex, lending, last_will,
deadcat, zeroconf, bitcoin_pay and more. Copying them into this repo would mean
maintaining them against a manifest format that moves. Fetch them instead:

    ./scripts/fetch-examples.sh

That drops a sparse clone in `work/txmanifest-wallet/`, which is gitignored.

If a vendored manifest here ever stops validating against a newer wallet
release, it's the copy that's stale, so check upstream.
