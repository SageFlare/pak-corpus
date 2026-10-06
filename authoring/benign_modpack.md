# Authoring the benign two-mod pack (both markers)

A single pak carrying **two legitimate mods**, each an `ArgonSDKModBase` actor WITH its own
`DA_ModMarker` — so both show in the Mod Manager menu and neither is hidden. Neither does anything
dangerous (no LaunchURL, no replacement). This is the honest multi-mod "mod pack" case: it must
scan **benign**, proving the `hidden_mod` rule does not false-positive on marker'd mods.

UE 4.25 Python can't wire BP graphs, so author the two actors by hand; a script cooks + paks them.
Paths are placeholders — don't commit machine-specific paths.

## 1. Create two benign mod actors (manual, in the editor)

For EACH of two mods `PakCorpusBenignModA` and `PakCorpusBenignModB`:

1. Make the folder `Content/Mods/AgMods/<ModName>/`.
2. Right-click → **Blueprint Class** → parent **`ArgonSDKModBase`** → name it exactly `<ModName>`
   (same as the folder — the auto-detect naming scheme).
3. Open it → **Compile** → **Save**. **Do not add any node** — leave BeginPlay empty. (A benign
   mod that does nothing is fine for this test; the point is two marker'd, menu-visible actors.)
4. In the same folder, right-click → **Miscellaneous → Data Asset** → class **`DA_ModMarker`** →
   name `<ModName>_Marker` → Save. (With the matching folder/actor name you can leave its Mod
   Actors list empty.)

Do this twice (ModA and ModB). Result: two folders, each with `<Name>.uasset` + `<Name>_Marker.uasset`.

## 2. Cook + pak (scripted)

```
authoring\scripts\build_benign_modpack.ps1 -Project "<path to your ArgonSDK\TBL.uproject>"
```

Cooks both mod folders and paks them into one `samples\benign_modpack.pak`.

## 3. Verify

```
<ENGINE>\Binaries\Win64\UnrealPak.exe samples\benign_modpack.pak -List
```

Confirm BOTH `<ModName>.uasset` and BOTH `<ModName>_Marker.uasset` are present. Then scan it — it
should be **benign** (both mods have markers → not hidden; no dangerous nodes). Add the manifest
entry and run `pak-corpus-validate`.
