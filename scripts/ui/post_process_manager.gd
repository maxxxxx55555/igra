

extends CanvasLayer

@onready 

var color_rect: ColorRect = $ColorRect

@onready 

var shader_material: ShaderMaterial = color_rect.material
var _damage_flash: float = 0.0
func _ready() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if _damage_flash > 0.0:
		_damage_flash = max(0.0, _damage_flash - delta * 2.0)
	shader_material.set_shader_parameter("damage_flash", _damage_flash)

func trigger_damage_flash() -> void:
	_damage_flash = 1.0
	shader_material.set_shader_parameter("damage_flash", _damage_flash)

func set_bloom(intensity: float) -> void:
	shader_material.set_shader_parameter("bloom_intensity", intensity)

func set_vignette(intensity: float) -> void:
	shader_material.set_shader_parameter("vignette_intensity", intensity)