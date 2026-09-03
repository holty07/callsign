# SPDX-License-Identifier: GPL-2.0-or-later
#
# Placeholder score/timer readout — map-level (one per match, not per-player),
# talks straight to the MatchState autoload like round_result_overlay.gd does
# rather than taking a NodePath. Scores update off MatchState.score_changed;
# the timer polls every frame (same "no convenient signal, just poll" call
# death_overlay.gd already made — MatchState.time_remaining just counts down
# in its own _process, nothing to connect to).
class_name ScoreDisplay
extends Control

## Match Bot's own team_a_color/team_b_color defaults — duplicated here since
## those are per-instance exports on a live Bot, not a shared constant.
@export var team_a_color: Color = Color(0.2, 0.45, 0.9)
@export var team_b_color: Color = Color(0.85, 0.15, 0.15)

@onready var _team_a_label: Label = $HBox/TeamALabel
@onready var _team_b_label: Label = $HBox/TeamBLabel
@onready var _timer_label: Label = $HBox/TimerLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_a_label.modulate = team_a_color
	_team_b_label.modulate = team_b_color
	MatchState.score_changed.connect(_on_score_changed)
	_on_score_changed(MatchState.team_a_score, MatchState.team_b_score)


func _process(_delta: float) -> void:
	_timer_label.text = format_time(MatchState.time_remaining)


func _on_score_changed(team_a_score: int, team_b_score: int) -> void:
	_team_a_label.text = "TEAM A %d" % team_a_score
	_team_b_label.text = "TEAM B %d" % team_b_score


## Pure, side-effect free so it's unit-testable. Floors rather than rounds so
## the display never reads e.g. "0:00" with real time still left on the clock.
static func format_time(seconds: float) -> String:
	var whole := maxi(0, int(seconds))
	return "%d:%02d" % [whole / 60, whole % 60]
