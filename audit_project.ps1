# audit_project.ps1 — аудит проекта перед мега-правками
$projectPath = Get-Location
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = "$projectPath\_AUDIT_$timestamp.md"
$backupPath = "$projectPath\_BACKUP_BEFORE_MEGA_PATCH_$timestamp"

# 1. Бэкап критичных файлов
Write-Host "🗄️ Создаю бэкап..." -ForegroundColor Cyan
$foldersToBackup = @("scripts","scenes","components","data","docs","localization","tests","templates")
New-Item -ItemType Directory -Force -Path $backupPath | Out-Null
foreach ($f in $foldersToBackup) {
    if (Test-Path $f) { Copy-Item -Recurse -Force $f "$backupPath\$f" }
}
Copy-Item project.godot $backupPath\ -Force
Write-Host "   Бэкап сохранён: $backupPath" -ForegroundColor Green

# 2. Аудит файлов
$gdFiles = Get-ChildItem -Recurse -Filter "*.gd" | Select-Object FullName, Length
$tscnFiles = Get-ChildItem -Recurse -Filter "*.tscn" | Select-Object FullName, Length

# 3. Поиск дублей по имени
$dupes = $gdFiles | Group-Object Name | Where-Object { $_.Count -gt 1 }

# 4. Поиск потенциальных мёртвых файлов (не упоминаются в tscn/gd)
$allScripts = $gdFiles | ForEach-Object { $_.Name }
$allContent = ""
Get-ChildItem -Recurse -Include "*.gd","*.tscn","*.cfg",".env" | ForEach-Object {
    $allContent += Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
}
$orphans = @()
foreach ($s in $allScripts) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($s)
    if ($allContent -notmatch $base) {
        $orphans += $s
    }
}

# 5. Autoload'ы из project.godot
$autoloads = @()
if (Test-Path "project.godot") {
    $godotContent = Get-Content "project.godot" -Raw
    $autoloadMatches = [regex]::Matches($godotContent, 'autoload/([^=]+)="([^"]+)"')
    foreach ($m in $autoloadMatches) {
        $autoloads += [PSCustomObject]@{ Name=$m.Groups[1].Value; Path=$m.Groups[2].Value }
    }
}

# 6. Формирование отчёта
@"
# AUDIT REPORT — THE_LAST_STREETLIGHT
**Дата:** $(Get-Date)
**Путь:** $projectPath

## 📊 Статистика
- GDScript файлов: $($gdFiles.Count)
- Сцен (.tscn): $($tscnFiles.Count)
- Общий вес скриптов: $([math]::Round(($gdFiles | Measure-Object -Property Length -Sum).Sum / 1KB, 2)) KB

## 🔁 Дубли по имени
$(if ($dupes.Count -eq 0) { "Дублей не найдено." } else { $dupes | ForEach-Object { "- $($_.Name): $($_.Count) шт." } | Out-String })

## ⚰️ Потенциально мёртвые скрипты (не референсятся)
$(if ($orphans.Count -eq 0) { "Не найдено." } else { $orphans | ForEach-Object { "- $_" } | Out-String })

## 🔌 Autoload'ы (из project.godot)
$( $autoloads | ForEach-Object { "- $($_.Name) → $($_.Path)" } | Out-String )

## 📋 Рекомендации
1. Проверить orphans вручную (могут быть false-positive)
2. Дубли — кандидаты на удаление/слияние
3. Autoload'ы: проверить, используются ли в коде
"@ | Set-Content $reportPath -Encoding UTF8

Write-Host "`n✅ Аудит готов: $reportPath" -ForegroundColor Green
Write-Host "📦 Бэкап: $backupPath" -ForegroundColor Green