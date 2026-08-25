# SPDX-License-Identifier: GPL-2.0-or-later
#
# Regression: a bot respawning mid-match picked a random spawn point with
# replacement, with no regard for where other living combatants currently
# stand — landing on top of one spawns two fully-overlapping
# CharacterBody3D capsules that immediately depenetrate into each other at
# high speed. The log would correctly report the respawn, but the bot
# could be flung off somewhere else entirely on the very same tick.
extends GdUnitTestSuite


func _make_marker(position: Vector3, group: String) -> Marker3D:
	var marker: Marker3D = auto_free(Marker3D.new())
	add_child(marker)
	marker.global_position = position
	marker.add_to_group(group)
	return marker


func test_pick_avoids_a_point_occupied_by_a_living_combatant() -> void:
	var group := "picker_test_markers_avoid"
	var occupied := _make_marker(Vector3(0.0, 0.0, 0.0), group)
	var clear := _make_marker(Vector3(20.0, 0.0, 20.0), group)

	var occupant: CharacterBody3D = auto_free(CharacterBody3D.new())
	add_child(occupant)
	occupant.global_position = occupied.global_position
	occupant.add_to_group("combatants")

	# `avoiding` is the bot being placed (so it never self-excludes), not
	# the occupant standing on the other point — a distinct node.
	for _i in range(10): # random with replacement — check it's never the occupied one
		var result := SpawnPointPicker.pick(get_tree(), group, null, 1.5, Vector3.ZERO)
		assert_vector(result).is_equal_approx(clear.global_position, Vector3(0.01, 0.01, 0.01))


func test_pick_ignores_dead_combatants_when_checking_occupancy() -> void:
	var group := "picker_test_markers_dead"
	var point := _make_marker(Vector3(5.0, 0.0, 5.0), group)

	# A real Bot, so has_method("is_alive") resolves truthily and returns
	# false once dead — the occupancy check must then ignore it.
	var dead_bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	add_child(dead_bot)
	dead_bot.global_position = point.global_position
	dead_bot.health.apply_damage(dead_bot.health.max_health)
	assert_bool(dead_bot.is_alive()).is_false()

	var result := SpawnPointPicker.pick(get_tree(), group, null, 1.5, Vector3(-1.0, -1.0, -1.0))
	assert_vector(result).is_equal_approx(point.global_position, Vector3(0.01, 0.01, 0.01))


func test_pick_falls_back_to_the_given_position_with_no_markers() -> void:
	var result := SpawnPointPicker.pick(get_tree(), "no_such_group_here", null, 1.5, Vector3(9.0, 9.0, 9.0))
	assert_vector(result).is_equal_approx(Vector3(9.0, 9.0, 9.0), Vector3(0.01, 0.01, 0.01))


func test_pick_returns_a_point_anyway_when_every_point_is_occupied() -> void:
	var group := "picker_test_markers_all_occupied"
	var only_point := _make_marker(Vector3(3.0, 0.0, 3.0), group)

	var occupant: CharacterBody3D = auto_free(CharacterBody3D.new())
	add_child(occupant)
	occupant.global_position = only_point.global_position
	occupant.add_to_group("combatants")

	# `avoiding` is null here (a distinct bot being placed) so the occupant
	# genuinely blocks the only point, forcing the "take it anyway" fallback.
	var result := SpawnPointPicker.pick(get_tree(), group, null, 1.5, Vector3.ZERO)
	assert_vector(result).is_equal_approx(only_point.global_position, Vector3(0.01, 0.01, 0.01))
