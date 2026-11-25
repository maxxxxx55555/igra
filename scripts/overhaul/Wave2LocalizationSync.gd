class_name Wave2LocalizationSync
extends Node

signal locale_changed(new_locale: String)

func _ready() -> void:
	LocalizationManager.language_changed.connect(_refresh_language)

func get_language() -> String:
	return LocalizationManager.current_lang

func toggle_language() -> String:
	return set_language("en" if get_language() == "ru" else "ru")

func set_language(locale_code: String, persist: bool = true) -> String:
	var locale := "ru" if locale_code.strip_edges().to_lower().get_slice("_", 0).get_slice("-", 0) == "ru" else "en"
	LocalizationManager.set_language(locale, persist)
	return get_language()

func _refresh_language(locale: String) -> void:
	refresh_tree_localization(get_tree().root)
	locale_changed.emit(locale)

func t(key: String, args: Dictionary = {}) -> String:
	var value := LocalizationManager.t(key)
	for argument in args:
		value = value.replace("{" + str(argument) + "}", str(args[argument]))
	return value

func bind_node_key(node: Node, i18n_key: String, args: Dictionary = {}) -> void:
	if not is_instance_valid(node):
		return
	node.set_meta(&"tls_i18n_key", i18n_key)
	node.set_meta(&"tls_i18n_args", args.duplicate())
	_apply_to_node(node)


func refresh_tree_localization(root: Node) -> void:
	if not is_instance_valid(root):
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if not is_instance_valid(cur):
			continue
		for child in cur.get_children():
			stack.append(child)
		_apply_to_node(cur)


func _apply_to_node(node: Node) -> void:
	if node.has_method("refresh_localization"):
		node.call("refresh_localization")
	if node.has_meta(&"tls_i18n_key"):
		var key: String = String(node.get_meta(&"tls_i18n_key", ""))
		var args_v: Variant = node.get_meta(&"tls_i18n_args", {})
		var args: Dictionary = args_v as Dictionary if (args_v is Dictionary) else {}
		var resolved: String = t(key, args)
		if node is Label:
			(node as Label).text = resolved
		elif node is Button:
			(node as Button).text = resolved
		elif node is RichTextLabel:
			(node as RichTextLabel).text = resolved
		elif node is Control:
			(node as Control).tooltip_text = resolved
