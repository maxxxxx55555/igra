extends RefCounted
## Key remapping (Settings > Controls > Key Bindings). A remapped action keeps its other events and gets its keyboard event on the new
## physical key; the choices are the setting "keybinds" ({action name: physical keycode}). The defaults are read from the InputMap the first
## time anything here runs, so a reset puts back exactly what project.godot says. Pause is not here: the UI closes on Escape.

## Remappable action -> the label key of its row.
const LABELS: Dictionary = {
	&"move_up": "KEY_MOVE_UP",
	&"move_down": "KEY_MOVE_DOWN",
	&"move_left": "KEY_MOVE_LEFT",
	&"move_right": "KEY_MOVE_RIGHT",
	&"run": "KEY_RUN",
	&"stealth": "KEY_STEALTH",
	&"jump": "KEY_JUMP",
	&"attack": "KEY_ATTACK",
	&"reload": "KEY_RELOAD",
	&"interact": "PROMPT_INTERACT",
	&"flashlight_toggle": "SCR_FONARIK",
	&"inventory_toggle": "KEY_INVENTORY",
	&"city_map_toggle": "MAP_TITLE",
	&"journal_toggle": "JOURNAL_TITLE",
}

static var _default_keys: Dictionary = {}

## The physical keycode of the action's first keyboard event; KEY_NONE when it has none.
static func key_of(action: StringName) -> int:
	if not InputMap.has_action(action):
		return KEY_NONE
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key := event as InputEventKey
			return int(key.physical_keycode) if key.physical_keycode != KEY_NONE else int(key.keycode)
	return KEY_NONE

## What the key is called on this keyboard layout.
static func key_text(code: int) -> String:
	return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(code as Key))

## Puts the saved choices on the InputMap; an action that is not saved goes back to its default.
static func apply(saved: Dictionary) -> void:
	_capture()
	for action: StringName in LABELS:
		_set_key(action, int(saved.get(String(action), _default_keys[action])))

## Binds the action to the key; a key another action holds goes to this action's old key (a swap). Returns the choices to save.
static func bind(action: StringName, code: int) -> Dictionary:
	_capture()
	var old: int = key_of(action)
	for other: StringName in LABELS:
		if other != action and key_of(other) == code:
			_set_key(other, old)
	_set_key(action, code)
	return overrides()

static func reset() -> void:
	_capture()
	for action: StringName in LABELS:
		_set_key(action, int(_default_keys[action]))

## Only the actions whose key differs from the default.
static func overrides() -> Dictionary:
	_capture()
	var out: Dictionary = {}
	for action: StringName in LABELS:
		if key_of(action) != int(_default_keys[action]):
			out[String(action)] = key_of(action)
	return out

static func _capture() -> void:
	if not _default_keys.is_empty():
		return
	for action: StringName in LABELS:
		_default_keys[action] = key_of(action)

static func _set_key(action: StringName, code: int) -> void:
	if code == KEY_NONE or not InputMap.has_action(action) or key_of(action) == code:
		return
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
			break
	var key := InputEventKey.new()
	key.physical_keycode = code as Key
	InputMap.action_add_event(action, key)
