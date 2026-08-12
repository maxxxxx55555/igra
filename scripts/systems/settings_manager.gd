extends Node
const BUSES := ["Master", "SFX", "Music", "Voice"]
## Порядок обязан совпадать с LocalizationManager.SUPPORTED: экран настроек
## строит список по SUPPORTED, а индекс выбранного пункта хранит в
## _settings["language"], который здесь ищется через LANGUAGES.find(). При разном
## порядке сохранённый индекс указывал на чужой язык.
const LANGUAGES := ["ru", "en", "es", "de", "fr", "it", "pt_BR", "tr", "ja", "ko", "zh", "zh_TW", "ar"]
const CFG_PATH := "user://settings.cfg"

## Подписи из UI → канонические имена шин.
const BUS_ALIASES := {
	"Мастер": "Master", "Master Volume": "Master",
	"Музыка": "Music", "Music Volume": "Music",
	"Эффекты": "SFX", "SFX Volume": "SFX", "SFX": "SFX",
	"Голоса": "Voice", "Voice Volume": "Voice", "Voice": "Voice",
}

## Подписи выпадающих списков → индекс уровня (0 низкий … 2 высокий).
const TIER_LABELS := {
	"Низкое": 0, "Среднее": 1, "Высокое": 2,
	"Низкие": 0, "Средние": 1, "Высокие": 2,
	"Low": 0, "Medium": 1, "High": 2,
}
const DIFFICULTY_LABELS := {"Легко": 0, "Нормально": 1, "Сложно": 2, "Easy": 0, "Normal": 1, "Hard": 2}

var _volumes: Dictionary = {}
var _language: String = "en"
var _settings: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in BUSES:
		_volumes[b] = 1.0
		_ensure_bus(b)
		_apply(b)
	_load_defaults()
	# Настройки сохранялись в user://settings.cfg, но никто их не читал —
	# каждый запуск игра стартовала с дефолтов.
	# LocalizationManager объявлен ниже в списке автолоадов, поэтому сейчас его
	# ещё нет в дереве; язык досылаем отложенно, и только если файл реально был
	# (иначе затрём выбор, который LocalizationManager определит сам).
	if load_from_cfg():
		call_deferred("_apply_locale", _language)

func _load_defaults() -> void:
	_settings["difficulty"] = 1  # Normal
	_settings["autosave"] = true
	_settings["hints"] = true
	_settings["hardcore"] = false
	_settings["language"] = 0
	_settings["sensitivity"] = 1.0
	_settings["deadzone"] = 0.15
	_settings["dodge_gesture"] = 0
	_settings["crouch_input"] = 0
	_settings["hud_opacity"] = 1.0
	_settings["button_size"] = 1.0
	_settings["graphics_tier"] = 2  # High
	_settings["resolution"] = 1     # 1080p
	_settings["vsync"] = true
	_settings["fps_cap"] = 1        # 60
	_settings["shadows"] = 2        # High
	_settings["textures"] = 2       # High
	_settings["effects"] = 2        # High
	_settings["draw_distance"] = 70.0
	_settings["master"] = 0.8
	_settings["music"] = 0.7
	_settings["sfx"] = 0.85
	_settings["voice"] = 0.7
	_settings["colorblind"] = 0
	_settings["text_size"] = 1
	_settings["dyslexia_font"] = false
	_settings["high_contrast"] = false
	_settings["auto_aim"] = false
	_settings["arachnophobia"] = false
	_settings["objective_markers"] = true

func set_volume(bus: String, v: float) -> void:
	var b := _canon_bus(bus)
	if not b in BUSES:
		# push_warning("SettingsManager: unknown audio bus '%s'" % bus)
		return
	_volumes[b] = clampf(v, 0.0, 1.0)
	_settings[b] = _volumes[b]
	_ensure_bus(b)
	_apply(b)
	EventBus.settings_changed.emit(b, _volumes[b])

func get_volume(bus: String) -> float:
	return _volumes.get(_canon_bus(bus), 1.0)

## Ползунки громкости подписаны локализованно ("Мастер", "Голоса"), а шины
## называются Master/Voice. Раньше это имя уходило прямо в _ensure_bus, который
## заводил НОВУЮ шину с русским именем — настоящая громкость не менялась вообще.
func _canon_bus(bus: String) -> String:
	return String(BUS_ALIASES.get(bus, bus))

func set_language(lang: String) -> void:
	if lang in LANGUAGES:
		_language = lang
		_settings["language"] = LANGUAGES.find(lang)
		_apply_locale(lang)
		EventBus.settings_changed.emit("language", lang)

## Раньше здесь стоял голый TranslationServer.set_locale(): локаль менялась, но
## словарь для неё никто не грузил — после смены языка из настроек весь UI
## показывал сырые ключи (BTN_SAVE, TUT_WAKE_UP...). LocalizationManager читает
## data/i18n/<lang>.json, регистрирует Translation, ставит локаль и сохраняет выбор.
func _apply_locale(lang: String) -> void:
	var lm := get_node_or_null("/root/LocalizationManager")
	if lm != null and lm.has_method("set_language"):
		lm.set_language(lang)
	else:
		TranslationServer.set_locale(lang)

func get_language() -> String:
	return _language

func get_languages() -> Array:
	return LANGUAGES.duplicate()

func get_setting(key: String, default: Variant = null) -> Variant:
	if _settings.has(key):
		return _settings[key]
	return default

func set_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	EventBus.settings_changed.emit(key, value)

## Три apply_* + save_to_cfg вызываются из экрана настроек (scripts/ui/screens.gd),
## но в классе их не было — кнопка «ПРИМЕНИТЬ» падала с "Nonexistent function".
## Каждый метод принимает подписи как их отдаёт UI и приводит их к индексам.

func apply_game(d: Dictionary) -> void:
	if d.has("language"):
		set_language(String(d["language"]))
	if d.has("difficulty"):
		set_difficulty(int(DIFFICULTY_LABELS.get(str(d["difficulty"]), 1)))
	if d.has("autosave"):
		_settings["autosave"] = bool(d["autosave"])
	if d.has("hints"):
		_settings["hints"] = bool(d["hints"])
	EventBus.settings_changed.emit("game", d)

func apply_graphics(d: Dictionary) -> void:
	# Порядок важен: сначала общий пресет качества, потом точечные переопределения,
	# иначе пресет затрёт то, что игрок выставил вручную в том же диалоге.
	if d.has("quality"):
		set_graphics_tier(_tier(d["quality"]))
	if d.has("resolution"):
		set_resolution(_tier(d["resolution"]))
	if d.has("shadows"):
		set_shadow_quality(_tier(d["shadows"]))
	if d.has("textures"):
		set_texture_quality(_tier(d["textures"]))
	if d.has("effects"):
		set_effects_quality(_tier(d["effects"]))
	if d.has("draw_distance"):
		set_draw_distance(float(d["draw_distance"]))
	if d.has("vsync"):
		_settings["vsync"] = bool(d["vsync"])
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if _settings["vsync"] else DisplayServer.VSYNC_DISABLED)
	if d.has("fps"):
		# Экран отдаёт сам FPS ("60"), а хранится индекс шага — переводим.
		var fps: int = int(d["fps"])
		var step: int = FPS_STEPS.find(fps)
		set_fps_cap(step if step >= 0 else 1)
	EventBus.settings_changed.emit("graphics", d)

func apply_controls(d: Dictionary) -> void:
	if d.has("sensitivity"):
		# Ползунок отдаёт 0..100, а игроку нужен множитель около 1.0.
		set_sensitivity(float(d["sensitivity"]) / 50.0)
	if d.has("deadzone"):
		set_deadzone(float(d["deadzone"]))
	if d.has("invert_y"):
		_settings["invert_y"] = bool(d["invert_y"])
	if d.has("camera_angle"):
		_settings["camera_angle"] = float(str(d["camera_angle"]).replace("°", ""))
	EventBus.settings_changed.emit("controls", d)

func _tier(value: Variant) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return clampi(int(value), 0, 2)
	return int(TIER_LABELS.get(str(value), 2))

func save_to_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volumes", _volumes)
	cfg.set_value("game", "language", _language)
	cfg.set_value("game", "settings", _settings)
	var err := cfg.save(CFG_PATH)
	if err != OK:
		push_warning("SettingsManager: cannot save %s (err %d)" % [CFG_PATH, err])

func load_from_cfg() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return false
	from_dict({
		"volumes": cfg.get_value("audio", "volumes", {}),
		"language": cfg.get_value("game", "language", _language),
		"settings": cfg.get_value("game", "settings", {}),
	})
	return true

## --- Точечные сеттеры для scripts/ui/settings_screen.gd ---
## Их не существовало вовсе: каждый ползунок и выпадающий список на этом экране
## падал с "Nonexistent function". Значение в _settings кладёт сам экран через
## set_setting(); задача сеттера — применить эффект к движку и оповестить систему.

const FPS_STEPS := [30, 60, 120]
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const SHADOW_ATLAS := [1024, 2048, 4096]
## Пресеты качества: тени / текстуры / эффекты / потолок FPS / разрешение.
const GRAPHICS_TIERS := [
	{"shadows": 0, "textures": 0, "effects": 0, "fps": 0, "resolution": 0},
	{"shadows": 1, "textures": 1, "effects": 1, "fps": 0, "resolution": 1},
	{"shadows": 2, "textures": 2, "effects": 2, "fps": 1, "resolution": 1},
	{"shadows": 2, "textures": 2, "effects": 2, "fps": 1, "resolution": 2},
]

func set_difficulty(idx: int) -> void:
	_settings["difficulty"] = clampi(idx, 0, 2)
	EventBus.settings_changed.emit("difficulty", _settings["difficulty"])

func set_sensitivity(v: float) -> void:
	_settings["sensitivity"] = clampf(v, 0.05, 4.0)
	EventBus.settings_changed.emit("sensitivity", _settings["sensitivity"])

func set_deadzone(v: float) -> void:
	_settings["deadzone"] = clampf(v, 0.0, 0.9)
	for act in InputMap.get_actions():
		InputMap.action_set_deadzone(act, _settings["deadzone"])
	EventBus.settings_changed.emit("deadzone", _settings["deadzone"])

func set_dodge_gesture(idx: int) -> void:
	_settings["dodge_gesture"] = clampi(idx, 0, 2)
	EventBus.settings_changed.emit("dodge_gesture", _settings["dodge_gesture"])

func set_crouch_input(idx: int) -> void:
	_settings["crouch_input"] = clampi(idx, 0, 2)
	EventBus.settings_changed.emit("crouch_input", _settings["crouch_input"])

func set_hud_opacity(v: float) -> void:
	_settings["hud_opacity"] = clampf(v, 0.0, 1.0)
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud is CanvasItem:
			hud.modulate.a = _settings["hud_opacity"]
	EventBus.settings_changed.emit("hud_opacity", _settings["hud_opacity"])

func set_button_size(v: float) -> void:
	_settings["button_size"] = clampf(v, 0.5, 2.0)
	EventBus.settings_changed.emit("button_size", _settings["button_size"])

func set_colorblind_mode(idx: int) -> void:
	_settings["colorblind"] = clampi(idx, 0, 3)
	_apply_colorblind()
	EventBus.settings_changed.emit("colorblind", _settings["colorblind"])

func _apply_colorblind() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var mode: int = _settings.get("colorblind", 0)
	# ColorCorrection not available in Godot 4 - stub implementation
	if mode == 0:
		return
	# In Godot 4, colorblind correction would use a shader or ColorRect overlay
	# For now, just emit the event
	pass

func set_text_size(idx: int) -> void:
	_settings["text_size"] = clampi(idx, 0, 2)
	_apply_text_size()
	EventBus.settings_changed.emit("text_size", _settings["text_size"])

func _apply_text_size() -> void:
	var mult: float = [0.8, 1.0, 1.3][_settings.get("text_size", 1)]
	for lbl in get_tree().get_nodes_in_group("ui_text"):
		if lbl is Label:
			lbl.add_theme_font_size_override("font_size", int(lbl.get_theme_font_size("font_size") * mult))

func set_dyslexia_font(enabled: bool) -> void:
	_settings["dyslexia_font"] = enabled
	_apply_dyslexia_font()
	EventBus.settings_changed.emit("dyslexia_font", _settings["dyslexia_font"])

func _apply_dyslexia_font() -> void:
	var font_name: String = "Rajdhani"
	if _settings.get("dyslexia_font", false):
		font_name = "OpenDyslexic"
	var theme: Theme = ThemeProvider.build_theme()
	for ctrl in get_tree().get_nodes_in_group("ui_text"):
		if ctrl is Control:
			ctrl.add_theme_font_override("font", load("res://assets/fonts/" + font_name + "-Regular.ttf"))

func set_high_contrast(enabled: bool) -> void:
	_settings["high_contrast"] = enabled
	_apply_high_contrast()
	EventBus.settings_changed.emit("high_contrast", _settings["high_contrast"])

func _apply_high_contrast() -> void:
	var env: Environment = _find_environment()
	if env:
		env.adjustment_enabled = _settings.get("high_contrast", false)
		if _settings.get("high_contrast", false):
			env.adjustment_contrast = 1.3
			env.adjustment_saturation = 1.2
		else:
			env.adjustment_contrast = 1.1
			env.adjustment_saturation = 1.05

func set_auto_aim(enabled: bool) -> void:
	_settings["auto_aim"] = enabled
	EventBus.settings_changed.emit("auto_aim", _settings["auto_aim"])

func set_arachnophobia(enabled: bool) -> void:
	_settings["arachnophobia"] = enabled
	_apply_arachnophobia()
	EventBus.settings_changed.emit("arachnophobia", _settings["arachnophobia"])

func _apply_arachnophobia() -> void:
	var enabled: bool = _settings.get("arachnophobia", false)
	for enemy in get_tree().get_nodes_in_group("crawlers"):
		if enemy.is_instance_valid():
			var mesh := enemy.find_child("BodyMesh", true, false) as MeshInstance3D
			if mesh:
				mesh.visible = not enabled
				var alt := enemy.find_child("AltMesh", true, false) as MeshInstance3D
				if alt:
					alt.visible = enabled

func set_graphics_tier(idx: int) -> void:
	idx = clampi(idx, 0, GRAPHICS_TIERS.size() - 1)
	_settings["graphics_tier"] = idx
	var preset: Dictionary = GRAPHICS_TIERS[idx]
	set_shadow_quality(preset["shadows"])
	set_texture_quality(preset["textures"])
	set_effects_quality(preset["effects"])
	set_fps_cap(preset["fps"])
	set_resolution(preset["resolution"])
	EventBus.settings_changed.emit("graphics_tier", idx)

func set_resolution(idx: int) -> void:
	idx = clampi(idx, 0, RESOLUTIONS.size() - 1)
	_settings["resolution"] = idx
	# В полноэкранном режиме менять размер окна нельзя — там разрешение задаёт ОС.
	var win := get_window()
	if win != null and win.mode == Window.MODE_WINDOWED:
		win.size = RESOLUTIONS[idx]
	EventBus.settings_changed.emit("resolution", idx)

func set_fps_cap(idx: int) -> void:
	idx = clampi(idx, 0, FPS_STEPS.size() - 1)
	_settings["fps_cap"] = idx
	Engine.max_fps = FPS_STEPS[idx]
	EventBus.settings_changed.emit("fps_cap", idx)

func set_shadow_quality(idx: int) -> void:
	idx = clampi(idx, 0, 2)
	_settings["shadows"] = idx
	RenderingServer.directional_shadow_atlas_set_size(SHADOW_ATLAS[idx], idx > 0)
	var vp := get_viewport()
	if vp != null:
		vp.positional_shadow_atlas_size = SHADOW_ATLAS[idx]
	for light in get_tree().get_nodes_in_group("shadow_casters"):
		if light is Light3D:
			light.shadow_enabled = idx > 0
	EventBus.settings_changed.emit("shadows", idx)

func set_texture_quality(idx: int) -> void:
	idx = clampi(idx, 0, 2)
	_settings["textures"] = idx
	# Положительный bias = более размытые мипы = дешевле выборка.
	var vp := get_viewport()
	if vp != null:
		vp.texture_mipmap_bias = [1.0, 0.5, 0.0][idx]
	EventBus.settings_changed.emit("textures", idx)

func set_effects_quality(idx: int) -> void:
	idx = clampi(idx, 0, 2)
	_settings["effects"] = idx
	var env := _find_environment()
	if env != null:
		env.glow_enabled = idx >= 1
		env.ssao_enabled = idx >= 2
		env.ssr_enabled = idx >= 2
	EventBus.settings_changed.emit("effects", idx)

func set_draw_distance(v: float) -> void:
	_settings["draw_distance"] = clampf(v, 10.0, 500.0)
	var cam := get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam != null:
		cam.far = maxf(_settings["draw_distance"], cam.near + 1.0)
	EventBus.settings_changed.emit("draw_distance", _settings["draw_distance"])

func _find_environment() -> Environment:
	var we := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if we != null and we.environment != null:
		return we.environment
	var cam := get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam != null and cam.environment != null:
		return cam.environment
	return null

func _ensure_bus(bus: String) -> void:
	if AudioServer.get_bus_index(bus) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)

func _apply(bus: String) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(_volumes[bus], 0.0001)))

func to_dict() -> Dictionary:
	return {"volumes": _volumes.duplicate(), "language": _language, "settings": _settings.duplicate()}

func from_dict(d: Dictionary) -> void:
	var v: Dictionary = d.get("volumes", {}) as Dictionary
	for b in BUSES:
		_volumes[b] = clampf(float(v.get(b, 1.0)), 0.0, 1.0)
		_apply(b)
	_language = d.get("language", "en")
	_apply_locale(_language)
	var s: Dictionary = d.get("settings", {}) as Dictionary
	for key in s:
		_settings[key] = s[key]