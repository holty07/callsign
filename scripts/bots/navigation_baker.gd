# SPDX-License-Identifier: GPL-2.0-or-later
#
# Bakes its own navmesh at runtime from whatever collision geometry sits
# under it, rather than shipping a pre-baked one. The M1 greybox test map is
# still being iterated on, and a pre-baked NavigationMesh resource would go
# stale every time the geometry changes — see CLAUDE.md's "prefer a working
# ugly version first". Revisit once M5 replaces the greybox with a real map.
extends NavigationRegion3D


func _ready() -> void:
	await get_tree().physics_frame
	bake_navigation_mesh(false)
