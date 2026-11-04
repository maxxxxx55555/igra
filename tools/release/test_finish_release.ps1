# Run with PowerShell 5.1 or newer; local fixtures never contact GitHub.
param([switch]$SkipTransport)
$ErrorActionPreference = 'Stop'
$driver = Join-Path $PSScriptRoot 'Finish-IgraRelease.ps1'
if (-not (Test-Path -LiteralPath $driver)) { throw 'Release entrypoint is missing' }
. $driver
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('igra-finish-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $fixture
$git = (Get-Command git -CommandType Application | Select-Object -First 1).Source
$passed = 0
function Assert-True($Value, $Message) { if (-not $Value) { throw $Message }; $script:passed++ }
function Assert-Throws([scriptblock]$Action, [string]$Pattern) {
    try { & $Action } catch { if ($_.Exception.Message -match $Pattern) { $script:passed++; return }; throw }
    throw "Expected failure: $Pattern"
}
try {
    $remote = Join-Path $fixture 'remote.git'
    $source = Join-Path $fixture 'seed'
    $checkout = Join-Path $fixture 'source'
    $null = Invoke-ReleaseCommand $git @('init', '--bare', $remote)
    $null = Invoke-ReleaseCommand $git @('init', '-b', 'main', $source)
    $null = Invoke-ReleaseCommand $git @('-C', $source, 'config', 'user.name', 'Release test')
    $null = Invoke-ReleaseCommand $git @('-C', $source, 'config', 'user.email', 'fixture@example.invalid')
    [IO.File]::WriteAllText((Join-Path $source 'game.txt'), 'first')
    $null = Invoke-ReleaseCommand $git @('-C', $source, 'add', '.')
    $null = Invoke-ReleaseCommand $git @('-C', $source, 'commit', '-m', 'Fixture')
    $first = (Invoke-ReleaseCommand $git @('-C', $source, 'rev-parse', 'HEAD')).Trim()
    if ($SkipTransport) {
        Copy-Item -LiteralPath $source -Destination $checkout -Recurse
        $null = Invoke-ReleaseCommand $git @('-C', $checkout, 'remote', 'add', 'origin', $remote)
    } else {
        $null = Invoke-ReleaseCommand $git @('-C', $source, 'push', $remote, 'main')
        $first = Update-ReleaseCheckout $git $checkout $remote '' $false
        Assert-True ($first -match '^[a-f0-9]{40}$') 'Fresh checkout must return a real commit'
    }
    [IO.File]::WriteAllText((Join-Path $source 'game.txt'), 'second')
    $null = Invoke-ReleaseCommand $git @('-C', $source, 'commit', '-am', 'Second')
    if (-not $SkipTransport) { $null = Invoke-ReleaseCommand $git @('-C', $source, 'push', $remote, 'main') }
    $resumed = Update-ReleaseCheckout $git $checkout $remote $first $false
    Assert-True ($resumed -eq $first) 'Resume must preserve its pinned source'
    Assert-True ([IO.File]::ReadAllText((Join-Path $checkout 'game.txt')) -eq 'first') 'Resume fetched newer source unexpectedly'
    $updated = $first
    if (-not $SkipTransport) {
        $updated = Update-ReleaseCheckout $git $checkout $remote $first $true
        Assert-True ($updated -ne $first) 'Explicit update must advance to current main'
    }
    Assert-Throws { Update-ReleaseCheckout $git $checkout ($remote + '-wrong') $updated $false } 'origin differs'
    Assert-Throws { Update-ReleaseCheckout $git $checkout $remote ('a' * 40) $false } 'Source changed'
    [IO.File]::WriteAllText((Join-Path $checkout 'game.txt'), 'user work')
    Assert-Throws { Update-ReleaseCheckout $git $checkout $remote $updated $true } 'dirty'
    Assert-True ([IO.File]::ReadAllText((Join-Path $checkout 'game.txt')) -eq 'user work') 'Dirty source must be preserved'
    $artifacts = Join-Path $fixture 'artifacts'
    $null = New-Item -ItemType Directory -Path $artifacts
    $reportPath = Join-Path $artifacts 'release-report.json'
    $report = @{source_commit=$updated;source_tree_dirty=$false;state='BUILDS_CREATED_MANUAL_REVIEW_PENDING';checks=@(@{result='PASS'});artifacts=@()}
    Write-ReleaseJson $reportPath $report
    [IO.File]::WriteAllText((Join-Path $artifacts 'build.zip'), 'fixture build bytes')
    $reportHash = (Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $buildHash = (Get-FileHash -LiteralPath (Join-Path $artifacts 'build.zip') -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText((Join-Path $artifacts 'SHA256SUMS.txt'), "$reportHash  release-report.json`n$buildHash  build.zip`n")
    $state = @{revision=$updated;mode='build';report=$reportPath;report_sha256=$reportHash}
    Assert-True (Test-ReleaseResult $state $updated 'build') 'Verified report and artifacts should be reusable'
    Assert-True (-not (Test-ReleaseResult $state ('f' * 40) 'build')) 'Never reuse another revision'
    Assert-True (-not (Test-ReleaseResult $state $updated 'check')) 'Never reuse another mode'
    [IO.File]::WriteAllText((Join-Path $artifacts 'build.zip'), 'corrupted')
    Assert-True (-not (Test-ReleaseResult $state $updated 'build')) 'Corrupt build must invalidate reuse'
    [IO.File]::WriteAllText((Join-Path $artifacts 'SHA256SUMS.txt'), "$reportHash  ../release-report.json`n")
    Assert-True (-not (Test-ReleaseResult $state $updated 'build')) 'Unsafe checksum path must be rejected'
    [IO.File]::WriteAllText($reportPath, '{}')
    Assert-True (-not (Test-ReleaseResult $state $updated 'build')) 'Report changes must invalidate reuse'
    Write-Output "Finish release tests: $passed passed"
    if ($SkipTransport) { Write-Output 'SKIPPED: fresh remote clone and fast-forward transport (Git Bash unavailable in sandbox).' }
} finally {
    $resolved = [IO.Path]::GetFullPath($fixture)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf).StartsWith('igra-finish-')) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
