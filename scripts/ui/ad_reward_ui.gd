extends Control
## Ad reward offer UI — shows "Watch ad for reward" / "Skip for coins" options.

signal ad_option_selected(option: String)

@onready var _title: Label = $Panel/VBox/Title
@onready var _reward_label: Label = $Panel/VBox/RewardLabel
@onready var _watch_btn: Button = $Panel/VBox/HBox/WatchBtn
@onready var _skip_btn: Button = $Panel/VBox/HBox/SkipBtn
@onready var _close_btn: Button = $Panel/VBox/CloseBtn

var _reward_type: String = "coins"
var _reward_amount: int = 100

func _ready() -> void:
	_apply_localization()
	_watch_btn.pressed.connect(_on_watch)
	_skip_btn.pressed.connect(_on_skip)
	_close_btn.pressed.connect(_on_close)
	LocalizationManager.language_changed.connect(_apply_localization)

func _apply_localization(_lang: Variant = null) -> void:
	_title.text = LocalizationManager.t("ad_reward_title")
	_watch_btn.text = LocalizationManager.t("ad_watch")
	_skip_btn.text = LocalizationManager.t("ad_skip")
	_close_btn.text = LocalizationManager.t("ui_close")
	_reward_label.text = "+%d %s" % [_reward_amount, _reward_type]

func setup(reward_type: String, amount: int) -> void:
	_reward_type = reward_type
	_reward_amount = amount
	_reward_label.text = "+%d %s" % [_reward_amount, _reward_type]

func _on_watch() -> void:
	ad_option_selected.emit("watch")
	queue_free()

func _on_skip() -> void:
	ad_option_selected.emit("skip")
	queue_free()

func _on_close() -> void:
	queue_free()
