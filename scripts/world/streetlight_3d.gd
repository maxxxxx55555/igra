extends Node3D

const _HARDWARE := preload("res://scripts/world/lamp_hardware.gd")

@export var district_id: StringName = &"test_zone"
@export var force_on: bool = false
@export var lamp_flicker: bool = true
## FINAL PERFECTION P3: street_props.gd batches every lamp's Pole+Lamp mesh
## into two shared MultiMeshInstance3D (their material/transform never
## change per-instance - only the lights below do), so a district's own
## Pole/Lamp copies would just double-draw the same geometry. Lights and
## LightArea stay per-instance (can't be MultiMesh'd; they weren't the
## draw-call problem - see docs/SESSION_REPORT_FINAL_PERFECTION.md).
@export var mesh_visible: bool = true

var _on: bool = false
## The flicker clock, negative until the first lit frame: it then starts at a phase of the lamp's own place, so the lamps of a street do not dip together (they all started at 0: the whole street pulsed by
## 15 % and fell to a fifth of its light six times a second, and two frames of one view differed by up to 20 %, the "drift" of Session 28).
var _t: float = -1.0
## PARTIAL (stage 1) lamps run weaker; _process multiplies this into the
## flicker so a stage-1 lamp reads dimmer than a STREETS lamp, not just
## on/off. 1.0 at STREETS/FULL.
var _energy_scale: float = 1.0
## VISUAL_PASS.md W10/§3: per-district light punch (fog districts read
## brighter through the murk, hospital/police stay dim per canon). 1.0 if
## the district has no entry or the config resource is missing.
var _light_energy_mult: float = 1.0
## QA_SWARM_FINDINGS.md P1 (accessibility): every lit lamp in every district
## dipped into a sharp ~6Hz flicker with no accessibility gate at all - only
## a per-instance scene export existed, nothing player-facing. Cached once
## like _light_energy_mult above (district scenes rebuild on re-entry per
## world_runtime.gd, so toggling the setting takes effect next visit).
var _reduce_flash: bool = false

func _ready() -> void:
	add_to_group("streetlights")
	_reduce_flash = SettingsManager != null and bool(SettingsManager.get_setting("reduce_flash", false))
	var pole := get_node_or_null("Pole")
	var lamp := get_node_or_null("Lamp")
	if pole is MeshInstance3D:
		(pole as MeshInstance3D).mesh = _HARDWARE.pole_mesh()
		(pole as MeshInstance3D).material_override = _HARDWARE.material()
	if pole: pole.visible = mesh_visible
	if lamp: lamp.visible = mesh_visible
	if lamp is MeshInstance3D and mesh_visible: lamp.material_override = preload("res://scripts/world/lamp_head.gd").shared()  # W4: a head that stands alone flickers like the batched ones
	if ResourceLoader.exists("res://assets/config/visual_quality.tres"):
		var vq := load("res://assets/config/visual_quality.tres")
		var district_lights: Dictionary = vq.get_meta("district_lights", {}) if vq else {}
		var entry: Dictionary = district_lights.get(String(district_id), {})
		_light_energy_mult = float(entry.get("energy_mult", 1.0))
	EventBus.district_stage_changed.connect(_on_stage_changed)
	var dm := get_node_or_null("/root/DistrictManager")
	var st: int = dm.get_stage(district_id) if dm else -1
	_apply_stage(st)

func _process(delta: float) -> void:
	if not _on or not lamp_flicker:
		return
	if _t < 0.0:
		_t = float(absi(hash(Vector2i(roundi(global_position.x), roundi(global_position.z)))) % 628) / 100.0
	_t += delta
	var spot: SpotLight3D = $SpotLight
	var glow: OmniLight3D = $Glow
	var base: float = (0.85 + sin(_t * 12.0) * 0.15) * _energy_scale
	# v10 N065: a dip 2.4 times a second (it was 5.9: a strobe, and GAMEFEEL_SPEC bans more than three a second)
	if not _reduce_flash and sin(_t * 15.0) > 0.95:
		base = 0.2 * _energy_scale
	spot.light_energy = base * 2.0 * _light_energy_mult
	glow.light_energy = base * 1.0 * _light_energy_mult

func _on_stage_changed(id: StringName, stage: int) -> void:
	if id == district_id:
		_apply_stage(stage)

## GDD §4.2: PARTIAL = "часть фонарей" — a deterministic ~40% subset of a
## district's lamps lights at stage 1, dimmer and with a tighter pool than
## STREETS, so PARTIAL is visually distinct from both DARK (all off) and
## STREETS (all on).
func _apply_stage(stage: int) -> void:
	var partial_lit: bool = stage == 1 and _in_partial_set()
	_on = stage >= 2 or partial_lit or force_on
	_energy_scale = 0.55 if (partial_lit and stage < 2 and not force_on) else 1.0
	_update_light(stage)

func _in_partial_set() -> bool:
	var cell := Vector2i(int(round(global_position.x)), int(round(global_position.z)))
	return abs(hash(cell)) % 5 < 2

func _update_light(stage: int = -1) -> void:
	var spot: SpotLight3D = $SpotLight
	var glow: OmniLight3D = $Glow
	spot.visible = _on
	glow.visible = _on
	if _on and stage >= 3:
		spot.light_energy = 3.5 * _light_energy_mult
		spot.spot_attenuation = 1.0
		glow.light_energy = 1.5 * _light_energy_mult
		glow.omni_range = 8.0
	elif _on and stage >= 2:
		spot.light_energy = 2.5 * _light_energy_mult
		spot.spot_attenuation = 1.5
		glow.light_energy = 1.0 * _light_energy_mult
		glow.omni_range = 6.0
	elif _on:
		# PARTIAL — tighter, weaker pool
		spot.light_energy = 1.4 * _light_energy_mult
		spot.spot_attenuation = 2.0
		glow.light_energy = 0.5 * _light_energy_mult
		glow.omni_range = 4.0
	else:
		spot.light_energy = 0.0  # a lamp that is out gives no light: the LightLimiter leaves such a light off, whatever slot it would hold
		glow.light_energy = 0.0
