# SPDX-License-Identifier: GPL-2.0-or-later
class_name WeaponBase
extends Node3D

signal fired()
signal reload_started()
signal reloaded()
signal ammo_changed(magazine_ammo: int, reserve_ammo: int)

@export_group("Firing")
@export var fire_rate_rpm: float = 700.0
@export var magazine_size: int = 30
@export var reserve_ammo_max: int = 90
@export var reload_time: float = 2.2
@export var auto_reload_on_empty: bool = true

@export_group("Spread")
@export var hipfire_spread_deg: float = 3.0
@export var ads_spread_deg: float = 0.4
## Extra hipfire spread, in degrees, added at the player's full move speed.
## Scales linearly with horizontal speed below that, and fades out as the
## weapon blends into ADS along with the rest of the hipfire spread.
@export var move_spread_deg: float = 2.0

@export_group("Damage")
@export var damage_near: float = 30.0
@export var damage_far: float = 15.0
@export var falloff_start: float = 10.0
@export var falloff_end: float = 40.0
@export var headshot_multiplier: float = 2.0
@export var max_range: float = 200.0

@export_group("Recoil")
@export var recoil_vertical_per_shot_deg: float = 0.6
@export var recoil_vertical_max_deg: float = 4.0
@export var recoil_horizontal_max_deg: float = 0.3
@export var recoil_recovery_deg_per_sec: float = 6.0
@export var recoil_seed: int = 12345

@export_group("ADS")
@export var ads_fov_degrees: float = 55.0
@export var ads_speed_scale: float = 0.6
@export var ads_transition_time: float = 0.18

@export_group("Sprint-out")
@export var sprint_out_delay: float = 0.25

@export_group("Reload")
## No reload viewmodel yet — as a placeholder, the whole weapon just slides
## off screen by this local offset for the duration of the reload and slides
## back once it's done. Replace with a real reload animation later.
@export var reload_offscreen_offset: Vector3 = Vector3(0.0, -0.6, 0.15)
@export var reload_move_speed: float = 3.0

@onready var _muzzle: Node3D = $Muzzle

var _player: PMove
var _camera: Camera3D
var _camera_look: Node
var _default_fov: float = 75.0

var _magazine_ammo: int
var _reserve_ammo: int
var _is_reloading: bool = false
var _fire_cooldown: float = 0.0
var _sprint_release_timer: float = 0.0
var _ads_active: bool = false
var _ads_blend: float = 0.0 # 0 = hip, 1 = fully ADS

var _recoil: Recoil
var _shot_rng := RandomNumberGenerator.new()
var _reload_timer: Timer
var _rest_position: Vector3


func _ready() -> void:
	_magazine_ammo = magazine_size
	_reserve_ammo = reserve_ammo_max
	_recoil = Recoil.new(recoil_vertical_per_shot_deg, recoil_vertical_max_deg, recoil_horizontal_max_deg, recoil_recovery_deg_per_sec, recoil_seed)
	_shot_rng.seed = recoil_seed + 1 # distinct stream from recoil's own RNG
	_rest_position = position

	_player = _find_ancestor(PMove)
	_camera = get_parent() as Camera3D
	if _camera == null:
		_camera = _find_ancestor(Camera3D)
	if _camera:
		_default_fov = _camera.fov
		_camera_look = _camera.get_parent()

	_reload_timer = Timer.new()
	_reload_timer.one_shot = true
	_reload_timer.timeout.connect(_finish_reload)
	add_child(_reload_timer)

	ammo_changed.emit(_magazine_ammo, _reserve_ammo)


func _physics_process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_update_sprint_out_timer(delta)
	_update_ads(delta)
	_update_reload_offset(delta)

	if Input.is_action_just_pressed("reload"):
		reload()

	if Input.is_action_pressed("fire") and _can_fire():
		fire()

	if _camera_look and _camera_look.has_method("apply_recoil_offset"):
		_camera_look.apply_recoil_offset(_recoil.process(delta))


func _can_fire() -> bool:
	if _is_reloading or _fire_cooldown > 0.0:
		return false
	if _sprint_release_timer > 0.0:
		return false
	if _magazine_ammo <= 0:
		if auto_reload_on_empty and not _is_reloading:
			reload()
		return false
	return true


func fire() -> void:
	_magazine_ammo -= 1
	_fire_cooldown = 60.0 / fire_rate_rpm
	_recoil.fire()
	fired.emit()
	ammo_changed.emit(_magazine_ammo, _reserve_ammo)

	var origin := _camera.global_position
	var forward := -_camera.global_transform.basis.z
	var direction := Hitscan.spread_direction(forward, get_current_spread_rad(), _shot_rng)
	var end_point := origin + direction * max_range

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, end_point)
	query.exclude = [_player.get_rid()] if _player else []
	var hit := space_state.intersect_ray(query)

	var muzzle_origin := _muzzle.global_position
	WeaponFX.spawn_muzzle_flash(_muzzle)

	if hit.is_empty():
		WeaponFX.spawn_tracer(get_tree().current_scene, muzzle_origin, end_point)
		return

	WeaponFX.spawn_tracer(get_tree().current_scene, muzzle_origin, hit.position)
	WeaponFX.spawn_impact_decal(get_tree().current_scene, hit.position, hit.normal)

	var collider: Object = hit.collider
	if collider is HitZone:
		var distance := origin.distance_to(hit.position)
		var damage := Hitscan.damage_at_distance(distance, damage_near, damage_far, falloff_start, falloff_end)
		damage = Hitscan.apply_headshot_multiplier(damage, collider.is_head, headshot_multiplier)
		collider.get_target_health().apply_damage(damage, collider.is_head, hit.position)


## Current spread cone half-angle, in radians: hipfire spread widened by the
## player's current movement, then blended toward ADS spread by `_ads_blend`.
## Used both for the actual shot and by the HUD crosshair to show it.
func get_current_spread_rad() -> float:
	var hip_spread_deg := hipfire_spread_deg + move_spread_deg * _movement_spread_fraction()
	return lerpf(deg_to_rad(hip_spread_deg), deg_to_rad(ads_spread_deg), _ads_blend)


func _movement_spread_fraction() -> float:
	if _player == null:
		return 0.0
	var horizontal_speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	return Hitscan.movement_spread_fraction(horizontal_speed, _player.move_speed * Units.QU_TO_M)


## 0 = fully hipfire, 1 = fully aimed down sights. The HUD crosshair uses this
## to switch from the spread reticle to the ADS placeholder dot.
func get_ads_blend() -> float:
	return _ads_blend


func reload() -> void:
	if _is_reloading or _magazine_ammo >= magazine_size or _reserve_ammo <= 0:
		return
	_is_reloading = true
	reload_started.emit()
	_reload_timer.start(reload_time)


func _finish_reload() -> void:
	var needed := magazine_size - _magazine_ammo
	var taken := mini(needed, _reserve_ammo)
	_magazine_ammo += taken
	_reserve_ammo -= taken
	_is_reloading = false
	reloaded.emit()
	ammo_changed.emit(_magazine_ammo, _reserve_ammo)


func _update_sprint_out_timer(delta: float) -> void:
	if _player and _player.is_sprinting():
		_sprint_release_timer = sprint_out_delay
	else:
		_sprint_release_timer = maxf(_sprint_release_timer - delta, 0.0)


func _update_ads(delta: float) -> void:
	_ads_active = Input.is_action_pressed("ads") and _sprint_release_timer <= 0.0

	var target_blend := 1.0 if _ads_active else 0.0
	var blend_speed := 1.0 / maxf(ads_transition_time, 0.001)
	_ads_blend = move_toward(_ads_blend, target_blend, blend_speed * delta)

	if _camera:
		_camera.fov = lerpf(_default_fov, ads_fov_degrees, _ads_blend)
	if _player:
		_player.speed_modifier = lerpf(1.0, ads_speed_scale, _ads_blend)


func _update_reload_offset(delta: float) -> void:
	var target := _rest_position + reload_offscreen_offset if _is_reloading else _rest_position
	position = position.move_toward(target, reload_move_speed * delta)


func _find_ancestor(of_type) -> Node:
	var node := get_parent()
	while node:
		if is_instance_of(node, of_type):
			return node
		node = node.get_parent()
	return null
