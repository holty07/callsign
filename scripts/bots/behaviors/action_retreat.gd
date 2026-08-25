# SPDX-License-Identifier: GPL-2.0-or-later
#
# Falls back away from whatever threat we're aware of once health drops
# below health_fraction_threshold — the most urgent branch of the tree
# short of respawning, so it pre-empts take-cover/engage/reposition below
# it in the Selector.
extends ActionLeaf

@export var health_fraction_threshold: float = 0.25
@export var retreat_distance: float = 8.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var bot: Bot = actor
	if not bot.perception.is_aware_of_threat():
		return FAILURE
	if bot.health.current_health > bot.health.max_health * health_fraction_threshold:
		return FAILURE

	var away := bot.global_position - _threat_position(bot)
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3.FORWARD # arbitrary direction if standing right on the threat's position
	bot.move_to(bot.global_position + away.normalized() * retreat_distance)
	return RUNNING


func _threat_position(bot: Bot) -> Vector3:
	var target := bot.perception.get_confirmed_target()
	if target:
		return target.global_position
	if bot.perception.has_any_memory():
		return bot.perception.get_any_last_known_position()
	return bot.perception.get_noise_position()
