extends Node3D
## WorldRuntime — то, чего в игре не хватало больше всего: код, который
## реально СОБИРАЕТ мир.
##
## DistrictSceneFactory был написан целиком и корректно, но его никто никогда
## не вызывал: во всём проекте не было ни одной строчки build(). Из-за этого
## main_3d.tscn оставался пустой коробкой — ни районов, ни врагов, ни
## головоломок, ни переходов. Здесь замыкается цепочка:
##   DistrictManager.current_district -> DistrictSceneFactory.build() -> мир.

## Куда складывается инстанс района (чтобы не мешался с HUD и светом сцены).
var _district_root: Node3D = null
var _current_id: StringName = &""
var _loading: bool = false
## Точка появления по умолчанию — перекрёсток (-8, -8): сетка улиц идёт по
## x/z = -24, -8, 8, 24, поэтому ровный ноль пришёлся бы на середину квартала.
## Высота чуть выше дороги, чтобы игрок встал на неё, а не застрял в плитке.
const PLAYER_SPAWN_POS: Vector3 = Vector3(-8.0, 1.2, -8.0)

func _ready() -> void:
	name = "WorldRuntime"
	# Переход между районами инициирует DistrictTrigger/DistrictManager.
	EventBus.district_entered.connect(_on_district_entered)
	# Автосейв при входе в район раньше вёл SaveLoad — он удалён как второй
	# конкурирующий формат, обязанность переехала на единственный SaveSystem.
	EventBus.district_entered.connect(func(_id: StringName) -> void:
		if GameManager.is_playing():
			SaveSystem.save_all())
	# Стартовый район поднимаем отложенно: игрок и HUD должны быть в дереве,
	# иначе EnemyPool спавнит врагов вокруг ещё не существующей цели.
	call_deferred("_load_initial")

func _load_initial() -> void:
	var dm := get_node_or_null("/root/DistrictManager")
	var start_id: StringName = &"suburbs"
	if dm != null and not String(dm.current_district).is_empty():
		start_id = StringName(dm.current_district)
	load_district(start_id)

func _on_district_entered(district_id: StringName) -> void:
	if district_id == _current_id:
		return
	load_district(district_id)

## Выгружает прошлый район и строит новый. Идемпотентна и защищена от
## повторного входа: DistrictTrigger умеет стрелять несколько раз за кадр.
func load_district(district_id: StringName) -> void:
	if _loading or district_id == _current_id:
		return
	_loading = true
	if is_instance_valid(_district_root):
		_district_root.queue_free()
		_district_root = null
	_current_id = district_id
	_district_root = DistrictSceneFactory.build(self, district_id)
	if _district_root != null:
		_place_player(_district_root)
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null:
		dm.current_district = String(district_id)
	_loading = false

## Ставит игрока на сохранённую позицию, иначе на точку старта района.
## Восстановление позиции жило в world_map.gd, которого нет в игровой сцене,
## поэтому загруженная координата никогда не применялась.
func _place_player(root: Node3D) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not (player is Node3D):
		return
	var saved: Vector3 = SaveSystem.consume_pending_player_pos()
	if saved != Vector3.INF:
		(player as Node3D).global_position = saved
		return
	var spawn := root.get_node_or_null("PlayerSpawn")
	if spawn is Node3D:
		(player as Node3D).global_position = (spawn as Node3D).global_position
		return
	# Узла PlayerSpawn нет ни в одной из 11 сцен районов, поэтому при переходе
	# игрок оставался на координатах прошлого района — мог оказаться в стене
	# или за краем квартала. Ставим его на ближний к центру перекрёсток.
	(player as Node3D).global_position = root.global_position + PLAYER_SPAWN_POS

func current_district() -> StringName:
	return _current_id
