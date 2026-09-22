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
		# District ids match district_manager.gd's own DISTRICTS list; the
		# pre-rename ids this test used to have ("powerplant", "suburb",
		# "policestation", "warehouse", "gasstation") silently no-op'd
		# against PowerGrid (unknown id -> get_district() returns null),
		# so the ending checks below never actually advanced a real
		# district and always failed regardless of ending logic. Also,
		# power_station itself requires the whole chain FULL first
		# (powered_by: substation<-industrial<-warehouses+police<-...) —
		# "only power_station" was never reachable; endings_manager.gd's
		# actual survivor rule is `power_station_full and full < total`,
		# i.e. the station up while ANY district (not necessarily all) is
		# short — satisfied here by the two GDD-documented optional leaves
		# (school, gas_station) staying unrestored.
		dm.set_stage("suburbs", 3)
		dm.set_stage("park", 3)
		dm.set_stage("residential", 3)
		dm.set_stage("police", 3)
		dm.set_stage("hospital", 3)
		dm.set_stage("warehouses", 3)
		dm.set_stage("industrial", 3)
		dm.set_stage("substation", 3)
		dm.set_stage("power_station", 3)
		ends = Endings.evaluate()
		checks.append(["survivor ending (station up, school+gas_station left)", ends.any(func(e): return e.get("id") == "survivor")])
		dm.set_stage("suburbs", 3)
		dm.set_stage("residential", 3)
		dm.set_stage("park", 3)
		dm.set_stage("school", 3)
		dm.set_stage("hospital", 3)
		dm.set_stage("police", 3)
		dm.set_stage("warehouses", 3)
		dm.set_stage("gas_station", 3)
		dm.set_stage("industrial", 3)
		dm.set_stage("substation", 3)
		ends = Endings.evaluate()
		checks.append(["light ending (all + no docs)", ends.any(func(e): return e.get("id") == "hope")])
		var pt = get_tree().root.get_node_or_null("/root/ProgressTracker")
		if pt:
			# Endings.get_total_documents() counts every DistrictLoot
			# document/lore id + the 2 event docs (see scripts/core/
			# endings.gd) — unlocking only the 2 event docs (as this
			# test used to) could never reach docs_pct >= 1.0. Unlock
			# the same set the counter itself sums, so this actually
			# tests the "light" branch instead of always failing it.
			var doc_ids: Dictionary = {}
			for id in DistrictLoot.DOCUMENTS.values():
				doc_ids[String(id)] = true
			for lore_list in DistrictLoot.LORE_DOCS.values():
				for id in lore_list:
					doc_ids[String(id)] = true
			doc_ids["doc_engineer_log"] = true
			doc_ids["doc_family_letter"] = true
			for id in doc_ids:
				pt._unlock_doc(id)
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
