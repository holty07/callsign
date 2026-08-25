# SPDX-License-Identifier: GPL-2.0-or-later
#
# Bot locomotion: a NavigationAgent3D-driven CharacterBody3D. Deliberately
# not built on pmove.gd — that's the player's raw-mouse-input Quake movement
# (see CLAUDE.md's movement non-negotiables), and a bot has no mouse or
# keyboard to read from. It just walks toward wherever move_to() points it.
#
# Body yaw is left alone here — same decoupling as the player, where Head
# (bot_aim.gd) turns independently of movement direction, so a bot can
# strafe around a target it's aiming at exactly like the player can.
class_name Bot
extends CharacterBody3D

@export var move_speed: float = 4.5 # m/s
@export var acceleration: float = 12.0 # m/s^2
@export var gravity: float = 20.0 # m/s^2
@export var arrival_distance: float = 0.3

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	add_to_group("combatants")
	_nav_agent.target_desired_distance = arrival_distance


func move_to(target_position: Vector3) -> void:
	_nav_agent.target_position = target_position


func stop_moving() -> void:
	_nav_agent.target_position = global_position


func is_move_finished() -> bool:
	return _nav_agent.is_navigation_finished()


func _physics_process(delta: float) -> void:
	var wish_velocity := Vector3.ZERO

	if not _nav_agent.is_navigation_finished():
		var next_point := _nav_agent.get_next_path_position()
		var to_next := next_point - global_position
		to_next.y = 0.0
		if to_next.length() > 0.01:
			wish_velocity = to_next.normalized() * move_speed

	velocity.x = move_toward(velocity.x, wish_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, wish_velocity.z, acceleration * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	move_and_slide()
