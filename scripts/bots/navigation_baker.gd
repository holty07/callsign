# SPDX-License-Identifier: GPL-2.0-or-later
#
# Bakes its own navmesh at runtime from whatever collision geometry sits
# under it, rather than shipping a pre-baked one. The M1 greybox test map is
# still being iterated on, and a pre-baked NavigationMesh resource would go
# stale every time the geometry changes — see CLAUDE.md's "prefer a working
# ugly version first". Revisit once M5 replaces the greybox with a real map.
#
# class_name'd because it's reused across maps (nav_debug.tscn, test_box.tscn)
# and other scripts (nav_debug_driver.gd) need a typed reference to await
# navmesh_ready on.
class_name NavigationBaker
extends NavigationRegion3D

## Fires once the bake is done and the resulting navmesh has had a real
## chance to become queryable. Anything that calls move_to() on a bot before
## this fires risks racing an unbaked/not-yet-usable navmesh:
## get_next_path_position() falls back to the agent's own position with no
## usable path, which looks like the bot standing still forever with
## is_navigation_finished() stuck reporting false.
signal navmesh_ready

## On a genuinely cold-started engine (this is the first navigation activity
## in the process — nothing else has baked/queried a navmesh yet), baking
## after only 1-2 frames measurably produces a navmesh that LOOKS correct
## (right polygon count, right vertices) but whose pathfinding queries never
## resolve — get_next_path_position() and is_target_reachable() stay
## permanently stuck, no matter how long you wait afterwards. Empirically,
## waiting 5 frames before the *first* bake attempt is enough for pathing to
## work reliably; this project has never explained why the engine needs
## that (no bake_finished/map sync signal ever surfaces it), so 10 is a
## deliberately generous margin above the observed minimum, not a tuned
## value — see nav_debug.tscn and tests/test_nav_diagnostic.gd, the repro
## this was diagnosed against.
const _COLD_START_SETTLE_FRAMES := 10

## Generous ceiling for retrying an empty bake below — CSG geometry combining
## can itself take more than one physics frame to finish on a cold-started
## engine, which produces a bake with zero polygons even after the settle
## above. 60 frames is half a second at this project's 120Hz physics tick —
## far more than a cold start needs, while still catching a genuinely
## broken map (no collidable geometry at all) instead of looping forever.
const _MAX_BAKE_ATTEMPTS := 60


func _ready() -> void:
	for _i in _COLD_START_SETTLE_FRAMES:
		await get_tree().physics_frame
	bake_navigation_mesh(false)
	var attempts := 1
	while navigation_mesh.get_polygon_count() == 0 and attempts < _MAX_BAKE_ATTEMPTS:
		await get_tree().physics_frame
		bake_navigation_mesh(false)
		attempts += 1
	if navigation_mesh.get_polygon_count() == 0:
		push_warning("%s: navmesh baked with zero polygons after %d attempts — no collidable geometry found under this region?" % [name, attempts])
	navmesh_ready.emit()
