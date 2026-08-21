# SPDX-License-Identifier: GPL-2.0-or-later
#
# Live F1 tuning panel. Exposes every pmove.gd/camera_look.gd movement
# variable as a slider that writes straight back into the running instance,
# so movement feel can be adjusted without restarting. Ranges here are just
# generous enough to explore in — see docs/TUNING.md for the values that
# actually ship, once they're chosen from playtesting.
extends CanvasLayer

@export var player_path: NodePath
@export var camera_look_path: NodePath

const _PLAYER_FIELDS: Array[Dictionary] = [
	{"prop": "move_speed", "label": "Move speed (qu/s)", "min": 0.0, "max": 600.0, "step": 1.0},
	{"prop": "ground_accel", "label": "Ground accel", "min": 0.0, "max": 40.0, "step": 0.1},
	{"prop": "ground_friction", "label": "Ground friction", "min": 0.0, "max": 20.0, "step": 0.1},
	{"prop": "stop_speed", "label": "Stop speed (qu/s)", "min": 0.0, "max": 300.0, "step": 1.0},
	{"prop": "air_accel", "label": "Air accel", "min": 0.0, "max": 10.0, "step": 0.05},
	{"prop": "gravity_qu", "label": "Gravity (qu/s^2)", "min": 0.0, "max": 2000.0, "step": 5.0},
	{"prop": "jump_velocity_qu", "label": "Jump velocity (qu/s)", "min": 0.0, "max": 600.0, "step": 1.0},
	{"prop": "standing_height", "label": "Standing height (m)", "min": 1.0, "max": 2.2, "step": 0.01},
	{"prop": "crouch_height", "label": "Crouch height (m)", "min": 0.3, "max": 1.8, "step": 0.01},
	{"prop": "crouch_speed_scale", "label": "Crouch speed scale", "min": 0.0, "max": 1.5, "step": 0.01},
	{"prop": "crouch_transition_speed", "label": "Crouch transition speed", "min": 1.0, "max": 20.0, "step": 0.1},
	{"prop": "sprint_speed_scale", "label": "Sprint speed scale", "min": 1.0, "max": 3.0, "step": 0.01},
	{"prop": "max_step_height", "label": "Max step height (m)", "min": 0.0, "max": 1.0, "step": 0.01},
	{"prop": "floor_max_angle_deg", "label": "Floor max angle (deg)", "min": 0.0, "max": 89.0, "step": 1.0},
]

const _CAMERA_FIELDS: Array[Dictionary] = [
	{"prop": "mouse_sensitivity", "label": "Mouse sensitivity", "min": 0.0002, "max": 0.02, "step": 0.0001},
]

@onready var _rows: VBoxContainer = $Panel/ScrollContainer/VBox


func _ready() -> void:
	visible = false

	var player := get_node_or_null(player_path)
	if player:
		_build_section("Movement", player, _PLAYER_FIELDS)

	var camera_look := get_node_or_null(camera_look_path)
	if camera_look:
		_build_section("Look", camera_look, _CAMERA_FIELDS)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_tuning_panel"):
		visible = not visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED


func _build_section(title: String, target: Node, fields: Array) -> void:
	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 18)
	_rows.add_child(header)

	for field in fields:
		_add_row(target, field)


func _add_row(target: Node, field: Dictionary) -> void:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = field.label
	label.custom_minimum_size = Vector2(220, 0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = field.min
	slider.max_value = field.max
	slider.step = field.step
	slider.value = target.get(field.prop)
	slider.custom_minimum_size = Vector2(220, 0)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(70, 0)
	value_label.text = "%.3f" % float(target.get(field.prop))
	row.add_child(value_label)

	slider.value_changed.connect(func(v: float) -> void:
		target.set(field.prop, v)
		value_label.text = "%.3f" % v
	)

	_rows.add_child(row)
