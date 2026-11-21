extends VBoxContainer

## The owning screen controls visibility. Only offers the player can see are polled.
var reward_id: StringName
var preferred_width_px := 0.0
var _action_key: String
var _title := Label.new()
var _claim := Button.new()
var _reason := Label.new()
var _watching := false
var _requested := false
var _state: StringName = &"BONUS_CHECKING"
var _seconds_left := 0
var _save_failed := false

func _init(id: StringName, action_key: String) -> void:
	reward_id = id
	_action_key = action_key

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_PASS
	for label: Label in [_title, _reason]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 3)
	_claim.icon = preload("res://assets/textures/ui_craft/icon_wifi_bonus_64.png")
	_claim.add_theme_constant_override("icon_max_width", 20)
	_claim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_title)
	add_child(_claim)
	add_child(_reason)
	_claim.pressed.connect(_request)
	WiFiBonusService.availability_changed.connect(_on_availability)
	WiFiBonusService.claim_failed.connect(_on_failure)
	WiFiBonusService.claimed.connect(_on_claimed)
	LocalizationManager.language_changed.connect(_render.unbind(1))
	visibility_changed.connect(_sync_visibility)
	get_viewport().size_changed.connect(_fit)
	_fit()
	_render()
	_sync_visibility()

func _fit() -> void:
	# Headless windows have no physical display and report a placeholder size.
	var ratio := 1.0
	if DisplayServer.get_name() != "headless":
		ratio = maxf(float(get_window().size.x) / maxf(get_viewport_rect().size.x, 1.0), 0.1)
	var scale_index := clampi(int(SettingsManager.get_setting("text_size", 1)), 0, 2)
	var text_scale: float = SettingsManager.TEXT_SCALE[scale_index]
	for control: Control in [_title, _claim, _reason]:
		control.add_theme_font_size_override("font_size", ceili(18.0 * text_scale / ratio))
	_claim.custom_minimum_size = Vector2.ONE * maxf(UiScale.min_touch(), ceilf(48.0 / ratio))
	if preferred_width_px > 0.0:
		custom_minimum_size.x = preferred_width_px / ratio
		size.x = custom_minimum_size.x

func _exit_tree() -> void:
	if _watching and is_instance_valid(WiFiBonusService):
		_watching = false
		WiFiBonusService.close_offer(reward_id)

func _sync_visibility() -> void:
	var showing := is_visible_in_tree()
	if showing == _watching:
		return
	_watching = showing
	_save_failed = false
	if showing:
		WiFiBonusService.open_offer(reward_id)
	else:
		WiFiBonusService.close_offer(reward_id)

func _request() -> void:
	_requested = true
	_save_failed = false
	WiFiBonusService.request_claim(reward_id)

func _on_availability(id: StringName, state: StringName, seconds_left: int) -> void:
	if id != reward_id or not _watching:
		return
	_state = state
	_seconds_left = seconds_left
	if state != &"BONUS_READY":
		_save_failed = false
	_render()

func _on_failure(id: StringName, reason: StringName) -> void:
	if id != reward_id or not _requested:
		return
	_requested = false
	if reason == &"BONUS_SAVE_FAILED":
		_save_failed = true
	else:
		_state = reason
	_render()

func _on_claimed(id: StringName) -> void:
	if id != reward_id or not _requested:
		return
	_requested = false
	UIManager.show_notification(tr("BONUS_GRANTED"))

func _render() -> void:
	_title.text = tr("BONUS_TITLE_WIFI") if OS.get_name() == "Android" else tr("BONUS_TITLE_NETWORK")
	_claim.text = tr(_action_key)
	_claim.disabled = _state != &"BONUS_READY"
	if _save_failed:
		_reason.text = tr("BONUS_SAVE_FAILED")
	elif _state == &"BONUS_COOLDOWN":
		_reason.text = tr("BONUS_COOLDOWN") % ("%d:%02d" % [_seconds_left / 60, _seconds_left % 60])
	else:
		_reason.text = tr(_state)
