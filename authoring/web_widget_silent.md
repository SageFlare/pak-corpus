# Authoring the silent web-widget beacon sample

Demonstrates the **silent** URL-fetch vector: a mod uses Chivalry 2's in-game web view
(`UTBLWebWidget.BrowseToUrl`) instead of `LaunchURL`, so it fetches an attacker URL from INSIDE the
game — no external browser, no visible tab — leaking IP + loading a full web page. Stealthier than
LaunchURL. The scanner's `web_widget` rule flags it; this sample proves detection end-to-end.

Payload stays inert: point BrowseToUrl at the loopback sentinel `http://127.0.0.1/PAKSEC_BEACON`
(or your LAN listener for a visible proof, like the ip_grab test).

UE 4.25 Python can't wire BP graphs, so author the actor by hand; a script cooks + paks it.

## IMPORTANT: Event Construct only fires when the widget is ADDED TO VIEWPORT

A UserWidget's `Event Construct` does NOT run just because the widget was created — it fires when
the widget is added to the viewport. If the actor only Creates the widget and never adds it, the
BrowseToUrl in Construct never runs (this was the bug in the first attempt). Two fixes:
- **(a) Call BrowseToUrl from the ACTOR**, right after Create Widget, instead of from the widget's
  Construct. No viewport needed. Cleanest, and matches the stealth case (nothing shown).
- **(b) Add To Viewport** but make the TBLWebWidget zero-size / offscreen / collapsed so nothing
  visible appears. Construct then fires.
Use (a) below.

## Instrument with Show Local Chat checkpoints (NOT Print String!)

`Print String` is **Development-only** — UE strips it from Shipping/Test cooks (which is how our
paks are cooked, via the cook commandlet), so it shows nothing in a real build. Use **`Show Local
Chat`** instead (wraps ClientReceiveLocalizedChat; BlueprintCallable, shipping-safe; the T3 "Hello
World" node). It prints to the in-game chat box.
- Actor BeginPlay, first node: Show Local Chat "WW: actor BeginPlay"
- After Create Widget: Show Local Chat "WW: widget created"
- After BrowseToUrl: Show Local Chat "WW: after BrowseToUrl"
Read the in-game chat: missing "actor BeginPlay" = actor didn't spawn; "created" but no "after
BrowseToUrl" = the call path broke; all three present but no listener hit = BrowseToUrl ran but the
in-game web view (CEF) did not fetch (vector present but neutered at runtime).

## 1. Create the mod actor + a UserWidget hosting the web view (manual, editor)

NOTE: `UTBLWebWidget` is a primitive `UWidget` (not a UserWidget), so **Create Widget will NOT list
it** (you'll only see "Cast To TBLWebWidget"). Primitive widgets are placed inside a UserWidget's
Designer, then driven from that UserWidget's graph. Correct steps:

1. Folder `Content/Mods/AgMods/PakCorpusWebWidget/`.
2. **Create a UserWidget IN THIS SAME FOLDER** (`Content/Mods/AgMods/PakCorpusWebWidget/`, so the
   build script paks it and the scanner sees the tokens): right-click → Blueprint Class → **Widget
   Blueprint** → name `WBP_PakCorpusWeb`. Open it.
3. In the **Designer**, from the Palette drag a **TBLWebWidget** onto the canvas (search "TBLWeb" in
   the palette). Name it `WebView`. Optionally untick `ShowAddressBar` (stealth; not needed for
   detection). Mark it **Is Variable** so the graph can reference it.
4. In the UserWidget **Graph**: add a **BlueprintCallable custom event or function** `DoBrowse`
   that calls `WebView -> BrowseToUrl(http://127.0.0.1:8080/PAKSEC_BEACON)`. (Do NOT rely on Event
   Construct — see the IMPORTANT note above.) Compile + Save.
5. **Create the mod actor**: Blueprint Class → parent **`ArgonSDKModBase`** → name
   `PakCorpusWebWidget` (match folder). On **Event BeginPlay**:
   - Print String "WW: actor BeginPlay"
   - **Create Widget** → class `WBP_PakCorpusWeb` → promote the return to a variable `W`.
   - Print String "WW: widget created"
   - Call `W -> DoBrowse` (the function from step 4) — this runs BrowseToUrl without needing the
     widget on screen.
   - Print String "WW: after BrowseToUrl"
   Compile + Save. (If `DoBrowse` is awkward, alternatively drag the created widget `W` -> get
   `WebView` (mark it Is Variable + public) -> BrowseToUrl directly from the actor graph.)
6. Add a `DA_ModMarker` named `PakCorpusWebWidget_Marker` (so it's menu-enableable for your test).

The scanner detects this regardless of path: `TBLWebWidget` / `BrowseToUrl` land in the WBP's name
table, which the web_widget rule scans.

## 2. Cook + pak

Copy build_launch_url_delivered.ps1 to build_web_widget.ps1, set `$modRel =
'Mods/AgMods/PakCorpusWebWidget'` and output name `zz_web_widget.pak`. Run it:

```
authoring\scripts\build_web_widget.ps1 -Project "<path to your ArgonSDK\TBL.uproject>"
```

## 3. Scan (detection proof)

```
dotnet run --project ../pak-scanner/src/PakScanner -- samples/zz_web_widget.pak
```
Expect **flagged-active**, `web_widget` finding ("references BrowseToUrl ... SILENT: in-game web
view").

## 4. (Optional) live test the SILENCE

Like ip_grab: set the URL to `http://<YOUR_LAN_IP>:8080/beacon`, run `python -m http.server 8080`,
install + enable, load a match. The listener logs the hit **with no browser window appearing** —
that's the silent beacon. Teardown: remove pak + sig.

## 5. Add to corpus

Copy the pak to samples/, add a manifest entry (vector `web_widget`, expected_state
`flagged-active`), run `pak-corpus-validate`. (vector `web_widget` must be added to the validator's
VECTORS set and the scanner already has the rule.)
