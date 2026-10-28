extends RefCounted
## Regressions for the final source handoff. CLOSEOUT_ONLY=final runs these
## together with the daily claim and ending checks in the closeout runner.

const QUICK := preload("res://scripts/ui/quick_slots.gd")
const HUD := preload("res://scenes/ui/hud_3d.tscn")
const SECRET := preload("res://scripts/world/secret.gd")

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	var hud: Node = r._main.get_node_or_null("HUD")
	if hud == null:
		r._ok(false, "FINAL0 the main scene has its HUD")
		return
	_initial_vitals(r)
	_thermal(r, hud)
	_wheel(r, hud)
	_toasts(r)
	await _secret_save(r)
	r._playing()

## A save is JSON: a number comes back from it as a float, and {"a": 1} == {"a": 1.0} is false, so the live value takes the same trip before the two are compared.
static func same_json(saved: Variant, live: Variant) -> bool:
	return saved == JSON.parse_string(JSON.stringify(live))

static func _initial_vitals(r: Node) -> void:
	var player: Node = r._player
	var keep_stats: Resource = player.get("stats")
	var keep: Array = [player.get("hp"), player.get("stamina"), player.get("battery"), player.get("battery_max")]
	var stats: Resource = keep_stats.duplicate()
	stats.set("max_hp", 100.0)
	stats.set("stamina_max", 200.0)
	player.set("stats", stats)
	player.set("hp", 40.0)
	player.set("stamina", 60.0)
	player.set("battery_max", 150.0)
	player.set("battery", 75.0)
	var fresh: Node = HUD.instantiate()
	r.add_child(fresh)
	var correct: bool = is_equal_approx(float(fresh.get("_hp")), 0.4) and is_equal_approx(float(fresh.get("_stam")), 0.3) and is_equal_approx(float(fresh.get("_bat")), 0.5)
	correct = correct and fresh.get_node("TopLeft/HP/HPVal").text == "40" and fresh.get_node("TopLeft/Bat/BatVal").text == "50"
	r._ok(correct, "VITALS1 a new HUD reads saved vitals and upgraded capacities before any change event")
	fresh.free()
	player.set("stats", keep_stats)
	for index: int in keep.size():
		player.set(["hp", "stamina", "battery", "battery_max"][index], keep[index])

static func _thermal(r: Node, hud: Node) -> void:
	var id := StringName(DistrictManager.current_district)
	var stage: int = PowerGrid.get_stage(id)
	var badge: Label = hud.get_node_or_null("StatusRow/ThermalComfort") as Label
	var states: Array[StringName] = [&"cold", &"warming", &"warming", &"warm"]
	var correct: bool = badge != null
	for value: int in states.size():
		PowerGrid._set_stage_direct(id, value)
		correct = correct and PowerGrid.get_thermal_comfort(id) == states[value]
		correct = correct and badge != null and badge.get("comfort_state") == states[value] and not badge.text.is_empty()
	r._ok(correct, "THERMAL1 district stages drive the localized cold/cool/warm badge without a survival timer")
	PowerGrid._set_stage_direct(id, stage)

static func _wheel(r: Node, hud: Node) -> void:
	var wheel: Control = hud.get("_quick_wheel") as Control
	if wheel == null:
		r._ok(false, "WHEEL0 the HUD owns a quick wheel")
		return
	var inventory: Dictionary = InventoryManager.to_dict().duplicate(true)
	var binding: Variant = SettingsManager.get_setting(QUICK.KEY, null)
	var hp: float = float(r._player.get("hp"))
	InventoryManager.from_dict({})
	InventoryManager.try_add(&"battery", 2)
	InventoryManager.try_add(&"medkit", 2)
	SettingsManager.set_setting(QUICK.KEY, QUICK.DEFAULTS.duplicate())
	QUICK.bind(2, &"medkit")
	r._player.set("hp", 20.0)
	wheel.call("open")
	var opened: bool = bool(wheel.get("_open")) and r.get_tree().paused
	wheel.set("_highlight", 2)
	wheel.call("close", true)
	r._ok(opened and InventoryManager.count_of(&"medkit") == 1 and InventoryManager.count_of(&"battery") == 2,
		"WHEEL1 selecting a rebound medkit consumes that item regardless of backpack order")
	wheel.call("open")
	GameManager.pause_game()
	wheel.call("close", false)
	r._ok(r.get_tree().paused, "WHEEL2 closing the wheel cannot resume a paused game")
	wheel.call("open")
	r._ok(not bool(wheel.get("_open")), "WHEEL3 the wheel cannot open over Pause")
	GameManager.resume_game()
	r._playing()
	SettingsManager.set_setting(QUICK.KEY, binding)
	InventoryManager.from_dict(inventory)
	r._player.set("hp", hp)

static func _toasts(r: Node) -> void:
	var manager: Node = r._main.get_node_or_null("ToastManager")
	if manager == null:
		r._ok(false, "TOAST0 the main scene owns its toast manager")
		return
	var trailer: Variant = SettingsManager.get_setting("trailer_mode", false)
	SettingsManager.set_setting("trailer_mode", false)
	EventBus.hud_visibility_changed.emit(false)
	EventBus.toast_requested.emit("release modal probe", "info")
	var stack: Control = manager.get("_stack") as Control
	r._ok(stack != null and not stack.visible and not (manager.get("_queue") as Array).is_empty(),
		"TOAST1 a modal hides the stack and defers new toasts")
	EventBus.hud_visibility_changed.emit(true)
	r._ok(stack != null and stack.visible, "TOAST2 the stack resumes with the HUD")
	SettingsManager.set_setting("trailer_mode", trailer)

static func _secret_save(r: Node) -> void:
	var inventory: Dictionary = InventoryManager.to_dict().duplicate(true)
	var progress: Dictionary = ProgressTracker.to_dict().duplicate(true)
	var wallet: Dictionary = CoinWallet.to_dict().duplicate(true)
	var photos: Array = SaveSystem.get_photos()
	var autosave: Variant = SettingsManager.get_setting("autosave", true)
	SettingsManager.set_setting("autosave", true)
	InventoryManager.from_dict({})
	var secret: Node3D = SECRET.new()
	secret.set("secret_id", &"release_secret_probe")
	r.add_child(secret)
	secret.call("interact", r._player)
	await r.get_tree().process_frame
	await r.get_tree().process_frame
	var saved: Dictionary = SaveSystem._read_validated(SaveSystem.SAVE_PATH)
	var saved_progress: Dictionary = saved.get("progress", {})
	r._ok((saved_progress.get("secret_ids", []) as Array).has("release_secret_probe") and int(saved_progress.get("secrets", -1)) == ProgressTracker.secrets,
		"SECRETSAVE1 the milestone save contains the collected secret and its counter")
	r._ok(same_json(saved.get("wallet", {}), CoinWallet.to_dict()) and same_json(saved.get("inventory", {}), InventoryManager.to_dict()),
		"SECRETSAVE2 the same save contains the item's inventory and all synchronous rewards")
	InventoryManager.from_dict(inventory)
	ProgressTracker.from_dict(progress)
	CoinWallet.from_dict(wallet)
	SaveSystem._photos = photos
	SettingsManager.set_setting("autosave", autosave)
	SaveSystem.save_all()
