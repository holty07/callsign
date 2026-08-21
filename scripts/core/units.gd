# SPDX-License-Identifier: GPL-2.0-or-later
class_name Units

## Quake units, as used throughout scripts/player/pmove.gd. Movement constants
## (speeds, accel, gravity, jump velocity) stay in Quake units in the exported
## variables so documented Quake III tuning values can be dropped in directly.
## Convert only at the boundary where a value meets Godot's physics/rendering
## (setting CharacterBody3D.velocity, sizing a collision shape, etc).

const QU_TO_M: float = 0.0254
const M_TO_QU: float = 1.0 / QU_TO_M
