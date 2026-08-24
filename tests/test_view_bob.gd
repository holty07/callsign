# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite

const DELTA := 1.0 / 120.0


func test_advance_phase_advances_with_distance_travelled() -> void:
	var phase := ViewBob.advance_phase(0.0, 260.0, 130.0, DELTA)
	var expected: float = (260.0 * DELTA / 130.0) * TAU
	assert_float(phase).is_equal_approx(expected, 0.0001)


func test_advance_phase_does_not_advance_when_stationary() -> void:
	var phase := ViewBob.advance_phase(1.0, 0.0, 130.0, DELTA)
	assert_float(phase).is_equal_approx(1.0, 0.0001)


func test_advance_phase_wraps_past_tau() -> void:
	var phase := ViewBob.advance_phase(TAU - 0.01, 1000.0, 1.0, 1.0)
	assert_float(phase).is_between(0.0, TAU)


func test_amplitude_scale_is_zero_at_or_below_min_speed() -> void:
	assert_float(ViewBob.amplitude_scale(20.0, 20.0, 380.0)).is_equal(0.0)
	assert_float(ViewBob.amplitude_scale(5.0, 20.0, 380.0)).is_equal(0.0)


func test_amplitude_scale_is_one_at_or_above_max_speed() -> void:
	assert_float(ViewBob.amplitude_scale(380.0, 20.0, 380.0)).is_equal(1.0)
	assert_float(ViewBob.amplitude_scale(500.0, 20.0, 380.0)).is_equal(1.0)


func test_amplitude_scale_is_linear_between_thresholds() -> void:
	var scale := ViewBob.amplitude_scale(200.0, 0.0, 400.0)
	assert_float(scale).is_equal_approx(0.5, 0.0001)


func test_offset_is_zero_at_phase_zero() -> void:
	var result := ViewBob.offset(0.0, 0.02, 0.012)
	assert_vector(result).is_equal_approx(Vector3.ZERO, Vector3(0.0001, 0.0001, 0.0001))


func test_offset_vertical_never_goes_negative() -> void:
	# abs(sin) means every step reads as a dip, never a lift, at any phase.
	for i in range(8):
		var phase: float = i * (TAU / 8.0)
		var result := ViewBob.offset(phase, 0.02, 0.012)
		assert_float(result.y).is_greater_equal(0.0)
