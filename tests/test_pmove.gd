# SPDX-License-Identifier: MIT
extends GdUnitTestSuite

const DELTA := 1.0 / 120.0


func test_horizontal_velocity_toward_decelerates_to_a_stop() -> void:
	var vel := Vector3(300.0, 5.0, 0.0)
	var result := PMove.horizontal_velocity_toward(vel, Vector3.ZERO, 0.0, 2200.0, DELTA)
	assert_float(result.x).is_less(300.0)
	assert_float(result.x).is_greater_equal(0.0)
	assert_float(result.y).is_equal(5.0) # vertical untouched


func test_horizontal_velocity_toward_reaches_zero_exactly_when_overshot() -> void:
	# move_toward must clamp exactly at the target, not oscillate past it.
	var vel := Vector3(1.0, 0.0, 0.0)
	var result := PMove.horizontal_velocity_toward(vel, Vector3.ZERO, 0.0, 2200.0, DELTA)
	assert_float(result.x).is_equal(0.0)


func test_horizontal_velocity_toward_accelerates_toward_wishdir() -> void:
	var wishdir := Vector3(1.0, 0.0, 0.0)
	var result := PMove.horizontal_velocity_toward(Vector3.ZERO, wishdir, 260.0, 2200.0, DELTA)
	var expected: float = 2200.0 * DELTA
	assert_float(result.x).is_equal_approx(expected, 0.0001)
	assert_float(result.z).is_equal(0.0)


func test_horizontal_velocity_toward_does_not_preserve_momentum_across_a_direction_change() -> void:
	# The whole point of dropping the old Quake projection: turning costs you
	# the speed you had, it doesn't add perpendicular speed for free. vel is
	# pure +X; wishdir is pure +Z (perpendicular).
	var vel := Vector3(260.0, 0.0, 0.0)
	var wishdir := Vector3(0.0, 0.0, 1.0)
	var result := PMove.horizontal_velocity_toward(vel, wishdir, 260.0, 2200.0, DELTA)
	assert_float(result.x).is_less(260.0) # x is being pulled toward 0, not left alone
	assert_float(result.z).is_greater(0.0)


func test_terminal_ground_speed_converges_to_wishspeed() -> void:
	var wishdir := Vector3(1.0, 0.0, 0.0)
	var wishspeed := 260.0
	var vel := Vector3.ZERO

	for _i in range(120): # 1 simulated second at 120 Hz
		vel = PMove.horizontal_velocity_toward(vel, wishdir, wishspeed, 2200.0, DELTA)

	assert_float(vel.length()).is_equal_approx(wishspeed, 0.5)


func test_air_rate_gains_speed_slower_than_ground_rate() -> void:
	var wishdir := Vector3(1.0, 0.0, 0.0)
	var wishspeed := 260.0

	var ground_vel := PMove.horizontal_velocity_toward(Vector3.ZERO, wishdir, wishspeed, 2200.0, DELTA)
	var air_vel := PMove.horizontal_velocity_toward(Vector3.ZERO, wishdir, wishspeed, 80.0, DELTA)

	assert_float(air_vel.length()).is_less(ground_vel.length())


func test_slide_velocity_decay_reduces_speed_but_keeps_vertical() -> void:
	var vel := Vector3(400.0, -50.0, 0.0)
	var result := PMove.slide_velocity_decay(vel, 500.0, DELTA)
	assert_float(result.x).is_less(400.0)
	assert_float(result.x).is_greater(0.0)
	assert_float(result.y).is_equal(-50.0)


func test_slide_velocity_decay_zeroes_horizontal_below_threshold() -> void:
	var vel := Vector3(0.5, 10.0, 0.0)
	var result := PMove.slide_velocity_decay(vel, 500.0, DELTA)
	assert_float(result.x).is_equal(0.0)
	assert_float(result.z).is_equal(0.0)
	assert_float(result.y).is_equal(10.0)


func test_should_start_slide_when_all_conditions_are_met() -> void:
	assert_bool(PMove.should_start_slide(true, true, true, 300.0, 250.0, 0.0)).is_true()


func test_should_start_slide_false_when_airborne() -> void:
	assert_bool(PMove.should_start_slide(false, true, true, 300.0, 250.0, 0.0)).is_false()


func test_should_start_slide_false_when_crouch_was_already_held() -> void:
	assert_bool(PMove.should_start_slide(true, false, true, 300.0, 250.0, 0.0)).is_false()


func test_should_start_slide_false_when_not_sprinting() -> void:
	assert_bool(PMove.should_start_slide(true, true, false, 300.0, 250.0, 0.0)).is_false()


func test_should_start_slide_false_when_too_slow() -> void:
	assert_bool(PMove.should_start_slide(true, true, true, 100.0, 250.0, 0.0)).is_false()


func test_should_start_slide_false_during_cooldown() -> void:
	assert_bool(PMove.should_start_slide(true, true, true, 300.0, 250.0, 0.2)).is_false()


func test_should_end_slide_when_timer_expires() -> void:
	assert_bool(PMove.should_end_slide(true, true, 0.0)).is_true()


func test_should_end_slide_when_crouch_released() -> void:
	assert_bool(PMove.should_end_slide(true, false, 0.4)).is_true()


func test_should_end_slide_when_airborne() -> void:
	assert_bool(PMove.should_end_slide(false, true, 0.4)).is_true()


func test_should_end_slide_false_mid_slide() -> void:
	assert_bool(PMove.should_end_slide(true, true, 0.4)).is_false()


func test_slide_boost_velocity_scales_horizontal_only() -> void:
	var result := PMove.slide_boost_velocity(Vector3(200.0, -50.0, 0.0), 1.15)
	assert_float(result.x).is_equal_approx(230.0, 0.001)
	assert_float(result.y).is_equal(-50.0)
	assert_float(result.z).is_equal(0.0)


func test_deterministic_replay_of_fixed_input_sequence() -> void:
	var final_a := _replay_fixed_sequence()
	var final_b := _replay_fixed_sequence()
	assert_vector(final_a).is_equal(final_b)


## A fixed scripted "input sequence": accelerate forward on the ground,
## jump into an unrelated air-strafe, then coast to a stop. No randomness,
## no engine time source — replaying it must always produce the same result.
func _replay_fixed_sequence() -> Vector3:
	var vel := Vector3.ZERO
	var forward := Vector3(0.0, 0.0, -1.0)
	var strafe := Vector3(1.0, 0.0, 0.0)

	for _i in range(30): # ground accel
		vel = PMove.horizontal_velocity_toward(vel, forward, 260.0, 2200.0, DELTA)

	for _i in range(20): # airborne strafe + gravity
		vel = PMove.horizontal_velocity_toward(vel, strafe, 260.0, 80.0, DELTA)
		vel.y -= 800.0 * DELTA

	for _i in range(40): # coast to a stop, grounded
		vel = PMove.horizontal_velocity_toward(vel, Vector3.ZERO, 0.0, 2200.0, DELTA)

	return vel
