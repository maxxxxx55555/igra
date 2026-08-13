extends Node3D
## Распределительный щит района — главный объект прогресса игры.
##
## Раньше здесь был один вызов PowerGrid.toggle_district(), то есть тумблер
## DARK <-> STREETS. Из-за этого район физически не мог дойти до стадии FULL,
## а от неё зависит вся игра: пререквизиты соседних районов (is_unlocked),
## победа (_check_victory), концовки и достижения. Игру нельзя было пройти
## в принципе — и это при том, что и босс, и экран победы, и пять концовок
## давно написаны.
##
## Теперь щит — то, чем он задуман в GDD §1.2: ремонт за найденные материалы,
## по одной стадии за раз.
##   DARK    --кабель-------->  PARTIAL  (часть фонарей)
##   PARTIAL --предохранитель-> STREETS  (улицы горят)
##   STREETS --транзистор----->  FULL    (район спасён)

@export var district_id: StringName = &""
@export var locked: bool = false

## Что нужно, чтобы поднять район на следующую стадию. Все три предмета
## DistrictLoot кладёт в каждый район, поэтому он проходим «своими силами»,
## но их можно принести и из других районов.
const REPAIR_COST: Dictionary = {
	DistrictData.Stage.PARTIAL: &"cable",
	DistrictData.Stage.STREETS: &"fuse",
	DistrictData.Stage.FULL: &"transistor",
}

## Ключи перечислены явно: статическая проверка локализации не умеет
## разворачивать "DISTRICT_STAGE_%d" и считала бы их потерянными.
const STAGE_MSG_KEYS: Array[String] = [
	"DISTRICT_STAGE_1", "DISTRICT_STAGE_1", "DISTRICT_STAGE_2", "DISTRICT_STAGE_3",
]

var _panel: MeshInstance3D
var _light: OmniLight3D
var _label: Label3D
var _stage_label: Label3D
var _bus: Node

func _ready() -> void:
	_bus = get_node_or_null("/root/EventBus")
	add_to_group("interactable")
	_build_visual()
	call_deferred("_refresh_visual")
	if _bus != null:
		_bus.district_stage_changed.connect(func(id: StringName, _s: int) -> void:
			if id == district_id:
				_refresh_visual())

func _build_visual() -> void:
	_panel = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.8, 1.6, 0.2)
	_panel.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.3)
	mat.emission_energy_multiplier = 0.4
	_panel.material_override = mat
	_panel.position = Vector3(0, 0.8, 0)
	add_child(_panel)

	# Щит нужно ещё и не проходить насквозь: голый Node3D был бесплотным.
	var body := StaticBody3D.new()
	body.name = "Body"
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 1.6, 0.2)
	cs.shape = shape
	cs.position = Vector3(0, 0.8, 0)
	body.add_child(cs)
	add_child(body)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.7, 0.3)
	_light.light_energy = 0.0
	_light.omni_range = 6.0
	_light.position = Vector3(0, 1.4, 0.6)
	add_child(_light)

	_label = Label3D.new()
	_label.text = _district_name()
	_label.font_size = 32
	_label.position = Vector3(0, 2.2, 0.1)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1.0, 0.85, 0.4)
	add_child(_label)

	# Вторая строка — сколько стадий пройдено. Без неё игрок не понимает,
	# что щит можно чинить несколько раз.
	_stage_label = Label3D.new()
	_stage_label.font_size = 24
	_stage_label.position = Vector3(0, 1.95, 0.1)
	_stage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stage_label.modulate = Color(0.68, 0.71, 0.75)
	add_child(_stage_label)

func _district_name() -> String:
	var pg := get_node_or_null("/root/PowerGrid")
	if pg != null:
		var d = pg.get_district(district_id)
		if d != null and not String(d.display_name).is_empty():
			return String(d.display_name)
	return String(district_id).to_upper()

func _stage() -> int:
	var pg := get_node_or_null("/root/PowerGrid")
	return pg.get_stage(district_id) if pg != null else 0

func _next_stage() -> int:
	return mini(_stage() + 1, DistrictData.Stage.FULL)

func _refresh_visual() -> void:
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null:
		return
	var stage: int = _stage()
	# Свет щита растёт вместе со стадией — видимая награда за ремонт.
	var energy: float = [0.0, 0.6, 1.5, 2.6][clampi(stage, 0, 3)]
	_light.light_energy = energy
	var mat := _panel.material_override as StandardMaterial3D
	if mat != null:
		mat.emission_energy_multiplier = maxf(0.2, energy)
	if _stage_label != null:
		_stage_label.text = "%d/3" % stage
	if _bus != null and not _bus.district_powered.is_connected(_refresh_visual):
		_bus.district_powered.connect(_refresh_visual)

## Interactor скрывает подсказку у полностью восстановленного щита.
func can_interact() -> bool:
	return not locked and district_id != &"" and _stage() < DistrictData.Stage.FULL

func interact_prompt() -> String:
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null:
		return ""
	if not pg.is_unlocked(district_id):
		return LocalizationManager.tf("PROMPT_NEED_DISTRICT", [pg.missing_prerequisite_name(district_id)])
	var need: StringName = REPAIR_COST.get(_next_stage(), &"")
	return LocalizationManager.tf("PROMPT_REPAIR", [_item_name(need)])

func interact(_player: Node = null) -> void:
	if locked or district_id == &"":
		return
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null:
		return
	var stage: int = _stage()
	if stage >= DistrictData.Stage.FULL:
		EventBus.inventory_notice.emit(LocalizationManager.t("DISTRICT_ALREADY_FULL"))
		return
	# Порядок восстановления города: без соседа-предка район не запитать.
	if not pg.is_unlocked(district_id):
		EventBus.inventory_notice.emit(
			LocalizationManager.tf("NEED_DISTRICT_FIRST", [pg.missing_prerequisite_name(district_id)]))
		return

	var target: int = stage + 1
	var need: StringName = REPAIR_COST.get(target, &"")
	var inv := get_node_or_null("/root/InventoryManager")
	if need != &"":
		if inv == null or not inv.has(need, 1):
			EventBus.inventory_notice.emit(
				LocalizationManager.tf("NEED_ITEM", [_item_name(need)]))
			return
		inv.remove(need, 1)

	if not pg.advance_district(district_id, target):
		return

	_on_repaired(target)

func _on_repaired(stage: int) -> void:
	_refresh_visual()
	EventBus.puzzle_solved.emit(StringName("switch_%s" % String(district_id)), district_id)
	EventBus.inventory_notice.emit(
		LocalizationManager.tf(STAGE_MSG_KEYS[clampi(stage, 1, 3)], [_district_name()]))
	if stage >= DistrictData.Stage.FULL:
		EventBus.toast_requested.emit(
			LocalizationManager.tf("DISTRICT_RESTORED_TOAST", [_district_name()]), "objective")
	var tw := create_tween()
	tw.tween_property(_light, "light_energy", 4.0, 0.08)
	tw.tween_property(_light, "light_energy", _light.light_energy, 0.45)

func _item_name(item_id: StringName) -> String:
	if item_id == &"":
		return ""
	var db := get_node_or_null("/root/ItemDatabase")
	if db != null and db.has_method("get_item"):
		var d = db.call("get_item", item_id)
		if d != null and not String(d.display_name).is_empty():
			return String(d.display_name)
	var res_path := "res://data/items/%s.tres" % String(item_id)
	if ResourceLoader.exists(res_path):
		var data = load(res_path)
		if data != null and not String(data.display_name).is_empty():
			return String(data.display_name)
	return String(item_id)
