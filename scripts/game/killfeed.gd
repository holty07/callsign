# SPDX-License-Identifier: GPL-2.0-or-later
#
# Placeholder killfeed — map-level, plain text lines, no team colouring or
# icons yet (greybox before art, same as every other M4 HUD element).
# Listens for MatchState.kill_confirmed; each kill becomes a Label row added
# to a VBoxContainer, newest on top, auto-expiring after entry_duration.
# Doesn't cover kill_zone.gd's environmental deaths — those never call
# MatchState.register_kill at all, so there's no attacker to report.
class_name Killfeed
extends Control

@export var entry_duration: float = 5.0
@export var max_entries: int = 5

@onready var _rows: VBoxContainer = $VBox

var _entries: Array = [] # [{label: Label, remaining: float}, ...], oldest first


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	MatchState.kill_confirmed.connect(_on_kill_confirmed)


func _process(delta: float) -> void:
	for i in range(_entries.size() - 1, -1, -1):
		_entries[i].remaining -= delta
		if _entries[i].remaining <= 0.0:
			_entries[i].label.queue_free()
			_entries.remove_at(i)


func _on_kill_confirmed(shooter_name: String, victim_name: String, was_headshot: bool) -> void:
	var label := Label.new()
	label.text = kill_feed_line(shooter_name, victim_name, was_headshot)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rows.add_child(label)
	_rows.move_child(label, 0) # newest on top

	_entries.append({label = label, remaining = entry_duration})
	if _entries.size() > max_entries:
		var oldest = _entries.pop_front()
		oldest.label.queue_free()


## Pure, side-effect free so it's unit-testable without a live scene.
static func kill_feed_line(shooter_name: String, victim_name: String, was_headshot: bool) -> String:
	var suffix := " (HS)" if was_headshot else ""
	return "%s killed %s%s" % [shooter_name, victim_name, suffix]
