class_name DocumentPickup
extends Node3D

@export var document_id: String = ""
@export var document_title: String = "Untitled"
@export var document_content: String = ""

## Скрипт делят две разные сцены: в scenes/pickups меш зовётся MeshInstance3D
## и есть GlowOmniLight3D, а в scenes/gameplay меш зовётся PickupMesh и света
## нет. Жёсткий $-путь падал на одной из них, поэтому ищем оба имени.
var pickup_mesh: MeshInstance3D = null
@onready var collect_area: Area3D = $CollectArea
var glow_light: OmniLight3D = null

var is_collected: bool = false
var _bob_timer: float = 0.0
var _rot_timer: float = 0.0

signal document_collected(title: String, doc_id: String)

func _ready() -> void:
	pickup_mesh = (get_node_or_null("PickupMesh") as MeshInstance3D)
	if pickup_mesh == null:
		pickup_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	_ensure_glow()
	if document_id != "":
		var journal := get_tree().root.get_node_or_null("/root/JournalManager")
		if journal and journal.has_method("is_collected") and journal.is_collected(document_id):
			queue_free()
			return
	collect_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_collected:
		return
	if pickup_mesh == null:
		return
	_bob_timer += delta
	pickup_mesh.position.y = 0.5 + sin(_bob_timer * 2.0) * 0.2
	_rot_timer += delta
	pickup_mesh.rotation.y = _rot_timer * 1.5

func _on_body_entered(body: Node) -> void:
	if is_collected:
		return
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	is_collected = true
	visible = false
	if pickup_mesh != null:
		pickup_mesh.visible = false
	if glow_light != null:
		glow_light.visible = false
	# У Area3D нет свойства disabled — отключается монитор столкновений.
	collect_area.monitoring = false
	document_collected.emit(document_title, document_id)
	queue_free()

func set_document(id: String, title: String, content: String) -> void:
	document_id = id
	document_title = title
	document_content = content

## Тёплое свечение документа создаётся в рантайме, если его нет в сцене.
func _ensure_glow() -> void:
	glow_light = get_node_or_null("GlowOmniLight3D") as OmniLight3D
	if glow_light != null:
		return
	glow_light = OmniLight3D.new()
	glow_light.name = "GlowOmniLight3D"
	glow_light.light_color = Color(0.886, 0.639, 0.235)
	glow_light.light_energy = 0.8
	glow_light.omni_range = 3.0
	add_child(glow_light)
