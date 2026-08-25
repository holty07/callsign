# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_apply_difficulty_pushes_values_onto_perception_aim_and_weapon() -> void:
	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	add_child(bot)

	var profile := BotDifficulty.new()
	profile.fov_deg = 77.0
	profile.reaction_delay = 0.42
	profile.memory_duration = 6.5
	profile.error_cone_deg = 4.4
	profile.turn_rate_deg = 199.0
	profile.hipfire_spread_deg = 2.2

	bot.apply_difficulty(profile)

	assert_float(bot.perception.fov_deg).is_equal(77.0)
	assert_float(bot.perception.reaction_delay).is_equal(0.42)
	assert_float(bot.perception.memory_duration).is_equal(6.5)
	assert_float(bot.aim.error_cone_deg).is_equal(4.4)
	assert_float(bot.aim.turn_rate_deg).is_equal(199.0)
	assert_float(bot.weapon.hipfire_spread_deg).is_equal(2.2)


func test_apply_difficulty_never_touches_health() -> void:
	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	add_child(bot)
	var max_health_before := bot.health.max_health

	var profile := BotDifficulty.new()
	bot.apply_difficulty(profile)

	assert_float(bot.health.max_health).is_equal(max_health_before)


func test_difficulty_presets_load_and_differ() -> void:
	var easy: BotDifficulty = load("res://scenes/bots/difficulty_easy.tres")
	var hard: BotDifficulty = load("res://scenes/bots/difficulty_hard.tres")

	assert_float(easy.reaction_delay).is_greater(hard.reaction_delay)
	assert_float(easy.error_cone_deg).is_greater(hard.error_cone_deg)
	assert_float(easy.hipfire_spread_deg).is_greater(hard.hipfire_spread_deg)
