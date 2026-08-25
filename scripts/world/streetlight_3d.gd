extends Node3D

@export var district_id: StringName = &"test_zone"
@export var force_on: bool = false
@export var lamp_flicker: bool = true
## FINAL PERFECTION P3: street_props.gd batches every lamp's Pole+Lamp mesh
## into two shared MultiMeshInstance3D (their material/transform never
## change per-instance - only the lights below do), so a district's own
## Pole/Lamp copies would just double-draw the same geometry. Lights, Hum
## and LightArea stay per-instance (can't be MultiMesh'd; they weren't the
## draw-call problem - see docs/SESSION_REPORT_FINAL_PERFECTION.md).
@export var mesh_visible: bool = true

var _on: bool = false
var _t: float = 0.0

func _ready() -> void:
	if not mesh_visible:
		var pole := get_node_or_null("Pole")
		var lamp := get_node_or_null("Lamp")
		if pole: pole.visible = false
		if lamp: lamp.visible = false
	EventBus.district_stage_changed.connect(_on_stage_changed)
	if force_on:
		_on = true
	var dm := get_node_or_null("/root/DistrictManager")
	var st := -1
	if dm:
		st = dm.get_stage(district_id)
		_on = st >= 2 or force_on
	_update_light(st)

func _process(delta: float) -> void:
	if not _on or not lamp_flicker:
		return
	_t += delta
	var spot: SpotLight3D = $SpotLight
	var glow: OmniLight3D = $Glow
	var base: float = 0.85 + sin(_t * 12.0) * 0.15
	if sin(_t * 37.0) > 0.95:
		base = 0.2
	spot.light_energy = base * 2.0
	glow.light_energy = base * 1.0

func _on_stage_changed(id: StringName, stage: int) -> void:
	if id == district_id:
		_on = stage >= 2
		_update_light(stage)

func _update_light(stage: int = -1) -> void:
	var spot: SpotLight3D = $SpotLight
	var glow: OmniLight3D = $Glow
	spot.visible = _on
	glow.visible = _on
	_update_hum()
	if _on and stage >= 3:
		spot.light_energy = 3.5
		spot.spot_attenuation = 1.0
		glow.light_energy = 1.5
		glow.omni_range = 8.0
	elif _on:
		spot.light_energy = 2.5
		spot.spot_attenuation = 1.5
		glow.light_energy = 1.0
		glow.omni_range = 6.0

## P4 (CONTENT UX wave): gул лампы теперь идёт через общий пул на
## StreetlightHumPool (max 8 голосов, ближайшие к игроку горящие фонари) -
## раньше каждый горящий столб держал свой AudioStreamPlayer3D, до 24
## одновременных 3D-потоков на район, большинство неслышны за max_distance.
func _update_hum() -> void:
	if _on:
		StreetlightHumPool.register(self)
	else:
		StreetlightHumPool.unregister(self)