extends Node
const BUSES := ["Master", "SFX", "Music", "Voice", "Ambient"]
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
	"Окружение": "Ambient", "Ambient Volume": "Ambient", "Ambient": "Ambient",
}

## Подписи выпадающих списков → индекс уровня (0 низкий … 2 высокий).
## Таблицы оставлены только для совместимости со старыми файлами настроек:
## подписи в них русские и английские, а языков в игре 13 — на японском или
## турецком совпадения не будет. Живой экран настроек (settings_screen.gd)
## передаёт сюда индекс, поэтому _tier()/_difficulty_index() сначала
## пробуют разобрать значение как число и только потом смотрят в таблицу.
const TIER_LABELS := {
	"Низкое": 0, "Среднее": 1, "Высокое": 2,
	"Низкие": 0, "Средние": 1, "Высокие": 2,
	"Low": 0, "Medium": 1, "High": 2,
}
const DIFFICULTY_LABELS := {"Легко": 0, "Нормально": 1, "Сложно": 2, "Easy": 0, "Normal": 1, "Hard": 2}

## Значение из UI или из .cfg → индекс. Числа проходят как есть.
static func _index_from(value: Variant, table: Dictionary, fallback: int) -> int:
	if value is int or value is float:
		return int(value)
	var s: String = str(value)
	if s.is_valid_int():
		return s.to_int()
	return int(table.get(s, fallback))

static func _difficulty_index(value: Variant) -> int:
	return clampi(_index_from(value, DIFFICULTY_LABELS, 1), 0, 2)

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
	# _load_defaults() только кладёт fps_cap в словарь. Без этого вызова
	# Engine.max_fps оставался нулём на свежей установке: кадры не ограничивались
	# ничем, телефон грелся и жёг батарею на меню.
	set_fps_cap(int(_settings.get("fps_cap", 1)))

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
	# The Settings screen's generic toggles/dropdowns route through here and
	# never called the real appliers — so High Contrast / Arachnophobia /
	# Colorblind / Text Size were stored but never took effect. Dispatch.
	match key:
		"high_contrast": _apply_high_contrast()
		"arachnophobia": _apply_arachnophobia()
		"dyslexia_font": _apply_dyslexia_font()
		"colorblind": _apply_colorblind()
		"text_size": _apply_text_size()
		"trailer_mode": EventBus.hud_visibility_changed.emit(not bool(value))
	EventBus.settings_changed.emit(key, value)

## Re-apply every accessibility effect from _settings — called after a config
## load and once on boot (deferred so the scene tree / root theme exist).
func apply_all_accessibility() -> void:
	_apply_high_contrast()
	_apply_arachnophobia()
	_apply_colorblind()
	_apply_text_size()

## Три apply_* + save_to_cfg вызываются из экрана настроек (scripts/ui/screens.gd),
## но в классе их не было — кнопка «ПРИМЕНИТЬ» падала с "Nonexistent function".
## Каждый метод принимает подписи как их отдаёт UI и приводит их к индексам.

func apply_game(d: Dictionary) -> void:
	if d.has("language"):
		set_language(String(d["language"]))
	if d.has("difficulty"):
		set_difficulty(_difficulty_index(d["difficulty"]))
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
	return clampi(_index_from(value, TIER_LABELS, 2), 0, 2)

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

var _cb_layer: CanvasLayer = null
var _cb_rect: ColorRect = null

func _ensure_cb_overlay() -> void:
	if is_instance_valid(_cb_rect):
		return
	_cb_layer = CanvasLayer.new()
	_cb_layer.layer = 200
	_cb_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_cb_layer)
	_cb_rect = ColorRect.new()
	_cb_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\n" \
		+ "uniform int mode = 0;\n" \
		+ "uniform sampler2D scr : hint_screen_texture, filter_linear;\n" \
		+ "void fragment(){\n" \
		+ " vec3 c = texture(scr, SCREEN_UV).rgb; vec3 o = c;\n" \
		+ " if (mode == 1) { o.r = clamp(c.r*1.15 + c.g*0.10, 0.0, 1.0); o.b = clamp(c.b + (c.r - c.g)*0.20, 0.0, 1.0); }\n" \
		+ " else if (mode == 2) { o.g = clamp(c.g*1.15 + c.r*0.10, 0.0, 1.0); o.b = clamp(c.b + (c.g - c.r)*0.20, 0.0, 1.0); }\n" \
		+ " else if (mode == 3) { o.r = clamp(c.r + (c.b - c.g)*0.15, 0.0, 1.0); o.g = clamp(c.g + (c.b - c.r)*0.15, 0.0, 1.0); }\n" \
		+ " COLOR = vec4(o, 1.0);\n}"
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_cb_rect.material = mat
	_cb_layer.add_child(_cb_rect)

## Colorblind assist: a full-screen post shader that lifts the confusable
## channel and pushes its error into a distinguishable one, per type.
## 0 off / 1 deuteranopia / 2 protanopia / 3 tritanopia. Constants are
## conservative; tune in the shader if a colorblind playtester wants more.
func _apply_colorblind() -> void:
	var mode: int = clampi(int(_settings.get("colorblind", 0)), 0, 3)
	if mode == 0:
		if is_instance_valid(_cb_rect):
			_cb_rect.visible = false
		return
	_ensure_cb_overlay()
	_cb_rect.visible = true
	(_cb_rect.material as ShaderMaterial).set_shader_parameter("mode", mode)

func set_text_size(idx: int) -> void:
	_settings["text_size"] = clampi(idx, 0, 2)
	_apply_text_size()
	EventBus.settings_changed.emit("text_size", _settings["text_size"])

var _base_font_size: int = 0

## The old version looped an "ui_text" group that nothing is ever added to,
## so it did nothing (and compounded if it had). Scale the root theme's
## default font size from a captured base instead — affects every Control
## that doesn't hard-override its own font size. Locale-agnostic.
func _apply_text_size() -> void:
	var tree := get_tree()
	if tree == null or tree.root == null or tree.root.theme == null:
		return
	var rt: Theme = tree.root.theme
	if _base_font_size <= 0:
		_base_font_size = rt.default_font_size if rt.default_font_size > 0 else 16
	var mult: float = [0.85, 1.0, 1.2][clampi(int(_settings.get("text_size", 1)), 0, 2)]
	rt.default_font_size = int(round(_base_font_size * mult))

func set_dyslexia_font(enabled: bool) -> void:
	_settings["dyslexia_font"] = enabled
	_apply_dyslexia_font()
	EventBus.settings_changed.emit("dyslexia_font", _settings["dyslexia_font"])

## NOTE: the OpenDyslexic .ttf is not shipped in assets/fonts/ and the
## "ui_text" group is never populated, so this has always been a no-op.
## The toggle was removed from the Settings screen (2026-09-10 MEGA POLISH);
## re-enable it once the font asset is added. Guarded here so a stale saved
## config with dyslexia_font=true can't load a null resource.
func _apply_dyslexia_font() -> void:
	if not _settings.get("dyslexia_font", false):
		return
	var path := "res://assets/fonts/OpenDyslexic-Regular.ttf"
	if not ResourceLoader.exists(path):
		return
	var f: Font = load(path)
	for ctrl in get_tree().get_nodes_in_group("ui_text"):
		if ctrl is Control:
			(ctrl as Control).add_theme_font_override("font", f)

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
		# `enemy.is_instance_valid()` was a runtime error — Node has no such
		# method; it's the global `is_instance_valid(obj)`.
		if is_instance_valid(enemy):
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
	# Only override the live language if the payload actually carries one —
	# an older save (or a game save missing the field) must not silently
	# reset a player's chosen language to English.
	if d.has("language") and String(d["language"]) != "":
		_language = String(d["language"])
		_apply_locale(_language)
	var s: Dictionary = d.get("settings", {}) as Dictionary
	for key in s:
		_settings[key] = s[key]
	# Re-apply accessibility effects from the loaded config (deferred: the
	# root theme / enemy nodes may not exist yet at load time).
	call_deferred("apply_all_accessibility")