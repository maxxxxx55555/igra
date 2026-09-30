extends Node
## Гейт вёрстки экранов UIManager.
##
## Ловит класс ошибок, который компилятор не видит и который дал сразу несколько
## визуальных багов: Control создают через Control.new() (размер 0x0), потом
## зовут set_anchors_preset() — тот меняет ТОЛЬКО якоря. Узел остаётся нулевого
## размера или стоит не там, а дочерние панели липнут к левому верхнему углу.
## Ещё одна ловушка: пресет считает offsets относительно родителя, поэтому его
## нельзя выставлять до add_child().
##
## Проверяем для каждого экрана:
##   1. корневой Control покрывает вьюпорт (это полноэкранный оверлей);
##   2. каждый видимый потомок с ненулевым размером попадает в кадр;
##   3. a FULL_RECT-anchored child really fills its parent (checked on the
##      main menu scene too);
##   4. in English no label shows Cyrillic: data resources keep Russian names,
##      and the scene files still hold Russian placeholder text (the main scene
##      showed "ЗАГРУЗКА" to every player until its script localized it).
##
## Запуск: godot --headless --path . res://scenes/tools/ui_layout_check_scene.tscn

## Scenes the game instantiates; game_over.tscn and pause_menu.tscn are legacy
## files only the scene smoke loads, their Russian placeholders never show.
const LIVE_SCENES: Array[String] = [
	"boot_loading", "main_menu", "hud_3d", "tutorial", "new_game_plus", "difficulty_screen", "save_slots",
	"district_banner", "daily_events", "epilogue", "lobby", "photo_album", "coin_hud", "quest_tracker_hud",
	"splash", "pre_loading", "confirm_quit", "credits",
]

var _fails: int = 0
var _checked: int = 0
var _cyrillic := RegEx.create_from_string("[\\x{0400}-\\x{04FF}]")

func _ready() -> void:
	LocalizationManager.set_language("en")
	await get_tree().process_frame
	var view := Vector2(get_viewport().get_visible_rect().size)
	print("[uilay] viewport = %dx%d" % [int(view.x), int(view.y)])
	for id in UIManager.SCREENS.keys():
		await _check_screen(id, view)
	var menu: Node = (load(Routes.MENU) as PackedScene).instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	_checked += 1
	_check_full_rect(&"main_menu", menu)
	# A CRLF checkout puts CR into the scene's two-line title: the Label draws a blank line.
	var menu_title := menu.find_child("Title", true, false) as Label
	if menu_title == null or menu_title.text.contains("\r"):
		_fail("main_menu/Title: missing or its text carries a CR (blank line between the words)")
	menu.queue_free()
	for scene_name in LIVE_SCENES:
		var inst: Node = (load("res://scenes/ui/%s.tscn" % scene_name) as PackedScene).instantiate()
		get_tree().root.add_child(inst)
		await get_tree().process_frame
		await get_tree().process_frame
		_scan_cyrillic(StringName("scene/" + scene_name), inst)
		inst.queue_free()
	print("[uilay] экранов проверено: ", _checked)
	print("[uilay] DONE fails=", _fails)
	get_tree().quit(1 if _fails > 0 else 0)

func _check_screen(id: StringName, view: Vector2) -> void:
	var root: Control = UIManager._get_screen(id)
	if root == null:
		_fail("%s: экран не создался" % id)
		return
	root.visible = true
	# Два кадра: первый — разложить контейнеры, второй — увидеть итоговые размеры.
	await get_tree().process_frame
	await get_tree().process_frame
	_checked += 1
	var r: Rect2 = root.get_global_rect()
	# Экраны-сцены центрируются и могут быть меньше кадра — от них требуется
	# только попадать в кадр целиком; полноэкранность проверяем у остальных.
	var is_scene: bool = String(UIManager.SCREENS.get(id, "")).ends_with(".tscn")
	if not is_scene and (r.size.x < view.x - 1.0 or r.size.y < view.y - 1.0):
		_fail("%s: корень %dx%d вместо %dx%d — вероятно set_anchors_preset() без offsets"
			% [id, int(r.size.x), int(r.size.y), int(view.x), int(view.y)])
	_check_children(id, root, view)
	_check_full_rect(id, root)
	_scan_cyrillic(id, root)
	# A centre-anchored box must really be centred: without grow-both it grows right
	# and down from the centre (the win and death panels sat off-centre at rc14).
	for c in root.get_children():
		if not (c is Container) or not c.visible:
			continue
		var cc := c as Control
		if is_equal_approx(cc.anchor_left, 0.5) and is_equal_approx(cc.anchor_right, 0.5) and is_equal_approx(cc.anchor_top, 0.5) and is_equal_approx(cc.anchor_bottom, 0.5):
			var off: Vector2 = cc.get_global_rect().get_center() - view / 2.0
			if off.length() > 4.0:
				_fail("%s/%s: centre-anchored box off-centre by (%d,%d)" % [id, cc.name, int(off.x), int(off.y)])
	root.visible = false

## Видимый элемент с реальным размером обязан пересекаться с кадром хотя бы
## наполовину: панель, уехавшая за край, для игрока просто не существует.
## Внутри ScrollContainer это неверно по определению — его контент специально
## больше видимой области и клипуется/скроллится, а не «уехал за край». Без
## этого исключения любой длинный список (кодекс, ачивки, журнал) даёт сотни
## ложных срабатываний на собственном скроллящемся содержимом.
func _check_children(id: StringName, node: Node, view: Vector2, in_scroll: bool = false) -> void:
	for c in node.get_children():
		# MOUSE_FILTER_IGNORE is this codebase's own established convention
		# for purely decorative, non-interactive overlays (see the hero art in
		# main_menu.gd) - menu_background.gd's parallax skyline tiles use it
		# too, deliberately staged partly/fully off-screen so a scroll
		# animation can bring them into view with no visible seam. An
		# off-screen INTERACTIVE control is always worth flagging (the
		# player can't click it); an off-screen decorative one, by design,
		# often isn't.
		if c is Control and c.visible and not in_scroll and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			var cr: Rect2 = (c as Control).get_global_rect()
			if cr.size.x > 1.0 and cr.size.y > 1.0:
				var screen := Rect2(Vector2.ZERO, view)
				var clip := screen.intersection(cr)
				var area: float = cr.size.x * cr.size.y
				if clip.size.x * clip.size.y < area * 0.5:
					_fail("%s/%s: pos=(%d,%d) size=(%dx%d) — больше половины вне кадра"
						% [id, c.name, int(cr.position.x), int(cr.position.y),
							int(cr.size.x), int(cr.size.y)])
		if c is Control:
			_check_children(id, c, view, in_scroll or c is ScrollContainer)

## set_anchors_preset() keeps the node's current rect: called after the parent
## was sized it leaves a fresh node 0x0 (the rc14 main menu hero art was never
## drawn) or at its texture size (the title grunge spilled over the buttons).
## Children of containers get their rect from the container; an inset panel
## (smaller but not empty) is fine.
func _check_full_rect(id: StringName, node: Node) -> void:
	for c in node.get_children():
		if not (c is Control):
			continue
		var cc := c as Control
		if cc.visible and node is Control and not (node is Container) and cc.anchor_left == 0.0 and cc.anchor_top == 0.0 and cc.anchor_right == 1.0 and cc.anchor_bottom == 1.0:
			var ps: Vector2 = (node as Control).size
			if ps.x > 1.0 and ps.y > 1.0 and (cc.size.x < 1.0 or cc.size.y < 1.0 or cc.size.x > ps.x + 2.0 or cc.size.y > ps.y + 2.0):
				_fail("%s/%s: full-rect anchors but %dx%d in a %dx%d parent (use set_anchors_and_offsets_preset)" % [id, cc.name, int(cc.size.x), int(cc.size.y), int(ps.x), int(ps.y)])
		if not (c is ScrollContainer):
			_check_full_rect(id, c)

## The language picker lists native names on purpose, so dropdowns are skipped.
func _scan_cyrillic(id: StringName, node: Node) -> void:
	for c in node.get_children():
		if not (c is OptionButton):
			for prop in ["text", "tooltip_text", "placeholder_text"]:
				if prop in c and _cyrillic.search(String(c.get(prop))) != null:
					_fail("%s/%s.%s shows Cyrillic in English: %s" % [id, c.name, prop, String(c.get(prop)).left(60)])
		_scan_cyrillic(id, c)

func _fail(msg: String) -> void:
	_fails += 1
	print("[uilay] [FAIL] ", msg)
