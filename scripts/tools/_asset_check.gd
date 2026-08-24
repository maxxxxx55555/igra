extends Node
## Проверка ассетов: иконки предметов подключены, генераторы звука дают непустой поток.

var _fails: int = 0

func _ready() -> void:
	await get_tree().process_frame
	_check_icons()
	_check_audio()
	_check_sfx_bank()
	_check_music()
	_check_app_icon()
	print("[asset-check] DONE fails=", _fails)
	# Гейт всегда выходил с кодом 0, поэтому в CI не мог ничего провалить.
	get_tree().quit(0 if _fails == 0 else 1)

## S9.2/S9.3: per-surface footsteps + monster cues must exist and be non-empty.
## Reads the actual sample names from FootstepSystem.MATERIALS / each monster's
## _set_cues() call sites (via the same literal file names) so this tests what
## the game really loads, not a frozen snapshot of an old naming convention.
func _check_sfx_bank() -> void:
	var surfaces := ["asphalt_dry", "asphalt_wet", "concrete", "wood", "metal", "puddle", "glass"]
	var fs = load("res://scripts/systems/footstep_system.gd").new()
	var missing: Array = []
	var sample_names: Array = []
	for s in surfaces:
		var sample: String = String(fs.MATERIALS.get(s, {}).get("sample", "step_" + s))
		sample_names.append(sample)
		if not ResourceLoader.exists("res://assets/audio/sfx/%s.wav" % sample):
			missing.append(sample)
	_ok(missing.is_empty(), "S9.2 шаги по поверхностям (%d/%d)%s" % [
		surfaces.size() - missing.size(), surfaces.size(),
		"" if missing.is_empty() else " нет: " + ", ".join(missing)])
	_ok(ResourceLoader.exists("res://assets/audio/sfx/step_clank.wav"), "S9.2 лязг для тяжёлого груза")

	# monster_id -> cue file, mirrors each monster script's _set_cues() call.
	var cues := ["monster_shadow_click", "monster_crawler_scrape", "monster_watcher_breath",
		"mon_watcher_scream", "mon_hunter_roar", "monster_destroyer_hum"]
	var cue_missing: Array = []
	for c in cues:
		if not ResourceLoader.exists("res://assets/audio/sfx/%s.wav" % c):
			cue_missing.append(c)
	_ok(cue_missing.is_empty(), "S9.3 звуки монстров (%d/%d)%s" % [
		cues.size() - cue_missing.size(), cues.size(),
		"" if cue_missing.is_empty() else " нет: " + ", ".join(cue_missing)])

	# Sample data must be non-empty, else playback is silent.
	var empty: Array = []
	for n in (sample_names + cues):
		var p := "res://assets/audio/sfx/%s.wav" % n
		if ResourceLoader.exists(p):
			var w: AudioStreamWAV = load(p)
			if w == null or w.data.size() < 512:
				empty.append(n)
	_ok(empty.is_empty(), "все новые WAV непустые%s" % ("" if empty.is_empty() else " пустые: " + ", ".join(empty)))

	# play_cue() now force-disables loop_mode before playback regardless of
	# what's baked into the source WAV (see base_monster.gd comment — a
	# looping AudioStreamPlayer3D never fires .finished, so it never frees;
	# that was a real leak). Source-file loop flags are no longer a
	# requirement, so there's nothing to assert here anymore.

	# FootstepSystem must map every generated surface.
	var unmapped: Array = []
	for s in surfaces:
		if not fs.MATERIALS.has(s):
			unmapped.append(s)
	_ok(unmapped.is_empty(), "FootstepSystem знает все поверхности%s" % ("" if unmapped.is_empty() else " нет: " + ", ".join(unmapped)))
	fs.free()

func _ok(cond: bool, what: String) -> void:
	if cond:
		print("[asset-check] OK  ", what)
	else:
		_fails += 1
		print("[asset-check] FAIL ", what)

func _check_icons() -> void:
	var ids: Array = ItemDatabase.all_ids()
	_ok(ids.size() > 0, "ItemDatabase заполнен (%d предметов)" % ids.size())
	var with_icon: int = 0
	var missing: Array = []
	for id in ids:
		var item: ItemData = ItemDatabase.get_item(id)
		if item != null and item.icon != null:
			with_icon += 1
		else:
			missing.append(String(id))
	_ok(missing.is_empty(), "у всех предметов есть icon (%d/%d)%s" % [with_icon, ids.size(),
		"" if missing.is_empty() else " нет: " + ", ".join(missing)])

	# Иконки на диске для всех .tres в data/items
	var d := DirAccess.open("res://data/items")
	var no_png: Array = []
	if d:
		d.list_dir_begin()
		var f := d.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var iid := f.get_basename()
				if not ResourceLoader.exists("res://assets/textures/items/%s.png" % iid):
					no_png.append(iid)
			f = d.get_next()
		d.list_dir_end()
	_ok(no_png.is_empty(), "PNG есть для всех предметов%s" % ("" if no_png.is_empty() else " нет: " + ", ".join(no_png)))

	# draw_icon отдаёт текстуру, а не векторную заглушку
	var icons := preload("res://scripts/ui/item_icons.gd")
	for probe_id in ["battery", "gear", "serum", "blueprint_backpack_slots"]:
		var host := Control.new()
		add_child(host)
		icons.draw_icon(host, StringName(probe_id), 32.0)
		var has_tex := false
		for c in host.get_children():
			if c is TextureRect and (c as TextureRect).texture != null:
				has_tex = true
		_ok(has_tex, "draw_icon(%s) рисует спрайт" % probe_id)
		host.queue_free()

func _check_audio() -> void:
	var gens: Array = ["_gen_pickup", "_gen_coin", "_gen_success", "_gen_fanfare",
		"_gen_chime", "_gen_powerup", "_gen_error", "_gen_thud", "_gen_boom"]
	for g in gens:
		_ok(AudioManager.has_method(g), "AudioManager.%s есть" % g)
	var s: AudioStream = AudioManager.call("_gen_pickup")
	_ok(s != null and (s as AudioStreamWAV).data.size() > 0, "_gen_pickup даёт непустой WAV")
	var drone: AudioStream = AudioManager.call("_gen_threat_drone", 0.5)
	_ok(drone != null and (drone as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "threat-гул зациклен")

	# Событийные хуки подключены
	_ok(EventBus.item_picked_up.get_connections().size() > 0, "item_picked_up озвучен")
	_ok(EventBus.puzzle_solved.get_connections().size() > 0, "puzzle_solved озвучен")
	_ok(EventBus.achievement_unlocked.get_connections().size() > 0, "achievement_unlocked озвучен")
	_ok(EventBus.player_damaged.get_connections().size() > 0, "player_damaged озвучен")
	_ok(AudioManager.has_method("set_threat_level"), "слой threat управляем")

## Музыка: все треки на диске, импортированы, зациклены; эмбиент меняется по району.
func _check_music() -> void:
	var moods: Dictionary = MusicDirector.TRACKS
	var missing: Array = []
	for m in moods:
		var p: String = moods[m]
		if not ResourceLoader.exists(p):
			missing.append(p.get_file())
	_ok(missing.is_empty(), "все треки настроений на диске%s" % ("" if missing.is_empty() else " нет: " + ", ".join(missing)))

	var no_import: Array = []
	for m in moods:
		var p: String = moods[m]
		if not FileAccess.file_exists(p + ".import"):
			no_import.append(p.get_file())
	for d in MusicDirector.AMBIENT_BY_DISTRICT.values():
		if not FileAccess.file_exists(String(d) + ".import"):
			no_import.append(String(d).get_file())
	_ok(no_import.is_empty(), "треки импортированы (попадут в APK)%s" % ("" if no_import.is_empty() else " нет: " + ", ".join(no_import)))

	## .import не в репозитории (см. .gitignore) - на свежем клоне loop_mode/
	## loop ВСЕГДА сбрасывается на дефолт при реимпорте, поэтому проект
	## принципиально не полагается на запечённый флаг: MusicDirector.
	## _force_loop() форсирует цикл в коде при каждой загрузке. Проверка
	## должна отражать РЕАЛЬНОЕ поведение рантайма, а не сырой .import-дефолт -
	## иначе она гарантированно красная на чистом клоне независимо от формата.
	var not_looped: Array = []
	for m in moods:
		var res: Resource = load(moods[m])
		if res is AudioStreamWAV or res is AudioStreamOggVorbis or res is AudioStreamMP3:
			MusicDirector._force_loop(res)
		if res is AudioStreamWAV:
			var wav := res as AudioStreamWAV
			if wav.data.size() == 0:
				not_looped.append(String(moods[m]).get_file() + "(пустой)")
			elif wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
				not_looped.append(String(moods[m]).get_file() + "(без лупа)")
		elif res is AudioStreamMP3:
			var mp3 := res as AudioStreamMP3
			if mp3.data.size() == 0:
				not_looped.append(String(moods[m]).get_file() + "(пустой)")
			elif not mp3.loop:
				not_looped.append(String(moods[m]).get_file() + "(без лупа)")
		elif res is AudioStreamOggVorbis:
			var ogg := res as AudioStreamOggVorbis
			if ogg.get_length() <= 0.0:
				not_looped.append(String(moods[m]).get_file() + "(пустой)")
			elif not ogg.loop:
				not_looped.append(String(moods[m]).get_file() + "(без лупа)")
		else:
			not_looped.append(String(moods[m]).get_file() + "(не загрузился)")
	_ok(not_looped.is_empty(), "треки непустые и зациклены%s" % ("" if not_looped.is_empty() else ": " + ", ".join(not_looped)))

	var districts: Dictionary = MusicDirector.AMBIENT_BY_DISTRICT
	_ok(districts.size() >= 2, "эмбиент задан для %d районов" % districts.size())
	var uniq: Dictionary = {}
	for k in districts:
		uniq[districts[k]] = true
	_ok(uniq.size() >= 2, "районы звучат по-разному (%d уникальных трека)" % uniq.size())
	_ok(EventBus.district_entered.get_connections().size() > 0, "смена района переключает музыку")

	# Реальная подмена трека при входе в район (RESCUE WAVE P2.2: теперь
	# районные ambience-подложки docs/PRODUCTION_BIBLE.md, не общие треки).
	MusicManager._on_district_entered(&"suburbs")
	var suburbs_path: String = MusicManager._ambient_path
	MusicManager._on_district_entered(&"substation")
	var after: String = MusicManager._ambient_path
	_ok(after != suburbs_path and after.ends_with("substation_dark.ogg"), "substation даёт свой эмбиент")
	MusicManager._on_district_entered(&"suburbs")
	_ok(MusicManager._ambient_path == suburbs_path, "возврат в suburbs возвращает трек")

## Иконка приложения: основная + adaptive для Android, привязаны в конфигах.
func _check_app_icon() -> void:
	for p in ["res://assets/ui/icon.png", "res://assets/ui/icon_adaptive_fg.png", "res://assets/ui/icon_adaptive_bg.png"]:
		var tex := load(p) as Texture2D
		_ok(tex != null, "иконка есть: %s" % p.get_file())
		if tex != null:
			var need: int = 512 if p.ends_with("icon.png") else 432
			_ok(tex.get_width() == need and tex.get_height() == need,
				"%s размер %dx%d (нужно %d)" % [p.get_file(), tex.get_width(), tex.get_height(), need])
	_ok(ProjectSettings.get_setting("application/config/icon", "") == "res://assets/ui/icon.png",
		"project.godot использует icon.png")
	var cfg := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if cfg != null:
		var txt := cfg.get_as_text()
		cfg.close()
		_ok(txt.contains("launcher_icons/adaptive_foreground_432x432=\"res://assets/ui/icon_adaptive_fg.png\""),
			"Android launcher icons привязаны")
		_ok(txt.contains("permissions/internet=true"), "INTERNET разрешён (нужен для LAN-мультиплеера)")
	else:
		_ok(false, "export_presets.cfg читается")
