# SPDX-License-Identifier: GPL-2.0-or-later
#
# Pure hitscan math: spread cone sampling, distance-based damage falloff,
# the headshot multiplier, and the movement spread penalty. Kept free of
# scene/node state so it's easy to unit test and to reuse for any future
# hitscan weapon.
class_name Hitscan
extends RefCounted


## A random direction within a cone of half-angle `spread_rad` around
## `forward` (both must be normalized `forward`). Zero spread returns
## `forward` unchanged.
static func spread_direction(forward: Vector3, spread_rad: float, rng: RandomNumberGenerator) -> Vector3:
	if spread_rad <= 0.0:
		return forward

	var up_hint := Vector3.UP if absf(forward.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var basis := Basis.looking_at(forward, up_hint)

	var angle := rng.randf_range(0.0, spread_rad)
	var around := rng.randf_range(0.0, TAU)
	# looking_at() puts `forward` along local -Z, not +Z.
	var local_dir := Vector3(sin(angle) * cos(around), sin(angle) * sin(around), -cos(angle))

	return (basis * local_dir).normalized()


## Linear falloff: full `damage_near` at or before `falloff_start`, full
## `damage_far` at or beyond `falloff_end`, interpolated in between.
static func damage_at_distance(distance: float, damage_near: float, damage_far: float, falloff_start: float, falloff_end: float) -> float:
	if distance <= falloff_start:
		return damage_near
	if distance >= falloff_end:
		return damage_far

	var t := (distance - falloff_start) / (falloff_end - falloff_start)
	return lerpf(damage_near, damage_far, t)


static func apply_headshot_multiplier(damage: float, was_headshot: bool, multiplier: float) -> float:
	return damage * multiplier if was_headshot else damage


## How much of the movement spread penalty currently applies, 0..1: 0 while
## stationary, 1 at or beyond `max_speed`, linear in between.
static func movement_spread_fraction(horizontal_speed: float, max_speed: float) -> float:
	if max_speed <= 0.0:
		return 0.0
	return clampf(horizontal_speed / max_speed, 0.0, 1.0)
