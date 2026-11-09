#requires -Version 5.1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = Join-Path $PSScriptRoot ('../../.qa_logs/cloudflare-tests/' + [Guid]::NewGuid().ToString('N'))
$build = Join-Path $root 'web'
$state = Join-Path $root 'state'
[IO.Directory]::CreateDirectory($build) | Out-Null
$revision = 'a' * 40
foreach ($name in @('index.js', 'index.wasm', 'index.pck')) { [IO.File]::WriteAllText((Join-Path $build $name), 'fixture bytes') }
[IO.File]::WriteAllText((Join-Path $build 'index.html'), '<script>const GODOT_THREADS_ENABLED = false;</script>')
[IO.File]::WriteAllText((Join-Path $build 'BUILD_INFO.json'), (@{ source_commit = $revision; platform = 'web' } | ConvertTo-Json))
$zip = Join-Path $root 'fixture-web.zip'
[IO.Compression.ZipFile]::CreateFromDirectory($build, $zip)
$reportPath = Join-Path $root 'release-report.json'
$report = @{ state = 'BUILDS_CREATED_MANUAL_REVIEW_PENDING'; source_commit = $revision; source_tree_dirty = $false; checks = @(@{ result = 'PASS' }); artifacts = @(@{ file = 'fixture-web.zip'; sha256 = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant() }) }
function Save-Report { [IO.File]::WriteAllText($reportPath, ($report | ConvertTo-Json -Depth 8)) }
Save-Report
$scriptPath = Join-Path $PSScriptRoot 'Deploy-IgraWeb.ps1'
$arguments = @{ BuildDirectory = $build; ReportPath = $reportPath; SourceCommit = $revision; WorkRoot = $state }
function Expect-Failure([scriptblock]$Action, [string]$Message) {
    $failed = $false
    try { & $Action } catch { $failed = $true; if ($_ -notmatch $Message) { throw "Wrong failure: $_" } }
    if (-not $failed) { throw 'Invalid input was accepted.' }
}
& $scriptPath @arguments
$plan = Get-Content -LiteralPath (Join-Path $state 'prepared.json') -Raw | ConvertFrom-Json
if ($plan.status -ne 'PREPARED_NOT_DEPLOYED' -or $plan.threaded -ne 'false' -or @($plan.files.PSObject.Properties).Count -ne 5) { throw 'Dry-run plan is wrong.' }
& $scriptPath @arguments
$resumed = Get-Content -LiteralPath (Join-Path $state 'prepared.json') -Raw | ConvertFrom-Json
if ($resumed.release_prefix -ne $plan.release_prefix) { throw 'Same bytes changed the immutable prefix.' }
if (Test-Path -LiteralPath (Join-Path $state 'npm-cache')) { throw 'Dry-run attempted to use npm.' }
$pack = Join-Path $build 'index.pck'
[IO.File]::WriteAllText($pack, 'changed bytes')
Expect-Failure { & $scriptPath @arguments } 'differs from the verified ZIP'
[IO.File]::WriteAllText($pack, 'fixture bytes')
$extra = Join-Path $build 'unexpected.json'
[IO.File]::WriteAllText($extra, '{}')
Expect-Failure { & $scriptPath @arguments } 'unrecorded files'
Remove-Item -LiteralPath $extra
$report.checks[0].result = 'FAIL'; Save-Report
Expect-Failure { & $scriptPath @arguments } 'failed verification'
$report.checks[0].result = 'PASS'; Save-Report
$report.source_commit = 'b' * 40; Save-Report
Expect-Failure { & $scriptPath @arguments } 'exact source commit'
$report.source_commit = $revision; Save-Report
$originalZip = [IO.File]::ReadAllBytes($zip)
[IO.File]::AppendAllText($zip, 'tampered')
Expect-Failure { & $scriptPath @arguments } 'ZIP hash differs'
[IO.File]::WriteAllBytes($zip, $originalZip)
Expect-Failure { & $scriptPath @arguments -Publish } 'explicit AccountId'
Write-Host 'CLOUDFLARE_DEPLOY_TESTS_PASS: dry-run, stable prefix, payload tampering, unrecorded file, failed checks, wrong revision, ZIP tampering, missing publish identity.'
