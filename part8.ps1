$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText((Join-Path $root 'scripts\tools\shot_tool.gd'), (@'
extends Node

func _ready() -> void:
	if "--shot" in OS.get_cmdline_args():
		_run()

func _run() -> void:
	await get_tree().create_timer(4.0).timeout
	var img := get_tree().root.get_texture().get_image()
	img.save_png("C:/Users/Maxsim/Desktop/shot1.png")
	get_tree().quit()
'@), $utf8)

$gf = Join-Path $root 'project.godot'
$text = [System.IO.File]::ReadAllText($gf, $utf8)
if ($text -notmatch '(?m)^ShotTool=') {
	$text = [regex]::Replace($text, '(\[autoload\]\s*\r?\n)', ('$1' + 'ShotTool="*res://scripts/tools/shot_tool.gd"' + "`n"), 1)
	[System.IO.File]::WriteAllText($gf, $text, $utf8)
}
Write-Host "SHOTTOOL READY"

git -C $root add -A
git -C $root commit -m "part8: shot tool"
git -C $root push

$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
& $godot --path $root res://scenes/main_3d.tscn --shot 2>&1 | Select-Object -Last 3
Test-Path "C:\Users\Maxsim\Desktop\shot1.png"