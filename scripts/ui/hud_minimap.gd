extends Control

const RADIUS := 70.0
const CENTER := Vector2(80, 80)

var _player: Vector3 = Vector3.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)
	queue_redraw()

func set_player(pos: Vector3, yaw_deg: float) -> void:
	_player = pos
	queue_redraw()

func set_flash(dir_world: Vector3, on: bool) -> void:
	queue_redraw()

func update_districts(arr: Array) -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(CENTER, RADIUS + 4.0, Color(0.04, 0.05, 0.08, 0.78))
	draw_arc(CENTER, RADIUS + 4.0, 0.0, TAU, 48, Color(1.0, 0.7, 0.28, 0.95), 2.0)
	var pp := CENTER + Vector2(_player.x, _player.z) * 0.5
	draw_circle(pp, 3.0, Color(1.0, 0.85, 0.4))