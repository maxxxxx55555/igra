extends Control
@onready var btn_run: Button = $BtnRun
@onready var btn_stealth: Button = $BtnStealth
@onready var btn_interact: Button = $BtnInteract
@onready var btn_bag: Button = $BtnBag
@onready var btn_shop: Button = $BtnShop
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for b in [btn_run, btn_stealth, btn_interact, btn_bag, btn_shop]:
		if is_instance_valid(b):
			b.focus_mode = Control.FOCUS_NONE
	if is_instance_valid(btn_stealth):
		btn_stealth.toggle_mode = true
	if is_instance_valid(btn_run):
		btn_run.button_down.connect(func() -> void: InputService.set_joy_run_held(true))
		btn_run.button_up.connect(func() -> void: InputService.set_joy_run_held(false))
	if is_instance_valid(btn_stealth):
		btn_stealth.toggled.connect(func(on: bool) -> void: InputService.set_joy_stealth_toggled(on))
	if is_instance_valid(btn_interact):
		btn_interact.pressed.connect(func() -> void: InputService.request_interact())
	if is_instance_valid(btn_bag):
		btn_bag.pressed.connect(func() -> void: EventBus.inventory_toggle_requested.emit())
	if is_instance_valid(btn_shop):
		btn_shop.pressed.connect(func() -> void: EventBus.shop_toggle_requested.emit())
