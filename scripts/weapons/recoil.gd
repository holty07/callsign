# SPDX-License-Identifier: GPL-2.0-or-later
#
# Recoil pattern: a deterministic vertical climb (constant kick per shot,
# capped) plus a horizontal drift seeded from a fixed RNG seed — same seed,
# same shot sequence, same pattern every time, so it can actually be learned.
# Both recover back toward zero over time when not firing.
class_name Recoil
extends RefCounted

var vertical_per_shot: float
var vertical_max: float
var horizontal_max: float
var recovery_per_sec: float

var _current: Vector2 = Vector2.ZERO # (pitch kick, yaw kick), degrees; positive pitch = up
var _rng := RandomNumberGenerator.new()


func _init(p_vertical_per_shot: float, p_vertical_max: float, p_horizontal_max: float, p_recovery_per_sec: float, p_seed: int) -> void:
	vertical_per_shot = p_vertical_per_shot
	vertical_max = p_vertical_max
	horizontal_max = p_horizontal_max
	recovery_per_sec = p_recovery_per_sec
	_rng.seed = p_seed


## Call once per shot fired. Adds this shot's kick to the accumulated offset.
func fire() -> void:
	_current.x = minf(_current.x + vertical_per_shot, vertical_max)
	_current.y += _rng.randf_range(-horizontal_max, horizontal_max)


## Call once per physics tick. Decays the accumulated offset toward zero and
## returns the current (pitch, yaw) kick in degrees.
func process(delta: float) -> Vector2:
	_current = _current.move_toward(Vector2.ZERO, recovery_per_sec * delta)
	return _current


## Resets the pattern back to its start, replaying the same seeded sequence
## from the beginning (e.g. on reload).
func reset(p_seed: int) -> void:
	_current = Vector2.ZERO
	_rng.seed = p_seed
