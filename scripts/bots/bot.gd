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
@onready var health: Health = $Health
@onready var perception: Perception = $Perception
@onready var weapon: WeaponBase = $Head/Camera3D/Rifle
@onready var aim: BotAim = $Head


func _ready() -> void:
	add_to_group("combatants")
	_nav_agent.target_desired_distance = arrival_distance
	health.died.connect(_on_died)


func _on_died() -> void:
	print("Bot %s died at %s" % [name, global_position])


func move_to(target_position: Vector3) -> void:
	_nav_agent.target_position = target_position


func stop_moving() -> void:
	_nav_agent.target_position = global_position


func is_move_finished() -> bool:
	return _nav_agent.is_navigation_finished()


func is_alive() -> bool:
	return health.current_health > 0.0


## Pushes a difficulty tier's perception/aim/weapon values onto this bot.
## Deliberately never touches health/max_health or damage — difficulty is
## how well the bot perceives and aims, not how much punishment it takes
## or deals.
func apply_difficulty(profile: BotDifficulty) -> void:
	perception.fov_deg = profile.fov_deg
	perception.reaction_delay = profile.reaction_delay
	perception.memory_duration = profile.memory_duration
	aim.error_cone_deg = profile.error_cone_deg
	aim.turn_rate_deg = profile.turn_rate_deg
	weapon.hipfire_spread_deg = profile.hipfire_spread_deg


## Resets health and teleports back to a spawn point. Leaves perception's
## own memory of this bot in other bots' heads to expire naturally rather
## than forcibly clearing it — reappearing somewhere else and having to be
## re-spotted is the point.
func respawn_at(spawn_position: Vector3) -> void:
	health.reset()
	velocity = Vector3.ZERO
	global_position = spawn_position
	stop_moving()
	print("Bot %s respawned at %s" % [name, global_position])


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
