Set-Location "C:\Users\Maxsim\Desktop\TLS_Build\THE_LAST_STREETLIGHT"

# 1. Восстановить побитые street-тайлы из коммита до 4A
git checkout abb47b4 -- meshes/street/lane_mark.tres meshes/street/road_tile.tres meshes/street/sidewalk_tile.tres

# 2. Добавить autoload в project.godot
$f = "project.godot"
$t = [System.IO.File]::ReadAllText($f)
$lines = @()
if ($t -notmatch 'FadeTransition=') { $lines += 'FadeTransition="*res://scripts/ui/fade_transition.gd"' }
if ($t -notmatch 'ObjectPool=') { $lines += 'ObjectPool="*res://scripts/systems/object_pool.gd"' }
if ($t -notmatch 'LightLimiter=') { $lines += 'LightLimiter="*res://scripts/systems/light_limiter.gd"' }
if ($lines.Count -gt 0) {
    $ins = $lines -join "`n"
    if ($t -match '\[autoload\]') {
        $t = $t -replace '\[autoload\]', ("[autoload]`n" + $ins)
    } else {
        $t = $t + "`n[autoload]`n" + $ins + "`n"
    }
    [System.IO.File]::WriteAllText($f, $t)
    Write-Host "autoload добавлен" -ForegroundColor Green
} else { Write-Host "autoload уже есть" -ForegroundColor Yellow }

# 3. Убрать дубликат project.godot из _BACKUPS
if (Test-Path "_BACKUPS\project.godot") {
    Rename-Item "_BACKUPS\project.godot" "project.godot.bak" -Force
    Write-Host "_BACKUPS обезврежен" -ForegroundColor Green
}

git add -A
git commit -m "Fix: restore street tiles, register autoloads"
Write-Host "ГОТОВО - перезапусти Godot" -ForegroundColor Cyan
