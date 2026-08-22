# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_damage_falloff_is_full_before_falloff_start() -> void:
	var dmg := Hitscan.damage_at_distance(5.0, 30.0, 15.0, 10.0, 40.0)
	assert_float(dmg).is_equal(30.0)


func test_damage_falloff_is_minimum_past_falloff_end() -> void:
	var dmg := Hitscan.damage_at_distance(100.0, 30.0, 15.0, 10.0, 40.0)
	assert_float(dmg).is_equal(15.0)


func test_damage_falloff_interpolates_in_between() -> void:
	var dmg := Hitscan.damage_at_distance(25.0, 30.0, 15.0, 10.0, 40.0) # halfway
	assert_float(dmg).is_equal_approx(22.5, 0.0001)


func test_headshot_multiplier_only_applies_on_headshot() -> void:
	assert_float(Hitscan.apply_headshot_multiplier(30.0, false, 2.0)).is_equal(30.0)
	assert_float(Hitscan.apply_headshot_multiplier(30.0, true, 2.0)).is_equal(60.0)


func test_spread_direction_is_forward_when_spread_is_zero() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var forward := Vector3(0.0, 0.0, -1.0)
	var dir := Hitscan.spread_direction(forward, 0.0, rng)
	assert_vector(dir).is_equal_approx(forward, Vector3(0.0001, 0.0001, 0.0001))


func test_spread_direction_stays_within_cone_angle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var forward := Vector3(0.0, 0.0, -1.0)
	var spread := deg_to_rad(5.0)
	for _i in range(50):
		var dir := Hitscan.spread_direction(forward, spread, rng)
		var angle := forward.angle_to(dir)
		assert_float(angle).is_less_equal(spread + 0.0001)


func test_movement_spread_fraction_is_zero_when_stationary() -> void:
	assert_float(Hitscan.movement_spread_fraction(0.0, 8.0)).is_equal(0.0)


func test_movement_spread_fraction_scales_linearly_with_speed() -> void:
	assert_float(Hitscan.movement_spread_fraction(4.0, 8.0)).is_equal_approx(0.5, 0.0001)


func test_movement_spread_fraction_clamps_at_one_past_max_speed() -> void:
	assert_float(Hitscan.movement_spread_fraction(20.0, 8.0)).is_equal(1.0)


func test_movement_spread_fraction_is_zero_when_max_speed_is_zero() -> void:
	assert_float(Hitscan.movement_spread_fraction(5.0, 0.0)).is_equal(0.0)
