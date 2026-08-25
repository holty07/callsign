# SPDX-License-Identifier: GPL-2.0-or-later
#
# Joins this Marker3D to a group at ready. Used for map-defined points
# (bot spawn points, patrol waypoints, cover points) that bot scripts look
# up via get_tree().get_nodes_in_group() rather than a hardcoded NodePath,
# so a map can define any number of them with no code changes.
extends Marker3D

@export var group_name: String = ""


func _ready() -> void:
	if not group_name.is_empty():
		add_to_group(group_name)
