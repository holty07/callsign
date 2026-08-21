# Callsign

An original, open-source, arena-style military FPS built in Godot 4.7, inspired by
the movement and gunplay feel of late-2000s military shooters. Bots are enabled by
default — the game is playable solo, offline, with no server required.

Callsign is not a Call of Duty port, remake, or asset-compatible clone. No
proprietary code, assets, map geometry, sound, or trademarked names appear in this
repository. See `CLAUDE.md` for the full set of hard rules.

Target platform: Linux (x86_64) first. Windows and macOS are secondary and untested.

## Status

Pre-alpha. See `docs/ROADMAP.md` for the milestone plan — one map, one mode, three
weapons, bots by default, with everything else deliberately out of scope for v0.1.

## Building and running

Requires Godot 4.7.x.

```fish
# Run the game
godot --path .

# Run tests headless (gdUnit4)
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/

# Reimport assets after adding files (required before headless test runs)
godot --headless --path . --import

# Export a Linux build
godot --headless --path . --export-release "Linux/X11" build/callsign.x86_64
```

## Licensing

Code is GPL-2.0-or-later — see `LICENSE`. This is deliberate: `scripts/player/pmove.gd`
is a derivative of Quake III Arena's movement code (id Software, GPL-2.0), and a
permissive licence would conflict with that.

Assets keep their own licences (CC0, CC-BY, etc.), tracked per-file in
`docs/ASSETS.md`. Do not assume an asset inherits the project licence.

## Contributing

Read `CLAUDE.md` before opening a PR — it covers hard rules on assets and
trademarks, coding conventions, and the milestone-based working style.
