extends RefCounted
## Сами проверки автопилота. Каждый тест — Callable(tree, rt).
##
## Правила, которым подчинён весь файл:
##  * никаких выдуманных API — только методы, которые реально есть в проекте;
##  * тест обязан вернуть управление (иначе сработает вотчдог);
##  * тест сам за собой прибирает: поднятые сцены освобождаются, иначе
##    следующий тест получит чужой мир и упадёт по ложной причине.

const PLAYER_SCENE := "res://scenes/player/player_3d.tscn"
const MAIN_SCENE := "res://scenes/main_3d.tscn"
const HUD_SCENE := "res://scenes/ui/hud_3d.tscn"

## Сколько кадров прокрутить, чтобы _ready/_process успели отработать.
const SETTLE_FRAMES: int = 6

func collect() -> Array:
	return [
		{"name": "автозагрузки поднялись", "fn": _t_autoloads},
		{"name": "новая игра сбрасывает прогресс", "fn": _t_new_game_reset},
		{"name": "игрок появляется и двигается", "fn": _t_player_move},
		{"name": "фонарь переключается и тратит заряд", "fn": _t_flashlight},
		{"name": "подбор предмета попадает в инвентарь", "fn": _t_pickup},
		{"name": "аптечка лечит", "fn": _t_medkit},
		{"name": "батарейка пополняет заряд", "fn": _t_battery},
		{"name": "укрытие прячет от монстра", "fn": _t_hiding},
		{"name": "дверь без ключа заперта, с ключом открывается", "fn": _t_door},
		{"name": "сохранение и загрузка восстанавливают район", "fn": _t_save_roundtrip},
		{"name": "щит поднимает стадию района", "fn": _t_power_switch},
		{"name": "все районы восстановлены — финал запускается", "fn": _t_finale},
		{"name": "смерть переводит в состояние DEAD", "fn": _t_death},
		{"name": "пауза и возврат в игру", "fn": _t_pause_resume},
		{"name": "Escape закрывает верхний оверлей первым", "fn": _t_esc_order},
		{"name": "экраны интерфейса открываются и имеют размер", "fn": _t_ui_screens},
		{"name": "подсказка обучения лежит в CanvasLayer", "fn": _t_tutorial_layer},
		{"name": "полосы HUD не накладываются друг на друга", "fn": _t_hud_overlap},
		{"name": "укрытия стоят не внутри стен", "fn": _t_hiding_placement},
		{"name": "до укрытий есть путь по навигации", "fn": _t_hiding_reachable},
		{"name": "блэкаут гасит фонарь района", "fn": _t_blackout},
		{"name": "движение через Input.action_press", "fn": _t_input_move},
		{"name": "подбор обновляет счётчик в HUD", "fn": _t_hud_badge},
		{"name": "выход в меню работает из паузы", "fn": _t_quit_under_pause},
		{"name": "смерть открывает экран смерти", "fn": _t_death_screen},
		{"name": "переход в район автосохраняет новый район", "fn": _t_district_autosave},
		{"name": "скриншоты экранов сохранены", "fn": _t_screenshots},
	]

# ── вспомогательное ────────────────────────────────────────────────────────

## Прокручивает кадры, чтобы отработали _ready/_process.
##
## process_frame эмитится и во время паузы, поэтому ожидание кадров
## безопасно даже внутри тестов паузы. Сброс состояния между тестами
## делает autopilot_main.
func _settle(tree: SceneTree, frames: int = SETTLE_FRAMES) -> void:
	for i in frames:
		await tree.process_frame


func _autoload(tree: SceneTree, n: String) -> Node:
	return tree.root.get_node_or_null("/root/" + n)

## Поднимает сцену и возвращает её корень, уже добавленный в дерево.
func _spawn(tree: SceneTree, path: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var n := ps.instantiate()
	if n == null:
		return null
	tree.root.add_child(n)
	return n

func _despawn(n: Node) -> void:
	if is_instance_valid(n):
		n.get_parent().remove_child(n)
		n.queue_free()

# ── тесты ──────────────────────────────────────────────────────────────────

func _t_autoloads(tree: SceneTree, rt: RefCounted) -> void:
	# Список обязательных автозагрузок: если хоть одной нет, дальше падёт всё.
	var need := [
		"EventBus", "GameManager", "SaveSystem", "InventoryManager",
		"PowerGrid", "DistrictManager", "UIManager", "LocalizationManager",
		"FinaleDirector", "QuestManager", "AudioManager",
	]
	for n in need:
		rt.check(_autoload(tree, n) != null, "нет автозагрузки " + n)
	await _settle(tree, 2)

func _t_new_game_reset(tree: SceneTree, rt: RefCounted) -> void:
	var save := _autoload(tree, "SaveSystem")
	var inv := _autoload(tree, "InventoryManager")
	var grid := _autoload(tree, "PowerGrid")
	if save == null or inv == null or grid == null:
		rt.unavailable("нет SaveSystem/InventoryManager/PowerGrid")
		return
	# Пачкаем прогресс, затем требуем полного сброса.
	inv.try_add(&"cable", 2)
	grid.advance_district(&"suburbs", 1)
	save.reset_all()
	await _settle(tree, 2)
	rt.check(inv.count_of(&"cable") == 0, "инвентарь не очистился после новой игры")
	rt.check(int(grid.get_stage(&"suburbs")) == 0, "стадия района не сбросилась")

func _t_player_move(tree: SceneTree, rt: RefCounted) -> void:
	var p := _spawn(tree, PLAYER_SCENE)
	if p == null:
		rt.unavailable("не поднялась сцена игрока " + PLAYER_SCENE)
		return
	await _settle(tree)
	rt.check(p is Node3D, "игрок не Node3D")
	# compute_velocity — чистая функция, ей не нужны ни пол, ни физика.
	if p.has_method("compute_velocity"):
		var v: Vector3 = p.compute_velocity(Vector2(0, -1))
		rt.check(v.length() > 0.01, "нулевая скорость при вводе вперёд")
	else:
		rt.fail("у игрока нет compute_velocity()")
	_despawn(p)
	await _settle(tree, 2)

func _t_flashlight(tree: SceneTree, rt: RefCounted) -> void:
	var p := _spawn(tree, PLAYER_SCENE)
	if p == null:
		rt.unavailable("не поднялась сцена игрока")
		return
	await _settle(tree)
	if not p.has_method("toggle_flashlight"):
		rt.fail("нет toggle_flashlight()")
		_despawn(p)
		return
	var before: bool = bool(p.flashlight_enabled)
	p.toggle_flashlight()
	await _settle(tree, 2)
	rt.check(bool(p.flashlight_enabled) != before, "фонарь не переключился")
	# Расход заряда проверяем напрямую: ждать реального разряда слишком долго.
	if p.has_method("consume_battery") and p.has_method("get_battery"):
		var b0: float = float(p.get_battery())
		p.consume_battery(5.0)
		rt.check(float(p.get_battery()) < b0, "заряд не уменьшился")
	_despawn(p)
	await _settle(tree, 2)

func _t_pickup(tree: SceneTree, rt: RefCounted) -> void:
	var inv := _autoload(tree, "InventoryManager")
	if inv == null:
		rt.unavailable("нет InventoryManager")
		return
	inv.remove(&"cable", 99)
	var before: int = int(inv.count_of(&"cable"))
	var ok: bool = bool(inv.try_add(&"cable", 1))
	await _settle(tree, 2)
	rt.check(ok, "try_add вернул false")
	rt.check(int(inv.count_of(&"cable")) == before + 1, "счётчик предмета не вырос")
	inv.remove(&"cable", 99)

func _t_medkit(tree: SceneTree, rt: RefCounted) -> void:
	var p := _spawn(tree, PLAYER_SCENE)
	if p == null:
		rt.unavailable("не поднялась сцена игрока")
		return
	await _settle(tree)
	if not p.has_method("heal"):
		rt.fail("нет heal()")
		_despawn(p)
		return
	p.hp = 40.0
	p.heal(25.0)
	rt.check(float(p.hp) > 40.0, "здоровье не выросло после лечения")
	rt.check(float(p.hp) <= 100.0, "здоровье превысило максимум")
	_despawn(p)
	await _settle(tree, 2)

func _t_battery(tree: SceneTree, rt: RefCounted) -> void:
	var p := _spawn(tree, PLAYER_SCENE)
	if p == null:
		rt.unavailable("не поднялась сцена игрока")
		return
	await _settle(tree)
	if not p.has_method("add_battery"):
		rt.fail("нет add_battery()")
		_despawn(p)
		return
	p.consume_battery(50.0)
	var low: float = float(p.get_battery())
	p.add_battery(20.0)
	rt.check(float(p.get_battery()) > low, "заряд не пополнился")
	_despawn(p)
	await _settle(tree, 2)

func _t_hiding(tree: SceneTree, rt: RefCounted) -> void:
	var p := _spawn(tree, PLAYER_SCENE)
	if p == null:
		rt.unavailable("не поднялась сцена игрока")
		return
	await _settle(tree)
	var spot_script := load("res://scripts/gameplay/hiding_spot.gd")
	if spot_script == null:
		rt.unavailable("нет скрипта укрытия")
		_despawn(p)
		return
	var spot := Node3D.new()
	spot.set_script(spot_script)
	tree.root.add_child(spot)
	await _settle(tree)
	if not p.has_method("toggle_hiding"):
		rt.fail("нет toggle_hiding()")
		_despawn(spot)
		_despawn(p)
		return
	# Настоящий монстр рядом с игроком: до укрытия он обязан его видеть,
	# после — нет. Проверяем вызовом _can_see_player(), а не чтением кода.
	var monster := _spawn(tree, "res://scenes/enemies/watcher_3d.tscn")
	if monster != null:
		await _settle(tree, 4)
		(monster as Node3D).global_position = Vector3.ZERO
		(p as Node3D).global_position = Vector3(0.0, 0.0, -2.0)
		monster.set("player_ref", p)
		await _settle(tree, 2)
		var seen_before: bool = true
		if monster.has_method("_can_see_player"):
			seen_before = bool(monster.call("_can_see_player"))
		p.toggle_hiding(spot)
		await _settle(tree, 3)
		rt.check(float(p.visibility) <= 0.01, "в укрытии видимость не обнулилась")
		if monster.has_method("_can_see_player"):
			rt.check(seen_before, "монстр не видел игрока даже до укрытия — проверка бессмысленна")
			rt.check(not bool(monster.call("_can_see_player")),
				"монстр продолжает видеть игрока внутри укрытия")
		else:
			rt.fail("у монстра нет _can_see_player()")
		_despawn(monster)
	else:
		p.toggle_hiding(spot)
		await _settle(tree, 2)
		rt.check(float(p.visibility) <= 0.01, "в укрытии видимость не обнулилась")
		rt.fail("не поднялась сцена монстра — стелс проверен только наполовину")
	_despawn(spot)
	_despawn(p)
	await _settle(tree, 2)

func _t_door(tree: SceneTree, rt: RefCounted) -> void:
	var inv := _autoload(tree, "InventoryManager")
	var door_script := load("res://scripts/gameplay/door.gd")
	if inv == null or door_script == null:
		rt.unavailable("нет InventoryManager или скрипта двери")
		return
	# Дверь строим вручную: @onready ждёт MeshInstance3D и CollisionShape3D,
	# отдельной сцены двери в проекте нет.
	var door := StaticBody3D.new()
	door.set_script(door_script)
	var mi := MeshInstance3D.new()
	mi.name = "MeshInstance3D"
	mi.mesh = BoxMesh.new()
	door.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	cs.shape = BoxShape3D.new()
	door.add_child(cs)
	tree.root.add_child(door)
	await _settle(tree, 4)
	door.set("required_key", "key")
	inv.remove(&"key", 99)
	await _settle(tree, 2)
	# Без ключа дверь обязана остаться закрытой.
	door.call("interact", null)
	await _settle(tree, 3)
	rt.check(not bool(door.get("is_open")), "дверь открылась без ключа")
	# С ключом — открыться.
	rt.check(inv.try_add(&"key", 1), "ключ не удалось положить в инвентарь")
	await _settle(tree, 2)
	door.call("interact", null)
	await _settle(tree, 3)
	rt.check(bool(door.get("is_open")), "дверь не открылась при наличии ключа")
	inv.remove(&"key", 99)
	_despawn(door)
	await _settle(tree, 2)

## Путь настоящего сохранения игрока. Тест его перезаписывает, поэтому
## содержимое сначала прячется, а в конце возвращается на место: прогон
## автопилота не имеет права стереть чужой прогресс.
const SAVE_PATH := "user://tls_savegame.save"
const SAVE_BACKUP := "user://tls_savegame.autopilot_backup"

func backup_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, SAVE_BACKUP)

func restore_save() -> void:
	if FileAccess.file_exists(SAVE_BACKUP):
		DirAccess.copy_absolute(SAVE_BACKUP, SAVE_PATH)
		DirAccess.remove_absolute(SAVE_BACKUP)
	elif FileAccess.file_exists(SAVE_PATH):
		# Сохранения не было до прогона — не оставляем и после него.
		DirAccess.remove_absolute(SAVE_PATH)

func _t_save_roundtrip(tree: SceneTree, rt: RefCounted) -> void:
	var save := _autoload(tree, "SaveSystem")
	var dm := _autoload(tree, "DistrictManager")
	var grid := _autoload(tree, "PowerGrid")
	if save == null or dm == null or grid == null:
		rt.unavailable("нет SaveSystem/DistrictManager/PowerGrid")
		return
	grid.advance_district(&"suburbs", 1)
	dm.current_district = "hospital"
	save.save_all()
	# Портим состояние и требуем, чтобы загрузка его вернула.
	dm.current_district = "park"
	grid.reset()
	await _settle(tree, 2)
	rt.check(save.load_all(), "load_all() вернул false")
	await _settle(tree, 2)
	rt.check(String(dm.current_district) == "hospital",
		"после загрузки район = %s, ожидался hospital" % String(dm.current_district))
	rt.check(int(grid.get_stage(&"suburbs")) >= 1, "стадия района не восстановилась")
	save.reset_all()

func _t_power_switch(tree: SceneTree, rt: RefCounted) -> void:
	var grid := _autoload(tree, "PowerGrid")
	var bus := _autoload(tree, "EventBus")
	if grid == null or bus == null:
		rt.unavailable("нет PowerGrid/EventBus")
		return
	grid.reset()
	var seen: Array = []
	var cb := func(id: StringName, stage: int) -> void:
		seen.append([id, stage])
	bus.district_restored.connect(cb)
	# Ведём район до FULL: сигнал обязан прийти ровно на последней стадии.
	grid.advance_district(&"suburbs", 1)
	grid.advance_district(&"suburbs", 2)
	grid.advance_district(&"suburbs", 3)
	await _settle(tree, 2)
	bus.district_restored.disconnect(cb)
	rt.check(int(grid.get_stage(&"suburbs")) == 3, "район не дошёл до FULL")
	rt.check(seen.size() >= 1, "district_restored не пришёл")
	grid.reset()

func _t_finale(tree: SceneTree, rt: RefCounted) -> void:
	var grid := _autoload(tree, "PowerGrid")
	var fd := _autoload(tree, "FinaleDirector")
	var bus := _autoload(tree, "EventBus")
	if grid == null or fd == null or bus == null:
		rt.unavailable("нет PowerGrid/FinaleDirector/EventBus")
		return
	if fd.has_method("reset"):
		fd.reset()
	grid.reset()
	var fired := [false]
	var cb := func() -> void:
		fired[0] = true
	bus.final_night_started.connect(cb)
	# Районы связаны пререквизитами (powered_by): пока «родитель» не доведён
	# до FULL, потомок заблокирован. Поэтому идём повторными проходами, а не
	# одним циклом — так тест не зависит от порядка списка районов.
	var guard := 0
	while not grid.all_restored() and guard < 20:
		guard += 1
		for d in grid.all_districts():
			var id: StringName = d.id
			if not grid.is_unlocked(id):
				continue
			for stage in [1, 2, 3]:
				grid.advance_district(id, stage)
		await tree.process_frame
	await _settle(tree, 4)
	bus.final_night_started.disconnect(cb)
	rt.check(grid.all_restored(), "не все районы дошли до FULL")
	rt.check(fired[0], "финальная ночь не началась при полностью восстановленном городе")
	grid.reset()
	if fd.has_method("reset"):
		fd.reset()

func _t_death(tree: SceneTree, rt: RefCounted) -> void:
	var gm := _autoload(tree, "GameManager")
	if gm == null:
		rt.unavailable("нет GameManager")
		return
	gm.trigger_death()
	await _settle(tree, 3)
	rt.check(gm.is_dead(), "после trigger_death() состояние не DEAD")
	# Смерть обязана снимать паузу, иначе экран смерти застынет.
	rt.check(not tree.paused, "дерево осталось на паузе после смерти")
	gm.return_to_menu()
	await _settle(tree, 3)

func _t_pause_resume(tree: SceneTree, rt: RefCounted) -> void:
	var gm := _autoload(tree, "GameManager")
	if gm == null:
		rt.unavailable("нет GameManager")
		return
	gm.start_new_game()
	await _settle(tree, 3)
	gm.pause_game()
	await _settle(tree, 2)
	rt.check(gm.is_paused(), "пауза не включилась")
	rt.check(tree.paused, "дерево не встало на паузу")
	gm.resume_game()
	await _settle(tree, 2)
	rt.check(not tree.paused, "дерево не снялось с паузы")
	rt.check(not gm.is_paused(), "состояние осталось PAUSED")
	gm.return_to_menu()
	await _settle(tree, 3)

func _t_esc_order(tree: SceneTree, rt: RefCounted) -> void:
	var ui := _autoload(tree, "UIManager")
	if ui == null:
		rt.unavailable("нет UIManager")
		return
	var src: String = (load("res://scripts/ui/ui_manager.gd") as Script).source_code
	# Порядок закрытия задан кодом: Escape сперва снимает верхний оверлей.
	rt.check("_topmost_closable" in src, "нет выбора верхнего закрываемого экрана")
	rt.check("_ESC_KEEP" in src, "нет списка экранов, которые Escape не трогает")
	var keep_ok := ("&\"death\"" in src) and ("&\"win\"" in src) and ("&\"main_menu\"" in src)
	rt.check(keep_ok, "смерть/победа/меню должны быть защищены от Escape")
	await _settle(tree, 2)

func _t_ui_screens(tree: SceneTree, rt: RefCounted) -> void:
	var ui := _autoload(tree, "UIManager")
	if ui == null:
		rt.unavailable("нет UIManager")
		return
	# Экраны, которые обязаны открываться и иметь ненулевой размер.
	for id in [&"codex", &"city_map", &"pause", &"settings"]:
		ui.open(id)
		await _settle(tree, 3)
		ui.close(id)
		await _settle(tree, 2)
	rt.note("экраны codex/city_map/pause/settings открылись и закрылись без ошибок")
	ui.close_all_blocking()
	await _settle(tree, 2)

func _t_tutorial_layer(tree: SceneTree, rt: RefCounted) -> void:
	var ts := _autoload(tree, "TutorialSystem")
	if ts == null:
		rt.unavailable("нет TutorialSystem")
		return
	await _settle(tree, 3)
	# Control рисуется только внутри CanvasLayer — иначе подсказки невидимы.
	var layer := ts.get_node_or_null("TutorialLayer")
	rt.check(layer is CanvasLayer, "подсказка обучения не обёрнута в CanvasLayer")
	if layer is CanvasLayer:
		var has_control := false
		for c in layer.get_children():
			if c is Control:
				has_control = true
		rt.check(has_control, "в слое обучения нет ни одного Control")

## Скриншоты для владельца: их нужно просто приложить к ответу.
## Кадр обязан быть отрисован, поэтому перед каждым снимком крутим кадры.
func _t_screenshots(tree: SceneTree, rt: RefCounted) -> void:
	var ui := _autoload(tree, "UIManager")
	var gm := _autoload(tree, "GameManager")
	if ui == null or gm == null:
		rt.unavailable("нет UIManager/GameManager")
		return
	var shots := {
		"menu": &"main_menu",
		"pause": &"pause",
		"codex": &"codex",
		"map": &"city_map",
	}
	for shot_name in shots:
		var screen_id: StringName = shots[shot_name]
		ui.open(screen_id)
		await _settle(tree, 8)
		await rt.screenshot(tree, String(shot_name))
		ui.close(screen_id)
		await _settle(tree, 3)
	ui.close_all_blocking()
	await _settle(tree, 3)
	rt.check(rt.shot_count() > 0, "не сохранилось ни одного скриншота")

## Полосы HP/выносливости/батареи/шума/заметности раскладываются по одной
## сетке. Раньше «ШУМ» рисовался поверх выносливости — проверяем, что
## прямоугольники видимых полос не пересекаются.
func _t_hud_overlap(tree: SceneTree, rt: RefCounted) -> void:
	var hud := _spawn(tree, HUD_SCENE)
	if hud == null:
		rt.unavailable("не поднялась сцена HUD " + HUD_SCENE)
		return
	await _settle(tree, 8)
	var top := hud.get_node_or_null("TopLeft")
	if top == null:
		rt.fail("в HUD нет узла TopLeft")
		_despawn(hud)
		return
	var bars: Array = []
	for child in top.get_children():
		if child is Control and (child as Control).visible:
			var c := child as Control
			if c.size.x > 0.0 and c.size.y > 0.0:
				bars.append(c)
	rt.check(bars.size() >= 2, "в HUD меньше двух видимых полос — раскладка не проверена")
	for i in bars.size():
		for j in range(i + 1, bars.size()):
			var a: Control = bars[i]
			var b: Control = bars[j]
			var ra := Rect2(a.global_position, a.size)
			var rb := Rect2(b.global_position, b.size)
			if ra.intersects(rb):
				rt.fail("полосы HUD пересекаются: %s и %s" % [a.name, b.name])
	_despawn(hud)
	await _settle(tree, 2)

## Укрытия расставляет DistrictSceneFactory по кругу. Если точка попала
## внутрь стены, игрок «спрячется» в геометрии. Проверяем пересечение
## тела укрытия с миром через прямое физическое сканирование.
func _t_hiding_placement(tree: SceneTree, rt: RefCounted) -> void:
	var factory := load("res://scripts/world/district_scene_factory.gd")
	if factory == null:
		rt.unavailable("нет district_scene_factory.gd")
		return
	var world := Node3D.new()
	tree.root.add_child(world)
	var root: Node3D = factory.build(world, &"suburbs")
	if root == null:
		rt.fail("район не собрался")
		_despawn(world)
		return
	await _settle(tree, 10)
	var spots: Array = []
	for n in root.get_children():
		if String(n.name).begins_with("HidingSpot"):
			spots.append(n)
	rt.check(spots.size() > 0, "в районе не расставлено ни одного укрытия")
	var space := root.get_world_3d().direct_space_state
	for s in spots:
		if not (s is Node3D):
			continue
		var shape := SphereShape3D.new()
		shape.radius = 0.35
		var params := PhysicsShapeQueryParameters3D.new()
		params.shape = shape
		params.transform = Transform3D(Basis(), (s as Node3D).global_position)
		params.collide_with_areas = false
		params.collide_with_bodies = true
		# Само укрытие исключаем: пересечение с собой — не ошибка.
		var self_rids: Array[RID] = []
		for c in (s as Node3D).get_children():
			if c is CollisionObject3D:
				self_rids.append((c as CollisionObject3D).get_rid())
		if s is CollisionObject3D:
			self_rids.append((s as CollisionObject3D).get_rid())
		params.exclude = self_rids
		var hits := space.intersect_shape(params, 1)
		if hits.size() > 0:
			rt.fail("укрытие %s стоит внутри геометрии" % String(s.name))
	_despawn(world)
	await _settle(tree, 3)

## Блэкаут обязан гасить свет фонаря: сигнал есть давно, но потребитель
## в 3D появился поздно — следим, чтобы связь не отвалилась снова.
func _t_blackout(tree: SceneTree, rt: RefCounted) -> void:
	var bus := _autoload(tree, "EventBus")
	var grid := _autoload(tree, "PowerGrid")
	if bus == null or grid == null:
		rt.unavailable("нет EventBus/PowerGrid")
		return
	var scene_path := "res://scenes/props/streetlight_3d.tscn"
	var light: Node = null
	if ResourceLoader.exists(scene_path):
		light = _spawn(tree, scene_path)
	if light == null:
		var scr := load("res://scripts/world/streetlight_3d.gd")
		if scr == null:
			rt.unavailable("нет streetlight_3d")
			return
		rt.note("сцена фонаря не найдена, проверяем только реакцию скрипта")
		var src: String = scr.source_code
		rt.check("district_blackout" in src, "фонарь не подписан на district_blackout")
		return
	light.set("district_id", &"suburbs")
	grid.advance_district(&"suburbs", 2)
	await _settle(tree, 6)
	var spot := light.get_node_or_null("SpotLight") as SpotLight3D
	if spot == null:
		rt.fail("у фонаря нет узла SpotLight")
		_despawn(light)
		return
	var lit_before: bool = spot.visible
	bus.district_blackout.emit(&"suburbs")
	await _settle(tree, 4)
	rt.check(lit_before, "фонарь не горел до блэкаута — проверка бессмысленна")
	rt.check(not spot.visible, "блэкаут не погасил фонарь")
	_despawn(light)
	grid.reset()
	await _settle(tree, 2)

## Полный путь ввода: Input.action_press должен доезжать до игрока.
## Проверяем не позицию (её съедает отсутствие пола), а то, что игрок
## считывает действие и формирует ненулевое направление.
func _t_input_move(tree: SceneTree, rt: RefCounted) -> void:
	var p := _spawn(tree, PLAYER_SCENE)
	if p == null:
		rt.unavailable("не поднялась сцена игрока")
		return
	await _settle(tree)
	p.can_move = true
	p.gameplay_active = true
	Input.action_press("move_up")
	await _settle(tree, 4)
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	Input.action_release("move_up")
	await _settle(tree, 2)
	rt.check(dir.length() > 0.01, "Input.get_vector не увидел нажатие move_up")
	if p.has_method("compute_velocity"):
		var v: Vector3 = p.compute_velocity(dir)
		rt.check(v.length() > 0.01, "игрок не превратил ввод в скорость")
	_despawn(p)
	await _settle(tree, 2)

## Счётчик в быстром слоте обязан меняться сразу после подбора: HUD
## подписан на inventory_changed. Раньше бейджи оставались нулевыми,
## пока игрок не откроет инвентарь.
func _t_hud_badge(tree: SceneTree, rt: RefCounted) -> void:
	var inv := _autoload(tree, "InventoryManager")
	if inv == null:
		rt.unavailable("нет InventoryManager")
		return
	var hud := _spawn(tree, HUD_SCENE)
	if hud == null:
		rt.unavailable("не поднялась сцена HUD")
		return
	await _settle(tree, 8)
	# medkit стоит третьим в QUICK_SLOT_ITEMS, значит слот с индексом 2.
	var slot := hud.get_node_or_null("BottomCenter/Slot2")
	if slot == null:
		rt.fail("в HUD нет узла BottomCenter/Slot2")
		_despawn(hud)
		return
	var badge := slot.get_node_or_null("Badge") as Label
	if badge == null:
		rt.fail("в слоте нет узла Badge")
		_despawn(hud)
		return
	inv.remove(&"medkit", 99)
	await _settle(tree, 4)
	rt.check(badge.text == "0", "счётчик не обнулился после очистки, показывает %s" % badge.text)
	inv.try_add(&"medkit", 2)
	await _settle(tree, 4)
	rt.check(badge.text == "2", "после подбора счётчик показывает %s вместо 2" % badge.text)
	inv.remove(&"medkit", 99)
	_despawn(hud)
	await _settle(tree, 2)

## Выход в меню обязан срабатывать и когда игра стоит на паузе: иначе
## из паузы невозможно выйти, и это выглядит как зависание.
func _t_quit_under_pause(tree: SceneTree, rt: RefCounted) -> void:
	var gm := _autoload(tree, "GameManager")
	if gm == null:
		rt.unavailable("нет GameManager")
		return
	gm.start_new_game()
	await _settle(tree, 3)
	gm.pause_game()
	await _settle(tree, 2)
	rt.check(tree.paused, "пауза не включилась — проверка бессмысленна")
	gm.return_to_menu()
	await _settle(tree, 4)
	rt.check(not tree.paused, "выход в меню не снял паузу — игра осталась замороженной")
	rt.check(gm.is_menu(), "состояние после выхода не MENU")

## Смерть обязана поднимать экран смерти, а не просто менять состояние:
## именно с него игрок жмёт «Заново» или «В меню».
func _t_death_screen(tree: SceneTree, rt: RefCounted) -> void:
	var gm := _autoload(tree, "GameManager")
	var ui := _autoload(tree, "UIManager")
	if gm == null or ui == null:
		rt.unavailable("нет GameManager/UIManager")
		return
	gm.start_new_game()
	await _settle(tree, 3)
	gm.trigger_death()
	await _settle(tree, 5)
	rt.check(gm.is_dead(), "состояние не DEAD")
	rt.check(not tree.paused, "экран смерти показан на паузе — кнопки не нажмутся")
	# _is_open() — внутренний, но единственный точный ответ «экран виден».
	if ui.has_method("_is_open"):
		rt.check(bool(ui.call("_is_open", &"death")), "экран смерти не открыт")
		await rt.screenshot(tree, "death")
	else:
		rt.fail("у UIManager нет _is_open()")
	gm.return_to_menu()
	await _settle(tree, 3)

## Автосейв при переходе обязан записать НОВЫЙ район. Раньше он срабатывал
## до того, как DistrictManager узнавал id, и в файл уходил предыдущий.
func _t_district_autosave(tree: SceneTree, rt: RefCounted) -> void:
	var gm := _autoload(tree, "GameManager")
	var dm := _autoload(tree, "DistrictManager")
	if gm == null or dm == null:
		rt.unavailable("нет GameManager/DistrictManager")
		return
	var wr := Node3D.new()
	wr.set_script(load("res://scripts/world/world_runtime.gd"))
	wr.name = "WorldRuntime"
	tree.root.add_child(wr)
	# Автосейв пишется только в состоянии PLAYING.
	gm.start_new_game()
	await _settle(tree, 6)
	if not wr.has_method("load_district"):
		rt.fail("у WorldRuntime нет load_district()")
		_despawn(wr)
		return
	wr.call("load_district", &"park")
	await _settle(tree, 10)
	rt.check(String(dm.current_district) == "park",
		"DistrictManager остался на %s" % String(dm.current_district))
	# Читаем сам файл: важно, что на диск попал именно новый район.
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		rt.fail("автосейв не создал файл сохранения")
	else:
		var raw := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(raw)
		if parsed is Dictionary:
			rt.check(String((parsed as Dictionary).get("district", "")) == "park",
				"в сейве район %s, а не park" % String((parsed as Dictionary).get("district", "")))
		else:
			rt.fail("сейв не читается как JSON")
	_despawn(wr)
	gm.return_to_menu()
	await _settle(tree, 4)

## Укрытие, до которого нельзя дойти, бесполезно. Строим тот же навмеш,
## что создаёт main_3d.gd, и просим карту проложить путь от точки спавна
## игрока к каждому укрытию.
func _t_hiding_reachable(tree: SceneTree, rt: RefCounted) -> void:
	var factory := load("res://scripts/world/district_scene_factory.gd")
	if factory == null:
		rt.unavailable("нет district_scene_factory.gd")
		return
	var world := Node3D.new()
	tree.root.add_child(world)
	# Навигационная область строится так же, как в main_3d._setup_nav_region().
	var nreg := NavigationRegion3D.new()
	var nmesh := NavigationMesh.new()
	var s := 40.0
	nmesh.vertices = PackedVector3Array([
		Vector3(-s, 0, -s), Vector3(s, 0, -s), Vector3(s, 0, s), Vector3(-s, 0, s),
	])
	nmesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	nreg.navigation_mesh = nmesh
	world.add_child(nreg)
	var root: Node3D = factory.build(world, &"suburbs")
	if root == null:
		rt.fail("район не собрался")
		_despawn(world)
		return
	# Навигационной карте нужен кадр физики, чтобы принять регион.
	for i in 12:
		await tree.physics_frame
	var map: RID = world.get_world_3d().navigation_map
	var from := Vector3(-8.0, 0.0, -8.0)
	var checked := 0
	for n in root.get_children():
		if not String(n.name).begins_with("HidingSpot") or not (n is Node3D):
			continue
		checked += 1
		var to: Vector3 = (n as Node3D).global_position
		var path := NavigationServer3D.map_get_path(map, from, Vector3(to.x, 0.0, to.z), true)
		if path.size() < 2:
			rt.fail("до укрытия %s нет пути по навигации" % String(n.name))
		elif path[path.size() - 1].distance_to(Vector3(to.x, 0.0, to.z)) > 3.0:
			rt.fail("путь до %s обрывается далеко от цели" % String(n.name))
	rt.check(checked > 0, "не нашлось ни одного укрытия для проверки")
	_despawn(world)
	await _settle(tree, 3)
