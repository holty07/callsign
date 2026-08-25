# SPDX-License-Identifier: GPL-2.0-or-later
#
# Just lost sight of whoever we were fighting (action_engage.gd records
# them on the blackboard while it runs). Move toward where we last saw
# them to try to line up a shot again, instead of freezing in place or
# giving up the instant line of sight breaks.
extends ActionLeaf

const BLACKBOARD_LAST_ENGAGED := "last_engaged_target"


func tick(actor: Node, blackboard: Blackboard) -> int:
	var bot: Bot = actor
	if bot.perception.get_confirmed_target() != null:
		return FAILURE # still (or already re-)engaged — let action_engage handle it

	var target: Node3D = blackboard.get_value(BLACKBOARD_LAST_ENGAGED, null)
	if target == null or not is_instance_valid(target) or not bot.perception.has_memory_of(target):
		return FAILURE

	bot.move_to(bot.perception.get_last_known_position(target))
	return RUNNING
