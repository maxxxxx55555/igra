# fix_parse_errors.ps1
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

# ---- confirm_quit.gd ----
$cq = "extends Control`n`nfunc _ready() -> void:`n`tadd_to_group(`"ui_root`")`n`t`$VBox/Yes.pressed.connect(func(): get_tree().quit())`n`t`$VBox/No.pressed.connect(func(): get_tree().change_scene_to_file(`"res://scenes/ui/main_menu.tscn`"))`n"
Write-Backup 'scripts/confirm_quit.gd' $cq

# ---- credits.gd ----
$cr = "extends Control`n`nfunc _ready() -> void:`n`tadd_to_group(`"ui_root`")`n`t`$VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file(`"res://scenes/ui/main_menu.tscn`"))`n"
Write-Backup 'scripts/credits.gd' $cr

# ---- death_screen.gd ----
$ds = "extends Control`n`nfunc _ready() -> void:`n`tadd_to_group(`"ui_root`")`n`t`$VBox/Retry.pressed.connect(func(): get_tree().reload_current_scene())`n`t`$VBox/Menu.pressed.connect(func(): get_tree().change_scene_to_file(`"res://scenes/ui/main_menu.tscn`"))`n"
Write-Backup 'scripts/death_screen.gd' $ds

# ---- pause_menu.gd ----
$pm = "extends Control`n`nfunc _ready() -> void:`n`tadd_to_group(`"ui_root`")`n`tget_tree().paused = true`n`tprocess_mode = Node.PROCESS_MODE_ALWAYS`n`t`$VBox/Resume.pressed.connect(func(): get_tree().paused = false; hide())`n`t`$VBox/Settings.pressed.connect(func(): get_tree().change_scene_to_file(`"res://scenes/ui/settings.tscn`"))`n`t`$VBox/Menu.pressed.connect(func(): get_tree().paused = false; get_tree().change_scene_to_file(`"res://scenes/ui/main_menu.tscn`"))`n`t`$VBox/Quit.pressed.connect(func(): get_tree().quit())`n"
Write-Backup 'scripts/pause_menu.gd' $pm

# ---- COMPILE ----
Write-Host "`n---- COMPILE ----"
$g = if ($GodotExe -and (Test-Path $GodotExe)) { (Resolve-Path $GodotExe).Path } else { $null }
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

$bad = Select-String -Path $log -Pattern 'SCRIPT ERROR|Parse Error|Failed to load' -ErrorAction SilentlyContinue
if ($exit -eq 0 -and -not $bad) {
    Write-Host 'COMPILE OK'
} else {
    Write-Host 'COMPILE FAIL:'
    $bad | Select-Object -First 15 | ForEach-Object { Write-Host ('  ' + $_.Line) }
    exit 1
}