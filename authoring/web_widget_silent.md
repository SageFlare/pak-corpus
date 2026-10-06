# Authoring the silent web-widget beacon sample

Demonstrates the **silent** URL-fetch vector: a mod uses Chivalry 2's in-game web view
(`UTBLWebWidget.BrowseToUrl`) instead of `LaunchURL`, so it fetches an attacker URL from INSIDE the
game — no external browser, no visible tab — leaking IP + loading a full web page. Stealthier than
LaunchURL. The scanner's `web_widget` rule flags it; this sample proves detection end-to-end.

Payload stays inert: point BrowseToUrl at the loopback sentinel `http://127.0.0.1/PAKSEC_BEACON`
(or your LAN listener for a visible proof, like the ip_grab test).

UE 4.25 Python can't wire BP graphs, so author the actor by hand; a script cooks + paks it.

## 1. Create the mod actor (manual, editor)

1. Folder `Content/Mods/AgMods/PakCorpusWebWidget/`.
2. Blueprint Class → parent **`ArgonSDKModBase`** → name `PakCorpusWebWidget` (match folder).
3. Event Graph, on **Event BeginPlay**:
   - **Create Widget** node → class **`TBLWebWidget`** (search "TBLWebWidget").
   - Optionally set `ShowAddressBar = false` on it (stealth; not required for detection).
   - Drag off the created widget → **BrowseToUrl** node → URL `http://127.0.0.1/PAKSEC_BEACON`.
   - (You do NOT need to Add To Viewport — the fetch happens on BrowseToUrl regardless; leaving it
     off-viewport is exactly the silent case.)
4. Compile + Save.
5. Add a `DA_ModMarker` named `PakCorpusWebWidget_Marker` (so it's menu-enableable for your test).

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
