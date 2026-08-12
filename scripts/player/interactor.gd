extends Node
class_name Interactor
## Наведение на объекты и клавиша «Взаимодействовать».
##
## Это самый крупный из недостающих кусков игры. В проекте есть готовые
## интерактивные объекты — рубильник района (power_switch.gd), генератор
## обучения, тайники, двери, осматриваемые предметы: у всех написан метод
## interact(). Но вызвать его было некому.
##
## Единственный живой контроллер игрока (player_3d.gd) на клавишу interact
## делал ровно две вещи: _try_inspect() по группе "inspectable" и вход в
## укрытие. Группу "interactable" не опрашивал никто, InputService.
## interact_requested слушал только puzzle_3d — сцена, которая ни в одном
## районе не стоит. Итог: рубильники в 11 районах были декорацией, район
## нельзя было запитать, а значит и пройти игру.
##
## Здесь один узел на игрока, который:
##   1) каждый кадр ищет ближайшую доступную цель перед игроком;
##   2) показывает подсказку в HUD через player_interact_available;
##   3) по нажатию вызывает interact() у цели, подстраиваясь под обе
##      сигнатуры, встречающиеся в проекте — interact() и interact(player).

## Дальше этого объекты не подхватываются.
const REACH: float = 3.2
## Косинус половинного угла обзора: цель должна быть примерно перед игроком.
## 0.35 ≈ 110° — достаточно щадяще для тача, где прицелиться точно трудно.
const AIM_DOT: float = 0.35
## Опрос списка целей — 10 раз в секунду; каждый кадр это лишняя работа
## на мобильном GPU, а на глаз разницы нет.
const SCAN_INTERVAL: float = 0.1

var _player: Node3D = null
var _aim: Node3D = null
var _target: Node = null
var _scan_timer: float = 0.0
var _last_available: bool = false

func setup(player: Node3D, aim_source: Node3D = null) -> void:
	_player = player
	_aim = aim_source if aim_source != null else player

func _ready() -> void:
	name = "Interactor"
	if _player == null:
		_player = get_parent() as Node3D
	if _aim == null:
		_aim = _player
	var isv := get_node_or_null("/root/InputService")
	if isv != null and isv.has_signal("interact_requested"):
		isv.interact_requested.connect(_on_interact_requested)

func _process(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return
	_scan_timer = SCAN_INTERVAL
	_refresh_target()

## Текущая цель — то, что вызовется по нажатию. null, если ничего рядом.
func current_target() -> Node:
	return _target

func _refresh_target() -> void:
	var found := _find_best()
	if found != _target:
		_target = found
	var available := _target != null
	if available != _last_available:
		_last_available = available
		EventBus.player_interact_available.emit(available)
		if available:
			EventBus.interact_prompt_changed.emit(_prompt_for(_target))

func _find_best() -> Node:
	if _player == null or not is_instance_valid(_player):
		return null
	if not _player.get("gameplay_active"):
		return null
	var origin: Vector3 = _player.global_position
	var forward: Vector3 = -(_aim.global_transform.basis.z) if is_instance_valid(_aim) else Vector3.FORWARD
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()

	var best: Node = null
	var best_score: float = -1.0
	for node in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		var n3: Node3D = node as Node3D
		var to: Vector3 = n3.global_position - origin
		var dist: float = to.length()
		if dist > REACH:
			continue
		if not _is_available(node):
			continue
		var flat: Vector3 = Vector3(to.x, 0.0, to.z)
		var dot: float = 1.0
		if flat.length_squared() > 0.0001 and forward.length_squared() > 0.0001:
			dot = forward.dot(flat.normalized())
			if dot < AIM_DOT:
				continue
		# Ближе и прямее по курсу — выше приоритет.
		var score: float = dot * 2.0 - dist / REACH
		if score > best_score:
			best_score = score
			best = node
	return best

## Объект может временно не принимать взаимодействие: занятое укрытие,
## уже решённый пазл, запертый рубильник.
func _is_available(node: Node) -> bool:
	if node.has_method("can_interact"):
		return bool(node.call("can_interact"))
	if node.has_method("can_enter"):
		return bool(node.call("can_enter"))
	if node.get("locked") == true:
		return false
	if node.get("solved") == true:
		return false
	if node.get("completed") == true:
		return false
	return true

func _prompt_for(node: Node) -> String:
	if node == null:
		return ""
	if node.has_method("interact_prompt"):
		return String(node.call("interact_prompt"))
	if node.has_method("get_prompt"):
		return String(node.call("get_prompt"))
	return LocalizationManager.t("PROMPT_INTERACT")

func _on_interact_requested() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if not _is_available(_target):
		return
	_invoke(_target)
	# Цель могла исчезнуть (queue_free) или перестать быть доступной.
	_scan_timer = 0.0
	call_deferred("_refresh_target")

## В проекте сосуществуют две сигнатуры: interact() и interact(player).
## Единый вызов избавляет от «Invalid call. Nonexistent function» в рантайме.
func _invoke(node: Node) -> void:
	if not node.has_method("interact"):
		return
	var arg_count := _interact_arg_count(node)
	if arg_count >= 1:
		node.call("interact", _player)
	else:
		node.call("interact")
	EventBus.interaction_done.emit(String(node.name))

func _interact_arg_count(node: Node) -> int:
	for m in node.get_method_list():
		if String(m.get("name", "")) == "interact":
			var args: Array = m.get("args", [])
			return args.size()
	return 0
