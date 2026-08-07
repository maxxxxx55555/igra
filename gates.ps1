$godot = "C:\Users\Maxsim\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
Set-Location $PSScriptRoot
$fail = 0
Get-ChildItem "scenes\tools\*.tscn" | ForEach-Object {
  Write-Host "=== $($_.Name) ===" -ForegroundColor Cyan
  & $godot --headless --path . "res://scenes/tools/$($_.Name)" 2>&1 | Select-Object -Last 3
  if ($LASTEXITCODE -ne 0) { $fail++; Write-Host "FAIL: $($_.Name)" -ForegroundColor Red }
}
if ($fail -eq 0) { Write-Host "ALL GATES PASSED" -ForegroundColor Green } else { Write-Host "$fail FAILED" -ForegroundColor Red }
