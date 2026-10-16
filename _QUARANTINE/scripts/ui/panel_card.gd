class_name PanelCard
extends PanelContainer

@export var card_title: String = ""
@export var show_close: bool = true


func _ready() -> void:
	_apply_style()



func _apply_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#141b24")
	sb.border_color = Color("#2a3340")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	sb.shadow_color = Color("#0c1016", 0.3)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(2, 2)
	add_theme_stylebox_override("panel", sb)
