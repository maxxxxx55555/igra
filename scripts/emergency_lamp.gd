class_name EmergencyLamp
extends Node3D

@export var lamp_id: String = "lamp_001"
@export var blink_interval: float = 1.5

var is_active: bool = true
var _timer: float = 0.0

@onready var light: OmniLight3D = get_node_or_null("OmniLight3D")


func _ready() -> void:
	add_to_group("emergency_lamps")
	if light:
		light.light_color = Color("#b4452f")
		light.light_energy = 0.8
		light.omni_range = 4.0
		light.shadow_enabled = false



func _process(delta: float) -> void:
	if not is_active or light == null:
		return
	_timer += delta
	if _timer >= blink_interval:
		_timer = 0.0
		light.visible = not light.visible
