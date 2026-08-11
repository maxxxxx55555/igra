extends CanvasLayer

# S11.1 Touch Layout
# Left bottom: Joystick (tap + drag, deadzone 15%)
# Left bottom double tap: Dodge
# Right bottom top: Attack (tap, combo = 3 taps)
# Right bottom bottom: Interact (contextual)
# Bottom center slots 1-4: Quick items
# Bottom center slot 5: Inventory
# Right top: Minimap toggle
# Right top gear: Pause

@onready var _root := get_viewport()

# Joystick
var _joy_area: Control
var _joy_knob: Control
var _joy_active: bool = false
var _joy_center: Vector2
var _joy_vector: Vector2 = Vector2.ZERO
var _joy_radius: float = 80.0
var _joy_last_tap_time: float = 0.0
var _joy_last_tap_pos: Vector2

# Attack button
var _attack_btn: TextureButton
var _attack_tap_count: int = 0
var _attack_tap_timer: float = 0.0
const COMBO_WINDOW: float = 0.8

# Interact button
var _interact_btn: TextureButton

# Quick item slots
var _item_slots: Array[TextureButton] = []
var _inv_btn: TextureButton

# Top right buttons
var _minimap_btn: TextureButton
var _pause_btn: TextureButton

# Flashlight button
var _flash_btn: TextureButton

func _ready() -> void:
	if OS.has_feature("pc"):
		visible = false
		return
	visible = true
	_build_ui()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _build_ui() -> void:
	var vp_size := _root.get_visible_rect().size
	
	# ===== LEFT JOYSTICK AREA =====
	_joy_area = Control.new()
	_joy_area.name = "JoyArea"
	_joy_area.size = Vector2(vp_size.x * 0.5, vp_size.y)
	_joy_area.position = Vector2(0, 0)
	_joy_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_joy_area)
	
	var joy_bg := ColorRect.new()
	joy_bg.name = "JoyBG"
	joy_bg.size = Vector2(_joy_radius * 2.5, _joy_radius * 2.5)
	joy_bg.position = Vector2(40, vp_size.y - joy_bg.size.y - 40)
	joy_bg.color = Color(0.2, 0.2, 0.25, 0.5)
	joy_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var joy_bg_corner := StyleBoxFlat.new()
	joy_bg_corner.corner_radius_all = joy_bg.size.x / 2
	joy_bg.add_theme_stylebox_override("normal", joy_bg_corner)
	_joy_area.add_child(joy_bg)
	
	_joy_knob = ColorRect.new()
	_joy_knob.name = "JoyKnob"
	_joy_knob.size = Vector2(_joy_radius * 0.6, _joy_radius * 0.6)
	_joy_knob.position = joy_bg.position + (joy_bg.size - _joy_knob.size) / 2
	_joy_knob.color = Color(0.8, 0.6, 0.3, 0.7)
	_joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_sb := StyleBoxFlat.new()
	knob_sb.corner_radius_all = _joy_knob.size.x / 2
	_joy_knob.add_theme_stylebox_override("normal", knob_sb)
	_joy_area.add_child(_joy_knob)
	_joy_center = _joy_knob.position

	# ===== RIGHT ACTION BUTTONS =====
	var right_x := vp_size.x - 140
	var bottom_y := vp_size.y - 100
	
	# Attack button (top right of action cluster)
	_attack_btn = TextureButton.new()
	_attack_btn.name = "AttackBtn"
	_attack_btn.custom_minimum_size = Vector2(80, 80)
	_attack_btn.position = Vector2(right_x, bottom_y)
	_attack_btn.texture_normal = _make_circle_texture(Color(0.8, 0.3, 0.2, 0.8), 80)
	_attack_btn.texture_pressed = _make_circle_texture(Color(1.0, 0.5, 0.3, 0.9), 80)
	_attack_btn.add_theme_font_size_override("font_size", 14)
	_attack_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(_attack_btn)
	_attack_btn.pressed.connect(_on_attack_pressed)
	
	# Interact button (below attack)
	_interact_btn = TextureButton.new()
	_interact_btn.name = "InteractBtn"
	_interact_btn.custom_minimum_size = Vector2(70, 70)
	_interact_btn.position = Vector2(right_x + 5, bottom_y + 90)
	_interact_btn.texture_normal = _make_circle_texture(Color(0.3, 0.6, 0.8, 0.8), 70)
	_interact_btn.texture_pressed = _make_circle_texture(Color(0.5, 0.8, 1.0, 0.9), 70)
	add_child(_interact_btn)
	_interact_btn.pressed.connect(func() -> void: Input.action_press("interact"))
	_interact_btn.button_up.connect(func() -> void: Input.action_release("interact"))
	
	# Flashlight button (left of attack)
	_flash_btn = TextureButton.new()
	_flash_btn.name = "FlashBtn"
	_flash_btn.custom_minimum_size = Vector2(60, 60)
	_flash_btn.position = Vector2(right_x - 70, bottom_y + 10)
	_flash_btn.texture_normal = _make_circle_texture(Color(0.8, 0.7, 0.3, 0.8), 60)
	_flash_btn.texture_pressed = _make_circle_texture(Color(1.0, 0.9, 0.5, 0.9), 60)
	add_child(_flash_btn)
	_flash_btn.pressed.connect(func() -> void: 
		var isv = get_node_or_null("/root/InputService")
		if isv: isv.request_flashlight()
	)

	# ===== BOTTOM CENTER - QUICK ITEM SLOTS =====
	var slot_count = 5
	var slot_size = 60
	var slot_gap = 8
	var total_width = slot_count * slot_size + (slot_count - 1) * slot_gap
	var start_x = (vp_size.x - total_width) / 2
	var slot_y = vp_size.y - slot_size - 20
	
	for i in range(slot_count):
		var slot = TextureButton.new()
		slot.name = "ItemSlot_%d" % (i + 1)
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.position = Vector2(start_x + i * (slot_size + slot_gap), slot_y)
		slot.texture_normal = _make_rect_texture(Color(0.15, 0.18, 0.22, 0.9), slot_size, 8)
		slot.texture_pressed = _make_rect_texture(Color(0.25, 0.28, 0.32, 0.9), slot_size, 8)
		if i == 4:  # Slot 5 = Inventory
			slot.text = "INV"
			slot.add_theme_font_size_override("font_size", 10)
			slot.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
			slot.pressed.connect(_open_inventory)
		else:
			slot.text = str(i + 1)
			slot.add_theme_font_size_override("font_size", 12)
			slot.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
			var idx = i
			slot.pressed.connect(func() -> void: _use_quick_slot(idx))
		add_child(slot)
		_item_slots.append(slot)
	_inv_btn = _item_slots[4]

	# ===== TOP RIGHT - MINIMAP & PAUSE =====
	var top_right_x := vp_size.x - 70
	var top_y := 20
	
	# Minimap toggle
	_minimap_btn = TextureButton.new()
	_minimap_btn.name = "MinimapBtn"
	_minimap_btn.custom_minimum_size = Vector2(50, 50)
	_minimap_btn.position = Vector2(top_right_x, top_y)
	_minimap_btn.texture_normal = _make_circle_texture(Color(0.2, 0.3, 0.4, 0.8), 50)
	_minimap_btn.texture_pressed = _make_circle_texture(Color(0.3, 0.5, 0.7, 0.9), 50)
	_minimap_btn.text = "MAP"
	_minimap_btn.add_theme_font_size_override("font_size", 9)
	_minimap_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(_minimap_btn)
	_minimap_btn.pressed.connect(func() -> void: 
		var ui = get_node_or_null("/root/UIManager")
		if ui: ui.toggle(&"city_map")
	)
	
	# Pause button (gear)
	_pause_btn = TextureButton.new()
	_pause_btn.name = "PauseBtn"
	_pause_btn.custom_minimum_size = Vector2(50, 50)
	_pause_btn.position = Vector2(top_right_x - 60, top_y)
	_pause_btn.texture_normal = _make_circle_texture(Color(0.3, 0.3, 0.35, 0.8), 50)
	_pause_btn.texture_pressed = _make_circle_texture(Color(0.5, 0.5, 0.55, 0.9), 50)
	_pause_btn.text = "⚙"
	_pause_btn.add_theme_font_size_override("font_size", 18)
	_pause_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(_pause_btn)
	_pause_btn.pressed.connect(func() -> void:
		var ui = get_node_or_null("/root/UIManager")
		if ui: ui.toggle(&"pause")
	)

func _make_circle_texture(color: Color, size: float) -> Texture2D:
	var img := Image.create(int(size), int(size), false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2, size / 2)
	var radius := size / 2
	for y in range(int(size)):
		for x in range(int(size)):
			if Vector2(x, y).distance_to(center) <= radius:
				img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)
	return tex

func _make_rect_texture(color: Color, size: float, radius: float) -> Texture2D:
	var img := Image.create(int(size), int(size), false, Image.FORMAT_RGBA8)
	for y in range(int(size)):
		for x in range(int(size)):
			var dx = max(abs(x - size/2) - size/2 + radius, 0)
			var dy = max(abs(y - size/2) - size/2 + radius, 0)
			if dx*dx + dy*dy <= radius*radius or (x >= radius and x < size-radius and y >= radius and y < size-radius):
				img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)
	return tex

func _on_attack_pressed() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _attack_tap_timer <= COMBO_WINDOW:
		_attack_tap_count += 1
	else:
		_attack_tap_count = 1
	_attack_tap_timer = now
	
	if _attack_tap_count >= 3:
		_attack_tap_count = 0
	Input.action_press("attack")

func _use_quick_slot(index: int) -> void:
	var im = get_node_or_null("/root/InventoryManager")
	if im and im.has_method("use_slot"):
		im.use_slot(index)

func _open_inventory() -> void:
	var ui = get_node_or_null("/root/UIManager")
	if ui: ui.toggle(&"inventory")

func _process(delta: float) -> void:
	# Handle joystick input
	if _joy_active:
		Input.action_press("move_left") if _joy_vector.x < -0.15 else Input.action_release("move_left")
		Input.action_press("move_right") if _joy_vector.x > 0.15 else Input.action_release("move_right")
		Input.action_press("move_up") if _joy_vector.y < -0.15 else Input.action_release("move_up")
		Input.action_press("move_down") if _joy_vector.y > 0.15 else Input.action_release("move_down")
	
	# Handle attack combo window
	if _attack_tap_count > 0:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _attack_tap_timer > COMBO_WINDOW:
			_attack_tap_count = 0

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_handle_touch(event)

func _handle_touch(event: InputEvent) -> void:
	var pos: Vector2 = event.position
	var vp_size := _root.get_visible_rect().size
	
	# Check if touch is in joystick area (left 50% of screen, bottom half)
	var in_joy_area: bool = pos.x < vp_size.x * 0.5 and pos.y > vp_size.y * 0.4
	
	if in_joy_area:
		if event is InputEventScreenTouch:
			var now := Time.get_ticks_msec() / 1000.0
			if event.pressed:
				# Check for double tap (dodge)
				if now - _joy_last_tap_time < 0.3 and pos.distance_to(_joy_last_tap_pos) < 50:
					_trigger_dodge()
					_joy_last_tap_time = 0
				else:
					_joy_last_tap_time = now
					_joy_last_tap_pos = pos
				
				_joy_active = true
				_joy_center = pos
				_joy_knob.position = pos
			else:
				_joy_active = false
				_joy_vector = Vector2.ZERO
				_joy_knob.position = _joy_center
		elif event is InputEventScreenDrag and _joy_active:
			var diff = pos - _joy_center
			var dist = min(diff.length(), _joy_radius)
			_joy_vector = diff.normalized() * (dist / _joy_radius) if dist > 0 else Vector2.ZERO
			_joy_knob.position = _joy_center + _joy_vector * _joy_radius

func _trigger_dodge() -> void:
	var isv = get_node_or_null("/root/InputService")
	if isv:
		# Dodge in current joystick direction or forward
		var dir := _joy_vector if _joy_vector.length() > 0.1 else Vector2(0, -1)
		isv.request_dodge(dir)