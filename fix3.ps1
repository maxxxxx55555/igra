# fix3.ps1 -- wire amber theme: autoload + valid theme_setup.gd
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

# ---- 1. autoload ThemeSetup in project.godot ----
$pgPath = Join-Path $root 'project.godot'
$txt = [System.IO.File]::ReadAllText($pgPath, $utf8)
if ($txt -notmatch 'ThemeSetup\s*=') {
    $txt = $txt -replace '\[autoload\]', "[autoload]`nThemeSetup=`"*res://scripts/theme_setup.gd`""
    [System.IO.File]::WriteAllText($pgPath, $txt, $utf8)
    Write-Host 'AUTOLOAD ThemeSetup added'
} else { Write-Host 'AUTOLOAD already present' }

# ---- 2. valid theme_setup.gd ----
Write-Backup 'scripts/theme_setup.gd' (GD @(
'extends Node',
'',
'const C_BG = Color("#12100C")',
'const C_PANEL = Color("#1D1812")',
'const C_AMBER = Color("#E2A33C")',
'const C_BONE = Color("#CFC9B8")',
'const C_RED = Color("#A63A32")',
'',
'var theme_res: Theme = null',
'',
'func _ready() -> void:',
'\t_build_theme()',
'\tget_tree().node_added.connect(_on_node)',
'',
'func _on_node(n: Node) -> void:',
'\tif theme_res != null and n is Control:',
'\t\tn.theme = theme_res',
'',
'func _build_theme() -> void:',
'\tvar t := Theme.new()',
'\tvar head: Font = null',
'\tvar body: Font = null',
'\tif ResourceLoader.exists("res://assets/fonts/bebas_neue_bold.ttf"):',
'\t\thead = load("res://assets/fonts/bebas_neue_bold.ttf")',
'\tif ResourceLoader.exists("res://assets/fonts/roboto_condensed.ttf"):',
'\t\tbody = load("res://assets/fonts/roboto_condensed.ttf")',
'\tif body == null:',
'\t\tbody = ThemeDB.fallback_font',
'\tif head == null:',
'\t\thead = body',
'\tt.default_font = body',
'\tt.default_font_size = 18',
'\tt.set_font("font", "Label", body)',
'\tt.set_font_size("font_size", "Label", 18)',
'\tt.set_color("font_color", "Label", C_BONE)',
'\tt.set_font("font", "Button", head)',
'\tt.set_font_size("font_size", "Button", 22)',
'\tt.set_color("font_color", "Button", C_BONE)',
'\tt.set_color("font_hover_color", "Button", C_AMBER)',
'\tt.set_color("font_pressed_color", "Button", C_RED)',
'\tvar bn = StyleBoxFlat.new()',
'\tbn.bg_color = C_PANEL',
'\tbn.border_color = C_AMBER',
'\tbn.set_border_width_all(2)',
'\tbn.set_content_margin_all(12)',
'\tt.set_stylebox("normal", "Button", bn)',
'\tvar bh = bn.duplicate()',
'\tbh.bg_color = C_PANEL.lightened(0.08)',
'\tt.set_stylebox("hover", "Button", bh)',
'\tvar bp = bn.duplicate()',
'\tbp.bg_color = C_AMBER',
'\tt.set_stylebox("pressed", "Button", bp)',
'\tvar pn = StyleBoxFlat.new()',
'\tpn.bg_color = C_PANEL',
'\tpn.border_color = C_AMBER',
'\tpn.set_border_width_all(1)',
'\tpn.set_content_margin_all(16)',
'\tt.set_stylebox("panel", "Panel", pn)',
'\tt.set_stylebox("panel", "PanelContainer", pn)',
'\tvar pbb = StyleBoxFlat.new()',
'\tpbb.bg_color = C_BG',
'\tpbb.set_content_margin_all(4)',
'\tt.set_stylebox("background", "ProgressBar", pbb)',
'\tvar pbf = StyleBoxFlat.new()',
'\tpbf.bg_color = C_AMBER',
'\tt.set_stylebox("fill", "ProgressBar", pbf)',
'\ttheme_res = t',
'\tif OS.has_feature("editor"):',
'\t\tDirAccess.make_dir_recursive_absolute("res://assets/theme")',
'\t\tResourceSaver.save(t, "res://assets/theme/tls_theme.tres")',
'\tprint("THEME ready")'
))

# ---- 3. compile ----
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
if ($exit -eq 0 -and -not $bad) { Write-Host 'COMPILE OK' }
else {
    Write-Host 'COMPILE FAIL:'
    $bad | Select-Object -First 20 | ForEach-Object { Write-Host ('  ' + $_.Line) }
    exit 1
}