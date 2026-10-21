class_name DocumentPickup
extends Node3D

@export var document_id: String = ""
@export var document_title: String = "Untitled"
@export var document_content: String = ""
## C4 (v1.0.0-ship): a lore note pinned upright on a streetlight pole (DistrictLoot), found with the flashlight; the other kind lies flat on the ground. Neither bobs, turns or glows.
@export var mounted: bool = false

const CATALOG_PATH: String = "res://data/documents/documents_catalog.json"
const _Meshes := preload("res://scripts/art/pickup_meshes.gd")

## Скрипт делят две разные сцены: в scenes/pickups меш зовётся MeshInstance3D,
## а в scenes/gameplay меш зовётся PickupMesh. Жёсткий $-путь падал на одной
## из них, поэтому ищем оба имени.
var pickup_mesh: MeshInstance3D = null
@onready var collect_area: Area3D = $CollectArea

var is_collected: bool = false

signal document_collected(title: String, doc_id: String)

func _ready() -> void:
	pickup_mesh = (get_node_or_null("PickupMesh") as MeshInstance3D)
	if pickup_mesh == null:
		pickup_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if pickup_mesh != null:
		_Meshes.dress(self, pickup_mesh, &"document", not mounted)
		if mounted:
			pickup_mesh.position = Vector3.ZERO
			pickup_mesh.rotation_degrees.x = 90.0
	_load_from_catalog()
	if document_id != "":
		# /root/JournalManager не существует; учёт документов ведёт ProgressTracker.
		if ProgressTracker.is_doc_unlocked(document_id):
			queue_free()
			return
	collect_area.body_entered.connect(_on_body_entered)

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
	# У Area3D нет свойства disabled — отключается монитор столкновений.
	# _collect() бежит из _on_body_entered (сигнал физики), где прямое
	# присваивание monitoring блокируется движком ("Function blocked
	# during in/out signal") — тот же set_deferred, что в item_pickup_3d.gd.
	collect_area.set_deferred("monitoring", false)
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
			# Content-authored entries (e.g. suburbs lore) ship i18n keys
			# instead of raw text so they translate; legacy entries keep
			# raw text as-is.
			if entry.has("title_key"):
				document_title = LocalizationManager.t(String(entry["title_key"]))
			else:
				document_title = String(entry.get("title", document_title))
			if entry.has("content_key"):
				document_content = LocalizationManager.t(String(entry["content_key"]))
			else:
				document_content = String(entry.get("content", ""))
			return
