# SPDX-License-Identifier: GPL-2.0-or-later
#
# Placeholder main menu — plain text/buttons, no art yet (greybox before art,
# same as every other M4 UI element). The new run/main_scene: the game boots
# here instead of straight into a match. Settings aren't reachable from here
# yet (only via the in-match pause menu) — out of scope for this checklist
# item, which only asked for start/results/back-to-menu.
class_name MainMenu
extends Control


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBox/StartButton.pressed.connect(_on_start_match_pressed)
	$VBox/QuitButton.pressed.connect(func(): get_tree().quit())


func _on_start_match_pressed() -> void:
	MatchState.reset_for_new_match()
	get_tree().change_scene_to_file("res://scenes/maps/test_box.tscn")
