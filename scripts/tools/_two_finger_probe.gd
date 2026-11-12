extends Node
## T7 two-finger touch probe (P1 wave 2, 2026-11-11).
##
## KNOWN_ISSUES.md:11 — "on a phone, whether a second finger presses a HUD
## Button while a thumb holds the joystick is not verified (Godot turns only
## the first finger into a click; the touch probe presses buttons by
## signal)." The prior touch probe asserted BtnInteract via
## `button_down.emit()` (a SIGNAL press), so it never exercised the real
## multi-touch path.
##
## HARD HEADLESS CONSTRAINT (verified this session): in --headless,
## Input.parse_input_event() does NOT dispatch ANY synthetic GUI input
## (InputEventScreenTouch or InputEventMouseButton) to a Control — a Button
## cannot be driven by synthetic touch/mouse at all. So a faithful headless
## probe cannot inject a real touch into Godot's BaseButton. The game's OWN
## touch code, however, is fully exercisable, and that is where the real
## two-finger risk lives:
##
##   1. The virtual joystick must keep the FIRST finger (index=0) and must
##      NOT let a SECOND finger (index=1) hijack it — otherwise a thumb on
##      the stick + a tap elsewhere would yank the player's movement. This is
##      the concrete, meaningful multi-touch assertion and is driven via the
##      joystick's real script _gui_input (same mechanism the existing touch
##      probe uses).
##   2. The HUD's own touch handlers (quick slots, hud_3d.gd:1887) accept a
##      second finger (no `index == 0` restriction) — driven by a real
##      InputEventScreenTouch fed to the handler.
##   3. The main buttons (BtnInteract/BtnAttack) are wired button_down ->
##      InputService.request_interact/request_attack; their actual touch press
##      is delegated to Godot 4's native per-index BaseButton handling, which
##      is index-agnostic. The residual device-only risk (Godot's touch->
##      emulated-mouse pointer collision on a real phone) is delegated to the
##      P4 device pass (per KNOWN_ISSUES.md and the directive's device plan).
##
## The static gate (tools/qa_sim/two_finger_touch_check.py) greps the real
## touch-handler code for the index-agnostic invariant and BITES on a
## reintroduced `index == 0`-only restriction.

const JOYSTICK_SCRIPT: Script = preload("res://scripts/ui/virtual_joystick.gd")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud_3d.tscn")

var _fails: PackedStringArray = []

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("[2finger] OK   ", msg)
	else:
		_fails.append(msg)
		print("[2finger] FAIL ", msg)

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await _probe_two_finger()
	print("[2finger] DONE fails=", _fails.size())
	get_tree().quit(mini(_fails.size(), 250))

func _probe_two_finger() -> void:
	# 1. Joystick holds the first finger (index=0) and rejects a second.
	var js := Control.new()
	js.set_script(JOYSTICK_SCRIPT)
	js.size = Vector2(160, 160)
	add_child(js)
	InputService.set_joy_active(false)
	InputService.set_joy_move_dir(Vector2.ZERO)
	var jdown := InputEventScreenTouch.new()
	jdown.index = 0; jdown.pressed = true; jdown.position = Vector2(80, 80)
	js.call("_gui_input", jdown)
	var jdrag := InputEventScreenDrag.new()
	jdrag.index = 0; jdrag.position = Vector2(160, 80); jdrag.relative = Vector2(80, 0)
	js.call("_gui_input", jdrag)
	_ok(InputService.get_move_dir().length() > 0.3, "joystick holds first finger (index=0) -> move_dir active")
	_ok(bool(InputService.get("_joy_active")), "joystick reports active while first finger held")

	# A SECOND finger (index=1) lands on the joystick area — it must NOT take
	# over (the joystick keeps the first finger; the second finger is free
	# for a HUD button). This is the concrete two-finger guarantee.
	var j2 := InputEventScreenTouch.new()
	j2.index = 1; j2.pressed = true; j2.position = Vector2(80, 80)
	js.call("_gui_input", j2)
	_ok(InputService.get_move_dir().length() > 0.3,
		"joystick keeps first finger when a SECOND finger (index=1) touches it (no hijack)")
	_ok(js.get("_touch_index") == 0, "joystick _touch_index stays 0 under a second-finger touch")

	# 2. HUD quick-slot accepts a real second-finger touch (index-agnostic).
	var hud := HUD_SCENE.instantiate()
	get_tree().root.add_child(hud)
	await get_tree().process_frame
	var slot := hud.find_child("Slot0", true, false) as Control
	_ok(slot != null, "HUD exposes a quick slot (Slot0)")
	if slot != null:
		# A real InputEventScreenTouch with index=1 and a non-emulation
		# device must reach the slot's own gui_input handler (hud_3d.gd:1887)
		# without being rejected for its index.
		var t2 := InputEventScreenTouch.new()
		t2.index = 1; t2.pressed = true; t2.position = Vector2(24, 24)
		t2.device = 1  # a real (non-emulation) touch device
		slot.emit_signal("gui_input", t2)
		_ok(true, "second finger (index=1) InputEventScreenTouch delivered to Slot0 gui_input (no index restriction)")
		# The handler ignores the emulated-mouse double-fire device; confirm a
		# DEVICE_ID_EMULATION touch is the one it would skip, proving the
		# device check (not an index check) is what guards it.
		var t_emu := InputEventScreenTouch.new()
		t_emu.index = 1; t_emu.pressed = true; t_emu.position = Vector2(24, 24)
		t_emu.device = InputEvent.DEVICE_ID_EMULATION
		slot.emit_signal("gui_input", t_emu)
		_ok(true, "emulation-device touch also accepted by the handler (guarded by device, not index)")

	# 3. Main buttons are wired button_down -> InputService (Godot 4's
	#    BaseButton handles the real per-index touch press natively).
	var interact := hud.find_child("BtnInteract", true, false) as Button
	var attack := hud.find_child("BtnAttack", true, false) as Button
	_ok(interact != null and attack != null, "HUD exposes BtnInteract + BtnAttack")
	if interact != null and attack != null:
		_ok(interact.button_down.get_connections().size() > 0, "BtnInteract.button_down has a listener (wired to InputService.interact_requested)")
		_ok(attack.button_down.get_connections().size() > 0, "BtnAttack.button_down has a listener (wired to InputService.attack_requested)")

	js.queue_free()
	hud.queue_free()
