# Vector: Asset replacement (primary)

**What:** A mod pak entry whose virtual path falls under a trusted game content dir
(`TBL/Content/<Blueprint|Characters|Weapons|GameModes|UI|...>`) rather than the mod's own
`TBL/Content/Mods/` namespace. On mount, UE's pak precedence makes the game load the mod's file
in place of the real asset — the mod *shadows* trusted game content.

**Why it matters:** This is the main way a malicious Chivalry 2 mod does damage without native
code. Swapping a gameplay-critical Blueprint (a PlayerController, GameMode, weapon, ability) for
a hostile version changes how the game behaves for anyone who loads the mod. Unchained's own
scanner models asset replacement as the key thing a mod does; our scanner treats it as the
primary malicious signal.

**Inert sample:** `samples/asset_replacement_attempt.pak` — an inert magenta UI material packed
to the real path `TBL/Content/UI/Materials/DetailLines/M_DetailLine_gradient`, shadowing the
game's material. Harmless (a color), but it genuinely exercises the vector. Authored via
`authoring/asset_replacement.md`.

**Scanner detection:** the `asset_replacement` rule flags any entry under `TBL/Content/<game
dir>` that is not under `Mods/`. Critical gameplay dirs are High severity (reachable →
malicious); others Medium.

**Find it manually:** list the pak entries and compare against the mod's own namespace:
```
UnrealPak.exe mod.pak -List
```
Any path under `TBL/Content/<game dir>/` that is NOT `TBL/Content/Mods/...` is a replacement —
the mod is writing over the game's own asset at that path.
