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


func test_friendly_fire_blocks_a_same_team_hit_when_disabled() -> void:
	assert_bool(WeaponBase.is_friendly_fire_blocked(false, Team.A, Team.A)).is_true()


func test_friendly_fire_allows_a_cross_team_hit_when_disabled() -> void:
	assert_bool(WeaponBase.is_friendly_fire_blocked(false, Team.A, Team.B)).is_false()


func test_friendly_fire_allows_a_same_team_hit_when_enabled() -> void:
	assert_bool(WeaponBase.is_friendly_fire_blocked(true, Team.A, Team.A)).is_false()


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


func test_health_ignores_damage_while_invulnerable() -> void:
	var health := Health.new()
	health.max_health = 100.0
	health._ready()
	health.grant_invulnerability(5.0)

	health.apply_damage(50.0)

	assert_float(health.current_health).is_equal(100.0)
	health.free()


func test_health_grant_invulnerability_of_zero_grants_no_protection() -> void:
	# A deterministic stand-in for "the protection window has expired" —
	# waiting out a real multi-second window in a test would be slow and
	# flaky (this codebase doesn't unit-test SpawnReservations' own
	# real-time expiry either, for the same reason).
	var health := Health.new()
	health.max_health = 100.0
	health._ready()
	health.grant_invulnerability(0.0)

	health.apply_damage(50.0)

	assert_float(health.current_health).is_equal(50.0)
	health.free()


func test_regen_step_does_nothing_before_the_delay_elapses() -> void:
	var result := Health.regen_step(60.0, 100.0, 3.9, 4.0, 40.0, 0.1)
	assert_float(result).is_equal(60.0)


func test_regen_step_does_nothing_to_a_dead_target() -> void:
	var result := Health.regen_step(0.0, 100.0, 10.0, 4.0, 40.0, 0.1)
	assert_float(result).is_equal(0.0)


func test_regen_step_does_nothing_once_already_full() -> void:
	var result := Health.regen_step(100.0, 100.0, 10.0, 4.0, 40.0, 0.1)
	assert_float(result).is_equal(100.0)


func test_regen_step_heals_gradually_rather_than_in_one_lump() -> void:
	# The point of ticking regen every delta rather than applying
	# rate_per_second * (time_since_damage - delay_seconds) in one go: a
	# single small tick just past the delay should only add a sliver of
	# health, not the full second's worth.
	var result := Health.regen_step(60.0, 100.0, 4.0, 4.0, 40.0, 0.1)
	assert_float(result).is_equal_approx(64.0, 0.0001)


func test_regen_step_accumulates_over_several_ticks() -> void:
	var health := 60.0
	for _i in range(10):
		health = Health.regen_step(health, 100.0, 5.0, 4.0, 40.0, 0.1)
	assert_float(health).is_equal_approx(100.0, 0.0001) # 60 + 40/s * 1s, clamped


func test_regen_step_clamps_at_max_health() -> void:
	var result := Health.regen_step(95.0, 100.0, 10.0, 4.0, 40.0, 0.5)
	assert_float(result).is_equal(100.0)


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


func test_reset_ammo_restores_full_magazine_and_reserve() -> void:
	# Regression: a combatant respawning while dry on ammo (magazine and
	# reserve both at 0) stayed stuck unable to fire at all — nothing
	# reset ammo on respawn_at() until this method existed to call.
	var weapon := _make_weapon_with_camera()
	weapon._magazine_ammo = 0
	weapon._reserve_ammo = 0
	weapon._is_reloading = true

	var ammo_events := []
	var on_ammo_changed := func(magazine_ammo, reserve_ammo): ammo_events.append([magazine_ammo, reserve_ammo])
	weapon.ammo_changed.connect(on_ammo_changed)

	weapon.reset_ammo()

	assert_int(weapon._magazine_ammo).is_equal(weapon.magazine_size)
	assert_int(weapon._reserve_ammo).is_equal(weapon.reserve_ammo_max)
	assert_bool(weapon._is_reloading).is_false()
	assert_array(ammo_events).is_equal([[weapon.magazine_size, weapon.reserve_ammo_max]])
