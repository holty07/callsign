# SPDX-License-Identifier: GPL-2.0-or-later
#
# Minimal driver for the nav_debug repro map: commands the one bot to walk
# to the target marker once on ready. Nothing else — no respawn, no combat,
# no per-tick re-issuing. gdUnit4 tests drive the bot directly and don't
# need this; it exists so the scene is watchable when run interactively.
extends Node3D

@onready var _bot: Bot = $Bot
@onready var _target: Marker3D = $TargetMarker
@onready var _nav_region: NavigationBaker = $NavigationRegion3D


func _ready() -> void:
	await _nav_region.navmesh_ready
	_bot.move_to(_target.global_position)
