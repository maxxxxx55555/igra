extends Node
## VISUAL_PASS Phase 3 items 12/13 proof: (a) the graphics-tier dropdown's
## apply path actually changes the live WorldEnvironment, not just the
## stored setting; (b) an accessibility option survives a real
## save_to_cfg() -> fresh SettingsManager -> load_from_cfg() round trip,
## the same path a real app restart uses. Headless-safe: reads Environment
## properties directly, no visual/screenshot check needed for either.

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var bad: int = 0

	# Mutates real user://settings.cfg (SettingsManager is the live autoload,
	# not a sandboxed copy) - capture whatever was actually saved so a
	# developer running this gate locally gets their own settings back, not
	# hardcoded defaults.
	var orig_tier: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var orig_hc: bool = bool(SettingsManager.get_setting("high_contrast", false))
	var orig_ts: int = int(SettingsManager.get_setting("text_size", 1))

	# --- Item 12: graphics preset switch actually applies ---
	var root: Node3D = Node3D.new()
	get_tree().root.add_child(root)
	get_tree().current_scene = root
	var env_setup := preload("res://scripts/world_env_setup.gd").new()
	root.add_child(env_setup)
	await get_tree().process_frame

	SettingsManager.set_graphics_tier(0)  # Low
	await get_tree().process_frame
	var we: WorldEnvironment = root.find_child("WorldEnvironment", true, false)
	var env: Environment = we.environment
	var low_glow := env.glow_intensity
	var low_ssao := env.ssao_enabled
	print("[settings-persist] tier=Low glow_intensity=%.2f ssao=%s" % [low_glow, low_ssao])

	SettingsManager.set_graphics_tier(2)  # High
	await get_tree().process_frame
	var high_glow := env.glow_intensity
	var high_ssao := env.ssao_enabled
	print("[settings-persist] tier=High glow_intensity=%.2f ssao=%s" % [high_glow, high_ssao])

	var tier_switch_ok: bool = not is_equal_approx(low_glow, high_glow) and low_ssao == false and high_ssao == true
	print("[settings-persist] item12 graphics preset switch applies to live Environment: ", tier_switch_ok)
	if not tier_switch_ok:
		bad += 1
	root.queue_free()

	# --- Item 13: accessibility option persists across a restart ---
	SettingsManager.set_high_contrast(true)
	SettingsManager.set_text_size(2)  # Large
	SettingsManager.save_to_cfg()

	var reloaded: Node = load("res://scripts/systems/settings_manager.gd").new()
	add_child(reloaded)
	var ok: bool = reloaded.load_from_cfg()
	var hc_back: Variant = reloaded.get_setting("high_contrast", false)
	var ts_back: Variant = reloaded.get_setting("text_size", 1)
	print("[settings-persist] item13 restart round-trip: load_from_cfg=%s high_contrast=%s text_size=%s" % [ok, hc_back, ts_back])
	var persist_ok: bool = ok and bool(hc_back) == true and int(ts_back) == 2
	if not persist_ok:
		bad += 1
	reloaded.queue_free()

	# Restore whatever was actually on disk before this probe ran.
	SettingsManager.set_graphics_tier(orig_tier)
	SettingsManager.set_high_contrast(orig_hc)
	SettingsManager.set_text_size(orig_ts)
	SettingsManager.save_to_cfg()

	print("[settings-persist] DONE bad=", bad)
	get_tree().quit(1 if bad > 0 else 0)
