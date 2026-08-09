Set-Location "C:\Users\Maxsim\Desktop\TLS_Build\THE_LAST_STREETLIGHT"

# 1. Побитые street-тайлы
git checkout abb47b4 -- meshes/street/lane_mark.tres meshes/street/road_tile.tres meshes/street/sidewalk_tile.tres

# 2. Autoload
$f = "project.godot"
$t = [System.IO.File]::ReadAllText($f)
$lines = @()
if ($t -notmatch 'FadeTransition=') { $lines += 'FadeTransition="*res://scripts/ui/fade_transition.gd"' }
if ($t -notmatch 'ObjectPool=') { $lines += 'ObjectPool="*res://scripts/systems/object_pool.gd"' }
if ($t -notmatch 'LightLimiter=') { $lines += 'LightLimiter="*res://scripts/systems/light_limiter.gd"' }
if ($lines.Count -gt 0) {
    $ins = $lines -join "`n"
    $t = $t -replace '\[autoload\]', ("[autoload]`n" + $ins)
    [System.IO.File]::WriteAllText($f, $t)
    Write-Host "autoload добавлен" -ForegroundColor Green
}

# 3. _BACKUPS
if (Test-Path "_BACKUPS\project.godot") { Rename-Item "_BACKUPS\project.godot" "project.godot.bak" -Force }

# 4. export_presets.cfg
$f = "export_presets.cfg"
$t = [System.IO.File]::ReadAllText($f)
if ($t -notmatch 'include_filter') {
    $ins = "include_filter=`"`"`nexclude_filter=`"`""
    $t = $t -replace '\[preset\.0\]', ("[preset.0]`n" + $ins)
    [System.IO.File]::WriteAllText($f, $t)
    Write-Host "export_presets исправлен" -ForegroundColor Green
}

git add -A
git commit -m "Phase 5B: known fixes"
Write-Host "ГОТОВО" -ForegroundColor Cyan