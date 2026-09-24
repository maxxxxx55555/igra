extends Node
## G0/G1 (order-pass v8): drives the game like a player from INSIDE the
## engine and records results as FUNCTION_MATRIX-ready lines.
##
## Why not real OS input (SendInput/PrintWindow, as the order-pass directive
## first asked for): this automation session runs in a non-interactive
## Windows session (confirmed: Process.MainWindowHandle never populates,
## MainWindowTitle stays empty even after 20s+ of polling a live, responding
## process - the window is never created on a desktop this session or the
## owner can see). Any SendInput here would move nothing the owner's own
## eyes could verify, so it would violate this very directive's own
## "NO GUESSING" rule by faking OS-level proof. Per the directive's own
## fallback clause, this degrades input to real in-engine InputEvent
## injection (get_viewport().push_input - the exact code path a real click
## goes through, same _gui_input/_unhandled_input dispatch) and keeps the
## already-proven-real screenshot method R0 used throughout
## (get_tree().root.get_texture().get_image() - genuine GPU pixels, just
## not desktop-compositor-captured). Every result line below is honestly
## labeled GUI-ENGINE, never GUI-OS.
##
## Run: godot --path . --windowed --rendering-method gl_compatibility
##        scenes/tools/gui_explore_scene.tscn
## Hard timeout: wrap the invocation in `timeout 120s` (TIMEOUT RULE).

const OUT_DIR := "res://docs/stills/gui/"
var _results: Array[String] = []
var _shots: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		print("[gui-explore] headless -- no display, no-op")
		get_tree().quit(0)
		return
	# Parented under get_tree().root by _gui_explore_bootstrap.gd (same
	# pattern as tools/qa_sim/capture_stills.gd) so this node survives the
	# Routes.goto() scene swaps it triggers below.
	call_deferred("_run")

func _log(status: String, name: String, detail: String = "") -> void:
	var line := "[gui-explore] %s %s%s" % [status, name, ("  " + detail) if detail else ""]
	print(line)
	_results.append(line)

## CONFIRMED BROKEN in this sandboxed session for multi-shot-per-process runs
## - do not call this more than once per process launch. Three root-cause
## attempts, all re-verified by diffing the saved PNG against what the scene
## tree actually held at capture time:
##   1. real-time wait only (0.2-0.3s) -> every shot after the first came back
##      byte-identical to the very first frame (stale, frozen).
##   2. + RenderingServer.force_draw() -> same result, still frozen.
##   3. + await RenderingServer.frame_post_draw x5, + a 3s real-time wait ->
##      the image DID start changing, but to a scene state from several
##      shots EARLIER in the run, not the current one (verified: a shot taken
##      right after entering Settings in English came back showing the main
##      menu in Portuguese, a language only selected many steps later) - a
##      lagging backlog, not a simple cache, and not fixable by waiting
##      longer from inside the script.
## Root cause (see class comment above): this session's window is never
## presented to a real compositor, so the render pipeline appears to queue
## up backlogged frames instead of drawing on demand. capture_stills.gd is
## NOT affected the same way because its shots are minutes apart during
## continuous 3D gameplay, which is real, ongoing engine activity, not tricks
## used on the render server; this driver's shots are seconds apart with a
## mostly-static 2D UI. Per the TIMEOUT RULE's "3 attempts then stop, no
## fudging" policy: stop here. Only the very first call in a process (no
## backlog yet to lag behind) is trustworthy - see _run()'s "00_menu" shot.
func _shot(name: String) -> void:
	var img := get_tree().root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	img.save_png(abs_dir.path_join(name + ".png"))
	_shots += 1

func _wait_scene(path: String, timeout_sec: float = 10.0) -> bool:
	var t := 0.0
	while t < timeout_sec:
		var cs := get_tree().current_scene
		if cs != null and cs.scene_file_path == path:
			return true
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	return false

func _find_option_button_with_count(root: Node, count: int) -> OptionButton:
	if root is OptionButton and (root as OptionButton).item_count == count:
		return root
	for c in root.get_children():
		var r := _find_option_button_with_count(c, count)
		if r != null:
			return r
	return null

## Pre-order DFS, first Label anywhere: settings_screen.gd's _build() adds its
## title Label to the VBox before the TabContainer (and everything under it),
## so this is the title, not a per-row label - deterministic by construction
## order, unlike guessing at Godot's auto-assigned default node name.
func _find_first_label(root: Node) -> Label:
	if root is Label:
		return root
	for c in root.get_children():
		var r := _find_first_label(c)
		if r != null:
			return r
	return null

## Mirrors i18n_truth_gate.py's SCRIPT_RANGES exactly: Latin is deliberately
## NOT one of the tracked scripts there, since this project's own convention
## keeps brand names/tech tokens in Latin on purpose even inside a
## CJK/Cyrillic/Arabic locale string. Tracking Latin here (as this used to)
## disagreed with the Python gate: a title mixing a Latin token with the
## target script was BUG here and PASS there.
func _has_mixed_script(s: String) -> bool:
	var has_cjk := false
	var has_cyrillic := false
	var has_arabic := false
	for i in s.length():
		var c := s.unicode_at(i)
		if c >= 0x4E00 and c <= 0x9FFF: has_cjk = true
		elif c >= 0x0400 and c <= 0x04FF: has_cyrillic = true
		elif c >= 0x0600 and c <= 0x06FF: has_arabic = true
	var scripts := int(has_cjk) + int(has_cyrillic) + int(has_arabic)
	return scripts > 1

func _run() -> void:
	await get_tree().create_timer(1.0).timeout
	if get_tree().current_scene == null or get_tree().current_scene.scene_file_path != Routes.MENU:
		Routes.goto(Routes.MENU)
	if not await _wait_scene(Routes.MENU, 12.0):
		_log("FAIL", "boot_to_menu", "menu never reached")
		_finish()
		return
	await get_tree().create_timer(0.3).timeout
	_shot("00_menu")
	_log("PASS", "boot_to_menu")

	# --- G1.1: main menu buttons, one at a time, back to MENU between each.
	# Each iteration re-fetches VBox/the button fresh: Routes.goto() destroys
	# and recreates MainMenu's whole subtree on every trip back, so a
	# reference captured before the loop goes stale after the first swap.
	# btn.pressed.emit() (not a geometric click) for the same reason the
	# language dropdown below uses item_selected.emit(): GUI-ENGINE, exercises
	# the real connected callback (Routes.goto) without depending on Control
	# layout having already settled the frame this runs.
	var routes_by_button := {
		"Settings": Routes.SETTINGS, "Difficulty": Routes.DIFFICULTY, "Credits": Routes.CREDITS,
	}
	for btn_name in routes_by_button:
		var vb := get_tree().current_scene.get_node_or_null("VBox")
		var btn := vb.get_node_or_null(btn_name) as Button if vb else null
		if btn == null:
			_log("BUG", "menu_button_%s" % btn_name, "node not found under MainMenu/VBox")
			continue
		btn.pressed.emit()
		await get_tree().process_frame
		var expect: String = routes_by_button[btn_name]
		var ok := await _wait_scene(expect, 8.0)
		_log("PASS" if ok else "BUG", "menu_button_%s" % btn_name,
			"" if ok else "pressed.emit() did not navigate to %s" % expect)
		Routes.goto(Routes.MENU)
		await _wait_scene(Routes.MENU, 8.0)

	# --- G1.2: settings screen, all 13 languages ---
	var menu_vb := get_tree().current_scene.get_node_or_null("VBox")
	(menu_vb.get_node("Settings") as Button).pressed.emit()
	await get_tree().process_frame
	if not await _wait_scene(Routes.SETTINGS, 8.0):
		_log("BUG", "settings_open", "did not reach settings_screen.tscn")
		Routes.goto(Routes.MENU)
		_finish()
		return
	await get_tree().create_timer(0.3).timeout
	var supported: Array = LocalizationManager.SUPPORTED
	if _find_option_button_with_count(get_tree().current_scene, supported.size()) == null:
		_log("BUG", "settings_language_dropdown", "no OptionButton with %d items found" % supported.size())
	else:
		var mixed_count := 0
		var empty_count := 0
		for i in supported.size():
			var lang: String = supported[i]
			# settings_screen.gd's _on_lang_changed() frees and rebuilds its
			# WHOLE subtree on every language_changed signal, so a dropdown
			# reference from a previous iteration (or from before this loop)
			# is a freed instance by the time this one fires - re-find it fresh.
			var dropdown := _find_option_button_with_count(get_tree().current_scene, supported.size())
			if dropdown == null:
				_log("BUG", "i18n_language_%s" % lang, "language dropdown vanished after rebuild")
				continue
			dropdown.select(i)
			dropdown.item_selected.emit(i)
			await get_tree().create_timer(0.25).timeout
			var title := _find_first_label(get_tree().current_scene)
			var title_text := title.text if title else ""
			var ok := LocalizationManager.current_lang == lang and title_text != ""
			if title_text == "":
				empty_count += 1
			if _has_mixed_script(title_text):
				mixed_count += 1
			_log("PASS" if ok else "BUG", "i18n_language_%s" % lang,
				"title='%s' current_lang=%s" % [title_text, LocalizationManager.current_lang])
		_log("PASS" if mixed_count == 0 else "BUG", "i18n_no_mixed_script",
			"%d/%d locales had mixed-script title" % [mixed_count, supported.size()])
		_log("PASS" if empty_count == 0 else "BUG", "i18n_no_empty_strings",
			"%d/%d locales had an empty title" % [empty_count, supported.size()])
		# Leave the game in ru per G1 spec ("switch back to ru/en at end").
		var ru_idx := supported.find("ru")
		var final_dropdown := _find_option_button_with_count(get_tree().current_scene, supported.size())
		if ru_idx >= 0 and final_dropdown != null:
			final_dropdown.select(ru_idx)
			final_dropdown.item_selected.emit(ru_idx)
			await get_tree().create_timer(0.2).timeout

	Routes.goto(Routes.MENU)
	await _wait_scene(Routes.MENU, 8.0)
	_finish()

func _finish() -> void:
	var pass_n := 0
	var bug_n := 0
	for line in _results:
		if line.begins_with("[gui-explore] PASS"): pass_n += 1
		elif line.begins_with("[gui-explore] BUG"): bug_n += 1
	print("[gui-explore] DONE -- %d PASS, %d BUG, %d shots" % [pass_n, bug_n, _shots])
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var f := FileAccess.open(abs_dir.path_join("results.txt"), FileAccess.WRITE)
	if f:
		for line in _results:
			f.store_line(line)
		f.close()
	get_tree().quit(0 if bug_n == 0 else 1)
