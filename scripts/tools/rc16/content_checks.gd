extends RefCounted
## rc16 closeout checks of content: wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const RIFLE: PackedScene = preload("res://scenes/weapons/weapon_rifle.tscn")
## A point high above the street: a shot straight up from here meets nothing that can take damage.
const SKY_SHOT_FROM := Vector3(480.0, 60.0, 480.0)
const WORKBENCH := preload("res://scripts/crafting/workbench_logic.gd")
const PINCH_STEPS: int = 5

static func run(r: Node) -> void:
	await _fire1_cooldown_ticks_with_physics(r)
	await _ct7_pinch_zooms_the_camera(r)
	_e11_a_refund_is_not_a_find(r)
	await _e13_battery_drains_behind_a_screen(r)

## FIRE1: the cooldown and the reload count on the physics tick that polls the trigger, not on the frame.
static func _fire1_cooldown_ticks_with_physics(r: Node) -> void:
	var rifle := RIFLE.instantiate() as WeaponBase
	r.add_child(rifle)
	rifle.set_process(false)
	r._ok(rifle.fire(SKY_SHOT_FROM, Vector3.UP) and not rifle.can_fire(), "FIRE1 a shot starts the cooldown")
	await r.get_tree().create_timer(0.5).timeout
	r._ok(rifle.can_fire(), "FIRE1 the cooldown runs on the physics tick: the rifle is ready 0.5 s after a shot with _process off")
	rifle.queue_free()

## Touch events go to the player's own _input, as the swipe check of the runner does: Input.parse_input_event would
## also emulate a mouse from the first finger, and a captured mouse would turn the view on its own.
static func _touch(player: Node, index: int, pressed: bool, at: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = index
	press.pressed = pressed
	press.position = at
	player._input(press)

static func _drag(player: Node, index: int, at: Vector2, by: Vector2) -> void:
	var drag := InputEventScreenDrag.new()
	drag.index = index
	drag.position = at
	drag.relative = by
	player._input(drag)

## Two fingers moving apart (or together) around `mid`, one drag event per finger and a physics frame between the steps.
static func _pinch(r: Node, player: Node, mid: Vector2, from_half: float, to_half: float) -> void:
	var step: float = (to_half - from_half) / PINCH_STEPS
	for i in range(1, PINCH_STEPS + 1):
		var half: float = from_half + step * i
		_drag(player, 0, mid - Vector2(half, 0.0), Vector2(-step, 0.0))
		_drag(player, 1, mid + Vector2(half, 0.0), Vector2(step, 0.0))
		await r.get_tree().physics_frame

## CT7: two fingers that land together in the look zone pinch the camera zoom and leave the look alone.
static func _ct7_pinch_zooms_the_camera(r: Node) -> void:
	var cam: Node = r._main.get_node_or_null("Camera3D")
	var has_zoom: bool = cam != null and cam.has_method("get_zoom_factor")
	r._ok(has_zoom, "CT7 the camera exposes its zoom factor")
	if not has_zoom:
		return
	r._playing()
	var player: Node3D = r._player
	var yaw0: float = player.rotation.y
	var pitch0: float = float(player.get("_pitch"))
	var mid: Vector2 = r.get_viewport().get_visible_rect().size * Vector2(0.7, 0.4)
	r._ok(is_equal_approx(float(cam.call("get_zoom_factor")), 1.0), "CT7 the camera rests at zoom 1.0")
	_touch(player, 0, true, mid - Vector2(150.0, 0.0))
	_touch(player, 1, true, mid + Vector2(150.0, 0.0))
	await _pinch(r, player, mid, 150.0, 225.0)
	await r.get_tree().create_timer(0.5).timeout
	var zoom_in: float = float(cam.call("get_zoom_factor"))
	r._ok(zoom_in > 1.2 and zoom_in <= 1.351, "CT7 two fingers spreading from 300 to 450 px zoom in to the 1.35 limit (%.3f)" % zoom_in)
	r._ok(is_equal_approx(player.rotation.y, yaw0) and is_equal_approx(float(player.get("_pitch")), pitch0), "CT7 the pinch does not turn the view")
	await _pinch(r, player, mid, 225.0, 150.0)
	await r.get_tree().create_timer(0.5).timeout
	var zoom_out: float = float(cam.call("get_zoom_factor"))
	r._ok(absf(zoom_out - 0.9) < 0.02, "CT7 the fingers closing back to 300 px zoom out to 1.35 x 300 / 450 = 0.9 (%.3f)" % zoom_out)
	_touch(player, 0, false, mid - Vector2(150.0, 0.0))
	_touch(player, 1, false, mid + Vector2(150.0, 0.0))
	await r.get_tree().create_timer(0.4).timeout
	r._ok(absf(float(cam.call("get_zoom_factor")) - zoom_out) < 0.01, "CT7 letting go keeps the zoom")
	_touch(player, 2, true, mid)
	_drag(player, 2, mid + Vector2(-40.0, 0.0), Vector2(-40.0, 0.0))
	_touch(player, 2, false, mid + Vector2(-40.0, 0.0))
	r._ok(absf(player.rotation.y - yaw0) > 0.005, "CT7 one finger still turns the view")
	player.rotation.y = yaw0
	_touch(player, 0, true, mid - Vector2(150.0, 0.0))
	await r.get_tree().create_timer(0.4).timeout
	_touch(player, 1, true, mid + Vector2(150.0, 0.0))
	_drag(player, 1, mid + Vector2(250.0, 0.0), Vector2(100.0, 0.0))
	r._ok(absf(player.rotation.y - yaw0) > 0.005 and absf(float(cam.call("get_zoom_factor")) - zoom_out) < 0.01, "CT7 a finger that lands long after the first looks around and does not zoom")
	_touch(player, 0, false, mid - Vector2(150.0, 0.0))
	_touch(player, 1, false, mid + Vector2(250.0, 0.0))
	cam.set("_zoom", 1.0)
	cam.set("_zoom_target", 1.0)
	var magnify := InputEventMagnifyGesture.new()
	magnify.factor = 1.2
	Input.parse_input_event(magnify)
	await r.get_tree().create_timer(0.5).timeout
	r._ok(float(cam.call("get_zoom_factor")) > 1.1, "CT7 a trackpad magnify gesture zooms in too")
	cam.set("_zoom", 1.0)
	cam.set("_zoom_target", 1.0)
	player.rotation.y = yaw0
	player.set("_pitch", pitch0)

## E11: a craft that does not fit gives its parts back, and the workbench's refund is not a find: a collect quest does
## not move, while a real pickup still counts once.
static func _e11_a_refund_is_not_a_find(r: Node) -> void:
	r._playing()
	var saved_quests: Dictionary = QuestManager.serialize()
	var saved_pack: Dictionary = InventoryManager.to_dict()
	var saved_picked: int = ProgressTracker.items_picked
	var capacity0: float = InventoryManager.stats.capacity_kg
	var quest: Dictionary = QuestManager.get_quest("q_collect_components")
	quest["progress"] = 0
	quest["done"] = false
	InventoryManager.from_dict({})
	InventoryManager.try_add(&"scrap", 1)
	InventoryManager.try_add(&"transistor", 1)
	var before: int = int(quest["progress"])
	InventoryManager.stats.capacity_kg = InventoryManager.current_weight + 0.5
	var heavy := {"id": "t", "name_key": "x", "result": "transformer", "count": 1, "components": [["transistor", 1]]}
	var crafted: bool = WORKBENCH.craft(heavy)
	r._ok(not crafted and InventoryManager.count_of(&"transistor") == 1, "E11 the refund path ran: the transformer did not fit and the transistor came back")
	r._ok(int(quest["progress"]) == before, "E11 the refunded transistor is not counted as found (%d -> %d)" % [before, int(quest["progress"])])
	InventoryManager.stats.capacity_kg = capacity0
	InventoryManager.try_add(&"transistor", 1)
	r._ok(int(quest["progress"]) == before + 1, "E11 a real pickup of a transistor still counts once (%d -> %d)" % [before, int(quest["progress"])])
	QuestManager.from_dict(saved_quests)
	InventoryManager.from_dict(saved_pack)
	ProgressTracker.items_picked = saved_picked

## E13: the inventory is a screen over a world that keeps running (the player walks, monsters act), so the flashlight
## battery keeps draining behind it.
static func _e13_battery_drains_behind_a_screen(r: Node) -> void:
	r._playing()
	var player: Node3D = r._player
	var light0: bool = bool(player.get("flashlight_enabled"))
	var battery0: float = float(player.get("battery"))
	var start: float = float(player.get("battery_max")) * 0.5
	player.set("flashlight_enabled", true)
	player.set("battery", start)
	UIManager.open(&"inventory")
	var blocked: bool = UIManager.is_hud_blocked()
	await r.get_tree().create_timer(1.0).timeout
	var drained: float = start - float(player.get("battery"))
	UIManager.close(&"inventory")
	var rate: float = float(player.get("BATTERY_DRAIN_PER_SEC"))
	r._ok(blocked, "E13 the open inventory counts as a blocking screen")
	r._ok(absf(drained - rate) <= rate * 0.3, "E13 the battery drains by about %.3f in 1 s behind the open inventory (%.3f)" % [rate, drained])
	player.set("battery", battery0)
	player.set("flashlight_enabled", light0)
