extends Node
## THEME UNIFICATION P0: this used to build its own separate Theme (from
## theme_tls.tres, with its own duplicated color tokens and StyleBoxFlat
## button/panel styles) and set it window-wide - completely independent of
## ThemeProvider.build_theme(), which 12 screens already call locally and
## which owns the real chrome-kit textures. Any screen that never opted
## into ThemeProvider (main_menu chief among them) silently inherited THIS
## theme instead, so last wave's button chrome was invisible there.
##
## ThemeProvider is now the single canonical source everywhere: this
## autoload just applies it window-wide so screens that don't set a local
## theme override still get the real one, not a second, drifted copy.

const HOVER_SCALE := Vector2(1.05, 1.05)
const HOVER_SEC: float = 0.12

func _ready() -> void:
	get_tree().root.theme = ThemeProvider.build_theme()
	get_tree().node_added.connect(_on_node_added)

## Every button swells a little under the mouse or the focus. It is hooked here, once, instead of in every scene.
func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null or button.has_meta(&"hover_wired"):
		return
	button.set_meta(&"hover_wired", true)
	button.mouse_entered.connect(_hover.bind(button, true))
	button.mouse_exited.connect(_hover.bind(button, false))
	button.focus_entered.connect(_hover.bind(button, true))
	button.focus_exited.connect(_hover.bind(button, false))

## Growing needs a mouse, a button that works and Reduce UI Motion off; settling back always plays.
func _hover(button: BaseButton, on: bool) -> void:
	if on and (button.disabled or InputService.is_touch_device() or bool(SettingsManager.get_setting("reduce_ui_motion", false))):
		return
	var old: Tween = button.get_meta(&"hover_tween") if button.has_meta(&"hover_tween") else null
	if old != null and old.is_valid():
		old.kill()
	button.pivot_offset = button.size / 2.0
	var tween := button.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", HOVER_SCALE if on else Vector2.ONE, HOVER_SEC)
	button.set_meta(&"hover_tween", tween)
