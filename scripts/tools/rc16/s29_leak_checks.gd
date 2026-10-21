extends RefCounted
## Session 29 (the v10.0.0-ship pass), R6 the exit leaks. LEAK1 every close button a screen keeps is in the tree or null: the six screens without a close button each held a `Button.new()` that never entered it,
## and at exit those six Buttons kept their theme styles, shaped texts and two fonts alive (12 ShapedTextData and 2 Font RIDs, 37 ObjectDB instances in a short run). Wired into _closeout_check_runner.gd.

static func run(r: Node) -> void:
	var screens: Node = r._main.get_node_or_null("Screens")
	var data: Dictionary = screens.get("_screen_data") if screens != null else {}
	var bare: int = 0
	var orphans: int = 0
	for entry: Dictionary in data.values():
		var button: Button = entry.get("close_btn")
		bare += 1 if button == null else 0
		orphans += 1 if button != null and not button.is_inside_tree() else 0
	r._ok(not data.is_empty() and bare > 0 and orphans == 0, "LEAK1 no screen holds a close button outside the tree (%d screens, %d without a close button, %d orphans)" % [data.size(), bare, orphans])
