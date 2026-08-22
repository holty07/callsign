# SPDX-License-Identifier: GPL-2.0-or-later
#
# Hipfire reticle: four lines whose gap tracks the equipped weapon's current
# spread cone, converted from an angle to on-screen pixels via the camera's
# vertical FOV. There's no ADS viewmodel yet, so while aiming this collapses
# to a fixed centre dot as a "spot on accurate" placeholder — replace with a
# proper ADS reticle once ADS viewmodels exist. Also draws a fading cross
# hitmarker on top when the weapon reports a confirmed hit.
class_name Crosshair
extends Control

@export var weapon_path: NodePath
@export var camera_path: NodePath

@export_group("Hipfire")
@export var line_length_px: float = 10.0
@export var line_thickness_px: float = 2.0
@export var gap_min_px: float = 4.0
@export var reticle_color: Color = Color.WHITE

@export_group("ADS placeholder")
@export var ads_dot_radius_px: float = 1.5
@export var ads_blend_threshold: float = 0.95

@export_group("Hitmarker")
@export var hitmarker_duration: float = 0.25
@export var hitmarker_length_px: float = 8.0
@export var hitmarker_thickness_px: float = 2.0
@export var hitmarker_hit_color: Color = Color.WHITE
@export var hitmarker_headshot_color: Color = Color(1.0, 0.85, 0.0)
@export var hitmarker_kill_color: Color = Color(0.9, 0.1, 0.1)

var _weapon: WeaponBase
var _camera: Camera3D
var _hitmarker_timer: float = 0.0
var _hitmarker_color: Color = Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_weapon = get_node_or_null(weapon_path)
	_camera = get_node_or_null(camera_path)
	if _weapon:
		_weapon.hit_confirmed.connect(_on_hit_confirmed)


func _process(delta: float) -> void:
	_hitmarker_timer = maxf(_hitmarker_timer - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if _weapon == null or _camera == null:
		return

	var center := size * 0.5

	if _weapon.get_ads_blend() >= ads_blend_threshold:
		draw_circle(center, ads_dot_radius_px, reticle_color)
	else:
		var gap := _spread_gap_px()
		draw_line(center + Vector2(0.0, gap), center + Vector2(0.0, gap + line_length_px), reticle_color, line_thickness_px)
		draw_line(center - Vector2(0.0, gap), center - Vector2(0.0, gap + line_length_px), reticle_color, line_thickness_px)
		draw_line(center + Vector2(gap, 0.0), center + Vector2(gap + line_length_px, 0.0), reticle_color, line_thickness_px)
		draw_line(center - Vector2(gap, 0.0), center - Vector2(gap + line_length_px, 0.0), reticle_color, line_thickness_px)

	if _hitmarker_timer > 0.0:
		_draw_hitmarker(center)


func _draw_hitmarker(center: Vector2) -> void:
	var alpha := _hitmarker_timer / hitmarker_duration
	var color := Color(_hitmarker_color.r, _hitmarker_color.g, _hitmarker_color.b, alpha)
	var d := hitmarker_length_px
	draw_line(center + Vector2(-d, -d), center + Vector2(d, d), color, hitmarker_thickness_px)
	draw_line(center + Vector2(-d, d), center + Vector2(d, -d), color, hitmarker_thickness_px)


func _on_hit_confirmed(was_headshot: bool, was_kill: bool) -> void:
	_hitmarker_color = hitmarker_color_for(was_headshot, was_kill, hitmarker_hit_color, hitmarker_headshot_color, hitmarker_kill_color)
	_hitmarker_timer = hitmarker_duration


## Pure priority rule: a kill marker always wins, then headshot, then a plain
## hit. Kept static and side-effect free so it's unit-testable without a live
## weapon/signal wiring.
static func hitmarker_color_for(was_headshot: bool, was_kill: bool, hit_color: Color, headshot_color: Color, kill_color: Color) -> Color:
	if was_kill:
		return kill_color
	if was_headshot:
		return headshot_color
	return hit_color


func _spread_gap_px() -> float:
	var radius := spread_to_screen_radius_px(_weapon.get_current_spread_rad(), deg_to_rad(_camera.fov), size.y)
	return maxf(radius, gap_min_px)


## Pure projection: a cone of half-angle `spread_rad`, seen through a camera
## with vertical field of view `vertical_fov_rad`, traces a circle of this
## radius (in pixels) on a viewport `viewport_height_px` tall. Kept static and
## side-effect free so it's unit-testable without a live Camera3D/Control.
static func spread_to_screen_radius_px(spread_rad: float, vertical_fov_rad: float, viewport_height_px: float) -> float:
	if viewport_height_px <= 0.0 or vertical_fov_rad <= 0.0:
		return 0.0
	var half_height := viewport_height_px * 0.5
	return tan(spread_rad) * half_height / tan(vertical_fov_rad * 0.5)
