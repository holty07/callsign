# SPDX-License-Identifier: GPL-2.0-or-later
#
# Debug-only overlay: shows this bot's name above its head, makes its
# hitzone meshes render through walls in an unmissable colour, and prints a
# periodic position sample so "is this bot actually moving?" is answerable
# from the console instead of guessing — the stuck-position logging noted
# as missing in docs/BACKLOG.md. Purely diagnostic — set enabled to false
# (or delete this node and its Label3D child) once that's no longer in
# question. None of this belongs in the shipped look.
extends Node3D

@export var enabled: bool = true
@export var debug_color: Color = Color(1.0, 0.0, 1.0)
@export var log_movement: bool = true
@export var log_interval: float = 1.0 # seconds between position samples

@onready var _label: Label3D = $Label3D

var _bot: Node3D
var _time_since_log: float = 0.0
var _position_at_last_log: Vector3


func _ready() -> void:
	_label.visible = enabled
	if not enabled:
		return

	_bot = get_parent()
	_label.text = _bot.name
	_position_at_last_log = _bot.global_position

	var debug_material := StandardMaterial3D.new()
	debug_material.albedo_color = debug_color
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.no_depth_test = true
	debug_material.render_priority = 100

	_apply_debug_material(_bot.get_node_or_null("Visual/TorsoBody/MeshInstance3D"), debug_material)
	_apply_debug_material(_bot.get_node_or_null("Visual/HeadHitZone/MeshInstance3D"), debug_material)


func _apply_debug_material(mesh: MeshInstance3D, material: StandardMaterial3D) -> void:
	if mesh:
		mesh.material_override = material


func _physics_process(delta: float) -> void:
	if not (enabled and log_movement) or _bot == null:
		return

	_time_since_log += delta
	if _time_since_log < log_interval:
		return

	var displacement := _bot.global_position.distance_to(_position_at_last_log)
	var nav_finished: bool = _bot.is_move_finished() if _bot.has_method("is_move_finished") else true
	print("[bot-debug] %s pos=%s moved=%.2fm/%.1fs alive=%s nav_finished=%s wish_velocity=%s velocity_before_move=%s velocity_after_move=%s" % [
		_bot.name, _bot.global_position, displacement, _time_since_log, _bot.is_alive(), nav_finished,
		_bot.last_wish_velocity, _bot.last_velocity_before_move, _bot.velocity
	])

	_position_at_last_log = _bot.global_position
	_time_since_log = 0.0
