# SPDX-License-Identifier: GPL-2.0-or-later
#
# Settings is an autoload (a live singleton for the whole test run, same
# reasoning as test_match_state.gd), so every test resets its mutable state in
# before_test/after_test. InputMap is also global/shared: any test that
# rebinds an action gets it restored afterward via Settings.reset_all_keybinds(),
# which replays whatever InputMap held at Settings' own _ready() — i.e.
# project.godot's real defaults, captured once before any test ever runs.
extends GdUnitTestSuite


func before_test() -> void:
	Settings.mouse_sensitivity = 0.0025
	Settings.fov_degrees = 90.0
	Settings.master_volume_linear = 1.0
	Settings.bot_count = 4


func after_test() -> void:
	before_test()
	Settings.reset_all_keybinds()


func test_serialize_and_deserialize_a_key_event_round_trips() -> void:
	var original := InputEventKey.new()
	original.physical_keycode = KEY_W

	var data := Settings.serialize_event(original)
	var restored: InputEventKey = Settings.deserialize_event(data)

	assert_int(restored.physical_keycode).is_equal(KEY_W)


func test_serialize_and_deserialize_a_mouse_button_event_round_trips() -> void:
	var original := InputEventMouseButton.new()
	original.button_index = MOUSE_BUTTON_LEFT

	var data := Settings.serialize_event(original)
	var restored: InputEventMouseButton = Settings.deserialize_event(data)

	assert_int(restored.button_index).is_equal(MOUSE_BUTTON_LEFT)


func test_humanize_action_name() -> void:
	assert_str(Settings.humanize_action_name("move_forward")).is_equal("Move Forward")


func test_set_mouse_sensitivity_emits_signal_with_new_value() -> void:
	var values := []
	var on_changed := func(v): values.append(v)
	Settings.mouse_sensitivity_changed.connect(on_changed)

	Settings.set_mouse_sensitivity(0.005)

	assert_float(Settings.mouse_sensitivity).is_equal(0.005)
	assert_array(values).is_equal([0.005])
	Settings.mouse_sensitivity_changed.disconnect(on_changed)


func test_set_fov_emits_signal_with_new_value() -> void:
	var values := []
	var on_changed := func(v): values.append(v)
	Settings.fov_changed.connect(on_changed)

	Settings.set_fov(100.0)

	assert_float(Settings.fov_degrees).is_equal(100.0)
	assert_array(values).is_equal([100.0])
	Settings.fov_changed.disconnect(on_changed)


func test_set_master_volume_emits_signal_and_applies_to_the_audio_bus() -> void:
	var values := []
	var on_changed := func(v): values.append(v)
	Settings.master_volume_changed.connect(on_changed)

	Settings.set_master_volume(0.5)

	assert_float(Settings.master_volume_linear).is_equal(0.5)
	assert_array(values).is_equal([0.5])
	var bus := AudioServer.get_bus_index("Master")
	assert_float(AudioServer.get_bus_volume_db(bus)).is_equal_approx(linear_to_db(0.5), 0.01)

	Settings.master_volume_changed.disconnect(on_changed)
	Settings.set_master_volume(1.0) # restore before/after_test doesn't touch the audio bus itself


func test_set_bot_count_emits_signal_with_new_value() -> void:
	var values := []
	var on_changed := func(v): values.append(v)
	Settings.bot_count_changed.connect(on_changed)

	Settings.set_bot_count(6)

	assert_int(Settings.bot_count).is_equal(6)
	assert_array(values).is_equal([6])
	Settings.bot_count_changed.disconnect(on_changed)


func test_reset_keybind_restores_the_original_binding_after_a_rebind() -> void:
	var original_keycode: int = InputMap.action_get_events("jump")[0].physical_keycode

	var new_event := InputEventKey.new()
	new_event.physical_keycode = KEY_J
	Settings.rebind_action("jump", new_event)
	assert_int(InputMap.action_get_events("jump")[0].physical_keycode).is_equal(KEY_J)

	Settings.reset_keybind("jump")

	assert_int(InputMap.action_get_events("jump")[0].physical_keycode).is_equal(original_keycode)
