# SPDX-License-Identifier: GPL-2.0-or-later
#
# Reports every hit to the console and flashes briefly, so shooting it
# actually feels like it's landing. Resets a beat after "dying" so the same
# target can be shot over and over during a tuning session.
extends Node3D

const _BASE_COLOR := Color(0.6, 0.6, 0.6)
const _FLASH_COLOR := Color(1.0, 0.15, 0.15)
const _FLASH_DURATION := 0.08

@export var respawn_delay: float = 1.0

@onready var _health: Health = $Health
@onready var _meshes: Array[MeshInstance3D] = [$TorsoBody/MeshInstance3D, $HeadBody/MeshInstance3D]


func _ready() -> void:
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)


func _on_damaged(amount: float, was_headshot: bool, _hit_position: Vector3) -> void:
	print("Dummy hit for %.1f%s (%.0f/%.0f hp)" % [
		amount,
		" (HEADSHOT)" if was_headshot else "",
		_health.current_health,
		_health.max_health,
	])
	_set_mesh_color(_FLASH_COLOR)
	get_tree().create_timer(_FLASH_DURATION).timeout.connect(_on_flash_timeout)


func _on_died() -> void:
	print("Dummy down. Respawning in %.1fs." % respawn_delay)
	get_tree().create_timer(respawn_delay).timeout.connect(_health.reset)


func _on_flash_timeout() -> void:
	if _health.current_health > 0.0:
		_set_mesh_color(_BASE_COLOR)


func _set_mesh_color(color: Color) -> void:
	for mesh in _meshes:
		var mat := mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = color
