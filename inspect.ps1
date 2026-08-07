<# inspect.ps1 v3 — с ловушкой ошибки и чекпоинтами. Только читает. #>
[CmdletBinding()]
param([string]$Path = ".")

$sw = [Diagnostics.Stopwatch]::StartNew()
$SKIP = @('.git','.godot','build','bin','export','exports','.vs','.vscode',
          '.idea','node_modules','.mono','obj','.tmp','backups','.import_cache')

function Get-ProjectFiles {
    param([string]$Dir)
    $items = Get-ChildItem -LiteralPath $Dir -Force -ErrorAction SilentlyContinue
    foreach ($it in $items) {
        if ($it.PSIsContainer) { if ($SKIP -notcontains $it.Name) { Get-ProjectFiles $it.FullName } }
        else { $it }
    }
}
function Find-ProjectRoot($p) {
    $p = (Resolve-Path $p).Path; $d = $p
    for ($i=0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $d 'project.godot')) { return $d }
        $parent = Split-Path $d -Parent; if ($parent -eq $d) { break }; $d = $parent
    }
    $f = Get-ChildItem -Path $p -Recurse -Filter 'project.godot' -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($f) { return $f.DirectoryName } else { return $null }
}

$root = Find-ProjectRoot $Path
if (-not $root) { throw "project.godot not found from '$Path'." }
Write-Host "PROJECT ROOT: $root" -ForegroundColor Cyan
Write-Host "scanning ..." -ForegroundColor DarkGray
$all = @(Get-ProjectFiles $root)
Write-Host ("collected {0} files in {1:N1}s" -f $all.Count, $sw.Elapsed.TotalSeconds) -ForegroundColor Green

try {
    $byExt = @{}
    foreach ($f in $all) { $e = $f.Extension.ToLower(); if (-not $byExt.ContainsKey($e)) { $byExt[$e] = New-Object System.Collections.ArrayList }; [void]$byExt[$e].Add($f) }
    Write-Host "[1] ext-index built" -ForegroundColor DarkGray
    function Ext($e) { $e = $e.ToLower(); if ($byExt.ContainsKey($e)) { return $byExt[$e].Count } else { return 0 } }
    function ByName($mask) { @($all | Where-Object { $_.Name -like $mask }).Count }
    function Cnt {
        param([string]$ExtMask, [string]$Pattern, [switch]$FilesOnly)
        $exts = @($ExtMask -split ',' | ForEach-Object { $_.Trim().TrimStart('*').ToLower() })
        $files = @($all | Where-Object { $exts -contains $_.Extension.ToLower() })
        if (-not $files) { return 0 }
        $hits = @($files | Select-String -Pattern $Pattern -ErrorAction SilentlyContinue)
        if (-not $hits) { return 0 }
        if ($FilesOnly) { return ($hits | Group-Object Path).Count } else { return $hits.Count }
    }

    $gdFiles = if ($byExt.ContainsKey('.gd')) { $byExt['.gd'] } else { @() }
    $totalLines = 0; $codeLines = 0
    foreach ($f in $gdFiles) {
        $ls = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
        $totalLines += $ls.Count
        $codeLines  += @($ls | Where-Object { $_ -notmatch '^\s*$' -and $_ -notmatch '^\s*#' }).Count
    }
    Write-Host "[2] gd lines counted" -ForegroundColor DarkGray

    $pgPath = Join-Path $root 'project.godot'
    $pg = if (Test-Path $pgPath) { Get-Content $pgPath -Raw -ErrorAction SilentlyContinue } else { '' }
    $autoloadCount = 0; $hasI18nSection = $false
    if ($pg) {
        $autoloadCount = @([regex]::Matches($pg, '(?m)^\s*\w+\s*=\s*"\*?res://.*\.gd"')).Count
        $hasI18nSection = ($pg -match '\[internationalization\]') -or ($pg -match 'locale')
    }
    $levels = @($all | Where-Object { $_.Name -match '^(level_\d+|boss_arena).*\.tscn$' })
    Write-Host "[3] project.godot parsed" -ForegroundColor DarkGray

    $m = [ordered]@{}
    $m.'gd_scripts'           = $gdFiles.Count
    $m.'code_lines(gross)'    = $totalLines
    $m.'code_lines(net)'      = $codeLines
    $m.'scenes_tscn'          = Ext '.tscn'
    $m.'resources_tres'       = Ext '.tres'
    $m.'levels_found'         = $levels.Count
    $m.'class_name_decl'      = Cnt '.gd' 'class_name\s+\w+'
    $m.'signals_decl'         = Cnt '.gd' '^\s*signal\s+\w+'
    $m.'exports_decl'         = Cnt '.gd' '@export'
    $m.'autoloads(approx)'    = $autoloadCount
    $m.'todo_fixme_hack'      = Cnt '.gd' 'TODO|FIXME|HACK|XXX'
    $m.'error_handling_proxy' = (Cnt '.gd' 'push_error\(')+(Cnt '.gd' 'push_warning\(')+(Cnt '.gd' 'assert\(')+(Cnt '.gd' 'is_instance_valid')
    $m.'tests_gut_gdunit'     = (ByName '*test*.gd')+(ByName 'test_*.gd')+(ByName '*_test.gd')+@($all | Where-Object { $_.FullName -match '[\\/]addons[\\/](gut|gdUnit)' }).Count
    $m.'img_png_jpg_svg_webp' = (Ext '.png')+(Ext '.jpg')+(Ext '.jpeg')+(Ext '.svg')+(Ext '.webp')
    $m.'audio_ogg_wav_mp3'    = (Ext '.ogg')+(Ext '.wav')+(Ext '.mp3')
    $m.'models_glb_gltf_obj'  = (Ext '.glb')+(Ext '.gltf')+(Ext '.obj')+(Ext '.fbx')
    $m.'shaders_gdshader'     = Ext '.gdshader'
    $m.'anim_tres_anim'       = ByName '*.anim'
    $m.'ui_control_scenes'    = Cnt '.tscn' '\[node[^\]]*type="Control"' -FilesOnly
    $m.'ui_canvaslayer'       = Cnt '.tscn' 'CanvasLayer' -FilesOnly
    $m.'perf_practices'       = Cnt '.gd,.tscn' 'visible_range|lod_|OccluderInstance3D|multi_mesh|MultiMesh'
    Write-Host "[4] volume metrics done" -ForegroundColor DarkGray

    $g = [ordered]@{}
    $g.'enemy_killed.emit (files)' = Cnt '.gd' 'enemy_killed\.emit' -FilesOnly
    $g.'enemy_died.emit  (files)'  = Cnt '.gd' 'enemy_died\.emit'  -FilesOnly
    $g.'can_progress (files)'      = Cnt '.gd' 'can_progress'      -FilesOnly
    $g.'item_pickup.tscn exists'   = @($all | Where-Object { $_.Name -eq 'item_pickup.tscn' }).Count
    $g.'document_pickup in levels' = Cnt '.tscn' 'document_pickup' -FilesOnly
    $g.'checkpoint in levels'      = Cnt '.tscn' 'checkpoint'      -FilesOnly
    $g.'zone_trigger in levels'    = Cnt '.tscn' 'zone_trigger|zone_id' -FilesOnly
    $g.'npc/interact in levels'    = Cnt '.tscn' 'dialog_manager|start_dialog|interact' -FilesOnly
    $g.'secret in levels'          = Cnt '.tscn' 'secret' -FilesOnly
    $g.'secret_found.emit (files)' = Cnt '.gd' 'secret_found\.emit' -FilesOnly
    $bossScene = $all | Where-Object { $_.Name -eq 'boss_arena.tscn' } | Select-Object -First 1
    $g.'boss_arena lines'          = if ($bossScene) { (Get-Content -LiteralPath $bossScene.FullName -ErrorAction SilentlyContinue).Count } else { 0 }
    $g.'boss scripts (boss*.gd)'   = ByName 'boss*.gd'
    $g.'NG+ final_night_started.emit' = Cnt '.gd' 'final_night_started\.emit' -FilesOnly
    Write-Host "[5] gaps metrics done" -ForegroundColor DarkGray

    $n = [ordered]@{}
    $n.'FPS mouse_capture refs'   = Cnt '.gd' 'MOUSE_MODE_CAPTURED|set_mouse_mode|mouse_mode'
    $n.'FPS Camera3D in scenes'   = Cnt '.tscn' 'Camera3D' -FilesOnly
    $n.'FPS controller scripts'   = (ByName '*fps*.gd')+(ByName '*first_person*.gd')+(ByName '*player_controller*.gd')+(ByName '*player*.gd')
    $n.'NET @rpc / rpc( refs'     = Cnt '.gd' '@rpc|rpc\('
    $n.'NET peer/api refs'        = Cnt '.gd' 'ENetMultiplayerPeer|WebSocketMultiplayerPeer|SceneMultiplayer|multiplayer\.peer|MultiplayerAPI'
    $n.'NET synchronizer/spawner' = Cnt '.tscn' 'MultiplayerSynchronizer|MultiplayerSpawner' -FilesOnly
    $n.'NET dedicated scripts'    = (ByName '*network*.gd')+(ByName '*multiplayer*.gd')+(ByName '*lobby*.gd')+(ByName '*online*.gd')+(ByName '*net_*.gd')
    $n.'NET pct scripts touched'  = if ($gdFiles.Count) { [math]::Round(100.0*(Cnt '.gd' '@rpc|multiplayer\.' -FilesOnly)/$gdFiles.Count) } else { 0 }
    $n.'I18N tr( calls'           = Cnt '.gd' 'tr\('
    $n.'I18N TranslationServer'   = Cnt '.gd' 'TranslationServer'
    $n.'I18N .translation files'  = Ext '.translation'
    $n.'I18N .csv files'          = Ext '.csv'
    $n.'I18N .po files'           = Ext '.po'
    $n.'I18N hardcoded UI (heur)' = Cnt '.tscn' 'text\s*=\s*"'
    $n.'I18N locale in project'   = [int]$hasI18nSection
    Write-Host "[6] new-feat metrics done" -ForegroundColor DarkGray

    function Section($t){ Write-Host "`n===== $t =====" -ForegroundColor Yellow }
    Section "VOLUME / QUALITY PROXIES";        $m.GetEnumerator() | ForEach-Object { "{0,-28} {1}" -f $_.Key, $_.Value }
    Section "INTEGRATION GAPS (prev plan)";    $g.GetEnumerator() | ForEach-Object { "{0,-32} {1}" -f $_.Key, $_.Value }
    Section "NEW FEATURES (FPS / NET / I18N)"; $n.GetEnumerator() | ForEach-Object { "{0,-32} {1}" -f $_.Key, $_.Value }
    Write-Host ("`ntotal time: {0:N1}s" -f $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray
    Write-Host "[7] printing done" -ForegroundColor DarkGray

    $reportTxt  = Join-Path $root 'report.txt'
    $reportJson = Join-Path $root 'report.json'
    $out = [ordered]@{ root=$root; volume=$m; gaps=$g; new_features=$n }
    ($out | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $reportJson -Encoding UTF8
    $L = @("ROOT: $root", "`n[VOLUME]")
    $m.GetEnumerator() | ForEach-Object { $L += ("{0,-28} {1}" -f $_.Key, $_.Value) }
    $L += "`n[GAPS]"; $g.GetEnumerator() | ForEach-Object { $L += ("{0,-32} {1}" -f $_.Key, $_.Value) }
    $L += "`n[NEW]";  $n.GetEnumerator() | ForEach-Object { $L += ("{0,-32} {1}" -f $_.Key, $_.Value) }
    $L | Set-Content -LiteralPath $reportTxt -Encoding UTF8
    Write-Host "`nSaved: $reportTxt  |  $reportJson" -ForegroundColor Green
    Write-Host "[8] saved" -ForegroundColor DarkGray
}
catch {
    Write-Host "`n!!! SCRIPT ERROR !!!" -ForegroundColor Red
    Write-Host ("Message : {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ("Line    : {0}" -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ("Code    : {0}" -f $_.InvocationInfo.Line.Trim()) -ForegroundColor Red
    Write-Host "Stack   :" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}