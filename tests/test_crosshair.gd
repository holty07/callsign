# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_spread_to_screen_radius_is_zero_for_zero_spread() -> void:
	var radius := Crosshair.spread_to_screen_radius_px(0.0, deg_to_rad(90.0), 1080.0)
	assert_float(radius).is_equal_approx(0.0, 0.0001)


func test_spread_to_screen_radius_grows_with_spread_angle() -> void:
	var fov := deg_to_rad(90.0)
	var small := Crosshair.spread_to_screen_radius_px(deg_to_rad(1.0), fov, 1080.0)
	var large := Crosshair.spread_to_screen_radius_px(deg_to_rad(5.0), fov, 1080.0)
	assert_float(large).is_greater(small)


func test_spread_to_screen_radius_scales_with_viewport_height() -> void:
	var fov := deg_to_rad(90.0)
	var spread := deg_to_rad(2.0)
	var small_viewport := Crosshair.spread_to_screen_radius_px(spread, fov, 720.0)
	var large_viewport := Crosshair.spread_to_screen_radius_px(spread, fov, 1440.0)
	assert_float(large_viewport).is_equal_approx(small_viewport * 2.0, 0.01)


func test_spread_to_screen_radius_shrinks_with_wider_fov() -> void:
	var spread := deg_to_rad(2.0)
	var narrow_fov := Crosshair.spread_to_screen_radius_px(spread, deg_to_rad(60.0), 1080.0)
	var wide_fov := Crosshair.spread_to_screen_radius_px(spread, deg_to_rad(120.0), 1080.0)
	assert_float(wide_fov).is_less(narrow_fov)


func test_hitmarker_color_is_white_for_a_plain_hit() -> void:
	var color := Crosshair.hitmarker_color_for(false, false, Color.WHITE, Color.YELLOW, Color.RED)
	assert_that(color).is_equal(Color.WHITE)


func test_hitmarker_color_is_yellow_for_a_headshot() -> void:
	var color := Crosshair.hitmarker_color_for(true, false, Color.WHITE, Color.YELLOW, Color.RED)
	assert_that(color).is_equal(Color.YELLOW)


func test_hitmarker_color_is_red_for_a_kill_even_on_a_headshot() -> void:
	var color := Crosshair.hitmarker_color_for(true, true, Color.WHITE, Color.YELLOW, Color.RED)
	assert_that(color).is_equal(Color.RED)
