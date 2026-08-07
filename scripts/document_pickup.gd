class_name DocumentPickup
extends Node3D

@export var document_id: String = ""
@export var document_title: String = "Untitled"
@export var document_content: String = ""

@onready var pickup_mesh: MeshInstance3D = $MeshInstance3D
@onready var collect_area: Area3D = $CollectArea
@onready var glow_light: OmniLight3D = $GlowOmniLight3D

var is_collected: bool = false
var _bob_timer: float = 0.0
var _rot_timer: float = 0.0

signal document_collected(title: String, doc_id: String)

func _ready() -> void:
	if document_id != "":
		var journal := get_tree().root.get_node_or_null("/root/JournalManager")
		if journal and journal.has_method("is_collected") and journal.is_collected(document_id):
			queue_free()
			return
	collect_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_collected:
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
	pickup_mesh.visible = false
	glow_light.visible = false
	collect_area.disabled = true
	document_collected.emit(document_title, document_id)
	queue_free()

func set_document(id: String, title: String, content: String) -> void:
	document_id = id
	document_title = title
	document_content = content