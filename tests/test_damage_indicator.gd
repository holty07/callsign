# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_vignette_alpha_is_zero_when_timer_has_expired() -> void:
	var alpha := DamageIndicator.vignette_alpha_for(1.0, 0.0, 0.6, 0.55)
	assert_float(alpha).is_equal_approx(0.0, 0.0001)


func test_vignette_alpha_is_max_at_full_intensity_and_fresh_timer() -> void:
	var alpha := DamageIndicator.vignette_alpha_for(1.0, 0.6, 0.6, 0.55)
	assert_float(alpha).is_equal_approx(0.55, 0.0001)


func test_vignette_alpha_scales_with_remaining_time() -> void:
	var alpha := DamageIndicator.vignette_alpha_for(1.0, 0.3, 0.6, 0.55)
	assert_float(alpha).is_equal_approx(0.275, 0.0001)


func test_vignette_alpha_is_zero_for_zero_duration() -> void:
	# Degenerate input guard — same style as HealthDisplay.health_color_for's
	# own zero-max-health test.
	var alpha := DamageIndicator.vignette_alpha_for(1.0, 0.3, 0.0, 0.55)
	assert_float(alpha).is_equal_approx(0.0, 0.0001)


func test_flash_intensity_is_full_at_or_above_the_full_damage_amount() -> void:
	var intensity := DamageIndicator.flash_intensity_for(40.0, 40.0, 0.25)
	assert_float(intensity).is_equal_approx(1.0, 0.0001)

	var over_intensity := DamageIndicator.flash_intensity_for(100.0, 40.0, 0.25)
	assert_float(over_intensity).is_equal_approx(1.0, 0.0001)


func test_flash_intensity_is_floored_for_small_hits() -> void:
	var intensity := DamageIndicator.flash_intensity_for(1.0, 40.0, 0.25)
	assert_float(intensity).is_equal_approx(0.25, 0.0001)


func test_flash_intensity_scales_linearly_between_the_floor_and_the_cap() -> void:
	var intensity := DamageIndicator.flash_intensity_for(20.0, 40.0, 0.25)
	assert_float(intensity).is_equal_approx(0.5, 0.0001)


func test_flash_intensity_is_full_when_full_damage_amount_is_zero() -> void:
	var intensity := DamageIndicator.flash_intensity_for(5.0, 0.0, 0.25)
	assert_float(intensity).is_equal_approx(1.0, 0.0001)


func test_angle_from_direction_is_zero_straight_ahead() -> void:
	var angle := DamageIndicator.angle_from_direction(Vector3(0.0, 0.0, -1.0), Basis.IDENTITY)
	assert_float(angle).is_equal_approx(0.0, 0.0001)


func test_angle_from_direction_is_positive_to_the_right() -> void:
	var angle := DamageIndicator.angle_from_direction(Vector3(1.0, 0.0, 0.0), Basis.IDENTITY)
	assert_float(angle).is_equal_approx(deg_to_rad(90.0), 0.0001)


func test_angle_from_direction_is_negative_to_the_left() -> void:
	var angle := DamageIndicator.angle_from_direction(Vector3(-1.0, 0.0, 0.0), Basis.IDENTITY)
	assert_float(angle).is_equal_approx(deg_to_rad(-90.0), 0.0001)


func test_angle_from_direction_wraps_to_the_far_side_when_behind() -> void:
	var angle := DamageIndicator.angle_from_direction(Vector3(0.0, 0.0, 1.0), Basis.IDENTITY)
	assert_float(absf(angle)).is_equal_approx(deg_to_rad(180.0), 0.0001)


func test_angle_from_direction_ignores_vertical_offset() -> void:
	var angle := DamageIndicator.angle_from_direction(Vector3(0.0, 5.0, -1.0), Basis.IDENTITY)
	assert_float(angle).is_equal_approx(0.0, 0.0001)


func test_angle_from_direction_accounts_for_player_yaw() -> void:
	# Player basis rotated -90 degrees around Y turns the player to face
	# world +X, so a hit from world +X now reads as straight ahead.
	var yawed_basis := Basis(Vector3.UP, deg_to_rad(-90.0))
	var angle := DamageIndicator.angle_from_direction(Vector3(1.0, 0.0, 0.0), yawed_basis)
	assert_float(angle).is_equal_approx(0.0, 0.0001)


func test_angle_from_direction_is_zero_for_a_negligible_direction() -> void:
	var angle := DamageIndicator.angle_from_direction(Vector3(0.0001, 0.0, 0.0), Basis.IDENTITY)
	assert_float(angle).is_equal_approx(0.0, 0.0001)
