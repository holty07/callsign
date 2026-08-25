# SPDX-License-Identifier: GPL-2.0-or-later
#
# Global noise event bus. Gunfire (and later, other loud actions) reports
# itself here; Perception listens so bots can react to a noise they didn't
# see, without every weapon needing to know which bots are in earshot.
extends Node

signal noise_emitted(position: Vector3, radius: float, source: Node)


func notify(position: Vector3, radius: float, source: Node = null) -> void:
	noise_emitted.emit(position, radius, source)
