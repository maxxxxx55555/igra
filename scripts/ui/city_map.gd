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

## Ключи перечислены явно, а не собираются как "MAP_STAGE_%d": проверка
## локализации ищет ключи по коду и на склеенных именах ничего не находит.
const STAGE_KEYS: Array[String] = [
	"MAP_STAGE_0", "MAP_STAGE_1", "MAP_STAGE_2", "MAP_STAGE_3",
]

var _list: VBoxContainer = null
var _title: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	_build()
	EventBus.district_stage_changed.connect(func(_a: StringName, _b: int) -> void: _refresh())
	EventBus.district_entered.connect(func(_a: StringName) -> void: _refresh())
	visibility_changed.connect(func() -> void:
		if visible:
			_refresh())

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.047, 0.063, 0.086, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(720, 560)
	add_child(panel)
	# V2 SKIN WIRING P4: real isometric city backdrop under the district
	# rows below (textless by design - rows/labels are the "engine overlay").
	var map_bg_path := "res://assets/textures/maps_v2/city_iso_2048.png"
	if ResourceLoader.exists(map_bg_path):
		var map_bg := TextureRect.new()
		map_bg.texture = load(map_bg_path)
		map_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		map_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		map_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(map_bg)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	root.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 440)
	root.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var close := Button.new()
	close.text = LocalizationManager.t("BTN_CLOSE")
	close.custom_minimum_size = Vector2(160, 40)
	close.pressed.connect(_close)
	root.add_child(close)

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

	for id in CANON:
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
		crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		crest.modulate.a = 1.0 if unlocked else 0.4
		hb.add_child(crest)

	# Индикатор стадии.
	var dot := ColorRect.new()
	dot.color = STAGE_COLORS[clampi(stage, 0, 3)]
	dot.custom_minimum_size = Vector2(14, 14)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(dot)

	var name_lbl := Label.new()
	name_lbl.text = _display_name(id, pg)
	name_lbl.custom_minimum_size = Vector2(200, 34)
	name_lbl.add_theme_color_override("font_color",
		ThemeProvider.COLOR_TEXT if unlocked else ThemeProvider.COLOR_TEXT_DIM)
	hb.add_child(name_lbl)

	var stage_lbl := Label.new()
	stage_lbl.text = LocalizationManager.t(STAGE_KEYS[clampi(stage, 0, 3)])
	stage_lbl.custom_minimum_size = Vector2(190, 34)
	stage_lbl.add_theme_color_override("font_color", STAGE_COLORS[clampi(stage, 0, 3)])
	hb.add_child(stage_lbl)

	var action := Button.new()
	action.custom_minimum_size = Vector2(190, 34)
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
