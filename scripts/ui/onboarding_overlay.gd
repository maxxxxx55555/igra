extends CanvasLayer
## P1 (FINAL INTEGRATION wave): first-launch onboarding, now that
## assets/textures/onboard_v2/ exists (delivered mid-session in
## REPORT_UNBLOCK_V2.md - was blocked/logged as missing in this same
## session's earlier P1 attempt). 4 panels shown once ever per save
## profile (SaveSystem is_onboard_done flag, unaffected by New Game resets -
## see save_system.gd), NEXT/SKIP, never blocks gameplay after dismissal.

const PANELS: Array[Dictionary] = [
	{"img": "res://assets/textures/onboard_v2/onboard_01_spawn_256x144.png", "caption": "ONBOARD_01_CAPTION"},
	{"img": "res://assets/textures/onboard_v2/onboard_02_light_256x144.png", "caption": "ONBOARD_02_CAPTION"},
	{"img": "res://assets/textures/onboard_v2/onboard_03_streetlight_256x144.png", "caption": "ONBOARD_03_CAPTION"},
	{"img": "res://assets/textures/onboard_v2/onboard_04_district_256x144.png", "caption": "ONBOARD_04_CAPTION"},
]
const AUTO_HIDE_DISTRICT: StringName = &"suburbs"
const AUTO_HIDE_STAGE: int = 2  ## DistrictData.Stage.STREETS

var _root: Control
var _art: TextureRect
var _caption: Label
var _index: int = 0
var _showing: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	EventBus.game_started.connect(_on_game_started)
	EventBus.district_stage_changed.connect(_on_district_stage_changed)

func _on_game_started() -> void:
	if SaveSystem.is_onboard_done() or _showing:
		return
	if not ResourceLoader.exists(PANELS[0]["img"]):
		return
	_build()
	_index = 0
	_show_panel()

func _on_district_stage_changed(district_id: StringName, stage: int) -> void:
	if _showing and district_id == AUTO_HIDE_DISTRICT and stage >= AUTO_HIDE_STAGE:
		_finish()

func _build() -> void:
	_showing = true
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.03, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(340, 280)
	_root.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	_art = TextureRect.new()
	_art.custom_minimum_size = Vector2(256, 144)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_art)

	_caption = Label.new()
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD
	_caption.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
	vb.add_child(_caption)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vb.add_child(btn_row)

	var skip := Button.new()
	skip.text = LocalizationManager.t("UI_SKIP")
	skip.focus_mode = Control.FOCUS_NONE
	skip.pressed.connect(_finish)
	btn_row.add_child(skip)

	var next := Button.new()
	next.name = "NextBtn"
	next.text = LocalizationManager.t("ONBOARD_NEXT")
	next.focus_mode = Control.FOCUS_NONE
	next.pressed.connect(_on_next)
	btn_row.add_child(next)

func _show_panel() -> void:
	var p: Dictionary = PANELS[_index]
	if ResourceLoader.exists(p["img"]):
		_art.texture = load(p["img"])
	_caption.text = LocalizationManager.t(p["caption"])
	var next: Button = _root.find_child("NextBtn", true, false)
	if next != null:
		next.text = LocalizationManager.t("ui_close") if _index == PANELS.size() - 1 else LocalizationManager.t("ONBOARD_NEXT")

func _on_next() -> void:
	_index += 1
	if _index >= PANELS.size():
		_finish()
	else:
		_show_panel()

func _finish() -> void:
	if not _showing:
		return
	_showing = false
	SaveSystem.mark_onboard_done()
	if _root != null:
		_root.queue_free()
		_root = null
