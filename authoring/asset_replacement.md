# Authoring the asset-replacement attempt pak

The **primary** attack vector. A mod pak places an entry at a **trusted game asset path**
(`TBL/Content/<game dir>/...`), so on mount it shadows the real game asset — the game loads the
mod's version instead. This sample does it harmlessly: an inert magenta material shadows a
low-risk UI material. A real attacker would target a gameplay-critical class.

This one is **fully scripted** — no manual editor work. Paths are placeholders; don't commit
machine-specific paths.

## Build

```
authoring\scripts\build_asset_replacement.ps1 -Project "<path to your ArgonSDK\TBL.uproject>"
```

(Add `-EngineRoot "<your UE 4.25 Engine dir>"` if not the default Epic location.)

What the scripts do:
- `make_replacement_asset.py` — creates an inert unlit **magenta** material under the mod's own
  `/Game/Mods/PakCorpusReplacement/` namespace (magenta so a human can see the swap in-game).
- `build_asset_replacement.ps1` — cooks it, then paks it to the **shadow path**
  `../../../TBL/Content/UI/Materials/DetailLines/M_DetailLine_gradient.*`, replacing the real
  game UI material. Writes `samples\asset_replacement_attempt.pak`.

## Verify the replacement path is present

```
<ENGINE>\Binaries\Win64\UnrealPak.exe samples\asset_replacement_attempt.pak -List
```

Confirm an entry under `TBL/Content/UI/Materials/DetailLines/` (NOT under `Mods/`). That path
under a trusted game dir is exactly what the scanner's `asset_replacement` rule flags.

## Label

Set by the **live test** (`docs/live-test.md`). If the magenta stand-in actually appears in
place of the original game material → the replacement took effect → `malicious`. If the game
ignores/rejects it → `attempted`. Don't commit the manifest entry until the live test sets the
real state.

## Safety

The replaced asset is a cosmetic UI material and the stand-in is inert (just a color). Nothing
gameplay-critical is touched. This demonstrates the vector without harming the game; remove the
pak (and its `.sig`) after testing to restore the original asset.
