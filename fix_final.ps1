$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8([string]$rel, [string]$content) {
	$full = Join-Path $root $rel
	$dir = Split-Path -Parent $full
	if (-not (Test-Path $dir)) { [void](New-Item -ItemType Directory -Force -Path $dir) }
	[System.IO.File]::WriteAllText($full, $content, $utf8)
	Write-Host ('WROTE    ' + $rel)
}

Write-Utf8 'scripts/_bootstrap.gd' @'
extends Node

func _ready() -> void:
	print("[Bootstrap] THE_LAST_STREETLIGHT ready")

func boot_info() -> Dictionary:
	return {"ts": Time.get_datetime_string_from_system(), "v": "1.0-final"}
'@

Write-Utf8 'scripts/i18n/i18n.gd' @'
extends Node

const LOCALES: PackedStringArray = ["en","ru","es","fr","de","it","pt","ja","ko","zh","ar","tr","pl"]

var _current: StringName = &""

func _ready() -> void:
	_load_all()
	_apply()

func _unquote(s: String) -> String:
	var t := s.strip_edges()
	if t.length() >= 2 and t.begins_with('"') and t.ends_with('"'):
		t = t.substr(1, t.length() - 2)
	return t.replace("\\n", "\n")

func _godot_loc(code: String) -> String:
	if code == "zh":
		return "zh_CN"
	if code == "pt":
		return "pt_BR"
	if code == "en":
		return "en_US"
	return code

func _load_all() -> void:
	for loc in LOCALES:
		var path := "res://locale/%s.po" % loc
		if not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var tr_res := Translation.new()
		tr_res.locale = _godot_loc(loc)
		var msgid := ""
		while not f.eof_reached():
			var line: String = f.get_line().strip_edges()
			if line.begins_with("msgid "):
				msgid = _unquote(line.substr(6))
			elif line.begins_with("msgstr "):
				tr_res.add_message(msgid, _unquote(line.substr(7)))
		f.close()
		TranslationServer.add_translation(tr_res)

func _apply() -> void:
	var lang := OS.get_locale().substr(0, 2).to_lower()
	if LOCALES.has(lang):
		_current = StringName(lang)
	else:
		_current = &"en"
	TranslationServer.set_locale(_godot_loc(String(_current)))

func set_locale(loc: StringName) -> void:
	_current = loc
	TranslationServer.set_locale(_godot_loc(String(loc)))

func current() -> StringName:
	return _current

func t(key: StringName) -> String:
	return tr(String(key))
'@

Write-Utf8 'scripts/ui/hud_banner.gd' @'
extends Control

var district_name: String = "—"
var powered: int = 0
var total: int = 11

func _ready() -> void:
	custom_minimum_size = Vector2(280, 64)
	queue_redraw()

func set_district(n: String, loc: String = "") -> void:
	if loc != "":
		district_name = loc
	else:
		district_name = n
	queue_redraw()

func set_progress(p: int, t: int) -> void:
	powered = p
	total = t
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(280, 64))
	draw_rect(r, Color(0.04, 0.05, 0.08, 0.78), true)
	draw_rect(r, Color(1.0, 0.7, 0.28, 0.95), false, 2.0)
	var f := ThemeDB.fallback_font
	if f == null:
		return
	draw_string(f, Vector2(12, 24), district_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.85, 0.5))
	draw_rect(Rect2(12, 38, 256, 14), Color(0.1, 0.1, 0.15), true)
	var pct := clamp(float(powered) / max(1, total), 0.0, 1.0)
	draw_rect(Rect2(14, 40, 252.0 * pct, 10), Color(1.0, 0.85, 0.4), true)
	draw_string(f, Vector2(220, 24), "%d/%d" % [powered, total], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
'@

Write-Utf8 'scripts/ui/city_map.gd' @'
extends Control

const CANON := ["suburbs","residential","park","school","hospital","gas_station","police","warehouses","industrial","substation","power_station"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.07, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var t := Label.new()
	t.text = "CITY POWER MAP"
	t.position = Vector2(20, 10)
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	add_child(t)
	var b := Button.new()
	b.text = "Close (K)"
	b.position = Vector2(20, 520)
	b.pressed.connect(_close)
	add_child(b)

func _close() -> void:
	visible = false

func _draw() -> void:
	var pg := get_node_or_null("/root/PowerGrid")
	var i := 0
	for id in CANON:
		var col := i % 4
		var row := i / 4
		var pos := Vector2(140.0 + float(col) * 180.0, 120.0 + float(row) * 130.0)
		var on := false
		if pg != null and pg.has_method("is_powered"):
			on = pg.is_powered(StringName(id))
		var c := Color(0.3, 1.0, 0.5) if on else Color(0.35, 0.35, 0.4)
		draw_circle(pos, 14.0, c)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-50, 32), id, HORIZONTAL_ALIGNMENT_LEFT, 140, 12, Color.WHITE)
		i += 1
'@

Write-Utf8 'scripts/ui/district_banner.gd' @'
extends Control

var _label: Label
var _t: float = 0.0
var _show: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	position = Vector2(-220, 110)
	size = Vector2(440, 48)
	_label = Label.new()
	_label.position = Vector2(14, 10)
	_label.size = Vector2(420, 36)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	add_child(_label)
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("district_entered"):
		bus.district_entered.connect(_on_district)
	visible = false

func _on_district(id: StringName) -> void:
	if _label != null:
		_label.text = String(id).to_upper()
	_t = 0.0
	_show = true
	visible = true

func _process(delta: float) -> void:
	if not _show:
		return
	_t += delta
	if _t > 3.5:
		_show = false
		visible = false
'@

Write-Utf8 'scripts/ui/hud.gd' @'
extends Control

func _ready() -> void:
	visible = false
'@

Write-Utf8 'scripts/world/puzzle_base.gd' @'
extends Area2D

@export var puzzle_id: StringName
@export var district_id: StringName
@export var action_name: String = "Activate"

var solved: bool = false

func _ready() -> void:
	add_to_group("interactable")
	monitorable = true

func interact(_player: Node) -> void:
	if solved:
		return
	var pg := get_node_or_null("/root/PowerGrid")
	if pg != null and pg.has_method("is_powered") and not pg.is_powered(district_id):
		pg.toggle_district(district_id)
	solved = true
	modulate = Color(0.5, 0.5, 0.5, 0.6)
'@

Write-Utf8 'scripts/ui/map_controller.gd' @'
extends Node

var _open := false
var _map: Control = null

func _ready() -> void:
	call_deferred("_find_or_create")

func _find_or_create() -> void:
	_map = _search(get_tree().root) as Control
	if _map == null:
		var s := load("res://scripts/ui/city_map.gd")
		if s != null:
			_map = s.new()
			_map.name = "CityMap"
			get_tree().root.add_child(_map)
	if _map != null:
		_map.visible = false

func _search(n: Node) -> Node:
	if String(n.name) == "CityMap":
		return n
	for c in n.get_children():
		var r := _search(c)
		if r != null:
			return r
	return null

func _process(_d: float) -> void:
	if _map != null and not _open:
		_map.visible = false

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("city_map_toggle"):
		_open = not _open
		if _map != null:
			_map.visible = _open
			if _open:
				_map.queue_redraw()
'@

$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
& $godot --headless --path . res://scenes/tools/compile_scene.tscn 2>&1 | Select-String "BAD|FAILED" | Select-Object -Last 3

git -C $root add -A
git -C $root commit -m "fix: rewrite 8 files to new API"
git -C $root push
Write-Host "FIX FINAL DONE" -ForegroundColor Green