extends RefCounted
## Touch slots follow measured labels and icon padding, including translated text.

const EDGE: float = 48.0
const GAP: float = 12.0
const SIDE_BUTTONS: Array[String] = ["BtnJump", "BtnFlash", "BtnStrobe", "BtnWheel", "BtnInventory", "BtnReload", "BtnMelee", "BtnUV", "BtnDodge", "BtnWorkbench"]

## QA override: TLS_FORCE_MOBILE_TOUCH=1 forces the phone HUD in a desktop
## window, so the 1600x720 touch audit can exercise the real arc layout.
static func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") \
		or OS.get_environment("TLS_FORCE_MOBILE_TOUCH") == "1"

static func pixel_ratio(viewport: Viewport) -> float:
	var window := viewport.get_window()
	return maxf(float(window.size.x) / maxf(1.0, viewport.get_visible_rect().size.x), 0.1)

static func arrange(cluster: Control, row_limit: float, factor: float = 1.0) -> Vector2:
	var target := Vector2.ONE * ceilf(56.0 / (pixel_ratio(cluster.get_viewport()) * factor)) if is_mobile() else Vector2.ZERO
	var extent := Vector2.ZERO
	var right: float = EDGE
	var bottom_height: float = 0.0
	for name_: String in ["BtnAttack", "BtnSprint", "BtnStealth"]:
		var button := cluster.get_node_or_null(name_) as Button
		if button == null:
			continue
		var size_: Vector2 = button.get_combined_minimum_size().max(target)
		if name_ == "BtnAttack":
			size_ = size_.max(target * 72.0 / 56.0)
		_place(button, right, EDGE, size_)
		extent.x = maxf(extent.x, right + size_.x)
		bottom_height = maxf(bottom_height, size_.y)
		right += size_.x + GAP
	var above: float = EDGE + bottom_height + 16.0
	var interact := cluster.get_node_or_null("BtnInteract") as Button
	if interact != null:
		var size_: Vector2 = interact.get_combined_minimum_size().max(target * 72.0 / 56.0)
		_place(interact, 60.0, above, size_)
		above += size_.y + 16.0
	extent.y = above
	row_limit = maxf(row_limit, extent.x)
	right = EDGE
	var row_height: float = 0.0
	for name_: String in SIDE_BUTTONS:
		var button := cluster.get_node_or_null(name_) as Button
		if button == null:
			continue
		var size_: Vector2 = button.get_combined_minimum_size().max(target)
		if right > EDGE and right + size_.x > row_limit:
			above += row_height + GAP
			right = EDGE
			row_height = 0.0
		_place(button, right, above, size_)
		extent.x = maxf(extent.x, right + size_.x)
		extent.y = maxf(extent.y, above + size_.y)
		row_height = maxf(row_height, size_.y)
		right += size_.x + GAP
	return extent

static func _place(button: Button, right: float, bottom: float, size_: Vector2) -> void:
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = -right - size_.x
	button.offset_right = -right
	button.offset_top = -bottom - size_.y
	button.offset_bottom = -bottom
