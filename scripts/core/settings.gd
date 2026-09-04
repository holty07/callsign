# SPDX-License-Identifier: GPL-2.0-or-later
#
# Autoload. Single source of truth for every player-facing setting the pause
# menu controls (sensitivity, FOV, master volume, bot count) plus keybind
# persistence — scripts/game/pause_menu.gd is the only thing that builds UI
# around this; everything else (camera_look.gd, weapon_base.gd, bot_spawner.gd)
# just seeds from it once and subscribes to its signals for live updates.
# Setters update in-memory state and emit a signal only — they never write to
# disk themselves, so they stay cheap to call on every slider-drag tick.
# save_to_disk() is called explicitly by the menu on gesture-complete.
extends Node

signal mouse_sensitivity_changed(value: float)
signal fov_changed(value: float)
signal master_volume_changed(linear: float)
signal bot_count_changed(value: int)

const CONFIG_PATH := "user://settings.cfg"
## Rebinding your own way out of the pause menu is an edge case not worth
## supporting in a first pass, so "pause" itself is deliberately excluded.
const REBINDABLE_ACTIONS: Array[String] = [
	"move_forward", "move_backward", "move_left", "move_right",
	"jump", "crouch", "sprint", "fire", "ads", "reload",
]

var mouse_sensitivity: float = 0.0025
var fov_degrees: float = 90.0
var master_volume_linear: float = 1.0
var bot_count: int = 4

var _default_keybind_events: Dictionary = {} # action -> Array[InputEvent], captured before any override


func _ready() -> void:
	for action in REBINDABLE_ACTIONS:
		_default_keybind_events[action] = InputMap.action_get_events(action).duplicate()
	_load_from_disk()
	_apply_master_volume()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = value
	mouse_sensitivity_changed.emit(value)


func set_fov(value: float) -> void:
	fov_degrees = value
	fov_changed.emit(value)


func set_master_volume(linear: float) -> void:
	master_volume_linear = linear
	_apply_master_volume()
	master_volume_changed.emit(linear)


func set_bot_count(value: int) -> void:
	bot_count = value
	bot_count_changed.emit(value)


func rebind_action(action: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)


func reset_keybind(action: String) -> void:
	InputMap.action_erase_events(action)
	for event in _default_keybind_events.get(action, []):
		InputMap.action_add_event(action, event)


func reset_all_keybinds() -> void:
	for action in REBINDABLE_ACTIONS:
		reset_keybind(action)


func _apply_master_volume() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(maxf(master_volume_linear, 0.0001)))


func save_to_disk() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("settings", "fov_degrees", fov_degrees)
	config.set_value("settings", "master_volume_linear", master_volume_linear)
	config.set_value("settings", "bot_count", bot_count)
	for action in REBINDABLE_ACTIONS:
		var events := InputMap.action_get_events(action)
		if not events.is_empty():
			config.set_value("keybinds", action, serialize_event(events[0]))
	config.save(CONFIG_PATH)


func _load_from_disk() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	mouse_sensitivity = config.get_value("settings", "mouse_sensitivity", mouse_sensitivity)
	fov_degrees = config.get_value("settings", "fov_degrees", fov_degrees)
	master_volume_linear = config.get_value("settings", "master_volume_linear", master_volume_linear)
	bot_count = config.get_value("settings", "bot_count", bot_count)
	for action in REBINDABLE_ACTIONS:
		var raw = config.get_value("keybinds", action, null)
		var event := deserialize_event(raw) if raw != null else null
		if event:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)


## Pure, side-effect free so it's unit-testable without touching InputMap/disk.
static func serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "code": event.physical_keycode}
	if event is InputEventMouseButton:
		return {"type": "mouse", "code": event.button_index}
	return {}


static func deserialize_event(data: Dictionary) -> InputEvent:
	if data.get("type") == "key":
		var event := InputEventKey.new()
		event.physical_keycode = data.get("code", 0)
		return event
	if data.get("type") == "mouse":
		var event := InputEventMouseButton.new()
		event.button_index = data.get("code", 0)
		return event
	return null


## "move_forward" -> "Move Forward". Godot's own String.capitalize() already
## does exactly this (splits on underscores, title-cases each word).
static func humanize_action_name(action: String) -> String:
	return action.capitalize()
