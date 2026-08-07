extends Control
## HUDPanel: dark translucent rectangle with amber border, optional label.
class_name HUDPanel

@export var w: float = 200.0
@export var h: float = 60.0
@export var border: float = 2.0
@export var radius: float = 4.0
@export var fill_color: Color = Color(0.04, 0.05, 0.08, 0.78)
@export var border_color: Color = Color(1.00, 0.70, 0.28, 0.95)
@export var label: String = ""
@export var label_color: Color = Color(0.96, 0.95, 0.90)
@export var font_size: int = 14

func _ready() -> void:
	custom_minimum_size = Vector2(w, h)
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(w, h))
	draw_rect(Rect2(Vector2(2, 3), Vector2(w, h)), Color(0, 0, 0, 0.45), true)
	draw_rect(r, fill_color, true)
	draw_rect(r, border_color, false, border)
	if label != "":
		var f := ThemeDB.fallback_font
		if f != null:
			var sz := font_size
			var tx := Vector2(10, 8 + sz)
			draw_string(f, tx, label, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, label_color)