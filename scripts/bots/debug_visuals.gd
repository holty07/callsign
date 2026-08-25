# SPDX-License-Identifier: GPL-2.0-or-later
#
# Debug-only overlay: shows this bot's name above its head and makes its
# hitzone meshes render through walls in an unmissable colour. Purely for
# tracking down "why can't I see the bots" — set enabled to false (or
# delete this node and its Label3D child) once that's no longer in
# question. None of this belongs in the shipped look.
extends Node3D

@export var enabled: bool = true
@export var debug_color: Color = Color(1.0, 0.0, 1.0)

@onready var _label: Label3D = $Label3D


func _ready() -> void:
	_label.visible = enabled
	if not enabled:
		return

	var bot := get_parent()
	_label.text = bot.name

	var debug_material := StandardMaterial3D.new()
	debug_material.albedo_color = debug_color
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.no_depth_test = true
	debug_material.render_priority = 100

	_apply_debug_material(bot.get_node_or_null("TorsoBody/MeshInstance3D"), debug_material)
	_apply_debug_material(bot.get_node_or_null("HeadHitZone/MeshInstance3D"), debug_material)


func _apply_debug_material(mesh: MeshInstance3D, material: StandardMaterial3D) -> void:
	if mesh:
		mesh.material_override = material
