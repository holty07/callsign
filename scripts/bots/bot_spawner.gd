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
	for _i in bot_count:
		_spawn_bot()


func _spawn_bot() -> void:
	var bot: Bot = bot_scene.instantiate()
	add_child(bot)
	bot.global_position = _pick_spawn_position()
	if difficulty:
		bot.apply_difficulty(difficulty)


func _pick_spawn_position() -> Vector3:
	var points := get_tree().get_nodes_in_group(spawn_points_group)
	if points.is_empty():
		return global_position
	return points[randi() % points.size()].global_position
