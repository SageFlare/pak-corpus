# Live-testing attempt paks (setting the three-state label)

The `attempted` vs `malicious` label must be confirmed empirically, not assumed. This is the
one step that needs the real game via Unchained. **Do it on a test install (or a VM/backup)**,
never your only copy — a replacement pak overwrites a game asset until removed.

General safety:
- Back up or note the original state first.
- Install one sample at a time.
- Always remove the sample pak **and** its `.sig` afterward to restore the game.
- **Offline / own server only.** Chivalry 2 runs EasyAntiCheat. Loading modded paks is what
  Unchained is designed for, but do these tests **offline or on your own server**, never on
  official matchmaking, so anti-cheat never sees a modded session on your account.
- These two samples are audited inert: the LaunchURL BP only opens
  `http://127.0.0.1/PAKSEC_BEACON` (loopback, dead page — nothing leaves your PC); the
  replacement is a cosmetic magenta material with no logic. Worst cases: a browser tab opens to
  a localhost "can't connect" page, or some UI lines render magenta until you remove the pak.

## Install a sample

1. Copy `samples\<sample>.pak` into your Chivalry 2 Paks folder:
   `<Chivalry 2>\TBL\Content\Paks\`
2. Give it a `.sig` (required to load): copy an existing `.sig` next to it and rename to match
   (e.g. copy `zz_FFA_Nuketown.sig` → `<sample>.sig`), or let the Unchained launcher sign it.
3. Launch Chivalry 2 **through the Unchained launcher**.

## launch_url_attempt — did LaunchURL fire?

Watch for the outbound request to the inert sentinel `http://127.0.0.1/PAKSEC_BEACON`:
- Before launching, start a loopback listener so you can see a hit:
  `python -m http.server 80`  (run in a terminal; it logs any GET to `/PAKSEC_BEACON`)
  (If port 80 needs admin, use `python -m http.server 8080` and set the BP URL to `:8080`.)
- Load into a match/map where the BP's actor spawns (the BP must be placed or auto-spawned for
  BeginPlay to run; if it is just an unreferenced asset, it will NOT fire — that is itself the
  finding).
- **Browser opens / listener logs the GET** → the node fired → label `malicious`.
- **Nothing happens** (node present but never reached/compiled out) → label `attempted`.

## asset_replacement_attempt — did the swap take effect?

- Go to the UI/screen that uses `M_DetailLine_gradient` (loading-screen / HUD detail lines).
- **The magenta stand-in shows instead of the original** → replacement took effect → `malicious`.
- **Original still shows** (game ignored/overrode the mod) → `attempted`.

## Record the result

For each sample, set `expected_state` in `manifest.json` to the observed state and add a
`notes` line citing what you saw (e.g. "listener logged GET /PAKSEC_BEACON on map load →
malicious, 2026-10-06"). Then run `pak-corpus-validate` and commit.

## Teardown

Delete `<sample>.pak` and `<sample>.sig` from the Paks folder. For the replacement sample,
confirm the original UI material is back (relaunch and check the screen).
