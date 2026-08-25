# SPDX-License-Identifier: GPL-2.0-or-later
#
# Moves to the nearest "cover_points" marker once health drops below
# health_fraction_threshold and a threat is known about — less urgent than
# retreating outright, more urgent than continuing to trade shots in the
# open. Falls through (FAILURE) if the current map has no cover points
# defined yet, rather than getting stuck trying to reach nothing.
extends ActionLeaf

@export var health_fraction_threshold: float = 0.5


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var bot: Bot = actor
	if not bot.perception.is_aware_of_threat():
		return FAILURE
	if bot.health.current_health > bot.health.max_health * health_fraction_threshold:
		return FAILURE

	var cover_point := _nearest_cover_point(bot)
	if cover_point == null:
		return FAILURE

	bot.move_to(cover_point.global_position)
	if bot.global_position.distance_to(cover_point.global_position) <= bot.arrival_distance:
		return SUCCESS
	return RUNNING


func _nearest_cover_point(bot: Bot) -> Node3D:
	var nearest: Node3D = null
	var nearest_distance := INF
	for point in bot.get_tree().get_nodes_in_group("cover_points"):
		if point is Node3D:
			var distance := bot.global_position.distance_to(point.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = point
	return nearest
