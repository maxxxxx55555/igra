class_name UiScale
extends RefCounted

## The smallest touch target in the UI's own (design-canvas) pixels. 48 px was judged on a
## reference phone; T8 (RELEASE_GAP_FINAL §1) found that value was never density-aware, so a
## narrower-in-dp phone got physically smaller buttons for the same number. The target now
## scales with the device's real density, normalised to the reference width, and is clamped:
## the floor is the 48 px value every layout was laid out for, the ceiling is where the HUD
## rows stop fitting. DisplayServer.screen_get_dpi() reports a fake 72 (or 0) on some drivers,
## and that case keeps the flat value - an emulator must not reshape the HUD.
const MIN_TOUCH: float = 48.0
const TOUCH_MAX: float = 88.0
const TOUCH_DP: float = 48.0
const TOUCH_REF_DP_WIDTH: float = 411.0  # 1080 px at 420 dpi: the density the 48 px was judged on
## The LOG toggle (toast_manager.gd) and the Map button (hud_3d.gd) share one row under the stat panel; both
## position from this single helper so the safe-area inset is computed once and never added twice on a resize.
const LOG_MAP_ROW_X: float = 16.0
const LOG_MAP_ROW_TOP: float = 290.0

static func min_touch() -> float:
	if not OS.has_feature("mobile"):
		return MIN_TOUCH
	var dpi := float(DisplayServer.screen_get_dpi())
	var screen: Vector2i = DisplayServer.screen_get_size()
	if dpi < 120.0 or screen.x < 320:
		return MIN_TOUCH
	var dp_width: float = float(screen.x) * 160.0 / dpi
	if dp_width <= 1.0:
		return MIN_TOUCH
	return clampf(TOUCH_DP * TOUCH_REF_DP_WIDTH / dp_width, MIN_TOUCH, TOUCH_MAX)

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
