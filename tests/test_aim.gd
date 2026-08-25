# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_clamp_turn_step_reaches_target_within_budget() -> void:
	var result := BotAim.clamp_turn_step(0.0, deg_to_rad(10.0), deg_to_rad(30.0))
	assert_float(result).is_equal_approx(deg_to_rad(10.0), 0.0001)


func test_clamp_turn_step_is_limited_by_max_step() -> void:
	var result := BotAim.clamp_turn_step(0.0, deg_to_rad(90.0), deg_to_rad(30.0))
	assert_float(result).is_equal_approx(deg_to_rad(30.0), 0.0001)


func test_clamp_turn_step_moves_the_short_way_around_the_wrap() -> void:
	# From 170 degrees toward -170 degrees: the short way is +20 degrees
	# (through 180), not the long way back across zero. The result isn't
	# renormalized into [-180, 180] — 190 degrees is the same orientation
	# as -170 and this only ever feeds a Node3D rotation, which doesn't care.
	var result := BotAim.clamp_turn_step(deg_to_rad(170.0), deg_to_rad(-170.0), deg_to_rad(30.0))
	assert_float(result).is_equal_approx(deg_to_rad(190.0), 0.0001)


func test_should_end_burst_false_before_burst_length_reached() -> void:
	assert_bool(BotAim.should_end_burst(2, 5)).is_false()


func test_should_end_burst_true_at_or_past_burst_length() -> void:
	assert_bool(BotAim.should_end_burst(5, 5)).is_true()
	assert_bool(BotAim.should_end_burst(6, 5)).is_true()


func test_is_pause_over() -> void:
	assert_bool(BotAim.is_pause_over(0.1)).is_false()
	assert_bool(BotAim.is_pause_over(0.0)).is_true()
	assert_bool(BotAim.is_pause_over(-0.1)).is_true()


func test_has_reacquired_requires_full_delay() -> void:
	assert_bool(BotAim.has_reacquired(0.1, 0.2)).is_false()
	assert_bool(BotAim.has_reacquired(0.2, 0.2)).is_true()
