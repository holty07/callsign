# CLAUDE.md — Callsign

Standing context for Claude Code. Read this before touching anything.

## What this project is

**Callsign** is an original, open-source, arena-style military FPS built in Godot 4.7,
inspired by the movement and gunplay feel of late-2000s military shooters. Bots are
enabled by default — the game is playable solo, offline, with no server required.

It is **not** a Call of Duty port, remake, or asset-compatible clone. No proprietary
code, assets, map geometry, sound, or trademarked names may enter this repository.
See "Hard rules" below.

Target platform: Linux (x86_64) first. Windows and macOS are secondary and untested.

## Licensing

**Code: GPL-2.0-or-later.** This is deliberate, not incidental. `scripts/player/pmove.gd`
is a derivative of Quake III Arena's movement code, which id Software released under
GPL-2.0. A permissive licence would be a conflict. GPL-2.0-or-later is compatible with
Godot's MIT-licensed engine, so distributing a Godot export is fine.

Every source file carries an SPDX header as its first line:

```gdscript
# SPDX-License-Identifier: GPL-2.0-or-later
```

**Assets: tracked separately.** The GPL covers code only. Art, audio and other assets
keep their own licences (CC0, CC-BY, etc.) and are recorded per-file in
`docs/ASSETS.md`. Do not assume an asset inherits the project licence, and do not
relicense third-party assets.

Any CC-BY asset requires visible attribution in the in-game credits screen, not just
the ledger. Prefer CC0 to avoid the obligation entirely.

## Hard rules — never break these

1. **No proprietary assets or code.** Do not add, reference, decompile, extract, or
   convert anything from a commercial game. If a task seems to require it, stop and
   raise it instead of improvising.
2. **No trademarked names** in code, assets, UI copy, or docs. No "Call of Duty",
   "Modern Warfare", "Infinity Ward", real weapon trade names, or real military unit
   insignia. Use invented designations.
3. **Every asset gets a ledger entry.** Any file added under `assets/` requires a
   matching row in `docs/ASSETS.md` (path, source URL, author, licence, date). No
   entry, no commit.
4. **No Mixamo animations.** Adobe's licence permits use in projects but restricts
   redistributing the animation files themselves — which an open repo does by
   definition. Use CC0 sources only.
5. **Never commit** `.godot/`, `.import` caches, exported binaries, or `*.tmp`.

## Movement — the core of the project

Movement feel is the single most important thing in this game. It is a GDScript port
of Quake III Arena's `PM_Friction` and `PM_Accelerate` (GPL-2.0, id Software), living
in `scripts/player/pmove.gd`. That file must carry a header comment attributing id
Software and naming the upstream source, in addition to the SPDX line.

Non-negotiables:

- **Fixed tick only.** All movement runs in `_physics_process`. Never `_process`.
  `physics/common/physics_ticks_per_second = 120`, 3D physics interpolation enabled.
- **Raw mouse input.** `Input.use_accumulated_input = false`. Accumulate raw
  `InputEventMouseMotion` and apply on the physics tick. Do not add smoothing,
  acceleration, or filtering to look input, ever.
- **Quake units throughout.** `const QU_TO_M := 0.0254` is defined once in
  `scripts/core/units.gd`. All movement constants stay in Quake units so documented
  tuning values can be dropped in directly. Convert only at the rendering boundary.
- **The projection is the point.** `PM_Accelerate` projects current velocity onto the
  desired direction *before* clamping the acceleration delta. That single line is what
  produces the momentum and air control. Do not "simplify" it.
- Tuning values live in exported variables on the player scene and are mirrored in
  `docs/TUNING.md`. Change values there, not by editing magic numbers inline.

Any PR touching `pmove.gd` must include or update tests in `tests/test_pmove.gd`.

## Conventions

**GDScript**
- Static typing everywhere: `var speed: float = 0.0`, typed function signatures.
- `snake_case` for files, variables, functions. `PascalCase` for classes and nodes.
- Private members prefixed `_`.
- One class per file, `class_name` declared at top where the type is reused.
- Prefer composition (child nodes) over deep inheritance.

**Scenes**
- `.tscn` and `.tres` only — never binary `.scn`/`.res`. They must stay diffable.
- Scenes are built by editing `.tscn` text directly where practical. Keep node paths
  stable; renaming nodes breaks references silently.

**Copy and docs**
- Australian English in all documentation, comments, and player-facing UI text
  (colour, armour, customise, centre, organise).

**Commits**
- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
- Reference the milestone issue: `feat(bots): add navmesh baking (#23)`.
- One logical change per commit. Do not bundle asset imports with code changes.

## Commands

```bash
# Run the game
godot --path . 

# Run tests headless (gdUnit4)
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/

# Reimport assets after adding files (required before headless test runs)
godot --headless --path . --import

# Export a Linux build
godot --headless --path . --export-release "Linux/X11" build/callsign.x86_64
```

Godot must be 4.7.x. On CachyOS: `paru -S godot` or use the official binary from
godotengine.org — do not use the Flatpak for development, its sandbox complicates
headless CI and asset paths.

## Repository layout

```
callsign/
├── CLAUDE.md
├── LICENSE                  # GPL-2.0-or-later (US spelling — GitHub detection)
├── project.godot
├── .claude/commands/        # custom slash commands
├── .github/workflows/ci.yml
├── addons/                  # gdUnit4, Beehave (behaviour trees)
├── assets/                  # third-party CC0 art/audio — ledger required
├── docs/
│   ├── ROADMAP.md
│   ├── ASSETS.md            # licence ledger
│   └── TUNING.md            # movement/weapon values and rationale
├── scenes/
│   ├── player/
│   ├── weapons/
│   ├── bots/
│   ├── maps/
│   └── ui/
├── scripts/
│   ├── core/                # units, constants, autoloads
│   ├── player/              # pmove.gd, camera, input
│   ├── weapons/             # base weapon, hitscan, recoil
│   ├── bots/                # navigation, behaviour tree tasks, perception
│   └── game/                # match state, scoring, spawns
└── tests/
```

## Working style

- Work one milestone at a time. Do not start milestone N+1 work while N is open.
- Prefer a working ugly version first, then refine. Greybox before art.
- When a task is ambiguous, ask rather than guessing at design intent — especially
  anything touching movement feel, which cannot be judged from code alone.
- Every milestone ends with something runnable. If it doesn't run, it isn't done.
