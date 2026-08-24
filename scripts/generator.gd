class_name Generator
extends Node3D
## WAVE 6 P4: real fuel-consuming generator. Previously this class had
## fuel_level/refuel()/interact() but was never instantiated anywhere,
## required pre-built %PowerLever/%FuelGauge/%InteractArea child nodes
## that no scene provided, and refuel() never touched the player's
## actual inventory - the "fuel" was just an internal float nothing
## could ever change. Rewired to the same "interactable" group
## convention as power_switch.gd/cable_box_interactable.gd (procedural
## visuals, no dependency on a hand-built scene), and to really consume
## StreetBuilder.GENERATOR_FUEL (gas_canister) from InventoryManager.

const FUEL_ITEM: StringName = &"gas_canister"
const RUN_TIME_PER_CANISTER: float = 90.0

var is_active: bool = false
var fuel_level: float = 0.0
var fuel_drain_rate: float = 1.0 / RUN_TIME_PER_CANISTER

signal generator_activated()
signal generator_deactivated()
signal fuel_low()
signal fuel_empty()

var _light: OmniLight3D
var _mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()
	fuel_empty.connect(_on_fuel_empty)

func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 1.2, 0.8)
	_mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.17, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.706, 0.271, 0.184)
	mat.emission_energy_multiplier = 0.0
	_mesh.material_override = mat
	_mesh.position = Vector3(0, 0.6, 0)
	add_child(_mesh)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 1.2, 0.8)
	cs.shape = shape
	cs.position = Vector3(0, 0.6, 0)
	body.add_child(cs)
	add_child(body)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.788, 0.635, 0.290)
	_light.light_energy = 0.0
	_light.omni_range = 5.0
	_light.position = Vector3(0, 1.2, 0)
	add_child(_light)

func _process(delta: float) -> void:
	if is_active and fuel_level > 0.0:
		fuel_level = maxf(0.0, fuel_level - fuel_drain_rate * delta)
		if fuel_level <= 0.2 and fuel_level > 0.0:
			fuel_low.emit()
		if fuel_level <= 0.0:
			_deactivate()
			fuel_empty.emit()

func can_interact() -> bool:
	return true

func interact_prompt() -> String:
	if is_active:
		return LocalizationManager.t("ACTION_STOP_GENERATOR")
	return LocalizationManager.t("ACTION_START_GENERATOR")

func interact(_player: Node = null) -> void:
	if is_active:
		_deactivate()
		return
	if fuel_level > 0.0:
		_activate()
		return
	var inv := get_node_or_null("/root/InventoryManager")
	if inv == null or not inv.has(FUEL_ITEM, 1):
		EventBus.inventory_notice.emit(LocalizationManager.tf("NEED_ITEM", [_item_name(FUEL_ITEM)]))
		return
	inv.remove(FUEL_ITEM, 1)
	fuel_level = 1.0
	_activate()

func refuel(amount: float) -> void:
	fuel_level = minf(fuel_level + amount, 1.0)

func _activate() -> void:
	is_active = true
	if _light: _light.light_energy = 2.0
	var mat := _mesh.material_override as StandardMaterial3D
	if mat: mat.emission_energy_multiplier = 1.2
	generator_activated.emit()

func _deactivate() -> void:
	is_active = false
	if _light: _light.light_energy = 0.0
	var mat := _mesh.material_override as StandardMaterial3D
	if mat: mat.emission_energy_multiplier = 0.0
	generator_deactivated.emit()

func _on_fuel_empty() -> void:
	EventBus.inventory_notice.emit(LocalizationManager.t("GENERATOR_OUT_OF_FUEL"))

func _item_name(item_id: StringName) -> String:
	var res_path := "res://data/items/%s.tres" % String(item_id)
	if ResourceLoader.exists(res_path):
		var data = load(res_path)
		if data != null and not String(data.display_name).is_empty():
			return String(data.display_name)
	return String(item_id)
