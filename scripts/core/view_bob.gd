# SPDX-License-Identifier: GPL-2.0-or-later
class_name ViewBob

## Shared bob/sway math used by both scripts/player/camera_look.gd (view bob)
## and scripts/weapons/weapon_base.gd (weapon sway), so the camera and the
## gun read as the same footstep rather than two unrelated wobbles. Kept
## static and side-effect free so it's unit-testable without a live
## PMove/Camera3D/WeaponBase.

## Advances the bob cycle by the distance travelled this tick, expressed as
## a fraction of a full cycle — so cadence tracks footwork, not time. Wrapped
## to [0, TAU) so it can run indefinitely without losing float precision.
static func advance_phase(phase: float, horizontal_speed_qu: float, cycle_length_qu: float, delta: float) -> float:
	if cycle_length_qu <= 0.0:
		return phase
	return wrapf(phase + (horizontal_speed_qu * delta / cycle_length_qu) * TAU, 0.0, TAU)


## Linear ramp from 0 at min_speed_qu to 1 at max_speed_qu, so a barely-moving
## player doesn't visibly bob and a sprinting one bobs at full amplitude.
static func amplitude_scale(horizontal_speed_qu: float, min_speed_qu: float, max_speed_qu: float) -> float:
	if max_speed_qu <= min_speed_qu:
		return 0.0
	return clampf((horizontal_speed_qu - min_speed_qu) / (max_speed_qu - min_speed_qu), 0.0, 1.0)


## Quake/Source-style bob: vertical motion uses abs(sin) so every step reads
## as a dip (never a lift), while the side-to-side sway runs at half that
## frequency, crossing the midline once per full step cycle rather than once
## per half-step. Caller scales the result by an amplitude scale.
static func offset(phase: float, vertical_amplitude_m: float, side_amplitude_m: float) -> Vector3:
	return Vector3(sin(phase * 0.5) * side_amplitude_m, absf(sin(phase)) * vertical_amplitude_m, 0.0)
