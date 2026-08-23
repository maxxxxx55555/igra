extends Control
## T15: удержание -> аналоговый радиальный выбор из 6 быстрых слотов.
## Работает и на ПК (мышь), и на тач-устройствах (BtnWheel в hud_3d.gd):
## угол считается по НАКОПЛЕННОМУ смещению указателя от точки открытия,
## а не по абсолютной позиции — курсор в игре обычно захвачен (CAPTURED),
## и накопленная относительная дельта работает одинаково для мыши и тача.

const RADIUS: float = 120.0
const DEADZONE: float = 18.0
const SLOT_COUNT: int = 6
const PANEL := Color("#141b24")
const BRASS := Color("#c9a24a")
const BRASS_DIM := Color("#3a3226")
const BONE := Color("#d8d2c4")

var _open: bool = false
var _drag: Vector2 = Vector2.ZERO
var _highlight: int = -1
var _center: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"quick_wheel") and not event.is_echo():
		open()
	elif event.is_action_released(&"quick_wheel") and _open:
		close(true)
	elif _open and event is InputEventMouseMotion:
		_drag += (event as InputEventMouseMotion).relative

func _input(event: InputEvent) -> void:
	if _open and event is InputEventScreenDrag:
		_drag += (event as InputEventScreenDrag).relative

func open() -> void:
	if _open:
		return
	_open = true
	_drag = Vector2.ZERO
	_highlight = -1
	_center = get_viewport().get_visible_rect().size * 0.5
	get_tree().paused = true
	visible = true
	queue_redraw()

## select=false отменяет выбор (например, отпустили тач мимо кнопки).
func close(select: bool) -> void:
	if not _open:
		return
	_open = false
	get_tree().paused = false
	visible = false
	if select and _highlight >= 0:
		var inv := get_tree().root.get_node_or_null("InventoryManager")
		if inv and inv.has_method("use_item"):
			inv.use_item(_highlight)

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
	queue_redraw()

func _draw() -> void:
	if not _open:
		return
	draw_circle(_center, RADIUS + 30.0, Color(PANEL.r, PANEL.g, PANEL.b, 0.55))
	var slice: float = TAU / SLOT_COUNT
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	for i in SLOT_COUNT:
		var mid: float = -PI * 0.5 + slice * i
		var col: Color = BRASS if i == _highlight else BRASS_DIM
		var p0 := _center + Vector2(cos(mid - slice * 0.5), sin(mid - slice * 0.5)) * RADIUS
		var p1 := _center + Vector2(cos(mid + slice * 0.5), sin(mid + slice * 0.5)) * RADIUS
		draw_line(_center, p0, col, 1.5)
		draw_line(_center, p1, col, 1.5)
		draw_arc(_center, RADIUS, mid - slice * 0.5, mid + slice * 0.5, 12, col, 2.0)
		var icon_pos: Vector2 = _center + Vector2(cos(mid), sin(mid)) * (RADIUS * 0.62)
		var s = inv.slots[i] if (inv and i < inv.slots.size()) else null
		if s != null:
			var item := ItemDatabase.get_item(s["item_id"])
			var label_col: Color = BONE if i == _highlight else BRASS_DIM
			if item != null:
				draw_string(ThemeDB.fallback_font, icon_pos - Vector2(24, 0), String(item.display_name),
					HORIZONTAL_ALIGNMENT_CENTER, 48, 12, label_col)
	draw_circle(_center, 10.0, BRASS if _highlight == -1 else BRASS_DIM)
