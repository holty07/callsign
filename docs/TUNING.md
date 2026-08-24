# Tuning — Callsign

Movement and weapon constants live as exported variables on scenes, not as magic
numbers inline. This file records the values in play and the reasoning behind them,
so a change can be judged against its rationale rather than re-litigated from scratch.

See CLAUDE.md — "Movement — the core of the project" for the non-negotiables these
values must respect.

## Movement

All values live as exported variables on `scripts/player/pmove.gd` (and
`camera_look.gd` for sensitivity) — this is a record of what's in play, not
the source of truth; if this ever drifts from the scene, the scene wins.

Playtested 2026-08-21 on the M1 greybox (`scenes/maps/test_box.tscn`).

| Variable | Value | Notes |
| --- | --- | --- |
| `move_speed` | **260** qu/s | Quake III default is 320 (`sv_speed`). Dropped to pull the pace back from Quake's arena-shooter sprint toward the grounded, military-shooter feel this project targets, and to move toward Phantom Forces (Roblox), which the project is now using as a feel reference — its own numbers (guns cluster around a Roblox humanoid walkspeed of 12-16 studs/s, vs. its default of 16) point the same direction, though studs don't convert cleanly to Quake units so this is a first pass, not a derived value. Pending playtest confirmation. |
| `ground_accel` | 10 | Quake III's `sv_accelerate`. Unchanged. |
| `ground_friction` | **10** | Quake III default is 6. Even after the `stop_speed` fix below, full-speed stops still decayed exponentially over most of a second before friction's linear "control" clamp took over — read as sliding on the ground, more arena shooter than military shooter. Raised to 10 to shrink that exponential window to a handful of ticks so releasing input reads as a hard stop. Confirmed still correct against the Phantom Forces reference: `ground_friction` only applies while grounded (`PM_Friction`'s `grounded` gate), so it governs stopping on the ground, not the airborne strafe-jump/bunnyhop tech Phantom Forces' own community explicitly likens to CS — that's `air_accel`, kept unchanged below, so this project keeps both a firm ground stop and full air control. |
| `stop_speed` | 200 qu/s | Quake III default is 100. `PM_Friction` only clamps its friction "control" value up to `stop_speed` below that threshold (`control = speed < stop_speed ? stop_speed : speed`), so at 100 the player kept gliding for a beat after releasing input before friction really bit — read as floaty. Raised to 200 so friction firms up sooner while slowing down. Confirmed by playtest. |
| `air_accel` | 1 | Quake III's `sv_airaccelerate`. Deliberately unchanged: Phantom Forces' own community compares its air-strafe/bunnyhop tech to CS-style movement, not a CoD-style fixed air trajectory, so the momentum-preserving air control this project's Quake-derived `PM_Accelerate` already gives is a feature to keep, not a bug to tune out. |
| `gravity_qu` | 800 qu/s² | Quake III's `sv_gravity`. Unchanged. |
| `jump_velocity_qu` | 270 qu/s | Quake III's jump impulse. Unchanged. |
| `standing_height` | 1.8 m | Not a Quake III value — Quake's own player hull is ~1.42m tall, but that's shorter than this project wants for a modern-scale character. Not yet specifically playtested beyond "works". |
| `crouch_height` | 1.0 m | Same caveat as above. |
| `crouch_speed_scale` | 0.5 | Genre convention (Quake III doesn't reduce crouch speed); not yet playtested in detail. |
| `crouch_transition_speed` | 8 | First-pass value; not yet playtested in detail. |
| `sprint_speed_scale` | **1.4** | Was 1.6. Trimmed slightly alongside the `move_speed` drop so top sprint speed (260 × 1.4 ≈ 364 qu/s, ~9.25 m/s) stays brisk but not superhuman. First pass, not yet playtested in detail. |
| `slide_min_speed` | 300 qu/s | New: sprinting into a crouch triggers a slide instead of an ordinary crouch, matching Phantom Forces' dev-supported slide/dive (community-documented as cooldown-gated, not stamina-gated — no exact numbers published). Set just under sprint top speed (≈364 qu/s) so only a genuine sprint triggers it, not a fast walk. First pass, needs playtest. |
| `slide_duration` | 0.65 s | New. First pass, needs playtest. |
| `slide_speed_boost` | 1.15× | New: the forward lurch Phantom Forces players describe when sprint-crouching. First pass, needs playtest. |
| `slide_friction` | 2.0 | New: far below `ground_friction` (10) so a slide actually carries — decays from boosted sprint speed to `stop_speed`'s 200 qu/s floor in roughly a third of a second, per `PM_Friction`'s math, leaving the rest of `slide_duration` at the shallower linear decay below that. First pass, needs playtest. |
| `slide_cooldown` | 0.8 s | New. First pass, needs playtest. |
| `max_step_height` | 0.3 m | First-pass stair-climb height; not yet stress-tested against the greybox stairs specifically. |
| `floor_max_angle_deg` | 45° | Godot's own default slope limit; unchanged. |
| `mouse_sensitivity` | 0.0025 | Personal preference, not a movement-feel value. |

**On the Phantom Forces reference:** community sources (Roblox DevForum threads, wiki/guide pages, and player comparisons to CS2) were sparse on hard numbers — no published sprint multiplier, ADS-slow percentage, or jump/gravity values could be sourced. What is well-supported is the *character* of the movement: momentum-retaining with working air-strafe/bunnyhop tech (not a CoD-style instant stop), no stamina bar (sprint is unlimited), and an official slide/dive move gated by a cooldown rather than a resource. The values above chase that character, not exact numbers — they're first-pass and need playtesting like every other entry in this table.

## Weapons

_Populated in M2._
