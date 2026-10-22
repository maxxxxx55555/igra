extends RefCounted
## Session 29 (the v1.0.0-ship pass), C block, the quick bar: QSLOT1 the bar of an empty run is [flashlight] and the pistol adds its slot (C8), QSLOT2 with 0, 1, 2 and 3 guns found every key and tap uses its slot of the six (C9),
## WCMP1 the weapon comparison of the HUD finds the player's WeaponManager (C10). The bar hides slots and does not renumber them: the keys and the taps name the slots of the six. The tested file is loaded when the checks run, so a tree without QuickSlots.visible_defaults fails the check and does not stop the run.
## Wired into _closeout_check_runner.gd next to s29_pickup_checks.gd; CLOSEOUT_ONLY=s29 runs it.

const _QUICK: String = "res://scripts/ui/quick_slots.gd"

static func run(r: Node) -> void:
	r._playing()
	await _quick_bar(r)
	r._playing()

## the bar of an empty run is [flashlight]; the pistol adds its slot; with 0 guns, the pistol, the pistol and the rifle and all three, every slot is used by its key and by a tap as its icon says.
static func _quick_bar(r: Node) -> void:
	var hud: Node = r._main.get_node_or_null("HUD")
	var quick: Script = load(_QUICK) if ResourceLoader.exists(_QUICK) else null
	var manager: Node = r._player.get_node_or_null("WeaponManager")
	if hud == null or manager == null or quick == null or not quick.has_method("visible_defaults"):
		r._ok(false, "QSLOT1 the HUD, the WeaponManager and QuickSlots.visible_defaults exist")
		r._ok(false, "QSLOT2 the keys use the slots of the bar")
		return
	var wired: bool = false
	for link in manager.weapon_switched.get_connections():
		wired = wired or (link["callable"] as Callable).get_object().has_method("on_weapon_switched")
	r._ok(wired, "WCMP1 the weapon comparison of the HUD is connected to the WeaponManager of the player")
	var slots0: Variant = SettingsManager.get_setting("quick_slots", null)
	var pack0: Dictionary = InventoryManager.to_dict()
	var guns0: Dictionary = ProgressTracker._weapons.duplicate()
	var owned0: Dictionary = (manager.get("_weapons") as Dictionary).duplicate()
	ProgressTracker._weapons.clear()
	(manager.get("_weapons") as Dictionary).clear()
	SettingsManager.set_setting("quick_slots", null)
	InventoryManager.from_dict({})
	hud.call("_refresh_slot_badges")
	var start: Array = quick.call("visible_defaults")
	var hidden: bool = true
	for i in 5:
		hidden = hidden and not (hud.get_node("BottomCenter/Slot%d" % i) as Control).visible
	var lone: bool = start == [&"flashlight"] and hidden and (hud.get_node("BottomCenter/Slot5") as Control).visible
	ProgressTracker.unlock_weapon("pistol")
	hud.call("_refresh_slot_badges")
	var grown: Array = quick.call("visible_defaults")
	r._ok(lone and grown == [&"pistol", &"flashlight"] and (hud.get_node("BottomCenter/Slot0") as Control).visible, "QSLOT1 the bar of an empty run is %s and %s once the pistol is found (slot 1 on screen: %s)" % [start, grown, (hud.get_node("BottomCenter/Slot0") as Control).visible])
	ProgressTracker._weapons.clear()
	var flashes: Array[int] = [0]
	var on_flash := func() -> void: flashes[0] += 1
	InputService.flashlight_requested.connect(on_flash)
	var rows: Array[String] = []
	var presses: bool = true
	var order: Array[StringName] = [&"pistol", &"rifle", &"shotgun"]
	var bound: Array = quick.call("read")
	for owned in 4:
		InventoryManager.from_dict({})  # a key and a tap each use one of a stack of three: the stacks stay on the bar
		InventoryManager.try_add(&"medkit", 3)
		InventoryManager.try_add(&"battery", 3)
		if owned > 0:
			manager.call("unlock", order[owned - 1])
		hud.call("_refresh_slot_badges")
		var shown: Array = quick.call("visible_defaults")
		var want: Array = []
		for gun_slot in ([&"pistol", &"rifle"].slice(0, mini(owned, 2))):
			want.append(gun_slot)
		want.append_array([&"battery", &"medkit", &"flashlight"])
		presses = presses and shown == want
		# every slot of the six, on the bar or not, by its key and by a tap: the slot that is on the bar does what its icon says, the one that is not does nothing
		for index in 6:
			for by_key in [true, false]:
				manager.call("holster")
				flashes[0] = 0
				r._player.set("hp", 40.0)
				var medkits: int = InventoryManager.count_of(&"medkit")
				if by_key:
					hud.call("_on_quick_slot_key", index)
				else:
					hud.call("_use_quick_slot", index)
				var item: StringName = bound[index]
				var on_bar: bool = shown.has(item)
				var group: Array = quick.call("group_of", item)
				var effect: bool = true
				if item == &"flashlight":
					effect = flashes[0] == 1
				elif item == &"medkit":
					effect = InventoryManager.count_of(&"medkit") == medkits - 1
				elif not group.is_empty():
					effect = group.has(manager.get("equipped")) if on_bar else manager.get("equipped") == &""
				elif not on_bar:
					effect = InventoryManager.count_of(item) == 0
				presses = presses and effect
				if not effect:
					rows.append("%d guns, slot %d (%s) by %s: %s" % [owned, index + 1, item, "key" if by_key else "tap", "nothing" if on_bar else "something"])
		rows.append("%d guns: %s" % [owned, shown])
	InputService.flashlight_requested.disconnect(on_flash)
	for id: StringName in order:
		var gun: Variant = (manager.get("_weapons") as Dictionary).get(id)
		if is_instance_valid(gun):
			(gun as Node).queue_free()
	manager.set("_weapons", owned0)
	manager.set("equipped", &"")
	ProgressTracker._weapons = guns0
	InventoryManager.from_dict(pack0)
	SettingsManager.set_setting("quick_slots", slots0)
	hud.call("_refresh_slot_badges")
	r._ok(presses, "QSLOT2 every key and tap uses the slot of the six it stands for, with 0, 1, 2 and 3 guns found (%s)" % [rows])
