# SPDX-License-Identifier: GPL-2.0-or-later
#
# Picks a spawn point from a group, preferring one no living combatant
# currently stands near. Shared by action_respawn.gd (a bot's normal
# mid-match respawn) and kill_zone.gd (falling out of bounds) — both hit
# the same hazard: landing on top of someone spawns two fully-overlapping
# CharacterBody3D capsules that immediately depenetrate into each other at
# high speed, the same class of bug fixed for HitZone colliders and for
# BotSpawner's own initial placement.
class_name SpawnPointPicker


static func pick(tree: SceneTree, group: String, avoiding: Node, clear_radius: float, fallback: Vector3) -> Vector3:
	var points := tree.get_nodes_in_group(group)
	if points.is_empty():
		return fallback

	var shuffled: Array = points.duplicate()
	shuffled.shuffle()
	for point in shuffled:
		if _is_clear(tree, point.global_position, avoiding, clear_radius):
			return point.global_position

	# every point is currently occupied; take one anyway rather than not
	# respawning at all.
	return shuffled[0].global_position


static func _is_clear(tree: SceneTree, position: Vector3, avoiding: Node, clear_radius: float) -> bool:
	for combatant in tree.get_nodes_in_group("combatants"):
		if combatant == avoiding or not is_instance_valid(combatant):
			continue
		if combatant.has_method("is_alive") and not combatant.is_alive():
			continue
		if combatant.global_position.distance_to(position) < clear_radius:
			return false
	return true
