# SPDX-License-Identifier: GPL-2.0-or-later
#
# Confirms the test map's baked navmesh agent dimensions actually match the
# player's own collision hull, rather than drifting from Godot's defaults
# (agent_radius 0.6, agent_height 1.5) unnoticed.
extends GdUnitTestSuite


func test_navmesh_agent_radius_matches_player_hull() -> void:
	var player: PMove = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	var capsule: CapsuleShape3D = player.get_node("CollisionShape3D").shape
	var map: Node = (load("res://scenes/maps/test_box.tscn") as PackedScene).instantiate()
	var nav_region: NavigationRegion3D = map.get_node("NavigationRegion3D")

	assert_float(nav_region.navigation_mesh.agent_radius).is_equal_approx(capsule.radius, 0.001)

	player.free()
	map.free()


func test_navmesh_agent_height_matches_player_standing_height() -> void:
	var player: PMove = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	var map: Node = (load("res://scenes/maps/test_box.tscn") as PackedScene).instantiate()
	var nav_region: NavigationRegion3D = map.get_node("NavigationRegion3D")

	assert_float(nav_region.navigation_mesh.agent_height).is_equal_approx(player.standing_height, 0.001)

	player.free()
	map.free()


func test_navmesh_agent_climb_matches_player_step_height() -> void:
	var player: PMove = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	var map: Node = (load("res://scenes/maps/test_box.tscn") as PackedScene).instantiate()
	var nav_region: NavigationRegion3D = map.get_node("NavigationRegion3D")

	assert_float(nav_region.navigation_mesh.agent_max_climb).is_equal_approx(player.max_step_height, 0.001)

	player.free()
	map.free()
