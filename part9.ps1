$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$f = Join-Path $root 'scripts\world\street_builder.gd'
$c = [System.IO.File]::ReadAllText($f, $utf8)
$c = $c.Replace('@onready var _road_mm: MultiMeshInstance3D = $RoadMM', 'var _road_mm: MultiMeshInstance3D')
$c = $c.Replace('@onready var _sidewalk_mm: MultiMeshInstance3D = $SidewalkMM', 'var _sidewalk_mm: MultiMeshInstance3D')
$c = $c.Replace('@onready var _marking_mm: MultiMeshInstance3D = $MarkingMM', 'var _marking_mm: MultiMeshInstance3D')
$c = $c.Replace("func _ready() -> void:", "func _ready() -> void:`r`n	_ensure_mm()")
$c += "`r`nfunc _ensure_mm() -> void:`r`n	if _road_mm == null:`r`n		_road_mm = MultiMeshInstance3D.new()`r`n		_road_mm.name = `"RoadMM`"`r`n		add_child(_road_mm)`r`n	if _sidewalk_mm == null:`r`n		_sidewalk_mm = MultiMeshInstance3D.new()`r`n		_sidewalk_mm.name = `"SidewalkMM`"`r`n		add_child(_sidewalk_mm)`r`n	if _marking_mm == null:`r`n		_marking_mm = MultiMeshInstance3D.new()`r`n		_marking_mm.name = `"MarkingMM`"`r`n		add_child(_marking_mm)`r`n"
[System.IO.File]::WriteAllText($f, $c, $utf8)
Write-Host "STREET_BUILDER PATCHED"

git -C $root add -A
git -C $root commit -m "part9: streetbuilder self-creates MM nodes"
git -C $root push

$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
& $godot --path $root res://scenes/main_3d.tscn --shot 2>&1 | Select-Object -Last 3
Test-Path "C:\Users\Maxsim\Desktop\shot1.png"