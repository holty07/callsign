# SPDX-License-Identifier: GPL-2.0-or-later
#
# Holds ground while aim.gd does the actual turning and shooting — that
# runs every physics tick regardless of the behaviour tree, the same way
# the player's own aim isn't gated by anything. This leaf's job is the
# tactical decision: while a target is confirmed, stop repositioning and
# fight where we stand.
extends ActionLeaf

const BLACKBOARD_LAST_ENGAGED := "last_engaged_target"


func tick(actor: Node, blackboard: Blackboard) -> int:
	var bot: Bot = actor
	var target := bot.perception.get_confirmed_target()
	if target == null:
		return FAILURE

	blackboard.set_value(BLACKBOARD_LAST_ENGAGED, target)
	bot.stop_moving()
	return RUNNING
