extends Node3D

@export var district_id: StringName = &"test_zone"
@export var force_on: bool = false
@export var lamp_flicker: bool = true

var _on: bool = false
var _t: float = 0.0
## Секунды до конца аварийного отключения. RandomEvents шлёт
## district_blackout, но слушал его только 2D-фонарь из старой версии —
## в 3D-мире событие ничего не гасило.
var _blackout: float = 0.0

const BLACKOUT_SECONDS: float = 15.0

func _ready() -> void:
	EventBus.district_stage_changed.connect(_on_stage_changed)
	EventBus.district_blackout.connect(_on_blackout)
	if force_on:
		_on = true
	var dm := get_node_or_null("/root/DistrictManager")
	var st := -1
	if dm:
		st = dm.get_stage(district_id)
		_on = st >= 2 or force_on
	_update_light(st)

func _process(delta: float) -> void:
	if _blackout > 0.0:
		_blackout -= delta
		if _blackout <= 0.0:
			_update_light()
		return
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

## Аварийное отключение района: гасим фонарь на BLACKOUT_SECONDS, после чего
## _process сам вернёт свет через _update_light().
func _on_blackout(id: StringName) -> void:
	if id != district_id or not _on:
		return
	_blackout = BLACKOUT_SECONDS
	var spot := get_node_or_null("SpotLight") as SpotLight3D
	var glow := get_node_or_null("Glow") as OmniLight3D
	if spot != null:
		spot.visible = false
	if glow != null:
		glow.visible = false
	_update_hum()

func _update_light(stage: int = -1) -> void:
	var spot: SpotLight3D = $SpotLight
	var glow: OmniLight3D = $Glow
	# Во время блэкаута свет остаётся выключенным, чем бы ни кончилась стадия.
	spot.visible = _on and _blackout <= 0.0
	glow.visible = _on and _blackout <= 0.0
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

## Гул лампы звучит только пока фонарь горит.
func _update_hum() -> void:
	var hum := get_node_or_null("Hum") as AudioStreamPlayer3D
	if hum == null:
		return
	var should_hum: bool = _on and _blackout <= 0.0
	if should_hum and not hum.playing:
		hum.play()
	elif not should_hum and hum.playing:
		hum.stop()