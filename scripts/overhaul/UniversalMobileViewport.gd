extends Node
## Screen roots and their decorative backdrops may stretch. Embedded widgets keep their own layout.
func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if not node is Control:
		return
	var parent := node.get_parent()
	if node.scene_file_path.begins_with("res://scenes/ui/") and not parent is Container:
		if parent is Window or parent is CanvasLayer or node.anchor_right == 1.0 and node.anchor_bottom == 1.0:
			node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif (node is TextureRect or node is ColorRect) and parent != null:
		if not parent.scene_file_path.begins_with("res://scenes/ui/"):
			return
		if node.name not in [&"BG", &"Background", &"Backdrop", &"KeyArt", &"Flicker", &"FadeRect"] and not (node.anchor_right == 1.0 and node.anchor_bottom == 1.0):
			return
		node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if node is TextureRect:
			node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
