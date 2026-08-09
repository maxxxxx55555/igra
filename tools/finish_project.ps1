$ErrorActionPreference = 'Stop'
$root = 'C:\Users\Maxsim\Desktop\TLS_Build\THE_LAST_STREETLIGHT'
$godotCandidates = @(
    'C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\godot.exe',
    'C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64.exe'
)
$godot = $godotCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $godot) { throw 'Godot executable not found.' }
if (-not (Test-Path -LiteralPath $root)) { throw "Project not found: $root" }
Set-Location -LiteralPath $root

function Invoke-GodotGate([string]$scene) {
    Write-Host "`n=== $scene ===" -ForegroundColor Cyan
    & $godot --headless --path $root --quit-after 600 $scene
    if ($LASTEXITCODE -ne 0) { throw "Gate failed: $scene (exit $LASTEXITCODE)" }
}

Write-Host "Godot: $godot" -ForegroundColor Green
& $godot --version
$gates = @(
    'res://scenes/tools/compile_gate_scene.tscn',
    'res://scenes/tools/signal_arity_check_scene.tscn',
    'res://scenes/tools/i18n_check_scene.tscn',
    'res://scenes/tools/asset_check_scene.tscn'
)
foreach ($gate in $gates) { Invoke-GodotGate $gate }
Write-Host "`n=== STATUS ===" -ForegroundColor Cyan
git status --short
Write-Host "`nGates completed. No commit was created." -ForegroundColor Green
