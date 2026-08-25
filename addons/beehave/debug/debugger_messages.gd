class_name BeehaveDebuggerMessages


## Local patch (not upstream bitbrain/beehave): OS.has_feature("editor") is
## true for any non-exported editor-build binary, including `godot --path .`
## run directly from a terminal with no debugger attached — not just "Play"
## from the editor UI. Without also checking EngineDebugger.is_active(),
## every tree register/tick call throws "Can't send message. No active
## debugger" in that case. Re-check this guard if Beehave is ever updated
## from upstream.
static func can_send_message() -> bool:
	return not Engine.is_editor_hint() and OS.has_feature("editor") and EngineDebugger.is_active()


static func register_tree(beehave_tree: Dictionary) -> void:
	if can_send_message():
		EngineDebugger.send_message("beehave:register_tree", [beehave_tree])


static func unregister_tree(instance_id: int) -> void:
	if can_send_message():
		EngineDebugger.send_message("beehave:unregister_tree", [instance_id])


static func process_tick(instance_id: int, status: int, blackboard: Dictionary = {}) -> void:
	if can_send_message():
		EngineDebugger.send_message("beehave:process_tick", [instance_id, status, blackboard])

static func process_interrupt(instance_id: int, blackboard: Dictionary = {}) -> void:
	if can_send_message():
		EngineDebugger.send_message("beehave:process_interrupt", [instance_id, blackboard])

static func process_begin(instance_id: int, blackboard: Dictionary = {}) -> void:
	if can_send_message():
		EngineDebugger.send_message("beehave:process_begin", [instance_id, blackboard])


static func process_end(instance_id: int, blackboard: Dictionary = {}) -> void:
	if can_send_message():
		EngineDebugger.send_message("beehave:process_end", [instance_id, blackboard])
