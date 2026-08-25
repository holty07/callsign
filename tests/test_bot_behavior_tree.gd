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
