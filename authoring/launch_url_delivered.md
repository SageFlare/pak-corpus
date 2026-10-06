# Authoring the DELIVERED LaunchURL attempt pak (a true `malicious` candidate)

The loose-BP LaunchURL sample is `attempted` — nothing spawns it. This variant uses ArgonSDK's
**mod-actor auto-spawn** so the Unchained mod loader runs it on **any** match load, with no
custom map needed. That is the realistic delivery path, so if LaunchURL fires here, the sample
is a confirmed **`malicious`**.

The payload stays inert: `LaunchURL("http://127.0.0.1/PAKSEC_BEACON")` (loopback, dead page).

UE 4.25 Python can't wire BP graph nodes, so the Blueprint is hand-authored; a script cooks and
paks it. Follow Field Guide T3 ("Create your first Blueprint Mod") — this mirrors it exactly.

## 1. Create the Mod Actor (manual, in the editor)

1. Open ArgonSDK (`TBL.uproject`).
2. Make the folder `Content/Mods/AgMods/PakCorpusLaunchUrlMod/` (the default mod-actor dir, so no
   extra marker wiring is needed).
3. Right-click → **Blueprint Class** → **expand "All Classes"** → pick parent **`ArgonSDKModBase`**
   (NOT plain Actor). Name it **`PakCorpusLaunchUrlMod`** (same as the folder — the loader
   auto-detects this naming scheme).
4. Open it → **Open Full Blueprint Editor** → Event Graph:
   - Add **Event BeginPlay** (or use the inherited `Parent: BeginPlay`).
   - Drag off its exec pin → add **Launch URL** node.
   - Set URL = `http://127.0.0.1/PAKSEC_BEACON`.
   - Connect BeginPlay exec → LaunchURL exec.
5. **Compile** then **Save**.

## 2. Create the Mod Marker (manual)

1. In the same folder, right-click → **Miscellaneous → Data Asset** → class **`DA_ModMarker`**.
   Name it `ModMarker`.
2. Because the actor uses the `Content/Mods/AgMods/<ModName>/<ModName>` naming scheme, you can
   leave `Mod Actors` empty (the loader auto-detects). If you named things differently, open the
   marker and add `PakCorpusLaunchUrlMod` to the `Mod Actors` list.
3. Save.

Optional (recommended for a clean offline test): open the Mod Actor → Class Defaults → Mod Loader
Settings → set **Host Only** (loads offline / on an Unchained server). Leave Silent Load off so
you see the "Loaded..." chat line confirming it spawned.

## 3. Cook + pak (scripted)

```
authoring\scripts\build_launch_url_delivered.ps1 -Project "<path to your ArgonSDK\TBL.uproject>"
```

Cooks `Content/Mods/AgMods/PakCorpusLaunchUrlMod/` and paks it (zz_-named to load cleanly),
writing `samples\zz_launch_url_delivered.pak`.

## 4. Live-test (sets the label)

Per `docs/live-test.md`, offline only. Start the loopback listener (`python -m http.server 80`),
install, launch via Unchained, **load into any match**. The mod actor auto-spawns → BeginPlay →
LaunchURL fires:
- Browser opens / listener logs `GET /PAKSEC_BEACON` → **`malicious`** (delivered + fired).
- Nothing → still `attempted`; check the marker/naming and that the mod shows as loaded.
