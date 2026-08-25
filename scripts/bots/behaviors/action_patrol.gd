# SPDX-License-Identifier: GPL-2.0-or-later
#
# Default behaviour once nothing more urgent applies: walk the
# "bot_waypoints" markers in a loop. Harmless no-op (SUCCESS) if a map
# defines none, rather than getting stuck trying to path nowhere.
extends ActionLeaf

const BLACKBOARD_WAYPOINT_INDEX := "patrol_waypoint_index"


func tick(actor: Node, blackboard: Blackboard) -> int:
	var bot: Bot = actor
	var waypoints := bot.get_tree().get_nodes_in_group("bot_waypoints")
	if waypoints.is_empty():
		return SUCCESS

	var index: int = blackboard.get_value(BLACKBOARD_WAYPOINT_INDEX, 0) % waypoints.size()
	var target: Node3D = waypoints[index]
	bot.move_to(target.global_position)

	if bot.is_move_finished():
		blackboard.set_value(BLACKBOARD_WAYPOINT_INDEX, (index + 1) % waypoints.size())

	return RUNNING
