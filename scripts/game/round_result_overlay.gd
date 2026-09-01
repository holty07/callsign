# SPDX-License-Identifier: GPL-2.0-or-later
#
# Placeholder round-over banner: winning team plus final score for
# MatchState.result_display_seconds before the round auto-restarts. Map-level
# (one instance per match, not per-player like crosshair/death_overlay), and
# event-driven off MatchState's own signals rather than polling — unlike
# death_overlay.gd, which has to poll because is_alive() has no signal of its
# own, MatchState already emits exactly the events this needs.
class_name RoundResultOverlay
extends Control

@onready var _label: Label = $Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	MatchState.round_ended.connect(_on_round_ended)
	MatchState.round_restarted.connect(_on_round_restarted)


func _on_round_ended(winning_team_id: int) -> void:
	_label.text = _result_text(winning_team_id)
	visible = true


func _on_round_restarted() -> void:
	visible = false


func _result_text(winning_team_id: int) -> String:
	var score_text := "%d : %d" % [MatchState.team_a_score, MatchState.team_b_score]
	if winning_team_id == Team.A:
		return "TEAM A WINS  " + score_text
	if winning_team_id == Team.B:
		return "TEAM B WINS  " + score_text
	return "DRAW  " + score_text
