# SPDX-License-Identifier: GPL-2.0-or-later
#
# FOV cone + raycast line-of-sight against every other combatant (group
# "combatants" — both the player and bots join it), gated by a reaction
# delay before a sighting counts and a short memory of the last confirmed
# position after losing sight. Without this, a bot would snap its aim onto
# a target the instant it enters view and know exactly where it went the
# moment it ducks behind cover — omniscient, not perceptive.
class_name Perception
extends Node

const _GROUP := "combatants"

@export var fov_deg: float = 100.0
@export var view_distance: float = 40.0
@export var reaction_delay: float = 0.25
@export var memory_duration: float = 5.0
## The node whose transform stands in for this bot's eyes/gun — forward
## direction for the FOV check, origin for the line-of-sight raycast.
@export var eye_path: NodePath

@onready var _eye: Node3D = get_node(eye_path)

var _actor: Node3D
var _sight_time: Dictionary = {} # target -> seconds continuously visible this sighting
var _time_since_seen: Dictionary = {} # target -> seconds since last confirmed visible
var _last_known_position: Dictionary = {} # target -> Vector3
var _confirmed_target: Node3D = null

var _has_noise_memory: bool = false
var _noise_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	_actor = get_parent()
	NoiseBus.noise_emitted.connect(_on_noise_emitted)


## A heard-but-unseen alert (e.g. gunfire) — investigate-noise behaviour
## reads this independently of the per-target sighting memory above, since
## a noise isn't tied to any specific confirmed target.
func has_noise_memory() -> bool:
	return _has_noise_memory


func get_noise_position() -> Vector3:
	return _noise_position


## Called once investigate-noise behaviour has resolved the alert (arrived
## and found nothing, or gave up), so the same noise doesn't keep re-firing
## the behaviour every tick.
func clear_noise_memory() -> void:
	_has_noise_memory = false


func _on_noise_emitted(position: Vector3, radius: float, source: Node) -> void:
	if source == _actor:
		return
	if _eye.global_position.distance_to(position) <= radius:
		_has_noise_memory = true
		_noise_position = position


## Whether `to_target` falls inside a forward-facing cone of half-angle
## fov_deg/2. Kept static and side-effect free so it's unit-testable
## without a live eye transform.
static func angle_within_fov(forward: Vector3, to_target: Vector3, fov_deg: float) -> bool:
	if to_target.length_squared() < 0.0001:
		return true
	return rad_to_deg(forward.angle_to(to_target)) <= fov_deg * 0.5


## A sighting only counts once it's been continuously visible for at least
## reaction_delay — the bot equivalent of "notice, then react", not an
## instant snap onto anything that enters the FOV cone.
static func should_confirm_sighting(time_visible: float, reaction_delay: float) -> bool:
	return time_visible >= reaction_delay


## Last-known-position memory expires after memory_duration with no
## confirmed sighting, so a bot eventually gives up and stops beelining for
## where a target used to be.
static func should_forget(time_since_seen: float, memory_duration: float) -> bool:
	return time_since_seen >= memory_duration


## Which of this tick's confirmed-visible sightings to lock onto. Sticks
## with `current` as long as it's still among them, rather than always
## snapping to whichever is nearest right now — with several combatants at
## similar range, "nearest" trades back and forth between them almost every
## tick as everyone moves, and each trade resets aim.gd's reacquire timer
## before it ever elapses, so the bot aims but never actually opens fire.
## Kept static and side-effect free so it's unit-testable without a live
## scene. `confirmed` maps each combatant confirmed visible this tick to its
## distance from this bot.
static func pick_target(current: Node3D, confirmed: Dictionary) -> Node3D:
	if confirmed.is_empty():
		return null
	if current != null and confirmed.has(current):
		return current

	var best_target: Node3D = null
	var best_distance := INF
	for node in confirmed:
		var distance: float = confirmed[node]
		if distance < best_distance:
			best_distance = distance
			best_target = node
	return best_target


func _physics_process(delta: float) -> void:
	if _is_dead(_actor):
		_confirmed_target = null
		return

	var confirmed_this_tick: Dictionary = {} # node -> distance, only for confirmed sightings

	for node in get_tree().get_nodes_in_group(_GROUP):
		if node == _actor or not is_instance_valid(node) or not (node is Node3D):
			continue
		if _is_dead(node):
			continue

		var eye_origin := _eye.global_position
		var target_point := _aim_point_of(node)
		var to_target := target_point - eye_origin
		var distance := to_target.length()

		var visible := (
			distance <= view_distance
			and angle_within_fov(-_eye.global_transform.basis.z, to_target, fov_deg)
			and _has_line_of_sight(node, eye_origin, target_point)
		)

		if visible:
			_sight_time[node] = _sight_time.get(node, 0.0) + delta
			_time_since_seen[node] = 0.0
			if should_confirm_sighting(_sight_time[node], reaction_delay):
				_last_known_position[node] = node.global_position
				confirmed_this_tick[node] = distance
		else:
			_sight_time[node] = 0.0
			if _last_known_position.has(node):
				var since: float = _time_since_seen.get(node, 0.0) + delta
				_time_since_seen[node] = since
				if should_forget(since, memory_duration):
					_last_known_position.erase(node)
					_time_since_seen.erase(node)

	_confirmed_target = pick_target(_confirmed_target, confirmed_this_tick)


## The target currently confirmed visible and reacted to (nearest, if more
## than one), or null if nothing currently qualifies.
func get_confirmed_target() -> Node3D:
	return _confirmed_target


## Whether this bot has any reason at all to think a threat is nearby —
## seeing one now, remembering where one was, or having heard one. Used to
## gate retreat/take-cover so a bot doesn't flee from nothing.
func is_aware_of_threat() -> bool:
	return _confirmed_target != null or has_any_memory() or _has_noise_memory


func has_memory_of(target: Node3D) -> bool:
	return _last_known_position.has(target)


func get_last_known_position(target: Node3D) -> Vector3:
	return _last_known_position.get(target, Vector3.ZERO)


## Any one remembered position, for "investigate" behaviour that doesn't
## care which target it was — e.g. reacting to a noise with no visual yet.
func get_any_last_known_position() -> Vector3:
	for position in _last_known_position.values():
		return position
	return Vector3.ZERO


func has_any_memory() -> bool:
	return not _last_known_position.is_empty()


func _is_dead(node: Node) -> bool:
	var health: Health = node.get_node_or_null("Health")
	return health != null and health.current_health <= 0.0


func _aim_point_of(node: Node3D) -> Vector3:
	var aim_point: Node3D = node.get_node_or_null("AimPoint")
	return aim_point.global_position if aim_point else node.global_position


func _has_line_of_sight(target: Node3D, from: Vector3, to: Vector3) -> bool:
	var space_state := _eye.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_actor.get_rid()]
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	return _belongs_to(hit.collider, target)


func _belongs_to(collider: Node, target: Node) -> bool:
	var node := collider
	while node:
		if node == target:
			return true
		node = node.get_parent()
	return false
