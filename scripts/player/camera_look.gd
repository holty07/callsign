# SPDX-License-Identifier: GPL-2.0-or-later
#
# Raw mouse look. Input.use_accumulated_input is disabled project-wide (see
# scripts/core/input_config.gd), so InputEventMouseMotion arrives unmerged —
# every event is summed into a buffer here and only consumed once per physics
# tick in _physics_process. Never read or apply look input in _process(); see
# CLAUDE.md's movement non-negotiables.
extends Node3D

@export var mouse_sensitivity: float = 0.0025
@export var min_pitch_deg: float = -89.0
@export var max_pitch_deg: float = 89.0

var _accumulated_mouse_delta: Vector2 = Vector2.ZERO
var _pitch: float = 0.0

## Absolute recoil kick (pitch, yaw) in radians, on top of player-driven
## aim. Weapons set this every tick via apply_recoil_offset(); it is not
## folded into _pitch, so recovering recoil never fights the player's own
## re-aiming.
var _recoil_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_accumulated_mouse_delta += event.relative


func _physics_process(_delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_accumulated_mouse_delta = Vector2.ZERO
		return

	var yaw_delta := -_accumulated_mouse_delta.x * mouse_sensitivity
	var pitch_delta := -_accumulated_mouse_delta.y * mouse_sensitivity
	_accumulated_mouse_delta = Vector2.ZERO

	get_parent().rotate_y(yaw_delta)

	_pitch = clampf(_pitch + pitch_delta, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	rotation.x = clampf(_pitch + _recoil_offset.x, deg_to_rad(min_pitch_deg) - 0.5, deg_to_rad(max_pitch_deg) + 0.5)


## Sets the current absolute recoil kick, in degrees (pitch, yaw); positive
## pitch looks up, positive yaw is a rightward drift. Called every physics
## tick by the active weapon with a value that decays back toward zero as
## its recoil recovers.
func apply_recoil_offset(offset_deg: Vector2) -> void:
	var new_offset := Vector2(deg_to_rad(offset_deg.x), deg_to_rad(offset_deg.y))
	var delta_yaw := new_offset.y - _recoil_offset.y
	get_parent().rotate_y(delta_yaw)
	_recoil_offset = new_offset
