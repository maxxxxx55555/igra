extends Control

@onready var logo: ColorRect = $Logo
@onready var label: Label = $Title

## FINAL HARDENING PASS (2026-09-12) — ROOT CAUSE of "world torn down ~8s
## after New Game" (docs/KNOWN_ISSUES.md "Autoplay bot"), traced and fixed.
##
## This node is instanced as a direct child of scenes/main_3d.tscn (the
## GAMEPLAY scene, run/main_scene is boot_loading.tscn — this is not the
## real cold-boot entry point). Unconditionally, ~3s after main_3d.tscn
## loads, it fired Routes.goto(Routes.BOOT), which replaces current_scene
## and destroys the entire game world — during an ACTIVE PLAYING session,
## every single time, with no guard anywhere (confirmed empirically: a
## one-off diagnostic print landed at t=7.87s, matching the documented
## ~8s figure exactly). This is real severity-1 behavior, not a test-only
## artifact — a real player would hit it too, just never observed because
## no session (agent or human) had ever played past the ~8s mark with eyes
## on the screen (docs/HONEST_ASSESSMENT.md's headline finding). The
## unused sibling scripts/ui/splash.gd (dead - not wired to any .tscn)
## already has the exact correct guard; ported it here to the file that
## is actually instanced, matching main_3d.gd's own established pattern
## (_auto_start_from_main() checks GameManager.is_playing() the same way).
func _ready() -> void:
	if GameManager and GameManager.has_method("is_playing") and GameManager.is_playing():
		queue_free()
		return
	add_to_group("ui_root")
	logo.color = Color("#1D1812")
	label.text = "THE LAST STREETLIGHT"
	label.add_theme_color_override("font_color", Color("#E2A33C"))
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.0)
	tw.tween_interval(2.0)
	tw.tween_callback(func(): Routes.goto(Routes.BOOT))
