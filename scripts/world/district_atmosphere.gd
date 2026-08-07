extends Node

var _env: Environment = null
var _target_fog: Color = Color.BLACK
var _target_sky: Color = Color.BLACK
var _target_ambient: Color = Color.BLACK
var _lerp_speed: float = 0.8

func _ready() -> void:
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
	if _env == null:
		return
	if not DistrictThemes.has(id):
		return
	var t: Dictionary = DistrictThemes.get_theme(id)
	_target_fog = t.get("fog", Color.BLACK)
	_target_sky = t.get("sky", Color.BLACK)
	_target_ambient = t.get("ambient", Color.BLACK)

func _process(delta: float) -> void:
	if _env == null:
		return
	var k: float = clamp(delta * _lerp_speed, 0.0, 1.0)
	_env.fog_light_color = _env.fog_light_color.lerp(_target_fog, k)
	_env.background_color = _env.background_color.lerp(_target_sky, k)
	_env.ambient_light_color = _env.ambient_light_color.lerp(_target_ambient, k)
