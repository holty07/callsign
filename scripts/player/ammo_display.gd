# SPDX-License-Identifier: GPL-2.0-or-later
#
# Placeholder ammo readout — plain "magazine / reserve" text. Event-driven off
# WeaponBase's own ammo_changed signal (already emitted on fire/reload/ready),
# unlike health_display.gd which has no equivalent signal to lean on.
class_name AmmoDisplay
extends Control

@export var weapon_path: NodePath

@onready var _label: Label = $Label

var _weapon: WeaponBase


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weapon = get_node_or_null(weapon_path)
	if _weapon:
		_weapon.ammo_changed.connect(_on_ammo_changed)
		# WeaponBase emits its own initial ammo_changed from its own
		# _ready(), which may already have run (and been missed) by the time
		# this connects, depending on node-tree _ready() ordering. Seed the
		# label with magazine_size/reserve_ammo_max — the public exported
		# starting values a fresh weapon always begins at (safe to read
		# directly, unlike the private runtime _magazine_ammo/_reserve_ammo
		# counters) — so the display is never wrong before the first shot.
		_on_ammo_changed(_weapon.magazine_size, _weapon.reserve_ammo_max)


func _on_ammo_changed(magazine_ammo: int, reserve_ammo: int) -> void:
	_label.text = "%d / %d" % [magazine_ammo, reserve_ammo]
