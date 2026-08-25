# SPDX-License-Identifier: GPL-2.0-or-later
#
# Bot aim: turns toward Perception's confirmed target at a limited turn
# rate, aims through a random error cone rather than a laser-perfect
# point, fires in bursts with a pause between rather than holding the
# trigger down forever, and won't open up the instant a target is
# (re)acquired. Structurally mirrors camera_look.gd — this node ("Head")
# yaws its parent (the bot body) and pitches itself locally — but driven by
# perception instead of mouse input. Implements apply_recoil_offset() the
# same way camera_look.gd does, so WeaponBase's recoil perturbs bot aim
# through the exact same call it makes on the player.
class_name BotAim
extends Node3D

@export_group("Turning")
@export var turn_rate_deg: float = 220.0 # deg/s, both yaw and pitch
@export var min_pitch_deg: float = -80.0
@export var max_pitch_deg: float = 80.0

@export_group("Accuracy")
## Half-angle of the cone the bot's aim wanders within around the true
## target direction. Reuses Hitscan.spread_direction — the same cone
## sampling the player's own hipfire spread uses.
@export var error_cone_deg: float = 3.0
@export var aim_seed: int = 54321

@export_group("Burst discipline")
@export var burst_min_shots: int = 3
@export var burst_max_shots: int = 6
@export var burst_pause_min: float = 0.3
@export var burst_pause_max: float = 0.7

@export_group("Target reacquisition")
## Delay after (re)acquiring a target — including switching from a
## different one — before the bot opens fire. Distinct from Perception's
## own reaction_delay, which gates the sighting itself; this gates the
## follow-up decision to shoot once a target is confirmed.
@export var reacquire_delay: float = 0.2

@onready var _weapon: WeaponBase = $Camera3D/Rifle
@onready var _perception: Perception = get_parent().get_node("Perception")

var _pitch: float = 0.0
var _recoil_offset: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()

var _current_target: Node3D = null
var _time_since_target_change: float = 0.0
var _burst_shots_fired: int = 0
var _burst_length: int = 0
var _burst_pause_timer: float = 0.0


## Turn-rate-limited step from current_rad toward target_rad, using the
## shortest angular direction and never moving by more than max_step_rad
## this tick. Kept static and side-effect free so it's unit-testable
## without a live transform.
static func clamp_turn_step(current_rad: float, target_rad: float, max_step_rad: float) -> float:
	var step := clampf(angle_difference(current_rad, target_rad), -max_step_rad, max_step_rad)
	return current_rad + step


## A burst ends once it's fired as many shots as this burst's rolled length.
static func should_end_burst(shots_fired: int, burst_length: int) -> bool:
	return shots_fired >= burst_length


## Whether the pause between bursts has fully elapsed.
static func is_pause_over(pause_remaining: float) -> bool:
	return pause_remaining <= 0.0


## Whether enough time has passed since (re)acquiring the current target
## to open fire on it.
static func has_reacquired(time_since_target_change: float, reacquire_delay: float) -> bool:
	return time_since_target_change >= reacquire_delay


func _ready() -> void:
	_rng.seed = aim_seed
	_weapon.fired.connect(_on_weapon_fired)
	_roll_new_burst_length()


func _physics_process(delta: float) -> void:
	_burst_pause_timer = maxf(_burst_pause_timer - delta, 0.0)

	var target := _perception.get_confirmed_target()
	_update_target_tracking(target, delta)

	if target:
		_turn_toward(target, delta)
		var reacquired := has_reacquired(_time_since_target_change, reacquire_delay)
		_weapon.ai_fire_held = reacquired and is_pause_over(_burst_pause_timer)
	else:
		_weapon.ai_fire_held = false


## Absolute recoil kick (pitch, yaw) in degrees, applied on top of aim —
## same contract as camera_look.gd's method of the same name, which is
## what lets WeaponBase call it on either without knowing which it has.
func apply_recoil_offset(offset_deg: Vector2) -> void:
	var new_offset := Vector2(deg_to_rad(offset_deg.x), deg_to_rad(offset_deg.y))
	var delta_yaw := new_offset.y - _recoil_offset.y
	get_parent().rotate_y(delta_yaw)
	_recoil_offset = new_offset


func _update_target_tracking(target: Node3D, delta: float) -> void:
	if target != _current_target:
		_current_target = target
		_time_since_target_change = 0.0
	elif target:
		_time_since_target_change += delta


func _on_weapon_fired() -> void:
	_burst_shots_fired += 1
	if should_end_burst(_burst_shots_fired, _burst_length):
		_burst_pause_timer = _rng.randf_range(burst_pause_min, burst_pause_max)
		_burst_shots_fired = 0
		_roll_new_burst_length()


func _roll_new_burst_length() -> void:
	_burst_length = _rng.randi_range(burst_min_shots, burst_max_shots)


func _turn_toward(target: Node3D, delta: float) -> void:
	var to_target := _aim_point_of(target) - global_position
	if to_target.length_squared() < 0.0001:
		return

	var jittered := Hitscan.spread_direction(to_target.normalized(), deg_to_rad(error_cone_deg), _rng)
	var max_step := deg_to_rad(turn_rate_deg) * delta

	var body := get_parent()
	var target_yaw := atan2(-jittered.x, -jittered.z)
	body.rotation.y = clamp_turn_step(body.rotation.y, target_yaw, max_step)

	var target_pitch := clampf(asin(clampf(jittered.y, -1.0, 1.0)), deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	_pitch = clamp_turn_step(_pitch, target_pitch, max_step)
	rotation.x = _pitch + _recoil_offset.x


func _aim_point_of(target: Node3D) -> Vector3:
	var aim_point: Node3D = target.get_node_or_null("AimPoint")
	return aim_point.global_position if aim_point else target.global_position
