# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_health_color_is_full_color_at_max_health() -> void:
	var color := HealthDisplay.health_color_for(100.0, 100.0, Color.WHITE, Color.RED)
	assert_that(color).is_equal(Color.WHITE)


func test_health_color_is_critical_color_at_zero_health() -> void:
	var color := HealthDisplay.health_color_for(0.0, 100.0, Color.WHITE, Color.RED)
	assert_that(color).is_equal(Color.RED)


func test_health_color_is_halfway_between_at_half_health() -> void:
	var color := HealthDisplay.health_color_for(50.0, 100.0, Color.WHITE, Color.RED)
	assert_that(color).is_equal(Color.WHITE.lerp(Color.RED, 0.5))


func test_health_color_is_full_color_when_max_health_is_zero() -> void:
	# Degenerate input guard — same style as Hitscan.movement_spread_fraction's
	# own zero-max-speed test.
	var color := HealthDisplay.health_color_for(0.0, 0.0, Color.WHITE, Color.RED)
	assert_that(color).is_equal(Color.WHITE)
