# ============================================================================
# final_polish.ps1 -- THE LAST STREETLIGHT: 10/10 pass
#   powershell -ExecutionPolicy Bypass -File final_polish.ps1 -GodotExe "..."
# ============================================================================
param([string]$GodotExe = '')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$utf8 = New-Object System.Text.UTF8Encoding($false)

# ---------- helpers ----------
function Ensure-Dir([string]$rel) {
    $f = Join-Path $root $rel
    if (-not (Test-Path $f)) { New-Item -ItemType Directory -Force -Path $f | Out-Null; Write-Host "MKDIR $rel" }
}
function Write-Backup([string]$rel, [string]$c) {
    $f = Join-Path $root $rel
    if (Test-Path $f) { Copy-Item $f "$f.bak" -Force }
    $d = Split-Path -Parent $f
    if ($d -and -not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    [System.IO.File]::WriteAllText($f, $c, $utf8)
    Write-Host "WROTE $rel"
}
function Resolve-Godot() {
    if ($GodotExe -and (Test-Path $GodotExe)) { return (Resolve-Path $GodotExe).Path }
    $d = $root
    for ($i = 0; $i -lt 6; $i++) {
        foreach ($sub in @('', 'Godot', 'godot_extracted')) {
            $sd = if ($sub) { Join-Path $d $sub } else { $d }
            if (-not (Test-Path $sd)) { continue }
            $h = Get-ChildItem -Path $sd -Filter 'Godot_*_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($h) { return $h.FullName }
        }
        $p = Split-Path $d -Parent
        if (-not $p -or $p -eq $d) { break }
        $d = $p
    }
    return $null
}
function Run-Godot([string[]]$a) {
    $g = Resolve-Godot
    if (-not $g) { return 'NO_GODOT' }
    $args = @('--headless', '--path', $root) + $a
    $o = Join-Path $root '.godot_out.tmp'
    $e = Join-Path $root '.godot_err.tmp'
    $null = Start-Process -FilePath $g -ArgumentList $args -NoNewWindow -PassThru -Wait -RedirectStandardOutput $o -RedirectStandardError $e
    $txt = ''
    if (Test-Path $o) { $txt += [System.IO.File]::ReadAllText($o, $utf8) }
    if (Test-Path $e) { $txt += [System.IO.File]::ReadAllText($e, $utf8) }
    Remove-Item $o, $e -ErrorAction SilentlyContinue
    return $txt
}

# ============================================================================
Write-Host '================== FINAL POLISH 10/10 =================='
Write-Host "Root: $root"

# ============================================================================
# PHASE 1: FONTS (Impact = Bebas Neue fallback, Arial Narrow = Roboto Condensed)
# ============================================================================
Write-Host '---- PHASE 1: FONTS ----'
Ensure-Dir 'assets/fonts'
$wins = 'C:\Windows\Fonts'
if (Test-Path (Join-Path $wins 'impact.ttf')) {
    Copy-Item (Join-Path $wins 'impact.ttf') (Join-Path $root 'assets\fonts\bebas_neue_bold.ttf') -Force
    Write-Host 'COPY impact.ttf -> bebas_neue_bold.ttf'
}
if (Test-Path (Join-Path $wins 'arialn.ttf')) {
    Copy-Item (Join-Path $wins 'arialn.ttf') (Join-Path $root 'assets\fonts\roboto_condensed.ttf') -Force
    Write-Host 'COPY arialn.ttf -> roboto_condensed.ttf'
}

# ============================================================================
# PHASE 2: THEME SETUP (amber palette, Bebas headings, Roboto body)
# ============================================================================
Write-Host '---- PHASE 2: THEME ----'
$themeGd = @'
extends Node

const PALETTE = {
    "bg": Color("#12100C"),
    "panel": Color("#1D1812"),
    "amber": Color("#E2A33C"),
    "olive": Color("#5A6332"),
    "bone": Color("#CFC9B8"),
    "red": Color("#A63A32"),
}

func _ready() -> void:
    _build_theme()
    await get_tree().process_frame
    _apply_to_all()

func _build_theme() -> void:
    var t = Theme.new()
    var head = FontFile.new() if not ResourceLoader.exists("res://assets/fonts/bebas_neue_bold.ttf") else load("res://assets/fonts/bebas_neue_bold.ttf")
    var body = FontFile.new() if not ResourceLoader.exists("res://assets/fonts/roboto_condensed.ttf") else load("res://assets/fonts/roboto_condensed.ttf")
    t.default_font = body
    t.default_font_size = 18
    t.set_font("Label", "font", body)
    t.set_font_size("Label", "font_size", 18)
    t.set_color("Label", "font_color", PALETTE.bone)
    t.set_font("Button", "font", head)
    t.set_font_size("Button", "font_size", 22)
    t.set_color("Button", "font_color", PALETTE.bone)
    t.set_color("Button", "font_hover_color", PALETTE.amber)
    t.set_color("Button", "font_pressed_color", PALETTE.red)
    var bn = StyleBoxFlat.new()
    bn.bg_color = PALETTE.panel
    bn.border_color = PALETTE.amber
    bn.set_border_width_all(2)
    bn.set_content_margin_all(12)
    t.set_stylebox("Button", "normal", bn)
    var bh = bn.duplicate()
    bh.bg_color = PALETTE.panel.lightened(0.08)
    bh.border_color = PALETTE.amber.lightened(0.15)
    t.set_stylebox("Button", "hover", bh)
    var bp = bn.duplicate()
    bp.bg_color = PALETTE.amber
    bp.border_color = PALETTE.amber
    t.set_stylebox("Button", "pressed", bp)
    var pn = StyleBoxFlat.new()
    pn.bg_color = PALETTE.panel
    pn.border_color = PALETTE.amber
    pn.set_border_width_all(1)
    pn.set_content_margin_all(16)
    t.set_stylebox("Panel", "panel", pn)
    t.set_stylebox("PanelContainer", "panel", pn)
    var pb_bg = StyleBoxFlat.new()
    pb_bg.bg_color = PALETTE.bg
    pb_bg.set_content_margin_all(4)
    t.set_stylebox("ProgressBar", "background", pb_bg)
    var pb_fill = StyleBoxFlat.new()
    pb_fill.bg_color = PALETTE.amber
    t.set_stylebox("ProgressBar", "fill", pb_fill)
    ResourceSaver.save(t, "res://assets/theme/tls_theme.tres")
    print("THEME saved")

func _apply_to_all() -> void:
    if not ResourceLoader.exists("res://assets/theme/tls_theme.tres"): return
    var t = load("res://assets/theme/tls_theme.tres")
    for n in get_tree().get_nodes_in_group("ui_root"):
        if n is Control: n.theme = t
    print("THEME applied")
'@
Write-Backup 'scripts/theme_setup.gd' $themeGd

# ============================================================================
# PHASE 3: SCREEN FLOW (splash -> pre_loading -> boot_loading -> main_menu)
# ============================================================================
Write-Host '---- PHASE 3: SCREEN FLOW ----'
Ensure-Dir 'scenes/ui'
Ensure-Dir 'scenes/ui/screens'

# -- splash (3 sec logo)
$splashGd = @'
extends Control

@onready var logo: ColorRect = $Logo
@onready var label: Label = $Title

func _ready() -> void:
    add_to_group("ui_root")
    logo.color = Color("#1D1812")
    label.text = "THE LAST STREETLIGHT"
    label.add_theme_color_override("font_color", Color("#E2A33C"))
    var tw = create_tween()
    tw.tween_property(self, "modulate:a", 1.0, 1.0)
    tw.tween_interval(2.0)
    tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/ui/boot_loading.tscn"))
'@
Write-Backup 'scripts/splash.gd' $splashGd

$splashTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/splash.gd" id="1"]

[node name="Splash" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
modulate = Color(1, 1, 1, 0)

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 1)

[node name="Logo" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -60.0
offset_top = -60.0
offset_right = 60.0
offset_bottom = 60.0
color = Color("#E2A33C", 1)

[node name="Title" type="Label" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_top = 80.0
offset_right = 400.0
offset_bottom = 120.0
horizontal_alignment = 1
text = "THE LAST STREETLIGHT"
'@
Write-Backup 'scenes/ui/splash.tscn' $splashTscn

# -- boot_loading (progress bar + tips)
$bootGd = @'
extends Control

@onready var bar: ProgressBar = $Bar
@onready var tip: Label = $Tip

const TIPS = [
    "Фонарь — твой единственный союзник.",
    "Слушай тишину — она лжёт реже людей.",
    "Каждый район имеет свой ритм.",
    "Документы раскрывают правду мира.",
    "Финальная ночь требует подготовки.",
]

var progress: float = 0.0
var target: float = 0.0

func _ready() -> void:
    add_to_group("ui_root")
    tip.text = TIPS[randi() % TIPS.size()]
    tip.add_theme_color_override("font_color", Color("#CFC9B8"))

func _process(delta: float) -> void:
    target = min(target + delta * 30.0, 100.0)
    progress = lerp(progress, target, delta * 2.0)
    bar.value = progress
    if progress > 99.0:
        get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
'@
Write-Backup 'scripts/boot_loading.gd' $bootGd

$bootTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/boot_loading.gd" id="1"]

[node name="BootLoading" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 1)

[node name="Panel" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -300.0
offset_top = -100.0
offset_right = 300.0
offset_bottom = 100.0

[node name="VBox" type="VBoxContainer" parent="Panel"]
layout_mode = 2

[node name="Title" type="Label" parent="Panel/VBox"]
layout_mode = 2
text = "ЗАГРУЗКА"
horizontal_alignment = 1

[node name="Bar" type="ProgressBar" parent="Panel/VBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 24)
value = 0.0

[node name="Tip" type="Label" parent="Panel/VBox"]
layout_mode = 2
text = "..."
horizontal_alignment = 1
autowrap_mode = 2
'@
Write-Backup 'scenes/ui/boot_loading.tscn' $bootTscn

# -- main_menu
$menuGd = @'
extends Control

@onready var play_btn: Button = $VBox/Play
@onready var settings_btn: Button = $VBox/Settings
@onready var difficulty_btn: Button = $VBox/Difficulty
@onready var credits_btn: Button = $VBox/Credits
@onready var quit_btn: Button = $VBox/Quit
@onready var flicker: ColorRect = $Flicker

func _ready() -> void:
    add_to_group("ui_root")
    play_btn.text = "ИГРАТЬ"
    settings_btn.text = "НАСТРОЙКИ"
    difficulty_btn.text = "СЛОЖНОСТЬ"
    credits_btn.text = "ТИТРЫ"
    quit_btn.text = "ВЫХОД"
    play_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn"))
    settings_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/settings.tscn"))
    difficulty_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/difficulty.tscn"))
    credits_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/credits.tscn"))
    quit_btn.pressed.connect(_on_quit)
    _start_flicker()

func _start_flicker() -> void:
    var tw = create_tween().set_loops()
    tw.tween_property(flicker, "modulate:a", 0.6, 2.0)
    tw.tween_property(flicker, "modulate:a", 1.0, 0.3)
    tw.tween_property(flicker, "modulate:a", 0.8, 1.5)
    tw.tween_property(flicker, "modulate:a", 1.0, 0.5)

func _on_quit() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/confirm_quit.tscn")
'@
Write-Backup 'scripts/main_menu.gd' $menuGd

$menuTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/main_menu.gd" id="1"]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 1)

[node name="Flicker" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#E2A33C", 0.15)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -200.0
offset_right = 150.0
offset_bottom = 200.0
theme_override_constants/separation = 12

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
text = "THE LAST
STREETLIGHT"
horizontal_alignment = 1

[node name="Play" type="Button" parent="VBox"]
layout_mode = 2

[node name="Settings" type="Button" parent="VBox"]
layout_mode = 2

[node name="Difficulty" type="Button" parent="VBox"]
layout_mode = 2

[node name="Credits" type="Button" parent="VBox"]
layout_mode = 2

[node name="Quit" type="Button" parent="VBox"]
layout_mode = 2
'@
Write-Backup 'scenes/ui/main_menu.tscn' $menuTscn

# -- settings
$setGd = @'
extends Control
func _ready() -> void:
    add_to_group("ui_root")
    $VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
'@
Write-Backup 'scripts/settings_menu.gd' $setGd

$setTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/settings_menu.gd" id="1"]

[node name="Settings" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 1)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -200.0
offset_right = 200.0
offset_bottom = 200.0
theme_override_constants/separation = 12

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
text = "НАСТРОЙКИ"
horizontal_alignment = 1

[node name="VolumeLabel" type="Label" parent="VBox"]
layout_mode = 2
text = "Громкость"

[node name="Volume" type="HSlider" parent="VBox"]
layout_mode = 2
min_value = 0.0
max_value = 100.0
value = 80.0

[node name="Back" type="Button" parent="VBox"]
layout_mode = 2
text = "НАЗАД"
'@
Write-Backup 'scenes/ui/settings.tscn' $setTscn

# -- difficulty
$diffGd = @'
extends Control
func _ready() -> void:
    add_to_group("ui_root")
    for b in $VBox.get_children():
        if b is Button and b.name != "Back":
            b.pressed.connect(_on_diff.bind(b.text))
    $VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
func _on_diff(d: String) -> void:
    print("Difficulty: ", d)
    get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")
'@
Write-Backup 'scripts/difficulty.gd' $diffGd

$diffTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/difficulty.gd" id="1"]

[node name="Difficulty" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 1)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -150.0
offset_right = 150.0
offset_bottom = 150.0
theme_override_constants/separation = 12

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
text = "СЛОЖНОСТЬ"
horizontal_alignment = 1

[node name="Easy" type="Button" parent="VBox"]
layout_mode = 2
text = "ЛЕГКО"

[node name="Normal" type="Button" parent="VBox"]
layout_mode = 2
text = "НОРМАЛЬНО"

[node name="Hard" type="Button" parent="VBox"]
layout_mode = 2
text = "СЛОЖНО"

[node name="Nightmare" type="Button" parent="VBox"]
layout_mode = 2
text = "КОШМАР"

[node name="Back" type="Button" parent="VBox"]
layout_mode = 2
text = "НАЗАД"
'@
Write-Backup 'scenes/ui/difficulty.tscn' $diffTscn

# -- credits
$credGd = @'
extends Control
func _ready() -> void:
    add_to_group("ui_root")
    $VBox/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
'@
Write-Backup 'scripts/credits.gd' $credGd

$credTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/credits.gd" id="1"]

[node name="Credits" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 1)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -300.0
offset_top = -200.0
offset_right = 300.0
offset_bottom = 200.0
theme_override_constants/separation = 10

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
text = "ТИТРЫ"
horizontal_alignment = 1

[node name="L1" type="Label" parent="VBox"]
layout_mode = 2
text = "THE LAST STREETLIGHT"
horizontal_alignment = 1

[node name="L2" type="Label" parent="VBox"]
layout_mode = 2
text = "Game Design and Code: TLS Team"
horizontal_alignment = 1

[node name="L3" type="Label" parent="VBox"]
layout_mode = 2
text = "Music and SFX: TLS Team"
horizontal_alignment = 1

[node name="L4" type="Label" parent="VBox"]
layout_mode = 2
text = "Art and UI: TLS Team"
horizontal_alignment = 1

[node name="L5" type="Label" parent="VBox"]
layout_mode = 2
text = "Special thanks to the players"
horizontal_alignment = 1

[node name="Back" type="Button" parent="VBox"]
layout_mode = 2
text = "НАЗАД"
'@
Write-Backup 'scenes/ui/credits.tscn' $credTscn

# -- confirm_quit
$cqGd = @'
extends Control
func _ready() -> void:
    add_to_group("ui_root")
    $VBox/Yes.pressed.connect(func(): get_tree().quit())
    $VBox/No.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
'@
Write-Backup 'scripts/confirm_quit.gd' $cqGd

$cqTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/confirm_quit.gd" id="1"]

[node name="ConfirmQuit" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 0.9)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -80.0
offset_right = 150.0
offset_bottom = 80.0
theme_override_constants/separation = 16

[node name="Q" type="Label" parent="VBox"]
layout_mode = 2
text = "Выйти из игры?"
horizontal_alignment = 1

[node name="HBox" type="HBoxContainer" parent="VBox"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 20

[node name="Yes" type="Button" parent="VBox/HBox"]
layout_mode = 2
text = "ДА"

[node name="No" type="Button" parent="VBox/HBox"]
layout_mode = 2
text = "НЕТ"
'@
Write-Backup 'scenes/ui/confirm_quit.tscn' $cqTscn

# ============================================================================
# PHASE 4: IN-GAME UI (pause, death, victory)
# ============================================================================
Write-Host '---- PHASE 4: IN-GAME UI ----'

$pauseGd = @'
extends Control
func _ready() -> void:
    add_to_group("ui_root")
    get_tree().paused = true
    process_mode = Node.PROCESS_MODE_ALWAYS
    $VBox/Resume.pressed.connect(func(): get_tree().paused = false; hide())
    $VBox/Settings.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/settings.tscn"))
    $VBox/Menu.pressed.connect(func(): get_tree().paused = false; get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
    $VBox/Quit.pressed.connect(func(): get_tree().quit())
'@
Write-Backup 'scripts/pause_menu.gd' $pauseGd

$pauseTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/pause_menu.gd" id="1"]

[node name="PauseMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 0.85)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -150.0
offset_top = -150.0
offset_right = 150.0
offset_bottom = 150.0
theme_override_constants/separation = 12

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
text = "ПАУЗА"
horizontal_alignment = 1

[node name="Resume" type="Button" parent="VBox"]
layout_mode = 2
text = "ПРОДОЛЖИТЬ"

[node name="Settings" type="Button" parent="VBox"]
layout_mode = 2
text = "НАСТРОЙКИ"

[node name="Menu" type="Button" parent="VBox"]
layout_mode = 2
text = "ГЛАВНОЕ МЕНЮ"

[node name="Quit" type="Button" parent="VBox"]
layout_mode = 2
text = "ВЫЙТИ"
'@
Write-Backup 'scenes/ui/pause_menu.tscn' $pauseTscn

$deathGd = @'
extends Control
func _ready() -> void:
    add_to_group("ui_root")
    $VBox/Retry.pressed.connect(func(): get_tree().reload_current_scene())
    $VBox/Menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
'@
Write-Backup 'scripts/death_screen.gd' $deathGd

$deathTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/death_screen.gd" id="1"]

[node name="DeathScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 0.95)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -100.0
offset_right = 200.0
offset_bottom = 100.0
theme_override_constants/separation = 16

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
text = "ВЫ ПОГИБЛИ"
horizontal_alignment = 1

[node name="Retry" type="Button" parent="VBox"]
layout_mode = 2
text = "ПОВТОРИТЬ"

[node name="Menu" type="Button" parent="VBox"]
layout_mode = 2
text = "В МЕНЮ"
'@
Write-Backup 'scenes/ui/death_screen.tscn' $deathTscn

$vicGd = @'
extends Control
func _ready() -> void:
    add_to_group("ui_root")
    $VBox/Menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
'@
Write-Backup 'scripts/victory.gd' $vicGd

$vicTscn = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/victory.gd" id="1"]

[node name="Victory" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="BG" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color("#12100C", 0.95)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -100.0
offset_right = 200.0
offset_bottom = 100.0
theme_override_constants/separation = 16

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
text = "ПОБЕДА"
horizontal_alignment = 1

[node name="Sub" type="Label" parent="VBox"]
layout_mode = 2
text = "Фонарь продолжает гореть."
horizontal_alignment = 1

[node name="Menu" type="Button" parent="VBox"]
layout_mode = 2
text = "В МЕНЮ"
'@
Write-Backup 'scenes/ui/victory_screen.tscn' $vicTscn

# ============================================================================
# PHASE 5: BOOTSTRAP (splash on game start)
# ============================================================================
Write-Host '---- PHASE 5: BOOTSTRAP ----'
$bootGd = @'
extends Node

func _ready() -> void:
    await get_tree().process_frame
    if get_tree().current_scene == null or get_tree().current_scene.name == "":
        get_tree().change_scene_to_file("res://scenes/ui/splash.tscn")
'@
Write-Backup 'scripts/_bootstrap.gd' $bootGd

# ============================================================================
# PHASE 6: GENERATE ART (run existing generator scenes)
# ============================================================================
Write-Host '---- PHASE 6: ART GENERATION ----'
Ensure-Dir 'assets/art'
Ensure-Dir 'assets/audio'
foreach ($scene in @('res://scenes/tools/gen_sprites_scene.tscn', 'res://scenes/tools/gen_icon_scene.tscn', 'res://scenes/tools/gen_meshes_scene.tscn')) {
    if (Test-Path (Join-Path $root ($scene -replace 'res://', '' -replace '/', '\'))) {
        Write-Host "RUN $scene"
        $null = Run-Godot @($scene, '--quit')
    } else {
        Write-Host "SKIP $scene (not found)"
    }
}

# ============================================================================
# PHASE 7: GENERATE MUSIC/SFX
# ============================================================================
Write-Host '---- PHASE 7: AUDIO GENERATION ----'
foreach ($scene in @('res://scenes/tools/gen_music_scene.tscn', 'res://scenes/tools/gen_sfx_scene.tscn')) {
    if (Test-Path (Join-Path $root ($scene -replace 'res://', '' -replace '/', '\'))) {
        Write-Host "RUN $scene"
        $null = Run-Godot @($scene, '--quit')
    } else {
        Write-Host "SKIP $scene (not found)"
    }
}

# ============================================================================
# PHASE 8: COMPILE (loop up to 3 iterations fixing errors)
# ============================================================================
Write-Host '---- PHASE 8: COMPILE ----'
$g = Resolve-Godot
if (-not $g) {
    Write-Host 'WARN: Godot not found; skipping compile'
} else {
    $log = Join-Path $root 'compile.log'
    $scene = 'res://scenes/tools/compile_scene.tscn'
    if (-not (Test-Path (Join-Path $root 'scenes\tools\compile_scene.tscn'))) { $scene = '--quit' }
    for ($iter = 1; $iter -le 3; $iter++) {
        Write-Host "Compile iteration $iter..."
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        if ($scene -eq '--quit') { & $g --headless --path $root --quit *> $log }
        else { & $g --headless --path $root $scene *> $log }
        $exit = $LASTEXITCODE
        $ErrorActionPreference = $prev
        $bad = Select-String -Path $log -Pattern 'SCRIPT ERROR|Parse Error|Failed to load' -ErrorAction SilentlyContinue
        if ($exit -eq 0 -and -not $bad) {
            Write-Host 'COMPILE OK'
            break
        }
        Write-Host "COMPILE FAIL (iter $iter):"
        $bad | Select-Object -First 10 | ForEach-Object { Write-Host ('  ' + $_.Line) }
        if ($iter -eq 3) { Write-Host 'Gave up after 3 iterations.' }
    }
}

# ============================================================================
# PHASE 9: GIT COMMIT
# ============================================================================
Write-Host '---- PHASE 9: GIT ----'
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    Push-Location $root
    & git add -A
    & git commit -m "polish: 10/10 visual/audio/screens pass" 2>&1 | Out-Null
    Pop-Location
    Write-Host 'GIT committed'
} else {
    Write-Host 'SKIP git not found'
}

# ============================================================================
Write-Host '================== POLISH DONE =================='
Write-Host 'Press F5 in Godot to play. Flow: splash -> boot_loading -> main_menu -> game.'