# SPDX-License-Identifier: GPL-2.0-or-later
#
# Picks a spawn point from a group, preferring one no living combatant
# currently stands near. Shared by bot_spawner.gd (initial placement),
# action_respawn.gd (a bot's normal mid-match respawn) and kill_zone.gd
# (falling out of bounds) — all three hit the same hazard: landing on top
# of someone spawns two fully-overlapping CharacterBody3D capsules that
# immediately depenetrate into each other at high speed. Also claims a
# short-lived SpawnReservations hold on whatever it picks, since two
# different actors' respawns resolving within the same stretch of time can
# each fail to see the other as occupying anything yet.
class_name SpawnPointPicker


static func pick(tree: SceneTree, group: String, avoiding: Node, clear_radius: float, fallback: Vector3) -> Vector3:
	var points := tree.get_nodes_in_group(group)
	if points.is_empty():
		return fallback

	var shuffled: Array = points.duplicate()
	shuffled.shuffle()

	# A point with a living combatant standing on it is never acceptable
	# short of every single point being occupied (handled below). A clear
	# point someone else just reserved is a lesser risk than that — worth
	# preferring over it, but not worth treating as if it were occupied.
	var clear_but_reserved: Node = null
	for point in shuffled:
		if not _is_clear(tree, point.global_position, avoiding, clear_radius):
			continue
		if SpawnReservations.is_reserved(point):
			if clear_but_reserved == null:
				clear_but_reserved = point
			continue
		SpawnReservations.reserve(point)
		return point.global_position

	if clear_but_reserved != null:
		SpawnReservations.reserve(clear_but_reserved)
		return clear_but_reserved.global_position

	# every point currently has a living combatant standing on it; take one
	# anyway rather than not respawning at all.
	SpawnReservations.reserve(shuffled[0])
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
