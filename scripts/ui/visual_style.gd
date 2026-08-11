# VisualStyle — ПРОГРАММНЫЙ арт в стиле референса (без внешних ассетов): силуэты,
# текстурные тайлы мира, виньетка, рамки. Поднимает визуал над уровнем «кружки».
class_name VisualStyle
extends RefCounted

static func _h(x: int, y: int, seed: int) -> float:
	var n := (x * 374761393 + y * 668265263 + seed * 1442695041)
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 255) / 255.0

# Текстурный тайл: 0=пол(асфальт+трещины+лужи), 1=стена(кирпич+мох), 2=декор(мусор).
static func make_tile_texture(kind: int, size: int = 32) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var c: Color
			var n := _h(x, y, kind * 17 + 3)
			if kind == 0:
				var base := 0.10 + n * 0.05
				if _h(x, y, 99) < 0.04:
					base *= 0.5
				if _h(x / 6, y / 6, 7) < 0.12:
					c = Color(0.06, 0.08, 0.12, 1.0)
				else:
					c = Color(base * 0.9, base, base * 1.1, 1.0)
			elif kind == 1:
				var brick := ((y % 8) == 0) or (((x + (y / 8) * 5) % 12) == 0)
				if brick:
					c = Color(0.12, 0.08, 0.06, 1.0)
				else:
					var b := 0.20 + n * 0.08
					c = Color(b * 1.1, b * 0.7, b * 0.5, 1.0)
				if _h(x / 5, y / 5, 33) < 0.10:
					c = c.lerp(Color("2f4a22"), 0.6)
			else:
				c = Color(0.10, 0.09, 0.07, 1.0)
				if _h(x, y, 55) < 0.10:
					c = Color(0.30 + n * 0.2, 0.22, 0.12, 1.0)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

static func draw_player(c: CanvasItem, look: Vector2, rim: Color, body: Color) -> void:
	c.draw_circle(Vector2(0, 4), 11.0, Color(0, 0, 0, 0.35))
	c.draw_circle(Vector2.ZERO, 10.0, body)
	c.draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, rim, 2.0, true)
	var tip := look * 9.0
	var perp := Vector2(-look.y, look.x) * 6.0
	c.draw_colored_polygon(PackedVector2Array([tip, -look * 4.0 + perp, -look * 4.0 - perp]), body.darkened(0.25))
	var hand := look * 8.0 + perp * 0.5
	c.draw_circle(hand, 2.5, Color("f2c879"))
	c.draw_line(Vector2.ZERO, hand, rim, 1.5, true)

static func draw_monster(c: CanvasItem, type: StringName, facing: Vector2, col: Color, t: float) -> void:
	match type:
		&"shadow":
			for i in 4:
				var off := Vector2(sin(t * 3.0 + i) * 3.0, cos(t * 2.5 + i) * 3.0)
				c.draw_circle(off, 9.0 - i, Color(col.r, col.g, col.b, 0.30))
		&"crawler":
			c.draw_circle(Vector2.ZERO, 7.0, col)
			for i in 6:
				var a := float(i) / 6.0 * TAU + sin(t * 8.0) * 0.3
				var d := Vector2(cos(a), sin(a))
				c.draw_line(d * 6.0, d * 13.0, col.lightened(0.2), 1.5, true)
		&"watcher":
			c.draw_line(Vector2.ZERO, Vector2(0, 8), col, 2.0, true)
			c.draw_circle(Vector2.ZERO, 7.0, col)
			c.draw_circle(facing * 2.5, 3.0, Color("ff5050"))
		&"hunter":
			var f := facing.normalized() if facing.length() > 0.1 else Vector2.DOWN
			var perp := Vector2(-f.y, f.x)
			c.draw_colored_polygon(PackedVector2Array([f * 11.0, -f * 4.0 + perp * 6.0, -f * 4.0 - perp * 6.0]), col)
		&"destroyer":
			c.draw_colored_polygon(PackedVector2Array([Vector2(0, -13), Vector2(11, -4), Vector2(9, 11), Vector2(-9, 11), Vector2(-11, -4)]), col)
			for i in 5:
				var a := float(i) / 5.0 * TAU
				c.draw_line(Vector2(cos(a), sin(a)) * 9.0, Vector2(cos(a), sin(a)) * 14.0, col.lightened(0.3), 2.0, true)
		&"boss":
			var pulse := 1.0 + sin(t * 4.0) * 0.12
			for i in 3:
				c.draw_arc(Vector2.ZERO, (16.0 + i * 5.0) * pulse, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.25 - i * 0.06), 2.0, true)
			c.draw_circle(Vector2.ZERO, 14.0 * pulse, col)
			c.draw_circle(Vector2.ZERO, 6.0, Color("ff3030"))
		_:
			c.draw_circle(Vector2.ZERO, 9.0, col)

# Кинематографичная виньетка поверх камеры (атмосфера референса).
static func draw_vignette(c: CanvasItem, r: Rect2, strength: float) -> void:
	var cx := r.size * 0.5
	var rad := r.size.length() * 0.5
	for i in 6:
		var f := float(i) / 6.0
		var a := strength * 0.5 * f * f
		c.draw_arc(cx, rad * (1.0 - f * 0.5), 0.0, TAU, 24, Color(0, 0, 0, a), maxf(2.0, rad * 0.12), true)