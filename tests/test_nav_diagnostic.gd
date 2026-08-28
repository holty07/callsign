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
	# NavigationBaker settles for _COLD_START_SETTLE_FRAMES (10) before its
	# first bake attempt — see that constant's comment for why. 20 clears
	# that plus the bake itself with margin to spare.
	for _i in range(20):
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


## Unlike the test above, this drives movement purely through the real
## BotSpawner + behaviour tree wiring on the actual map — no manual
## move_to() call — to catch the class of bug a hand-driven test can't:
## every bot immediately perceiving someone and holding Engage's
## stop_moving() forever, or any other reason Patrol never gets a turn in
## the real multi-bot/player scene.
func test_spawned_bots_actually_displace_from_their_spawn_point_over_time() -> void:
	var map := await _load_map()

	var spawner: BotSpawner = map.get_node("BotSpawner")
	var start_positions: Dictionary = {} # Bot -> Vector3
	for child in spawner.get_children():
		if child is Bot:
			start_positions[child] = child.global_position

	assert_int(start_positions.size()).is_greater(0)

	for _i in range(300): # 2.5s at 120Hz — enough for reaction_delay + a step or two
		await get_tree().physics_frame

	for bot in start_positions:
		var displacement: float = bot.global_position.distance_to(start_positions[bot])
		print("[test] %s displaced %.3fm from spawn (alive=%s)" % [bot.name, displacement, bot.is_alive()])
		# A dead bot (killed in the crossfire) is a legitimate reason to have
		# stopped moving — see bot.gd's is_alive() gate on nav movement — so
		# only living bots are held to "actually moved".
		if bot.is_alive():
			assert_float(displacement).is_greater(0.1)


## Regression: action_engage.gd calls bot.stop_moving() on every single tick
## it holds ground (not just once, when engagement starts) — the same
## RUNNING leaf re-ticks every physics frame for as long as a target stays
## confirmed, which in the real 4-bot map is close to the whole match.
## Reassigning NavigationAgent3D.target_position that often, even to the
## bot's own already-current position, keeps re-triggering a repath before
## the previous one resolves, so is_navigation_finished() can get stuck
## reporting false forever — flaky under the old code (it raced the
## NavigationServer and sometimes won), reliably reproduced by holding it
## for long enough here.
func test_repeatedly_calling_stop_moving_does_not_wedge_navigation() -> void:
	var map := await _load_map()
	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	map.add_child(bot)
	bot.global_position = Vector3(4.0, 0.1, 0.0)
	for _i in range(3):
		await get_tree().physics_frame

	# Get a real path in flight first, the way a bot mid-Patrol would have
	# one when it suddenly perceives a target and Engage takes over.
	bot.move_to(Vector3(4.0, 0.1, -10.0))
	for _i in range(10):
		await get_tree().physics_frame

	# Only the first of these actually reassigns target_position — see the
	# _has_commanded_target guard in bot.gd. Polls with a generous budget
	# rather than a fixed tick count: NavigationServer settle time varies
	# with system load (this suite runs many navmesh bakes back to back),
	# and that variance isn't the bug under test here — a wedged agent
	# never finishes no matter how long you wait, a merely-slow one does.
	for _i in range(900):
		bot.stop_moving()
		await get_tree().physics_frame
		if bot.is_move_finished():
			break

	print("[diag] after repeated stop_moving(): is_move_finished=%s pos=%s" % [bot.is_move_finished(), bot.global_position])
	assert_bool(bot.is_move_finished()).is_true()
