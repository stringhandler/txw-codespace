# Examples

| Example | Chain | Actions | Walkthrough |
|---------|-------|---------|-------------|
| [`p2pk`](p2pk) | Liquid testnet | `Pay`, `Receive` | [Root README](../README.md#liquid-testnet) |
| [`bitcoin_covenant`](bitcoin_covenant) | Bitcoin signet (public Simplicity signet) | `Lock`, `Unlock` | [bitcoin_covenant/README.md](bitcoin_covenant/README.md) |

Both run the same Simplicity program (`p2pk.simf`), a pay-to-public-key, on different chains.
`bitcoin_covenant` comes with its own `config.json` and needs wallet 0.3.0 or later.

Try one without spending anything:

```sh
txw describe examples/p2pk/txmanifest.json
txw validate examples/p2pk/txmanifest.json
```

> [!IMPORTANT]
> **Copy an example into `work/` before you `run` it.** `run` writes `*.state.json` next to the
> manifest, and `work/` is gitignored.

## More examples

The full set (dex, lending, last_will, deadcat, zeroconf, bitcoin_pay and more) lives
[upstream](https://github.com/stringhandler/txmanifest-wallet/tree/main/examples) so it doesn't
drift from the manifest format. Fetch it with:

```sh
./scripts/fetch-examples.sh    # sparse clone into work/txmanifest-wallet/ (gitignored)
```

## Notes for maintainers

The two examples here are copies of the matching directories in
[txmanifest-wallet](https://github.com/stringhandler/txmanifest-wallet)'s `examples/`. Their
`$schema` points at the upstream schema's raw URL, so editors can still resolve it. If one stops
validating against a newer wallet release, the copy here is stale. Re-sync it from upstream.
