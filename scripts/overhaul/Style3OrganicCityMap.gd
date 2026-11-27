class_name Style3OrganicCityMap
extends RefCounted

## Reference Style 3 City & District Map Painter obeying canonical ThemeProvider palette
## and gameplay rules: 0 enemy markers, 0 item markers, light-only fog-of-war on district tab,
## glowing sodium-amber illumination nodes & arterial streets on the 11-district city tab.

const COL_BG: Color = Color("#060f13")
const COL_RIVER: Color = Color("#0f1314")
const COL_PARK: Color = Color("#161e22")
const COL_BLOCK: Color = Color("#1c1e1d")
const COL_ROAD_DIM: Color = Color("#5a4a2a")
const COL_ROAD_LIT: Color = Color("#c9a24a")
const COL_AMBER: Color = Color("#d4a94e")
const COL_IVORY: Color = Color("#e6dfd1")

const LEGEND_DISTRICT_RU: String = "Свет — разведано | Контуры — здания | Стрелка — вы (враги и предметы скрыты)"
const LEGEND_DISTRICT_EN: String = "Light — explored | Outlines — buildings | Arrow — you (enemies & items hidden)"
const LEGEND_CITY_RU: String = "Янтарь — свет возвращён | Кольцо — текущий район | Тень — закрыто"
const LEGEND_CITY_EN: String = "Amber — light restored | Ring — current district | Dark — locked"

const COORDS: Array[Vector2] = [
	Vector2(0.14, 0.22),
	Vector2(0.27, 0.35),
	Vector2(0.18, 0.58),
	Vector2(0.39, 0.20),
	Vector2(0.43, 0.49),
	Vector2(0.35, 0.75),
	Vector2(0.57, 0.61),
	Vector2(0.62, 0.26),
	Vector2(0.76, 0.41),
	Vector2(0.72, 0.75),
	Vector2(0.86, 0.60),
]


static func get_legend(is_city_tab: bool) -> String:
	var is_ru: bool = TranslationServer.get_locale().to_lower().begins_with("ru")
	if is_city_tab:
		return LEGEND_CITY_RU if is_ru else LEGEND_CITY_EN
	return LEGEND_DISTRICT_RU if is_ru else LEGEND_DISTRICT_EN


static func draw_compass_minimap_chrome(canvas: CanvasItem, center: Vector2, radius: float, font: Font) -> void:
	if canvas == null or radius < 16.0:
		return
	canvas.draw_arc(center, radius + 2.0, 0.0, TAU, 48, Color(COL_BG, 0.80), 4.0, true)
	canvas.draw_arc(center, radius, 0.0, TAU, 48, COL_ROAD_DIM, 1.8, true)
	canvas.draw_arc(center, radius - 3.0, 0.0, TAU, 48, Color(COL_AMBER, 0.18), 1.0, true)
	for deg in [0, 90, 180, 270]:
		var rad: float = deg_to_rad(float(deg))
		var dir: Vector2 = Vector2(sin(rad), -cos(rad))
		canvas.draw_line(center + dir * (radius - 5.0), center + dir * (radius + 1.0), COL_AMBER if deg == 0 else COL_ROAD_DIM, 1.6, true)
	if font != null:
		canvas.draw_string(font, center + Vector2(-4.0, -(radius + 5.0)), "N", HORIZONTAL_ALIGNMENT_LEFT, 16.0, 11, COL_AMBER)


static func draw_city_map(
	canvas: CanvasItem,
	rect: Rect2,
	current_district_1_based: int,
	cleared_count: int,
	district_names: Array[String],
	font: Font
) -> void:
	if canvas == null or rect.size.x < 100.0 or rect.size.y < 100.0:
		return
	canvas.draw_rect(rect, COL_BG, true)

	var river: PackedVector2Array = PackedVector2Array([
		_pt(rect, 0.48, 0.0), _pt(rect, 0.52, 0.26), _pt(rect, 0.45, 0.54),
		_pt(rect, 0.53, 0.78), _pt(rect, 0.46, 1.0),
	])
	canvas.draw_polyline(river, COL_PARK, maxf(18.0, rect.size.x * 0.032), true)
	canvas.draw_circle(_pt(rect, 0.30, 0.46), rect.size.y * 0.11, COL_RIVER)
	canvas.draw_circle(_pt(rect, 0.68, 0.23), rect.size.y * 0.09, COL_RIVER)

	for i in range(COORDS.size()):
		var c: Vector2 = _pt(rect, COORDS[i].x, COORDS[i].y)
		for b in range(5):
			var ang: float = float(i * 5 + b) * 1.18
			var off: Vector2 = Vector2(cos(ang) * 28.0, sin(ang) * 18.0)
			canvas.draw_rect(Rect2(c + off - Vector2(10.0, 6.0), Vector2(20.0, 12.0)), COL_BLOCK, true)

	for i in range(COORDS.size() - 1):
		var p0: Vector2 = _pt(rect, COORDS[i].x, COORDS[i].y)
		var p1: Vector2 = _pt(rect, COORDS[i + 1].x, COORDS[i + 1].y)
		var mid: Vector2 = (p0 + p1) * 0.5 + Vector2(0.0, 11.0 if (i % 2 == 0) else -11.0)
		var lit: bool = (i + 1) <= cleared_count
		canvas.draw_polyline(PackedVector2Array([p0, mid, p1]), COL_ROAD_LIT if lit else Color(COL_ROAD_DIM, 0.55), 2.2 if lit else 1.4, true)

	for i in range(COORDS.size()):
		var idx: int = i + 1
		var c: Vector2 = _pt(rect, COORDS[i].x, COORDS[i].y)
		var cleared: bool = idx <= cleared_count
		var cur: bool = idx == current_district_1_based
		var pct: int = 100 if cleared else (35 if cur else 0)

		if cleared or cur:
			var r_glow: float = 38.0 if cleared else 28.0
			canvas.draw_circle(c, r_glow, Color(COL_AMBER, 0.14 if cleared else 0.10))
			canvas.draw_circle(c, r_glow * 0.55, Color(COL_AMBER, 0.24))

		var fill: Color = COL_AMBER if cleared else (COL_BLOCK if cur else COL_RIVER)
		canvas.draw_circle(c, 10.0, fill)
		canvas.draw_arc(c, 10.0, 0.0, TAU, 24, COL_AMBER if (cleared or cur) else COL_ROAD_DIM, 1.6, true)
		if cur:
			canvas.draw_arc(c, 16.0, 0.0, TAU, 28, COL_AMBER, 1.8, true)

		if font != null:
			var nm: String = district_names[i] if i < district_names.size() else ("D%02d" % idx)
			canvas.draw_string(font, c + Vector2(-32.0, 24.0), nm, HORIZONTAL_ALIGNMENT_LEFT, 130.0, 11, COL_IVORY)
			canvas.draw_string(font, c + Vector2(-12.0, 36.0), "%d%%" % pct, HORIZONTAL_ALIGNMENT_LEFT, 48.0, 10, COL_AMBER if pct > 0 else COL_ROAD_DIM)


static func _pt(r: Rect2, nx: float, ny: float) -> Vector2:
	return Vector2(r.position.x + r.size.x * nx, r.position.y + r.size.y * ny)
