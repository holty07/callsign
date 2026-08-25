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


func test_recoil_vertical_climb_caps_at_max() -> void:
	var recoil := Recoil.new(1.0, 3.0, 0.0, 0.0, 42)
	for _i in range(10):
		recoil.fire()
	var offset := recoil.process(0.0)
	assert_float(offset.x).is_equal(3.0)


func test_recoil_recovers_toward_zero_over_time() -> void:
	var recoil := Recoil.new(1.0, 3.0, 0.0, 10.0, 42)
	recoil.fire()
	recoil.process(0.0) # register the shot's kick
	var offset := recoil.process(10.0) # far longer than needed to fully recover
	assert_vector(offset).is_equal(Vector2.ZERO)


func test_recoil_horizontal_drift_is_deterministic_for_a_given_seed() -> void:
	var a := Recoil.new(1.0, 10.0, 2.0, 0.0, 99)
	var b := Recoil.new(1.0, 10.0, 2.0, 0.0, 99)
	for _i in range(5):
		a.fire()
		b.fire()
	assert_vector(a.process(0.0)).is_equal(b.process(0.0))


func test_health_reports_damage_and_death() -> void:
	var health := Health.new()
	health.max_health = 100.0
	health._ready()

	# Plain locals aren't mutable from inside a lambda closure in GDScript —
	# only what's inside a captured Array/Dictionary/Object actually persists.
	var damage_events := []
	health.damaged.connect(func(amount, was_headshot, _pos): damage_events.append([amount, was_headshot]))
	var died_flag := [false]
	health.died.connect(func(): died_flag[0] = true)

	health.apply_damage(40.0, false)
	assert_float(health.current_health).is_equal(60.0)
	assert_bool(died_flag[0]).is_false()

	health.apply_damage(60.0, true)
	assert_float(health.current_health).is_equal(0.0)
	assert_bool(died_flag[0]).is_true()
	assert_int(damage_events.size()).is_equal(2)
	assert_bool(damage_events[1][1]).is_true()

	health.apply_damage(10.0) # already dead; must not go negative or re-fire signals
	assert_float(health.current_health).is_equal(0.0)
	assert_int(damage_events.size()).is_equal(2)

	health.free()


func _make_weapon_with_camera() -> WeaponBase:
	var camera: Camera3D = auto_free(Camera3D.new())
	add_child(camera)
	var weapon: WeaponBase = auto_free((load("res://scenes/weapons/rifle.tscn") as PackedScene).instantiate())
	camera.add_child(weapon)
	return weapon


func test_ai_controlled_weapon_wants_to_fire_from_ai_fire_held_not_global_input() -> void:
	# A bot's rifle must never read the shared Input singleton — that would
	# fire every bot's gun whenever the player (or another bot) does. Checked
	# at the trigger-decision level (not a full fire()) since fire()'s FX
	# side effects (WeaponFX tracers/decals) need a live running scene this
	# suite doesn't have.
	var weapon := _make_weapon_with_camera()
	weapon.player_controlled = false

	assert_bool(weapon._wants_to_fire()).is_false()
	weapon.ai_fire_held = true
	assert_bool(weapon._wants_to_fire()).is_true()


func test_player_controlled_weapon_ignores_ai_fields() -> void:
	var weapon := _make_weapon_with_camera()
	# player_controlled defaults to true; ai_fire_held must be a no-op.
	weapon.ai_fire_held = true

	assert_bool(weapon._wants_to_fire()).is_false()


func test_ai_controlled_weapon_reload_request_is_one_shot() -> void:
	var weapon := _make_weapon_with_camera()
	weapon.player_controlled = false

	weapon.ai_reload_requested = true
	assert_bool(weapon._wants_reload()).is_true()

	# _physics_process clears the one-shot request the tick after it's read,
	# mirroring Input.is_action_just_pressed's single-frame pulse.
	weapon._physics_process(1.0 / 120.0)
	assert_bool(weapon.ai_reload_requested).is_false()
