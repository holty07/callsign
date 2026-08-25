# SPDX-License-Identifier: GPL-2.0-or-later
#
# Wiring smoke test: instantiates the real bot.tscn and ticks its behaviour
# tree, to catch the class of bug .tscn hand-editing is most prone to
# (wrong node type string, wrong NodePath, missing script) that no pure
# unit test of the leaf logic would ever exercise.
extends GdUnitTestSuite


func test_behavior_tree_ticks_without_error_and_falls_back_to_patrol() -> void:
	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	add_child(bot)

	var tree: BeehaveTree = bot.get_node("BehaviorTree")
	var status := tree.tick()

	# No target, no threat memory, no map waypoints: every branch above
	# Patrol fails its guard, and Patrol succeeds immediately since there
	# are no waypoints to walk between, rather than getting stuck.
	assert_int(status).is_equal(BeehaveTree.SUCCESS)


func test_dead_bot_respawns_even_after_locking_onto_engage() -> void:
	# Regression: the root composite must be SelectorReactiveComposite, not
	# the plain (non-reactive) SelectorComposite. A plain Selector resumes
	# from wherever it last stopped rather than re-checking every child from
	# the top each tick, so once a lower-priority branch like Engage starts
	# returning RUNNING, Respawn (index 0) never gets re-evaluated again —
	# not even after the bot dies. A dead bot fell through to Patrol
	# instead and just wandered as a corpse forever.
	var bot_a: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	var bot_b: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	add_child(bot_a)
	add_child(bot_b)
	bot_a.global_position = Vector3(0.0, 0.0, 0.0)
	bot_b.global_position = Vector3(0.0, 0.0, -3.0)

	var respawn_leaf: Node = bot_a.get_node("BehaviorTree/Selector/Respawn")
	respawn_leaf.respawn_delay = 0.1 # keep the test fast

	# Run long enough for both to perceive each other past reaction_delay
	# and lock onto Engage — the exact state a plain Selector gets stuck on.
	for _i in range(60):
		await get_tree().physics_frame

	bot_a.health.apply_damage(bot_a.health.max_health)
	assert_bool(bot_a.is_alive()).is_false()

	for _i in range(40):
		await get_tree().physics_frame

	assert_bool(bot_a.is_alive()).is_true()
