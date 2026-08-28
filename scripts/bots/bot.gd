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

@export_group("Death")
## No death animation yet — the corpse just tips over onto its back instead
## of a real ragdoll. Replace with a real death animation later.
@export var death_tilt_deg: float = 90.0
@export var death_fall_speed_deg: float = 260.0 # deg/s

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _visual: Node3D = $Visual
@onready var health: Health = $Health
@onready var perception: Perception = $Perception
@onready var weapon: WeaponBase = $Head/Camera3D/Rifle
@onready var aim: BotAim = $Head

var _death_tilt_current_deg: float = 0.0

## Guards move_to()/stop_moving() against reassigning target_position when
## the target hasn't meaningfully changed. Every behaviour-tree leaf that
## drives movement (patrol, take cover, investigate noise, and — the worst
## offender — engage holding ground via stop_moving()) calls move_to() or
## stop_moving() from a RUNNING leaf that re-ticks every physics frame for
## as long as its condition holds, which in a small map with several
## combatants can be most of the match. NavigationAgent3D.target_position's
## setter kicks off a fresh repath every time it's assigned, even to a
## value equal to the one already there; doing that 120 times a second
## raced the NavigationServer and could leave is_navigation_finished()
## reporting false forever — the bot frozen in place with no path ever
## considered "arrived".
var _has_commanded_target: bool = false
var _last_commanded_target: Vector3 = Vector3.ZERO

## Recovery for a commanded target that never produces a usable path — e.g.
## move_to() lands before a map's navmesh has baked/synced (see
## NavigationBaker.navmesh_ready). Reassigning target_position directly
## (bypassing move_to()'s de-dupe guard above) only after sustained zero
## progress, not every tick, is what keeps this from reintroducing the
## every-frame-reassignment race that guard exists to prevent.
const _STUCK_RETRY_SECONDS := 0.5
var _stuck_seconds: float = 0.0

## Pipeline diagnostic snapshot of the last _physics_process tick, read by
## debug_visuals.gd's periodic log — see that file for why velocity_after
## isn't stored separately (it's just `velocity`, read post-move_and_slide).
var last_wish_velocity: Vector3 = Vector3.ZERO
var last_velocity_before_move: Vector3 = Vector3.ZERO
## Comfortably above the sub-millimetre jitter move_and_slide()'s floor
## snapping leaves in global_position between ticks, well below any
## deliberate move_to() destination change.
const _TARGET_CHANGE_EPSILON := 0.05


func _ready() -> void:
	add_to_group("combatants")
	_nav_agent.target_desired_distance = arrival_distance
	health.died.connect(_on_died)


func _on_died() -> void:
	print("Bot %s died at %s" % [name, global_position])
	stop_moving()
	aim.visible = false


func move_to(target_position: Vector3) -> void:
	if _has_commanded_target and _last_commanded_target.distance_to(target_position) < _TARGET_CHANGE_EPSILON:
		return
	_has_commanded_target = true
	_last_commanded_target = target_position
	_nav_agent.target_position = target_position


func stop_moving() -> void:
	move_to(global_position)


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
	_death_tilt_current_deg = 0.0
	_visual.rotation_degrees.x = 0.0
	aim.visible = true
	print("Bot %s respawned at %s" % [name, global_position])


func _physics_process(delta: float) -> void:
	_update_death_tilt(delta)

	var wish_velocity := Vector3.ZERO

	if is_alive() and _has_commanded_target and not _nav_agent.is_navigation_finished():
		var next_point := _nav_agent.get_next_path_position()
		var to_next := next_point - global_position
		to_next.y = 0.0
		if to_next.length() > 0.01:
			wish_velocity = to_next.normalized() * move_speed
			_stuck_seconds = 0.0
		else:
			_stuck_seconds += delta
			if _stuck_seconds >= _STUCK_RETRY_SECONDS:
				_stuck_seconds = 0.0
				_nav_agent.target_position = _last_commanded_target
	else:
		_stuck_seconds = 0.0

	velocity.x = move_toward(velocity.x, wish_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, wish_velocity.z, acceleration * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	var velocity_before_move := velocity
	move_and_slide()
	last_wish_velocity = wish_velocity
	last_velocity_before_move = velocity_before_move


## Tips the corpse's visual (torso + head meshes) over onto its back at
## death_tilt_deg, pivoting at the bot's own feet since Visual sits at this
## node's origin — a stand-in for a real death animation. Left alone while
## alive (target 0 is already where it rests) and un-done instantly by
## respawn_at() rather than tweening back upright.
func _update_death_tilt(delta: float) -> void:
	var target_deg := 0.0 if is_alive() else -death_tilt_deg
	_death_tilt_current_deg = move_toward(_death_tilt_current_deg, target_deg, death_fall_speed_deg * delta)
	_visual.rotation_degrees.x = _death_tilt_current_deg
