# SPDX-License-Identifier: GPL-2.0-or-later
class_name Health
extends Node

signal damaged(amount: float, was_headshot: bool, hit_position: Vector3)
signal died()

@export var max_health: float = 100.0

var current_health: float
var _invulnerable_until_msec: int = 0


func _ready() -> void:
	current_health = max_health


func apply_damage(amount: float, was_headshot: bool = false, hit_position: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0.0 or is_invulnerable():
		return

	current_health = maxf(current_health - amount, 0.0)
	damaged.emit(amount, was_headshot, hit_position)

	if current_health <= 0.0:
		died.emit()


func reset() -> void:
	current_health = max_health


## Granted by respawn_at() on both Bot and PMove (see MatchState.spawn_protection_seconds)
## rather than implied by reset() — a health reset and a spawn don't always
## coincide, and the two are conceptually separate.
func grant_invulnerability(duration_seconds: float) -> void:
	_invulnerable_until_msec = Time.get_ticks_msec() + int(duration_seconds * 1000.0)


func is_invulnerable() -> bool:
	return Time.get_ticks_msec() < _invulnerable_until_msec
