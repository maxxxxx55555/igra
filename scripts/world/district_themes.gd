extends Node

signal theme_changed(district_id: StringName)

var current_id: StringName = &"suburbs"

## sky/fog/ambient раньше были светлыми пастельными (sky ~#b0c8a0 — это же
## светлое облачное НЕБО ДНЁМ), хотя в игре нет дня вообще (GDD §11.1,
## permanent night) — статичное меню и вся 3D-графика вокруг были залиты
## этими цветами через district_grading.gd. Затемнены до near-black,
## оттенок сохранён по кластерам районов; fog приведён к канону #1a2133
## (GDD §11.6: единый depth fog, не по-районно).
const _FOG_CANON := Color("#1a2133")
const THEMES := {
	&"suburbs": {"primary": Color("#6a7a5a"), "accent": Color("#f4a35d"), "sky": Color("#0b0f0a"), "fog": _FOG_CANON, "ambient": Color("#141a12"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Пригород"},
	&"residential": {"primary": Color("#6a7a5a"), "accent": Color("#f4a35d"), "sky": Color("#0b0f0a"), "fog": _FOG_CANON, "ambient": Color("#141a12"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Жилые"},
	&"park": {"primary": Color("#3a6a4a"), "accent": Color("#f4e35d"), "sky": Color("#0a110a"), "fog": _FOG_CANON, "ambient": Color("#12180f"), "music": "res://assets/audio/music/park.wav", "weather": "clear", "display_name": "Парк"},
	&"school": {"primary": Color("#5a5a6a"), "accent": Color("#f4c95d"), "sky": Color("#0b0c11"), "fog": _FOG_CANON, "ambient": Color("#14151c"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Школа"},
	&"hospital": {"primary": Color("#5a5a6a"), "accent": Color("#5dc8f4"), "sky": Color("#0b0c11"), "fog": _FOG_CANON, "ambient": Color("#14151c"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Больница"},
	&"gas_station": {"primary": Color("#5a4a3a"), "accent": Color("#e85d3a"), "sky": Color("#100d0a"), "fog": _FOG_CANON, "ambient": Color("#1a140f"), "music": "res://assets/audio/music/industrial.wav", "weather": "clear", "display_name": "АЗС"},
	&"police": {"primary": Color("#4a4a6a"), "accent": Color("#5d5dc8"), "sky": Color("#0a0a11"), "fog": _FOG_CANON, "ambient": Color("#12121c"), "music": "res://assets/audio/music/residential.wav", "weather": "clear", "display_name": "Полиция"},
	&"warehouses": {"primary": Color("#5a4a3a"), "accent": Color("#e85d3a"), "sky": Color("#100d0a"), "fog": _FOG_CANON, "ambient": Color("#1a140f"), "music": "res://assets/audio/music/industrial.wav", "weather": "fog", "display_name": "Склады"},
	&"industrial": {"primary": Color("#5a4a3a"), "accent": Color("#e85d3a"), "sky": Color("#100d0a"), "fog": _FOG_CANON, "ambient": Color("#1a140f"), "music": "res://assets/audio/music/industrial.wav", "weather": "fog", "display_name": "Промзона"},
	&"substation": {"primary": Color("#5a5a5a"), "accent": Color("#f4f45d"), "sky": Color("#0c0c0c"), "fog": _FOG_CANON, "ambient": Color("#161616"), "music": "res://assets/audio/music/industrial.wav", "weather": "fog", "display_name": "Подстанция"},
	&"power_station": {"primary": Color("#5a5a5a"), "accent": Color("#f4f45d"), "sky": Color("#0c0c0c"), "fog": _FOG_CANON, "ambient": Color("#161616"), "music": "res://assets/audio/music/industrial.wav", "weather": "fog", "display_name": "Станция"},
}

func get_theme(district_id: StringName) -> Dictionary:
	return THEMES.get(district_id, THEMES[&"suburbs"])

func get_district_color(district_id: StringName) -> Color:
	var t: Dictionary = get_theme(district_id)
	return t.get("accent", Color.WHITE)

func apply_to_environment(env: Environment, district_id: StringName) -> void:
	var t: Dictionary = get_theme(district_id)
	env.background_color = t.get("sky", Color.BLACK)
	env.ambient_light_color = t.get("ambient", Color.BLACK)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = t.get("fog", Color.GRAY)
	env.fog_density = 0.005

func has(district_id: StringName) -> bool:
	return THEMES.has(district_id)

func list_ids() -> Array[StringName]:
	return THEMES.keys()

func set_current(district_id: StringName) -> void:
	current_id = district_id
	theme_changed.emit(district_id)

func color_of(district_id: StringName, key: String) -> Color:
	return get_theme(district_id).get(key, Color.WHITE)
