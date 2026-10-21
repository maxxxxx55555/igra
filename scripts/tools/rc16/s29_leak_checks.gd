extends RefCounted
## Session 29 (the v10.0.0-ship pass), R6 the exit leaks and F19 the brightness drift. LEAK1 every close button a screen keeps is in the tree or null: the six screens without a close button each held a `Button.new()` that
## never entered it, and at exit those six Buttons kept their theme styles, shaped texts and two fonts alive (12 ShapedTextData and 2 Font RIDs, 37 ObjectDB instances in a short run). LAMP2 the lamps do not flicker in step:
## all 48 lamps of a district started their sine at 0, so the street pulsed by 15 % and fell to a fifth of its light six times a second together (two frames of one view differed by up to 20 %). Wired into _closeout_check_runner.gd.

static func run(r: Node) -> void:
	_screens(r)
	await _lamps(r)

static func _screens(r: Node) -> void:
	var screens: Node = r._main.get_node_or_null("Screens")
	var data: Dictionary = screens.get("_screen_data") if screens != null else {}
	var bare: int = 0
	var orphans: int = 0
	for entry: Dictionary in data.values():
		var button: Button = entry.get("close_btn")
		bare += 1 if button == null else 0
		orphans += 1 if button != null and not button.is_inside_tree() else 0
	r._ok(not data.is_empty() and bare > 0 and orphans == 0, "LEAK1 no screen holds a close button outside the tree (%d screens, %d without a close button, %d orphans)" % [data.size(), bare, orphans])

## Twelve lit lamps 11 m apart stand on their own phases of the flicker (buckets of half a radian over the 12 rad/s sine): lamps that start together stand in one.
static func _lamps(r: Node) -> void:
	var scene := load("res://scenes/props/streetlight_3d.tscn") as PackedScene
	var holder := Node3D.new()
	r._main.add_child(holder)
	var lamps: Array[Node3D] = []
	for i in 12:
		var lamp := scene.instantiate() as Node3D
		lamp.set("force_on", true)
		lamp.position = Vector3(float(i) * 11.0, 0.0, float(i % 3) * 7.0)
		holder.add_child(lamp)
		lamps.append(lamp)
	for _frame in 3:
		await r.get_tree().process_frame
	var phases: Dictionary = {}
	for lamp in lamps:
		phases[int(fposmod(float(lamp.get("_t")) * 12.0, TAU) / 0.5)] = true
	holder.queue_free()
	r._ok(phases.size() >= 5, "LAMP2 twelve lit lamps stand on %d of 13 phases of the flicker (one when they flicker in step)" % phases.size())
