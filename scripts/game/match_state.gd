# SPDX-License-Identifier: GPL-2.0-or-later
#
# Autoload. Owns score/timer/round-over state for Team Deathmatch. Kill
# attribution is resolved by weapon_base.gd (it already has shooter and victim
# identity on hand at the point of a confirmed hit) and reported in here via
# register_kill() — Health itself carries no attacker payload and stays the
# same dumb, reusable component every actor shares.
extends Node

signal score_changed(team_a_score: int, team_b_score: int)
signal round_ended(winning_team_id: int) # Team.A / Team.B / -1 for a draw
signal round_restarted()

@export var score_limit: int = 30
@export var time_limit_seconds: float = 600.0
@export var friendly_fire_enabled: bool = false
@export var result_display_seconds: float = 5.0
## Same hazard SpawnPointPicker guards against everywhere else: landing a
## respawn on top of a living combatant spawns two fully-overlapping
## CharacterBody3D capsules that immediately depenetrate into each other.
@export var clear_radius: float = 1.5
## Avoid respawning within this distance of a living enemy specifically —
## teammates nearby are fine, an enemy in your face on spawn isn't.
@export var enemy_avoid_radius: float = 15.0
## Damage immunity granted by every respawn_at() call (Bot and PMove both
## read this directly) — long enough that a spawn which does end up exposed
## isn't an instant, unavoidable kill.
@export var spawn_protection_seconds: float = 1.0

var team_a_score: int = 0
var team_b_score: int = 0
var time_remaining: float = 0.0
var round_over: bool = false

var _result_timer: float = 0.0


func _ready() -> void:
	time_remaining = time_limit_seconds


func _process(delta: float) -> void:
	if round_over:
		_result_timer -= delta
		if _result_timer <= 0.0:
			restart_round()
		return

	time_remaining = maxf(time_remaining - delta, 0.0)
	if time_remaining <= 0.0:
		_end_round(_leading_team())


## No scoring effect either way for a team-kill (shooter_team_id ==
## victim_team_id) — friendly_fire_enabled only governs whether the damage
## that produced this kill was allowed to happen at all (see
## weapon_base.gd::is_friendly_fire_blocked); once a kill is reported here,
## a team-kill just never moves the scoreboard.
func register_kill(shooter_team_id: int, victim_team_id: int) -> void:
	if round_over or shooter_team_id == victim_team_id:
		return
	if shooter_team_id != Team.A and shooter_team_id != Team.B:
		return

	if shooter_team_id == Team.A:
		team_a_score += 1
	else:
		team_b_score += 1
	score_changed.emit(team_a_score, team_b_score)

	if team_a_score >= score_limit or team_b_score >= score_limit:
		_end_round(Team.A if team_a_score >= score_limit else Team.B)


func _leading_team() -> int:
	if team_a_score == team_b_score:
		return -1
	return Team.A if team_a_score > team_b_score else Team.B


func _end_round(winning_team_id: int) -> void:
	round_over = true
	_result_timer = result_display_seconds
	round_ended.emit(winning_team_id)


## Resets scores/timer and respawns every combatant via the same respawn_at()
## every death path already uses — it resets health/velocity and grants a
## fresh spawn-protection window internally on both Bot and PMove, so there's
## no separate health-reset or invulnerability step needed here.
func restart_round() -> void:
	team_a_score = 0
	team_b_score = 0
	time_remaining = time_limit_seconds
	round_over = false

	for combatant in get_tree().get_nodes_in_group("combatants"):
		if combatant.has_method("respawn_at") and combatant.has_method("get_team_id"):
			var spawn_position := SpawnPointPicker.pick(get_tree(), Team.spawn_group_name(combatant.get_team_id()), combatant, clear_radius, combatant.global_position, enemy_avoid_radius)
			combatant.respawn_at(spawn_position)

	round_restarted.emit()
