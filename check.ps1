# check.ps1 — вердикт компиляции
$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
Set-Location $PSScriptRoot
$out = & $godot --headless --path . res://scenes/tools/compile_scene.tscn 2>&1 | Out-String
$bad = [regex]::Matches($out, "BAD: [^\r\n]+")
$failed = [regex]::Match($out, "FAILED: \d+/\d+")
if ($bad.Count -eq 0) {
    Write-Host "=== БЕЗ ОШИБОК: компиляция чистая ===" -ForegroundColor Green
} else {
    Write-Host "=== ОШИБКИ ($($bad.Count)): ===" -ForegroundColor Red
    foreach ($m in $bad) { Write-Host ("  " + $m.Value) -ForegroundColor Red }
}
if ($failed.Success) { Write-Host ("Гейт: " + $failed.Value) -ForegroundColor Yellow }