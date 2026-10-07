extends RefCounted
## rc16 closeout checks of uifx: wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const CHROMA_PX: float = 0.75
## Loaded at run time: the file does not exist on the code this check is proven against.
const QUICK_SLOTS_PATH: String = "res://scripts/ui/quick_slots.gd"
## Overlay layer name -> its letter in the tier table: vignette, grain, chromatic aberration, sprint motion blur.
const LAYER_LETTERS: Dictionary = {"VignetteOverlay": "V", "GrainOverlay": "G", "ChromaOverlay": "C", "MotionBlurOverlay": "B"}

static func run(r: Node) -> void:
	await _post_fx_tiers(r)
	await _damage_pulse(r)
	await _quick_slot_drag(r)
	await _hover(r)
	await _bar_shake(r)
	await _damage_numbers(r)

static func _overlay(r: Node) -> Node:
	return r._main.get_node_or_null("PostProcessOverlay")

static func _chroma_px(overlay: Node) -> float:
	var mat := (overlay.get_node("ChromaOverlay") as ColorRect).material as ShaderMaterial
	return float(mat.get_shader_parameter("amount_px_1080p"))

static func _blur_strength(overlay: Node) -> float:
	var blur := overlay.get_node_or_null("MotionBlurOverlay") as ColorRect
	return float((blur.material as ShaderMaterial).get_shader_parameter("strength")) if blur != null else -1.0

static func _layers_on(overlay: Node) -> String:
	var shown := ""
	for layer_name in LAYER_LETTERS:
		var layer := overlay.get_node_or_null(String(layer_name)) as CanvasItem
		if layer != null and layer.visible:
			shown += String(LAYER_LETTERS[layer_name])
	return shown

## The stick forward with run held, as the movement check drives it, or released.
static func _stick(on: bool) -> void:
	InputService.set_joy_active(on)
	InputService.set_joy_move_dir(Vector2(0.0, -1.0) if on else Vector2.ZERO)
	InputService.set_joy_run_held(on)

## The tier table while the player sprints for real (the blur follows the sprint).
static func _post_fx_tiers(r: Node) -> void:
	var overlay: Node = _overlay(r)
	r._ok(overlay != null, "UIFX1 the game scene carries the post-fx overlay")
	if overlay == null:
		return
	r._playing()
	var player: Node3D = r._player
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var pos0: Vector3 = player.global_position
	SettingsManager.set_graphics_tier(2)
	var chroma0: float = _chroma_px(overlay)
	overlay.call("set_chroma_amount", CHROMA_PX)  # a district preset: the aberration has something to show
	player.set("gameplay_active", true)
	_stick(true)
	var seen := PackedStringArray()
	for tier in 4:
		SettingsManager.set_graphics_tier(tier)
		player.set("stamina", 100.0)
		await r.get_tree().create_timer(0.8).timeout
		seen.append(_layers_on(overlay))
	var strength: float = _blur_strength(overlay)
	_stick(false)
	await r.get_tree().create_timer(1.2).timeout
	var after: String = _layers_on(overlay)
	r._ok(seen == PackedStringArray(["V", "VG", "VGC", "VGCB"]) and strength > 0.2 and strength <= 0.35 and after == "VGC",
		"UIFX1 the tier table while sprinting: Low the vignette alone, Medium + grain, High + chromatic aberration, Ultra + motion blur up to 0.35 (Low..Ultra: %s; blur %.2f; 1.2 s after the sprint: %s)" % [", ".join(seen), strength, after])
	overlay.call("set_chroma_amount", chroma0)
	SettingsManager.set_graphics_tier(tier0)
	player.global_position = pos0

## One hit through the real signal at a tier and Reduce Flash setting; the aberration on screen 0.05 s later.
static func _hit_at(r: Node, tier: int, reduce_flash: bool) -> float:
	SettingsManager.set_graphics_tier(tier)
	SettingsManager.set_setting("reduce_flash", reduce_flash)
	EventBus.player_damaged.emit(5.0)
	await r.get_tree().create_timer(0.05).timeout
	return _chroma_px(_overlay(r))

static func _damage_pulse(r: Node) -> void:
	var overlay: Node = _overlay(r)
	if overlay == null:
		return
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var flash0: bool = bool(SettingsManager.get_setting("reduce_flash", false))
	SettingsManager.set_graphics_tier(2)
	var chroma0: float = _chroma_px(overlay)
	overlay.call("set_chroma_amount", 0.0)  # nothing from the district, so only the hit can show
	var peak: float = await _hit_at(r, 2, false)
	await r.get_tree().create_timer(0.5).timeout
	var gone: bool = _chroma_px(overlay) == 0.0 and not (overlay.get_node("ChromaOverlay") as CanvasItem).visible
	var low: float = await _hit_at(r, 0, false)
	var calm: float = await _hit_at(r, 2, true)
	r._ok(peak > 0.0 and peak <= 2.0 and gone, "UIFX2 a hit pulses the chromatic aberration up to 2 px and it is gone 0.5 s later, the layer hidden again (%.2f px, gone %s)" % [peak, gone])
	r._ok(peak > 0.0 and low == 0.0 and calm == 0.0, "UIFX2 the pulse stays 0 at the Low tier and under Reduce Flash (%.2f px, %.2f px)" % [low, calm])
	SettingsManager.set_setting("reduce_flash", flash0)
	overlay.call("set_chroma_amount", chroma0)
	SettingsManager.set_graphics_tier(tier0)

## One tap of a key action through the real input path: a press, a frame, a release, a frame.
static func _tap(r: Node, action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await r.get_tree().process_frame

static func _bound_item(hud: Node, index: int) -> Variant:
	var bound: Variant = hud.get("_slot_items") if hud != null else null
	return (bound as Array)[index] if bound is Array else null

## QS2 / I9.7: the medkit cell is dragged onto quick-slot target 1, key 1 then uses a medkit, a right-click restores the pistol.
static func _quick_slot_drag(r: Node) -> void:
	r._playing()
	var hud: Node = r._main.get_node_or_null("HUD")
	var player: Node = r._player
	var quick_slots: Resource = load(QUICK_SLOTS_PATH) if ResourceLoader.exists(QUICK_SLOTS_PATH) else null
	var saved_slots: Variant = SettingsManager.get_setting("quick_slots", null)
	var saved_pack: Dictionary = InventoryManager.to_dict()
	var hp0: float = float(player.get("hp"))
	InventoryManager.from_dict({})
	InventoryManager.try_add(&"medkit", 2)
	var defaults: Variant = hud.get("_SLOT_ITEMS") if hud != null else null
	UIManager.open(&"inventory")
	await r.get_tree().process_frame
	await r.get_tree().process_frame
	var ui: Control = UIManager._get_screen(&"inventory")
	var cell: Node = null
	for child in ui.get("_grid").get_children():
		if child.get("item_id") == &"medkit":
			cell = child
	var target: Node = ui.find_child("QuickSlot0", true, false)
	var data: Variant = null
	if cell != null and cell.has_method("_get_drag_data"):
		data = cell.call("_get_drag_data", Vector2.ZERO)
	if data != null:
		r.get_viewport().gui_cancel_drag()  # drops the preview the drag would be showing
	var carries: bool = data is Dictionary and (data as Dictionary).values().has(&"medkit")
	var accepts: bool = target != null and target.has_method("_can_drop_data") and bool(target.call("_can_drop_data", Vector2.ZERO, data))
	if accepts:
		target.call("_drop_data", Vector2.ZERO, data)
	var rebound: bool = _bound_item(hud, 0) == &"medkit"
	UIManager.close(&"inventory")
	player.set("hp", 40.0)
	var medkits0: int = InventoryManager.count_of(&"medkit")
	await _tap(r, &"quick_slot_1")
	var medkits1: int = InventoryManager.count_of(&"medkit")
	var hp1: float = float(player.get("hp"))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	if target != null and target.has_method("_gui_input"):
		target.call("_gui_input", click)
	var restored: bool = defaults is Array and _bound_item(hud, 0) == (defaults as Array)[0]
	var forged_ok := false
	if quick_slots != null and defaults is Array:
		SettingsManager.set_setting("quick_slots", [&"medkit"])
		var short_list: Variant = quick_slots.call("read")
		SettingsManager.set_setting("quick_slots", [&"battery", &"bogus_item", &"medkit", &"battery", &"battery", &"battery"])
		forged_ok = short_list == defaults and quick_slots.call("read") == defaults
	r._ok(carries and accepts and rebound, "QS2 dragging the medkit cell onto quick slot 1 binds it (drag data %s, the target accepts %s, the HUD's slot 1 is %s)" % [data, accepts, _bound_item(hud, 0)])
	r._ok(rebound and medkits1 == medkits0 - 1 and hp1 > 40.0, "QS2 key 1 then uses a medkit (medkits %d -> %d, health 40 -> %.0f)" % [medkits0, medkits1, hp1])
	r._ok(rebound and restored, "QS2 a right-click on the slot puts the default item back (%s)" % [_bound_item(hud, 0)])
	r._ok(forged_ok, "QS2 a saved list that is not six known items falls back to the defaults")
	SettingsManager.set_setting("quick_slots", saved_slots)
	player.set("hp", hp0)
	EventBus.player_health_changed.emit(hp0 / float(player.stats.max_hp))  # the HUD's own memory of the health
	InventoryManager.from_dict(saved_pack)

## UIFX3: a button under the mouse swells to 1.05 about its centre and settles back; Reduce UI Motion keeps it still.
static func _hover(r: Node) -> void:
	var still0: bool = bool(SettingsManager.get_setting("reduce_ui_motion", false))
	var button := Button.new()
	button.custom_minimum_size = Vector2(120.0, 40.0)
	r.add_child(button)
	await r.get_tree().process_frame
	await r.get_tree().process_frame
	SettingsManager.set_setting("reduce_ui_motion", false)
	button.mouse_entered.emit()
	await r.get_tree().create_timer(0.2).timeout
	var swollen: float = button.scale.x
	var centred: bool = button.pivot_offset.is_equal_approx(button.size / 2.0)
	button.mouse_exited.emit()
	await r.get_tree().create_timer(0.2).timeout
	var settled: float = button.scale.x
	SettingsManager.set_setting("reduce_ui_motion", true)
	button.mouse_entered.emit()
	await r.get_tree().create_timer(0.2).timeout
	var calm: float = button.scale.x
	var grown: float = 1.0 if InputService.is_touch_device() else 1.05  # a touch device never grows buttons
	r._ok(absf(swollen - grown) < 0.01 and centred and absf(settled - 1.0) < 0.01 and calm == 1.0,
		"UIFX3 hovering a button scales it to 1.05 about its centre in 0.12 s and back, and Reduce UI Motion keeps it at 1.0 (%.3f, centred %s, %.3f, %.3f)" % [swollen, centred, settled, calm])
	button.queue_free()
	SettingsManager.set_setting("reduce_ui_motion", still0)

## UIFX5: a hit shakes the health bar by at most 4 px and it is back on its exact place after 0.4 s; Reduce Screen Shake keeps it still.
static func _bar_shake(r: Node) -> void:
	var hud: Node = r._main.get_node_or_null("HUD")
	var bar: Control = hud.get_node_or_null("TopLeft/HP") as Control if hud != null else null
	r._ok(bar != null, "UIFX5 the HUD has its health bar row")
	if bar == null:
		return
	var shake0: bool = bool(SettingsManager.get_setting("reduce_screen_shake", false))
	var rest: Vector2 = bar.position
	SettingsManager.set_setting("reduce_screen_shake", false)
	EventBus.player_damaged.emit(5.0)
	await r.get_tree().create_timer(0.08).timeout
	var off: Vector2 = (bar.position - rest).abs()
	var shaken: bool = off != Vector2.ZERO and off.x <= 4.0 and off.y <= 4.0
	await r.get_tree().create_timer(0.4).timeout
	var home: bool = bar.position == rest
	SettingsManager.set_setting("reduce_screen_shake", true)
	EventBus.player_damaged.emit(5.0)
	await r.get_tree().create_timer(0.08).timeout
	var calm: bool = bar.position == rest
	await r.get_tree().create_timer(0.3).timeout
	SettingsManager.set_setting("reduce_screen_shake", shake0)
	r._ok(shaken and home, "UIFX5 a hit shakes the health bar by at most 4 px (%s) and it is on its exact place 0.4 s later (%s)" % [off, home])
	r._ok(shaken and calm, "UIFX5 under Reduce Screen Shake the health bar stays where it is")

static func _visible_numbers(pool: Node) -> Array:
	var shown: Array = []
	for label in (pool.get_children() if pool != null else []):
		if label.visible:
			shown.append(label.text)
	return shown

## UIFX4: a monster that takes a hit shows its damage as a floating number from the HUD's pool of 12, back in the pool 1.0 s later.
static func _damage_numbers(r: Node) -> void:
	r._playing()
	var hud: Node = r._main.get_node_or_null("HUD")
	var pool: Node = hud.get_node_or_null("DamageNumbers") if hud != null else null
	var player: Node3D = r._player
	var aim: Vector3 = -player.global_transform.basis.z
	aim.y = 0.0
	var monster: Node3D = r._monster("rotter_3d", player.global_position + aim.normalized() * 4.0)
	var hp0: float = float(monster.get("hp"))
	monster.call("take_damage", 7.0)
	await r.get_tree().process_frame
	var dealt: String = str(roundi(hp0 - float(monster.get("hp"))))
	var shown: Array = _visible_numbers(pool)
	await r.get_tree().create_timer(1.0).timeout
	r._ok(pool != null and shown == [dealt] and _visible_numbers(pool).is_empty() and pool.get_child_count() == 12,
		"UIFX4 a monster hit for %s shows that number and it is back in the pool of 12 after 1.0 s (shown %s, pool %s, signal %s)" % [dealt, shown, pool.get_child_count() if pool != null else "missing", EventBus.has_signal(&"enemy_damaged")])
	monster.queue_free()
