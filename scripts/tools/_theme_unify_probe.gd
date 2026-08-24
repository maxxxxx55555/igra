extends Node
## THEME UNIFICATION P0.4 proof: instantiates the real main_menu.tscn and
## hud_3d.tscn (no test doubles) and reads live, inherited styleboxes on
## real Button/Panel nodes - proves the chrome kit is now actually visible
## on screens that previously fell back to a different theme.

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var bad: int = 0
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var btn: Button = menu.get_node("VBox/Play")
	var sb := btn.get_theme_stylebox("normal", "Button")
	print("[theme-unify] main_menu Play button stylebox = ", sb.get_class())
	if sb is StyleBoxTexture:
		print("[theme-unify] texture = ", (sb as StyleBoxTexture).texture.resource_path)
	else:
		bad += 1
	menu.queue_free()

	var hud: Node = load("res://scenes/ui/hud_3d.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	var pause_btn: Button = hud.get_node("BtnPause")
	var sb2 := pause_btn.get_theme_stylebox("normal", "Button")
	print("[theme-unify] hud_3d BtnPause stylebox = ", sb2.get_class())
	if sb2 is StyleBoxTexture:
		print("[theme-unify] texture = ", (sb2 as StyleBoxTexture).texture.resource_path)
	else:
		bad += 1
	var slot0: Panel = hud.find_child("Slot0", true, false) as Panel
	if slot0 != null:
		var panel_sb := slot0.get_theme_stylebox("panel", "Panel")
		var is_canon: bool = panel_sb is StyleBoxFlat and \
			(panel_sb as StyleBoxFlat).bg_color.is_equal_approx(ThemeProvider.COLOR_BG_PANEL)
		print("[theme-unify] hud_3d Slot0 (nested, inherited) panel bg matches ThemeProvider.COLOR_BG_PANEL: ", is_canon)
		if not is_canon:
			bad += 1
	else:
		print("[theme-unify] Slot0 not present at runtime on this platform (touch-only UI) - skipped, not a failure")

	print("[theme-unify] DONE bad=", bad)
	get_tree().quit(bad)
