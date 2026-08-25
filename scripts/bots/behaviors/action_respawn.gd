# SPDX-License-Identifier: GPL-2.0-or-later
#
# While dead, this pre-empts every other branch (it's first in the root
# Selector) so a dead bot doesn't try to patrol or fight while waiting out
# its respawn timer. Picks a random "bot_spawn_points" marker so a bot
# doesn't reliably reappear in the same spot it just died in.
extends ActionLeaf

@export var respawn_delay: float = 3.0

var _timer: float = -1.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var bot: Bot = actor
	if bot.is_alive():
		_timer = -1.0
		return FAILURE

	if _timer < 0.0:
		_timer = respawn_delay

	_timer -= bot.get_physics_process_delta_time()
	if _timer > 0.0:
		return RUNNING

	bot.respawn_at(_spawn_position(bot))
	_timer = -1.0
	return SUCCESS


func _spawn_position(bot: Bot) -> Vector3:
	var points := bot.get_tree().get_nodes_in_group("bot_spawn_points")
	if points.is_empty():
		return bot.global_position
	return points[randi() % points.size()].global_position
