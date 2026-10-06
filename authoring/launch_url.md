# Authoring the LaunchURL attempt pak

A mod whose Blueprint calls the stock **LaunchURL** node on load, pointing at an **inert
localhost sentinel** URL. It attempts the browser-open vector without reaching any real
destination. The scanner's `launch_url` rule should flag it.

UE 4.25 Python cannot author Blueprint graph nodes, so the Blueprint is built **by hand** in
the editor; a script then cooks and paks it. Paths are placeholders — set them to your own and
do not commit machine-specific paths.

## 1. Create the Blueprint (manual, in the ArgonSDK editor)

1. Open the ArgonSDK project (`TBL.uproject`) in the UE 4.25 editor.
2. In the Content Browser, make the folder path `Content/Mods/PakCorpusLaunchUrl/` (the mod's
   own namespace — the point is a benign-looking mod that *tries* a dangerous node).
3. Right-click in that folder → **Blueprint Class** → parent class **Actor** → name it
   `BP_LaunchUrlAttempt`.
4. Double-click it to open the Blueprint editor. In the **Event Graph**:
   - You already have **Event BeginPlay** (add it if not: right-click → "Add Event" →
     "Event BeginPlay").
   - Drag off BeginPlay's exec pin → search **"Launch URL"** → add the **Launch URL** node
     (KismetSystemLibrary).
   - In the node's **URL** field type the inert sentinel:
     `http://127.0.0.1/PAKSEC_BEACON`
     (loopback; nothing real is contacted.)
5. **Compile** then **Save**.

That's the only manual part. The node name `LaunchURL` now lives in the asset's name table,
which is what the scanner detects.

## 2. Cook + pak (scripted)

Run the build script with your project path:

```
authoring\scripts\build_launch_url.ps1 -Project "<path to your ArgonSDK\TBL.uproject>"
```

(Add `-EngineRoot "<your UE 4.25 Engine dir>"` if not the default Epic location.)

It cooks `Content/Mods/PakCorpusLaunchUrl/` and paks it under
`../../../TBL/Content/Mods/PakCorpusLaunchUrl/`, then writes `samples\launch_url_attempt.pak`
and lists its entries.

## 3. Verify the attempt is present

List the pak and confirm the BP is there:

```
<ENGINE>\Binaries\Win64\UnrealPak.exe samples\launch_url_attempt.pak -List
```

You should see `BP_LaunchUrlAttempt.uasset` under the mod namespace.

## 4. Label

The three-state label (`attempted` vs `malicious`) is set by the **live test** — see
`docs/live-test.md`. If LaunchURL actually fires on load in the real game → `malicious`; if the
node is present but never fires (e.g. compiled out / not reached) → `attempted`. Do not commit
the manifest entry until the live test sets the real state.
