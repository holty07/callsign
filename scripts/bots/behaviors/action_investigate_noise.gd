# SPDX-License-Identifier: GPL-2.0-or-later
#
# Reacts to a heard-but-unseen alert (gunfire, via NoiseBus) by walking
# over to where it came from. Perception.clear_noise_memory() on arrival
# so the same alert doesn't keep re-triggering this every tick.
extends ActionLeaf

@export var arrival_distance: float = 1.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var bot: Bot = actor
	if not bot.perception.has_noise_memory():
		return FAILURE

	var noise_position := bot.perception.get_noise_position()
	bot.move_to(noise_position)

	if bot.global_position.distance_to(noise_position) <= arrival_distance:
		bot.perception.clear_noise_memory()
		return SUCCESS

	return RUNNING
