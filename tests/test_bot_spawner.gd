# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_spawner_spawns_configured_bot_count() -> void:
	var spawner: BotSpawner = auto_free(BotSpawner.new())
	spawner.bot_count = 3
	add_child(spawner)
	await get_tree().process_frame

	var bots := 0
	for child in spawner.get_children():
		if child is Bot:
			bots += 1

	assert_int(bots).is_equal(3)


func test_spawner_applies_difficulty_to_every_bot() -> void:
	var spawner: BotSpawner = auto_free(BotSpawner.new())
	spawner.bot_count = 2
	spawner.difficulty = load("res://scenes/bots/difficulty_hard.tres")
	add_child(spawner)
	await get_tree().process_frame

	for child in spawner.get_children():
		if child is Bot:
			assert_float(child.aim.error_cone_deg).is_equal(spawner.difficulty.error_cone_deg)


func test_spawner_falls_back_to_own_position_with_no_spawn_points() -> void:
	var spawner: BotSpawner = auto_free(BotSpawner.new())
	spawner.bot_count = 1
	spawner.spawn_points_group = "no_such_group_in_this_test"
	spawner.global_position = Vector3(1.0, 2.0, 3.0)
	add_child(spawner)
	await get_tree().process_frame

	for child in spawner.get_children():
		if child is Bot:
			assert_vector(child.global_position).is_equal_approx(Vector3(1.0, 2.0, 3.0), Vector3(0.01, 0.01, 0.01))


func test_spawner_assigns_distinct_positions_when_enough_markers_exist() -> void:
	# Regression: picking a spawn point with replacement let two bots land on
	# the exact same marker, spawning fully-overlapping CharacterBody3D
	# capsules that immediately depenetrate into each other at high speed.
	var group := "distinct_spawn_test_markers"
	var marker_positions := [Vector3(0.0, 0.0, 0.0), Vector3(5.0, 0.0, 0.0), Vector3(10.0, 0.0, 0.0), Vector3(15.0, 0.0, 0.0)]
	for position in marker_positions:
		var marker: Marker3D = auto_free(Marker3D.new())
		add_child(marker)
		marker.global_position = position
		marker.add_to_group(group)

	var spawner: BotSpawner = auto_free(BotSpawner.new())
	spawner.bot_count = 4
	spawner.spawn_points_group = group
	add_child(spawner)
	await get_tree().process_frame

	var seen_positions: Array[Vector3] = []
	for child in spawner.get_children():
		if child is Bot:
			seen_positions.append(child.global_position)

	assert_int(seen_positions.size()).is_equal(4)
	for i in seen_positions.size():
		for j in range(i + 1, seen_positions.size()):
			assert_float(seen_positions[i].distance_to(seen_positions[j])).is_greater(0.01)


func test_spawner_finds_markers_declared_as_later_siblings() -> void:
	# Regression: BotSpawner is declared as a sibling before its map's
	# marker nodes in test_box.tscn. _ready() runs in sibling declaration
	# order, so querying the group inline (not deferred a frame) found
	# nothing — every bot fell back to BotSpawner's own position and spawned
	# stacked on top of each other. Mirrors that ordering here: the marker
	# is added as a LATER sibling of the spawner.
	var spawner: BotSpawner = auto_free(BotSpawner.new())
	spawner.bot_count = 1
	spawner.spawn_points_group = "later_sibling_markers"
	add_child(spawner)

	var marker: Marker3D = auto_free(Marker3D.new())
	add_child(marker)
	marker.global_position = Vector3(7.0, 0.0, 7.0)
	marker.add_to_group("later_sibling_markers")

	await get_tree().process_frame

	for child in spawner.get_children():
		if child is Bot:
			assert_vector(child.global_position).is_equal_approx(Vector3(7.0, 0.0, 7.0), Vector3(0.01, 0.01, 0.01))


func test_test_box_map_spawns_four_bots_by_default() -> void:
	# Validates the actual map wiring (test_box.tscn's BotSpawner node and
	# its spawn-point markers), not just the BotSpawner class in isolation —
	# catches the class of NodePath/group-name typo a pure unit test can't.
	var map: Node = auto_free((load("res://scenes/maps/test_box.tscn") as PackedScene).instantiate())
	add_child(map)
	await get_tree().process_frame

	var spawner: BotSpawner = map.get_node("BotSpawner")
	var bots := 0
	for child in spawner.get_children():
		if child is Bot:
			bots += 1

	assert_int(bots).is_equal(4)


func test_test_box_map_bots_do_not_all_spawn_at_the_origin() -> void:
	# The actual symptom reported: every bot spawned at (0, 0, 0) because
	# the group query ran before the map's marker nodes were ready.
	var map: Node = auto_free((load("res://scenes/maps/test_box.tscn") as PackedScene).instantiate())
	add_child(map)
	await get_tree().process_frame

	var spawner: BotSpawner = map.get_node("BotSpawner")
	for child in spawner.get_children():
		if child is Bot:
			assert_vector(child.global_position).is_not_equal(Vector3.ZERO)
