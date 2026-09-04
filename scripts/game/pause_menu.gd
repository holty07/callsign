# SPDX-License-Identifier: GPL-2.0-or-later
#
# Placeholder pause + settings menu — map-level, one per match. A genuine
# pause: get_tree().paused freezes bots/physics/MatchState's round timer for
# free (Godot's default process_mode = PROCESS_MODE_PAUSABLE on every other
# node already stops them), so this is the one node in the whole game that
# needs PROCESS_MODE_ALWAYS to keep working while everything else is frozen.
# Talks straight to the Settings autoload, same as the HUD's map-level
# elements talk to MatchState — no exported NodePaths.
class_name PauseMenu
extends CanvasLayer

@onready var _main_panel: Panel = $MainPanel
@onready var _settings_panel: Panel = $SettingsPanel
@onready var _sensitivity_slider: HSlider = $SettingsPanel/VBox/SensitivityRow/HSlider
@onready var _fov_slider: HSlider = $SettingsPanel/VBox/FovRow/HSlider
@onready var _volume_slider: HSlider = $SettingsPanel/VBox/VolumeRow/HSlider
@onready var _bot_count_slider: HSlider = $SettingsPanel/VBox/BotCountRow/HSlider
@onready var _keybind_rows: VBoxContainer = $SettingsPanel/VBox/KeybindRows

var _rebinding_action: String = ""
var _rebinding_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_show_main()

	$MainPanel/VBox/ResumeButton.pressed.connect(_toggle_pause)
	$MainPanel/VBox/SettingsButton.pressed.connect(_show_settings)
	$MainPanel/VBox/QuitButton.pressed.connect(func(): get_tree().quit())
	$SettingsPanel/VBox/BackButton.pressed.connect(_show_main)
	$SettingsPanel/VBox/ResetKeybindsButton.pressed.connect(_on_reset_keybinds)

	_wire_slider(_sensitivity_slider, Settings.mouse_sensitivity, Settings.set_mouse_sensitivity)
	_wire_slider(_fov_slider, Settings.fov_degrees, Settings.set_fov)
	_wire_slider(_volume_slider, Settings.master_volume_linear, Settings.set_master_volume)
	_wire_slider(_bot_count_slider, float(Settings.bot_count), func(v): Settings.set_bot_count(int(v)))

	_build_keybind_rows()


func _wire_slider(slider: HSlider, initial: float, setter: Callable) -> void:
	slider.value = initial
	slider.value_changed.connect(setter)
	# Live-apply on every drag tick (setter), but only touch disk once the
	# gesture finishes — cheap during the drag, no I/O storm from a slider.
	slider.drag_ended.connect(func(_value_changed): Settings.save_to_disk())


func _input(event: InputEvent) -> void:
	# _input (not _unhandled_input): a focused Button's own _gui_input could
	# otherwise swallow the key before this sees it — important while
	# capturing "any key" for a rebind, but applies to the pause toggle too.
	if _rebinding_action != "":
		_handle_rebind_input(event)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _toggle_pause() -> void:
	var pausing := not get_tree().paused
	get_tree().paused = pausing
	visible = pausing
	if pausing:
		_show_main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pausing else Input.MOUSE_MODE_CAPTURED


func _show_main() -> void:
	_main_panel.visible = true
	_settings_panel.visible = false


func _show_settings() -> void:
	_main_panel.visible = false
	_settings_panel.visible = true


func _build_keybind_rows() -> void:
	for action in Settings.REBINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = Settings.humanize_action_name(action)
		label.custom_minimum_size = Vector2(180, 0)
		var rebind_button := Button.new()
		rebind_button.text = _current_binding_text(action)
		rebind_button.set_meta("action", action)
		rebind_button.pressed.connect(_on_rebind_pressed.bind(rebind_button))
		row.add_child(label)
		row.add_child(rebind_button)
		_keybind_rows.add_child(row)


func _current_binding_text(action: String) -> String:
	var events := InputMap.action_get_events(action)
	return events[0].as_text() if not events.is_empty() else "Unbound"


func _on_rebind_pressed(button: Button) -> void:
	_rebinding_action = button.get_meta("action")
	_rebinding_button = button
	button.text = "Press any key..."


func _handle_rebind_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_finish_rebind() # cancel: just refreshes back to the current binding
			return
		Settings.rebind_action(_rebinding_action, event)
		Settings.save_to_disk()
		_finish_rebind()
	elif event is InputEventMouseButton and event.pressed:
		Settings.rebind_action(_rebinding_action, event)
		Settings.save_to_disk()
		_finish_rebind()


func _finish_rebind() -> void:
	_rebinding_button.text = _current_binding_text(_rebinding_action)
	_rebinding_action = ""
	_rebinding_button = null


func _on_reset_keybinds() -> void:
	Settings.reset_all_keybinds()
	Settings.save_to_disk()
	for row in _keybind_rows.get_children():
		var button: Button = row.get_child(1)
		button.text = _current_binding_text(button.get_meta("action"))
