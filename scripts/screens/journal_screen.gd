class_name JournalScreen
extends CanvasLayer

@onready var document_list: ItemList = %DocumentList
@onready var content_label: RichTextLabel = %ContentLabel
@onready var close_button: Button = %CloseButton
@onready var journal_panel: Panel = %JournalPanel

var documents: Array[Dictionary] = []


func _ready() -> void:
	visible = false
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(_on_close)
	document_list.item_selected.connect(_on_document_selected)


func show_journal() -> void:
	visible = true
	_refresh_list()


func _refresh_list() -> void:
	document_list.clear()
	for doc: Dictionary in documents:
		document_list.add_item(doc.get("title", "Untitled"))


func add_document(title: String, content: String) -> void:
	documents.append({"title": title, "content": content})
	if visible:
		_refresh_list()


func _on_document_selected(index: int) -> void:
	if index >= 0 and index < documents.size():
		content_label.text = documents[index].get("content", "")


func _on_close() -> void:
	visible = false
