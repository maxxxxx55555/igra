extends Node3D
## Диагностика освещения: состояние фонарика/окружения + измеримая яркость кадра.
## Критерий играбельности: экран не должен быть чёрным.
## Запуск: godot --path <proj> res://scenes/tools/light_check_scene.tscn

var _fails: int = 0

func _ready() -> void:
	print("[light] DBG ready start")
	var main: Node = load("res://scenes/main_3d.tscn").instantiate()
	print("[light] DBG instantiated, adding child")
	add_child(main)
	print("[light] DBG child added")
	await get_tree().create_timer(2.0).timeout
	print("[light] DBG timer1 done")
	var screens: Node = get_tree().root.find_child("Screens", true, false)
	if screens and screens.has_method("hide_all"):
		screens.hide_all()
	GameManager._change_state(GameManager.GameState.PLAYING)
	print("[light] DBG change_state done")
	await get_tree().create_timer(2.5).timeout
	print("[light] DBG timer2 done")

	_report_lights()
	await _report_frame("start")

	# Смотрим вниз на асфальт — фонарик обязан давать пятно света
	var player := _find_player()
	if player:
		player.set("_pitch", -0.45)
		await get_tree().create_timer(1.0).timeout
		await _report_frame("look_down")

	print("[light] DONE fails=", _fails)
	get_tree().quit(1 if _fails > 0 else 0)

## Ищем по группе, а не по имени узла: имя зависит от того, как игрок попал в
## сцену (инстанс "Player", спавн мультиплеера, "PlayerFPS" из player_fps.tscn),
## и поиск по строке молча не находил его в headless-прогоне.
func _find_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _ok(cond: bool, what: String) -> void:
	if cond:
		print("[light] OK  ", what)
	else:
		_fails += 1
		print("[light] FAIL ", what)

func _report_lights() -> void:
	var player := _find_player()
	if player == null:
		_ok(false, "игрок найден")
		return
	var fl := player.find_child("Flashlight", true, false) as SpotLight3D
	if fl == null:
		_ok(false, "фонарик найден")
		return
	print("[light] flashlight visible=%s energy=%.1f range=%.1f angle=%.1f pos=%s rot_deg=%s" % [
		fl.visible, fl.light_energy, fl.spot_range, fl.spot_angle,
		str(fl.global_position.round()), str((fl.global_rotation_degrees).round())])
	_ok(fl.visible and fl.light_energy > 0.0, "фонарик включён на старте")
	_ok(fl.spot_range >= 8.0, "дальность фонарика %.1f м (>=8)" % fl.spot_range)

	var cam := get_viewport().get_camera_3d()
	if cam:
		var cam_fwd: Vector3 = -cam.global_transform.basis.z
		var fl_fwd: Vector3 = -fl.global_transform.basis.z
		var ang: float = rad_to_deg(cam_fwd.angle_to(fl_fwd))
		print("[light] угол камера↔фонарик = %.1f°" % ang)
		_ok(ang < 12.0, "фонарик светит туда, куда смотрит камера (%.1f° < 12°)" % ang)
		var cone := player.find_child("ConeMesh", true, false) as MeshInstance3D
		if cone:
			var d: float = cam.global_position.distance_to(cone.global_position)
			_ok(not (cone.visible and d < 2.0), "конус не засвечивает камеру (visible=%s, d=%.1fм)" % [cone.visible, d])

	var we := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if we and we.environment:
		var e := we.environment
		print("[light] env ambient=%.3f fog=%.4f glow=%s tonemap=%d" % [
			e.ambient_light_energy, e.fog_density, e.glow_enabled, e.tonemap_mode])
	var moon := get_tree().root.find_child("Moon", true, false) as DirectionalLight3D
	if moon:
		print("[light] moon energy=%.3f shadows=%s" % [moon.light_energy, moon.shadow_enabled])
	var lights_on: int = 0
	for n in get_tree().get_nodes_in_group("lights"):
		if n is Node3D and (n as Node3D).visible:
			lights_on += 1
	print("[light] уличных фонарей включено: %d" % lights_on)

func _report_frame(tag: String) -> void:
	# В headless рендерер — заглушка: frame_post_draw не приходит НИКОГДА, и
	# await на нём вешал весь гейт намертво. Яркость там мерить нечем, поэтому
	# честно пропускаем этот блок вместо тихого зависания.
	if DisplayServer.get_name() == "headless":
		print("[light] кадр[%s]: SKIP (headless, нет растеризации)" % tag)
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	# HUD занимает края — считаем яркость центральной зоны 3D-вида
	var w: int = img.get_width()
	var h: int = img.get_height()
	var x0: int = int(w * 0.25)
	var x1: int = int(w * 0.75)
	var y0: int = int(h * 0.20)
	var y1: int = int(h * 0.85)
	var total: float = 0.0
	var maxl: float = 0.0
	var lit: int = 0
	var n: int = 0
	var step: int = 4
	for y in range(y0, y1, step):
		for x in range(x0, x1, step):
			var c := img.get_pixel(x, y)
			var l: float = c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			total += l
			maxl = maxf(maxl, l)
			if l > 0.06:
				lit += 1
			n += 1
	var mean: float = total / maxf(float(n), 1.0)
	var lit_pct: float = 100.0 * float(lit) / maxf(float(n), 1.0)
	print("[light] кадр[%s]: средняя=%.4f макс=%.3f освещено=%.1f%%" % [tag, mean, maxl, lit_pct])
	_ok(mean > 0.012, "[%s] кадр не чёрный (средняя %.4f > 0.012)" % [tag, mean])
	_ok(lit_pct > 4.0, "[%s] видно детали (%.1f%% пикселей освещено > 4%%)" % [tag, lit_pct])
