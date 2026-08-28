# SPDX-License-Identifier: GPL-2.0-or-later
#
# Placeholder "YOU ARE DEAD" overlay — the player currently just stops
# responding to input for a few seconds on death (see pmove.gd's own
# placeholder note) with no other feedback. Without this, a dead player
# looks exactly like a frozen/bugged one. Replace with a proper death
# screen once the match loop (M4) owns HUD/round flow.
class_name DeathOverlay
extends Control

@export var player_path: NodePath

@onready var _label: Label = $Label

var _player: PMove


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_player = get_node_or_null(player_path)
	_label.visible = false


func _process(_delta: float) -> void:
	if _player:
		_label.visible = not _player.is_alive()
