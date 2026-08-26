extends Node

var _env: Environment = null
var _target_fog: Color = Color.BLACK
var _target_sky: Color = Color.BLACK
var _target_ambient: Color = Color.BLACK
var _lerp_speed: float = 0.8

## BUGS_FOR_CLAUDE #4: docs/REPORT_AUDIO_DETAIL.md T2 delivered 40 per-district
## detail beds (30s seamless loops) documenting this script as the consumer,
## but nothing here ever loaded them. Layered under the main
## `<district>_dark.ogg` bed (owned by MusicManager) as a second, quieter
## accent loop; one random file per district switch, at DETAIL_BASE_DB plus
## that file's LUFS offset from the report (compensates files recorded
## quieter than the -18 LUFS ambience canon back toward it).
const DETAIL_BASE_DB: float = -20.0
const DETAIL_BEDS: Dictionary = {
	&"suburbs": {"suburbs_dog_bark": 2.8, "suburbs_porch_creak": 0.0, "suburbs_wind_leaves": 0.0},
	&"residential": {"residential_pipe_creak": 1.8, "residential_tv_murmur": 0.0, "residential_window_rattle": 3.6},
	&"park": {"park_leaves_skitter": 0.0, "park_branch_snap": 0.0, "park_bare_trees_wind": 0.0, "park_distant_city_hum": 0.0},
	&"school": {"school_bell_echo": 1.8, "school_locker_slam": 2.7, "school_chalk_scratch": 0.0, "school_desk_scrape": 0.0},
	&"hospital": {"hospital_monitor_beep": 4.6, "hospital_gurney_wheels": 0.0, "hospital_pa_mumble": 2.4, "hospital_elevator_distant": 0.0},
	&"gas_station": {"gas_station_sign_buzz": 0.0, "gas_station_pump_hum": 0.0, "gas_station_gravel_crunch": 0.0, "gas_station_car_pass": 2.2},
	&"police": {"police_radio_static": 4.9, "police_siren_tail": 0.0, "police_boots_concrete": 2.4},
	&"warehouses": {"warehouses_metal_creak": 0.0, "warehouses_chain_rattle": 2.1, "warehouses_forklift_distant": 0.0, "warehouses_cargo_impact": 0.0},
	&"industrial": {"industrial_machinery_drone": 4.0, "industrial_pipe_hiss": 0.0, "industrial_steam_vent": 0.0, "industrial_vent_rattle": 4.5},
	&"substation": {"substation_transformer_buzz": 0.0, "substation_arc_crackle": 5.8, "substation_cable_hum": 0.0},
	&"power_station": {"power_station_generator_thrum": 0.0, "power_station_hv_whine": 0.0, "power_station_cooling_fan": 0.0, "power_station_breaker_clunk": 3.0},
}
var _detail_player: AudioStreamPlayer
var _detail_district: StringName = &""

func _ready() -> void:
	_detail_player = AudioStreamPlayer.new()
	_detail_player.name = "DistrictDetailBed"
	_detail_player.bus = "Ambient" if AudioServer.get_bus_index("Ambient") >= 0 else "Master"
	add_child(_detail_player)
	await get_tree().process_frame
	var we = get_tree().root.get_node_or_null("Main3D/WorldEnvironment")
	if we != null and we.environment != null:
		_env = we.environment
		_target_fog = _env.fog_light_color
		_target_sky = _env.background_color
		_target_ambient = _env.ambient_light_color
	if EventBus.has_signal("district_entered"):
		EventBus.district_entered.connect(_on_district)

func _on_district(id: StringName) -> void:
	_update_detail_bed(id)
	if _env == null:
		return
	if not DistrictThemes.has(id):
		return
	var t: Dictionary = DistrictThemes.get_theme(id)
	_target_fog = t.get("fog", Color.BLACK)
	_target_sky = t.get("sky", Color.BLACK)
	_target_ambient = t.get("ambient", Color.BLACK)

func _update_detail_bed(id: StringName) -> void:
	if id == _detail_district:
		return
	_detail_district = id
	var beds: Dictionary = DETAIL_BEDS.get(id, {})
	if beds.is_empty():
		_detail_player.stop()
		return
	var files: Array = beds.keys()
	var file: String = files[randi() % files.size()]
	var path: String = "res://assets/audio/ambience/district_details/%s.ogg" % file
	if not ResourceLoader.exists(path):
		_detail_player.stop()
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_detail_player.stream = stream
	_detail_player.volume_db = DETAIL_BASE_DB + float(beds[file])
	_detail_player.play()

func _process(delta: float) -> void:
	if _env == null:
		return
	var k: float = clamp(delta * _lerp_speed, 0.0, 1.0)
	_env.fog_light_color = _env.fog_light_color.lerp(_target_fog, k)
	_env.background_color = _env.background_color.lerp(_target_sky, k)
	_env.ambient_light_color = _env.ambient_light_color.lerp(_target_ambient, k)
