# Chivalry 2 BlueprintCallable surface — dangerous-node reflection

Parsed from C++ headers (ArgonSDK/Source = the Chiv2 `TBL` module a modder sees, + engine
Kismet/GameFramework/Online) by `authoring/scripts/extract_bp_callable.py`. Each node's
**dev_only** is read from its `UFUNCTION(... DevelopmentOnly ...)` metadata — the same flag that
strips Print String from Shipping builds. A dev-only node is unlikely usable in retail.

## Summary

- BlueprintCallable functions parsed: **5414**
- Dev-only (stripped from Shipping, unlikely usable): **22**
- Flagged dangerous (URL/file/process/net/analytics patterns): **24**
  - of which shipping-live (NOT dev-only): **24**
  - of which dev-only (unlikely usable): **0**

## Dangerous nodes (triage list — a human judges each)

| function | why | dev_only | header | scanner status |
| --- | --- | --- | --- | --- |
| AnalyticsEventClickedOnCampaignProgress | analytics | False | AnalyticsUtilitiesLibrary.h | not yet a rule - review |
| AnalyticsEventClosedMenuScreen | analytics | False | AnalyticsUtilitiesLibrary.h | not yet a rule - review |
| AnalyticsEventDeveloperMessageClickedUrl | analytics | False | AnalyticsUtilitiesLibrary.h | not yet a rule - review |
| AnalyticsEventOpenedMenuScreen | analytics | False | AnalyticsUtilitiesLibrary.h | not yet a rule - review |
| AsyncLoadGameFromSlot | loadgamefromslot | False | AsyncActionHandleSaveGame.h | not yet a rule - review |
| AsyncSaveGameToSlot | savegametoslot | False | AsyncActionHandleSaveGame.h | not yet a rule - review |
| LoadGameFromSlot | loadgamefromslot | False | GameplayStatics.h | not yet a rule - save sandbox read |
| SaveGameToSlot | savegametoslot | False | GameplayStatics.h | not yet a rule - sandboxed to Saved/SaveGames/*.sav (can't drop a pak) |
| CanLaunchURL | launchurl | False | KismetSystemLibrary.h | not flagged (pure bool check, not an action) |
| ExecuteConsoleCommand | consolecommand,executeconsolecommand | False | KismetSystemLibrary.h | not yet a rule - review |
| LaunchURL | launchurl | False | KismetSystemLibrary.h | flagged (launch_url) - LIVE-CONFIRMED fires in retail |
| GetCameraSocketLocation | socket | False | TBLCharacter.h | not yet a rule - review |
| SendToAll | sendto | False | TBLCheatManager.h | not yet a rule - review |
| SendToTrace | sendto | False | TBLCheatManager.h | not yet a rule - review |
| AnalyticsQuery | analytics | False | TBLPlayerController.h | not yet a rule - review |
| DrawSocket | socket | False | TBLPlayerController.h | not yet a rule - review |
| ServerRequestAnalyticsStart | analytics | False | TBLPlayerController.h | not yet a rule - review |
| ServerRequestAnalyticsStop | analytics | False | TBLPlayerController.h | not yet a rule - review |
| ServerSendOfflineAnalyticsEvent | analytics | False | TBLPlayerController.h | not yet a rule - review |
| ServerStopAnalytics | analytics | False | TBLPlayerController.h | not yet a rule - review |
| StopAnalytics | analytics | False | TBLPlayerController.h | not yet a rule - review |
| FindClosestSocket | socket | False | TBLUtilityLibrary.h | not yet a rule - review |
| BrowseToUrl | browsetourl | False | TBLWebWidget.h | flagged (web_widget) - live-tested INERT in retail (CEF stripped) |
| OnImageDownloaded | download | False | WebImageWidget.h | NOT yet investigated - WebImageWidget image-from-URL fetch (possible silent beacon) |

## Dev-only nodes (for reference; stripped from Shipping)

AddFloatHistorySample, DrawDebugArrow, DrawDebugBox, DrawDebugCamera, DrawDebugCapsule, DrawDebugCircle, DrawDebugCone, DrawDebugConeInDegrees, DrawDebugCoordinateSystem, DrawDebugCylinder, DrawDebugFloatHistoryLocation, DrawDebugFloatHistoryTransform, DrawDebugFrustum, DrawDebugLine, DrawDebugPlane, DrawDebugPoint, DrawDebugSphere, DrawDebugString, FlushDebugStrings, FlushPersistentDebugLines, PrintString, PrintText

## Limitations

- Covers classes with headers (SDK + engine). Binary-only/closed plugins without headers are
  NOT covered. UE 4.25 in-editor Python can't walk function metadata (verified), so headers
  are the authoritative dev-only source.
- `dangerous` is a name/category keyword triage, not a verdict — review each; some are benign
  (e.g. GetCameraSocketLocation/DrawSocket/FindClosestSocket matched 'socket' but are bone/skeletal
  sockets, not network sockets; the analytics events send fixed payloads to Chiv2's own backend).
- **dev_only vs shipping-stripped are two different mechanisms.** `ExecuteConsoleCommand` shows
  dev_only=False (no DevelopmentOnly metadata) yet the CONSOLE is still compiled out of Shipping —
  that stripping is build-config, not the metadata flag. So dev_only=False means "not metadata-dev-
  only"; it does not guarantee the capability works in retail. Live testing remains the final word
  (LaunchURL confirmed live; BrowseToUrl confirmed inert despite dev_only=False).
- **Lead to investigate:** `OnImageDownloaded` / `WebImageWidget.h` — an image-from-URL fetcher that
  could be a silent beacon like TBLWebWidget. Not yet examined.
- Full per-node data (all 5000+) is in `bp_callable.json`.
