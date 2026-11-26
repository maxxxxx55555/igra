extends Control
## Карта города: прогресс энергосети и переход между районами.
##
## Прежняя версия была заглушкой: восемь кружков через _draw(), английские
## подписи мимо локализации, кнопка «Close (K)» и никакой возможности
## куда-либо пойти. Между тем перемещаться по городу больше нечем — в
## районах нет порталов, а WorldRuntime умеет строить любой район по
## сигналу district_entered. Пока карта молчала, игрок навсегда оставался
## в пригороде, то есть 10 из 11 районов были недостижимы.
##
## Теперь это рабочий экран: видно стадию каждого района, что его открывает
## и куда можно отправиться.

const CANON: Array[StringName] = [
	&"suburbs", &"residential", &"park", &"school", &"hospital", &"gas_station",
	&"police", &"warehouses", &"industrial", &"substation", &"power_station",
]

## Цвет кружка по стадии восстановления.
const STAGE_COLORS: Array[Color] = [
	Color(0.30, 0.31, 0.35),  # DARK
	Color(0.55, 0.42, 0.20),  # PARTIAL
	Color(0.79, 0.64, 0.29),  # STREETS
	Color(0.37, 0.54, 0.31),  # FULL
]

## V2 SKIN WIRING P1: hex_[color]_128.png per DistrictData.Stage, plus a
## separate "locked" hex for districts not yet unlocked at all.
const _HEX_ICON: Array[String] = [
	"res://assets/textures/ui_v2/hex_grey_128.png",   # DARK
	"res://assets/textures/ui_v2/hex_amber_128.png",  # PARTIAL
	"res://assets/textures/ui_v2/hex_amber_128.png",  # STREETS
	"res://assets/textures/ui_v2/hex_green_128.png",  # FULL
]
const _HEX_LOCKED := "res://assets/textures/ui_v2/hex_locked_128.png"

## Ключи перечислены явно, а не собираются как "MAP_STAGE_%d": проверка
## локализации ищет ключи по коду и на склеенных именах ничего не находит.
const STAGE_KEYS: Array[String] = [
	"MAP_STAGE_0", "MAP_STAGE_1", "MAP_STAGE_2", "MAP_STAGE_3",
]

## A row is the crest, the stage pip, the name, the stage and this button: 32 + 16 + 190 + 150 + 230 + 4 gaps of 12 = 666 px,
## inside the 680 px list less its scroll bar. At 190 px for the button the longest lock text ("Закрыт: Жилые кварталы") ran
## past the row and the list got a horizontal bar of its own.
## Wave 2.5: the travel list shares the screen with the light-revealed city,
## so its rows were compacted to fit a 34-38% right column without a horizontal bar.
const NAME_WIDTH: float = 108.0
const STAGE_WIDTH: float = 78.0
const ACTION_SIZE := Vector2(140, 34)

var _list: VBoxContainer = null
var _title: Label = null
var _close_button: Button = null
var _map_art: Node = null
var _panel: PanelContainer = null
var _scroll: ScrollContainer = null

## Wave 2: a quiet, light-revealed street plan behind the travel list. It is
## drawn from the real PowerGrid stages, so restored blocks carry sodium pools
## and dark ones stay as faint architecture. No enemies, no player arrow.
class LightRevealArt:
	extends Control

	var _stages: Dictionary = {}

	func refresh(pg: Node) -> void:
		_stages.clear()
		if pg != null:
			for id: StringName in CANON:
				_stages[id] = int(pg.get_stage(id))
		queue_redraw()

	func _draw() -> void:
		var cell_w: float = size.x / 4.8
		var cell_h: float = size.y / 3.8
		var ox: float = (size.x - cell_w * 4.0) * 0.5
		var oy: float = (size.y - cell_h * 3.0) * 0.5
		var road := Color(0.12, 0.18, 0.20, 0.68)
		for c: int in 5:
			draw_line(Vector2(ox + c * cell_w, oy), Vector2(ox + c * cell_w, oy + cell_h * 3.0), road, 2.0)
		for r: int in 4:
			draw_line(Vector2(ox, oy + r * cell_h), Vector2(ox + cell_w * 4.0, oy + r * cell_h), road, 2.0)
		for i: int in CANON.size():
			var row: int = i / 4
			var col: int = i % 4
			var x: float = ox + col * cell_w + cell_w * 0.12
			var y: float = oy + row * cell_h + cell_h * 0.14
			var stage: int = int(_stages.get(CANON[i], 0))
			var lit: float = 1.0 if stage >= DistrictData.Stage.FULL else (0.55 if stage >= DistrictData.Stage.STREETS else (0.22 if stage == DistrictData.Stage.PARTIAL else 0.06))
			for b: int in 5:
				var bx: float = x + float((b * 37 + i * 17) % 48) / 48.0 * cell_w * 0.62
				var by: float = y + float((b * 53 + i * 29) % 48) / 48.0 * cell_h * 0.58
				var bw: float = 16.0 + float((b * 13 + i * 7) % 22)
				var bh: float = 12.0 + float((b * 11 + i * 5) % 20)
				draw_rect(Rect2(bx, by, bw, bh), Color(0.09, 0.14, 0.16, 0.38 + lit * 0.45))
				draw_rect(Rect2(bx, by, bw, bh), Color(0.79, 0.64, 0.29, 0.16 + lit * 0.50), false, 1.0)
			if lit > 0.2:
				var pool := Vector2(x + cell_w * 0.38, y + cell_h * 0.34)
				draw_circle(pool, 18.0 * lit, Color(0.83, 0.66, 0.31, 0.05 * lit))
				draw_circle(pool, 7.0 * lit, Color(0.83, 0.66, 0.31, 0.22 * lit))
				draw_circle(pool, 2.5, Color(0.91, 0.85, 0.69, 0.65 * lit))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = CraftThemeBridge.build()
	_build()
	get_viewport().size_changed.connect(_apply_map_layout)
	LocalizationManager.language_changed.connect(_on_language_changed)
	EventBus.district_stage_changed.connect(func(_a: StringName, _b: int) -> void: _refresh())
	EventBus.district_entered.connect(func(_a: StringName) -> void: _refresh())
	visibility_changed.connect(func() -> void:
		if visible:
			_refresh())

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0235294, 0.0588235, 0.0745098, 1.0)  # keep the live player/enemies out of the charted city
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_map_art = LightRevealArt.new()
	(_map_art as Control).name = "LightRevealMap"
	(_map_art as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	(_map_art as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map_art)

	_panel = PanelContainer.new()
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	_panel.add_child(root)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	root.add_child(_title)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)

	var close := Button.new()
	_close_button = close
	close.text = LocalizationManager.t("BTN_CLOSE")
	close.custom_minimum_size = Vector2(160, 40)
	close.pressed.connect(_close)
	root.add_child(close)
	_apply_map_layout()

## Wave 2.5: the city stays visible on the left 62-66%. The list occupies a
## 36%-wide right column (capped so a desktop does not get a absurdly wide list),
## and every row was compacted enough that no horizontal scroll bar appears.
func _apply_map_layout() -> void:
	if _panel == null or _scroll == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var column_w: float = clampf(vp.x * 0.36, 430.0, 640.0)
	var panel_h: float = clampf(vp.y - 80.0, 480.0, 640.0)
	var margin: float = 18.0
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -margin - column_w
	_panel.offset_right = -margin
	_panel.offset_top = -panel_h * 0.5
	_panel.offset_bottom = panel_h * 0.5
	_panel.custom_minimum_size = Vector2(column_w, panel_h)
	_scroll.custom_minimum_size = Vector2(maxf(420.0, column_w - 20.0), maxf(360.0, panel_h - 180.0))

func _on_language_changed(_language: String) -> void:
	_close_button.text = LocalizationManager.t("BTN_CLOSE")
	_refresh()

func _refresh() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	var pg := get_node_or_null("/root/PowerGrid")
	var dm := get_node_or_null("/root/DistrictManager")
	var current: StringName = StringName(dm.current_district) if dm != null else &""
	var restored := 0
	for id in CANON:
		if pg != null and pg.get_stage(id) >= DistrictData.Stage.FULL:
			restored += 1
	if _title != null:
		_title.text = LocalizationManager.tf("MAP_PROGRESS", [restored, CANON.size()])
	if _map_art != null and _map_art.has_method("refresh"):
		_map_art.call("refresh", pg)

	# district travel lists only the destinations the player already knows (the owner's map rules): no locked name
	for id in CANON:
		if pg == null or pg.is_unlocked(id) or id == current:
			_list.add_child(_make_row(id, pg, current))

func _make_row(id: StringName, pg: Node, current: StringName) -> Control:
	var stage: int = pg.get_stage(id) if pg != null else 0
	var unlocked: bool = pg.is_unlocked(id) if pg != null else false
	var is_here: bool = id == current

	var row := PanelContainer.new()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	row.add_child(hb)

	# Герб района — какой это район; отдельно от кружка ниже (тот про стадию сети).
	var crest_path := "res://assets/textures/crests/crest_%s_96.png" % String(id)
	if ResourceLoader.exists(crest_path):
		var crest := TextureRect.new()
		crest.texture = load(crest_path)
		crest.custom_minimum_size = Vector2(32, 32)
		crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		crest.modulate.a = 1.0 if unlocked else 0.4
		hb.add_child(crest)

	# Индикатор стадии: hex-пип V2 (заблокирован -> серый замочный hex,
	# иначе цвет по стадии сети). Цветной ColorRect ниже — запасной вариант,
	# если файла нет на диске.
	var hex_path := _HEX_LOCKED if not unlocked else _HEX_ICON[clampi(stage, 0, 3)]
	if ResourceLoader.exists(hex_path):
		var hex := TextureRect.new()
		hex.texture = load(hex_path)
		hex.custom_minimum_size = Vector2(16, 16)
		hex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(hex)
	else:
		var dot := ColorRect.new()
		dot.color = STAGE_COLORS[clampi(stage, 0, 3)]
		dot.custom_minimum_size = Vector2(14, 14)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(dot)

	var name_lbl := Label.new()
	name_lbl.text = _display_name(id, pg)
	name_lbl.custom_minimum_size = Vector2(NAME_WIDTH, 34)
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_color_override("font_color",
		ThemeProvider.COLOR_TEXT if unlocked else ThemeProvider.COLOR_TEXT_DIM)
	hb.add_child(name_lbl)

	var stage_lbl := Label.new()
	stage_lbl.text = LocalizationManager.t(STAGE_KEYS[clampi(stage, 0, 3)])
	stage_lbl.custom_minimum_size = Vector2(STAGE_WIDTH, 34)
	stage_lbl.clip_text = true
	stage_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stage_lbl.add_theme_color_override("font_color", STAGE_COLORS[clampi(stage, 0, 3)])
	hb.add_child(stage_lbl)

	var action := Button.new()
	action.custom_minimum_size = ACTION_SIZE
	action.clip_text = true
	action.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if is_here:
		action.text = LocalizationManager.t("MAP_YOU_ARE_HERE")
		action.disabled = true
	elif not unlocked:
		var need: String = pg.missing_prerequisite_name(id) if pg != null else ""
		action.text = LocalizationManager.tf("MAP_LOCKED_BY", [need])
		action.disabled = true
	else:
		action.text = LocalizationManager.t("MAP_TRAVEL")
		action.pressed.connect(_travel.bind(id))
	hb.add_child(action)
	return row

func _display_name(id: StringName, pg: Node) -> String:
	# display_name в .tres записан по-русски; для остальных 12 языков имя
	# берётся из словаря по ключу DISTRICT_NAME_<ID>.
	var fallback: String = ""
	if pg != null:
		var d = pg.get_district(id)
		if d != null:
			fallback = String(d.display_name)
	return LocalizationManager.name_for("DISTRICT_NAME_", id, fallback)

## Переход строит WorldRuntime: он слушает district_entered и пересобирает
## район вместе с врагами и лутом.
func _travel(id: StringName) -> void:
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null and dm.has_method("transition_to"):
		dm.transition_to(String(id))
	else:
		EventBus.district_entered.emit(id)
	_close()

func _close() -> void:
	var ui := get_node_or_null("/root/UIManager")
	if ui != null and ui.has_method("close"):
		ui.close(&"city_map")
	else:
		visible = false
