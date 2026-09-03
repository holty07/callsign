# Backlog — Callsign

Ideas and forward work noticed in passing, not scoped to the milestone in progress
when they came up. See `docs/ROADMAP.md` for the actual milestone plan; this file is
just a holding pen so nothing gets lost or smuggled into the wrong milestone.

## Already built ahead of schedule

- **Crosshair with dynamic hipfire spread, and a hit-marker cross (white hit /
  yellow headshot / red kill / grey blocked).** Built and playtested during M2
  alongside the weapon it visualises (`scripts/player/crosshair.gd`,
  `scenes/ui/crosshair.tscn`), extended during M4's spawn-protection work.
  Covered the "crosshair with dynamic spread" part of M4's HUD checklist item
  early; the rest (health, ammo, score, killfeed) landed later in the same
  milestone.

- **Player death/respawn flow, and any health HUD.** M3 gave the player a
  `Health`/`HitZone` (same components `DummyTarget` and bots use) purely so bot
  gunfire has something to hit — `Health.died` fires but nothing consumes it yet.
  M4's own checklist ("HUD: health...", match loop, spawn system) is the right
  home for actually handling player death, respawn, and displaying health.

## Noticed during M3 (Bots)

- **M2's weapon values were never backfilled into `docs/TUNING.md`.** The
  Weapons section only got sway values (added alongside M3's bot work) —
  `fire_rate_rpm`, spread, damage/falloff, recoil, and ADS from M2 are still
  undocumented there. Not blocking, but the table's usefulness as "the record
  of what's in play" is incomplete until it's filled in.

- **The M1 greybox's jump gap (between `Platform_Stairs_Top` and
  `Platform_Landing`) disconnects the baked navmesh** — there's no walkable
  surface across it, so bots can't patrol or path into that area at all. Fine
  for now (it's a player-only air-control test), but worth remembering if M5's
  real map has an equivalent gap a designer expects bots to use flanking routes
  around.

- **Bot/player `HitZone` colliders are `StaticBody3D`s that move every physics
  tick** (following their parent `CharacterBody3D`), same pattern `DummyTarget`
  already used while stationary. Transform propagation is immediate so hitscan
  raycasts read the current position correctly, but Godot's own docs steer
  moving colliders toward `AnimatableBody3D` instead. Revisit if hit
  registration ever feels off during fast movement — not observed yet.

- **`action_take_cover.gd` picks the nearest `cover_points` marker by distance
  only** — it doesn't check whether that point actually breaks line of sight
  from the threat. A bot can "take cover" somewhere still fully exposed. Needs
  a line-of-sight check against the threat position (Perception already has
  the raycast plumbing to reuse) before this reads as real tactical behaviour.

- **No agent-to-agent avoidance configured on `NavigationAgent3D`.** Multiple
  bots converging on the same corridor or waypoint will path through each
  other rather than yielding. Godot's navigation avoidance (`avoidance_enabled`
  + radius) would fix this; skipped for M3 since it's polish, not a blocker for
  "competent and fair" bots.

- **No stuck-position logging.** M3's own roadmap "Watch for" note suggests
  logging stuck bot positions to a file to debug nav issues by data — not
  implemented. Worth adding once real playtesting surfaces actual stuck spots,
  rather than guessing where they'll be.

## Noticed during M4 (Match loop) — Team Deathmatch

- **The round-result display window doesn't freeze combat.** Between a round
  ending and `MatchState.restart_round()` firing (`result_display_seconds`,
  5 s default), players/bots can still move and fire. Kills in that window
  just don't score (`register_kill` returns early once `round_over` is true)
  and the restart repositions/heals everyone regardless — a deliberate
  first-pass simplification, not a bug, but a real pause/freeze would read
  better once there's a proper results screen (a later M4 checklist item).
- **Spawn protection is pure damage immunity, first pass.** It doesn't
  restrict the protected combatant's own firing or movement, and doesn't
  break early on taking an action (some games end protection the moment you
  shoot). Simplest version that still solves "spawned right into a kill".
- **`kill_zone.gd`'s environmental insta-kill is also blocked by
  invulnerability** — `Health`'s guard is uniform ("no special-cased
  damage"), so a freshly-spawned combatant could in principle walk into the
  kill zone unharmed for a moment. Harmless in practice since spawn points
  aren't anywhere near it by map design.
- **BUG, needs investigation: the player can stop being able to shoot
  entirely.** Reported during manual playtesting of the spawn-protection/
  hitmarker work (2026-09-03) — no repro steps captured yet. Not yet
  connected to any specific change in this milestone. Once reproducible,
  start with `WeaponBase._can_fire()`'s gates (`_is_reloading`,
  `_fire_cooldown`, `_sprint_release_timer`, the empty-magazine
  auto-reload path) and the new early-returns in `fire()` (friendly-fire
  and spawn-protection blocks) — confirm first whether either is somehow
  left set/true when it shouldn't be, rather than guessing at a fix blind.
- **Killfeed doesn't cover `kill_zone.gd`'s environmental deaths.** Falling
  out of the map never calls `MatchState.register_kill` at all (no
  attacker to report), so a void death is silent in the feed. Consistent
  with everything else about that path (no score either), just noted here
  too.
- **No team-colouring anywhere in the new HUD text** (score labels aside,
  which do use `Bot`'s own default blue/red) — killfeed lines are plain
  white, matching every other "ship ugly" placeholder this milestone.
- **HUD elements are always visible** — none of them hide or reposition
  for the round-result banner, a dead player, or the (still nonexistent)
  pause menu. First pass; revisit once there's an actual menu/results flow
  to coordinate with.
- **ADS movement speed feels far too slow.** Reported during manual
  playtesting of the HUD work (2026-09-03). `WeaponBase.ads_speed_scale`
  (currently `0.6`, blended in via `speed_modifier` in `_update_ads()`) is
  the value to tune — needs a proper playtest pass and a `docs/TUNING.md`
  entry once settled, same as `pmove.gd`'s own movement constants got.
