extends Control
## T14: 3 динамических фона меню (NIGHT/DAY/GENERATOR) с параллаксом.
##
## Ассетов нет и не будет (assets/** — чужая зона), поэтому силуэт города
## рисуется процедурно в ImageTexture, как и остальной UI этого проекта
## (см. shot_tool/pointer texture в damage_indicator.gd).

enum BgTheme { NIGHT, DAY, GENERATOR }

const CYCLE_TIME: float = 24.0
const CROSSFADE_TIME: float = 2.5
const TEX_W: int = 640
const TEX_H: int = 360
const FAR_SPEED: float = 6.0
const NEAR_SPEED: float = 16.0

const _SKY := {
	BgTheme.NIGHT: Color(0.043, 0.055, 0.082),
	BgTheme.DAY: Color(0.243, 0.271, 0.318),
	BgTheme.GENERATOR: Color(0.071, 0.055, 0.043),
}
const _WINDOW := {
	BgTheme.NIGHT: Color(0.788, 0.635, 0.290),
	BgTheme.DAY: Color(0.4, 0.42, 0.46, 0.5),
	BgTheme.GENERATOR: Color(0.706, 0.271, 0.184),
}
const _LIT_CHANCE := {BgTheme.NIGHT: 0.5, BgTheme.DAY: 0.06, BgTheme.GENERATOR: 0.85}

var _layers: Array = []  # [{"far": [TextureRect,TextureRect], "near": [...]}] per active container
var _containers: Array[Control] = []
var _active: int = 0
var _theme: int = BgTheme.NIGHT
var _timer: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 2:
		var c := Control.new()
		c.name = "BGLayer%d" % i
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.modulate.a = 0.0
		add_child(c)
		_containers.append(c)
		_layers.append({"far": [], "near": []})
	_theme = randi() % 3
	_build_theme(0, _theme)
	_containers[0].modulate.a = 1.0
	_timer = CYCLE_TIME

func _build_theme(container_idx: int, theme: int) -> void:
	var c := _containers[container_idx]
	var far_tex := _make_skyline(theme, 11, 0.35, 0.6)
	var near_tex := _make_skyline(theme, 6, 0.6, 1.0)
	_layers[container_idx]["far"] = _make_scroll_pair(c, far_tex, 0.45)
	_layers[container_idx]["near"] = _make_scroll_pair(c, near_tex, 0.85)

func _make_scroll_pair(parent: Control, tex: ImageTexture, y_scale: float) -> Array:
	var out: Array = []
	for i in 2:
		var t := TextureRect.new()
		t.texture = tex
		t.stretch_mode = TextureRect.STRETCH_KEEP
		t.size = Vector2(TEX_W, TEX_H * y_scale)
		t.position = Vector2(float(i) * TEX_W, 0)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(t)
		out.append(t)
	return out

## Силуэт зданий со случайными окнами; seed привязан к теме+слою, чтобы
## два слоя параллакса не выглядели одинаково.
func _make_skyline(theme: int, building_count: int, min_h: float, max_h: float) -> ImageTexture:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(_SKY[theme])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(theme) + "_" + str(building_count))
	var x := 0
	var win_color: Color = _WINDOW[theme]
	var lit_chance: float = _LIT_CHANCE[theme]
	while x < TEX_W:
		var bw: int = rng.randi_range(28, 60)
		var bh: int = int(TEX_H * rng.randf_range(min_h, max_h))
		var top: int = TEX_H - bh
		var body := Color(0.06, 0.055, 0.05) if theme != BgTheme.DAY else Color(0.18, 0.19, 0.21)
		_fill_rect(img, x, top, bw, bh, body)
		if theme == BgTheme.GENERATOR and rng.randf() < 0.2:
			_fill_rect(img, x, top, bw, 4, _WINDOW[BgTheme.GENERATOR])
		var wx := x + 4
		while wx < x + bw - 6:
			var wy := top + 6
			while wy < TEX_H - 6:
				if rng.randf() < lit_chance:
					_fill_rect(img, wx, wy, 3, 4, win_color)
				wy += 10
			wx += 8
		x += bw + rng.randi_range(4, 12)
	return ImageTexture.create_from_image(img)

func _fill_rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var x0 := clampi(x, 0, TEX_W - 1)
	var y0 := clampi(y, 0, TEX_H - 1)
	var x1 := clampi(x + w, 0, TEX_W)
	var y1 := clampi(y + h, 0, TEX_H)
	for py in range(y0, y1):
		for px in range(x0, x1):
			img.set_pixel(px, py, c)

func _process(delta: float) -> void:
	var active_layers: Dictionary = _layers[_active]
	_scroll(active_layers["far"], FAR_SPEED * delta)
	_scroll(active_layers["near"], NEAR_SPEED * delta)
	_timer -= delta
	if _timer <= 0.0:
		_timer = CYCLE_TIME
		_advance_theme()

func _scroll(pair: Array, dx: float) -> void:
	if pair.is_empty():
		return
	for t in pair:
		t.position.x -= dx
	if pair[0].position.x <= -TEX_W:
		for t in pair:
			t.position.x += TEX_W

func _advance_theme() -> void:
	_theme = (_theme + 1) % 3
	var next_idx := 1 - _active
	_build_theme(next_idx, _theme)
	var from_c := _containers[_active]
	var to_c := _containers[next_idx]
	to_c.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(to_c, "modulate:a", 1.0, CROSSFADE_TIME)
	tw.tween_property(from_c, "modulate:a", 0.0, CROSSFADE_TIME)
	tw.chain().tween_callback(func():
		for t in _layers[_active]["far"] + _layers[_active]["near"]:
			t.queue_free()
		_layers[_active] = {"far": [], "near": []})
	_active = next_idx
