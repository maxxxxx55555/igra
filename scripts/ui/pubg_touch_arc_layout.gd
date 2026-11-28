class_name PubgTouchArcLayout
extends RefCounted

## Single-Owner Clean Reference #3 FPP Mobile Touch Layout for Last Streetlight.
## Eliminates every overlap from the legacy 15-button PUBG layout:
##  - Bottom-Left: 1 directional charcoal joystick + compact stat bars beside it (0 buttons colliding).
##  - Bottom-Center: clean hotbar + single backpack (BtnInventory) docked right beside it (0 dock buttons over it).
##  - Bottom-Right: clean 4-button circular charcoal/bronze arc (Interact >= 72px, Flash, Sprint, Stealth >= 56px;
##    Attack only when weapon equipped). Unused legacy clutter buttons stay hidden.
##  - Top-Left middle edge: completely clean (0 floating utility circles; circular radar minimap opens map).

const TOUCH_AAA_DIR: String = "res://assets/textures/ui_craft/touch_aaa"

const SAFE_MARGIN_X: float = 24.0
const SAFE_MARGIN_Y: float = 20.0
const MIN_GAP_PX: float = 10.0

const COL_BG := Color("#0f1314")
const COL_BG_DEEP := Color("#060f13")
const COL_BRONZE := Color("#5a4a2a")
const COL_AMBER := Color("#d4a94e")
const COL_TEXT_SUB := Color("#d8d5cc")
const COL_TEXT_HOT := Color("#d4a94e")

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

const HIDDEN_CLUTTER: Array[String] = [
	"BtnUV", "BtnStrobe", "BtnWheel", "BtnWorkbench",
	"BtnJump", "BtnReload", "BtnMelee", "BtnDodge", "MapButton",
]

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
		var alt := path.replace(".webp", ".png")
		if not ResourceLoader.exists(alt):
			return null
		path = alt
	var res: Resource = ResourceLoader.load(path)
	if res is Texture2D:
		_tex_cache[path] = res
		return res as Texture2D
	return null


static func _make_circle_plate(pressed: bool, primary: bool, pad_px: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(COL_BG_DEEP, 0.90) if pressed else Color(COL_BG, 0.78)
	sb.border_color = COL_AMBER if (pressed or primary) else Color(COL_BRONZE, 0.90)
	sb.set_border_width_all(2 if (pressed or primary) else 1)
	sb.set_corner_radius_all(48)
	sb.content_margin_left = pad_px
	sb.content_margin_top = pad_px
	sb.content_margin_right = pad_px
	sb.content_margin_bottom = pad_px
	return sb


static func _style_touch_button(btn: Control, node_name: String, tier: String) -> void:
	if not (btn is BaseButton):
		return
	var b: BaseButton = btn as BaseButton
	var is_primary: bool = (tier == "primary" or tier == "interact")
	var pad_px: float = 14.0 if is_primary else 10.0

	var normal_box: StyleBox = _make_circle_plate(false, is_primary, pad_px)
	var pressed_box: StyleBox = _make_circle_plate(true, true, pad_px)

	b.add_theme_stylebox_override("normal", normal_box)
	b.add_theme_stylebox_override("hover", normal_box)
	b.add_theme_stylebox_override("focus", normal_box)
	b.add_theme_stylebox_override("pressed", pressed_box)
	b.add_theme_color_override("font_color", COL_TEXT_SUB)
	b.add_theme_color_override("font_pressed_color", COL_TEXT_HOT)
	b.add_theme_color_override("font_hover_color", COL_TEXT_SUB)

	if b is Button:
		var button: Button = b as Button
		var icon_file: String = str(ICON_MAP.get(node_name, ""))
		var icon_tex: Texture2D = _load_tex(icon_file) if not icon_file.is_empty() else null
		if icon_tex != null:
			button.icon = icon_tex
			button.expand_icon = true
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			button.add_theme_color_override("font_color", Color(COL_TEXT_SUB, 0.0))
			button.add_theme_color_override("font_hover_color", Color(COL_TEXT_SUB, 0.0))
			button.add_theme_color_override("font_pressed_color", Color(COL_TEXT_HOT, 0.0))
			button.add_theme_color_override("font_focus_color", Color(COL_TEXT_SUB, 0.0))
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

	# 1. Hide redundant legacy PUBG clutter buttons so ZERO icons collide with stats/hotbar/left edge
	for cname: String in HIDDEN_CLUTTER:
		var cctrl: Control = _find_ctrl(hud_root, cname)
		if cctrl != null:
			cctrl.visible = false

	# 2. Right Thumb Cluster (clean Reference #3 circular bronze buttons, strictly right bottom)
	var interact_sz := Vector2(_scale_btn(76.0, sf), _scale_btn(76.0, sf))
	var anchor_center := Vector2(
		viewport_size.x - SAFE_MARGIN_X - _scale_dim(74.0, sf),
		viewport_size.y - SAFE_MARGIN_Y - _scale_dim(78.0, sf)
	)
	_place_named(hud_root, viewport_size, placed_rects, report, "BtnInteract", anchor_center - interact_sz * 0.5, interact_sz, "interact")

	var flash_sz := Vector2(_scale_btn(60.0, sf), _scale_btn(60.0, sf))
	var flash_pos := anchor_center + Vector2(-_scale_dim(94.0, sf), -_scale_dim(12.0, sf)) - flash_sz * 0.5
	_place_named(hud_root, viewport_size, placed_rects, report, "BtnFlash", flash_pos, flash_sz, "arc")

	var sprint_sz := Vector2(_scale_btn(58.0, sf), _scale_btn(58.0, sf))
	var sprint_pos := anchor_center + Vector2(-_scale_dim(62.0, sf), -_scale_dim(88.0, sf)) - sprint_sz * 0.5
	_place_named(hud_root, viewport_size, placed_rects, report, "BtnSprint", sprint_pos, sprint_sz, "arc")

	var stealth_sz := Vector2(_scale_btn(58.0, sf), _scale_btn(58.0, sf))
	var stealth_pos := anchor_center + Vector2(_scale_dim(14.0, sf), -_scale_dim(96.0, sf)) - stealth_sz * 0.5
	_place_named(hud_root, viewport_size, placed_rects, report, "BtnStealth", stealth_pos, stealth_sz, "arc")

	# Attack button placed cleanly left-of-flash only if visible
	var attack_sz := Vector2(_scale_btn(64.0, sf), _scale_btn(64.0, sf))
	var attack_pos := anchor_center + Vector2(-_scale_dim(170.0, sf), _scale_dim(4.0, sf)) - attack_sz * 0.5
	_place_named(hud_root, viewport_size, placed_rects, report, "BtnAttack", attack_pos, attack_sz, "primary")

	# 3. Backpack/Inventory button cleanly right of bottom-center hotbar (like Ref #3 backpack slot)
	var inv_sz := Vector2(_scale_btn(56.0, sf), _scale_btn(56.0, sf))
	var inv_pos := Vector2(
		viewport_size.x * 0.5 + _scale_dim(196.0, sf),
		viewport_size.y - SAFE_MARGIN_Y - inv_sz.y - _scale_dim(4.0, sf)
	)
	_place_named(hud_root, viewport_size, placed_rects, report, "BtnInventory", inv_pos, inv_sz, "arc")

	return report
