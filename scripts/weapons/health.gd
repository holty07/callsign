# SPDX-License-Identifier: GPL-2.0-or-later
class_name Health
extends Node

## source_position is where the shot came from (the shooter's ray origin),
## not where it landed on this body — ground truth for a HUD direction
## indicator, rather than something it has to infer from hit geometry.
signal damaged(amount: float, was_headshot: bool, source_position: Vector3)
signal died()

@export var max_health: float = 100.0

## Regen — delayed heal-over-time, not an instant top-up. Waits this long
## since the last hit before starting, then applies continuously (see
## regen_step) rather than in one lump after the delay elapses.
@export var regen_delay_seconds: float = 4.0
@export var regen_rate_per_second: float = 40.0

var current_health: float
var _invulnerable_until_msec: int = 0
## Starts at INF rather than 0 so a fresh spawn at full health never has to
## "wait out" the regen delay it doesn't need.
var _time_since_damage: float = INF


func _ready() -> void:
	current_health = max_health


func _process(delta: float) -> void:
	_time_since_damage += delta
	current_health = regen_step(current_health, max_health, _time_since_damage, regen_delay_seconds, regen_rate_per_second, delta)


func apply_damage(amount: float, was_headshot: bool = false, source_position: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0.0 or is_invulnerable():
		return

	current_health = maxf(current_health - amount, 0.0)
	_time_since_damage = 0.0
	damaged.emit(amount, was_headshot, source_position)

	if current_health <= 0.0:
		died.emit()


func reset() -> void:
	current_health = max_health
	_time_since_damage = INF


## Pure regen tick: once time_since_damage clears delay_seconds, advances
## current_health toward max_health at rate_per_second — smoothly, spread
## over each delta, never as a lump sum the instant the delay elapses. A
## dead (current_health <= 0.0) or already-full target is left untouched.
## Kept static and side effect free so it's unit-testable without a live
## Node/_process loop.
static func regen_step(current_health: float, max_health: float, time_since_damage: float, delay_seconds: float, rate_per_second: float, delta: float) -> float:
	if current_health <= 0.0 or current_health >= max_health:
		return current_health
	if time_since_damage < delay_seconds:
		return current_health
	return minf(current_health + rate_per_second * delta, max_health)


## Granted by respawn_at() on both Bot and PMove (see MatchState.spawn_protection_seconds)
## rather than implied by reset() — a health reset and a spawn don't always
## coincide, and the two are conceptually separate.
func grant_invulnerability(duration_seconds: float) -> void:
	_invulnerable_until_msec = Time.get_ticks_msec() + int(duration_seconds * 1000.0)


func is_invulnerable() -> bool:
	return Time.get_ticks_msec() < _invulnerable_until_msec
