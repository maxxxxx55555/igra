class_name Wave2ComfortableHud
extends Node

## Ergonomic 20:9 Mobile HUD Layout & Brass Styling Hardener (Samsung Galaxy A32 / Mali-G52).
## Enforces comfortable >=54px touch targets, 0px overlap between BottomCenter hotbar & BottomRight buttons,
## removes stale Wi-Fi/Log clutter, and unifies all HUD widgets with main menu brass (#c9a24a) + dark slate (#0f1314).

const COL_BG: Color = Color(0.0588, 0.0745, 0.0784, 0.86)     # #0f1314
const COL_BG_PRESS: Color = Color(0.118, 0.145, 0.153, 0.94)
const COL_BRASS: Color = Color(0.7882, 0.6353, 0.2902, 0.95)  # #c9a24a
const COL_AMBER: Color = Color(0.8314, 0.6627, 0.3059, 1.0)   # #d4a94e
const COL_TEXT: Color = Color(0.902, 0.871, 0.784, 1.0)       # #e6dec8

const MIN_TOUCH_PX: float = 56.0
const PRIMARY_TOUCH_PX: float = 72.0
const BUTTON_GAP_PX: float = 12.0

const REMOVE_TOKENS: Array[String] = ["wifi", "wi-fi", "bonusoffer", "bonus_offer", "debuglog", "btnlog", "logpanel"]

var _hud_root: Node = null
var _tweens: Array[Tween] = []


func _ready() -> void:
	_hud_root = get_parent()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(apply_comfortable_layout):
		get_viewport().size_changed.connect(apply_comfortable_layout)
	call_deferred("apply_comfortable_layout")


func _exit_tree() -> void:
	for tw in _tweens:
		if is_instance_valid(tw):
			tw.kill()
	_tweens.clear()


func apply_comfortable_layout() -> void:
	if not is_instance_valid(_hud_root) or get_viewport() == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var left_pad: float = maxf(20.0, float(safe.position.x)) if safe.size.x > 0 else 20.0
	var top_pad: float = maxf(14.0, float(safe.position.y)) if safe.size.y > 0 else 14.0
	var right_pad: float = maxf(20.0, vp.x - float(safe.position.x + safe.size.x)) if safe.size.x > 0 else 20.0
	var bottom_pad: float = maxf(18.0, vp.y - float(safe.position.y + safe.size.y)) if safe.size.y > 0 else 18.0

	_purge_clutter_nodes(_hud_root)
	_style_all_buttons(_hud_root)

	# Anchor Bottom-Right Action Cluster cleanly inside right 25% without invading BottomCenter
	var btn_interact: Control = _find_control_ci(_hud_root, ["btninteract", "interactbutton", "interact"])
	var btn_attack: Control = _find_control_ci(_hud_root, ["btnattack", "btnflashlight", "flashlightbutton", "attack"])
	var btn_sprint: Control = _find_control_ci(_hud_root, ["btnsprint", "sprintbutton", "sprint"])
	var btn_stealth: Control = _find_control_ci(_hud_root, ["btnstealth", "btncrouch", "stealthbutton", "stealth"])
	var btn_pause: Control = _find_control_ci(_hud_root, ["btnpause", "pausebutton", "pause"])
	var bottom_center: Control = _find_control_ci(_hud_root, ["bottomcenter", "hotbar", "itembar", "quickslots"])
	var bottom_left: Control = _find_control_ci(_hud_root, ["bottomleft", "joystick", "virtualjoystick", "movejoystick"])

	if btn_pause != null:
		btn_pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		btn_pause.custom_minimum_size = Vector2(MIN_TOUCH_PX, MIN_TOUCH_PX)
		btn_pause.size = Vector2(MIN_TOUCH_PX, MIN_TOUCH_PX)
		btn_pause.position = Vector2(vp.x - right_pad - MIN_TOUCH_PX, top_pad)

	var anchor_rx: float = vp.x - right_pad - PRIMARY_TOUCH_PX
	var anchor_ry: float = vp.y - bottom_pad - PRIMARY_TOUCH_PX

	if btn_interact != null:
		_place_button(btn_interact, Vector2(anchor_rx, anchor_ry), Vector2(PRIMARY_TOUCH_PX, PRIMARY_TOUCH_PX))
	if btn_attack != null:
		_place_button(btn_attack, Vector2(anchor_rx - MIN_TOUCH_PX - BUTTON_GAP_PX, anchor_ry + 8.0), Vector2(MIN_TOUCH_PX, MIN_TOUCH_PX))
	if btn_sprint != null:
		_place_button(btn_sprint, Vector2(anchor_rx + 8.0, anchor_ry - MIN_TOUCH_PX - BUTTON_GAP_PX), Vector2(MIN_TOUCH_PX, MIN_TOUCH_PX))
	if btn_stealth != null:
		_place_button(btn_stealth, Vector2(anchor_rx - MIN_TOUCH_PX - BUTTON_GAP_PX, anchor_ry - MIN_TOUCH_PX - BUTTON_GAP_PX), Vector2(MIN_TOUCH_PX, MIN_TOUCH_PX))

	var left_clear_x: float = left_pad + 172.0
	if bottom_left != null:
		bottom_left.position = Vector2(left_pad, vp.y - bottom_pad - maxf(140.0, bottom_left.size.y))
		left_clear_x = bottom_left.position.x + maxf(152.0, bottom_left.size.x) + 24.0

	var right_clear_x: float = anchor_rx - MIN_TOUCH_PX - BUTTON_GAP_PX - 24.0
	if bottom_center != null:
		var avail_w: float = maxf(240.0, right_clear_x - left_clear_x)
		var target_w: float = minf(avail_w, 348.0)
		var target_h: float = 58.0
		var center_x: float = left_clear_x + (avail_w - target_w) * 0.5
		bottom_center.set_anchors_preset(Control.PRESET_TOP_LEFT)
		bottom_center.position = Vector2(center_x, vp.y - bottom_pad - target_h)
		bottom_center.size = Vector2(target_w, target_h)


func _place_button(ctrl: Control, pos: Vector2, sz: Vector2) -> void:
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.custom_minimum_size = sz
	ctrl.size = sz
	ctrl.position = pos


func _purge_clutter_nodes(root: Node) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if not is_instance_valid(cur):
			continue
		var ln: String = cur.name.to_lower()
		var is_clutter: bool = false
		for tok in REMOVE_TOKENS:
			if ln.contains(tok):
				is_clutter = true
				break
		if is_clutter and cur != root:
			cur.visible = false
			if cur is Control:
				(cur as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
			continue
		for ch in cur.get_children():
			stack.append(ch)


func _style_all_buttons(root: Node) -> void:
	var norm_sb: StyleBoxFlat = _make_box(COL_BG, COL_BRASS, 2, 8)
	var hov_sb: StyleBoxFlat = _make_box(COL_BG_PRESS, COL_AMBER, 2, 8)
	var prs_sb: StyleBoxFlat = _make_box(COL_BG_PRESS, COL_AMBER, 3, 8)

	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if not is_instance_valid(cur):
			continue
		for ch in cur.get_children():
			stack.append(ch)
		if cur is Button:
			var b: Button = cur as Button
			if b.custom_minimum_size.x < MIN_TOUCH_PX and b.custom_minimum_size.y < MIN_TOUCH_PX:
				b.custom_minimum_size = Vector2(maxf(MIN_TOUCH_PX, b.custom_minimum_size.x), maxf(MIN_TOUCH_PX, b.custom_minimum_size.y))
			b.add_theme_stylebox_override("normal", norm_sb)
			b.add_theme_stylebox_override("hover", hov_sb)
			b.add_theme_stylebox_override("pressed", prs_sb)
			b.add_theme_color_override("font_color", COL_TEXT)
			b.add_theme_color_override("font_hover_color", COL_AMBER)
			b.add_theme_color_override("font_pressed_color", COL_AMBER)
			if not b.button_down.is_connected(_on_btn_down.bind(b)):
				b.button_down.connect(_on_btn_down.bind(b))
				b.button_up.connect(_on_btn_up.bind(b))


func _on_btn_down(b: Button) -> void:
	if not is_instance_valid(b):
		return
	b.pivot_offset = b.size * 0.5
	var tw: Tween = create_tween()
	tw.tween_property(b, "scale", Vector2(0.94, 0.94), 0.06)
	_tweens.append(tw)


func _on_btn_up(b: Button) -> void:
	if not is_instance_valid(b):
		return
	var tw: Tween = create_tween()
	tw.tween_property(b, "scale", Vector2.ONE, 0.09)
	_tweens.append(tw)


func _find_control_ci(root: Node, names_lower: Array[String]) -> Control:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if not is_instance_valid(cur):
			continue
		if cur is Control:
			var ln: String = cur.name.to_lower()
			for target in names_lower:
				if ln == target or ln.contains(target):
					return cur as Control
		for ch in cur.get_children():
			stack.append(ch)
	return null


func _make_box(bg: Color, border: Color, bw: int, r: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = bw
	sb.border_width_top = bw
	sb.border_width_right = bw
	sb.border_width_bottom = bw
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	return sb
