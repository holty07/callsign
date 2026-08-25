# SPDX-License-Identifier: GPL-2.0-or-later
#
# A difficulty tier is a bundle of perception/aim/weapon tuning values, not
# a health or damage multiplier — see CLAUDE.md's roadmap note: "driven by
# reaction delay / aim error / spread, not health cheats". Every bot fights
# with the same Health, the same WeaponBase, the same damage math as the
# player; only how well it perceives and aims changes between tiers.
class_name BotDifficulty
extends Resource

@export_group("Perception")
@export var fov_deg: float = 100.0
@export var reaction_delay: float = 0.25
@export var memory_duration: float = 5.0

@export_group("Aim")
@export var error_cone_deg: float = 3.0
@export var turn_rate_deg: float = 220.0

@export_group("Weapon")
## Applied to the bot's own rifle instance only — every other actor's
## spread (the player's included) is untouched.
@export var hipfire_spread_deg: float = 3.0
