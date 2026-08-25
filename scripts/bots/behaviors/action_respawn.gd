# SPDX-License-Identifier: GPL-2.0-or-later
#
# While dead, this pre-empts every other branch (it's first in the root
# Selector) so a dead bot doesn't try to patrol or fight while waiting out
# its respawn timer. Picks a random "bot_spawn_points" marker, preferring
# one no living combatant currently stands near.
extends ActionLeaf

@export var respawn_delay: float = 3.0
## Below this distance from a living combatant, a spawn point is treated as
## occupied. Landing on top of someone spawns two fully-overlapping
## CharacterBody3D capsules that immediately depenetrate into each other at
## high speed — the same class of bug fixed for HitZone colliders and for
## BotSpawner's own initial placement, except this time on respawn, mid-match.
@export var clear_radius: float = 1.5

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
	return SpawnPointPicker.pick(bot.get_tree(), "bot_spawn_points", bot, clear_radius, bot.global_position)
