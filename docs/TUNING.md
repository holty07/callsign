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
| `move_speed` | 320 qu/s | Quake III's own default (`sv_speed`). Kept as-is — the whole point of the port was to get this feel, and it playtested fine unchanged. |
| `ground_accel` | 10 | Quake III's `sv_accelerate`. Unchanged. |
| `ground_friction` | **10** | Quake III default is 6. Even after the `stop_speed` fix below, full-speed stops still decayed exponentially over most of a second before friction's linear "control" clamp took over — read as sliding on the ground, more arena shooter than military shooter. Raised to 10 to shrink that exponential window to a handful of ticks so releasing input reads as a hard stop. Pending playtest confirmation. |
| `stop_speed` | **200** qu/s | Quake III default is 100. `PM_Friction` only clamps its friction "control" value up to `stop_speed` below that threshold (`control = speed < stop_speed ? stop_speed : speed`), so at 100 the player kept gliding for a beat after releasing input before friction really bit — read as floaty. Raised to 200 so friction firms up sooner while slowing down. Confirmed by playtest. |
| `air_accel` | 1 | Quake III's `sv_airaccelerate`. Unchanged. |
| `gravity_qu` | 800 qu/s² | Quake III's `sv_gravity`. Unchanged. |
| `jump_velocity_qu` | 270 qu/s | Quake III's jump impulse. Unchanged. |
| `standing_height` | 1.8 m | Not a Quake III value — Quake's own player hull is ~1.42m tall, but that's shorter than this project wants for a modern-scale character. Not yet specifically playtested beyond "works". |
| `crouch_height` | 1.0 m | Same caveat as above. |
| `crouch_speed_scale` | 0.5 | Genre convention (Quake III doesn't reduce crouch speed); not yet playtested in detail. |
| `crouch_transition_speed` | 8 | First-pass value; not yet playtested in detail. |
| `sprint_speed_scale` | 1.6 | Not a Quake III mechanic; first-pass value, not yet playtested in detail. |
| `max_step_height` | 0.3 m | First-pass stair-climb height; not yet stress-tested against the greybox stairs specifically. |
| `floor_max_angle_deg` | 45° | Godot's own default slope limit; unchanged. |
| `mouse_sensitivity` | 0.0025 | Personal preference, not a movement-feel value. |

## Weapons

_Populated in M2._
