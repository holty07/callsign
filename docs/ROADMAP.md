# Roadmap — Callsign

Seven milestones to a playable v0.1. Each one ends in something you can run and judge.
Scope is deliberately brutal: **one map, one mode, three weapons, bots by default.**
Everything else is post-v0.1. Scope creep is the failure mode for this project, not
technical difficulty.

Order matters. M1 comes before everything because if the movement doesn't feel right,
nothing built on top of it will either — and you'd rather find that out in week two
than month six.

---

## M0 — Skeleton

Get a repo that builds, tests, and runs an empty scene in CI.

- [x] `project.godot` on Godot 4.7, Forward+ renderer
- [x] Physics tick 120, 3D physics interpolation on, `use_accumulated_input = false`
- [x] `LICENSE` (GPL-2.0-or-later), `README.md`, `CLAUDE.md`, `.gitignore`
      (excludes `.godot/`, `build/`)
- [x] gdUnit4 installed under `addons/`
- [x] GitHub Actions: headless import → run tests → export Linux binary as artefact
- [x] `docs/ASSETS.md` and `docs/TUNING.md` created empty with headers

**Done when:** CI is green on an empty commit and produces a runnable binary.

---

## M1 — Movement

The whole project rests here. Nothing else starts until this feels right.

- [x] `scripts/core/units.gd` — Quake unit constants
- [x] `scripts/player/pmove.gd` — GPL-2.0 port of `PM_Friction` / `PM_Accelerate`,
      with SPDX header and id Software attribution in a file header comment
- [x] Ground move, air move, jump, crouch, sprint, stair stepping, slope handling
- [x] Raw-input mouse look, applied on physics tick
- [x] Greybox test box: flat ground, stairs, ramps, a gap you can only clear with
      correct air accel, a corridor for strafe testing
- [x] Live tuning panel (F1) exposing every movement variable with sliders
- [x] `tests/test_pmove.gd` — friction curve, accel clamp, terminal ground speed,
      air-accel gain, deterministic replay of a fixed input sequence

**Done when:** you can run it, strafe around the test box, and say "yes, that's it."
Spend real time here. Record your final values in `docs/TUNING.md` with notes on why.

---

## M2 — Weapons

One rifle done properly beats three done badly. Build the base system, ship one gun.

- [x] `WeaponBase` — fire rate, magazine, reserve ammo, reload, hipfire spread cone
- [x] Hitscan with per-shot spread, damage falloff by distance, headshot multiplier
- [x] Recoil: deterministic vertical climb + seeded horizontal drift, with recovery
- [x] ADS: FOV shift, movement speed scalar, spread reduction, transition timing
- [x] Weapon-driven movement modifiers (ADS slow, sprint-out delay before firing)
- [x] Placeholder cube-with-a-barrel viewmodel; muzzle flash, tracers, impact decals
- [x] Damage/health system with a dummy target that reports hits

**Done when:** shooting the dummy feels responsive and the recoil pattern is learnable.

---

## M3 — Bots

The headline feature. This is the biggest single chunk of work in the project.

- [x] NavigationRegion3D baked on the test map, verify agent radius against player hull
- [x] Beehave behaviour trees under `addons/`
- [ ] Perception: FOV cone + raycast line-of-sight, with reaction delay and a memory
      of last-known position so bots don't have omniscient tracking
- [ ] Behaviours: patrol, investigate noise, engage, take cover, reposition, retreat
      at low health, respawn
- [ ] Aim model: turn rate limit, error cone, burst discipline, target reacquisition
- [ ] Difficulty tiers driven by reaction delay / aim error / spread, not health cheats
- [ ] Bots use the same weapon system as the player — no special-cased damage
- [ ] Bot count and difficulty configurable at match start, default: on

**Done when:** a 4-bot free-for-all is winnable but not trivial, and bots don't get
stuck on geometry over a 10-minute match.

**Watch for:** this milestone will want to expand forever. Ship "competent and fair",
not "human-like". Log stuck positions to a file so you can fix nav issues by data.

---

## M4 — Match loop

Turn the sandbox into a game.

- [ ] Team Deathmatch: two teams, score limit, time limit, round end and restart
- [ ] Spawn system with enemy-proximity avoidance and spawn protection window
- [ ] HUD: health, ammo, score, killfeed, crosshair with dynamic spread
- [ ] Pause and settings menus: sensitivity, FOV, keybinds, volume, bot count
- [ ] Main menu → match start → results → back to menu, with no crashes

**Done when:** you can launch, play a full 10-minute match, and return to menu cleanly.

---

## M5 — One real map

Replace the greybox with something intentionally designed.

- [ ] Layout on paper first: three lanes, connected flanks, no dead ends, clear
      sightline hierarchy. Steal the *principles* of good multiplayer maps, never
      the geometry of an existing one.
- [ ] Blockout in Godot with CSG, playtest against bots, iterate before art
- [ ] Modular CC0 kit (Kenney, Quaternius) for walls, floors, props
- [ ] Lighting pass, occlusion culling, navmesh rebake
- [ ] Every asset logged in `docs/ASSETS.md`

**Done when:** matches on it produce varied engagements rather than one chokepoint.

---

## M6 — Art and audio pass

- [ ] Player and bot character models (Quaternius CC0), retargeted animations from a
      CC0 source — **not Mixamo**, see CLAUDE.md rule 4
- [ ] Weapon model, first-person animation set (idle, fire, reload, ADS, sprint)
- [ ] Audio: weapon fire, impacts, footsteps, reload foley, UI (Freesound CC0)
- [ ] Materials from ambientCG / Poly Haven, skybox HDRI
- [ ] Consistent art direction — pick stylised-realistic and hold the line; mixing
      asset packs of different fidelity is what makes free-asset games look cheap

**Done when:** a screenshot doesn't immediately read as a prototype.

---

## M7 — Release v0.1

- [ ] Performance pass: 120fps target on your hardware, profile the bot AI cost
- [ ] AppImage and Flatpak builds, tagged release via CI on `v*`
- [ ] README with screenshots, build instructions, contribution guide
- [ ] `docs/ASSETS.md` audited — every file accounted for
- [ ] Publish to itch.io, post to r/godot and r/linux_gaming

---

## Deliberately out of scope for v0.1

Online multiplayer. Killstreaks. Perks and loadout customisation. A second map or
mode. Campaign. Console support. Anti-cheat. Progression systems.

Online multiplayer in particular means client-side prediction and lag compensation —
the hardest problem available to you here. Bots exist precisely so you don't need it.
Revisit only once v0.1 is out and holding up.
