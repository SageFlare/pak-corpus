# Vector: LaunchURL

**What:** A Blueprint in a mod pak calls the stock **LaunchURL** node (KismetSystemLibrary),
which opens a URL in the user's default browser. Unlike arbitrary HTTP or file I/O (which need
C++ plugins a pak cannot ship), `LaunchURL` is a built-in node available to any Blueprint, so a
pak-only mod can reach it.

**Why it matters:** A mod that opens a browser URL on load is a nuisance and a
social-engineering / tracking vector — it can send the player to a phishing page, an ad, or a
URL that fingerprints them, just by being loaded. It is one of the few genuinely dangerous
native nodes reachable from a pak in a shipping build.

**Inert sample:** `samples/launch_url_attempt.pak` — an Actor Blueprint whose Event BeginPlay
calls `LaunchURL("http://127.0.0.1/PAKSEC_BEACON")`, an inert loopback sentinel that contacts
nothing real. Authored by hand (UE 4.25 Python cannot wire BP graph nodes) per
`authoring/launch_url.md`.

**Scanner detection:** the `launch_url` rule loads each Blueprint asset and checks its name
table for `LaunchURL`. Presence is flagged (an attempt); whether it is actually wired to run is
a Phase 2 reachability refinement.

**Find it manually:** extract the pak and inspect Blueprint assets for the node name:
```
UnrealPak.exe mod.pak -Extract <dir>
grep -ai "LaunchURL" <dir>/*.uasset
```
A gameplay Blueprint that references `LaunchURL` is worth scrutinizing — legit mods rarely open
browser URLs on load.
