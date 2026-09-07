# SPDX-License-Identifier: GPL-2.0-or-later
#
# Feedback for taking damage: a red vignette flash that spikes on each hit
# and fades, plus a directional marker at the screen edge showing which way
# the hit came from. Health.damaged's source_position is the shooter's own
# ray origin (see weapon_base.gd), so the direction is exact — no need to
# infer it from where the shot happened to land on this body's collider.
class_name DamageIndicator
extends Control

@export var health_path: NodePath
@export var player_path: NodePath

@export_group("Vignette")
@export var vignette_color: Color = Color(0.8, 0.05, 0.05)
@export var vignette_max_alpha: float = 0.55
## Alpha floor for the smallest hits, so a chip of damage still reads as
## "something happened" rather than being invisible next to a big hit.
@export var vignette_min_intensity: float = 0.25
## Damage amount that maxes out the flash. Bigger hits beyond this don't
## flash any harder, they just still hit the ceiling.
@export var vignette_full_damage_amount: float = 40.0
@export var vignette_flash_duration: float = 0.6
## Fraction of the shorter screen dimension the vignette fades over, in from
## each edge.
@export var vignette_inset_fraction: float = 0.16

@export_group("Directional marker")
@export var indicator_color: Color = Color(0.9, 0.1, 0.1)
@export var indicator_duration: float = 1.2
@export var indicator_max_alpha: float = 0.9
@export var indicator_radius_px: float = 140.0
@export var indicator_size_px: float = 26.0
@export var max_indicators: int = 6

var _health: Health
var _player: Node3D
var _vignette_intensity: float = 0.0
var _vignette_timer: float = 0.0
var _indicators: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_health = get_node_or_null(health_path)
	_player = get_node_or_null(player_path)
	if _health:
		_health.damaged.connect(_on_damaged)


func _process(delta: float) -> void:
	_vignette_timer = maxf(_vignette_timer - delta, 0.0)
	for entry in _indicators:
		entry["time_left"] = maxf(entry["time_left"] - delta, 0.0)
	_indicators = _indicators.filter(func(entry: Dictionary) -> bool: return entry["time_left"] > 0.0)
	queue_redraw()


func _draw() -> void:
	var vignette_alpha := vignette_alpha_for(_vignette_intensity, _vignette_timer, vignette_flash_duration, vignette_max_alpha)
	if vignette_alpha > 0.0:
		_draw_vignette(vignette_alpha)

	for entry in _indicators:
		var alpha: float = entry["time_left"] / indicator_duration * indicator_max_alpha
		_draw_indicator(entry["angle"], alpha)


func _on_damaged(amount: float, _was_headshot: bool, source_position: Vector3) -> void:
	_vignette_intensity = flash_intensity_for(amount, vignette_full_damage_amount, vignette_min_intensity)
	_vignette_timer = vignette_flash_duration

	if _player == null:
		return

	var direction := source_position - _player.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return

	var angle := angle_from_direction(direction, _player.global_transform.basis)
	_indicators.append({"angle": angle, "time_left": indicator_duration})
	if _indicators.size() > max_indicators:
		_indicators.pop_front()


func _draw_vignette(alpha: float) -> void:
	var w := size.x
	var h := size.y
	var depth := minf(w, h) * vignette_inset_fraction
	var edge := Color(vignette_color.r, vignette_color.g, vignette_color.b, alpha)
	var clear := Color(vignette_color.r, vignette_color.g, vignette_color.b, 0.0)

	draw_polygon(PackedVector2Array([Vector2(0.0, 0.0), Vector2(w, 0.0), Vector2(w, depth), Vector2(0.0, depth)]), PackedColorArray([edge, edge, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0.0, h), Vector2(w, h), Vector2(w, h - depth), Vector2(0.0, h - depth)]), PackedColorArray([edge, edge, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.0, h), Vector2(depth, h), Vector2(depth, 0.0)]), PackedColorArray([edge, edge, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(w, 0.0), Vector2(w, h), Vector2(w - depth, h), Vector2(w - depth, 0.0)]), PackedColorArray([edge, edge, clear, clear]))


## Draws a chevron at the screen edge, pointing outward along the radial
## direction — away from centre, toward where the damage came from — not
## inward at the player.
func _draw_indicator(angle: float, alpha: float) -> void:
	var center := size * 0.5
	var out_dir := Vector2(sin(angle), -cos(angle))
	var perp := Vector2(-out_dir.y, out_dir.x)
	var base_pos := center + out_dir * indicator_radius_px
	var color := Color(indicator_color.r, indicator_color.g, indicator_color.b, alpha)

	var tip := base_pos + out_dir * indicator_size_px * 0.6
	var left := base_pos - out_dir * indicator_size_px * 0.4 + perp * indicator_size_px * 0.5
	var right := base_pos - out_dir * indicator_size_px * 0.4 - perp * indicator_size_px * 0.5
	draw_polygon(PackedVector2Array([tip, left, right]), PackedColorArray([color, color, color]))


## Pure decay rule for the vignette's current alpha. Kept static and side
## effect free so it's unit-testable without a live Control/timer.
static func vignette_alpha_for(intensity: float, time_left: float, duration: float, max_alpha: float) -> float:
	if duration <= 0.0:
		return 0.0
	return max_alpha * intensity * clampf(time_left / duration, 0.0, 1.0)


## Pure mapping from damage amount to flash strength: scales up to
## full_damage_amount, clamped to a floor so small hits still show something.
## Kept static and side effect free so it's unit-testable without a live
## Health node.
static func flash_intensity_for(amount: float, full_damage_amount: float, min_intensity: float) -> float:
	if full_damage_amount <= 0.0:
		return 1.0
	return clampf(amount / full_damage_amount, min_intensity, 1.0)


## Pure projection of a world-space direction into an angle relative to the
## player's forward (-Z), on the horizontal plane only. 0 is straight ahead,
## positive is clockwise (to the right) — matches _draw_indicator's mapping
## from angle to screen position. Kept static and side effect free so it's
## unit-testable without a live Node3D.
static func angle_from_direction(world_direction: Vector3, player_basis: Basis) -> float:
	var local_direction := player_basis.inverse() * world_direction
	local_direction.y = 0.0
	if local_direction.length_squared() < 0.0001:
		return 0.0
	return atan2(local_direction.x, -local_direction.z)
