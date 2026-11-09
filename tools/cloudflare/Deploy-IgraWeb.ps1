#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BuildDirectory,
    [Parameter(Mandatory = $true)][string]$ReportPath,
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-f0-9]{40}$')][string]$SourceCommit,
    [ValidatePattern('^[a-f0-9]{32}$')][string]$AccountId = $env:CLOUDFLARE_ACCOUNT_ID,
    [ValidatePattern('^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$')][string]$Bucket = $env:IGRA_R2_BUCKET,
    [ValidatePattern('^[a-z][a-z0-9-]{0,62}$')][string]$WorkerName = $env:IGRA_WORKER_NAME,
    [string]$WorkRoot = (Join-Path $PSScriptRoot '../../.qa_logs/cloudflare'),
    [switch]$Publish
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-StreamHash([IO.Stream]$Stream) {
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($hasher.ComputeHash($Stream))).Replace('-', '').ToLowerInvariant() }
    finally { $hasher.Dispose() }
}
function Write-Json([string]$Path, $Value) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
}
function Invoke-Wrangler([string[]]$Arguments) {
    & $script:npx --yes wrangler@4 @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Wrangler failed ($LASTEXITCODE); activation stopped." }
}

$build = (Resolve-Path -LiteralPath $BuildDirectory).Path
$reportFile = (Resolve-Path -LiteralPath $ReportPath).Path
$report = [IO.File]::ReadAllText($reportFile) | ConvertFrom-Json
if ($report.state -ne 'BUILDS_CREATED_MANUAL_REVIEW_PENDING' -or $report.source_commit -ne $SourceCommit -or $report.source_tree_dirty) {
    throw 'A clean, verified build report for the exact source commit is required.'
}
if (@($report.checks).Count -eq 0 -or @($report.checks | Where-Object { $_.result -notin @('PASS', 'RECOVERED_IMPORT') }).Count -gt 0) {
    throw 'The build report contains missing or failed verification.'
}
$artifact = @($report.artifacts | Where-Object { $_.file -match '^[^/\\:]+-web\.zip$' })
if ($artifact.Count -ne 1) { throw 'Exactly one recorded Web ZIP is required.' }
$archivePath = Join-Path (Split-Path $reportFile -Parent) $artifact[0].file
if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $artifact[0].sha256) {
    throw 'Web ZIP hash differs from the build report.'
}
$files = [ordered]@{}
$mime = @{ '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8'; '.wasm' = 'application/wasm'; '.pck' = 'application/octet-stream'; '.png' = 'image/png'; '.ico' = 'image/x-icon'; '.json' = 'application/json'; '.webmanifest' = 'application/manifest+json' }
$archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    foreach ($entry in @($archive.Entries | Sort-Object FullName)) {
        $name = $entry.FullName
        $extension = [IO.Path]::GetExtension($name).ToLowerInvariant()
        if ($name -notmatch '^[a-zA-Z0-9_.-]+$' -or -not $mime.ContainsKey($extension) -or $files.Contains($name)) { throw "Unexpected Web ZIP entry: $name" }
        if ($entry.Length -le 0 -or $entry.Length -gt 300MB) { throw "Asset outside the supported 1..300 MiB upload size: $name" }
        $stream = $entry.Open()
        try { $hash = Get-StreamHash $stream } finally { $stream.Dispose() }
        $path = Join-Path $build $name
        if (-not [IO.File]::Exists($path) -or (Get-Item -LiteralPath $path).Length -ne $entry.Length -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) {
            throw "Build directory differs from the verified ZIP: $name"
        }
        $files[$name] = [ordered]@{ bytes = $entry.Length; sha256 = $hash; mime = $mime[$extension] }
    }
} finally { $archive.Dispose() }
foreach ($required in @('index.html', 'index.js', 'index.wasm', 'index.pck', 'BUILD_INFO.json')) {
    if (-not $files.Contains($required)) { throw "Incomplete verified Web export: $required" }
}
if (@(Get-ChildItem -LiteralPath $build -Force).Count -ne $files.Count) { throw 'Build directory has unrecorded files or directories.' }
$info = [IO.File]::ReadAllText((Join-Path $build 'BUILD_INFO.json')) | ConvertFrom-Json
if ($info.source_commit -ne $SourceCommit -or $info.platform -ne 'web') { throw 'BUILD_INFO does not identify this Web source revision.' }
$html = [IO.File]::ReadAllText((Join-Path $build 'index.html'))
if ($html -notmatch 'GODOT_THREADS_ENABLED\s*=\s*(true|false)') { throw 'Cannot determine the exported Godot thread mode.' }
$threaded = $Matches[1]
$serialized = ConvertTo-Json -InputObject $files -Depth 6 -Compress
if ([Text.Encoding]::UTF8.GetByteCount($serialized) -gt 4000) { throw 'Manifest exceeds the conservative Worker variable budget.' }
$manifestStream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($serialized))
try { $manifestHash = Get-StreamHash $manifestStream } finally { $manifestStream.Dispose() }
$prefix = 'releases/' + $SourceCommit + '/' + $manifestHash
$WorkRoot = [IO.Path]::GetFullPath($WorkRoot)
[IO.Directory]::CreateDirectory($WorkRoot) | Out-Null
$workerPath = Join-Path $PSScriptRoot 'worker.mjs'
$workerHash = (Get-FileHash -LiteralPath $workerPath -Algorithm SHA256).Hash.ToLowerInvariant()
$plan = [ordered]@{ source_commit = $SourceCommit; manifest_sha256 = $manifestHash; worker_sha256 = $workerHash; release_prefix = $prefix; threaded = $threaded; files = $files; status = 'PREPARED_NOT_DEPLOYED'; account_id = $AccountId; bucket = $Bucket; worker = $WorkerName }
Write-Json (Join-Path $WorkRoot 'prepared.json') $plan
Write-Host "VERIFIED: $($files.Count) files; source $SourceCommit; prefix $prefix"
if (-not $Publish) { Write-Host 'PREPARED_NOT_DEPLOYED: repeat with account, bucket, worker and -Publish after authenticating Wrangler.'; return }
if ($AccountId -notmatch '^[a-f0-9]{32}$' -or $Bucket -notmatch '^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$' -or $WorkerName -notmatch '^[a-z][a-z0-9-]{0,62}$') { throw 'Publish requires explicit AccountId, existing Bucket and WorkerName.' }
$script:npx = (Get-Command npx.cmd -CommandType Application -ErrorAction Stop).Source
$previousCache = $env:npm_config_cache
$previousAccount = $env:CLOUDFLARE_ACCOUNT_ID
try {
    $env:npm_config_cache = Join-Path $WorkRoot 'npm-cache'
    $env:CLOUDFLARE_ACCOUNT_ID = $AccountId
    Invoke-Wrangler @('whoami')
    Invoke-Wrangler @('r2', 'bucket', 'info', $Bucket)
    foreach ($name in $files.Keys) {
        $path = Join-Path $build $name
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $files[$name].sha256) { throw "File changed before upload: $name" }
        Invoke-Wrangler @('r2', 'object', 'put', ($Bucket + '/' + $prefix + '/' + $name), '--file', $path, '--content-type', $files[$name].mime, '--remote')
    }
    # A successful PUT alone is not deployment evidence: read back every byte before activation.
    foreach ($name in $files.Keys) {
        $download = Join-Path $WorkRoot ([Guid]::NewGuid().ToString('N') + '.verify')
        try {
            Invoke-Wrangler @('r2', 'object', 'get', ($Bucket + '/' + $prefix + '/' + $name), '--file', $download, '--remote')
            if ((Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash.ToLowerInvariant() -ne $files[$name].sha256) { throw "Remote object hash mismatch: $name" }
        } finally { if ([IO.File]::Exists($download)) { Remove-Item -LiteralPath $download } }
    }
    $versionRoot = Join-Path $WorkRoot ('versions/' + $WorkerName + '/' + $SourceCommit + '/' + $manifestHash + '/' + $workerHash)
    [IO.Directory]::CreateDirectory($versionRoot) | Out-Null
    Copy-Item -LiteralPath $workerPath -Destination (Join-Path $versionRoot 'worker.mjs')
    if ((Get-FileHash -LiteralPath (Join-Path $versionRoot 'worker.mjs') -Algorithm SHA256).Hash.ToLowerInvariant() -ne $workerHash) { throw 'Worker changed during upload; activation stopped.' }
    $config = [ordered]@{ name = $WorkerName; account_id = $AccountId; main = 'worker.mjs'; compatibility_date = '2026-11-09'; workers_dev = $true; r2_buckets = @(@{ binding = 'GAME'; bucket_name = $Bucket }); vars = @{ RELEASE_PREFIX = $prefix; FILES_JSON = $serialized; THREADED = $threaded } }
    $configPath = Join-Path $versionRoot 'wrangler.json'
    Write-Json $configPath $config
    Invoke-Wrangler @('deploy', '--config', $configPath)
    $plan.status = 'DEPLOYED_BROWSER_REVIEW_PENDING'
    Write-Json (Join-Path $WorkRoot 'deployed.json') $plan
    Write-Json (Join-Path $versionRoot 'deployed.json') $plan
    Write-Host 'DEPLOYED_BROWSER_REVIEW_PENDING: verify HTTPS load, console, audio, saves and gameplay at the reported Worker URL.'
} finally {
    $env:npm_config_cache = $previousCache
    $env:CLOUDFLARE_ACCOUNT_ID = $previousAccount
}
