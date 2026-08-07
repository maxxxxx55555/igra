extends Control
## Daily events UI — shows event countdown, bonus multiplier, rewards.

@onready var _title: Label = $Panel/VBox/Title
@onready var _timer_label: Label = $Panel/VBox/TimerLabel
@onready var _bonus_label: Label = $Panel/VBox/BonusLabel
@onready var _start_btn: Button = $Panel/VBox/StartBtn
@onready var _close_btn: Button = $Panel/VBox/CloseBtn

var _event_active: bool = false
var _time_remaining: float = 0.0

func _ready() -> void:
	_apply_localization()
	_close_btn.pressed.connect(_on_close)
	_start_btn.pressed.connect(_on_start)
	_update_display()
	LocalizationManager.language_changed.connect(_apply_localization)

func _apply_localization(_lang: Variant = null) -> void:
	_title.text = "DAILY EVENT"
	_close_btn.text = LocalizationManager.t("ui_close")
	_start_btn.text = "START"

func _process(delta: float) -> void:
	if _event_active:
		_time_remaining -= delta
		if _time_remaining <= 0:
			_event_active = false
			_on_event_end()
		_update_display()

func _update_display() -> void:
	if _event_active:
		var mins := int(_time_remaining) / 60
		var secs := int(_time_remaining) % 60
		_timer_label.text = "%02d:%02d" % [mins, secs]
		_start_btn.visible = false
	else:
		_timer_label.text = "00:00"
		_start_btn.visible = true
	_bonus_label.text = "BONUS: x%.1f" % _get_bonus()

func _get_bonus() -> float:
	if not SaveSystem:
		return 1.0
	var streak: int = SaveSystem.get_daily_streak()
	return 1.0 + minf(2.0, streak * 0.5)

func _on_start() -> void:
	_event_active = true
	_time_remaining = 3600.0
	SaveSystem.increment_daily_streak()
	EventBus.toast_requested.emit("Daily Event started!", "achievement")

func _on_event_end() -> void:
	EventBus.toast_requested.emit("Daily Event ended!", "achievement")

func _on_close() -> void:
	queue_free()
