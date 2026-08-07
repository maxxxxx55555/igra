# fix2.ps1 -- rewrite remaining broken UI scripts (paste-safe)
param([string]$GodotExe = '')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Backup([string]$rel, [string]$c) {
    $f = Join-Path $root $rel
    if (Test-Path $f) { Copy-Item $f "$f.bak" -Force }
    [System.IO.File]::WriteAllText($f, $c, $utf8)
    Write-Host "WROTE $rel"
}
function GD([string[]]$l) { return (($l -join "`n") + "`n").Replace('\t', "`t") }

# ---- splash.gd ----
Write-Backup 'scripts/splash.gd' (GD @(
'extends Control',
'',
'@onready var logo: ColorRect = $Logo',
'@onready var label: Label = $Title',
'',
'func _ready() -> void:',
'\tadd_to_group("ui_root")',
'\tlogo.color = Color("#1D1812")',
'\tlabel.text = "THE LAST STREETLIGHT"',
'\tlabel.add_theme_color_override("font_color", Color("#E2A33C"))',
'\tvar tw = create_tween()',
'\ttw.tween_property(self, "modulate:a", 1.0, 1.0)',
'\ttw.tween_interval(2.0)',
'\ttw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/ui/boot_loading.tscn"))'
))

# ---- settings_menu.gd ----
Write-Backup 'scripts/settings_menu.gd' (GD @(
'extends Control',
'',
'func _ready() -> void:',
'\tadd_to_group("ui_root")',
'\t$VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))'
))

# ---- victory.gd ----
Write-Backup 'scripts/victory.gd' (GD @(
'extends Control',
'',
'func _ready() -> void:',
'\tadd_to_group("ui_root")',
'\t$VBox/Menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))'
))

# ---- COMPILE ----
Write-Host '---- COMPILE ----'
$g = $null
if ($GodotExe -and (Test-Path $GodotExe)) { $g = (Resolve-Path $GodotExe).Path }
if (-not $g) {
    $d = $root
    for ($i = 0; $i -lt 6; $i++) {
        foreach ($sub in @('', 'Godot', 'godot_extracted')) {
            $sd = if ($sub) { Join-Path $d $sub } else { $d }
            if (-not (Test-Path $sd)) { continue }
            $h = Get-ChildItem -Path $sd -Filter 'Godot_*_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($h) { $g = $h.FullName; break }
        }
        if ($g) { break }
        $p = Split-Path $d -Parent
        if (-not $p -or $p -eq $d) { break }
        $d = $p
    }
}
if (-not $g) { Write-Host 'WARN: Godot not found'; exit 1 }

$scene = 'res://scenes/tools/compile_scene.tscn'
if (-not (Test-Path (Join-Path $root 'scenes\tools\compile_scene.tscn'))) { $scene = '--quit' }
$log = Join-Path $root 'compile.log'
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
if ($scene -eq '--quit') { & $g --headless --path $root --quit *> $log }
else { & $g --headless --path $root $scene *> $log }
$exit = $LASTEXITCODE
$ErrorActionPreference = $prev

$bad = Select-String -Path $log -Pattern 'SCRIPT ERROR|Parse Error|Failed to load|\[compile-all\] BAD' -ErrorAction SilentlyContinue
if ($exit -eq 0 -and -not $bad) {
    Write-Host 'COMPILE OK'
} else {
    Write-Host 'COMPILE FAIL:'
    $bad | Select-Object -First 20 | ForEach-Object { Write-Host ('  ' + $_.Line) }
    exit 1
}