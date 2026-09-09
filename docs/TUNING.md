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

Playtested 2026-08-21 on the M1 greybox (`scenes/maps/test_box.tscn`) — that pass was against
the old Quake-derived accel/friction model; the direct velocity-toward-target-speed model below
replaced it on 2026-09-09 and needs its own fresh playtest pass (see the reference note at the
end of this section for why).

| Variable | Value | Notes |
| --- | --- | --- |
| `move_speed` | 260 qu/s | Carried over unchanged from the old model. Still first-pass/needs-playtest under the new accel model, since how quickly you *reach* this speed has changed even though the top speed hasn't. |
| `ground_accel_qu` | 2200.0 | Replaces the old `ground_accel`/`ground_friction`/`stop_speed` trio entirely — there's no more friction curve or stop-speed clamp to tune, just one flat qu/s² rate that `PMove.horizontal_velocity_toward` uses for both starting and stopping. At 2200, 0→`move_speed` takes ~0.12s and 0→sprint speed (~364 qu/s) takes ~0.17s: snappy and direct, matching this project's other single-rate `move_toward` uses (crouch transition, ADS blend, view-bob amplitude smoothing). First pass, needs playtest. |
| `air_accel_qu` | 80.0 | Renamed from `air_accel`, new meaning: a flat qu/s² rate, not a Quake `sv_airaccelerate` coefficient. Deliberately low — over a full jump's ~0.675s hang time (at `jump_velocity_qu`=270, `gravity_qu`=800), this allows at most ~54 qu/s of redirection, about a fifth of `move_speed`. "Near-zero air control," not literally zero: see the reference note below for why this project no longer targets Quake/CS-style air-strafe momentum. First pass, needs playtest. |
| `gravity_qu` | 800 qu/s² | Carried over unchanged. Not a Quake reference anymore (the file it lived in no longer is one) — just a value that already worked. |
| `jump_velocity_qu` | 270 qu/s | Carried over unchanged, same reasoning as `gravity_qu`. |
| `standing_height` | 1.8 m | Not a Quake III value — Quake's own player hull is ~1.42m tall, but that's shorter than this project wants for a modern-scale character. Not yet specifically playtested beyond "works". |
| `crouch_height` | 1.0 m | Same caveat as above. |
| `crouch_speed_scale` | 0.5 | Genre convention (Quake III doesn't reduce crouch speed); not yet playtested in detail. |
| `crouch_transition_speed` | 8 | First-pass value; not yet playtested in detail. |
| `sprint_speed_scale` | **1.4** | Was 1.6. Trimmed slightly alongside the `move_speed` drop so top sprint speed (260 × 1.4 ≈ 364 qu/s, ~9.25 m/s) stays brisk but not superhuman. First pass, not yet playtested in detail. |
| `slide_min_speed` | 300 qu/s | New: sprinting into a crouch triggers a slide instead of an ordinary crouch, matching Phantom Forces' dev-supported slide/dive (community-documented as cooldown-gated, not stamina-gated — no exact numbers published). Set just under sprint top speed (≈364 qu/s) so only a genuine sprint triggers it, not a fast walk. First pass, needs playtest. |
| `slide_duration` | 0.65 s | New. First pass, needs playtest. |
| `slide_speed_boost` | 1.15× | New: the forward lurch Phantom Forces players describe when sprint-crouching. First pass, needs playtest. |
| `slide_decel_qu` | 500.0 | Renamed from `slide_friction`, new meaning: a flat qu/s² deceleration (`PMove.slide_velocity_decay`), not a Quake friction coefficient borrowed from the general ground/air model — that model is gone, so slide gets its own dedicated, much shallower decay instead. A boosted slide from sprint speed (~419 qu/s at `slide_speed_boost`=1.15×364) decays to a stop in ~0.84s, slightly longer than `slide_duration`'s 0.65s, so most slides end via the duration timer rather than by fully stopping. First pass, needs playtest. |
| `slide_cooldown` | 0.8 s | New. First pass, needs playtest. |
| `max_step_height` | 0.3 m | First-pass stair-climb height; not yet stress-tested against the greybox stairs specifically. |
| `floor_max_angle_deg` | 45° | Godot's own default slope limit; unchanged. |
| `mouse_sensitivity` | 0.0025 | Personal preference, not a movement-feel value. Default now lives on the `Settings` autoload (`scripts/core/settings.gd`) — `camera_look.gd`'s own export is just the fallback seeded from it. User-overridable via the pause menu's Settings screen, persisted to `user://settings.cfg`. |
| `bob_cycle_length_qu` | 130 qu | New: view bob. Phase advances with distance travelled rather than wall-clock time, so cadence tracks footwork and speeds up under sprint automatically. First pass, needs playtest. |
| `bob_vertical_amplitude_m` | **0.1** m | New: view bob, vertical component. First value (0.02 m) read as no bob at all on playtest — too small to notice against normal running motion. 0.05 m was tried next, still felt weak; confirmed at 0.1 m by playtest. |
| `bob_side_amplitude_m` | **0.1** m | New: view bob, side-to-side sway at half the vertical frequency. Raised alongside `bob_vertical_amplitude_m` to the same 0.1 m value; confirmed by playtest. |
| `bob_min_speed_qu` | 20 qu/s | New: below this horizontal speed, bob amplitude eases to zero so a barely-moving player doesn't visibly bob. First pass, needs playtest. |
| `bob_max_speed_qu` | 380 qu/s | New: horizontal speed at which bob reaches full amplitude — just above sprint top speed (≈364 qu/s), so sprinting reads as the strongest bob. First pass, needs playtest. |
| `bob_amplitude_smoothing` | 8 | New: eases bob amplitude toward its target rather than snapping, so starting/stopping doesn't pop. First pass, needs playtest. |
| `slide_tilt_deg` | 8° | New: camera roll while sliding — the player's only feedback that a slide (as opposed to an ordinary crouch) is in progress. First pass, needs playtest. |
| `slide_tilt_speed_deg` | 90°/s | New: how fast the slide tilt eases in and back out. First pass, needs playtest. |

**On the Phantom Forces reference:** community sources (Roblox DevForum threads, wiki/guide pages, and community discussion) were sparse on hard numbers — no published sprint multiplier, ADS-slow percentage, or jump/gravity values could be sourced, and none of that is expected to change (those numbers only exist in decompiled/leaked scripts, which this project will not touch per CLAUDE.md's hard rule against proprietary game code). **Correction to an earlier version of this section:** it previously claimed "Phantom Forces' own community explicitly likens its air-strafe/bunnyhop tech to CS-style movement" — that claim does not hold up under closer research and has been removed. What's actually documented is different in kind: PF's "bhop"/"leapslide" tech is a **cooldown-gated chain of discrete triggered actions** (slide → jump → dive, timed keypresses within a window, some gated behind an opt-in Stamina Movement setting that changes cooldowns), not continuous velocity-projection momentum. Speed itself reads as a **direct per-state value** — set per weapon/loadout, with sprint/ADS/crouch applying as instant-or-short-lerp multipliers — rather than something built up through acceleration over time. That's the model this project's `PMove.horizontal_velocity_toward`/`slide_velocity_decay` now target: no momentum carried across a direction change, near-zero (not literal-zero) air control, and slide as its own discrete triggered state rather than an emergent case of the general movement model. No stamina bar by default (sprint is unlimited) and slide/dive gated by cooldown rather than a resource both still hold and are reflected in `slide_cooldown` above. The values above chase that character, not exact numbers — they're first-pass and need playtesting like every other entry in this table.

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
| `ads_speed_scale` | **0.6** (assault rifle) | Flagged during M4 playtesting (see the M4 HUD commit's backlog note) as reading far too slow — but that was compounded by the ramped Quake accel below still easing into the reduced speed rather than hitting it immediately. Briefly raised to 0.8 to compensate, then dropped back to 0.6 (a 40% cut) once ADS accel below went instant and the ramp itself was no longer the problem. Per-weapon now that attachments are coming: this is the assault rifle's value specifically, not a shared default. |
| ADS acceleration | **same rate as ground/air** | Updated post movement-rewrite: ADS is now just another multiplier on `wishspeed` (via `speed_modifier`, still blended smoothly over `ads_transition_time` by `weapon_base.gd`), and velocity converges to that already-scaled target through the same `ground_accel_qu`/`air_accel_qu` rate as ordinary movement — there's no separate instant-snap path anymore. `PMove.ads_active` and `pm_accelerate_instant` are gone as a distinct code path; the "instant" feel this row used to require is now just a byproduct of `ground_accel_qu` already being a snappy, direct rate (~0.12s to full speed). Flag for playtest: if ADS no longer reads as snappy enough sharing the ground rate, that's the first thing to revisit (e.g. a dedicated `ads_accel_qu`). |

## Health

Lives as exported variables on `scripts/weapons/health.gd`. First pass, not yet
playtested.

| Variable | Value | Notes |
| --- | --- | --- |
| `max_health` | 100 | Genre convention. Unchanged since M3. |
| `regen_delay_seconds` | 4 s | How long since the last hit before regen starts. Arbitrary first guess. |
| `regen_rate_per_second` | 40 HP/s | Applied continuously once the delay clears (`Health.regen_step`), not as a lump sum — a full heal from empty takes 2.5 s. Arbitrary first guess. |

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

## Match

Lives as exported variables on `scripts/game/match_state.gd` (the `MatchState` autoload).
First pass, not yet playtested.

| Variable | Value | Notes |
| --- | --- | --- |
| `score_limit` | 30 | Kills needed to end the round. Arbitrary first guess. |
| `time_limit_seconds` | 600 s (10 min) | Matches the roadmap's own M4 "Done when" criterion — "play a full 10-minute match." |
| `friendly_fire_enabled` | false | Off by default per design discussion: when on, damaging a teammate is allowed but never affects the scoreboard either way. |
| `result_display_seconds` | 5 s | How long the round-result banner shows before auto-restart. Arbitrary first guess. |
| `spawn_protection_seconds` | 1 s | Damage immunity granted by every respawn. Confirmed too long at the original 3 s guess (matching `respawn_delay`) during manual playtesting; shortened. |
| `enemy_avoid_radius` | 15 m | Distance a spawn pick avoids a living *enemy* specifically (teammates nearby are fine). Duplicated as its own export on `BotSpawner`, `action_respawn.gd`, `kill_zone.gd`, `MatchState`, and `PMove` — same per-class-export convention `clear_radius` already uses rather than one shared constant. Arbitrary first guess for this small greybox map. |

## Settings

Lives as plain vars on `scripts/core/settings.gd` (the `Settings` autoload), user-overridable
via the pause menu's Settings screen and persisted to `user://settings.cfg`. First pass.

| Variable | Value | Notes |
| --- | --- | --- |
| `fov_degrees` | 90° | Matches the value `Camera3D.fov` already shipped hardcoded in `scenes/player/player.tscn`; now the live, settings-driven default instead. |
| `master_volume_linear` | 1.0 (0 dB) | Applied to Godot's own "Master" audio bus. Inaudible until M6 adds any actual sounds — the control is real and correctly wired, just has nothing to affect yet. |
