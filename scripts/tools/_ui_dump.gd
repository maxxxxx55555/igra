extends Node3D
## Дамп фактического UI: что реально видно на экране и в каком прямоугольнике.
## Нужен потому, что HUD собирается из нескольких CanvasLayer'ов (сцена + код
## + автолоады), и по .tscn нельзя понять, кто рисует что поверх чего.
## Запуск: godot --headless --path . res://scenes/tools/ui_dump_scene.tscn

const VIEW: Vector2 = Vector2(1280, 720)

## Реальный размер вьюпорта, а не предполагаемый: headless берёт разрешение из
## project.godot, и захардкоженные 1280x720 отфильтровывали весь правый и нижний
## HUD как «за кадром».
var _view: Vector2 = VIEW

func _ready() -> void:
	_view = Vector2(get_viewport().get_visible_rect().size)
	print("[ui] viewport = %dx%d" % [int(_view.x), int(_view.y)])
	var main: Node = load("res://scenes/main_3d.tscn").instantiate()
	add_child(main)
	# Сплэш держит экран 3 с и только потом отдаёт управление меню — снимать
	# состояние раньше бессмысленно, поэтому идём по реальной шкале загрузки.
	for t in [1.0, 3.5, 6.0]:
		await get_tree().create_timer(t if t == 1.0 else 2.5).timeout
		print("[ui] ===== t=%.1fs  state=%d =====" % [t, (GameManager.current_state if GameManager != null else 0)])
		_dump()
	GameManager._change_state(GameManager.GameState.PLAYING)
	var screens := get_tree().root.find_child("Screens", true, false)
	if screens and screens.has_method("hide_all"):
		screens.hide_all()
	await get_tree().create_timer(2.0).timeout
	print("[ui] ===== PLAYING STATE =====")
	_dump()
	get_tree().quit()

func _dump() -> void:
	# Слой 0 — узлы Control, подвешенные НЕ в CanvasLayer (например, прямо в
	# Node3D-сцене). Они рисуются поверх 3D и легко превращаются в невидимый
	# в редакторе, но непрозрачный в игре прямоугольник — их надо видеть.
	print("[ui] LAYER <default canvas>  layer=0 visible=true")
	for c in _root_controls(get_tree().root):
		_print_control(get_tree().root, c)
	for layer in _layers(get_tree().root):
		var vis: bool = layer.visible if layer is CanvasLayer else true
		print("[ui] LAYER %s  layer=%d visible=%s" % [
			layer.get_path(), layer.get("layer") if layer is CanvasLayer else 0, vis])
		for c in _controls(layer):
			_print_control(layer, c)

func _print_control(base: Node, c: Control) -> void:
	var r := c.get_global_rect()
	# Интересует только то, что реально нарисуется: видимое, ненулевое
	# и попадающее в кадр.
	if not c.is_visible_in_tree() or r.size.x < 4.0 or r.size.y < 4.0:
		return
	if not Rect2(Vector2.ZERO, _view).intersects(r):
		return
	print("[ui]   %-42s %-18s pos=(%4d,%4d) size=(%4d,%4d) mod_a=%.2f%s" % [
		String(base.get_path_to(c)), c.get_class(),
		int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y),
		c.modulate.a, _clip_note(r)])

## Controls вне CanvasLayer: идём по дереву, но не заходим внутрь слоёв.
func _root_controls(n: Node, acc: Array[Control] = []) -> Array[Control]:
	for c in n.get_children():
		if c is CanvasLayer:
			continue
		if c is Control:
			acc.append(c)
			continue  # детей Control уже покажет сам Control
		_root_controls(c, acc)
	return acc

func _clip_note(r: Rect2) -> String:
	var out := ""
	if r.position.x < -1.0 or r.position.y < -1.0:
		out += " [OFFSCREEN-]"
	if r.end.x > _view.x + 1.0 or r.end.y > _view.y + 1.0:
		out += " [CLIPPED+]"
	return out

func _layers(n: Node, acc: Array[Node] = []) -> Array[Node]:
	if n is CanvasLayer:
		acc.append(n)
	for c in n.get_children():
		_layers(c, acc)
	return acc

func _controls(n: Node, acc: Array[Control] = []) -> Array[Control]:
	for c in n.get_children():
		if c is CanvasLayer:
			continue  # вложенный слой обойдём отдельно
		if c is Control:
			acc.append(c)
		_controls(c, acc)
	return acc
