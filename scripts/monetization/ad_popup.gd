extends CanvasLayer
## Видимое окно «просмотра ролика» для заглушки рекламы.
##
## Без него весь поток был невидимым: таймер на 3 секунды и сигнал. Здесь игрок
## видит отсчёт, а забрать награду можно только нажав кнопку — то есть поток
## проверяется глазами, а не только автопилотом.
##
## Строится кодом: панель из четырёх узлов не стоит отдельной сцены.

signal claimed
signal dismissed

const WATCH_SEC: float = 3.0
const LAYER := 128  ## поверх HUD и меню

var _title: Label
var _status: Label
var _claim: Button
var _close: Button
var _left: float = WATCH_SEC

func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS  # окно живёт и на паузе

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP  # не кликать сквозь окно
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(420, 0)
	dim.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	_title = Label.new()
	_title.text = LocalizationManager.t("AD_TITLE")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.theme_type_variation = &"header"
	box.add_child(_title)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)

	_claim = Button.new()
	_claim.name = "ClaimButton"  # по этому имени кнопку находит автопилот
	_claim.text = LocalizationManager.t("AD_CLAIM")
	_claim.disabled = true
	_claim.pressed.connect(_on_claim)
	box.add_child(_claim)

	_close = Button.new()
	_close.text = LocalizationManager.t("AD_SKIP")
	_close.pressed.connect(_on_close)
	box.add_child(_close)

	_refresh()

func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(0.0, _left - delta)
	_refresh()

func _refresh() -> void:
	if _left > 0.0:
		_status.text = LocalizationManager.t("AD_WATCHING") % int(ceil(_left))
		_claim.disabled = true
	else:
		_status.text = LocalizationManager.t("AD_READY")
		_claim.disabled = false

## Награду отдаём только после отсчёта — кнопка до этого недоступна,
## но проверяем и здесь, чтобы программный вызов не обошёл правило.
func _on_claim() -> void:
	if _left > 0.0:
		return
	claimed.emit()
	queue_free()

func _on_close() -> void:
	dismissed.emit()
	queue_free()
