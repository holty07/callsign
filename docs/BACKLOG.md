# Backlog — Callsign

Ideas and forward work noticed in passing, not scoped to the milestone in progress
when they came up. See `docs/ROADMAP.md` for the actual milestone plan; this file is
just a holding pen so nothing gets lost or smuggled into the wrong milestone.

## Already built ahead of schedule

- **Crosshair with dynamic hipfire spread, and a hit-marker cross (white hit /
  yellow headshot / red kill).** Built and playtested during M2 alongside the
  weapon it visualises (`scripts/player/crosshair.gd`, `scenes/ui/crosshair.tscn`).
  This covers the "crosshair with dynamic spread" part of M4's HUD checklist item
  early. M4 still needs: health, ammo, score, and killfeed HUD elements, plus
  wiring the hit-marker feed into a real killfeed once teams/scoring exist.

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
