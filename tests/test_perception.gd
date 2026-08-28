# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_angle_within_fov_true_straight_ahead() -> void:
	var forward := Vector3(0.0, 0.0, -1.0)
	var to_target := Vector3(0.0, 0.0, -10.0)
	assert_bool(Perception.angle_within_fov(forward, to_target, 100.0)).is_true()


func test_angle_within_fov_false_directly_behind() -> void:
	var forward := Vector3(0.0, 0.0, -1.0)
	var to_target := Vector3(0.0, 0.0, 10.0)
	assert_bool(Perception.angle_within_fov(forward, to_target, 100.0)).is_false()


func test_angle_within_fov_respects_half_angle_boundary() -> void:
	var forward := Vector3(0.0, 0.0, -1.0)
	# 40 degrees off-axis: inside a 100-degree FOV (half-angle 50), outside an 60-degree one (half-angle 30).
	var to_target := Vector3(sin(deg_to_rad(40.0)), 0.0, -cos(deg_to_rad(40.0)))
	assert_bool(Perception.angle_within_fov(forward, to_target, 100.0)).is_true()
	assert_bool(Perception.angle_within_fov(forward, to_target, 60.0)).is_false()


func test_angle_within_fov_true_for_zero_distance_target() -> void:
	var forward := Vector3(0.0, 0.0, -1.0)
	assert_bool(Perception.angle_within_fov(forward, Vector3.ZERO, 10.0)).is_true()


func test_should_confirm_sighting_requires_full_reaction_delay() -> void:
	assert_bool(Perception.should_confirm_sighting(0.1, 0.25)).is_false()
	assert_bool(Perception.should_confirm_sighting(0.25, 0.25)).is_true()
	assert_bool(Perception.should_confirm_sighting(0.5, 0.25)).is_true()


func test_should_forget_requires_full_memory_duration() -> void:
	assert_bool(Perception.should_forget(2.0, 5.0)).is_false()
	assert_bool(Perception.should_forget(5.0, 5.0)).is_true()
	assert_bool(Perception.should_forget(10.0, 5.0)).is_true()


func test_pick_target_returns_null_with_no_confirmed_sightings() -> void:
	assert_object(Perception.pick_target(null, {})).is_null()


func test_pick_target_picks_nearest_when_no_current_target() -> void:
	var near := Node3D.new()
	var far := Node3D.new()
	var result := Perception.pick_target(null, {near: 5.0, far: 12.0})
	assert_object(result).is_same(near)
	near.free()
	far.free()


func test_pick_target_sticks_with_current_target_even_if_no_longer_nearest() -> void:
	# Regression: always snapping to "nearest" made two combatants at similar
	# range trade the confirmed target back and forth almost every tick as
	# they moved, which kept resetting aim.gd's reacquire timer before it
	# ever elapsed — bots would track a target but never actually fire on
	# it. A bot must keep fighting whoever it's already locked onto as long
	# as that target is still confirmed visible, regardless of who's closer.
	var current_target := Node3D.new()
	var nearer_target := Node3D.new()
	var result := Perception.pick_target(current_target, {current_target: 10.0, nearer_target: 4.0})
	assert_object(result).is_same(current_target)
	current_target.free()
	nearer_target.free()


func test_pick_target_switches_once_current_target_drops_out() -> void:
	var old_target := Node3D.new()
	var new_target := Node3D.new()
	var result := Perception.pick_target(old_target, {new_target: 6.0})
	assert_object(result).is_same(new_target)
	old_target.free()
	new_target.free()
