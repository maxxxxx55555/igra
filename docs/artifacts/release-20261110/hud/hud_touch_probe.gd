extends SceneTree

class Harness extends Node:
	var fails: int = 0
	func _ok(ok: bool, label: String) -> void:
		if not ok:
			fails += 1
		print("[hud-touch] %s %s" % ["OK" if ok else "FAIL", label])

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var r := Harness.new()
	root.add_child(r)
	var checks: Script = load("res://scripts/tools/rc16/hud_checks.gd")
	var a11y: Script = load("res://scripts/tools/rc16/a11y_checks.gd")
	for lang: String in ["en", "ru"]:
		root.get_node("LocalizationManager").set_language(lang)
		print("[hud-touch] requested=%s actual=%s" % [lang, root.get_node("LocalizationManager").current_lang])
		await checks._touch_cluster_is_clear(r)
		await checks._touch_buttons_scale_clear(r)
		await a11y._one_handed(r)
	var hud := (load("res://scenes/ui/hud_3d.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	checks._touch_covers_actions(r, hud)
	hud.queue_free()
	await process_frame
	print("[hud-touch] DONE fails=%d" % r.fails)
	quit(0 if r.fails == 0 else 1)
