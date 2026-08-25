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
