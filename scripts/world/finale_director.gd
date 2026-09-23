extends Node
## Финал игры: появление Архитектора и настоящая победа.
##
## Босс The Architect был полностью написан (boss_3d.gd — три фазы,
## телепорты, призыв теней, обвал балок, экран победы в _trigger_death),
## но во всём проекте не было ни одной строчки, которая бы его создавала.
## Дойти до него было невозможно.
##
## Второй разрыв: PowerGrid._check_victory() объявлял победу в ту же секунду,
## когда последний район дошёл до FULL. Игрок побеждал, не увидев ни босса,
## ни финальной ночи, ни концовки за документы.
##
## Здесь эти два конца связаны так, как описано в GDD §6.3 и §12.4:
##   все 11 районов FULL -> финальная ночь -> Архитектор на электростанции
##   -> его смерть -> GameManager.trigger_win() -> EndingsManager выбирает
##   концовку по документам и секретам.

const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/boss_architect_3d.tscn")

## Где босс появляется относительно игрока, если в районе нет метки BossSpawn.
const SPAWN_OFFSET: Vector3 = Vector3(0.0, 0.0, -14.0)

var _boss: Node3D = null
var _triggered: bool = false
var _spawn_retries: int = 0
## BREAK_REPORT B1: district_entered fires once from DistrictManager.transition_to
## (before WorldRuntime's own deferred load_district swaps in the new district)
## and again from DistrictSceneFactory.build, synchronously, after the new
## district root is already parented. Both reach _on_district_entered.
## Diagnostic-confirmed: FinaleDirector (autoload) connects before WorldRuntime
## (scene node), so its deferred _spawn_boss is queued and runs first, landing
## the boss in the OLD district root a frame before it's queue_free()'d. The
## report predicted this permanently loses the boss (assuming is_instance_valid
## stays true through end-of-frame after queue_free); confirmed instead that
## Godot invalidates it immediately once queue_free() runs on the ancestor, so
## the second (post-rebuild) emit's "already spawned?" check sees false and
## retries into the now-correct district. That's an accident of engine timing,
## not a designed guarantee - anything that changes the order or timing of
## either deferred call would silently reintroduce the loss. Removed the
## dependence on it entirely: _spawn_boss now verifies the resolved root's own
## identity (scene_file_path) before parenting into it, regardless of when or
## how many times it's called. Capped so a genuinely broken transition can't
## retry forever.
const MAX_SPAWN_RETRIES: int = 120
const POWER_STATION_SCENE_PATH: String = "res://scenes/districts/power_station.tscn"

func _ready() -> void:
	name = "FinaleDirector"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	EventBus.district_restored.connect(_on_district_restored)
	EventBus.district_entered.connect(_on_district_entered)
	EventBus.boss_defeated.connect(_on_boss_defeated)

func _on_district_restored(_id: StringName, _stage: int) -> void:
	if _triggered:
		return
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null or not pg.all_restored():
		return
	_triggered = true
	EventBus.final_night_started.emit()
	EventBus.toast_requested.emit(LocalizationManager.t("FINAL_NIGHT_BEGINS"), "objective")
	EventBus.inventory_notice.emit(LocalizationManager.t("FINAL_NIGHT_GOTO_STATION"))
	# Если игрок уже стоит на электростанции — босс выходит немедленно.
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null and String(dm.current_district) == "power_station":
		call_deferred("_spawn_boss")

## Босс ждёт игрока на электростанции: приходить туда нужно самому.
func _on_district_entered(district_id: StringName) -> void:
	if not _triggered or district_id != &"power_station":
		return
	if is_instance_valid(_boss):
		return
	call_deferred("_spawn_boss")

func _spawn_boss() -> void:
	if is_instance_valid(_boss) and not _boss.is_queued_for_deletion():
		return
	var parent: Node = _district_root()
	if parent == null or (parent as Node).scene_file_path != POWER_STATION_SCENE_PATH:
		# The rebuild that swaps in the power_station scene hasn't finished
		# yet - wait one more idle frame instead of spawning into whatever
		# district is still WorldRuntime's last child (the one about to be
		# freed).
		_spawn_retries += 1
		if _spawn_retries <= MAX_SPAWN_RETRIES:
			call_deferred("_spawn_boss")
		return
	_spawn_retries = 0
	var boss := BOSS_SCENE.instantiate() as Node3D
	if boss == null:
		return
	parent.add_child(boss)
	boss.global_position = _spawn_position(parent)
	_boss = boss
	EventBus.enemy_spawned.emit(boss)
	EventBus.boss_spawned.emit()
	EventBus.toast_requested.emit(LocalizationManager.t("BOSS_APPEARS"), "danger")

func _district_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var wr = tree.root.find_child("WorldRuntime", true, false)
	if wr != null and wr.get_child_count() > 0:
		return wr.get_child(wr.get_child_count() - 1)
	return tree.current_scene

func _spawn_position(parent: Node) -> Vector3:
	var marker := parent.get_node_or_null("BossSpawn")
	if marker is Node3D:
		return (marker as Node3D).global_position
	var player := get_tree().get_first_node_in_group("player")
	if player is Node3D:
		var p: Node3D = player as Node3D
		return p.global_position + p.global_transform.basis * SPAWN_OFFSET
	return Vector3(0.0, 0.0, -14.0)

func _on_boss_defeated() -> void:
	_boss = null
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("trigger_win"):
		gm.trigger_win()
