extends CanvasLayer

## 3.15 Спека: индикатор направления урона.
## В HUD показывает короткую вспышку по кромке экрана в точке, откуда пришёл урон.
## Использует Vignette (красное затемнение) + radial-pointer (капелюшная метка).

@onready var vignette: ColorRect = $Vignette

## Максимальная длительность затухания (секунды).
const _FADE_TIME: float = 0.55
## Размер метки (px).
const _POINTER_SIZE: float = 26.0

var _pointer: TextureRect = null

## Was a flat ColorRect.color:a tween; now driven by the art pass's
## damage_vignette.gdshader (ember tint + 60bpm heartbeat pulse) via its
## `strength` uniform instead — same trigger points, better visual.
var _vignette_mat: ShaderMaterial

func _ready() -> void:
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = load("res://assets/shaders/damage_vignette.gdshader")
	vignette.material = _vignette_mat
	EventBus.player_damaged.connect(_on_damaged)
	if EventBus.has_signal(&"player_damage_direction"):
		EventBus.player_damage_direction.connect(_on_damage_direction)
		_setup_pointer()

## Создаю узел указателя — капелюшная рамка в центре экрана.
func _setup_pointer() -> void:
	if _pointer and is_instance_valid(_pointer):
		return
	_pointer = TextureRect.new()
	_pointer.name = "DamageDirectionPointer"
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_pointer.texture = _make_pointer_texture()
	_pointer.custom_minimum_size = Vector2(_POINTER_SIZE, _POINTER_SIZE)
	_pointer.set_anchors_preset(Control.PRESET_CENTER)
	_pointer.size = Vector2(_POINTER_SIZE, _POINTER_SIZE)
	_pointer.position = -_pointer.size * 0.5
	_pointer.modulate = Color(0.706, 0.271, 0.184, 1.0)  # ember
	_pointer.visible = false
	add_child(_pointer)

## Простая procedural textura: рамка-кольцо (всё через packed arrays — не надо ресурсы).
func _make_pointer_texture() -> ImageTexture:
	var img := Image.create(int(_POINTER_SIZE), int(_POINTER_SIZE), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := _POINTER_SIZE * 0.5
	var r_in: float = c * 0.65
	var r_out: float = c * 0.95
	for y in range(int(_POINTER_SIZE)):
		for x in range(int(_POINTER_SIZE)):
			var px := Vector2(float(x) - c, float(y) - c)
			var d: float = px.length()
			if d >= r_in and d <= r_out:
				var t: float = (d - r_in) / (r_out - r_in)
				var alpha: float = 0.3 + 0.7 * (1.0 - t)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

func _on_damaged(_amount: int) -> void:
	_vignette_mat.set_shader_parameter("strength", 1.0)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _vignette_mat.set_shader_parameter("strength", v), 1.0, 0.0, _FADE_TIME)

## 3.15: при ударе — показываем по краю экрана, откуда пришёл урон.
func _on_damage_direction(amount: float, src_pos: Vector3) -> void:
	if _pointer == null:
		return
	# Угол к источнику в экранных координатах.
	var dir: Vector2 = _world_dir_to_screen(src_pos)
	var angle: float = dir.angle()
	_pointer.rotation = angle + PI * 0.5  # Cap facing center
	_pointer.position = Vector2(cos(angle), sin(angle)) * (get_viewport().get_visible_rect().size * 0.32) + (get_viewport().get_visible_rect().size * 0.5) - _pointer.size * 0.5
	_pointer.modulate.a = clampf(amount / 40.0, 0.3, 1.0)
	_pointer.visible = true
	if _pointer.has_meta("tween"):
		var t: Tween = _pointer.get_meta("tween") as Tween
		if t and t.is_valid():
			t.kill()
	var t2 := create_tween()
	t2.tween_interval(_FADE_TIME)
	t2.tween_property(_pointer, "modulate:a", 0.0, _FADE_TIME * 0.5)
	t2.tween_callback(func(): _pointer.visible = false)
	_pointer.set_meta("tween", t2)

## World Vector3 → 2D direction на камере.
func _world_dir_to_screen(src_pos: Vector3) -> Vector2:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player is Node3D:
		return Vector2.RIGHT
	var p3: Node3D = player
	if not p3.has_method("get_global_transform"):
		return Vector2.RIGHT
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return Vector2.RIGHT
	var to_src: Vector3 = (src_pos - cam.global_transform.origin)
	var to_cam: Vector3 = -cam.global_transform.basis.z
	# Проекция на 2D: x — в горизонталь (yaw), y — вертикаль (pitch).
	var dir_xy: Vector2 = Vector2(to_src.x, to_src.z).normalized()
	var dir_y: float = clampf(to_src.y * 0.4, -1.0, 1.0)
	return Vector2(dir_xy.x, -dir_y)  # minus: вверх = -y в screen
