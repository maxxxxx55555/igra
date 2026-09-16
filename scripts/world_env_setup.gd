extends Node

# Ночной город: темно, но геометрия обязана читаться.
#
# Раньше здесь стояли ambient 0.01 и moon 0.03 — «абсолютная тьма вне источников
# света». На практике это давало почти чёрный кадр: ни домов, ни дороги, ни
# силуэта монстра, играть было невозможно. Держим низкую, но ненулевую засветку,
# а разницу между стадиями восстановления города показываем контрастом.

@export var ambient_energy_default: float = 0.12
@export var moon_energy_default: float = 0.09
@export var moon_rotation_deg: Vector3 = Vector3(-55.0, -35.0, 0.0)
@export var fog_density: float = 0.012
@export var glow_intensity: float = 0.5

# Стадия района: DARK — только фонарик и луна, FULL — восстановленный свет.
const AMBIENT_DARK: float = 0.12
const AMBIENT_LIT: float = 0.20
const AMBIENT_FULL: float = 0.30
const AMBIENT_COLOR_DARK: Color = Color(0.075, 0.094, 0.137)
const AMBIENT_COLOR_LIT: Color = Color(0.098, 0.125, 0.184)
const AMBIENT_COLOR_FULL: Color = Color(0.125, 0.153, 0.212)
const MOON_DARK: float = 0.09
const MOON_LIT: float = 0.14
const MOON_FULL: float = 0.20
# Свечение вокруг игрока: в тёмном районе его нет, с восстановлением растёт.
const GLOW_DARK: float = 0.0
const GLOW_LIT: float = 0.35
const GLOW_FULL: float = 0.7

var _env: Environment = null
var _moon: DirectionalLight3D = null
var _player_glow: OmniLight3D = null
var _override_frames: int = 5
var _postfx: Dictionary = {}
var _postfx_overlay: Node = null

func _ready() -> void:
	var root = get_tree().current_scene
	if root == null: root = get_tree().root

	var we: WorldEnvironment = _find_we(root)
	if we == null:
		we = WorldEnvironment.new()
		we.name = "WorldEnvironment"
		we.environment = Environment.new()
		root.add_child(we)
		we.owner = root
	if we.environment == null:
		we.environment = Environment.new()
	_env = we.environment

	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = AMBIENT_COLOR_DARK
	_env.ambient_light_energy = ambient_energy_default
	_env.glow_enabled = true
	_env.glow_intensity = glow_intensity
	_env.glow_strength = 1.0
	_env.glow_bloom = 0.1
	_env.ssao_enabled = false
	_env.ssil_enabled = false
	_env.volumetric_fog_enabled = false
	_env.fog_enabled = true
	_env.fog_density = fog_density
	_env.fog_light_color = Color(0.102, 0.129, 0.2)  # #1a2133
	# fog_light_energy = 0 гасил цвет тумана полностью — туман переставал быть
	# видимым как дымка и работал только на затемнение дали.
	_env.fog_light_energy = 0.6

	var moon: DirectionalLight3D = _find_moon(root)
	if moon == null:
		moon = DirectionalLight3D.new()
		moon.name = "Moon"
		root.add_child(moon)
		moon.owner = root
	_moon = moon
	_moon.light_energy = moon_energy_default
	_moon.light_color = Color(0.439, 0.502, 0.753)  # #7080C0
	_moon.rotation_degrees = moon_rotation_deg
	_moon.shadow_enabled = true

	# Flashlight defaults (set on player scene)
	# - spot_range = 8.0, spot_angle = 45, light_energy = 1.0, color = #c9a24a

	_apply_graphics_tier(int(SettingsManager.get_setting("graphics_tier", 2)))
	EventBus.settings_changed.connect(_on_settings_changed)
	EventBus.district_stage_changed.connect(_on_district_stage_changed)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.district_entered.connect(_apply_lut)
	EventBus.district_entered.connect(_apply_postfx)
	_postfx = _load_postfx_presets()

	_player_glow = _find_player_glow()
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null:
		_apply_lut(dm.current_district)
		_apply_postfx(dm.current_district)

func _process(delta: float) -> void:
	if _override_frames > 0:
		_override_frames -= 1
		var dm := get_node_or_null("/root/DistrictManager")
		if dm:
			apply_for_stage(dm.get_stage(dm.current_district))

func apply_for_stage(stage: int) -> void:
	if _env == null:
		return
	var ambient_energy: float
	var ambient_color: Color
	var moon_energy: float
	var glow_energy: float
	match stage:
		0, 1:
			ambient_energy = AMBIENT_DARK
			ambient_color = AMBIENT_COLOR_DARK
			moon_energy = MOON_DARK
			glow_energy = GLOW_DARK
		2:
			ambient_energy = AMBIENT_LIT
			ambient_color = AMBIENT_COLOR_LIT
			moon_energy = MOON_LIT
			glow_energy = GLOW_LIT
		_:
			ambient_energy = AMBIENT_FULL
			ambient_color = AMBIENT_COLOR_FULL
			moon_energy = MOON_FULL
			glow_energy = GLOW_FULL
	_env.ambient_light_energy = ambient_energy
	_env.ambient_light_color = ambient_color
	if _moon:
		_moon.light_energy = moon_energy
	if _player_glow:
		_player_glow.light_energy = glow_energy



## Static audit 2026-09-08: this owns the ONE global WorldEnvironment/Moon/
## PlayerGlow for the whole game, but reacted to every district's stage
## change, not just wherever the player actually is - restoring a district
## the player wasn't standing in overwrote the correct lighting underfoot.
## Same guard district_grading.gd/music_manager.gd already use.
## RELEASE CONVERGENCE STEP 4: a headless_suite language-switch scenario
## (mid scene-reload) intermittently fired district_stage_changed while
## this node was detached from the active tree - an absolute-path
## get_node_or_null("/root/...") requires being inside the active tree
## and threw instead of just returning null. Guard the same way
## hud_3d.gd's _on_weight_changed now does: no-op when not attached,
## nothing meaningful to update on a detached node anyway.
func _on_district_stage_changed(_id: StringName, stage: int) -> void:
	if not is_inside_tree():
		return
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null and _id != dm.current_district:
		return
	apply_for_stage(stage)

## VISUAL_PASS W1: graphics_tier (SettingsManager, 0..3) selects a preset
## dict from visual_quality.tres (tier 3/Ultra reuses "high", per its own
## metadata/graphics_tier_map which only defines low/medium/high). Runs
## before the district stage/LUT/postfx application below, which refine
## rather than replace this base — matches the wiring spec's stated order.
func _apply_graphics_tier(tier: int) -> void:
	if _env == null:
		return
	var vq := load("res://assets/config/visual_quality.tres")
	if vq == null:
		return
	var names := ["low", "medium", "high", "high"]
	var name: String = names[clampi(tier, 0, names.size() - 1)]
	var p: Dictionary = vq.get_meta(name, {})
	if p.is_empty():
		return
	_env.tonemap_mode = int(p.get("tonemap_mode", Environment.TONE_MAPPER_ACES))
	_env.tonemap_exposure = float(p.get("tonemap_exposure", 1.0))
	_env.glow_enabled = bool(p.get("glow_enabled", true))
	_env.glow_bloom = float(p.get("glow_bloom", _env.glow_bloom))
	_env.glow_intensity = float(p.get("glow_intensity", _env.glow_intensity))
	_env.glow_strength = float(p.get("glow_strength", _env.glow_strength))
	_env.glow_hdr_threshold = float(p.get("glow_hdr_threshold", _env.glow_hdr_threshold))
	_env.fog_density = float(p.get("fog_density", _env.fog_density))
	_env.fog_sky_affect = float(p.get("fog_sky_affect", _env.fog_sky_affect))
	_env.ssao_enabled = bool(p.get("ssao_enabled", false))
	_env.ssil_enabled = bool(p.get("ssil_enabled", false))
	_env.volumetric_fog_enabled = bool(p.get("volumetric_fog_enabled", false))
	_env.adjustment_enabled = true
	_env.adjustment_contrast = float(p.get("contrast", 1.0))
	_env.adjustment_saturation = float(p.get("saturation", 1.0))

func _on_settings_changed(key: String, value: Variant) -> void:
	if key != "graphics_tier":
		return
	_apply_graphics_tier(int(value))

func _on_weather_changed(_weather: int, _name: String, _fog: float, _rain: float) -> void:
	if not is_inside_tree():
		return
	var dm := get_node_or_null("/root/DistrictManager")
	if dm:
		apply_for_stage(dm.get_stage(dm.current_district))

## Игрок ищется по группе: узел зовётся то "Player", то "PlayerFPS" в зависимости
## от того, как игрок попал в сцену, и поиск по имени молча возвращал null.
func _find_player_glow() -> OmniLight3D:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	return player.find_child("PlayerGlow", true, false) as OmniLight3D

## 2026-09-12 audio/visual pass: per-district color-correction LUT
## (assets/textures/luts/README.md). This is the ONE live WorldEnvironment
## (see class comment above) — district_grading.gd also grades per-district
## fog/sky/ambient, but its `world_environment_path` export is never set by
## its only instantiator (world_bootstrap.gd's dynamic "Grading" node), so
## that whole branch is dead code today; not touched here (see
## docs/KNOWN_ISSUES.md "district_grading.gd Environment branch is dead").
## Filename convention IS the district->LUT mapping, no table needed.
## Missing file (a district with no LUT yet) leaves grading off — safe
## identity fallback, never an error.
func _apply_lut(district_id: StringName) -> void:
	if _env == null:
		return
	var lut_path := "res://assets/textures/luts/lut_%s.png" % String(district_id)
	if ResourceLoader.exists(lut_path):
		_env.adjustment_enabled = true
		_env.adjustment_color_correction = load(lut_path)
	else:
		_env.adjustment_enabled = false

## 2026-09-13 FINALE merge: cinematic post-fx presets per district
## (assets/textures/postfx/README.md). Bloom lands on this WorldEnvironment
## (already the one live Environment — see _apply_lut's comment above);
## vignette/chroma/grain land on the PostProcessOverlay CanvasLayer, found
## lazily the same way hud_3d.gd finds its VignetteOverlay child. A missing
## file or a district with no preset row leaves everything at its already-
## shipped default — safe identity fallback, same policy as _apply_lut.
func _load_postfx_presets() -> Dictionary:
	var path := "res://assets/textures/postfx/presets.json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary and parsed.get("districts") is Dictionary:
		return parsed["districts"]
	return {}

func _apply_postfx(district_id: StringName) -> void:
	if _env == null:
		return
	var preset: Dictionary = _postfx.get(String(district_id), {})
	var bloom: Dictionary = preset.get("bloom", {})
	_env.glow_enabled = bool(bloom.get("enabled", true))
	_env.glow_bloom = float(bloom.get("bloom", 0.1))
	_env.glow_intensity = float(bloom.get("intensity", glow_intensity))
	_env.glow_strength = float(bloom.get("strength", 1.0))
	_env.glow_hdr_threshold = float(bloom.get("hdr_threshold", 1.0))

	var overlay := _find_postfx_overlay()
	if overlay == null:
		return
	var vignette: Dictionary = preset.get("vignette", {})
	if overlay.has_method("set_vignette_strength"):
		overlay.set_vignette_strength(float(vignette.get("strength", 0.55)))
	var chroma: Dictionary = preset.get("chroma", {})
	if overlay.has_method("set_chroma_amount"):
		overlay.set_chroma_amount(float(chroma.get("amount_px_1080p", 0.0)))
	var grain: Dictionary = preset.get("grain", {})
	if overlay.has_method("set_grain_intensity"):
		overlay.set_grain_intensity(float(grain.get("intensity", 0.1)))

func _find_postfx_overlay() -> Node:
	if is_instance_valid(_postfx_overlay):
		return _postfx_overlay
	_postfx_overlay = get_tree().root.find_child("PostProcessOverlay", true, false)
	return _postfx_overlay

func _find_we(n: Node) -> WorldEnvironment:
	if n == null: return null
	if n is WorldEnvironment: return n
	for c in n.get_children():
		var r = _find_we(c)
		if r != null: return r
	return null

func _find_moon(n: Node) -> DirectionalLight3D:
	return _find_moon_r(n, null)

func _find_moon_r(n: Node, fallback: DirectionalLight3D) -> DirectionalLight3D:
	if n == null: return fallback
	if n is DirectionalLight3D:
		if "moon" in n.name.to_lower(): return n
		if fallback == null: fallback = n
	for c in n.get_children():
		var r = _find_moon_r(c, fallback)
		if r != null and "moon" in r.name.to_lower(): return r
		if r != null: fallback = r
	return fallback