# SPDX-License-Identifier: GPL-2.0-or-later
#
# Regression: bots never moved at all. The baked NavigationMesh had zero
# vertices and zero polygons — CSGBox3D's use_collision=true registers its
# collider directly with PhysicsServer3D rather than as a discoverable
# StaticBody3D/CollisionShape3D node, so geometry_parsed_geometry_type =
# STATIC_COLLIDERS (which walks the node tree for physics body nodes) found
# nothing to bake from. Separately, even after switching to MESH_INSTANCES
# (which Godot's baker specifically knows how to pull CSGShape3D geometry
# from via get_meshes()), baking synchronously in _ready() ran before CSG
# shapes had built that combined mesh — still zero polygons. Needed both:
# MESH_INSTANCES *and* deferring the bake a physics frame.
extends GdUnitTestSuite

var _previous_current_scene: Node


func before_test() -> void:
	_previous_current_scene = get_tree().current_scene


func after_test() -> void:
	get_tree().current_scene = _previous_current_scene


func _load_map() -> Node:
	var map: Node = auto_free((load("res://scenes/maps/test_box.tscn") as PackedScene).instantiate())
	get_tree().root.add_child(map)
	get_tree().current_scene = map
	for _i in range(5):
		await get_tree().physics_frame
	return map


func test_navmesh_actually_has_polygons_after_baking() -> void:
	var map := await _load_map()
	var region: NavigationRegion3D = map.get_node("NavigationRegion3D")
	assert_int(region.navigation_mesh.get_polygon_count()).is_greater(0)


func test_bot_actually_moves_toward_a_move_to_target_on_the_real_map() -> void:
	var map := await _load_map()

	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	map.add_child(bot)
	bot.global_position = Vector3(4.0, 0.1, 0.0)
	for _i in range(3):
		await get_tree().physics_frame

	var start_pos := bot.global_position
	bot.move_to(Vector3(4.0, 0.1, -10.0))

	for _i in range(120):
		await get_tree().physics_frame

	# Before the fix this was ~0.001m of pure floating-point jitter — no path
	# was ever found, so wish_velocity stayed zero forever. The map's own
	# Player is close enough that the bot may perceive and Engage them
	# before reaching the full 10m target (correctly stopping to fight), so
	# this only checks that genuine nav-driven movement happened at all.
	assert_float(bot.global_position.distance_to(start_pos)).is_greater(0.2)
