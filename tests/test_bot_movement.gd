# SPDX-License-Identifier: GPL-2.0-or-later
#
# Diagnostic regression test: a single bot on a minimal flat map, with no
# props, respawn logic, combat, or other bots, commanded to a target 15
# units away in a dead-straight line. This is expected to FAIL as of
# writing — see scenes/maps/nav_debug.tscn and the [bot-debug] pipeline log
# (wish_velocity / velocity_before_move / velocity_after_move) added to
# bot.gd and debug_visuals.gd for this diagnosis session. Do not "fix" this
# test by loosening the threshold; it is meant to stay red until the actual
# movement break is found and fixed.
extends GdUnitTestSuite

var _previous_current_scene: Node


func before_test() -> void:
	_previous_current_scene = get_tree().current_scene


func after_test() -> void:
	get_tree().current_scene = _previous_current_scene


func _load_map() -> Node:
	var map: Node = auto_free((load("res://scenes/maps/nav_debug.tscn") as PackedScene).instantiate())
	get_tree().root.add_child(map)
	get_tree().current_scene = map
	for _i in range(5):
		await get_tree().physics_frame
	return map


func test_bot_travels_towards_a_target_15_units_away_on_a_minimal_flat_map() -> void:
	var map := await _load_map()

	var bot: Bot = map.get_node("Bot")
	var target: Marker3D = map.get_node("TargetMarker")
	var start_position := bot.global_position

	bot.move_to(target.global_position)

	for _i in range(120):
		await get_tree().physics_frame

	var travelled := bot.global_position.distance_to(start_position)
	print("[test] bot travelled %.3fm toward target (start=%s end=%s)" % [travelled, start_position, bot.global_position])
	assert_float(travelled).is_greater(2.0)
