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
const COL_PERCENT := Color(0.60, 0.54, 0.42)
const COL_IVORY: Color = Color("#e6dfd1")

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
	return I18nSync.t("MAP_LEGEND_CITY" if is_city_tab else "MAP_LEGEND_DISTRICT")


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
	progress: Array[int],
	district_names: Array[String],
	font: Font
) -> void:
	if canvas == null or rect.size.x < 100.0 or rect.size.y < 100.0:
		return

	# 1. Dark map parchment base
	canvas.draw_rect(rect, COL_BG, true)

	# 2. Organic river ribbon winding diagonally through the city
	var river_pts: PackedVector2Array = PackedVector2Array([
		_pt(rect, 0.48, 0.035), _pt(rect, 0.52, 0.25), _pt(rect, 0.45, 0.52),
		_pt(rect, 0.53, 0.78), _pt(rect, 0.46, 0.965),
	])
	canvas.draw_polyline(_round_corners(river_pts), COL_RIVER, maxf(18.0, rect.size.x * 0.032), true)

	# 3. Park green-slate organic blobs
	canvas.draw_circle(_pt(rect, 0.30, 0.45), rect.size.y * 0.11, COL_PARK)
	canvas.draw_circle(_pt(rect, 0.68, 0.24), rect.size.y * 0.09, COL_PARK)

	# 4. Subtle city block rectangles along districts
	for i in range(COORDS.size()):
		var c: Vector2 = _pt(rect, COORDS[i].x, COORDS[i].y)
		for b in range(4):
			var ang: float = float(i * 3 + b) * 1.15
			var off: Vector2 = Vector2(cos(ang) * 26.0, sin(ang) * 18.0)
			canvas.draw_rect(Rect2(c + off - Vector2(10.0, 6.0), Vector2(20.0, 12.0)), COL_BLOCK, true)

	# 5. Connecting arterial roads (lit amber between restored districts, dim slate for unlit)
	for i in range(COORDS.size() - 1):
		var p0: Vector2 = _pt(rect, COORDS[i].x, COORDS[i].y)
		var p1: Vector2 = _pt(rect, COORDS[i + 1].x, COORDS[i + 1].y)
		var mid: Vector2 = (p0 + p1) * 0.5 + Vector2(0.0, 12.0 if (i % 2 == 0) else -12.0)
		var is_lit: bool = progress[i] == 100 and progress[i + 1] > 0
		var road_col: Color = COL_ROAD_LIT if is_lit else COL_ROAD_DIM
		canvas.draw_polyline(_round_corners(PackedVector2Array([p0, mid, p1])), road_col, 2.2 if is_lit else 1.5, true)

	# 6. District nodes with warm amber glow pools + restoration %
	for i in range(COORDS.size()):
		var idx: int = i + 1
		var c: Vector2 = _pt(rect, COORDS[i].x, COORDS[i].y)
		var pct: int = progress[i]
		var is_cleared: bool = pct == 100
		var is_cur: bool = idx == current_district_1_based

		if is_cleared or is_cur:
			var glow_r: float = 34.0 if is_cleared else 26.0
			canvas.draw_circle(c, glow_r, Color(COL_AMBER.r, COL_AMBER.g, COL_AMBER.b, 0.14 if is_cleared else 0.10))
			canvas.draw_circle(c, glow_r * 0.58, Color(COL_AMBER.r, COL_AMBER.g, COL_AMBER.b, 0.22))

		var fill_c: Color = COL_AMBER if is_cleared else (Color(0.22, 0.29, 0.34, 1.0) if is_cur else Color(0.09, 0.13, 0.16, 1.0))
		canvas.draw_circle(c, 10.5, fill_c)
		canvas.draw_arc(c, 10.5, 0.0, TAU, 24, COL_AMBER if (is_cleared or is_cur) else COL_ROAD_DIM, 1.6, true)
		if is_cur:
			canvas.draw_arc(c, 16.0, 0.0, TAU, 28, COL_AMBER, 1.8, true)

		if font != null:
			var label: String = district_names[i] if i < district_names.size() else ("D%02d" % idx)
			var sub: String = "%d%%" % pct
			var label_width := rect.size.x * 0.22
			var font_size := 13
			while font_size > 9 and font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label_width:
				font_size -= 1
			canvas.draw_string(font, c + Vector2(-label_width * 0.5, 26), label,
				HORIZONTAL_ALIGNMENT_CENTER, label_width, font_size, COL_IVORY)
			canvas.draw_string(font, c + Vector2(-24, 40), sub,
				HORIZONTAL_ALIGNMENT_CENTER, 48, 11, COL_AMBER if pct > 0 else COL_PERCENT)


static func _pt(r: Rect2, nx: float, ny: float) -> Vector2:
	return Vector2(r.position.x + r.size.x * nx, r.position.y + r.size.y * ny)


static func _round_corners(points: PackedVector2Array) -> PackedVector2Array:
	for _pass_idx in 3:
		var refined := PackedVector2Array([points[0]])
		for i in points.size() - 1:
			refined.append(points[i].lerp(points[i + 1], 0.24))
			refined.append(points[i].lerp(points[i + 1], 0.76))
		refined.append(points[-1])
		points = refined
	return points
