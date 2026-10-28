extends Control
## T15: удержание -> аналоговый радиальный выбор из 6 быстрых слотов.
## Работает и на ПК (мышь), и на тач-устройствах (BtnWheel в hud_3d.gd):
## угол считается по НАКОПЛЕННОМУ смещению указателя от точки открытия,
## а не по абсолютной позиции — курсор в игре обычно захвачен (CAPTURED),
## и накопленная относительная дельта работает одинаково для мыши и тача.

const QUICK_SLOTS := preload("res://scripts/ui/quick_slots.gd")

const RADIUS: float = 184.0
const DEADZONE: float = 18.0
const SLOT_COUNT: int = 6
const PANEL := Color("#141b24")
const BRASS := Color("#c9a24a")
const BRASS_DIM := Color("#3a3226")
const BONE := Color("#d8d2c4")

## V2 SKIN WIRING P1: same slot chrome as hud_3d.gd's quickslots, drawn under
## each wedge's icon position. Loaded once; null (skipped) if missing on disk.
const _CHROME_PATH := "res://assets/textures/ui_v2/quickslot_v2_72.png"
var _chrome: Texture2D = load(_CHROME_PATH) if ResourceLoader.exists(_CHROME_PATH) else null

var _open: bool = false
var _paused_before: bool = false
var _drag: Vector2 = Vector2.ZERO
var _highlight: int = -1
var _center: Vector2 = Vector2.ZERO
var _icons: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_icons = Control.new()
	_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icons)
	EventBus.ui_screen_opened.connect(_on_ui_screen_opened)

func _exit_tree() -> void:
	close(false)

func _on_ui_screen_opened(_id: StringName) -> void:
	close(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"quick_wheel") and not event.is_echo():
		open()
	elif event.is_action_released(&"quick_wheel") and _open:
		close(true)
	elif _open and event is InputEventMouseMotion:
		_drag += (event as InputEventMouseMotion).relative

func _input(event: InputEvent) -> void:
	if _open and event.is_action_pressed(&"ui_cancel"):
		close(false)
		get_viewport().set_input_as_handled()
	elif _open and event is InputEventScreenDrag:
		_drag += (event as InputEventScreenDrag).relative

func open() -> void:
	if _open or not GameManager.is_playing() or UIManager.is_hud_blocked() or get_tree().paused:
		return
	_paused_before = get_tree().paused
	_open = true
	_drag = Vector2.ZERO
	_highlight = -1
	_center = get_viewport().get_visible_rect().size * 0.5
	_rebuild_icons()
	get_tree().paused = true
	visible = true
	queue_redraw()

## select=false отменяет выбор (например, отпустили тач мимо кнопки).
func close(select: bool) -> void:
	if not _open:
		return
	_open = false
	get_tree().paused = _paused_before or GameManager.is_paused() or UIManager.is_hud_blocked()
	visible = false
	if select and _highlight >= 0:
		var hud: Node = get_parent()
		if is_instance_valid(hud) and hud.has_method("_use_quick_slot"):
			hud.call("_use_quick_slot", _highlight)

func _process(_delta: float) -> void:
	if not _open:
		return
	if _drag.length() > DEADZONE:
		var angle: float = _drag.angle()
		var slice: float = TAU / SLOT_COUNT
		# -90° сдвиг: слот 0 сверху, дальше по часовой.
		var a: float = fposmod(angle + PI * 0.5 + slice * 0.5, TAU)
		_highlight = int(a / slice)
	else:
		_highlight = -1
	for i: int in _icons.get_child_count():
		(_icons.get_child(i) as Control).modulate.a = 1.0 if i == _highlight else 0.65
	queue_redraw()

func _rebuild_icons() -> void:
	for child: Node in _icons.get_children():
		child.free()
	var bound: Array = QUICK_SLOTS.read()
	for i: int in SLOT_COUNT:
		var angle: float = -PI * 0.5 + TAU * i / SLOT_COUNT
		var root := Control.new()
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.position = _center + Vector2.from_angle(angle) * (RADIUS * 0.62) - Vector2(20, 20)
		_icons.add_child(root)
		if StringName(bound[i]) != &"":
			preload("res://scripts/ui/item_icons.gd").draw_icon(root, StringName(bound[i]), 40.0)

func _draw() -> void:
	if not _open:
		return
	draw_circle(_center, RADIUS + 30.0, Color(PANEL.r, PANEL.g, PANEL.b, 0.55))
	var slice: float = TAU / SLOT_COUNT
	var bound: Array = QUICK_SLOTS.read()
	for i in SLOT_COUNT:
		var mid: float = -PI * 0.5 + slice * i
		var col: Color = BRASS if i == _highlight else BRASS_DIM
		var p0 := _center + Vector2(cos(mid - slice * 0.5), sin(mid - slice * 0.5)) * RADIUS
		var p1 := _center + Vector2(cos(mid + slice * 0.5), sin(mid + slice * 0.5)) * RADIUS
		draw_line(_center, p0, col, 1.5)
		draw_line(_center, p1, col, 1.5)
		draw_arc(_center, RADIUS, mid - slice * 0.5, mid + slice * 0.5, 12, col, 2.0)
		var icon_pos: Vector2 = _center + Vector2(cos(mid), sin(mid)) * (RADIUS * 0.62)
		if _chrome != null:
			draw_texture_rect(_chrome, Rect2(icon_pos - Vector2(32, 32), Vector2(64, 64)), false,
				Color(1, 1, 1, 1) if i == _highlight else Color(1, 1, 1, 0.6))
		draw_string(get_theme_default_font(), icon_pos + Vector2(-20, 48), str(i + 1),
			HORIZONTAL_ALIGNMENT_CENTER, 40, 18, BONE if i == _highlight else BRASS)
	if _highlight >= 0:
		var item_id := StringName(bound[_highlight])
		var label: String = LocalizationManager.t("SCR_FONARIK") if item_id == &"flashlight" else LocalizationManager.name_for("ITEM_", item_id, "")
		draw_string(get_theme_default_font(), _center + Vector2(-240, RADIUS + 64), label,
			HORIZONTAL_ALIGNMENT_CENTER, 480, 22, BONE)
	draw_circle(_center, 10.0, BRASS if _highlight == -1 else BRASS_DIM)
