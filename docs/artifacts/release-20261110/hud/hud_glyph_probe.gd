extends SceneTree

class Harness extends Node:
	var fails: int = 0
	func _ok(ok: bool, label: String) -> void:
		if not ok:
			fails += 1
		print("[hud-glyph] %s %s" % ["OK" if ok else "FAIL", label])

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var reporter := Harness.new()
	root.add_child(reporter)
	var checks: Script = load("res://scripts/tools/rc16/hud_checks.gd")
	await checks._touch_labels_use_bundled_glyphs(reporter)
	print("[hud-glyph] DONE fails=%d" % reporter.fails)
	quit(0 if reporter.fails == 0 else 1)
