# SPDX-License-Identifier: GPL-2.0-or-later
#
# Raw mouse look. Input.use_accumulated_input is disabled project-wide (see
# scripts/core/input_config.gd), so InputEventMouseMotion arrives unmerged —
# every event is summed into a buffer here and only consumed once per physics
# tick in _physics_process. Never read or apply look input in _process(); see
# CLAUDE.md's movement non-negotiables.
#
# Also owns view bob and the slide tilt: both are camera feel, not movement
# (pmove.gd's velocity is untouched), so they live here rather than in
# pmove.gd. View bob's math lives in scripts/core/view_bob.gd, shared with
# weapon_base.gd's sway so the camera and the gun read as the same footstep.
# This node's parent is always the PMove player root (see
# scenes/player/player.tscn) — the same assumption the existing yaw rotation
# below already makes.
class_name CameraLook
extends Node3D

@export var mouse_sensitivity: float = 0.0025
@export var min_pitch_deg: float = -89.0
@export var max_pitch_deg: float = 89.0

@export_group("View bob")
@export var bob_enabled: bool = true
## Horizontal distance (qu) travelled per full bob cycle. Ties bob cadence
## to footwork rather than the wall clock, so it naturally speeds up when
## sprinting and never "runs on the spot" while airborne or stopped.
@export var bob_cycle_length_qu: float = 130.0
@export var bob_vertical_amplitude_m: float = 0.1
@export var bob_side_amplitude_m: float = 0.1
## Below this horizontal speed, bob amplitude eases to zero — keeps a
## barely-moving player from visibly bobbing.
@export var bob_min_speed_qu: float = 20.0
## Horizontal speed at which bob amplitude reaches its full exported value.
@export var bob_max_speed_qu: float = 380.0
@export var bob_amplitude_smoothing: float = 8.0

@export_group("Slide tilt")
## Camera roll while sliding — the player's only feedback that a slide
## (as opposed to an ordinary crouch) is in progress.
@export var slide_tilt_deg: float = 8.0
@export var slide_tilt_speed_deg: float = 90.0

@onready var _camera: Camera3D = $Camera3D
@onready var _player: PMove = get_parent() as PMove

var _accumulated_mouse_delta: Vector2 = Vector2.ZERO
var _pitch: float = 0.0
var _bob_phase: float = 0.0
var _bob_amplitude_scale: float = 0.0
var _tilt_deg: float = 0.0

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


func _physics_process(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_accumulated_mouse_delta = Vector2.ZERO
		return

	var yaw_delta := -_accumulated_mouse_delta.x * mouse_sensitivity
	var pitch_delta := -_accumulated_mouse_delta.y * mouse_sensitivity
	_accumulated_mouse_delta = Vector2.ZERO

	get_parent().rotate_y(yaw_delta)

	_pitch = clampf(_pitch + pitch_delta, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	rotation.x = clampf(_pitch + _recoil_offset.x, deg_to_rad(min_pitch_deg) - 0.5, deg_to_rad(max_pitch_deg) + 0.5)

	_update_view_bob(delta)
	_update_slide_tilt(delta)


func _update_view_bob(delta: float) -> void:
	var horizontal_speed := _player.get_horizontal_speed_qu()
	var target_scale := 0.0
	if bob_enabled and _player.is_on_floor():
		_bob_phase = ViewBob.advance_phase(_bob_phase, horizontal_speed, bob_cycle_length_qu, delta)
		target_scale = ViewBob.amplitude_scale(horizontal_speed, bob_min_speed_qu, bob_max_speed_qu)

	_bob_amplitude_scale = move_toward(_bob_amplitude_scale, target_scale, bob_amplitude_smoothing * delta)
	_camera.position = ViewBob.offset(_bob_phase, bob_vertical_amplitude_m, bob_side_amplitude_m) * _bob_amplitude_scale


func _update_slide_tilt(delta: float) -> void:
	var target_deg := slide_tilt_target_deg(_player.is_sliding(), slide_tilt_deg)
	_tilt_deg = move_toward(_tilt_deg, target_deg, slide_tilt_speed_deg * delta)
	rotation.z = deg_to_rad(_tilt_deg)


## Pure target-angle rule for the slide tilt: on while sliding, back to
## level otherwise. Kept static and side-effect free so it's unit-testable
## without a live PMove/Camera3D.
static func slide_tilt_target_deg(is_sliding: bool, tilt_deg: float) -> float:
	return tilt_deg if is_sliding else 0.0


## Sets the current absolute recoil kick, in degrees (pitch, yaw); positive
## pitch looks up, positive yaw is a rightward drift. Called every physics
## tick by the active weapon with a value that decays back toward zero as
## its recoil recovers.
func apply_recoil_offset(offset_deg: Vector2) -> void:
	var new_offset := Vector2(deg_to_rad(offset_deg.x), deg_to_rad(offset_deg.y))
	var delta_yaw := new_offset.y - _recoil_offset.y
	get_parent().rotate_y(delta_yaw)
	_recoil_offset = new_offset
