extends SceneTree

const BUTTONS: Array[String] = ["BtnAttack", "BtnSprint", "BtnStealth", "BtnInteract", "BtnJump", "BtnFlash", "BtnStrobe", "BtnWheel", "BtnInventory", "BtnReload", "BtnMelee", "BtnUV", "BtnDodge", "BtnWorkbench"]
var _rows: Array[Dictionary] = []
var _fails: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings: Node = root.get_node("SettingsManager")
	var loc: Node = root.get_node("LocalizationManager")
	loc.set_language("en")
	root.get_node("QualityManager").enabled = false
	root.get_node("AdService").enabled = false
	root.get_node("QaLaunchGuard").qa_launch = true
	settings.set_setting("touch_calibration_done", true)
	settings.set_text_size(1)
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
	Input.emulate_touch_from_mouse = true
	root.get_node("SaveSystem").mark_onboard_done()
	var gm: Node = root.get_node("GameManager")
	gm._change_state(gm.GameState.PLAYING)
	var main := (load("res://scenes/main_3d.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	for _attempt in 60:
		if get_first_node_in_group("player") != null:
			break
		await create_timer(0.2).timeout
	if get_first_node_in_group("player") == null:
		printerr("[hud-native] missing player")
		quit(1)
		return
	await create_timer(0.5).timeout
	paused = true
	var out_dir: String = OS.get_environment("HUD_EVIDENCE_DIR").replace("\\", "/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	for lang: String in ["en", "ru"]:
		loc.set_language(lang)
		await create_timer(3.2).timeout  # Let real startup toasts expire before recording the control labels.
		for tier: int in [2, 0]:
			settings.set_graphics_tier(tier)
			root.mode = Window.MODE_WINDOWED
			root.size = Vector2i(1600, 740)
			for factor: float in [0.8, 1.5]:
				settings.set_button_size(factor)
				for left: bool in [false, true]:
					settings.set_setting("one_handed", left)
					await create_timer(0.15).timeout
					await RenderingServer.frame_post_draw
					var hud: Node = current_scene.get_node("HUD")
					var rects: Dictionary = {}
					var controls: Array[Dictionary] = []
					var bad: Array[String] = []
					var captions := {"BtnSprint": "HUD_SPRINT", "BtnStealth": "HUD_STEALTH", "BtnStrobe": "TOUCH_STROBE", "BtnMelee": "TOUCH_MELEE", "BtnUV": "TOUCH_UV", "BtnWorkbench": "TOUCH_CRAFT"}
					var view := Rect2(Vector2.ZERO, root.get_visible_rect().size)
					for name_: String in BUTTONS:
						var button := hud.get_node("BottomRight/" + name_) as Button
						var transform := button.get_global_transform()
						var rect := Rect2(transform * Vector2.ZERO, transform.basis_xform(button.size))
						rects[name_] = rect
						if not view.encloses(rect):
							bad.append(name_ + " outside")
						if minf(rect.size.x, rect.size.y) < 47.99:
							bad.append(name_ + " below48")
						if button.text.is_empty() and button.icon == null:
							bad.append(name_ + " no visible label")
						if captions.has(name_) and button.text != loc.t(captions[name_]):
							bad.append(name_ + " stale caption")
						var font := button.get_theme_font("font")
						for index: int in button.text.length():
							if not font.has_char(button.text.unicode_at(index)):
								bad.append(name_ + " missing glyph " + button.text[index])
						controls.append({"name": name_, "text": button.text, "tooltip": button.tooltip_text, "icon": button.icon.resource_path if button.icon != null else "", "rect": str(rect)})
					var ring := hud.get_node("BottomLeft/JoystickRing") as Control
					var ring_drawn := ring.get_global_transform()
					var ring_rect := Rect2(ring_drawn * Vector2.ZERO, ring_drawn.basis_xform(ring.size))
					var ammo := hud.get_node("AmmoCounter") as Control
					var ammo_rect := ammo.get_global_rect()
					for i: int in BUTTONS.size():
						var rect: Rect2 = rects[BUTTONS[i]]
						if rect.intersects(ring_rect):
							bad.append(BUTTONS[i] + " joystick")
						if rect.intersects(ammo_rect):
							bad.append(BUTTONS[i] + " ammo")
						for j: int in range(i + 1, BUTTONS.size()):
							if rect.intersects(rects[BUTTONS[j]]):
								bad.append(BUTTONS[i] + " overlaps " + BUTTONS[j])
					var name_: String = "%s_%s_%.1f_%s" % [lang, "high" if tier == 2 else "low", factor, "onehand" if left else "normal"]
					var shot := root.get_texture().get_image()
					shot.save_png(out_dir.path_join(name_ + ".png"))
					var row: Dictionary = {"case": name_, "requested_language": lang, "actual_language": loc.current_lang, "tier": settings.get_setting("graphics_tier"), "button_size": factor, "one_handed": left, "native_window": str(root.size), "logical_viewport": str(view.size), "buttons": rects.size(), "controls": controls, "failures": bad}
					_rows.append(row)
					_fails += bad.size()
					print("[hud-native] " + JSON.stringify(row))
	var report := FileAccess.open(out_dir.path_join("native-cases.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(_rows, "\t"))
	report.close()
	paused = false
	print("[hud-native] DONE cases=%d fails=%d" % [_rows.size(), _fails])
	quit(0 if _fails == 0 else 1)
