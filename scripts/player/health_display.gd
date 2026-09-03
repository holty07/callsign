# SPDX-License-Identifier: GPL-2.0-or-later
#
# Placeholder health readout — plain text, no bar/icon yet (greybox before
# art). Polls every frame rather than wiring Health.damaged: Health.reset()
# (called on every respawn) doesn't emit any signal, so a purely event-driven
# display would miss updating right when it matters most. Same call
# death_overlay.gd already made for is_alive() having no convenient signal.
class_name HealthDisplay
extends Control

@export var health_path: NodePath
@export var full_health_color: Color = Color.WHITE
@export var critical_health_color: Color = Color(0.9, 0.1, 0.1)

@onready var _label: Label = $Label

var _health: Health


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health = get_node_or_null(health_path)


func _process(_delta: float) -> void:
	if _health == null:
		return

	_label.text = "HP %d" % roundi(_health.current_health)
	if _health.is_invulnerable():
		_label.text += " (protected)"
	_label.modulate = health_color_for(_health.current_health, _health.max_health, full_health_color, critical_health_color)


## Pure, side-effect free so it's unit-testable without a live Health node.
static func health_color_for(current_health: float, max_health: float, full_color: Color, critical_color: Color) -> Color:
	if max_health <= 0.0:
		return full_color
	return full_color.lerp(critical_color, 1.0 - clampf(current_health / max_health, 0.0, 1.0))
