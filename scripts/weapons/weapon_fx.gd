# SPDX-License-Identifier: GPL-2.0-or-later
#
# Placeholder hit-feedback effects: a muzzle flash, a hitscan tracer streak,
# and a flat impact "decal". All greybox — plain colours, no textures, no
# assets — swap for real VFX in M6.
class_name WeaponFX
extends RefCounted

const _MUZZLE_FLASH_LIFETIME := 0.05
const _TRACER_LIFETIME := 0.06
const _IMPACT_DECAL_LIFETIME := 8.0


static func spawn_muzzle_flash(muzzle: Node3D) -> void:
	var light := OmniLight3D.new()
	light.light_energy = 8.0
	light.omni_range = 3.0
	light.light_color = Color(1.0, 0.85, 0.5)
	muzzle.add_child(light)

	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.08, 0.08)
	quad.mesh = mesh
	quad.material_override = _unshaded_material(Color(1.0, 0.9, 0.5))
	muzzle.add_child(quad)

	muzzle.get_tree().create_timer(_MUZZLE_FLASH_LIFETIME).timeout.connect(light.queue_free)
	muzzle.get_tree().create_timer(_MUZZLE_FLASH_LIFETIME).timeout.connect(quad.queue_free)


static func spawn_tracer(parent: Node, from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.01:
		return

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.02, 0.02, length)
	mesh_instance.mesh = box
	mesh_instance.material_override = _unshaded_material(Color(1.0, 0.9, 0.4))

	parent.add_child(mesh_instance)
	mesh_instance.global_position = (from + to) * 0.5
	mesh_instance.look_at(to, Vector3.UP)

	parent.get_tree().create_timer(_TRACER_LIFETIME).timeout.connect(mesh_instance.queue_free)


static func spawn_impact_decal(parent: Node, hit_position: Vector3, normal: Vector3) -> void:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.12, 0.12)
	quad.mesh = mesh
	quad.material_override = _unshaded_material(Color(0.05, 0.05, 0.05, 0.85))

	parent.add_child(quad)
	quad.global_position = hit_position + normal * 0.01
	quad.global_transform.basis = Basis.looking_at(-normal, Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT)

	parent.get_tree().create_timer(_IMPACT_DECAL_LIFETIME).timeout.connect(quad.queue_free)


static func _unshaded_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
