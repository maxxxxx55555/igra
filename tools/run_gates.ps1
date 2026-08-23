# Runs the four headless Godot validation gates and prints exit codes.
# Usage: powershell -File tools/run_gates.ps1

$ErrorActionPreference = "Stop"
$Godot = "C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe"
$root = Split-Path -Parent $PSScriptRoot

$gates = @(
    "res://scenes/tools/compile_gate_scene.tscn",
    "res://scenes/tools/signal_arity_check_scene.tscn",
    "res://scenes/tools/i18n_check_scene.tscn",
    "res://scenes/tools/asset_check_scene.tscn"
)

$results = @{}
foreach ($g in $gates) {
    Write-Host "=== $g ===" -ForegroundColor Cyan
    & $Godot --headless --path $root $g
    $code = $LASTEXITCODE
    $results[$g] = $code
    Write-Host "exit code: $code"
    Write-Host ""
}

Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
$allPass = $true
foreach ($g in $gates) {
    $code = $results[$g]
    if ($code -ne 0) { $allPass = $false }
    Write-Host "$g -> $code"
}

if ($allPass) {
    Write-Host "ALL GATES PASS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "GATE FAILURES DETECTED" -ForegroundColor Red
    exit 1
}
