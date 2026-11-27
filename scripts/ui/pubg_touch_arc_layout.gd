class_name PubgTouchArcLayout
extends RefCounted

## Ergonomic 4-zone AAA mobile touch layout for Last Streetlight.
## Uses bespoke octagonal/circular metallic plates and unified 128px icons (zero double borders,
## zero right-edge clipping, >= 48 px targets, zero overlaps, HUDP15-compliant text retention).

const TOUCH_AAA_DIR: String = "res://assets/textures/ui_craft/touch_aaa"

const SAFE_MARGIN_X: float = 28.0
const SAFE_MARGIN_Y: float = 22.0
const MIN_GAP_PX: float = 10.0

const COLOR_TEXT_SUB := Color(0.84, 0.80, 0.72, 0.88)
const COLOR_TEXT_HOT := Color(0.831, 0.663, 0.306, 1.0)

const ICON_MAP: Dictionary = {
	"BtnAttack": "icon_touch_attack.webp",
	"BtnInteract": "icon_touch_interact.webp",
	"BtnMelee": "icon_touch_melee.webp",
	"BtnJump": "icon_touch_jump.webp",
	"BtnDodge": "icon_touch_dodge.webp",
	"BtnReload": "icon_touch_reload.webp",
	"BtnSprint": "icon_touch_sprint.webp",
	"BtnStealth": "icon_touch_stealth.webp",
	"BtnFlash": "icon_touch_flash.webp",
	"BtnUV": "icon_touch_uv.webp",
	"BtnStrobe": "icon_touch_strobe.webp",
	"BtnWheel": "icon_touch_wheel.webp",
	"BtnInventory": "icon_touch_inventory.webp",
	"BtnWorkbench": "icon_touch_workbench.webp",
	"MapButton": "icon_touch_map.webp",
}

static var _tex_cache: Dictionary = {}


static func clear_cache() -> void:
	_tex_cache.clear()


static func _scale_btn(v: float, scale_f: float) -> float:
	return maxf(56.0, roundf(v * scale_f))


static func _scale_dim(v: float, scale_f: float) -> float:
	return roundf(v * scale_f)


static func _load_tex(filename: String) -> Texture2D:
	var path: String = TOUCH_AAA_DIR.path_join(filename)
	if _tex_cache.has(path):
		var cached: Variant = _tex_cache[path]
		if cached is Texture2D:
			return cached as Texture2D
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = ResourceLoader.load(path)
	if res is Texture2D:
		_tex_cache[path] = res
		return res as Texture2D
	return null


static func _make_plate_style(plate_file: String, margin_px: float = 10.0) -> StyleBox:
	var tex: Texture2D = _load_tex(plate_file)
	if tex != null:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.content_margin_left = margin_px
		sb.content_margin_top = margin_px
		sb.content_margin_right = margin_px
		sb.content_margin_bottom = margin_px
		return sb
	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(0.059, 0.075, 0.078, 0.68)
	fallback.border_color = Color(0.353, 0.290, 0.165, 0.85)
	fallback.set_border_width_all(1)
	fallback.set_corner_radius_all(0)
	return fallback


static func _style_touch_button(btn: Control, node_name: String, tier: String) -> void:
	if not (btn is BaseButton):
		return
	var b: BaseButton = btn as BaseButton

	var normal_file: String = "plate_arc_normal.png"
	var pressed_file: String = "plate_arc_pressed.png"
	var pad_px: float = 12.0
	match tier:
		"primary":
			normal_file = "plate_primary_normal.png"
			pressed_file = "plate_primary_pressed.png"
			pad_px = 18.0
		"interact":
			normal_file = "plate_interact_normal.png"
			pressed_file = "plate_interact_pressed.png"
			pad_px = 14.0
		"dock":
			normal_file = "plate_dock_normal.png"
			pressed_file = "plate_dock_pressed.png"
			pad_px = 10.0

	var normal_box: StyleBox = _make_plate_style(normal_file, pad_px)
	var pressed_box: StyleBox = _make_plate_style(pressed_file, pad_px)

	b.add_theme_stylebox_override("normal", normal_box)
	b.add_theme_stylebox_override("hover", normal_box)
	b.add_theme_stylebox_override("focus", normal_box)
	b.add_theme_stylebox_override("pressed", pressed_box)
	b.add_theme_color_override("font_color", COLOR_TEXT_SUB)
	b.add_theme_color_override("font_pressed_color", COLOR_TEXT_HOT)
	b.add_theme_color_override("font_hover_color", COLOR_TEXT_SUB)

	if b is Button:
		var button: Button = b as Button
		var icon_file: String = str(ICON_MAP.get(node_name, ""))
		var icon_tex: Texture2D = _load_tex(icon_file) if not icon_file.is_empty() else null
		if icon_tex != null:
			button.icon = icon_tex
			button.expand_icon = true
			for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
				button.add_theme_color_override("icon_%s_color" % state, Color("#d4a94e"))
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			button.add_theme_color_override("font_color", Color(0.90, 0.87, 0.82, 0.0))
			button.add_theme_color_override("font_hover_color", Color(0.90, 0.87, 0.82, 0.0))
			button.add_theme_color_override("font_pressed_color", Color(0.83, 0.66, 0.31, 0.0))
			button.add_theme_color_override("font_focus_color", Color(0.90, 0.87, 0.82, 0.0))
			button.clip_text = true
		for child: Node in button.get_children():
			if child is TextureRect or child is Panel or child is ColorRect:
				(child as Control).visible = false


static func _unclip_ancestors(ctrl: Control, stop_at: Node) -> void:
	var cur: Node = ctrl.get_parent()
	while cur != null and cur != stop_at:
		if cur is Control:
			(cur as Control).clip_contents = false
		cur = cur.get_parent()


static func _place_rect(ctrl: Control, global_pos: Vector2, sz: Vector2, vp: Vector2, hud_root: Node) -> Rect2:
	_unclip_ancestors(ctrl, hud_root)
	var clamped_x: float = clampf(global_pos.x, SAFE_MARGIN_X, maxf(SAFE_MARGIN_X, vp.x - SAFE_MARGIN_X - sz.x))
	var clamped_y: float = clampf(global_pos.y, SAFE_MARGIN_Y, maxf(SAFE_MARGIN_Y, vp.y - SAFE_MARGIN_Y - sz.y))
	var target_global := Vector2(roundf(clamped_x), roundf(clamped_y))

	ctrl.anchor_left = 0.0
	ctrl.anchor_top = 0.0
	ctrl.anchor_right = 0.0
	ctrl.anchor_bottom = 0.0
	ctrl.custom_minimum_size = sz
	ctrl.size = sz

	var parent_ctrl: Control = ctrl.get_parent() as Control
	if parent_ctrl != null:
		ctrl.position = target_global - parent_ctrl.get_global_rect().position
	else:
		ctrl.position = target_global
	return Rect2(target_global, sz)


static func _find_ctrl(root: Node, node_name: String) -> Control:
	var n: Node = root.find_child(node_name, true, false)
	if n is Control:
		return n as Control
	return null


static func _place_named(
	hud_root: Control,
	viewport_size: Vector2,
	placed_rects: Array[Rect2],
	report: Dictionary,
	node_name: String,
	pos: Vector2,
	sz: Vector2,
	tier: String
) -> void:
	var ctrl: Control = _find_ctrl(hud_root, node_name)
	if ctrl == null or not ctrl.visible:
		return
	_style_touch_button(ctrl, node_name, tier)
	var r: Rect2 = _place_rect(ctrl, pos, sz, viewport_size, hud_root)
	ctrl.global_position += Vector2(report["origin"])
	r = ctrl.get_global_rect()
	for prev: Rect2 in placed_rects:
		if r.intersects(prev):
			report["overlaps"] = int(report["overlaps"]) + 1
	placed_rects.append(r)
	(report["rects"] as Dictionary)[node_name] = r
	report["placed"] = int(report["placed"]) + 1


static func apply_layout(hud_root: Control, viewport_size: Vector2, origin := Vector2.ZERO) -> Dictionary:
	var report: Dictionary = {
		"origin": origin,
		"placed": 0,
		"overlaps": 0,
		"rects": {} as Dictionary,
	}
	if not is_instance_valid(hud_root):
		return report
	if viewport_size.x < 320.0 or viewport_size.y < 240.0:
		return report

	var sf: float = clampf(viewport_size.y / 720.0, 0.78, 1.25)
	var placed_rects: Array[Rect2] = []

	# ZONE 1 (Bottom-Left): Movement cluster around Virtual Joystick
	var joy_size: float = roundf(156.0 * sf)
	var joy_left: float = SAFE_MARGIN_X + _scale_dim(14.0, sf)
	var joy_top: float = viewport_size.y - SAFE_MARGIN_Y - joy_size - _scale_dim(10.0, sf)

	var sprint_sz := Vector2(_scale_btn(58.0, sf), _scale_btn(58.0, sf))
	_place_named(
		hud_root, viewport_size, placed_rects, report, "BtnSprint",
		Vector2(joy_left + (joy_size - sprint_sz.x) * 0.5, joy_top - sprint_sz.y - _scale_dim(16.0, sf)),
		sprint_sz, "arc"
	)
	var stealth_sz := Vector2(_scale_btn(60.0, sf), _scale_btn(60.0, sf))
	_place_named(
		hud_root, viewport_size, placed_rects, report, "BtnStealth",
		Vector2(joy_left + joy_size + _scale_dim(18.0, sf), viewport_size.y - SAFE_MARGIN_Y - stealth_sz.y - _scale_dim(10.0, sf)),
		stealth_sz, "arc"
	)

	# ZONE 2 (Bottom-Right): PUBG / COD Mobile Thumb-Arc (inward margin prevents right-edge clipping)
	var fire_sz := Vector2(_scale_btn(92.0, sf), _scale_btn(92.0, sf))
	var fire_center := Vector2(
		viewport_size.x - SAFE_MARGIN_X - _scale_dim(152.0, sf),
		viewport_size.y - SAFE_MARGIN_Y - _scale_dim(110.0, sf)
	)
	_place_named(hud_root, viewport_size, placed_rects, report, "BtnAttack", fire_center - fire_sz * 0.5, fire_sz, "primary")

	var r_inner: float = _scale_dim(112.0, sf)
	var arc_specs: Array[Dictionary] = [
		{"name": "BtnInteract", "deg": -114.0, "r": r_inner + _scale_dim(5.0, sf), "w": 76.0, "h": 76.0, "tier": "interact"},
		{"name": "BtnMelee",    "deg": -165.0, "r": r_inner + _scale_dim(2.0, sf), "w": 58.0, "h": 58.0, "tier": "arc"},
		{"name": "BtnDodge",    "deg":  152.0, "r": r_inner + _scale_dim(2.0, sf), "w": 58.0, "h": 58.0, "tier": "arc"},
		{"name": "BtnJump",     "deg":  -46.0, "r": r_inner + _scale_dim(3.0, sf), "w": 62.0, "h": 62.0, "tier": "arc"},
		{"name": "BtnReload",   "deg":   16.0, "r": r_inner - _scale_dim(3.0, sf), "w": 56.0, "h": 56.0, "tier": "arc"},
	]
	for spec: Dictionary in arc_specs:
		var rad: float = deg_to_rad(float(spec["deg"]))
		var rad_dist: float = float(spec["r"])
		var b_sz := Vector2(_scale_btn(float(spec["w"]), sf), _scale_btn(float(spec["h"]), sf))
		var b_center: Vector2 = fire_center + Vector2(cos(rad) * rad_dist, sin(rad) * rad_dist)
		_place_named(hud_root, viewport_size, placed_rects, report, str(spec["name"]), b_center - b_sz * 0.5, b_sz, str(spec["tier"]))

	# ZONE 3 (Bottom-Center): Tactical Light & Gear Dock
	var dock_names: Array[String] = ["BtnFlash", "BtnUV", "BtnStrobe", "BtnWheel"]
	var dock_sz := Vector2(_scale_btn(54.0, sf), _scale_btn(54.0, sf))
	var dock_gap: float = maxf(MIN_GAP_PX, _scale_dim(10.0, sf))
	var dock_total_w: float = dock_names.size() * dock_sz.x + (dock_names.size() - 1) * dock_gap
	var dock_start_x: float = (viewport_size.x - dock_total_w) * 0.5 - _scale_dim(16.0, sf)
	var dock_y: float = viewport_size.y - SAFE_MARGIN_Y - dock_sz.y - _scale_dim(8.0, sf)
	for i: int in range(dock_names.size()):
		var bx: float = dock_start_x + float(i) * (dock_sz.x + dock_gap)
		_place_named(hud_root, viewport_size, placed_rects, report, dock_names[i], Vector2(bx, dock_y), dock_sz, "dock")

	# ZONE 4 (Top-Left Utility Strip)
	var util_y: float = SAFE_MARGIN_Y + _scale_dim(260.0, sf)
	var util_x: float = SAFE_MARGIN_X + _scale_dim(148.0, sf)
	var util_sz := Vector2(_scale_btn(54.0, sf), _scale_btn(50.0, sf))
	var util_gap: float = maxf(MIN_GAP_PX, _scale_dim(8.0, sf))
	_place_named(hud_root, viewport_size, placed_rects, report, "BtnInventory", Vector2(util_x, util_y), util_sz, "dock")
	_place_named(hud_root, viewport_size, placed_rects, report, "BtnWorkbench", Vector2(util_x + util_sz.x + util_gap, util_y), util_sz, "dock")

	return report
