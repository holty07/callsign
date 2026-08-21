# SPDX-License-Identifier: GPL-2.0-or-later
extends Node

# Raw mouse input for pmove.gd (see CLAUDE.md — movement non-negotiables).
# Motion events are accumulated manually and applied on the physics tick;
# Godot must not accumulate/smooth them itself.
func _init() -> void:
	Input.use_accumulated_input = false
