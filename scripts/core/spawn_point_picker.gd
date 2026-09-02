# SPDX-License-Identifier: GPL-2.0-or-later
#
# Picks a spawn point from a group, preferring one no living combatant
# currently stands near, and (optionally) one no living enemy stands near
# either. Shared by bot_spawner.gd (initial placement), action_respawn.gd (a
# bot's normal mid-match respawn), kill_zone.gd (falling out of bounds), and
# MatchState.restart_round() — the anti-overlap check guards a hazard common
# to all of them: landing on top of someone spawns two fully-overlapping
# CharacterBody3D capsules that immediately depenetrate into each other at
# high speed. Also claims a short-lived SpawnReservations hold on whatever it
# picks, since two different actors' respawns resolving within the same
# stretch of time can each fail to see the other as occupying anything yet.
class_name SpawnPointPicker


static func pick(tree: SceneTree, group: String, avoiding: Node, clear_radius: float, fallback: Vector3, enemy_avoid_radius: float = 0.0) -> Vector3:
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
		if not _is_clear(tree, point.global_position, avoiding, clear_radius, enemy_avoid_radius):
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


## clear_radius rules out any nearby living combatant (teammate or not) — the
## capsule-overlap hazard above. enemy_avoid_radius (0.0 disables it) is a
## second, usually much larger, check that only rules out proximity to a
## living *enemy* of `avoiding` — spawning near a teammate is fine and
## expected, since teams already cluster at their own spawn groups.
static func _is_clear(tree: SceneTree, position: Vector3, avoiding: Node, clear_radius: float, enemy_avoid_radius: float = 0.0) -> bool:
	var avoiding_team: int = avoiding.get_team_id() if avoiding and avoiding.has_method("get_team_id") else -1
	for combatant in tree.get_nodes_in_group("combatants"):
		if combatant == avoiding or not is_instance_valid(combatant):
			continue
		if combatant.has_method("is_alive") and not combatant.is_alive():
			continue

		var distance: float = combatant.global_position.distance_to(position)
		if distance < clear_radius:
			return false
		if enemy_avoid_radius > 0.0 and distance < enemy_avoid_radius \
				and avoiding_team != -1 and combatant.has_method("get_team_id") \
				and combatant.get_team_id() != avoiding_team:
			return false
	return true
