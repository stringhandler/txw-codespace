# examples

One vendored manifest, kept here purely so a fresh codespace can prove the
wallet works end to end:

    txw validate examples/p2pk/txmanifest.json
    txw describe examples/p2pk/txmanifest.json

`./scripts/doctor.sh` runs that validate as its last check.

`p2pk` is the "hello world" manifest — a Simplicity pay-to-public-key on Liquid.
It is a copy of `examples/p2pk` from
[txmanifest-wallet](https://github.com/stringhandler/txmanifest-wallet), with
`$schema` repointed at the raw URL of the upstream schema so editors can still
resolve it.

**The full example set lives upstream, not here** — dex, lending, last_will,
styx, deadcat, prize_contest, zeroconf and more. Copying them into this repo
would mean maintaining them against a manifest format that moves. Fetch them
instead:

    ./scripts/fetch-examples.sh

That drops a sparse clone in `work/txmanifest-wallet/`, which is gitignored.

If the vendored manifest here ever stops validating against a newer wallet
release, it's the copy that's stale — check upstream.
