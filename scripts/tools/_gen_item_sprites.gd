extends Node
## Генератор иконок предметов в стиле UI-листа: semi-realistic, PNG с альфой, 128x128.
## Сглаживание — аналитическое покрытие (SDF), заливка — вертикальный градиент + блик + тёмный контур.
## Запуск: godot --headless --quit-after 900 --path <proj> res://scenes/tools/gen_sprites_scene.tscn

const W: int = 128
const OUT_DIR: String = "res://assets/textures/items/"

# Палитра с UI-листа: графит, янтарь, кремовый, тёмно-красный, олива.
const DARK := Color(0.051, 0.063, 0.078)
const AMBER := Color(0.784, 0.588, 0.235)
const AMBER_HI := Color(0.910, 0.753, 0.416)
const CREAM := Color(0.910, 0.878, 0.800)
const STEEL := Color(0.541, 0.580, 0.627)
const STEEL_DK := Color(0.325, 0.353, 0.392)
const RED := Color(0.627, 0.204, 0.157)
const RED_HI := Color(0.784, 0.298, 0.235)
const OLIVE := Color(0.290, 0.353, 0.220)
const GREEN := Color(0.235, 0.420, 0.259)
const GLASS := Color(0.478, 0.659, 0.722)
const BROWN := Color(0.420, 0.290, 0.180)
const COPPER := Color(0.690, 0.416, 0.220)
const PAPER := Color(0.816, 0.776, 0.671)

var _img: Image

## Яркость умножением — сохраняет тон и насыщенность (в отличие от lightened/darkened).
func _mul(c: Color, k: float) -> Color:
	return Color(minf(c.r * k, 1.0), minf(c.g * k, 1.0), minf(c.b * k, 1.0), c.a)

func _ready() -> void:
	var made: int = 0
	for id_v in _targets():
		var id := String(id_v)
		_img = Image.create(W, W, false, Image.FORMAT_RGBA8)
		_img.fill(Color(0, 0, 0, 0))
		call("_draw_" + id)
		var path: String = OUT_DIR + id + ".png"
		if _img.save_png(path) == OK:
			made += 1
			print("[sprites] ok: ", id)
		else:
			print("[sprites] FAIL: ", id)
	print("[sprites] DONE generated=", made)
	get_tree().quit()

func _targets() -> Array:
	return [
		# предметы игры
		"battery", "medkit", "key", "ancient_key", "scrap", "cable", "fuse", "gear",
		"circuit", "wiring", "motor", "transistor", "serum", "radio_part",
		"scope_lens", "gas_canister",
		# чертежи
		"blueprint_flashlight_brightness", "blueprint_flashlight_battery",
		"blueprint_backpack_capacity", "blueprint_backpack_slots",
		# новые из UI-листа
		"bandage", "molotov", "lockpick", "taser", "repair_kit", "explosive",
		# прочее
		"flashlight", "coin",
		# WAVE 6 P2: workbench.gd recipe materials/results that shipped
		# with no icon at all (asset-check gate hard-fails on that).
		"fabric", "alcohol", "gunpowder", "case", "metal", "paper",
		"bottle", "noise_bomb", "firework", "makeshift_lamp",
	]

# ---------------- движок рисования ----------------

func _blend(x: int, y: int, c: Color, a: float) -> void:
	if a <= 0.002 or x < 0 or y < 0 or x >= W or y >= W:
		return
	var sa: float = clampf(a, 0.0, 1.0) * c.a
	if sa <= 0.002:
		return
	var dst := _img.get_pixel(x, y)
	var out_a: float = sa + dst.a * (1.0 - sa)
	if out_a <= 0.0001:
		return
	var k: float = dst.a * (1.0 - sa)
	_img.set_pixel(x, y, Color(
		(c.r * sa + dst.r * k) / out_a,
		(c.g * sa + dst.g * k) / out_a,
		(c.b * sa + dst.b * k) / out_a,
		out_a))

## Знаковое расстояние до скруглённого прямоугольника (локальные координаты, центр в 0).
func _sd_rrect(px: float, py: float, hw: float, hh: float, r: float) -> float:
	var qx: float = absf(px) - maxf(hw - r, 0.0)
	var qy: float = absf(py) - maxf(hh - r, 0.0)
	var ox: float = maxf(qx, 0.0)
	var oy: float = maxf(qy, 0.0)
	return sqrt(ox * ox + oy * oy) + minf(maxf(qx, qy), 0.0) - r

## Скруглённый прямоугольник с поворотом, объёмной заливкой, контуром и бликом.
func _rrect(cx: float, cy: float, w: float, h: float, rad: float, ang: float, base: Color,
		outline: float = 1.9, shade: float = 0.5, hl: float = 0.16) -> void:
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	rad = clampf(rad, 0.0, minf(hw, hh))
	var ca: float = cos(-ang)
	var sa: float = sin(-ang)
	var reach: float = sqrt(hw * hw + hh * hh) + outline + 2.0
	var top := _mul(base, 1.26)
	var bot := _mul(base, 1.0 - shade * 0.78)
	for py in range(int(floor(cy - reach)), int(ceil(cy + reach)) + 1):
		for px in range(int(floor(cx - reach)), int(ceil(cx + reach)) + 1):
			var fx: float = float(px) + 0.5 - cx
			var fy: float = float(py) + 0.5 - cy
			var lx: float = fx * ca - fy * sa
			var ly: float = fx * sa + fy * ca
			var d: float = _sd_rrect(lx, ly, hw, hh, rad)
			if outline > 0.0:
				var ao: float = clampf(0.5 - (d - outline), 0.0, 1.0)
				if ao > 0.0:
					_blend(px, py, DARK, ao * 0.92)
			var a: float = clampf(0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var t: float = clampf((ly + hh) / maxf(hh * 2.0, 0.001), 0.0, 1.0)
			var col: Color = top.lerp(bot, t)
			if hl > 0.0 and ly < -hh * 0.25 and d < -0.8:
				col = col.lerp(CREAM, hl * clampf((-ly - hh * 0.25) / maxf(hh * 0.6, 0.001), 0.0, 1.0))
			_blend(px, py, col, a)

func _circ(cx: float, cy: float, r: float, base: Color,
		outline: float = 1.9, shade: float = 0.5, hl: float = 0.18) -> void:
	var reach: float = r + outline + 2.0
	var top := _mul(base, 1.26)
	var bot := _mul(base, 1.0 - shade * 0.78)
	for py in range(int(floor(cy - reach)), int(ceil(cy + reach)) + 1):
		for px in range(int(floor(cx - reach)), int(ceil(cx + reach)) + 1):
			var fx: float = float(px) + 0.5 - cx
			var fy: float = float(py) + 0.5 - cy
			var d: float = sqrt(fx * fx + fy * fy) - r
			if outline > 0.0:
				var ao: float = clampf(0.5 - (d - outline), 0.0, 1.0)
				if ao > 0.0:
					_blend(px, py, DARK, ao * 0.92)
			var a: float = clampf(0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var t: float = clampf((fy + r) / maxf(r * 2.0, 0.001), 0.0, 1.0)
			var col: Color = top.lerp(bot, t)
			# косой блик слева-сверху
			var sp: float = clampf(1.0 - Vector2(fx + r * 0.35, fy + r * 0.4).length() / maxf(r * 0.8, 0.001), 0.0, 1.0)
			if hl > 0.0:
				col = col.lerp(CREAM, hl * sp)
			_blend(px, py, col, a)

func _caps(x1: float, y1: float, x2: float, y2: float, r: float, base: Color,
		outline: float = 1.9, shade: float = 0.48, hl: float = 0.14) -> void:
	var minx: float = minf(x1, x2) - r - outline - 2.0
	var maxx: float = maxf(x1, x2) + r + outline + 2.0
	var miny: float = minf(y1, y2) - r - outline - 2.0
	var maxy: float = maxf(y1, y2) + r + outline + 2.0
	var bax: float = x2 - x1
	var bay: float = y2 - y1
	var bb: float = maxf(bax * bax + bay * bay, 0.0001)
	var top := _mul(base, 1.22)
	var bot := _mul(base, 1.0 - shade * 0.78)
	for py in range(int(floor(miny)), int(ceil(maxy)) + 1):
		for px in range(int(floor(minx)), int(ceil(maxx)) + 1):
			var fx: float = float(px) + 0.5 - x1
			var fy: float = float(py) + 0.5 - y1
			var hp: float = clampf((fx * bax + fy * bay) / bb, 0.0, 1.0)
			var dx: float = fx - bax * hp
			var dy: float = fy - bay * hp
			var d: float = sqrt(dx * dx + dy * dy) - r
			if outline > 0.0:
				var ao: float = clampf(0.5 - (d - outline), 0.0, 1.0)
				if ao > 0.0:
					_blend(px, py, DARK, ao * 0.92)
			var a: float = clampf(0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var t: float = clampf((d + r) / maxf(r * 2.0, 0.001), 0.0, 1.0)
			var col: Color = top.lerp(bot, t)
			if hl > 0.0 and dy < 0.0:
				col = col.lerp(CREAM, hl * clampf(-dy / maxf(r, 0.001), 0.0, 1.0) * 0.8)
			_blend(px, py, col, a)

## Плоская заливка без контура — для деталей поверх (полосы, надписи, стёкла).
func _flat(cx: float, cy: float, w: float, h: float, rad: float, ang: float, col: Color, alpha: float = 1.0) -> void:
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	rad = clampf(rad, 0.0, minf(hw, hh))
	var ca: float = cos(-ang)
	var sa: float = sin(-ang)
	var reach: float = sqrt(hw * hw + hh * hh) + 2.0
	for py in range(int(floor(cy - reach)), int(ceil(cy + reach)) + 1):
		for px in range(int(floor(cx - reach)), int(ceil(cx + reach)) + 1):
			var fx: float = float(px) + 0.5 - cx
			var fy: float = float(py) + 0.5 - cy
			var lx: float = fx * ca - fy * sa
			var ly: float = fx * sa + fy * ca
			var a: float = clampf(0.5 - _sd_rrect(lx, ly, hw, hh, rad), 0.0, 1.0)
			if a > 0.0:
				_blend(px, py, col, a * alpha)

func _ring(cx: float, cy: float, r: float, thick: float, base: Color, outline: float = 1.9) -> void:
	var reach: float = r + thick + outline + 2.0
	var top := _mul(base, 1.22)
	var bot := _mul(base, 0.62)
	for py in range(int(floor(cy - reach)), int(ceil(cy + reach)) + 1):
		for px in range(int(floor(cx - reach)), int(ceil(cx + reach)) + 1):
			var fx: float = float(px) + 0.5 - cx
			var fy: float = float(py) + 0.5 - cy
			var dist: float = sqrt(fx * fx + fy * fy)
			var d: float = absf(dist - r) - thick * 0.5
			if outline > 0.0:
				var ao: float = clampf(0.5 - (d - outline), 0.0, 1.0)
				if ao > 0.0:
					_blend(px, py, DARK, ao * 0.9)
			var a: float = clampf(0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var t: float = clampf((fy + r) / maxf(r * 2.0, 0.001), 0.0, 1.0)
			_blend(px, py, top.lerp(bot, t), a)

# ---------------- иконки ----------------

func _draw_battery() -> void:
	_rrect(64, 34, 22, 12, 3, 0, STEEL)
	_rrect(64, 74, 50, 76, 7, 0, AMBER)
	_flat(64, 52, 50, 6, 2, 0, DARK, 0.26)
	_flat(64, 98, 50, 6, 2, 0, DARK, 0.26)
	# молния
	_caps(70, 58, 58, 74, 4.5, CREAM, 0.0, 0.15, 0.0)
	_caps(58, 74, 70, 74, 4.5, CREAM, 0.0, 0.15, 0.0)
	_caps(70, 74, 58, 92, 4.5, CREAM, 0.0, 0.15, 0.0)
	_flat(50, 74, 5, 58, 2, 0, CREAM, 0.14)

func _draw_medkit() -> void:
	_rrect(64, 46, 26, 12, 4, 0, STEEL_DK)
	_rrect(64, 78, 82, 58, 8, 0, RED)
	_flat(64, 78, 82, 5, 2, 0, DARK, 0.35)
	_flat(64, 76, 34, 11, 3, 0, CREAM, 0.95)
	_flat(64, 76, 11, 34, 3, 0, CREAM, 0.95)
	_rrect(64, 104, 16, 8, 2, 0, AMBER, 1.2, 0.3, 0.2)
	_flat(30, 78, 6, 48, 3, 0, CREAM, 0.13)

func _draw_key() -> void:
	_ring(44, 44, 17, 9, STEEL)
	_caps(52, 56, 92, 96, 6, STEEL)
	_rrect(86, 78, 9, 18, 2, 0, STEEL)
	_rrect(98, 90, 9, 16, 2, 0, STEEL)
	_flat(40, 38, 8, 8, 4, 0, CREAM, 0.25)

func _draw_ancient_key() -> void:
	_ring(42, 42, 20, 10, COPPER)
	_caps(50, 54, 94, 98, 7, AMBER)
	_rrect(84, 76, 11, 22, 3, 0, AMBER)
	_rrect(98, 92, 11, 18, 3, 0, AMBER)
	_caps(28, 30, 56, 30, 4, COPPER, 1.4)
	_circ(42, 42, 6, DARK, 0.0, 0.1, 0.0)
	_flat(36, 34, 9, 9, 4, 0, CREAM, 0.3)

func _draw_scrap() -> void:
	_rrect(52, 76, 54, 34, 4, -0.32, STEEL_DK)
	_rrect(80, 56, 40, 28, 3, 0.45, STEEL)
	_rrect(46, 50, 30, 22, 3, 0.18, BROWN)
	_flat(60, 66, 26, 4, 2, -0.32, CREAM, 0.22)
	_flat(84, 50, 18, 4, 2, 0.45, CREAM, 0.2)

func _draw_cable() -> void:
	_caps(28, 84, 50, 46, 9, GREEN)
	_caps(50, 46, 78, 84, 9, GREEN)
	_caps(78, 84, 100, 44, 9, GREEN)
	_rrect(26, 92, 18, 14, 3, 0, STEEL)
	_rrect(102, 38, 18, 14, 3, 0, STEEL)
	_flat(50, 52, 40, 4, 2, -0.5, CREAM, 0.14)

func _draw_fuse() -> void:
	_rrect(64, 64, 54, 28, 8, 0, GLASS)
	_flat(64, 64, 44, 5, 2, 0, AMBER_HI, 0.95)
	_flat(64, 64, 6, 14, 2, 0, AMBER, 0.9)
	_rrect(26, 64, 18, 24, 4, 0, STEEL)
	_rrect(102, 64, 18, 24, 4, 0, STEEL)
	_flat(60, 56, 32, 4, 2, 0, CREAM, 0.3)

func _draw_gear() -> void:
	for i in 8:
		var a: float = TAU * float(i) / 8.0
		_rrect(64 + cos(a) * 42.0, 64 + sin(a) * 42.0, 20, 18, 3, a, STEEL_DK)
	_circ(64, 64, 36, STEEL)
	_ring(64, 64, 22, 7, AMBER, 1.2)
	_circ(64, 64, 12, DARK, 1.2, 0.2, 0.0)

func _draw_circuit() -> void:
	_rrect(64, 64, 88, 72, 5, 0, OLIVE.darkened(0.15))
	_caps(30, 48, 96, 48, 2.5, AMBER, 0.0, 0.2, 0.0)
	_caps(30, 66, 66, 66, 2.5, AMBER, 0.0, 0.2, 0.0)
	_caps(66, 66, 66, 90, 2.5, AMBER, 0.0, 0.2, 0.0)
	_caps(76, 78, 96, 78, 2.5, AMBER, 0.0, 0.2, 0.0)
	_rrect(46, 58, 26, 18, 2, 0, DARK, 1.2, 0.2, 0.1)
	_rrect(84, 90, 20, 14, 2, 0, DARK, 1.2, 0.2, 0.1)
	_circ(96, 36, 5, COPPER, 1.0)
	_circ(34, 92, 5, COPPER, 1.0)

func _draw_wiring() -> void:
	_caps(24, 46, 104, 40, 7, RED)
	_caps(24, 64, 104, 64, 7, AMBER)
	_caps(24, 82, 104, 88, 7, OLIVE)
	_rrect(64, 64, 22, 58, 5, 0, STEEL_DK)
	_flat(64, 64, 22, 5, 2, 0, CREAM, 0.18)

func _draw_motor() -> void:
	_rrect(60, 64, 62, 52, 8, 0, STEEL_DK)
	for i in 4:
		_flat(38.0 + float(i) * 14.0, 64, 5, 52, 2, 0, DARK, 0.35)
	_circ(30, 64, 18, STEEL)
	_circ(30, 64, 7, DARK, 1.2, 0.2, 0.0)
	_rrect(100, 64, 24, 16, 4, 0, COPPER)
	_flat(60, 44, 56, 5, 2, 0, CREAM, 0.16)

func _draw_transistor() -> void:
	_circ(64, 54, 30, DARK.lightened(0.16))
	_rrect(64, 62, 60, 30, 3, 0, DARK.lightened(0.16))
	_flat(64, 42, 44, 7, 3, 0, STEEL, 0.5)
	_caps(46, 76, 46, 106, 4, STEEL)
	_caps(64, 76, 64, 110, 4, STEEL)
	_caps(82, 76, 82, 106, 4, STEEL)

func _draw_serum() -> void:
	_rrect(64, 30, 26, 14, 4, 0, STEEL)
	_rrect(64, 72, 34, 72, 12, 0, GLASS)
	_flat(64, 86, 30, 42, 10, 0, RED, 0.92)
	_flat(64, 66, 34, 12, 3, 0, CREAM, 0.85)
	_flat(54, 70, 6, 44, 3, 0, CREAM, 0.28)

func _draw_radio_part() -> void:
	_rrect(62, 78, 74, 46, 5, 0, STEEL_DK)
	_rrect(44, 78, 26, 26, 3, 0, DARK, 1.2, 0.2, 0.1)
	_circ(84, 78, 13, AMBER)
	_flat(84, 72, 4, 10, 2, 0, DARK, 0.7)
	_caps(64, 56, 92, 26, 3.5, STEEL)
	_circ(94, 22, 6, RED_HI, 1.2)
	_flat(40, 70, 18, 4, 2, 0, CREAM, 0.2)

func _draw_scope_lens() -> void:
	_ring(64, 64, 42, 12, STEEL_DK)
	_circ(64, 64, 32, GLASS.darkened(0.25))
	_flat(64, 64, 56, 2.5, 1, 0, DARK, 0.75)
	_flat(64, 64, 2.5, 56, 1, 0, DARK, 0.75)
	_circ(52, 52, 11, CREAM, 0.0, 0.1, 0.0)
	_flat(52, 52, 22, 22, 11, 0, GLASS, 0.35)

func _draw_gas_canister() -> void:
	_rrect(64, 74, 58, 74, 10, 0, RED)
	_flat(64, 52, 58, 8, 3, 0, DARK, 0.4)
	_flat(64, 92, 58, 8, 3, 0, DARK, 0.4)
	_rrect(64, 30, 18, 20, 4, 0, STEEL_DK)
	_rrect(64, 22, 36, 9, 3, 0, STEEL)
	_flat(64, 74, 30, 26, 4, 0, CREAM, 0.16)
	_flat(64, 74, 22, 5, 2, 0, DARK, 0.5)
	_flat(42, 74, 6, 52, 3, 0, CREAM, 0.14)

func _paper() -> void:
	_rrect(64, 64, 92, 80, 3, 0, PAPER, 1.6, 0.25, 0.12)
	for i in 6:
		_flat(64, 30.0 + float(i) * 14.0, 92, 1.4, 0, 0, AMBER, 0.22)
	for i in 6:
		_flat(24.0 + float(i) * 16.0, 64, 1.4, 80, 0, 0, AMBER, 0.22)
	_flat(64, 26, 92, 6, 2, 0, BROWN, 0.3)

func _draw_blueprint_flashlight_brightness() -> void:
	_paper()
	_circ(64, 64, 14, AMBER, 1.4, 0.3, 0.25)
	for i in 8:
		var a: float = TAU * float(i) / 8.0
		_caps(64 + cos(a) * 20.0, 64 + sin(a) * 20.0, 64 + cos(a) * 30.0, 64 + sin(a) * 30.0, 2.6, AMBER, 0.0, 0.2, 0.0)

func _draw_blueprint_flashlight_battery() -> void:
	_paper()
	_rrect(64, 66, 34, 42, 4, 0, AMBER, 1.4, 0.3, 0.2)
	_rrect(64, 42, 14, 7, 2, 0, AMBER, 1.2, 0.3, 0.0)
	_flat(64, 58, 24, 5, 2, 0, DARK, 0.55)
	_flat(64, 70, 24, 5, 2, 0, DARK, 0.55)
	_flat(64, 82, 24, 5, 2, 0, DARK, 0.55)

func _draw_blueprint_backpack_capacity() -> void:
	_paper()
	_rrect(64, 68, 34, 38, 6, 0, OLIVE, 1.4, 0.3, 0.2)
	_rrect(64, 46, 18, 10, 4, 0, OLIVE, 1.2, 0.3, 0.0)
	_caps(40, 68, 26, 68, 2.6, AMBER, 0.0, 0.2, 0.0)
	_caps(26, 68, 33, 61, 2.6, AMBER, 0.0, 0.2, 0.0)
	_caps(26, 68, 33, 75, 2.6, AMBER, 0.0, 0.2, 0.0)
	_caps(88, 68, 102, 68, 2.6, AMBER, 0.0, 0.2, 0.0)
	_caps(102, 68, 95, 61, 2.6, AMBER, 0.0, 0.2, 0.0)
	_caps(102, 68, 95, 75, 2.6, AMBER, 0.0, 0.2, 0.0)

func _draw_blueprint_backpack_slots() -> void:
	_paper()
	for r in 2:
		for c in 2:
			_rrect(52.0 + float(c) * 24.0, 52.0 + float(r) * 24.0, 20, 20, 3, 0, AMBER, 1.4, 0.3, 0.2)
			_flat(52.0 + float(c) * 24.0, 52.0 + float(r) * 24.0, 11, 11, 2, 0, PAPER, 0.65)

func _draw_bandage() -> void:
	_circ(58, 62, 32, CREAM)
	_circ(58, 62, 13, PAPER.darkened(0.25), 1.4, 0.3, 0.1)
	_flat(58, 62, 64, 9, 3, 0, RED, 0.55)
	_caps(84, 74, 108, 96, 11, CREAM)
	_flat(96, 86, 22, 4, 2, -0.75, RED, 0.4)
	_flat(46, 44, 20, 6, 3, -0.5, CREAM, 0.4)

func _draw_molotov() -> void:
	_rrect(64, 82, 44, 54, 10, 0, GLASS)
	_flat(64, 92, 40, 32, 8, 0, AMBER, 0.85)
	_rrect(64, 50, 18, 24, 5, 0, GLASS)
	_caps(64, 40, 72, 22, 6, CREAM)
	_circ(76, 16, 9, RED_HI, 1.2, 0.3, 0.35)
	_circ(78, 10, 5, AMBER_HI, 0.0, 0.2, 0.4)
	_flat(50, 80, 6, 34, 3, 0, CREAM, 0.28)

func _draw_lockpick() -> void:
	_caps(28, 96, 92, 40, 4, STEEL)
	_caps(92, 40, 104, 34, 4, STEEL)
	_caps(38, 84, 96, 62, 3.4, STEEL_DK)
	_caps(96, 62, 106, 56, 3.4, STEEL_DK)
	_rrect(30, 94, 26, 14, 5, -0.72, AMBER)
	_flat(60, 68, 40, 3, 1.5, -0.72, CREAM, 0.25)

func _draw_taser() -> void:
	_rrect(56, 84, 40, 42, 7, 0, DARK.lightened(0.18))
	_flat(56, 84, 26, 6, 2, 0, AMBER, 0.5)
	_rrect(74, 54, 44, 22, 5, 0, STEEL_DK)
	_caps(92, 44, 104, 30, 3.4, STEEL)
	_caps(92, 62, 104, 74, 3.4, STEEL)
	_caps(104, 30, 100, 52, 2.6, AMBER_HI, 0.0, 0.2, 0.0)
	_caps(100, 52, 104, 74, 2.6, AMBER_HI, 0.0, 0.2, 0.0)
	_circ(104, 30, 4, CREAM, 0.0, 0.1, 0.0)
	_circ(104, 74, 4, CREAM, 0.0, 0.1, 0.0)

func _draw_repair_kit() -> void:
	_rrect(64, 82, 84, 50, 6, 0, OLIVE)
	_flat(64, 82, 84, 5, 2, 0, DARK, 0.35)
	_rrect(64, 50, 30, 12, 5, 0, STEEL_DK)
	_caps(48, 92, 70, 70, 5, STEEL)
	_ring(46, 94, 8, 5, STEEL, 1.2)
	_caps(78, 70, 86, 94, 5, AMBER)
	_rrect(86, 96, 14, 10, 3, 0, AMBER)
	_flat(30, 82, 6, 40, 3, 0, CREAM, 0.13)

func _draw_explosive() -> void:
	_rrect(46, 78, 26, 62, 6, 0.06, RED)
	_rrect(66, 74, 26, 66, 6, 0, RED)
	_rrect(86, 78, 26, 62, 6, -0.06, RED)
	_flat(66, 66, 74, 12, 3, 0, AMBER, 0.9)
	_flat(66, 96, 74, 12, 3, 0, AMBER, 0.9)
	_caps(66, 42, 88, 20, 4, BROWN)
	_circ(90, 16, 7, AMBER_HI, 1.2, 0.3, 0.4)
	_flat(38, 78, 5, 44, 2, 0, CREAM, 0.16)

func _draw_flashlight() -> void:
	_rrect(58, 76, 34, 62, 6, -0.35, STEEL_DK)
	_rrect(80, 44, 40, 30, 6, -0.35, STEEL)
	_flat(88, 36, 30, 8, 3, -0.35, AMBER_HI, 0.9)
	_flat(58, 82, 26, 6, 2, -0.35, AMBER, 0.6)
	_caps(96, 28, 112, 14, 5, AMBER_HI, 0.0, 0.2, 0.3)
	_flat(46, 68, 6, 40, 3, -0.35, CREAM, 0.2)

func _draw_coin() -> void:
	_circ(64, 64, 40, AMBER)
	_ring(64, 64, 31, 6, AMBER_HI, 1.2)
	_flat(64, 64, 10, 34, 4, 0, DARK, 0.45)
	_flat(64, 64, 34, 10, 4, 0, DARK, 0.45)
	_flat(50, 48, 16, 16, 8, 0, CREAM, 0.3)

# ---------------- WAVE 6 P2: craft materials/results ----------------

func _draw_fabric() -> void:
	_rrect(56, 58, 68, 44, 4, -0.12, CREAM)
	_rrect(72, 78, 68, 40, 4, 0.1, PAPER.darkened(0.08))
	_flat(56, 58, 54, 3, 1, -0.12, STEEL_DK, 0.35)
	_flat(56, 66, 54, 3, 1, -0.12, STEEL_DK, 0.35)
	_flat(72, 86, 54, 3, 1, 0.1, STEEL_DK, 0.3)

func _draw_alcohol() -> void:
	_rrect(64, 34, 20, 16, 3, 0, STEEL)
	_rrect(64, 78, 36, 70, 8, 0, GLASS)
	_flat(64, 92, 30, 40, 6, 0, CREAM, 0.55)
	_flat(64, 62, 30, 10, 2, 0, CREAM, 0.85)
	_flat(56, 70, 5, 40, 2, 0, CREAM, 0.25)

func _draw_gunpowder() -> void:
	_rrect(64, 72, 56, 60, 16, 0, BROWN)
	_caps(64, 42, 64, 30, 5, STEEL_DK)
	_flat(64, 24, 20, 6, 2, 0, STEEL_DK, 0.8)
	for i in 10:
		var rx: float = 64.0 + cos(float(i) * 2.4) * randf_range(6.0, 20.0)
		var ry: float = 78.0 + sin(float(i) * 3.1) * randf_range(6.0, 18.0)
		_circ(rx, ry, 2.2, DARK, 0.0, 0.1, 0.15)

func _draw_case() -> void:
	_caps(64, 92, 64, 44, 13, COPPER)
	_ring(64, 40, 13, 4, AMBER_HI, 1.0)
	_flat(64, 92, 20, 6, 3, 0, DARK, 0.4)
	_flat(56, 60, 5, 40, 2, 0, CREAM, 0.2)

func _draw_metal() -> void:
	_rrect(64, 64, 84, 60, 4, -0.08, STEEL)
	_flat(64, 64, 70, 6, 2, -0.08, CREAM, 0.3)
	_flat(64, 78, 70, 3, 1, -0.08, STEEL_DK, 0.4)
	_circ(34, 42, 4, STEEL_DK, 1.0, 0.2, 0.0)
	_circ(94, 86, 4, STEEL_DK, 1.0, 0.2, 0.0)

func _draw_paper() -> void:
	_rrect(58, 60, 58, 76, 3, -0.06, PAPER)
	_rrect(70, 68, 58, 76, 3, 0.06, CREAM)
	_flat(70, 46, 40, 3, 1, 0.06, STEEL_DK, 0.35)
	_flat(70, 56, 40, 3, 1, 0.06, STEEL_DK, 0.35)
	_flat(70, 66, 40, 3, 1, 0.06, STEEL_DK, 0.35)
	_flat(70, 76, 26, 3, 1, 0.06, STEEL_DK, 0.3)

func _draw_bottle() -> void:
	_caps(64, 30, 64, 44, 7, GLASS)
	_rrect(64, 84, 40, 72, 10, 0, GLASS)
	_flat(64, 96, 34, 44, 8, 0, OLIVE, 0.75)
	_flat(64, 60, 34, 10, 2, 0, CREAM, 0.7)
	_flat(56, 68, 5, 44, 2, 0, CREAM, 0.25)

func _draw_noise_bomb() -> void:
	_circ(64, 72, 38, STEEL_DK)
	_ring(64, 72, 24, 5, STEEL, 1.0)
	_caps(64, 34, 64, 20, 4, BROWN)
	_circ(64, 16, 6, RED_HI, 1.0, 0.3, 0.35)
	_flat(50, 56, 14, 14, 6, 0, CREAM, 0.22)

func _draw_firework() -> void:
	_caps(64, 108, 64, 56, 6, BROWN)
	_rrect(64, 46, 26, 32, 6, 0, RED)
	_flat(64, 40, 20, 6, 2, 0, AMBER_HI, 0.8)
	_circ(64, 20, 5, AMBER_HI, 0.0, 0.2, 0.4)
	_circ(48, 30, 3, RED_HI, 0.0, 0.2, 0.4)
	_circ(80, 30, 3, RED_HI, 0.0, 0.2, 0.4)

func _draw_makeshift_lamp() -> void:
	_rrect(64, 96, 28, 14, 4, 0, STEEL_DK)
	_caps(64, 88, 64, 66, 4, STEEL)
	_circ(64, 50, 26, AMBER_HI, 1.4, 0.25, 0.3)
	_ring(64, 50, 30, 4, STEEL, 1.0)
	_circ(64, 50, 14, CREAM, 0.0, 0.1, 0.5)
