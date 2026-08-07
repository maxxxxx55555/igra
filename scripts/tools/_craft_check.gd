extends Node
## Проверка крафт-флоу + концовок. Сцена: scenes/tools/craft_check_scene.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func _run() -> void:
	var checks: Array = []
	var inv = get_tree().root.get_node_or_null("/root/InventoryManager")
	checks.append(["inventory autoload", inv != null])
	if inv:
		inv.try_add(&"scrap", 2)
		inv.try_add(&"cable", 1)
		var st: Node = load("res://scenes/gameplay/craft_station.tscn").instantiate()
		add_child(st)
		checks.append(["can craft battery (scrap2+cable1)", st._can_craft(st.RECIPES[&"battery"])])
		checks.append(["cannot craft medkit (no gear)", not st._can_craft(st.RECIPES[&"medkit"])])
		st._on_craft(&"battery")
		checks.append(["battery crafted", inv.count_of(&"battery") == 1])
		checks.append(["scrap spent", inv.count_of(&"scrap") == 0])
		checks.append(["cable spent", inv.count_of(&"cable") == 0])
		# Материалы рецептов должны быть получаемы (есть в ItemDatabase).
		checks.append(["gear добываем", inv.try_add(&"gear", 1)])
		checks.append(["wiring добываем", inv.try_add(&"wiring", 1)])
		inv.try_add(&"scrap", 2)
		checks.append(["medkit крафтится (scrap+gear)", st._can_craft(st.RECIPES[&"medkit"])])
		st._on_craft(&"medkit")
		checks.append(["medkit получен", inv.count_of(&"medkit") == 1])
		checks.append(["fuse крафтится (scrap+wiring)", st._can_craft(st.RECIPES[&"fuse"])])
		st.queue_free()
	var ends: Array = Endings.evaluate()
	checks.append(["endings empty on fresh run", ends.is_empty()])
	Endings.mark_ended()
	ends = Endings.evaluate()
	var dm = get_tree().root.get_node_or_null("/root/DistrictManager")
	if dm:
		dm.set_stage("powerplant", 3)
		ends = Endings.evaluate()
		checks.append(["survivor ending (only powerplant)", ends.any(func(e): return e.get("id") == "survivor")])
		dm.set_stage("powerplant", 3)
		dm.set_stage("suburb", 3)
		dm.set_stage("residential", 3)
		dm.set_stage("park", 3)
		dm.set_stage("school", 3)
		dm.set_stage("hospital", 3)
		dm.set_stage("policestation", 3)
		dm.set_stage("warehouse", 3)
		dm.set_stage("gasstation", 3)
		dm.set_stage("industrial", 3)
		dm.set_stage("substation", 3)
		ends = Endings.evaluate()
		checks.append(["light ending (all + no docs)", ends.any(func(e): return e.get("id") == "hope")])
		var pt = get_tree().root.get_node_or_null("/root/ProgressTracker")
		if pt:
			pt.is_doc_unlocked("doc_engineer_log")
			pt.is_doc_unlocked("doc_family_letter")
			pt._unlock_doc("doc_engineer_log")
			pt._unlock_doc("doc_family_letter")
			ends = Endings.evaluate()
			checks.append(["light ending with all docs", ends.any(func(e): return e.get("id") == "light")])
	Endings.reset()
	var fails: int = 0
	for c in checks:
		print("[craft-check] ", "OK " if c[1] else "FAIL", " ", c[0])
		if not c[1]:
			fails += 1
	print("[craft-check] DONE fails=", fails)
	get_tree().quit(0 if fails == 0 else 1)
