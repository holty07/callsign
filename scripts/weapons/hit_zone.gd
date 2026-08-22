# SPDX-License-Identifier: GPL-2.0-or-later
#
# Marks a StaticBody3D as a hitscan-detectable collider reporting to a
# shared Health component, distinguishing headshot zones from the rest of
# the body so WeaponBase doesn't need to know anything about a target's
# internal layout.
class_name HitZone
extends StaticBody3D

@export var is_head: bool = false
@export var health_path: NodePath = ^"../Health"


func get_target_health() -> Health:
	return get_node(health_path)
