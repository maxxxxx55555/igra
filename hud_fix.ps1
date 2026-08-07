$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText((Join-Path $root 'scripts\ui\hud_banner.gd'), (@'
extends Control

var district_name: String = "-"
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
	draw_rect(Rect2(0, 0, 280, 64), Color(0.04, 0.05, 0.08, 0.78), true)
	draw_rect(Rect2(0, 0, 280, 64), Color(1.0, 0.7, 0.28, 0.95), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(12, 24), district_name, HORIZONTAL_ALIGNMENT_LEFT, 256, 18, Color(1.0, 0.85, 0.5))
	draw_rect(Rect2(12, 38, 256, 14), Color(0.1, 0.1, 0.15), true)
	var w: float = 252.0 * clamp(float(powered) / float(max(1, total)), 0.0, 1.0)
	draw_rect(Rect2(14, 40, w, 10), Color(1.0, 0.85, 0.4), true)
	draw_string(ThemeDB.fallback_font, Vector2(220, 24), str(powered) + "/" + str(total), HORIZONTAL_ALIGNMENT_LEFT, 60, 14, Color.WHITE)
'@), $utf8)
Write-Host "WROTE hud_banner.gd"

$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
& $godot --headless --path . res://scenes/tools/compile_scene.tscn 2>$null | Select-String "BAD|FAILED" | Select-Object -Last 3

git -C $root add -A
git -C $root commit -m "fix: hud_banner final"
git -C $root push
Write-Host "ALL DONE" -ForegroundColor Green