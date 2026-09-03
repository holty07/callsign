# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_format_time_ten_minutes() -> void:
	assert_str(ScoreDisplay.format_time(600.0)).is_equal("10:00")


func test_format_time_pads_seconds_under_ten() -> void:
	assert_str(ScoreDisplay.format_time(65.0)).is_equal("1:05")


func test_format_time_zero() -> void:
	assert_str(ScoreDisplay.format_time(0.0)).is_equal("0:00")


func test_format_time_floors_negative_at_zero() -> void:
	# time_remaining is always clamped to >= 0.0 by MatchState itself, but the
	# display shouldn't ever show a negative clock even if fed a stray value.
	assert_str(ScoreDisplay.format_time(-5.0)).is_equal("0:00")
