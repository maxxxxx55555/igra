extends Control

@export var enable_character_screen: bool = true

const PANEL := Color("#141b24")
const PANEL_EDGE := Color("#2a3340")
const BRASS := Color("#c9a24a")
const BRASS_DIM := Color("#8a7338")
const EMBER := Color("#b4452f")
const STEEL_TEXT := Color("#aeb6bf")
const BONE_TEXT := Color("#d8d2c4")
const STAMINA := Color("#5f8a4e")

var _player: Node = null
var _inv: Node = null
var _bar_fills: Array = []
var _bar_values: Array = []

func _ready() -> void:
	if not enable_character_screen: return
	_player = get_tree().get_first_node_in_group("player")
	_inv = get_tree().root.get_node_or_null("InventoryManager")
	_build_ui()
	_update_stats()


func _build_ui() -> void:
	var left_x := 5.0
	var stat_y := 5.0
	var stats := [
		{"key": "CHAR_HEALTH", "color": EMBER},
		{"key": "CHAR_STAMINA", "color": STAMINA},
		{"key": "CHAR_NOISE", "color": STEEL_TEXT},
		{"key": "CHAR_WEIGHT", "color": BRASS},
	]
	for i in stats.size():
		var s = stats[i]
		var y := stat_y + i * 50
		var lbl := Label.new()
		lbl.text = tr(s.key)
		lbl.size = Vector2(80, 18)
		lbl.position = Vector2(left_x, y)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 10)
		add_child(lbl)
		var bar_bg := ColorRect.new()
		bar_bg.color = PANEL_EDGE
		bar_bg.size = Vector2(100, 8)
		bar_bg.position = Vector2(left_x, y + 20)
		add_child(bar_bg)
		var bar_fill := ColorRect.new()
		bar_fill.color = s.color
		bar_fill.size = Vector2(100, 8)
		bar_fill.position = Vector2(left_x, y + 20)
		add_child(bar_fill)
		_bar_fills.append(bar_fill)
		var val := Label.new()
		val.name = "StatVal" + str(i)
		val.size = Vector2(60, 18)
		val.position = Vector2(left_x + 108, y)
		val.add_theme_color_override("font_color", s.color)
		val.add_theme_font_size_override("font_size", 10)
		add_child(val)
		_bar_values.append(val)

	var center_x := size.x * 0.35
	var center_y := 10.0
	var silhouette := ColorRect.new()
	silhouette.color = PANEL_EDGE
	silhouette.size = Vector2(80, 120)
	silhouette.position = Vector2(center_x, center_y)
	add_child(silhouette)
	var head := ColorRect.new()
	head.color = PANEL_EDGE
	head.size = Vector2(24, 24)
	head.position = Vector2(28, 4)
	silhouette.add_child(head)
	var body := ColorRect.new()
	body.color = PANEL_EDGE
	body.size = Vector2(40, 40)
	body.position = Vector2(20, 32)
	silhouette.add_child(body)
	var hood := ColorRect.new()
	hood.color = PANEL_EDGE
	hood.size = Vector2(30, 12)
	hood.position = Vector2(25, 0)
	silhouette.add_child(hood)
	var backpack := ColorRect.new()
	backpack.color = PANEL_EDGE
	backpack.size = Vector2(16, 30)
	backpack.position = Vector2(8, 34)
	silhouette.add_child(backpack)

	var slot_x := size.x - 105.0
	var slot_y := 5.0
	var slot_keys := ["CHAR_HEAD", "CHAR_BODY", "CHAR_BACKPACK", "CHAR_LAMP"]
	for i in slot_keys.size():
		var y := slot_y + i * 50
		var slot := ColorRect.new()
		slot.color = PANEL
		slot.size = Vector2(90, 42)
		slot.position = Vector2(slot_x, y)
		add_child(slot)
		var border := ColorRect.new()
		border.color = BRASS_DIM
		border.size = Vector2(92, 44)
		border.position = Vector2(-1, -1)
		border.mouse_filter = Control.MOUSE_FILTER_PASS
		slot.add_child(border)
		var lbl := Label.new()
		lbl.text = tr(slot_keys[i])
		lbl.size = Vector2(90, 18)
		lbl.position = Vector2(0, 12)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", BRASS_DIM)
		lbl.add_theme_font_size_override("font_size", 8)
		slot.add_child(lbl)
		var si := i
		# gdtoolkit не поддерживает многострочные лямбды и помечает строку ниже
		# как ошибку разбора. В Godot 4 синтаксис валиден — это ограничение
		# инструмента; файл проверяется движком.
		slot.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if InventoryManager and InventoryManager.has_method("use_item"):
					InventoryManager.use_item(si)
					_show_toast("Item used")
				)

	var grid_y := slot_y + slot_keys.size() * 50 + 10
	var grid_label := Label.new()
	grid_label.text = tr("INV_QUICK_ACCESS")
	grid_label.size = Vector2(size.x, 18)
	grid_label.position = Vector2(0, grid_y)
	grid_label.add_theme_color_override("font_color", BONE_TEXT)
	grid_label.add_theme_font_size_override("font_size", 10)
	add_child(grid_label)
	var cols := 4
	var rows := 2
	var slot_sz := 44
	var gap := 4
	var grid_start_x := (size.x - (slot_sz * cols + gap * (cols - 1))) * 0.5
	var grid_start_y := grid_y + 22
	for i in cols * rows:
		var col := i % cols
		var row = i / cols
		var slot := ColorRect.new()
		slot.color = PANEL
		slot.size = Vector2(slot_sz, slot_sz)
		slot.position = Vector2(grid_start_x + col * (slot_sz + gap), grid_start_y + row * (slot_sz + gap))
		add_child(slot)
		var border := ColorRect.new()
		border.color = BRASS_DIM
		border.size = Vector2(slot_sz + 2, slot_sz + 2)
		border.position = Vector2(-1, -1)
		slot.add_child(border)

func _process(delta: float) -> void:
	if not enable_character_screen: return
	_update_stats()

func _update_stats() -> void:
	var hp_val := 100.0
	var stam_val := 100.0
	var noise_val := 0.0
	var weight_val := 0.0
	var weight_max := 40.0

	if _player:
		hp_val = _player.hp if _player else 100.0
		stam_val = _player.stamina if _player else 100.0
		noise_val = _player.noise_level if _player else 0.0
		weight_val = _inv.current_weight if _inv else 0.0
		weight_max = _inv.stats.capacity_kg if _inv and _inv.stats else 40.0

	hp_val = clampf(hp_val, 0.0, 100.0)
	stam_val = clampf(stam_val, 0.0, 100.0)

	var ratios := [hp_val / 100.0, stam_val / 100.0, clampf(noise_val / 100.0, 0.0, 1.0), clampf(weight_val / maxf(weight_max, 0.001), 0.0, 1.0)]
	var vals := [str(int(hp_val)) + "/100", str(int(stam_val)) + "/100", str(int(noise_val)) + "%", str(roundf(weight_val * 10.0) / 10.0) + "/" + str(weight_max)]

	for i in 4:
		if i < _bar_fills.size():
			_bar_fills[i].size.x = 100.0 * ratios[i]
		if i < _bar_values.size():
			_bar_values[i].text = vals[i]

func _show_toast(msg: String) -> void:
	var existing := get_node_or_null("Toast")
	if existing:
		existing.queue_free()
	var toast := Label.new()
	toast.name = "Toast"
	toast.text = msg
	toast.size = Vector2(300, 24)
	toast.position = Vector2(size.x * 0.5 - 150, size.y * 0.5 - 50)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color", EMBER)
	toast.add_theme_font_size_override("font_size", 14)
	toast.modulate = Color(1, 1, 1, 0)
	add_child(toast)
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.2)
	tw.tween_property(toast, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): if toast: toast.queue_free())
