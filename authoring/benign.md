# Authoring the benign control paks

These are **normal, harmless mods** — the false-positive controls. The scanner must label them
`benign`. They only add content under their own `Mods/` namespace and never replace a trusted
game asset or call a dangerous node.

The pipeline is the standard ArgonSDK cook → UnrealPak create/test/list/hash. Set these to your
own locations (do not commit machine-specific paths back into this repo):

- `ENGINE` — your UE 4.25 engine root (contains `Binaries\Win64\UE4Editor-Cmd.exe` and
  `UnrealPak.exe`).
- `PROJECT` — your `TBL.uproject` (ArgonSDK).
- `SAMPLES` — this repo's `samples/` directory.

## benign_map — a simple custom FFA map

The quickest benign map is the ArgonSDK "Create a Free-For-All Map" tutorial mod (Field Guide
T2), or any existing custom-map mod you already build. Any custom FFA map whose content lives
entirely under `Content/Mods/...` works.

1. Cook the map mod with `UE4Editor-Cmd` (adapt the target to your map package):
   ```
   <ENGINE>\Binaries\Win64\UE4Editor-Cmd.exe <PROJECT> -run=cook -targetplatform=WindowsNoEditor ^
     -map=/Game/Mods/<YourMapPackage> -unattended -nop4 -abslog=cook.log
   ```
2. Pak the cooked output with `UnrealPak.exe` using a create-manifest that maps each cooked file
   to a path **inside the mod's own namespace**, e.g.
   `../../../TBL/Content/Mods/<YourMod>/<relative>`.
3. Copy the resulting `.pak` to `<SAMPLES>\benign_map.pak`.

## benign_cosmetic — a mod adding new content under its own path

A second benign shape: a mod that adds a new asset under its own `Mods/` folder, touching
nothing the game ships. **This one is automated** — you do not need to create the asset by hand.

The scripts in `authoring/scripts/` create a plain cosmetic material under
`/Game/Mods/PakCorpusBenign/`, cook it, and pak it. Just run the build script with your project
path:

```
authoring\scripts\build_benign_cosmetic.ps1 -Project "<path to your ArgonSDK\TBL.uproject>"
```

(Optionally add `-EngineRoot "<your UE 4.25 Engine dir>"` if your engine is not at the default
Epic install location.)

It writes `samples\benign_cosmetic.pak` and `authoring\scripts\build\pak-list.txt`. The script
already maps everything under `../../../TBL/Content/Mods/PakCorpusBenign/`, so it's benign by
construction. What the scripts do:
- `make_benign_cosmetic.py` — creates the material via the `unreal` Python API (same pattern as
  TheBox's `create_map.py`).
- `build_benign_cosmetic.ps1` — runs that, cooks, paks, verifies integrity, lists, hashes.

## Verify they're genuinely benign (before labeling)

For each pak, list its entries and confirm **every path is under `TBL/Content/Mods/`** (the
mod's own namespace) — nothing under a standard game dir, so nothing is replaced:

```
<ENGINE>\Binaries\Win64\UnrealPak.exe <SAMPLES>\benign_map.pak -List
```

If any entry lands under e.g. `TBL/Content/Characters/` or `TBL/Content/Blueprint/`, it is NOT
benign — that's an asset replacement; set it aside for the replacement sample instead.

## Then

Add the manifest entries (see the Phase 1 plan, Task 2) and run `pak-corpus-validate`.
