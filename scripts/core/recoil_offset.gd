# SPDX-License-Identifier: GPL-2.0-or-later
#
# Shared math for apply_recoil_offset(), which camera_look.gd (player) and
# aim.gd (bots) both implement against the same contract so WeaponBase can
# call it on either without knowing which it has.
class_name RecoilOffset

## Converts an absolute recoil kick (pitch, yaw) in degrees, as WeaponBase
## reports it, to the radians both callers store and rotate by.
static func from_degrees(offset_deg: Vector2) -> Vector2:
	return Vector2(deg_to_rad(offset_deg.x), deg_to_rad(offset_deg.y))
