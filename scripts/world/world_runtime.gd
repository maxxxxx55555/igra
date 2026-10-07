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
## What the last load_district cost, in milliseconds: "district", "total_ms" and the scene/enemies/loot phases of
## DistrictSceneFactory.build. get_last_load_stats() adds the street and prop phases, which finish a frame later.
var last_load_stats: Dictionary = {}
const _PRELOADER_SCRIPT := preload("res://scripts/world/district_preloader.gd")
## Background-loads what the neighbouring districts will need; requested_paths() lists what it asked the loader for.
var district_preloader: RefCounted = _PRELOADER_SCRIPT.new()
## Точка появления по умолчанию — перекрёсток (-8, -8): сетка улиц идёт по
## x/z = -24, -8, 8, 24, поэтому ровный ноль пришёлся бы на середину квартала.
## Высота чуть выше дороги, чтобы игрок встал на неё, а не застрял в плитке.
const PLAYER_SPAWN_POS: Vector3 = Vector3(-8.0, 1.2, -8.0)

func _ready() -> void:
	name = "WorldRuntime"
	# Переход между районами инициирует DistrictTrigger/DistrictManager.
	EventBus.district_entered.connect(_on_district_entered)
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
	# district_entered arrives from DistrictTrigger's body_entered — a
	# physics in/out signal. Building the new district synchronously here
	# runs every spawned pickup's _ready() inside that callback, where
	# Area3D.set_monitorable/monitoring is blocked by the engine
	# ("Function blocked during in/out signal"). Defer the rebuild to the
	# next idle frame; the _loading / _current_id guards already make
	# load_district re-entrant-safe.
	call_deferred("load_district", district_id)

## Выгружает прошлый район и строит новый. Идемпотентна и защищена от
## повторного входа: DistrictTrigger умеет стрелять несколько раз за кадр.
func load_district(district_id: StringName) -> void:
	# A deferred call can land after a scene swap (Routes.restart_game) took
	# this WorldRuntime out of the tree but before it was freed.
	if not is_inside_tree() or _loading or district_id == _current_id:
		return
	_loading = true
	var started: int = Time.get_ticks_usec()
	if is_instance_valid(_district_root):
		# Out of the tree at once: queue_free alone keeps its bodies, lights and MultiMeshes alive next to the new
		# district's until the end of the frame.
		remove_child(_district_root)
		_district_root.queue_free()
		_district_root = null
	_current_id = district_id
	var stats: Dictionary = {}
	_district_root = DistrictSceneFactory.build(self, district_id, stats)
	if _district_root != null:
		_place_player(_district_root)
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null:
		dm.current_district = String(district_id)
	district_preloader.request_around(district_id)
	_loading = false
	# BREAK_REPORT B10: the autosave used to be a separate listener on
	# EventBus.district_entered - the same signal that ALSO (via
	# _on_district_entered's own deferred call) triggers this whole
	# rebuild. DistrictSceneFactory.build() re-emits district_entered
	# synchronously from inside itself, so that listener always fired
	# before _place_player() ran below it in this same function -
	# save_all() captured the pre-teleport position every time, whichever
	# of the two emits triggered it. Moved the save to here, after the
	# district pointer and player position are both actually correct.
	if GameManager.is_playing():
		SaveSystem.autosave()
	stats["district"] = String(district_id)
	stats["total_ms"] = float(Time.get_ticks_usec() - started) / 1000.0
	last_load_stats = stats

## last_load_stats plus the street and prop phases, which run a frame after load_district returns and are read off their nodes
## (0.0 until they have run).
func get_last_load_stats() -> Dictionary:
	var stats: Dictionary = last_load_stats.duplicate()
	if is_instance_valid(_district_root):
		var streets := _district_root.get_node_or_null("StreetBuilder") as StreetBuilder
		if streets != null:
			stats["streets_ms"] = streets.build_ms
		var props := _district_root.get_node_or_null("Props") as CityStreetProps
		if props != null:
			stats["props_ms"] = props.build_ms
	return stats

## Ставит игрока на сохранённую позицию, иначе на точку старта района.
## Восстановление позиции жило в world_map.gd, которого нет в игровой сцене,
## поэтому загруженная координата никогда не применялась.
func _place_player(root: Node3D) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not (player is Node3D):
		return
	var target: Vector3
	var saved: Vector3 = SaveSystem.consume_pending_player_pos()
	if saved != Vector3.INF:
		target = saved
	else:
		var spawn := root.get_node_or_null("PlayerSpawn")
		if spawn is Node3D:
			target = (spawn as Node3D).global_position
		else:
			# Узла PlayerSpawn нет ни в одной из 11 сцен районов, поэтому при
			# переходе игрок оставался на координатах прошлого района — мог
			# оказаться в стене или за краем квартала. Ставим его на ближний
			# к центру перекрёсток.
			target = root.global_position + PLAYER_SPAWN_POS
	(player as Node3D).global_position = target
	# BREAK_REPORT B15: street_builder.gd's road collision is built via a
	# deferred call, one frame after this. Fall recovery in player_3d.gd
	# used to only arm once the player had actually STOOD on a floor -
	# zero net for the frame(s) right after any teleport, including this
	# one, if a hitch dropped the player through geometry that isn't
	# solid yet. Arming it with the intended spawn point immediately
	# closes that specific gap without needing to wait for a real floor.
	if player.has_method("mark_spawn_as_grounded"):
		player.mark_spawn_as_grounded(target)
	SaveSystem.apply_pending_vitals(player)
	GameManager.apply_pending_respawn(player)

func current_district() -> StringName:
	return _current_id
