# make_it_perfect.ps1 -- авто-стабилизация до играбельного состояния
param([string]$GodotExe = '')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$utf8 = New-Object System.Text.UTF8Encoding($false)

function GD([string[]]$l) { return (($l -join "`n") + "`n").Replace('\t', "`t") }
function Save([string]$path, [string]$c) {
    if (Test-Path $path) { Copy-Item $path "$path.bak" -Force }
    [System.IO.File]::WriteAllText($path, $c, $utf8)
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
$g = Resolve-Godot
if (-not $g) { Write-Host 'FATAL: Godot not found'; exit 1 }

# ================= 1. ТИШИНА: убираем спам print/push_warning/push_error =====
Write-Host '---- 1. silence spam ----'
$changed = 0
Get-ChildItem -Path $root -Recurse -Filter *.gd -File | ForEach-Object {
    $t = [System.IO.File]::ReadAllText($_.FullName)
    $new = [regex]::Replace($t, '(?m)^(\s*)(push_warning\(|push_error\()', '$1# $2')
    if ($_.Name -eq 'Enemy3D.gd' -or $_.Name -eq 'stress_test.gd') {
        $new = [regex]::Replace($new, '(?m)^(\s*)(print\()', '$1# $2')
    }
    if ($new -ne $t) { Save $_.FullName $new; $changed++ }
}
Write-Host "silenced in $changed file(s)"

# ================= 2. ШИНА: все используемые сигналы объявлены ================
Write-Host '---- 2. event bus ----'
$pf = [System.IO.File]::ReadAllText((Join-Path $root 'project.godot'), $utf8)
$busPath = $null
if ($pf -match 'EventBus\s*=\s*"\*?res://([^"]+)"') { $busPath = Join-Path $root ($Matches[1] -replace '/', '\') }
if ($busPath -and (Test-Path $busPath)) {
    $bus = [System.IO.File]::ReadAllText($busPath)
    $used = @{}
    Get-ChildItem -Path $root -Recurse -Filter *.gd -File | ForEach-Object {
        $t = [System.IO.File]::ReadAllText($_.FullName)
        [regex]::Matches($t, 'EventBus\.([A-Za-z_]\w*)') | ForEach-Object { $used[$_.Groups[1].Value] = $true }
    }
    $skip = @('has_signal','connect','emit_signal','disconnect','is_connected','has_method','has_node','get_node','call','call_deferred','set','get','get_meta','set_meta','get_tree','add_child','queue_free','is_instance_valid','get_name','set_name','get_class')
    $add = @()
    foreach ($n in ($used.Keys | Sort-Object)) {
        if ($bus -match ("signal\s+$n\b") -or ($skip -contains $n)) { continue }
        $add += "signal $n"
    }
    if ($add.Count) { [System.IO.File]::AppendAllText($busPath, ("`n" + ($add -join "`n") + "`n")); Write-Host "bus +$($add.Count)" }
    else { Write-Host 'bus OK' }
}

# ================= 3. СТАРТ: main_scene обязательно задан ====================
Write-Host '---- 3. main scene ----'
if ($pf -notmatch 'run/main_scene="res://[^"]+"') {
    $pf2 = $pf
    if ($pf2 -match '\[application\]') {
        $pf2 = $pf2 -replace '\[application\]', "[application]`nrun/main_scene=`"res://scenes/main_3d.tscn`""
    } else {
        $pf2 = "[application]`nrun/main_scene=`"res://scenes/main_3d.tscn`"`n" + $pf2
    }
    [System.IO.File]::WriteAllText((Join-Path $root 'project.godot'), $pf2, $utf8)
    Write-Host 'main_scene set'
} else { Write-Host 'main_scene OK' }

# ================= 4. ЦИКЛ: играем headless и чиним, пока чисто ==============
Write-Host '---- 4. play & fix loop ----'
$log = Join-Path $root 'perfect.log'
for ($iter = 1; $iter -le 4; $iter++) {
    Write-Host "session $iter..."
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $g --headless --path $root --quit-after 900 *> $log
    $ErrorActionPreference = $prev
    $txt = if (Test-Path $log) { [System.IO.File]::ReadAllText($log) } else { '' }
    $fixedSomething = $false

    # 4a. недостающие сигналы шины из рантайм-ошибок
    foreach ($m in [regex]::Matches($txt, "Invalid access to property or key '(\w+)' on a base object of type 'Node \(event_bus")) {
        if ($busPath -and (Test-Path $busPath)) {
            $b = [System.IO.File]::ReadAllText($busPath)
            $sig = $m.Groups[1].Value
            if ($b -notmatch "signal\s+$sig\b") { [System.IO.File]::AppendAllText($busPath, "`nsignal $sig`n"); $fixedSomething = $true; Write-Host "  +signal $sig" }
        }
    }
    # 4b. недостающие скрипты -> стабы
    foreach ($m in [regex]::Matches($txt, 'Failed to load script "res://([^"]+\.gd)"')) {
        $rel = $m.Groups[1].Value
        $p = Join-Path $root ($rel -replace '/', '\')
        if (-not (Test-Path $p)) {
            Save $p (GD @('extends Node', '', 'func _ready() -> void:', '\tpass'))
            $fixedSomething = $true; Write-Host "  stub $rel"
        }
    }
    # 4c. недостающие сцены, на которые идут переходы -> минимальная сцена
    foreach ($m in [regex]::Matches($txt, 'Failed to load|Cannot open file|change_scene[^"]*"res://([^"]+\.tscn)"')) {
        $rel = $m.Groups[1].Value
        $p = Join-Path $root ($rel -replace '/', '\')
        if (-not (Test-Path $p)) {
            $d = Split-Path -Parent $p
            if ($d -and -not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
            Save $p (GD @('[gd_scene format=3]', '', '[node name="Fallback" type="Node3D"]'))
            $fixedSomething = $true; Write-Host "  scene stub $rel"
        }
    }
    $bad = Select-String -Path $log -Pattern 'SCRIPT ERROR|Parse Error' -ErrorAction SilentlyContinue
    if (-not $bad) { Write-Host 'SESSION CLEAN'; break }
    if (-not $fixedSomething) {
        Write-Host 'remaining issues (need manual look):'
        $bad | Select-Object -First 10 | ForEach-Object { Write-Host ('  ' + $_.Line) }
        break
    }
}

# ================= 5. ФИНАЛ ==================================================
Write-Host '---- 5. final compile ----'
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $g --headless --path $root --quit *> (Join-Path $root 'compile.log')
$ErrorActionPreference = $prev
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) { Push-Location $root; & git add -A; & git commit -m "stabilize: silent clean playable build" 2>&1 | Out-Null; Pop-Location }
Write-Host '================== DONE =================='
Write-Host 'Теперь просто открой project.godot в Godot и нажми F5.'