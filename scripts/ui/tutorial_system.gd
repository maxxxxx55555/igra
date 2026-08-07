extends Node

signal step_completed(step_id: String)
signal tutorial_completed()

const STEPS: Array = [
	{
		"id": "wake_up",
		"trigger": "auto",
		"text_key": "TUT_WAKE_UP",
		"position": Vector2(0, -200),
		"duration": 5.0
	},
	{
		"id": "flashlight",
		"trigger": "action",
		"action": "flashlight_toggle",
		"text_key": "TUT_FLASHLIGHT",
		"position": Vector2(0, -200),
		"duration": 0.0
	},
	{
		"id": "move",
		"trigger": "action",
		"action": "move",
		"text_key": "TUT_MOVE",
		"position": Vector2(0, -200),
		"duration": 0.0
	},
	{
		"id": "pickup",
		"trigger": "action",
		"action": "interact",
		"text_key": "TUT_PICKUP",
		"position": Vector2(0, -200),
		"duration": 0.0
	},
	{
		"id": "generator",
		"trigger": "area",
		"area_name": "GenTrigger",
		"text_key": "TUT_GENERATOR",
		"position": Vector2(0, -200),
		"duration": 0.0
	},
	{
		"id": "crouch",
		"trigger": "action",
		"action": "stealth",
		"text_key": "TUT_CROUCH",
		"position": Vector2(0, -200),
		"duration": 0.0
	},
	{
		"id": "dodge",
		"trigger": "action",
		"action": "dodge",
		"text_key": "TUT_DODGE",
		"position": Vector2(0, -200),
		"duration": 0.0
	},
	{
		"id": "attack",
		"trigger": "action",
		"action": "attack",
		"text_key": "TUT_ATTACK",
		"position": Vector2(0, -200),
		"duration": 0.0
	},
	{
		"id": "inventory",
		"trigger": "action",
		"action": "inventory_toggle",
		"text_key": "TUT_INVENTORY",
		"position": Vector2(0, -200),
		"duration": 0.0
	},
	{
		"id": "complete",
		"trigger": "auto",
		"text_key": "TUT_COMPLETE",
		"position": Vector2(0, -200),
		"duration": 3.0
	}
]

var _current_step: int = 0
var _hint_panel: Control = null
var _step_timer: float = 0.0
var _completed_steps: Array = []
var _tutorial_active: bool = false
var _waiting_for_action: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_load_progress()
	
	EventBus.game_started.connect(_on_game_started)
	InputService.attack_requested.connect(_on_attack)
	InputService.dodge_requested.connect(_on_dodge)
	InputService.flashlight_requested.connect(_on_flashlight)
	InputService.interact_requested.connect(_on_interact)

func _build_ui() -> void:
	_hint_panel = Control.new()
	_hint_panel.name = "TutorialHint"
	_hint_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_hint_panel.visible = false
	
	var bg := PanelContainer.new()
	bg.size = Vector2(500, 120)
	bg.anchors_preset = Control.PRESET_BOTTOM_WIDE
	bg.offset_bottom = -80
	bg.offset_top = 80
	bg.add_theme_stylebox_override("panel", _make_stylebox())
	_hint_panel.add_child(bg)
	
	var lbl := Label.new()
	lbl.name = "HintText"
	lbl.size = Vector2(460, 80)
	lbl.position = Vector2(20, 20)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	bg.add_child(lbl)
	
	var skip_btn := Button.new()
	skip_btn.text = "Пропустить"
	skip_btn.size = Vector2(100, 30)
	skip_btn.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	skip_btn.offset_bottom = -10
	skip_btn.offset_right = -10
	skip_btn.pressed.connect(_skip_tutorial)
	bg.add_child(skip_btn)
	
	add_child(_hint_panel)

func _make_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.07, 0.95)
	sb.border_color = Color(0.788, 0.635, 0.290)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	return sb

func _load_progress() -> void:
	if not FileAccess.file_exists("user://tutorial.cfg"):
		return
	var f = FileAccess.open("user://tutorial.cfg", FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data:
			_completed_steps = data.get("completed", [])

func _save_progress() -> void:
	var f = FileAccess.open("user://tutorial.cfg", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"completed": _completed_steps}))

func _on_game_started() -> void:
	if _is_tutorial_complete():
		return
	_tutorial_active = true
	_current_step = 0
	_show_step()

func _show_step() -> void:
	if _current_step >= STEPS.size():
		_complete_tutorial()
		return
	
	var step = STEPS[_current_step]
	if step["id"] in _completed_steps:
		_current_step += 1
		_show_step()
		return
	
	var lbl = _hint_panel.find_child("HintText", true, false) as Label
	if lbl:
		lbl.text = tr(step["text_key"])
	
	_hint_panel.visible = true
	_waiting_for_action = step["trigger"] != "auto"
	
	if step["trigger"] == "auto":
		_step_timer = step["duration"]
	elif step["trigger"] == "area":
		# Wait for area entered signal
		var area = get_tree().root.find_child(step["area_name"], true, false)
		if area:
			area.body_entered.connect(_on_tutorial_area_entered)

func _on_attack() -> void:
	_check_action("attack")

## InputService.dodge_requested передаёт направление (dir: Vector2) — параметр
## обязателен, иначе связь падает в рантайме при первом же рывке игрока.
func _on_dodge(_dir: Vector2) -> void:
	_check_action("dodge")

func _on_flashlight() -> void:
	_check_action("flashlight_toggle")

func _on_interact() -> void:
	_check_action("interact")

func _check_action(action: String) -> void:
	if not _tutorial_active or not _waiting_for_action:
		return
	if _current_step >= STEPS.size():
		return
	var step = STEPS[_current_step]
	if step["trigger"] == "action" and step["action"] == action:
		_complete_step()

func _on_tutorial_area_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if _current_step >= STEPS.size():
		return
	var step = STEPS[_current_step]
	if step["trigger"] == "area":
		_complete_step()

func _complete_step() -> void:
	if _current_step >= STEPS.size():
		return
	var step = STEPS[_current_step]
	_completed_steps.append(step["id"])
	_waiting_for_action = false
	_step_timer = 0.0
	_hint_panel.visible = false
	step_completed.emit(step["id"])
	_current_step += 1
	call_deferred("_show_step")

func _process(delta: float) -> void:
	if not _tutorial_active or _current_step >= STEPS.size():
		return
	var step = STEPS[_current_step]
	if step["trigger"] == "auto" and _step_timer > 0.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_complete_step()

func _skip_tutorial() -> void:
	_tutorial_active = false
	_hint_panel.visible = false
	_complete_tutorial()

func _complete_tutorial() -> void:
	_tutorial_active = false
	_hint_panel.visible = false
	if "complete" not in _completed_steps:
		_completed_steps.append("complete")
	_save_progress()
	tutorial_completed.emit()

func _is_tutorial_complete() -> bool:
	return "complete" in _completed_steps