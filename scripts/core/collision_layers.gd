# SPDX-License-Identifier: GPL-2.0-or-later
#
# Named collision layers so these bit values aren't magic numbers scattered
# across every .tscn and the weapon's raycast query.
#
# A character's own movement capsule (CHARACTER_BODY) always fully encloses
# its smaller HitZone shapes (HITZONE) — the torso/head hittable zones sit
# nested inside it. If a weapon raycast's mask included CHARACTER_BODY, it
# would always hit that outer capsule first and never reach the HitZone
# nested inside it, silently registering as "hit something, but it wasn't
# a HitZone" — no damage, no error. So WEAPON_RAYCAST_MASK deliberately
# masks CHARACTER_BODY out: WORLD stops a shot (walls), HITZONE is what a
# shot can actually damage, and a character's bare movement capsule is
# invisible to gunfire entirely.
class_name CollisionLayers

const WORLD: int = 1
const HITZONE: int = 2
const CHARACTER_BODY: int = 4

const WEAPON_RAYCAST_MASK: int = WORLD | HITZONE
const CHARACTER_MOVEMENT_MASK: int = WORLD | CHARACTER_BODY
