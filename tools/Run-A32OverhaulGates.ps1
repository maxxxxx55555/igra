#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RepoRoot = ".",
    [string]$GodotBin = "",
    [switch]$Apply,
    [switch]$GenerateAudioPack
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path -LiteralPath $RepoRoot).Path
Write-Host "[GATE] Repo: $repo"

python --version
if ($LASTEXITCODE -ne 0) { throw "Python not found in PATH" }

if ($Apply) {
    python (Join-Path $repo "tools\audit_and_patch_mobile.py") --repo $repo --apply
} else {
    python (Join-Path $repo "tools\audit_and_patch_mobile.py") --repo $repo
}
$auditExit = $LASTEXITCODE
Write-Host "[GATE] audit_and_patch_mobile exit=$auditExit"

if ($GenerateAudioPack) {
    python (Join-Path $repo "tools\generate_procedural_audio_pack.py") --repo $repo
    if ($LASTEXITCODE -ne 0) { throw "generate_procedural_audio_pack failed (exit=$LASTEXITCODE)" }
}

if ($Apply) {
    python (Join-Path $repo "tools\optimize_mobile_media.py") --repo $repo --apply
} else {
    python (Join-Path $repo "tools\optimize_mobile_media.py") --repo $repo --verify-only
}
$mediaExit = $LASTEXITCODE
Write-Host "[GATE] optimize_mobile_media exit=$mediaExit"

$verifyArgs = @((Join-Path $repo "tools\verify_release_gates.py"), "--repo", $repo)
if (-not [string]::IsNullOrWhiteSpace($GodotBin)) {
    $verifyArgs += @("--godot", $GodotBin)
}
python @verifyArgs
$finalExit = $LASTEXITCODE
Write-Host "[GATE] verify_release_gates exit=$finalExit"
exit $finalExit
