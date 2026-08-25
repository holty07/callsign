# Tuning — Callsign

Movement and weapon constants live as exported variables on scenes, not as magic
numbers inline. This file records the values in play and the reasoning behind them,
so a change can be judged against its rationale rather than re-litigated from scratch.

See CLAUDE.md — "Movement — the core of the project" for the non-negotiables these
values must respect.

## Movement

All values live as exported variables on `scripts/player/pmove.gd` (and
`camera_look.gd` for sensitivity, view bob, and slide tilt) — this is a
record of what's in play, not the source of truth; if this ever drifts from
the scene, the scene wins.

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
| `bob_cycle_length_qu` | 130 qu | New: view bob. Phase advances with distance travelled rather than wall-clock time, so cadence tracks footwork and speeds up under sprint automatically. First pass, needs playtest. |
| `bob_vertical_amplitude_m` | **0.1** m | New: view bob, vertical component. First value (0.02 m) read as no bob at all on playtest — too small to notice against normal running motion. 0.05 m was tried next, still felt weak; confirmed at 0.1 m by playtest. |
| `bob_side_amplitude_m` | **0.1** m | New: view bob, side-to-side sway at half the vertical frequency. Raised alongside `bob_vertical_amplitude_m` to the same 0.1 m value; confirmed by playtest. |
| `bob_min_speed_qu` | 20 qu/s | New: below this horizontal speed, bob amplitude eases to zero so a barely-moving player doesn't visibly bob. First pass, needs playtest. |
| `bob_max_speed_qu` | 380 qu/s | New: horizontal speed at which bob reaches full amplitude — just above sprint top speed (≈364 qu/s), so sprinting reads as the strongest bob. First pass, needs playtest. |
| `bob_amplitude_smoothing` | 8 | New: eases bob amplitude toward its target rather than snapping, so starting/stopping doesn't pop. First pass, needs playtest. |
| `slide_tilt_deg` | 8° | New: camera roll while sliding — the player's only feedback that a slide (as opposed to an ordinary crouch) is in progress. First pass, needs playtest. |
| `slide_tilt_speed_deg` | 90°/s | New: how fast the slide tilt eases in and back out. First pass, needs playtest. |

**On the Phantom Forces reference:** community sources (Roblox DevForum threads, wiki/guide pages, and player comparisons to CS2) were sparse on hard numbers — no published sprint multiplier, ADS-slow percentage, or jump/gravity values could be sourced. What is well-supported is the *character* of the movement: momentum-retaining with working air-strafe/bunnyhop tech (not a CoD-style instant stop), no stamina bar (sprint is unlimited), and an official slide/dive move gated by a cooldown rather than a resource. The values above chase that character, not exact numbers — they're first-pass and need playtesting like every other entry in this table.

## Weapons

Firing, spread, damage, recoil, and ADS values from M2 aren't logged here yet —
still to be backfilled. Weapon sway (M1/M2 polish, added alongside view bob) is
recorded below; it lives as exported variables on `scripts/weapons/weapon_base.gd`,
sharing its bob math with `camera_look.gd`'s view bob via `scripts/core/view_bob.gd`
so the gun reads as following the same footstep as the camera, not wobbling on
its own.

| Variable | Value | Notes |
| --- | --- | --- |
| `sway_cycle_length_qu` | 130 qu | New: matches `bob_cycle_length_qu` so the gun's cadence lines up with the camera's. First pass, needs playtest. |
| `sway_vertical_amplitude_m` | 0.015 m | New. Kept below the camera's view bob amplitude — the gun should read as trailing the camera's motion, not matching it 1:1. First pass, needs playtest. |
| `sway_side_amplitude_m` | 0.025 m | New. First pass, needs playtest. |
| `sway_min_speed_qu` | 20 qu/s | New: matches `bob_min_speed_qu`. First pass, needs playtest. |
| `sway_max_speed_qu` | 380 qu/s | New: matches `bob_max_speed_qu`. First pass, needs playtest. |
| `sway_amplitude_smoothing` | 8 | New: matches `bob_amplitude_smoothing`. First pass, needs playtest. |

## Bots

Difficulty tiers (`scripts/bots/bot_difficulty.gd`, presets in `scenes/bots/difficulty_*.tres`)
are the only place bot skill is tuned — per the roadmap, driven by reaction delay, aim error,
and spread, never health or damage. `Bot.apply_difficulty()` pushes a tier's values onto that
bot's own `Perception`/`BotAim`/`WeaponBase` instances only; every other actor is untouched.

| Tier | `reaction_delay` | `memory_duration` | `fov_deg` | `error_cone_deg` | `turn_rate_deg` | `hipfire_spread_deg` |
| --- | --- | --- | --- | --- | --- | --- |
| Easy | 0.6 s | 3.0 s | 90° | 6.0° | 140°/s | 5.0° |
| Normal | 0.25 s | 5.0 s | 100° | 3.0° | 220°/s | 3.0° |
| Hard | 0.1 s | 8.0 s | 110° | 1.0° | 320°/s | 1.5° |

First pass, not yet playtested — Normal matches the values `Perception`/`BotAim`/`WeaponBase`
already shipped with in earlier M3 commits; Easy and Hard are symmetric first-guess spreads
around it, not derived from anything. All other bot values (Perception's view_distance,
BotAim's burst/reacquisition timing, WeaponBase's damage/recoil/fire rate) are shared across
tiers — only the six columns above vary.
