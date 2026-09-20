extends Node
## Arena design audit / RC finish pass: proves the three accessibility
## toggles (reduce_flash, reduce_time_fx, reduce_ui_motion) actually gate
## their juice sites, and that all three survive a real save->reload round
## trip - the same settings.cfg path a real app restart uses (same
## technique as _settings_persist_probe.gd's item 13, reused not
## reinvented).

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var bad: int = 0

	# Whatever was actually on disk - restored at the end, not clobbered.
	var orig_flash: bool = bool(SettingsManager.get_setting("reduce_flash", false))
	var orig_time_fx: bool = bool(SettingsManager.get_setting("reduce_time_fx", false))
	var orig_ui_motion: bool = bool(SettingsManager.get_setting("reduce_ui_motion", false))

	# --- reduce_flash gates WowDirector's screen flash ---
	SettingsManager.set_setting("reduce_flash", true)
	WowDirector.wow("cascade")
	var flash_suppressed: bool = not is_instance_valid(WowDirector._flash)
	print("[a11y] reduce_flash=true suppresses WowDirector flash: ", flash_suppressed)
	if not flash_suppressed:
		bad += 1
	SettingsManager.set_setting("reduce_flash", false)
	WowDirector.wow("cascade")
	var flash_fires: bool = is_instance_valid(WowDirector._flash) and WowDirector._flash.visible
	print("[a11y] reduce_flash=false lets WowDirector flash fire: ", flash_fires)
	if not flash_fires:
		bad += 1

	# --- reduce_time_fx gates WowDirector.hit_stop()'s Engine.time_scale dip ---
	SettingsManager.set_setting("reduce_time_fx", true)
	WowDirector.hit_stop()
	var hitstop_suppressed: bool = not WowDirector._hitstop_active
	print("[a11y] reduce_time_fx=true suppresses hit_stop: ", hitstop_suppressed)
	if not hitstop_suppressed:
		bad += 1
	SettingsManager.set_setting("reduce_time_fx", false)
	WowDirector.hit_stop()
	var hitstop_fires: bool = WowDirector._hitstop_active
	print("[a11y] reduce_time_fx=false lets hit_stop fire: ", hitstop_fires)
	if not hitstop_fires:
		bad += 1
	Engine.time_scale = 1.0
	WowDirector._hitstop_active = false

	# --- reduce_ui_motion gates UISFX.press_pulse()'s button scale-pop ---
	var probe_btn := Control.new()
	probe_btn.size = Vector2(100, 40)
	add_child(probe_btn)
	SettingsManager.set_setting("reduce_ui_motion", true)
	probe_btn.scale = Vector2.ONE
	UISFX.press_pulse(probe_btn)
	var motion_suppressed: bool = probe_btn.scale.is_equal_approx(Vector2.ONE)
	print("[a11y] reduce_ui_motion=true suppresses press_pulse: ", motion_suppressed)
	if not motion_suppressed:
		bad += 1
	SettingsManager.set_setting("reduce_ui_motion", false)
	probe_btn.scale = Vector2.ONE
	UISFX.press_pulse(probe_btn)
	var motion_fires: bool = not probe_btn.scale.is_equal_approx(Vector2.ONE)
	print("[a11y] reduce_ui_motion=false lets press_pulse fire: ", motion_fires)
	if not motion_fires:
		bad += 1
	probe_btn.queue_free()

	# --- all three toggles survive a real save_to_cfg() -> load_from_cfg() ---
	SettingsManager.set_setting("reduce_flash", true)
	SettingsManager.set_setting("reduce_time_fx", true)
	SettingsManager.set_setting("reduce_ui_motion", true)
	SettingsManager.save_to_cfg()
	var reloaded: Node = load("res://scripts/systems/settings_manager.gd").new()
	add_child(reloaded)
	var loaded_ok: bool = reloaded.load_from_cfg()
	var persist_ok: bool = loaded_ok \
		and bool(reloaded.get_setting("reduce_flash", false)) \
		and bool(reloaded.get_setting("reduce_time_fx", false)) \
		and bool(reloaded.get_setting("reduce_ui_motion", false))
	print("[a11y] all three toggles survive save->reload round trip: ", persist_ok)
	if not persist_ok:
		bad += 1
	reloaded.queue_free()

	SettingsManager.set_setting("reduce_flash", orig_flash)
	SettingsManager.set_setting("reduce_time_fx", orig_time_fx)
	SettingsManager.set_setting("reduce_ui_motion", orig_ui_motion)
	SettingsManager.save_to_cfg()

	print("[a11y] DONE bad=", bad)
	get_tree().quit(1 if bad > 0 else 0)
