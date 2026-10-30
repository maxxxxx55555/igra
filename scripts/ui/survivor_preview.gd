extends Control
## The shipped survivor render is the equipment-column portrait; real equipment rows sit beside it.

const PORTRAIT: Texture2D = preload("res://assets/textures/renders_v2/player_512x768.png")
const BACKING := Color(0.025, 0.035, 0.035, 0.9)
const EDGE := Color(0.396, 0.325, 0.196, 0.8)

func _ready() -> void:
	custom_minimum_size = Vector2(176, 224)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKING, true)
	if PORTRAIT == null:
		return
	var height := minf(size.y, 224.0)
	var width := height * float(PORTRAIT.get_width()) / float(PORTRAIT.get_height())
	var dst := Rect2(Vector2((size.x - width) * 0.5, 0.0), Vector2(width, height))
	draw_texture_rect(PORTRAIT, dst, false)
	draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), EDGE, false, 1.0)
