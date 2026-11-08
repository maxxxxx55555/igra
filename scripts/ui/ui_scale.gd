class_name UiScale
extends RefCounted

const NARROW_WIDTH: float = 1120.0
const MIN_TOUCH: float = 48.0
## The LOG toggle (toast_manager.gd) and the Map button (hud_3d.gd) share one row under the stat panel; both
## position from this single helper so the safe-area inset is computed once and never added twice on a resize.
const LOG_MAP_ROW_X: float = 16.0
const LOG_MAP_ROW_TOP: float = 290.0

static func narrow_layout(width: float, text_scale: float) -> bool:
	return width < NARROW_WIDTH or text_scale > 1.16

static func min_touch() -> float:
	return MIN_TOUCH

static func log_map_row(viewport: Vector2) -> Vector2:
	var inset := insets(viewport)
	return Vector2(LOG_MAP_ROW_X + inset.x, LOG_MAP_ROW_TOP + inset.y)

static func insets(viewport: Vector2) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var screen: Vector2 = Vector2(DisplayServer.screen_get_size())
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	if screen.x <= 1.0 or screen.y <= 1.0 or safe.size.x <= 1.0:
		return Vector4.ZERO
	var sx: float = viewport.x / screen.x
	var sy: float = viewport.y / screen.y
	return Vector4(safe.position.x * sx, safe.position.y * sy,
		(screen.x - safe.end.x) * sx, (screen.y - safe.end.y) * sy)
