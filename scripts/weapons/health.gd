# SPDX-License-Identifier: GPL-2.0-or-later
class_name Health
extends Node

signal damaged(amount: float, was_headshot: bool, hit_position: Vector3)
signal died()

@export var max_health: float = 100.0

var current_health: float


func _ready() -> void:
	current_health = max_health


func apply_damage(amount: float, was_headshot: bool = false, hit_position: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	damaged.emit(amount, was_headshot, hit_position)

	if current_health <= 0.0:
		died.emit()


func reset() -> void:
	current_health = max_health
