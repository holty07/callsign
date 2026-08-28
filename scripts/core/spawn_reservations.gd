# SPDX-License-Identifier: GPL-2.0-or-later
#
# Stopgap for two combatants landing on the same spawn marker at once: the
# occupancy check in spawn_point_picker.gd only rules a marker out once
# someone is standing on it *and* reporting itself alive, which is exactly
# what two respawns resolving in the same stretch of time can both miss —
# neither sees the other as occupying anything yet. Reserving a marker the
# instant it's picked, for a short global window, closes that gap without
# having to reason about exact same-tick ordering between two different
# actors' behaviour trees.
extends Node

## How long a marker stays reserved after being picked. Comfortably longer
## than a physics frame or two — short enough that a marker isn't left
## unusable for any real stretch of a match if a reservation is never
## actually consumed (e.g. the reserving bot despawning mid-pick).
@export var reservation_seconds: float = 2.0

var _reserved_until_msec: Dictionary = {} # marker instance ID -> Time.get_ticks_msec() it expires


func is_reserved(marker: Node) -> bool:
	var expires: int = _reserved_until_msec.get(marker.get_instance_id(), 0)
	return Time.get_ticks_msec() < expires


func reserve(marker: Node) -> void:
	_reserved_until_msec[marker.get_instance_id()] = Time.get_ticks_msec() + int(reservation_seconds * 1000.0)
