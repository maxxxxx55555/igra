class_name OrganicCityMapRenderer
extends RefCounted

## Procedural Organic City Map Painter modeled directly on the concept sheet ("КАРТА ГОРОДА"):
## Curved main avenues, dark river & park zones, city blocks, warm amber illumination pools
## for restored districts, percentage restoration labels, and zero enemy/item markers.

const COL_BG: Color = Color(0.031, 0.047, 0.055, 1.0)
const COL_RIVER: Color = Color(0.024, 0.066, 0.086, 1.0)
const COL_PARK: Color = Color(0.048, 0.082, 0.064, 1.0)
const COL_BLOCK: Color = Color(0.062, 0.084, 0.096, 1.0)
const COL_ROAD_DIM: Color = Color(0.145, 0.188, 0.212, 0.65)
const COL_ROAD_LIT: Color = Color(0.788, 0.635, 0.290, 0.72)
const COL_AMBER: Color = Color(0.855, 0.678, 0.302, 1.0)
const COL_SLATE_TEXT: Color = Color(0.76, 0.80, 0.82, 0.90)

# Organic normalized (0..1) coordinates for the 11 city districts (no artificial zigzag!)
const DISTRICT_COORDS: Array[Vector2] = [
	Vector2(0.14, 0.22), # 01 Outskirts Yard
	Vector2(0.28, 0.34), # 02 Wet Alleys
	Vector2(0.18, 0.56), # 03 Tram Depot
	Vector2(0.39, 0.21), # 04 Frost Promenade
	Vector2(0.42, 0.48), # 05 Foggy Canal
	Vector2(0.36, 0.73), # 06 Old Market
	Vector2(0.56, 0.62), # 07 Substation 7
	Vector2(0.62, 0.28), # 08 Silent Clinic
	Vector2(0.76, 0.42), # 09 Tenement Blocks
	Vector2(0.72, 0.74), # 10 Blackout Station
	Vector2(0.86, 0.62), # 11 Last Streetlight Plaza
]


static func draw_organic_city_map(
	canvas: CanvasItem,
	rect: Rect2,
	current_district_1_based: int,
	cleared_count: int,
	district_names: Array[String],
	font: Font
) -> void:
	if canvas == null or rect.size.x < 100.0 or rect.size.y < 100.0:
		return

	# 1. Dark map parchment base
	canvas.draw_rect(rect, COL_BG, true)

	# 2. Organic river ribbon winding diagonally through the city
	var river_pts: PackedVector2Array = PackedVector2Array([
		_pt(rect, 0.48, 0.0), _pt(rect, 0.52, 0.25), _pt(rect, 0.45, 0.52),
		_pt(rect, 0.53, 0.78), _pt(rect, 0.46, 1.0),
	])
	canvas.draw_polyline(river_pts, COL_RIVER, maxf(18.0, rect.size.x * 0.032), true)

	# 3. Park green-slate organic blobs
	canvas.draw_circle(_pt(rect, 0.30, 0.45), rect.size.y * 0.11, COL_PARK)
	canvas.draw_circle(_pt(rect, 0.68, 0.24), rect.size.y * 0.09, COL_PARK)

	# 4. Subtle city block rectangles along districts
	for i in range(DISTRICT_COORDS.size()):
		var c: Vector2 = _pt(rect, DISTRICT_COORDS[i].x, DISTRICT_COORDS[i].y)
		for b in range(4):
			var ang: float = float(i * 3 + b) * 1.15
			var off: Vector2 = Vector2(cos(ang) * 26.0, sin(ang) * 18.0)
			canvas.draw_rect(Rect2(c + off - Vector2(10.0, 6.0), Vector2(20.0, 12.0)), COL_BLOCK, true)

	# 5. Connecting arterial roads (lit amber between restored districts, dim slate for unlit)
	for i in range(DISTRICT_COORDS.size() - 1):
		var p0: Vector2 = _pt(rect, DISTRICT_COORDS[i].x, DISTRICT_COORDS[i].y)
		var p1: Vector2 = _pt(rect, DISTRICT_COORDS[i + 1].x, DISTRICT_COORDS[i + 1].y)
		var mid: Vector2 = (p0 + p1) * 0.5 + Vector2(0.0, 12.0 if (i % 2 == 0) else -12.0)
		var is_lit: bool = (i + 1) <= cleared_count
		var road_col: Color = COL_ROAD_LIT if is_lit else COL_ROAD_DIM
		canvas.draw_polyline(PackedVector2Array([p0, mid, p1]), road_col, 2.2 if is_lit else 1.5, true)

	# 6. District nodes with warm amber glow pools + restoration %
	for i in range(DISTRICT_COORDS.size()):
		var idx: int = i + 1
		var c: Vector2 = _pt(rect, DISTRICT_COORDS[i].x, DISTRICT_COORDS[i].y)
		var is_cleared: bool = idx <= cleared_count
		var is_cur: bool = idx == current_district_1_based
		var pct: int = 100 if is_cleared else (35 if is_cur else 0)

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
			canvas.draw_string(font, c + Vector2(-28.0, 24.0), label, HORIZONTAL_ALIGNMENT_LEFT, 120.0, 11, COL_SLATE_TEXT)
			canvas.draw_string(font, c + Vector2(-12.0, 36.0), sub, HORIZONTAL_ALIGNMENT_LEFT, 48.0, 10, COL_AMBER if pct > 0 else COL_ROAD_DIM)


static func _pt(r: Rect2, nx: float, ny: float) -> Vector2:
	return Vector2(r.position.x + r.size.x * nx, r.position.y + r.size.y * ny)
