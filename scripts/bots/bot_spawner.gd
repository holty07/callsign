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
## Falls back to this node's own position if the map defines no markers in
## this group (see action_respawn.gd, which reads the same group).
@export var spawn_points_group: String = "bot_spawn_points"


func _ready() -> void:
	var positions := _spawn_positions_for(bot_count)
	for i in bot_count:
		_spawn_bot(i, positions[i])


func _spawn_bot(index: int, spawn_position: Vector3) -> void:
	var bot: Bot = bot_scene.instantiate()
	bot.name = "Bot%d" % (index + 1)
	add_child(bot)
	bot.global_position = spawn_position
	if difficulty:
		bot.apply_difficulty(difficulty)


## One position per bot, drawn from spawn_points_group without replacement
## as long as there are enough distinct markers — picking with replacement
## (the previous approach) let two bots land on the exact same marker,
## spawning two fully-overlapping CharacterBody3D capsules that immediately
## depenetrate into each other at high speed, the same class of bug fixed
## for HitZone colliders. Only wraps around (repeating positions) once the
## map has fewer markers than bots to spawn.
func _spawn_positions_for(count: int) -> Array[Vector3]:
	var markers := get_tree().get_nodes_in_group(spawn_points_group)
	var positions: Array[Vector3] = []

	if markers.is_empty():
		positions.resize(count)
		positions.fill(global_position)
		return positions

	var marker_positions: Array[Vector3] = []
	for marker in markers:
		marker_positions.append(marker.global_position)
	marker_positions.shuffle()

	for i in count:
		positions.append(marker_positions[i % marker_positions.size()])
	return positions
