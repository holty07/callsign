# SPDX-License-Identifier: GPL-2.0-or-later
#
# No death animation yet (see docs/ROADMAP.md M6) — bot.gd tips the corpse's
# Visual node over as a placeholder. Covers the wiring most likely to break
# from hand-editing bot.tscn: Visual missing, or a HitZone's health_path
# left pointing at the old (now one level too shallow) parent.
extends GdUnitTestSuite


func test_bot_lies_flat_after_dying_and_stands_back_up_on_respawn() -> void:
	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	add_child(bot)
	bot.global_position = Vector3.ZERO

	await get_tree().physics_frame
	assert_float(bot.get_node("Visual").rotation_degrees.x).is_equal_approx(0.0, 0.01)

	bot.health.apply_damage(bot.health.max_health)
	assert_bool(bot.is_alive()).is_false()

	for _i in range(60):
		await get_tree().physics_frame

	assert_float(bot.get_node("Visual").rotation_degrees.x).is_equal_approx(-bot.death_tilt_deg, 0.1)
	assert_bool(bot.aim.visible).is_false()

	bot.respawn_at(Vector3(1.0, 0.0, 1.0))
	assert_float(bot.get_node("Visual").rotation_degrees.x).is_equal_approx(0.0, 0.01)
	assert_bool(bot.aim.visible).is_true()
	assert_bool(bot.health.is_invulnerable()).is_true()


func test_dead_bot_stops_sliding_toward_its_last_nav_target() -> void:
	# Needs a real baked navmesh (see tests/test_nav_diagnostic.gd) — a bare
	# NavigationAgent3D with nowhere to path considers itself finished
	# immediately, which would make this test pass for the wrong reason.
	var map: Node = auto_free((load("res://scenes/maps/test_box.tscn") as PackedScene).instantiate())
	get_tree().root.add_child(map)
	var previous_current_scene := get_tree().current_scene
	get_tree().current_scene = map
	# NavigationBaker settles for _COLD_START_SETTLE_FRAMES (10) before its
	# first bake attempt — see that constant's comment for why. 20 clears
	# that plus the bake itself with margin to spare.
	for _i in range(20):
		await get_tree().physics_frame

	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	map.add_child(bot)
	bot.global_position = Vector3(4.0, 0.1, 0.0)
	for _i in range(3):
		await get_tree().physics_frame

	bot.move_to(Vector3(4.0, 0.1, -10.0))
	for _i in range(20):
		await get_tree().physics_frame

	bot.health.apply_damage(bot.health.max_health)
	var position_at_death := bot.global_position

	# 60 frames is comfortably more than bot.gd's own move_speed/acceleration
	# constants (4.5 and 12) ever need to fully decelerate from a dead stop
	# to zero: 4.5/12 = 0.375s = 45 frames worst case.
	for _i in range(60):
		await get_tree().physics_frame

	# Only gravity should still act on a corpse — velocity must decay to
	# exactly zero and stay there rather than beelining toward wherever it
	# was headed when it died. It won't stop instantly though: move_toward's
	# constant deceleration means some coast distance is physically expected
	# (v^2/(2*acceleration) per axis — up to ~0.84m at this bot's own
	# move_speed/acceleration ceiling). 1.0m stays well below what an actual
	# "still navigating toward the dead target" bug would produce over this
	# same window (multiple metres) while giving real headroom above that
	# expected coast, which shifts slightly with exactly when a path became
	# usable relative to this test's fixed pre-death movement window.
	var horizontal_drift := Vector2(bot.global_position.x, bot.global_position.z) \
		.distance_to(Vector2(position_at_death.x, position_at_death.z))
	assert_float(horizontal_drift).is_less(1.0)

	get_tree().current_scene = previous_current_scene
