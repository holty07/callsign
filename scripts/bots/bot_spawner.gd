# SPDX-License-Identifier: GPL-2.0-or-later
#
# Bot count and difficulty for a match: exported so each map instance can
# set its own, and on by default per the roadmap's M3 "Done when" (a
# winnable 4-bot free-for-all). A real match-start menu to change these
# live is M4's job (see docs/ROADMAP.md) — this is the underlying knob
# that menu will drive once it exists.
class_name BotSpawner
extends Node3D

@export var bot_scene: PackedScene = preload("res://scenes/bots/bot.tscn")
@export var bot_count: int = 4
@export var difficulty: BotDifficulty = preload("res://scenes/bots/difficulty_normal.tres")
## When true (Team Deathmatch's default), bots alternate onto Team A/Team B —
## the player (Team A by default) fights alongside roughly half of them
## against the other half. When false, every bot lands on Team B and the
## player is alone on Team A.
@export var split_bots_across_teams: bool = true
## Falls back to this node's own position if the map defines no markers in
## the relevant group (see action_respawn.gd, which reads the same groups).
@export var team_a_spawn_points_group: String = "team_a_spawn_points"
@export var team_b_spawn_points_group: String = "team_b_spawn_points"
## Same hazard SpawnPointPicker guards against elsewhere: landing on top of
## a living combatant spawns two fully-overlapping CharacterBody3D capsules
## that immediately depenetrate into each other at high speed.
@export var clear_radius: float = 1.5


## Deferred a frame rather than spawning inline: _ready() runs in sibling
## declaration order, so querying spawn_points_group here would run before
## sibling marker nodes later in the tree have had their own _ready() call
## add_to_group() — exactly what happened when BotSpawner was declared
## before its map's spawn-point markers, silently falling back to this
## node's own position for every bot (all 4 spawned stacked on top of each
## other at the same point and flung each other away on contact). Waiting
## a frame makes this correct regardless of node order.
func _ready() -> void:
	await get_tree().process_frame
	for i in bot_count:
		_spawn_bot(i)


## Spawns and places one bot at a time (rather than pre-computing every
## position up front) so each pick sees the previous bots already standing
## where SpawnPointPicker put them — the same shared occupancy/reservation
## check every other respawn path uses, instead of a separate
## without-replacement shuffle that silently doubled bots up onto the same
## marker whenever the map had fewer markers than bot_count.
func _spawn_bot(index: int) -> void:
	var bot: Bot = bot_scene.instantiate()
	bot.name = "Bot%d" % (index + 1)
	# Assigned before add_child() so _ready() (which tints the bot by team,
	# see bot.gd) already sees the right team_id.
	bot.team_id = (Team.A if index % 2 == 0 else Team.B) if split_bots_across_teams else Team.B
	add_child(bot)
	var group := team_a_spawn_points_group if bot.team_id == Team.A else team_b_spawn_points_group
	bot.global_position = SpawnPointPicker.pick(get_tree(), group, bot, clear_radius, global_position)
	if difficulty:
		bot.apply_difficulty(difficulty)
	print("%s spawned at %s (team %d)" % [bot.name, bot.global_position, bot.team_id])
