# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_slide_tilt_target_is_zero_when_not_sliding() -> void:
	assert_float(CameraLook.slide_tilt_target_deg(false, 8.0)).is_equal(0.0)


func test_slide_tilt_target_matches_configured_angle_when_sliding() -> void:
	assert_float(CameraLook.slide_tilt_target_deg(true, 8.0)).is_equal(8.0)
