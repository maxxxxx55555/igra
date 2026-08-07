extends Node
## Генератор иконки приложения: уличный фонарь во тьме.
## Пишет icon.png 512 (основная), icon_adaptive_fg/bg.png 432 (Android adaptive).
## Запуск: godot --headless --path <proj> res://scenes/tools/gen_icon_scene.tscn

const S: int = 512
const ADAPTIVE: int = 432

# Геометрия фонаря в нормализованных координатах (0..1)
const POLE_X: float = 0.615
const POLE_TOP: float = 0.20
const POLE_BOT: float = 0.92
const POLE_W: float = 0.022
const ARM_Y: float = 0.225
const ARM_H: float = 0.016
const LAMP_X: float = 0.40
const LAMP_Y: float = 0.245
const WARM := Color(1.0, 0.815, 0.51)

func _ready() -> void:
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	for y in S:
		for x in S:
			img.set_pixel(x, y, _pixel(float(x) / S, float(y) / S, false))
	var err := img.save_png("res://assets/ui/icon.png")
	print("[icon] icon.png ", "ok" if err == OK else "FAIL")

	var fg := Image.create(ADAPTIVE, ADAPTIVE, false, Image.FORMAT_RGBA8)
	for y in ADAPTIVE:
		for x in ADAPTIVE:
			# Безопасная зона adaptive-иконки: центральные 66% — сжимаем сцену.
			var u := (float(x) / ADAPTIVE - 0.5) / 0.66 + 0.5
			var v := (float(y) / ADAPTIVE - 0.5) / 0.66 + 0.5
			fg.set_pixel(x, y, _pixel(u, v, true))
	err = fg.save_png("res://assets/ui/icon_adaptive_fg.png")
	print("[icon] icon_adaptive_fg.png ", "ok" if err == OK else "FAIL")

	var bg := Image.create(ADAPTIVE, ADAPTIVE, false, Image.FORMAT_RGBA8)
	for y in ADAPTIVE:
		for x in ADAPTIVE:
			bg.set_pixel(x, y, _background(float(x) / ADAPTIVE, float(y) / ADAPTIVE))
	err = bg.save_png("res://assets/ui/icon_adaptive_bg.png")
	print("[icon] icon_adaptive_bg.png ", "ok" if err == OK else "FAIL")
	print("[icon] DONE")
	get_tree().quit()

func _background(u: float, v: float) -> Color:
	var top := Color(0.055, 0.075, 0.115)
	var bot := Color(0.016, 0.022, 0.045)
	var c := top.lerp(bot, v)
	var d := Vector2(u - 0.5, v - 0.5).length()
	c = c.darkened(clampf(d * 0.9, 0.0, 0.55))
	c.a = 1.0
	return c

## Основной расчёт пикселя. transparent=true — adaptive foreground (без фона).
func _pixel(u: float, v: float, transparent: bool) -> Color:
	var lamp := Vector2(LAMP_X, LAMP_Y)
	var p := Vector2(u, v)
	# Тёплое свечение вокруг лампы
	var glow: float = pow(clampf(1.0 - p.distance_to(lamp) / 0.34, 0.0, 1.0), 2.2)
	# Конус света вниз
	var cone: float = 0.0
	var dy := v - LAMP_Y
	if dy > 0.0:
		var half_w := dy * 0.52 + 0.012
		var dx: float = absf(u - LAMP_X)
		if dx < half_w:
			cone = (1.0 - dx / half_w) * clampf(1.0 - dy / 0.72, 0.0, 1.0) * 0.42
	# Пятно света на земле
	var g := Vector2((u - LAMP_X) / 0.30, (v - 0.90) / 0.055)
	var pool: float = pow(clampf(1.0 - g.length(), 0.0, 1.0), 1.6) * 0.5
	var light: float = clampf(glow + cone + pool, 0.0, 1.15)

	# Силуэт фонаря: столб + дугой кронштейн + плафон
	var pole: float = 0.0
	if absf(u - POLE_X) < POLE_W * 0.5 and v > POLE_TOP and v < POLE_BOT:
		pole = 1.0
	if u > LAMP_X - 0.01 and u < POLE_X:
		var k := (u - LAMP_X) / (POLE_X - LAMP_X)
		var arm_y := ARM_Y - sin(k * PI) * 0.018
		if absf(v - arm_y) < ARM_H * 0.5:
			pole = 1.0
	if v > LAMP_Y - 0.035 and v < LAMP_Y + 0.006 and absf(u - LAMP_X) < 0.034:
		pole = 1.0

	var c: Color
	if transparent:
		var a := maxf(light * 0.85, pole)
		if a <= 0.01:
			return Color(0, 0, 0, 0)
		c = Color(WARM.r * light, WARM.g * light, WARM.b * light, clampf(a, 0.0, 1.0))
	else:
		c = _background(u, v)
		c = Color(c.r + WARM.r * light * 0.9, c.g + WARM.g * light * 0.9, c.b + WARM.b * light * 0.9, 1.0)
	# Земля (только на основной иконке)
	if v > 0.905 and not transparent:
		var gc := Color(0.045, 0.055, 0.075).lerp(Color(0.35, 0.30, 0.20), clampf(pool * 1.6, 0.0, 0.8))
		c = Color(gc.r, gc.g, gc.b, 1.0)
	# Столб поверх света — тёмный силуэт с тёплым отсветом у лампы
	if pole > 0.0:
		var pc := Color(0.075, 0.085, 0.105).lerp(WARM, clampf(glow * 0.35, 0.0, 0.4))
		c = Color(pc.r, pc.g, pc.b, 1.0)
	# Ядро лампы
	var core: float = pow(clampf(1.0 - p.distance_to(lamp) / 0.030, 0.0, 1.0), 0.8)
	if core > 0.0:
		c = c.lerp(Color(1.0, 0.93, 0.78), core)
		c.a = maxf(c.a, core) if transparent else 1.0
	# Зерно
	var n := _hash2(u * 512.0, v * 512.0) * 0.02 - 0.01
	return Color(clampf(c.r + n, 0.0, 1.0), clampf(c.g + n, 0.0, 1.0), clampf(c.b + n, 0.0, 1.0), c.a)

func _hash2(x: float, y: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)
