class_name DocumentPickup
extends Node3D

@export var document_id: String = ""
@export var document_title: String = "Untitled"
@export var document_content: String = ""

const CATALOG_PATH: String = "res://data/documents/documents_catalog.json"

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
	_load_from_catalog()
	if document_id != "":
		# /root/JournalManager не существует; учёт документов ведёт ProgressTracker.
		if ProgressTracker.is_doc_unlocked(document_id):
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
	# Раньше подбор только гасил модельку: документ не засчитывался в
	# прогресс, не открывался в журнале и игрок не получал уведомления.
	if document_id != "":
		ProgressTracker.unlock_doc(document_id)
	EventBus.inventory_notice.emit(
		LocalizationManager.t("DOC_FOUND") + ": " + document_title)
	document_collected.emit(document_title, document_id)
	queue_free()

## Заголовок и текст берём из data/documents/documents_catalog.json —
## 33 готовых документа, которые до сих пор не читал никто.
func _load_from_catalog() -> void:
	if document_id == "" or document_content != "":
		return
	var f := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Array):
		return
	for entry in (parsed as Array):
		if entry is Dictionary and String(entry.get("doc_id", "")) == document_id:
			document_title = String(entry.get("title", document_title))
			document_content = String(entry.get("content", ""))
			return

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
