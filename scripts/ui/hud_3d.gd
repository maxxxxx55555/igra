extends CanvasLayer

const BAR_W: float = 220.0
const BAR_H: float = 16.0
const BAR_ROW_PITCH: float = 34.0
const BAR_ROW_TOP: float = 30.0

var _hp: float = 1.0
var _stam: float = 1.0
var _bat: float = 1.0
var _vignette_default_color: Color
var _enemy_hp_tween: Tween

@onready var hp_fill: ColorRect = $TopLeft/HP/HPF
@onready var hp_val: Label = $TopLeft/HP/HPVal
@onready var stam_fill: ColorRect = $TopLeft/Stam/StamF
@onready var stam_val: Label = $TopLeft/Stam/StamVal
@onready var bat_fill: ColorRect = $TopLeft/Bat/BatF
@onready var bat_val: Label = $TopLeft/Bat/BatVal
@onready var ammo_val: Label = $AmmoCounter/AmmoVal
@onready var prompt: Label = $PromptLabel
@onready var notice: Label = $NoticeLabel
## VignetteOverlay создаётся PostProcessOverlay уже после готовности HUD,
## поэтому @onready ловил null и виньетка урона не работала — ищем лениво.
var _vignette_cache: ColorRect = null
var vignette: ColorRect:
	get:
		if is_instance_valid(_vignette_cache):
			return _vignette_cache
		_vignette_cache = get_tree().root.find_child("VignetteOverlay", true, false) as ColorRect
		return _vignette_cache
@onready var enemy_name_label: Label = $EnemyName
@onready var enemy_hp_bar: ColorRect = $EnemyHPBar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_remove_dup_leftbottom()
	_apply_touch_visibility()
	_fix_radar_anchor()
	InputService.quick_slot_requested.connect(_on_quick_slot_key)
	hp_fill.color = Color(0.706, 0.271, 0.184)
	stam_fill.color = Color(0.373, 0.541, 0.306)
	bat_fill.color = Color(0.788, 0.635, 0.290)
	var player := get_tree().get_first_node_in_group("player")
	var hp_ratio := 1.0
	var stam_ratio := 1.0
	var bat_ratio := 1.0
	if player:
		var p_hp = player.get("hp")
		var p_stats = player.get("stats")
		var p_max_hp = p_stats.max_hp if (p_stats and "max_hp" in p_stats and p_stats.max_hp > 0) else 100.0
		hp_ratio = clampf(p_hp / p_max_hp, 0.0, 1.0) if (p_hp != null) else 1.0
		var p_bat = player.get("battery")
		bat_ratio = clampf(p_bat / 100.0, 0.0, 1.0) if (p_bat != null) else 1.0
	hp_fill.offset_right = hp_ratio * BAR_W
	stam_fill.offset_right = stam_ratio * BAR_W
	bat_fill.offset_right = bat_ratio * BAR_W
	hp_val.text = str(int(hp_ratio * 100))
	stam_val.text = str(int(stam_ratio * 100))
	bat_val.text = str(int(bat_ratio * 100))
	# Цвет по умолчанию читаем отложенно — оверлея ещё нет на этом кадре.
	call_deferred("_cache_vignette_default")
	_add_captions()
	_setup_number_fonts()
	_setup_slot_placeholders()
	_setup_radar()
	_setup_button_feedback()
	_apply_text_outlines()
	EventBus.player_health_changed.connect(_on_hp)
	EventBus.player_health_changed.connect(_on_damage_vignette)
	if EventBus.has_signal(&"crosshair_state_changed"):
		EventBus.crosshair_state_changed.connect(_on_crosshair_state)
	EventBus.player_stamina_changed.connect(_on_stam)
	EventBus.player_battery_changed.connect(_on_bat)
	EventBus.ammo_changed.connect(_on_ammo_changed)
	EventBus.player_interact_available.connect(func(avail: bool): prompt.visible = avail)
	EventBus.inventory_weight_changed.connect(_on_weight_changed)
	EventBus.inventory_notice.connect(func(msg: String): _show_notice(msg))
	EventBus.monster_spotted.connect(_on_monster_spotted)
	EventBus.enemy_hp_updated.connect(_on_enemy_hp_updated)
	enemy_name_label.add_theme_font_size_override("font_size", 18)
	enemy_name_label.add_theme_color_override("font_color", Color(0.706, 0.271, 0.184))
	enemy_name_label.visible = false
	enemy_hp_bar.visible = false
	prompt.visible = false
	_setup_weight_bar()
	_setup_nv_poll()
	$BtnPause.pressed.connect(_on_pause)
	_add_map_button()
	EventBus.game_state_changed.connect(_on_game_state)
	_on_game_state(int(GameManager.current_state))

func _cache_vignette_default() -> void:
	var v := vignette
	if v != null:
		_vignette_default_color = v.color

func _setup_nv_poll() -> void:
	var nv_poll := Timer.new()
	nv_poll.name = "NVPollTimer"
	nv_poll.wait_time = 0.1
	nv_poll.autostart = true
	nv_poll.timeout.connect(_poll_noise_visibility)
	add_child(nv_poll)

func _setup_weight_bar() -> void:
	var w := $WeightBar
	if not w:
		return
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	if inv and inv.has_method("weight_ratio"):
		var ratio: float = inv.weight_ratio()
		w.value = ratio * 100.0
		_set_weight_color(w, ratio)
	var poll := Timer.new()
	poll.name = "WeightPollTimer"
	poll.wait_time = 0.2
	poll.autostart = true
	poll.timeout.connect(_poll_weight)
	add_child(poll)

## Бары шум/заметность (спека 3.10/3.11). Заполняются по игроку.
@onready var noise_fill: ColorRect = $TopLeft/NoiseF
@onready var noise_caption: Label = $TopLeft/NoiseLabel
@onready var vis_fill: ColorRect = $TopLeft/VisibilityF
@onready var vis_caption: Label = $TopLeft/VisibilityLabel

const _BAR_L: float = 88.0
const _BAR_W: float = 222.0  # 88 -> 310 px

func _poll_noise_visibility() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		if noise_fill: noise_fill.visible = false
		if vis_fill: vis_fill.visible = false
		return
	var noise: float = 0.0
	if player.has_method("get_noise_level"):
		noise = float(player.get_noise_level())
	elif "noise_level" in player:
		noise = float(player.noise_level)
	noise = clampf(noise, 0.0, 1.0)
	var vis: float = 1.0
	if "visibility" in player:
		vis = float(player.visibility)
	vis = clampf(vis, 0.0, 1.0)
	if noise_fill:
		noise_fill.offset_right = _BAR_L + noise * _BAR_W
		noise_fill.color = _pick_noise_color(noise)
	if vis_fill:
		vis_fill.offset_right = _BAR_L + vis * _BAR_W
		vis_fill.color = _pick_vis_color(vis)

func _pick_noise_color(v: float) -> Color:
	if v < 0.34: return Color(0.373, 0.541, 0.306)  # stamina
	elif v < 0.67: return Color(0.788, 0.635, 0.290)  # brass
	else: return Color(0.706, 0.271, 0.184)  # ember

func _pick_vis_color(v: float) -> Color:
	# Видимость «наоборот» от шума: тихий+тёмный = зелёный.
	if v < 0.15: return Color(0.373, 0.541, 0.306)
	elif v < 0.5: return Color(0.788, 0.635, 0.290)
	else: return Color(0.706, 0.271, 0.184)

## 3.6 Спека: прицел меняет цвет по наведению на врага
## YAGNI: не делаем RayCast-tick, а слушаем EventBus.
@onready var _crosshair: ColorRect = $Crosshair

const _CROSSHAIR_NAMES: Dictionary = {
	"default": Color(0.541, 0.451, 0.220, 0.85),   # brass-dim
	"enemy":  Color(0.706, 0.271, 0.184, 0.95),     # ember
	"disabled": Color(0.165, 0.200, 0.251, 0.6),    # panel-edge (недоступно/прицел-вне-врага)
}

func _update_crosshair(state: StringName) -> void:
	if _crosshair == null:
		return
	if _CROSSHAIR_NAMES.has(state):
		_crosshair.color = _CROSSHAIR_NAMES[state]

## Triggered по сигналу EventBus.player_aim_at / crosshair_state_changed.
## Caller: игрок или система взаимодействия.
func _on_crosshair_state(state: StringName) -> void:
	_update_crosshair(state)


func _poll_weight() -> void:
	var w := $WeightBar
	if not w:
		return
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	if inv and inv.has_method("weight_ratio"):
		var ratio: float = inv.weight_ratio()
		w.value = ratio * 100.0
		_set_weight_color(w, ratio)

func _on_weight_changed(weight: float) -> void:
	var w := $WeightBar
	if not w:
		return
	var ratio := weight
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	if inv and inv.has_method("weight_ratio"):
		ratio = inv.weight_ratio()
	w.value = clampf(ratio * 100.0, 0.0, 100.0)
	_set_weight_color(w, ratio)

func _set_weight_color(w: Control, ratio: float) -> void:
	if ratio < 0.5:
		w.modulate = Color(0.373, 0.541, 0.306)
	elif ratio < 0.8:
		w.modulate = Color(0.788, 0.635, 0.290)
	else:
		w.modulate = Color(0.706, 0.271, 0.184)

func _on_game_state(state: int) -> void:
	visible = state == GameManager.GameState.PLAYING or state == GameManager.GameState.PAUSED

func has_touch_ui() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

func _apply_touch_visibility() -> void:
	if not has_touch_ui():
		for path in ["BottomLeft", "BottomRight"]:
			var n := get_node_or_null(path) as CanvasItem
			if n != null:
				n.visible = false
		return
	_install_joystick()

## JoystickRing в сцене был просто нарисованным кольцом — двигать им игрока было
## нельзя. Вешаем на него virtual_joystick.gd, который пишет в InputService;
## отдельный джойстик из main_3d.gd больше не создаётся (было два кольца).
func _install_joystick() -> void:
	var ring := get_node_or_null("BottomLeft/JoystickRing") as Control
	if ring == null or ring.get_script() != null:
		return
	var js: Script = load("res://scripts/ui/virtual_joystick.gd")
	if js == null:
		return
	var joy := Control.new()
	joy.name = "JoystickInput"
	joy.set_script(js)
	joy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joy.mouse_filter = Control.MOUSE_FILTER_STOP
	ring.add_child(joy)

func _fix_radar_anchor() -> void:
	var tr := get_node_or_null("TopRight") as Control
	if tr == null:
		return
	tr.grow_vertical = Control.GROW_DIRECTION_END
	tr.offset_bottom = tr.offset_top + tr.get_combined_minimum_size().y

func _remove_dup_leftbottom() -> void:
	var vp := get_viewport().get_visible_rect().size
	for c in get_children():
		if c is Control and c.visible and c.name != "BottomLeft":
			var cr: Rect2 = c.get_global_rect()
			if cr.position.x < vp.x * 0.25 and cr.position.y + cr.size.y > vp.y * 0.75:
				c.queue_free()

func _add_captions() -> void:
	var data := [
		["HP", $TopLeft/HP],
		["СТАМИНА", $TopLeft/Stam],
		["БАТАРЕЯ", $TopLeft/Bat]
	]
	var outline_col := Color(0.047, 0.063, 0.086, 1.0)
	var shadow_col := Color(0.0, 0.0, 0.0, 0.5)
	var row: int = 0
	for d in data:
		var lbl := Label.new()
		lbl.text = d[0]
		lbl.mouse_filter = 2
		lbl.add_theme_color_override("font_color", Color(0.682, 0.714, 0.749))
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_outline_color", outline_col)
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.add_theme_color_override("font_shadow_color", shadow_col)
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		d[1].add_child(lbl)
		var cap_h: float = maxf(lbl.get_combined_minimum_size().y, 12.0)
		lbl.size = Vector2(120, cap_h)
		lbl.position = Vector2(0, -cap_h - 2.0)
		var bar: Control = d[1]
		bar.position.y = float(row) * (BAR_ROW_PITCH)
		bar.offset_top = float(row) * BAR_ROW_PITCH + BAR_ROW_TOP
		bar.offset_bottom = bar.offset_top + BAR_H
		row += 1
	var tl: Control = $TopLeft
	tl.offset_bottom = tl.offset_top + BAR_ROW_TOP + float(data.size()) * BAR_ROW_PITCH

func _setup_number_fonts() -> void:
	for lbl in [hp_val, stam_val, bat_val]:
		lbl.add_theme_color_override("font_color", Color(0.847, 0.824, 0.769))
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.text = "100"

func _apply_text_outlines() -> void:
	var outline_col := Color(0.047, 0.063, 0.086, 1.0)
	var shadow_col := Color(0.0, 0.0, 0.0, 0.5)
	for lbl in [hp_val, stam_val, bat_val, prompt, notice]:
		if lbl:
			lbl.add_theme_color_override("font_outline_color", outline_col)
			lbl.add_theme_constant_override("outline_size", 2)
			lbl.add_theme_color_override("font_shadow_color", shadow_col)
			lbl.add_theme_constant_override("shadow_offset_x", 1)
			lbl.add_theme_constant_override("shadow_offset_y", 1)
	_outline_recursive(self, outline_col, shadow_col)

func _outline_recursive(node: Node, oc: Color, sc: Color) -> void:
	if node is Label:
		node.add_theme_color_override("font_outline_color", oc)
		node.add_theme_constant_override("outline_size", 2)
		node.add_theme_color_override("font_shadow_color", sc)
		node.add_theme_constant_override("shadow_offset_x", 1)
		node.add_theme_constant_override("shadow_offset_y", 1)
	for c in node.get_children():
		_outline_recursive(c, oc, sc)

func _process(delta: float) -> void:
	if _bat < 0.25:
		var pulse: float = sin(Time.get_ticks_msec() * 0.0095) * 0.5 + 0.5
		bat_fill.color = Color(0.788, 0.635, 0.290).lerp(Color(0.706, 0.271, 0.184), pulse)
	else:
		bat_fill.color = Color(0.788, 0.635, 0.290)

func _on_monster_spotted(monster_id) -> void:
	if typeof(monster_id) == TYPE_INT:
		enemy_name_label.text = "CRAWLER"
	else:
		enemy_name_label.text = "ember #" + str(monster_id)
	enemy_name_label.visible = true
	enemy_hp_bar.visible = true
	if _enemy_hp_tween:
		_enemy_hp_tween.kill()
	_enemy_hp_tween = create_tween()
	_enemy_hp_tween.tween_property(enemy_name_label, "modulate:a", 1.0, 0.3).from(0.0)
	_enemy_hp_tween.parallel().tween_property(enemy_hp_bar, "modulate:a", 1.0, 0.3).from(0.0)
	_enemy_hp_tween.tween_interval(2.0)
	_enemy_hp_tween.tween_property(enemy_name_label, "modulate:a", 0.0, 0.3)
	_enemy_hp_tween.parallel().tween_property(enemy_hp_bar, "modulate:a", 0.0, 0.3)
	_enemy_hp_tween.tween_callback(func():
		enemy_name_label.visible = false
		enemy_hp_bar.visible = false)

func _on_enemy_hp_updated(_monster_id: StringName, ratio: float) -> void:
	enemy_hp_bar.scale.x = clampf(ratio, 0.0, 1.0)
	enemy_hp_bar.visible = true
	if _enemy_hp_tween:
		_enemy_hp_tween.kill()
	_enemy_hp_tween = create_tween()
	_enemy_hp_tween.tween_interval(2.0)
	_enemy_hp_tween.tween_property(enemy_hp_bar, "modulate:a", 0.0, 0.3)
	_enemy_hp_tween.tween_callback(func():
		enemy_hp_bar.visible = false)

## Вспышка виньетки при уроне. Возврат идёт к фактической базовой прозрачности,
## а не к константе 0.4: иначе каждое попадание навсегда затемняло экран.
func _on_damage_vignette(ratio: float) -> void:
	var v := vignette
	if ratio < _hp and v != null:
		var tween := create_tween()
		tween.tween_property(v, "color:a", 0.8, 0.15)
		tween.tween_property(v, "color:a", _vignette_default_color.a, 0.25)

func _on_hp(ratio: float) -> void:
	_hp = ratio
	_tween_fill(hp_fill, ratio)
	hp_val.text = str(int(ratio * 100))
	# На низком HP виньетка остаётся заметно плотнее базовой, но не «залипает».
	var v := vignette
	if ratio < 0.3 and v != null:
		var tween := create_tween()
		tween.tween_property(v, "color:a", 0.8, 0.15)
		tween.tween_property(v, "color:a", maxf(_vignette_default_color.a, 0.6), 0.15)

func _on_stam(ratio: float) -> void:
	_stam = ratio
	_tween_fill(stam_fill, ratio)
	stam_val.text = str(int(ratio * 100))

func _on_bat(ratio: float) -> void:
	_bat = ratio
	_tween_fill(bat_fill, ratio)
	bat_val.text = str(int(ratio * 100))

func _on_ammo_changed(current: int, max_ammo: int) -> void:
	ammo_val.text = "%d / %d" % [current, max_ammo]

func _tween_fill(cr: ColorRect, ratio: float) -> void:
	var target: float = clampf(ratio, 0.0, 1.0) * BAR_W
	var tween := create_tween()
	tween.tween_property(cr, "offset_right", target, 0.15)
	tween.play()

func _set_fill(cr: ColorRect, ratio: float) -> void:
	cr.offset_right = clampf(ratio, 0.0, 1.0) * BAR_W

func _on_pause() -> void:
	if UIManager and UIManager.has_method("toggle"):
		UIManager.toggle(&"pause")

func _setup_button_feedback() -> void:
	for b in [$BottomRight/BtnAttack, $BottomRight/BtnSprint, $BottomRight/BtnStealth, $BottomRight/BtnInteract]:
		if b:
			b.pressed.connect(_on_btn_pressed.bind(b))
	_wire_action_buttons()

func _wire_action_buttons() -> void:
	var isv := get_node_or_null("/root/InputService")
	if not isv:
		return
	var attack := $BottomRight/BtnAttack
	var sprint := $BottomRight/BtnSprint
	var stealth := $BottomRight/BtnStealth
	var interact := $BottomRight/BtnInteract
	if attack:
		attack.button_down.connect(func() -> void: isv.request_attack())
	if sprint:
		sprint.button_down.connect(func() -> void: isv.set_joy_run_held(true))
		sprint.button_up.connect(func() -> void: isv.set_joy_run_held(false))
	if stealth:
		stealth.button_down.connect(func() -> void:
			isv.set_joy_stealth_toggled(not isv.is_stealth_toggled()))
	if interact:
		interact.button_down.connect(func() -> void: isv.request_interact())
	_add_side_buttons(isv)

func _on_btn_pressed(btn: Button) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.04)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.04)

## Кнопки-«спутники» правого кластера. Раньше они позиционировались абсолютными
## пикселями от 1920x1080 и на телефоне уезжали за экран — теперь якорятся к
## правому нижнему углу, а размер берётся из TOUCH_BTN (палец ~48-64 px).
const TOUCH_BTN: Vector2 = Vector2(64, 64)

func _add_side_buttons(isv: Node) -> void:
	if not has_touch_ui():
		return
	var anchored := func(node: Control, from_right: float, from_bottom: float) -> void:
		node.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		node.offset_left = -from_right - node.custom_minimum_size.x
		node.offset_right = -from_right
		node.offset_top = -from_bottom - node.custom_minimum_size.y
		node.offset_bottom = -from_bottom
	var mk := func(nm: String, label: String, cb: Callable) -> Button:
		var b := Button.new()
		b.name = nm
		b.text = label
		b.custom_minimum_size = TOUCH_BTN
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 22)
		b.button_down.connect(cb)
		add_child(b)
		return b
	var jump := mk.call("BtnJump", "↑", func() -> void: isv.request_jump()) as Button
	anchored.call(jump, 20.0, 250.0)
	var flash := mk.call("BtnFlash", "☀", func() -> void: isv.request_flashlight()) as Button
	anchored.call(flash, 100.0, 250.0)
	# Стробоскоп (GDD §3.1) — отдельная кнопка, на ПК это клавиша C.
	# Приседание уже висит на BtnStealth в сцене — второй кнопки не нужно.
	var strobe := mk.call("BtnStrobe", "⚡", func() -> void: _request_strobe()) as Button
	anchored.call(strobe, 180.0, 250.0)

func _request_strobe() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p != null and p.has_method("trigger_strobe"):
		p.call("trigger_strobe")

func _setup_slot_placeholders() -> void:
	var item_icons := preload("res://scripts/ui/item_icons.gd")
	var order := [&"flashlight", &"battery", &"medkit", &"key", &"cable", &"fuse"]
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	for i in 6:
		var slot := get_node("BottomCenter/Slot" + str(i))
		if not slot:
			continue
		for child in slot.get_children():
			child.queue_free()
		var border := ColorRect.new()
		border.name = "Border"
		border.color = Color(0.165, 0.200, 0.251)
		border.size = Vector2(54, 54)
		border.position = Vector2(-1, -1)
		border.mouse_filter = Control.MOUSE_FILTER_PASS
		slot.add_child(border)
		var icon_parent := Control.new()
		icon_parent.name = "IconParent"
		icon_parent.size = Vector2(48, 48)
		icon_parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon_parent)
		var item_id: StringName = order[i] if i < order.size() else &""
		item_icons.draw_icon(icon_parent, item_id, 32.0)
		var badge := Label.new()
		badge.name = "Badge"
		badge.text = "0"
		badge.add_theme_color_override("font_color", Color(0.847, 0.824, 0.769))
		badge.add_theme_font_size_override("font_size", 11)
		badge.position = Vector2(34, 34)
		slot.add_child(badge)
		if inv and item_id != &"":
			var cnt: int = inv.count_of(item_id)
			if cnt > 0:
				badge.text = str(cnt)
		var si := i
		slot.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_use_quick_slot(si)
		)
	var slot0 := get_node("BottomCenter/Slot0")
	if slot0:
		var border := slot0.get_node_or_null("Border")
		if border:
			border.color = Color(0.788, 0.635, 0.290)

func _on_quick_slot_key(index: int) -> void:
	_use_quick_slot(index)

func _use_quick_slot(index: int) -> void:
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	if not inv or not inv.has_method("use_item"):
		return
	inv.use_item(index)

func _add_map_button() -> void:
	var btn := Button.new()
	btn.name = "MapButton"
	btn.position = Vector2(16, 182)
	btn.size = Vector2(48, 48)
	btn.add_theme_color_override("font_color", Color(0.788, 0.635, 0.290))
	btn.add_theme_font_size_override("font_size", 20)
	btn.text = "🗺"
	btn.pressed.connect(_on_map_btn)
	add_child(btn)

func _on_map_btn() -> void:
	if UIManager and UIManager.has_method("open"):
		UIManager.open(&"city_map")

func _setup_radar() -> void:
	var frame := $TopRight/RadarFrame
	if not frame:
		return
	for c in frame.get_children():
		c.queue_free()
	var radar_script = load("res://scripts/ui/radar.gd")
	if not radar_script:
		return
	var radar := Control.new()
	radar.set_script(radar_script)
	radar.name = "Radar"
	frame.add_child(radar)
	radar.set_anchors_preset(Control.PRESET_FULL_RECT)

func _show_notice(msg: String) -> void:
	notice.text = msg
	await get_tree().create_timer(3.0).timeout
	if notice.text == msg:
		notice.text = ""
