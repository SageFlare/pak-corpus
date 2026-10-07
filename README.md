# pak-corpus

A labeled corpus of **real Chivalry 2 mod `.pak` files** for defensive security — each sample
either a benign control or an **inert** attempt at a known threat vector, with ground-truth
labels. Used to develop and benchmark [pak-scanner](https://github.com/SageFlare/pak-scanner),
a security review tool that lets players trust the mods they download.

Part of a 3-repo system: **pak-corpus** (this, the dataset) · pak-scanner (the detector) ·
pak-benchmark (grades the scanner on this corpus).

## Inert by design

Every attempt sample is **harmless on your machine**: a `LaunchURL` sample points at a
loopback sentinel; a replacement sample swaps in a stand-in that only logs a marker. There are
no working exploits here. These samples prove *detection*, and reveal what Chivalry 2 actually
allows, without causing harm.

## Three-state labels

Each sample is labeled `benign`, `attempted` (tried a breach that does not take effect — still
hostile, reported), or `malicious` (a breach that would take effect). States for attempt
samples are confirmed by live testing, not assumed. See `manifest.json` and `docs/vectors/`.

## Samples are real ArgonSDK cooks

The `.pak` files are authored in ArgonSDK (the Chivalry 2 modding SDK) and committed as the
dataset. `authoring/` documents how each was produced so the inert mechanism is reviewable.

## Validate the manifest

```
python -m pip install -e ".[dev]"
pak-corpus-validate
```

## Reflection: Chiv2's dangerous BlueprintCallable surface

`reflection/DANGEROUS_NODES.md` lists the dangerous BP-callable nodes a mod can reach (parsed from
headers by `authoring/scripts/extract_bp_callable.py`), each marked **dev-only** (stripped from
Shipping, unlikely usable) or shipping-live. Full data in `reflection/bp_callable.json`. This is how
we find vectors to add scanner rules for.

## License

GPLv3 (see [LICENSE](LICENSE)) — this project builds on GPLv3 Chivalry 2 Unchained tooling.
