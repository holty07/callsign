# SPDX-License-Identifier: GPL-2.0-or-later
#
# Ground/air acceleration and friction are a GDScript port of PM_Friction and
# PM_Accelerate from Quake III Arena's bg_pmove.c (id Software, GPL-2.0 —
# https://github.com/id-Software/Quake-III-Arena). PM_Accelerate projects the
# current velocity onto the wish direction *before* clamping the acceleration
# delta for this tick — that projection is why turning in the air (or on the
# ground) doesn't cost you the speed you already have, and it is preserved
# exactly below. Do not "simplify" it.
extends CharacterBody3D
class_name PMove

# All speed/accel/gravity constants below are in Quake units (see
# scripts/core/units.gd) so documented Quake III tuning values can be dropped
# in directly. They're converted to metres only where they meet Godot's
# physics, in _physics_process.

@export_group("Ground")
@export var move_speed: float = 260.0
@export var ground_accel: float = 10.0
@export var ground_friction: float = 10.0
@export var stop_speed: float = 200.0

@export_group("Air")
@export var air_accel: float = 1.0

@export_group("Jump & gravity")
@export var gravity_qu: float = 800.0
@export var jump_velocity_qu: float = 270.0

@export_group("Crouch")
@export var standing_height: float = 1.8
@export var crouch_height: float = 1.0
@export var crouch_speed_scale: float = 0.5
@export var crouch_transition_speed: float = 8.0
@export var eye_offset_from_top: float = 0.15

@export_group("Sprint")
@export var sprint_speed_scale: float = 1.4

@export_group("Slide")
## Sprinting into a crouch triggers a slide instead of an ordinary crouch:
## a forward speed boost, low friction while it lasts, and a cooldown
## before it can trigger again. Ends early if crouch is released, the
## timer runs out, or the ground drops out from under you.
@export var slide_min_speed: float = 300.0
@export var slide_duration: float = 0.65
@export var slide_speed_boost: float = 1.15
@export var slide_friction: float = 2.0
@export var slide_cooldown: float = 0.8

@export_group("Stepping & slopes")
@export var max_step_height: float = 0.3
@export var floor_max_angle_deg: float = 45.0

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _head: Node3D = $Head

var _velocity_qu: Vector3 = Vector3.ZERO
var _current_height: float = standing_height
var _was_sprinting: bool = false
var _is_sliding: bool = false
var _slide_timer: float = 0.0
var _slide_cooldown_timer: float = 0.0

## Runtime multiplier on move_speed, e.g. for weapon ADS slow. Not exported —
## this is a live hook other systems poke, not a tuning value.
var speed_modifier: float = 1.0

## Q3 bg_pmove.c PM_Friction, ported. `vel` is a full 3D velocity (Quake Z-up
## became Godot Y-up: the vertical axis is `y`, not `z`). `grounded` mirrors
## Q3's `pm->walking` — friction only bites while standing on the ground.
static func pm_friction(vel: Vector3, friction: float, stopspeed: float, delta: float, grounded: bool) -> Vector3:
	var speed := vel.length()
	if speed < 1.0:
		return Vector3(0.0, vel.y, 0.0)

	var drop := 0.0
	if grounded:
		var control := stopspeed if speed < stopspeed else speed
		drop += control * friction * delta

	var new_speed := speed - drop
	if new_speed < 0.0:
		new_speed = 0.0
	new_speed /= speed

	return vel * new_speed

## Q3 bg_pmove.c PM_Accelerate, ported verbatim. `wishdir` must be normalized
## (or zero). The projection of the current velocity onto wishdir — computed
## before the accel delta is clamped to what's still needed — is the whole
## point: accelerating perpendicular to your current velocity adds speed
## without first "paying it down".
static func pm_accelerate(vel: Vector3, wishdir: Vector3, wishspeed: float, accel: float, delta: float) -> Vector3:
	var current_speed := vel.dot(wishdir)
	var add_speed := wishspeed - current_speed
	if add_speed <= 0.0:
		return vel

	var accel_speed := accel * delta * wishspeed
	if accel_speed > add_speed:
		accel_speed = add_speed

	return vel + wishdir * accel_speed


## Whether a sprint-to-crouch slide should begin this tick. Gated on being
## grounded, the crouch press being the one that starts it (not a held
## repeat), having been sprinting going into this tick, having enough
## horizontal speed to bother, and the cooldown from the last slide.
static func should_start_slide(grounded: bool, crouch_just_pressed: bool, was_sprinting: bool, horizontal_speed: float, min_speed: float, cooldown_remaining: float) -> bool:
	if not grounded or not crouch_just_pressed or not was_sprinting:
		return false
	if cooldown_remaining > 0.0:
		return false
	return horizontal_speed >= min_speed


## Whether an in-progress slide should end this tick: losing the floor,
## releasing crouch, or the duration timer running out.
static func should_end_slide(grounded: bool, crouch_held: bool, time_remaining: float) -> bool:
	return not grounded or not crouch_held or time_remaining <= 0.0


## The forward lurch a slide starts with: boosts horizontal speed only,
## vertical velocity (e.g. a fall already in progress) passes through.
static func slide_boost_velocity(vel: Vector3, boost: float) -> Vector3:
	return Vector3(vel.x * boost, vel.y, vel.z * boost)


func _ready() -> void:
	_current_height = standing_height
	_apply_height(_current_height)


func _physics_process(delta: float) -> void:
	floor_max_angle = deg_to_rad(floor_max_angle_deg)

	var grounded := is_on_floor()

	_update_slide(delta, grounded)
	_handle_crouch(delta)

	var wish := _wish_velocity()

	if grounded and Input.is_action_just_pressed("jump"):
		_velocity_qu.y = jump_velocity_qu
		grounded = false
		_end_slide()

	var friction := slide_friction if _is_sliding else ground_friction
	_velocity_qu = pm_friction(_velocity_qu, friction, stop_speed, delta, grounded)

	if not _is_sliding:
		if grounded:
			_velocity_qu = pm_accelerate(_velocity_qu, wish.dir, wish.speed, ground_accel, delta)
		else:
			_velocity_qu = pm_accelerate(_velocity_qu, wish.dir, wish.speed, air_accel, delta)

	if not grounded:
		_velocity_qu.y -= gravity_qu * delta

	velocity = _velocity_qu * Units.QU_TO_M
	_move_with_step_up(grounded)
	_velocity_qu = velocity * Units.M_TO_QU


## Returns { dir: Vector3 (world-space, normalized, flattened), speed: float (qu/s) }.
## Equivalent to Q3's PM_CmdScale + wishvel/wishdir/wishspeed dance, specialised
## for continuous analog input instead of Q3's -127..127 quantized usercmd: for
## a unit-length input vector, PM_CmdScale's diagonal-normalization collapses
## to exactly "normalize the input, scale by its own length", which is what
## this does directly.
func _wish_velocity() -> Dictionary:
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	)
	var input_len := input.length()
	if input_len > 1.0:
		input = input / input_len
		input_len = 1.0

	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var wishdir := forward * input.y + right * input.x
	if wishdir.length() > 0.0001:
		wishdir = wishdir.normalized()

	var speed_scale := 1.0
	_was_sprinting = false
	if _is_crouched():
		speed_scale = crouch_speed_scale
	elif Input.is_action_pressed("sprint") and input.y > 0.1:
		speed_scale = sprint_speed_scale
		_was_sprinting = true

	return {"dir": wishdir, "speed": move_speed * input_len * speed_scale * speed_modifier}


func _is_crouched() -> bool:
	return Input.is_action_pressed("crouch")


func _update_slide(delta: float, grounded: bool) -> void:
	_slide_cooldown_timer = maxf(_slide_cooldown_timer - delta, 0.0)

	if _is_sliding:
		_slide_timer -= delta
		if should_end_slide(grounded, _is_crouched(), _slide_timer):
			_end_slide()
		return

	var horizontal_speed := Vector2(_velocity_qu.x, _velocity_qu.z).length()
	if should_start_slide(grounded, Input.is_action_just_pressed("crouch"), _was_sprinting, horizontal_speed, slide_min_speed, _slide_cooldown_timer):
		_start_slide()


func _start_slide() -> void:
	_is_sliding = true
	_slide_timer = slide_duration
	_velocity_qu = slide_boost_velocity(_velocity_qu, slide_speed_boost)


func _end_slide() -> void:
	if _is_sliding:
		_slide_cooldown_timer = slide_cooldown
	_is_sliding = false
	_slide_timer = 0.0


## Whether the last physics tick's wish velocity was sprint-scaled. Weapons
## use this to gate a brief sprint-out delay before firing.
func is_sprinting() -> bool:
	return _was_sprinting


## Whether a slide is currently in progress. camera_look.gd uses this to
## drive the slide tilt that's the player's only feedback that a slide
## (as opposed to an ordinary crouch) is happening.
func is_sliding() -> bool:
	return _is_sliding


## Current horizontal speed in qu/s, ignoring vertical velocity. camera_look.gd
## uses this to drive view bob amplitude and cadence.
func get_horizontal_speed_qu() -> float:
	return Vector2(_velocity_qu.x, _velocity_qu.z).length()


func _handle_crouch(delta: float) -> void:
	var target_height := crouch_height if _is_crouched() else standing_height

	if target_height > _current_height:
		var grow := target_height - _current_height
		if test_move(global_transform, Vector3.UP * grow):
			target_height = _current_height

	_current_height = move_toward(_current_height, target_height, crouch_transition_speed * delta)
	_apply_height(_current_height)


func _apply_height(height: float) -> void:
	var shape: CapsuleShape3D = _collision_shape.shape
	shape.height = height
	_collision_shape.position.y = height * 0.5
	_head.position.y = height - eye_offset_from_top


## move_and_slide() handles ramps within floor_max_angle on its own. Godot has
## no built-in stair auto-climb, so: try the normal slide; if it was blocked
## by something wall-shaped while we started the tick grounded, retry from a
## lifted position and settle back down. If there's no floor within
## max_step_height on the way down, it wasn't a step — undo the lift.
func _move_with_step_up(was_grounded: bool) -> void:
	var pre_position := global_position
	var pre_velocity := velocity

	move_and_slide()

	if not was_grounded or not _blocked_by_low_step():
		return

	global_position = pre_position
	velocity = pre_velocity

	if test_move(global_transform, Vector3.UP * max_step_height):
		return # no headroom above to step into; keep the blocked slide result

	global_position.y += max_step_height
	move_and_slide()

	if move_and_collide(Vector3.DOWN * max_step_height) == null:
		global_position = pre_position
		velocity = pre_velocity
		move_and_slide()


func _blocked_by_low_step() -> bool:
	for i in get_slide_collision_count():
		var normal := get_slide_collision(i).get_normal()
		if absf(normal.y) < 0.3:
			return true
	return false
