extends Node

var _fails: int = 0

func _ready() -> void:
	for id: StringName in DistrictSceneFactory.DISTRICTS:
		await _check_district(id)
	await _check_inventory()
	print("[premium] DONE fails=", _fails)
	get_tree().quit(1 if _fails > 0 else 0)

func _check_district(id: StringName) -> void:
	var scene := load(DistrictSceneFactory.district_scene_path(id)) as PackedScene
	var root := scene.instantiate() as Node3D
	add_child(root)
	for i in 8:
		await get_tree().process_frame
	for node_name in ["FacadeTrim", "WindowSills", "FacadePipes", "CurbMM", "RoadDamageMM", "UrbanSetDressing"]:
		_expect(root.find_child(node_name, true, false) != null, "%s missing %s" % [id, node_name])
	root.queue_free()
	await get_tree().process_frame

func _check_inventory() -> void:
	SettingsManager.set_setting("text_size", 1)
	get_window().size = Vector2i(1280, 720)
	InventoryManager.try_add(&"fuse", 1, false)
	await get_tree().process_frame
	var root := UIManager._get_screen(&"inventory") as Control
	_expect(root != null, "inventory does not build")
	if root == null:
		return
	root.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	for node_name in ["EquipmentColumn", "ItemColumn", "InspectorColumn", "InventoryToolbar", "ItemGrid"]:
		_expect(root.find_child(node_name, true, false) != null, "inventory missing %s" % node_name)
	var inspector := root.find_child("InspectorColumn", true, false) as Control
	_expect(inspector != null and inspector.visible, "wide inventory hides the inspector")
	_expect(inspector != null and inspector.size.x >= 300.0, "wide inspector collapsed")
	var grid := root.find_child("ItemGrid", true, false) as GridContainer
	_expect(grid != null and grid.columns == 4, "inventory grid is not four columns")
	_expect(grid != null and grid.get_child_count() == InventoryManager.slots.size(), "grid does not show every real slot")
	_expect(UiScale.min_touch() >= 48.0, "touch target below 48")
	_expect(UiScale.narrow_layout(960.0, 1.0), "phone width did not select narrow layout")
	_expect(not UiScale.narrow_layout(1280.0, 1.0), "desktop width selected narrow layout")
	get_window().size = Vector2i(960, 540)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(not inspector.visible, "narrow inventory keeps the inline inspector")
	root.set("_overlay_open", true)
	root.call("_apply_responsive")
	var overlay := root.find_child("InventoryInspectorOverlay", true, false) as Control
	_expect(overlay != null and overlay.visible, "narrow inventory does not open the inspector overlay")
	print("[premium] inventory root=%s inspector=%s" % [root.size, inspector.size if inspector else Vector2.ZERO])
	root.visible = false

func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	_fails += 1
	print("[premium] [FAIL] ", message)
