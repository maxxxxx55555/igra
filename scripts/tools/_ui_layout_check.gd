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
##   2. каждый видимый потомок с ненулевым размером попадает в кадр.
##
## Запуск: godot --headless --path . res://scenes/tools/ui_layout_check_scene.tscn

var _fails: int = 0
var _checked: int = 0

func _ready() -> void:
	await get_tree().process_frame
	var view := Vector2(get_viewport().get_visible_rect().size)
	print("[uilay] viewport = %dx%d" % [int(view.x), int(view.y)])
	for id in UIManager.SCREENS.keys():
		await _check_screen(id, view)
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
	root.visible = false

## Видимый элемент с реальным размером обязан пересекаться с кадром хотя бы
## наполовину: панель, уехавшая за край, для игрока просто не существует.
func _check_children(id: StringName, node: Node, view: Vector2) -> void:
	for c in node.get_children():
		if c is Control and c.visible:
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
			_check_children(id, c, view)

func _fail(msg: String) -> void:
	_fails += 1
	print("[uilay] [FAIL] ", msg)
