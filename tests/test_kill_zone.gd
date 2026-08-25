# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_kill_zone_kills_and_respawns_a_bot() -> void:
	var spawn_marker: Marker3D = auto_free(Marker3D.new())
	add_child(spawn_marker)
	spawn_marker.global_position = Vector3(20.0, 0.0, 20.0)
	spawn_marker.add_to_group("bot_spawn_points_test")

	var kill_zone: Area3D = auto_free(KillZone.new())
	kill_zone.spawn_points_group = "bot_spawn_points_test"
	add_child(kill_zone)

	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	add_child(bot)
	bot.global_position = Vector3(0.0, -50.0, 0.0)

	var died_flag := [false]
	bot.health.died.connect(func(): died_flag[0] = true)

	kill_zone._on_body_entered(bot)

	assert_bool(died_flag[0]).is_true()
	assert_float(bot.health.current_health).is_equal(bot.health.max_health)
	assert_vector(bot.global_position).is_equal_approx(Vector3(20.0, 0.0, 20.0), Vector3(0.01, 0.01, 0.01))


func test_kill_zone_respawns_player_at_configured_marker() -> void:
	var spawn_marker: Marker3D = auto_free(Marker3D.new())
	add_child(spawn_marker)
	spawn_marker.global_position = Vector3(1.0, 2.0, 3.0)

	var kill_zone: Area3D = auto_free(KillZone.new())
	add_child(kill_zone)
	kill_zone.player_spawn_point_path = kill_zone.get_path_to(spawn_marker)

	var player: PMove = auto_free((load("res://scenes/player/player.tscn") as PackedScene).instantiate())
	add_child(player)
	player.global_position = Vector3(0.0, -50.0, 0.0)
	var player_health: Health = player.get_node("Health")
	player_health.apply_damage(40.0)

	kill_zone._on_body_entered(player)

	assert_float(player_health.current_health).is_equal(player_health.max_health)
	assert_vector(player.global_position).is_equal_approx(Vector3(1.0, 2.0, 3.0), Vector3(0.01, 0.01, 0.01))
