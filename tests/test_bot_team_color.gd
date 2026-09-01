# SPDX-License-Identifier: GPL-2.0-or-later
#
# Regression: TorsoBody/HeadHitZone's MeshInstance3D nodes share one
# StandardMaterial3D sub-resource across every bot.tscn instance. Recolouring
# it in place instead of duplicating first would repaint every other bot on
# the map the same colour the moment a second one spawns.
extends GdUnitTestSuite


func _torso_color(bot: Bot) -> Color:
	var mesh: MeshInstance3D = bot.get_node("Visual/TorsoBody/MeshInstance3D")
	return mesh.material_override.albedo_color


func test_team_a_bot_is_tinted_team_a_color() -> void:
	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	bot.team_id = Team.A
	add_child(bot)

	assert_object(_torso_color(bot)).is_equal(bot.team_a_color)


func test_team_b_bot_is_tinted_team_b_color() -> void:
	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	bot.team_id = Team.B
	add_child(bot)

	assert_object(_torso_color(bot)).is_equal(bot.team_b_color)


func test_bots_do_not_share_a_tinted_material_instance() -> void:
	var bot_a: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	bot_a.team_id = Team.A
	add_child(bot_a)

	var bot_b: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	bot_b.team_id = Team.B
	add_child(bot_b)

	assert_object(_torso_color(bot_a)).is_equal(bot_a.team_a_color)
	assert_object(_torso_color(bot_b)).is_equal(bot_b.team_b_color)
