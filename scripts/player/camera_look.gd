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
	rotation.x = _pitch
