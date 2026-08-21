# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite

const DELTA := 1.0 / 120.0


func test_friction_reduces_speed_when_grounded() -> void:
	var vel := Vector3(300.0, 0.0, 0.0)
	var result := PMove.pm_friction(vel, 6.0, 100.0, DELTA, true)
	assert_float(result.length()).is_less(300.0)
	assert_float(result.length()).is_greater(0.0)
	assert_float(result.x).is_greater(0.0)


func test_friction_is_a_noop_in_air() -> void:
	var vel := Vector3(300.0, -50.0, 40.0)
	var result := PMove.pm_friction(vel, 6.0, 100.0, DELTA, false)
	assert_vector(result).is_equal_approx(vel, Vector3(0.0001, 0.0001, 0.0001))


func test_friction_zeroes_horizontal_below_threshold_but_keeps_vertical() -> void:
	# Overall 3D speed must be below the 1 qu/s threshold for the early
	# return to trigger, so the vertical component has to be small too.
	var vel := Vector3(0.5, 0.5, 0.0)
	var result := PMove.pm_friction(vel, 6.0, 100.0, DELTA, true)
	assert_float(result.x).is_equal(0.0)
	assert_float(result.z).is_equal(0.0)
	assert_float(result.y).is_equal(0.5)


func test_accelerate_clamps_when_already_past_wishspeed() -> void:
	var wishdir := Vector3(1.0, 0.0, 0.0)
	var vel := wishdir * 400.0
	var result := PMove.pm_accelerate(vel, wishdir, 320.0, 10.0, DELTA)
	assert_vector(result).is_equal_approx(vel, Vector3(0.0001, 0.0001, 0.0001))


func test_accelerate_projects_existing_velocity_before_clamping() -> void:
	# The whole point of PM_Accelerate: accelerating perpendicular to your
	# current velocity adds speed without first "paying down" what you
	# already have. vel is pure +X; wishdir is pure +Z (perpendicular).
	var vel := Vector3(200.0, 0.0, 0.0)
	var wishdir := Vector3(0.0, 0.0, 1.0)
	var wishspeed := 320.0
	var accel := 10.0

	var result := PMove.pm_accelerate(vel, wishdir, wishspeed, accel, DELTA)

	var expected_gain: float = accel * DELTA * wishspeed
	assert_float(result.x).is_equal_approx(200.0, 0.0001) # untouched
	assert_float(result.z).is_equal_approx(expected_gain, 0.0001)


func test_terminal_ground_speed_converges_to_wishspeed() -> void:
	var wishdir := Vector3(1.0, 0.0, 0.0)
	var wishspeed := 320.0
	var vel := Vector3.ZERO

	for _i in range(600): # 5 simulated seconds at 120 Hz
		vel = PMove.pm_friction(vel, 6.0, 100.0, DELTA, true)
		vel = PMove.pm_accelerate(vel, wishdir, wishspeed, 10.0, DELTA)

	assert_float(vel.length()).is_equal_approx(wishspeed, 0.5)


func test_air_accel_gains_speed_slower_than_ground_accel() -> void:
	var wishdir := Vector3(1.0, 0.0, 0.0)
	var wishspeed := 320.0

	var ground_vel := Vector3.ZERO
	var air_vel := Vector3.ZERO
	for _i in range(30):
		ground_vel = PMove.pm_accelerate(ground_vel, wishdir, wishspeed, 10.0, DELTA)
		air_vel = PMove.pm_accelerate(air_vel, wishdir, wishspeed, 1.0, DELTA)

	assert_float(air_vel.length()).is_less(ground_vel.length())


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

	for _i in range(30):
		vel = PMove.pm_friction(vel, 6.0, 100.0, DELTA, true)
		vel = PMove.pm_accelerate(vel, forward, 320.0, 10.0, DELTA)

	for _i in range(20):
		vel = PMove.pm_friction(vel, 6.0, 100.0, DELTA, false)
		vel = PMove.pm_accelerate(vel, strafe, 320.0, 1.0, DELTA)
		vel.y -= 800.0 * DELTA

	for _i in range(40):
		vel = PMove.pm_friction(vel, 6.0, 100.0, DELTA, true)
		vel = PMove.pm_accelerate(vel, Vector3.ZERO, 0.0, 10.0, DELTA)

	return vel
