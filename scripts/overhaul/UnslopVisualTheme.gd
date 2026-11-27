class_name UnslopVisualTheme
extends RefCounted

## Style-locked Anti-Slop UI, Cartography & Moonlight Atmosphere Toolkit for Last Streetlight.
## Zero external image assets; keeps active repository strictly within <= 45.00 MiB.

const COL_BG_GLASS: Color = Color(0.031, 0.055, 0.071, 0.58)
const COL_BG_MODAL_BACKDROP: Color = Color(0.016, 0.035, 0.047, 0.84)
const COL_SLATE: Color = Color(0.086, 0.133, 0.161, 1.0)
const COL_BRASS: Color = Color(0.788, 0.635, 0.290, 1.0)
const COL_BRASS_EDGE: Color = Color(0.788, 0.635, 0.290, 0.28)
const COL_AMBER: Color = Color(0.831, 0.663, 0.306, 1.0)
const COL_MOON: Color = Color(0.427, 0.553, 0.651, 1.0)
const COL_STEALTH_CALM: Color = Color(0.322, 0.427, 0.478, 1.0)
const COL_STEALTH_CHASE: Color = Color(0.651, 0.227, 0.212, 1.0)
const COL_MAP_BG: Color = Color(0.027, 0.055, 0.071, 1.0)
const COL_MAP_STREET: Color = Color(0.090, 0.141, 0.173, 1.0)
const COL_MAP_BLDG_FILL: Color = Color(0.051, 0.082, 0.102, 1.0)
const COL_MAP_BLDG_EDGE: Color = Color(0.333, 0.451, 0.510, 1.0)

const LEGEND_DISTRICT_RU: String = "Свет — разведано | Контуры — здания | Стрелка — вы (враги и предметы скрыты)"
const LEGEND_DISTRICT_EN: String = "Light — explored | Outlines — buildings | Arrow — you (enemies & items hidden)"
const LEGEND_CITY_RU: String = "Янтарный — пройден | Кольцо — вы здесь | Тёмный — закрыт"
const LEGEND_CITY_EN: String = "Amber — cleared | Ring — you are here | Dark — locked"


static func make_glass_panel(accent_left: bool = false, radius: int = 4) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = COL_BG_GLASS
	sb.border_color = COL_BRASS_EDGE
	sb.border_width_left = 2 if accent_left else 1
	sb.border_width_right = 0 if accent_left else 1
	sb.border_width_top = 0 if accent_left else 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_size = 6
	return sb


static func make_toast_panel() -> StyleBoxFlat:
	var sb: StyleBoxFlat = make_glass_panel(true, 3)
	sb.bg_color = Color(0.031, 0.063, 0.082, 0.84)
	sb.border_color = COL_BRASS
	sb.border_width_left = 3
	sb.border_width_bottom = 0
	return sb


static func visibility_bar_color(ratio: float) -> Color:
	var r: float = 0.0 if (is_nan(ratio) or is_inf(ratio)) else clampf(ratio, 0.0, 1.0)
	if r < 0.45:
		return COL_STEALTH_CALM.lerp(COL_AMBER, r / 0.45)
	return COL_AMBER.lerp(COL_STEALTH_CHASE, (r - 0.45) / 0.55)


static func draw_corner_ticks(canvas: CanvasItem, rect: Rect2, tick_len: float = 6.0, col: Color = COL_BRASS) -> void:
	if canvas == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var l: float = minf(tick_len, minf(rect.size.x, rect.size.y) * 0.25)
	var x0: float = rect.position.x
	var y0: float = rect.position.y
	var x1: float = rect.position.x + rect.size.x
	var y1: float = rect.position.y + rect.size.y
	# The eight corner ticks used to be eight draw_line calls, and both maps
	# frame every panel with them: one draw_multiline carries the whole set.
	var ticks := PackedVector2Array([
		Vector2(x0, y0), Vector2(x0 + l, y0),
		Vector2(x0, y0), Vector2(x0, y0 + l),
		Vector2(x1, y0), Vector2(x1 - l, y0),
		Vector2(x1, y0), Vector2(x1, y0 + l),
		Vector2(x0, y1), Vector2(x0 + l, y1),
		Vector2(x0, y1), Vector2(x0, y1 - l),
		Vector2(x1, y1), Vector2(x1 - l, y1),
		Vector2(x1, y1), Vector2(x1, y1 - l),
	])
	canvas.draw_multiline(ticks, col, 1.5, true)


static func draw_eye_icon(canvas: CanvasItem, center: Vector2, radius: float, col: Color = COL_BRASS) -> void:
	if canvas == null or radius <= 1.0:
		return
	var pts_top: PackedVector2Array = PackedVector2Array()
	var pts_bot: PackedVector2Array = PackedVector2Array()
	for i in range(9):
		var t: float = float(i) / 8.0
		var x: float = lerpf(-radius, radius, t)
		var arch: float = sin(t * PI) * radius * 0.56
		pts_top.append(center + Vector2(x, -arch))
		pts_bot.append(center + Vector2(x, arch))
	# Both lids and the pupil ring in one call: the HUD eye used to cost three
	# draw calls (two polylines and an arc) on top of the bar it sits on.
	var strokes := PackedVector2Array()
	_append_segments(strokes, pts_top)
	_append_segments(strokes, pts_bot)
	var pr: float = radius * 0.28
	var prev: Vector2 = center + Vector2(pr, 0.0)
	for i in range(1, 17):
		var a: float = TAU * float(i) / 16.0
		var p: Vector2 = center + Vector2(cos(a), sin(a)) * pr
		strokes.append(prev)
		strokes.append(p)
		prev = p
	canvas.draw_multiline(strokes, col, 1.5, true)


## Turns a polyline into the flat point pairs draw_multiline expects.
static func _append_segments(out: PackedVector2Array, pts: PackedVector2Array) -> void:
	for i in range(pts.size() - 1):
		out.append(pts[i])
		out.append(pts[i + 1])



static func draw_medkit_icon(canvas: CanvasItem, center: Vector2, half: float, col: Color = COL_BRASS) -> void:
	if canvas == null or half <= 2.0:
		return
	var box: Rect2 = Rect2(center - Vector2(half, half * 0.78), Vector2(half * 2.0, half * 1.56))
	canvas.draw_rect(box, col, false, 1.6)
	var handle: Rect2 = Rect2(center + Vector2(-half * 0.42, -half * 1.05), Vector2(half * 0.84, half * 0.27))
	canvas.draw_rect(handle, col, false, 1.4)
	var arm: float = half * 0.44
	canvas.draw_line(center + Vector2(-arm, 0.0), center + Vector2(arm, 0.0), COL_AMBER, 2.0, true)
	canvas.draw_line(center + Vector2(0.0, -arm), center + Vector2(0.0, arm), COL_AMBER, 2.0, true)


static func draw_lantern_icon(canvas: CanvasItem, center: Vector2, half: float, col: Color = COL_AMBER) -> void:
	if canvas == null or half <= 2.0:
		return
	var cap_top: Vector2 = center + Vector2(0.0, -half * 0.92)
	canvas.draw_arc(cap_top, half * 0.28, PI, TAU, 12, col, 1.5, true)
	var body: Rect2 = Rect2(center + Vector2(-half * 0.48, -half * 0.58), Vector2(half * 0.96, half * 1.18))
	canvas.draw_rect(body, col, false, 1.6)
	canvas.draw_circle(center + Vector2(0.0, 0.04 * half), half * 0.22, Color(col.r, col.g, col.b, 0.85))
	canvas.draw_line(center + Vector2(-half * 0.62, half * 0.66), center + Vector2(half * 0.62, half * 0.66), col, 1.8, true)


static func draw_player_arrow(canvas: CanvasItem, pos: Vector2, yaw_rad: float, size: float = 9.0) -> void:
	if canvas == null or size <= 1.0:
		return
	var fwd: Vector2 = Vector2(-sin(yaw_rad), -cos(yaw_rad)).normalized()
	var right: Vector2 = Vector2(-fwd.y, fwd.x)
	var cone: PackedVector2Array = PackedVector2Array([
		pos,
		pos + (fwd * size * 3.2) + (right * size * 1.65),
		pos + (fwd * size * 3.2) - (right * size * 1.65),
	])
	canvas.draw_colored_polygon(cone, Color(COL_AMBER.r, COL_AMBER.g, COL_AMBER.b, 0.16))
	var tri: PackedVector2Array = PackedVector2Array([
		pos + fwd * size,
		pos - fwd * (size * 0.65) + right * (size * 0.62),
		pos - fwd * (size * 0.30),
		pos - fwd * (size * 0.65) - right * (size * 0.62),
	])
	canvas.draw_colored_polygon(tri, COL_AMBER)


static func paint_soft_fog_circle(img: Image, cx: int, cy: int, radius_px: float) -> void:
	if img == null or radius_px <= 0.5:
		return
	var w: int = img.get_width()
	var h: int = img.get_height()
	var r_ceil: int = int(ceilf(radius_px))
	var x_min: int = maxi(0, cx - r_ceil)
	var x_max: int = mini(w - 1, cx + r_ceil)
	var y_min: int = maxi(0, cy - r_ceil)
	var y_max: int = mini(h - 1, cy + r_ceil)
	for y in range(y_min, y_max + 1):
		var dy: float = float(y - cy)
		for x in range(x_min, x_max + 1):
			var dx: float = float(x - cx)
			var d: float = sqrt(dx * dx + dy * dy) / radius_px
			if d >= 1.0:
				continue
			var falloff: float = clampf(1.0 - d * d * (3.0 - 2.0 * d), 0.0, 1.0)
			var cur: float = img.get_pixel(x, y).r
			if falloff > cur:
				img.set_pixel(x, y, Color(falloff, falloff, falloff, 1.0))


static func get_map_legend(is_city_tab: bool) -> String:
	var is_ru: bool = TranslationServer.get_locale().to_lower().begins_with("ru")
	if is_city_tab:
		return LEGEND_CITY_RU if is_ru else LEGEND_CITY_EN
	return LEGEND_DISTRICT_RU if is_ru else LEGEND_DISTRICT_EN


static func set_modal_isolated(hud_nodes: Array, modal_open: bool) -> void:
	for n in hud_nodes:
		if is_instance_valid(n) and (n is CanvasItem or n is CanvasLayer):
			n.visible = not modal_open


static func apply_cinematic_night_env(world_env: WorldEnvironment) -> void:
	if world_env == null or world_env.environment == null:
		return
	var env: Environment = world_env.environment
	env.ambient_light_color = Color(0.094, 0.173, 0.231, 1.0)
	env.ambient_light_energy = 1.30
	env.ambient_light_sky_contribution = 0.68
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.28
	env.fog_enabled = true
	env.fog_light_color = Color(0.047, 0.094, 0.129, 1.0)
	env.fog_density = 0.009
	env.fog_depth_begin = 9.0
	# The lamp halos are additive quads, not lights: without a bloom they stay
	# one pixel wide at distance and the street reads as a black void with a
	# row of dots. The glow is what turns them into sodium discs.
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.95
	env.glow_intensity = 0.45
	env.glow_bloom = 0.14
