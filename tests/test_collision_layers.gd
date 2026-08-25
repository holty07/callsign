# SPDX-License-Identifier: GPL-2.0-or-later
#
# Regression: a target's own CHARACTER_BODY movement capsule always
# encloses its smaller HitZone shapes. Without an explicit raycast mask
# excluding CHARACTER_BODY, WeaponBase's shot always registered a hit
# against that outer capsule first and never reached the HitZone nested
# inside it — bots (and the player) could shoot each other all day with
# zero damage. A pure-logic unit test can't catch this; it needs a real
# physics query against real collision shapes.
extends GdUnitTestSuite

var _previous_current_scene: Node
var _world: Node3D


func before_test() -> void:
	_previous_current_scene = get_tree().current_scene
	# WeaponFX.spawn_tracer() needs get_tree().current_scene to add its tracer
	# to, and current_scene must be a direct child of the tree root — a node
	# added under this test suite (itself nested under the runner) doesn't
	# qualify.
	_world = auto_free(Node3D.new())
	get_tree().root.add_child(_world)
	get_tree().current_scene = _world


func after_test() -> void:
	get_tree().current_scene = _previous_current_scene


func _fire_straight_shot_at(target_aim_point: Vector3) -> WeaponBase:
	var camera: Camera3D = auto_free(Camera3D.new())
	_world.add_child(camera)
	camera.global_position = Vector3(0.0, 1.65, 0.0)
	camera.look_at(target_aim_point, Vector3.UP)

	var weapon: WeaponBase = auto_free((load("res://scenes/weapons/rifle.tscn") as PackedScene).instantiate())
	camera.add_child(weapon)
	weapon.player_controlled = false
	weapon.hipfire_spread_deg = 0.0 # deterministic: dead centre, no RNG jitter

	# The physics server registers newly-added collision shapes once per
	# physics step, not synchronously with add_child() — firing immediately
	# queries against a physics state that doesn't know about them yet.
	await get_tree().physics_frame

	weapon.ai_fire_held = true
	weapon._physics_process(1.0 / 120.0)
	return weapon


func test_shot_damages_a_bots_hitzone_through_its_own_movement_capsule() -> void:
	var target: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	_world.add_child(target)
	target.global_position = Vector3(0.0, 0.0, -5.0)

	var damaged_flag := [false]
	target.health.damaged.connect(func(_amount, _headshot, _pos): damaged_flag[0] = true)

	await _fire_straight_shot_at(target.get_node("AimPoint").global_position)

	assert_bool(damaged_flag[0]).is_true()


func test_shot_damages_the_players_hitzone_through_its_own_movement_capsule() -> void:
	var target: PMove = auto_free((load("res://scenes/player/player.tscn") as PackedScene).instantiate())
	_world.add_child(target)
	target.global_position = Vector3(0.0, 0.0, -5.0)
	var target_health: Health = target.get_node("Health")

	var damaged_flag := [false]
	target_health.damaged.connect(func(_amount, _headshot, _pos): damaged_flag[0] = true)

	await _fire_straight_shot_at(target.get_node("AimPoint").global_position)

	assert_bool(damaged_flag[0]).is_true()
