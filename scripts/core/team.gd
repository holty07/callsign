# SPDX-License-Identifier: GPL-2.0-or-later
#
# Team identity: just two invented designations (never real unit names, per
# CLAUDE.md rule 2) plus the one thing every spawn-point consumer needs — which
# marker group belongs to which team.
class_name Team

const A := 0
const B := 1

static func spawn_group_name(team_id: int) -> String:
	return "team_a_spawn_points" if team_id == A else "team_b_spawn_points"
