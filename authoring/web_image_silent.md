# Testing the WebImageWidget silent-beacon lead

`UWebImageWidget : UImage` (TBL/Public/WebImageWidget.h) downloads an image from a URL and displays
it. BlueprintCallable `SetUrl(FString)` + a BlueprintReadWrite `URL` + an ImageDownloaded delegate.
Unlike TBLWebWidget (needs CEF, proven inert in shipping), this uses UE's image-download path
(HTTP that ships with the game for normal features), so it is MORE likely to actually fetch in
retail — a silent IP beacon via an image GET (no browser, loads a texture).

Status: the SDK .cpp is an empty stub (reconstructed SDK), so we CANNOT confirm from source whether
the real shipping game's SetUrl downloads. Only a live test settles it.

Payload inert: point the URL at your LAN listener (image GET still leaks IP even if it 404s).

## 1. Author (manual, editor)

1. Folder `Content/Mods/AgMods/PakCorpusWebImage/`.
2. **Widget Blueprint** `WBP_PakCorpusImg` IN THIS FOLDER (User Interface -> Widget Blueprint).
3. Designer: drag a **WebImageWidget** from the palette (search "WebImage") onto the canvas, name it
   `Img`, tick **Is Variable** + make it public.
4. Widget Graph: add a BlueprintCallable custom event `DoFetch` -> `Img -> SetUrl` ->
   `http://<YOUR_LAN_IP>:8080/beacon.png`. (Also set the `URL` property on Img in the Designer to the
   same, in case SetUrl is a stub but the property-driven download fires.) Compile + Save.
5. Mod actor `PakCorpusWebImage` (parent **ArgonSDKModBase**, match folder). Event BeginPlay:
   - Show Local Chat "WI: actor BeginPlay"
   - Create Widget (WBP_PakCorpusImg) -> promote to var `W`
   - Show Local Chat "WI: widget created"
   - **Add to Viewport** on `W`  <-- include this: an Image may only download when shown.
   - Call `W -> DoFetch`
   - Show Local Chat "WI: after SetUrl"
   Compile + Save. Add `DA_ModMarker` `PakCorpusWebImage_Marker`.

Note: we DO add to viewport here (unlike the web_widget test) because an image widget may defer the
download until it needs to render. If it fires without viewport too, even better (more silent).

## 2. Build

Copy build_launch_url_delivered.ps1 -> build_web_image.ps1, set modRel
`Mods/AgMods/PakCorpusWebImage`, output `zz_web_image.pak`. Run it.

## 3. Live test

`python -m http.server 8080`, launch offline, enable `PakCorpusWebImage`, load a match.
- All 3 chat lines + listener logs `GET /beacon.png` => **silent image beacon CONFIRMED in retail**
  (higher-severity than the inert TBLWebWidget; a real working silent IP leak).
- Chat lines but no listener hit => SetUrl is a no-op in shipping too (like TBLWebWidget) -> inert.
Teardown: remove pak + sig.
