# SPDX-License-Identifier: GPL-2.0-or-later
#
# A large Area3D placed well below the map: anyone who falls out of bounds
# dies and respawns rather than free-falling forever. Applies lethal damage
# through the same Health component everything else uses (no special-cased
# damage), then respawns whoever it was directly — bots have no behaviour
# tree action watching for "died from falling" specifically, so this
# doesn't rely on action_respawn.gd, it just calls the same respawn_at()
# every combatant exposes.
class_name KillZone
extends Area3D

@export var spawn_points_group: String = "bot_spawn_points"
@export var player_spawn_point_path: NodePath
## Same hazard SpawnPointPicker guards against elsewhere: landing on top of
## a living combatant spawns two fully-overlapping CharacterBody3D capsules
## that immediately depenetrate into each other at high speed.
@export var clear_radius: float = 1.5


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var health: Health = body.get_node_or_null("Health")
	if health:
		health.apply_damage(health.max_health)

	if not body.has_method("respawn_at"):
		return

	body.respawn_at(_pick_respawn_position(body))


func _pick_respawn_position(body: Node3D) -> Vector3:
	if body is Bot:
		return SpawnPointPicker.pick(get_tree(), spawn_points_group, body, clear_radius, body.global_position)

	if not player_spawn_point_path.is_empty():
		var marker := get_node_or_null(player_spawn_point_path)
		if marker:
			return marker.global_position

	return body.global_position
