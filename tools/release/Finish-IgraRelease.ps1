#requires -Version 5.1
<#
Run: powershell -NoProfile -ExecutionPolicy Bypass -File .\Finish-IgraRelease.ps1
Checks current main and builds Windows/Web. Repeat to resume the pinned source;
-Update starts from newest main. -CheckGame skips exports.
-Android requires the existing signing identity, Android SDK and JDK 17.
-SigningEnv .signing\release.env loads signing variables into this process only;
values are never printed. Missing SDK/JDK paths are detected when installed.
Android example: .\tools\release\Finish-IgraRelease.ps1 -Android -SigningEnv .signing\release.env
This script never replaces a project, generates signing keys or publishes a store release.
#>
[CmdletBinding()]
param(
    [string]$Repository = 'maxxxxx55555/igra',
    [string]$WorkRoot,
    [switch]$Update,
    [switch]$CheckGame,
    [switch]$Android,
    [string]$AndroidSdk = $env:ANDROID_HOME,
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$SigningEnv,
    [switch]$DraftRelease
)

function Invoke-ReleaseCommand([string]$Exe, [string[]]$Arguments) {
    if (-not [IO.File]::Exists($Exe)) { throw "Executable not found: $Exe" }
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $lines = @(& $Exe @Arguments 2>&1 | ForEach-Object { "$_" })
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    if ($code -ne 0) { throw ((Split-Path $Exe -Leaf) + " exited ${code}:`n" + ($lines -join "`n")) }
    return ($lines -join "`n")
}

function Write-ReleaseJson([string]$Path, $Value) {
    $temporary = $Path + '.tmp'
    [IO.File]::WriteAllText($temporary, ($Value | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, $null) }
    else { [IO.File]::Move($temporary, $Path) }
}

function Update-ReleaseCheckout([string]$Git, [string]$Path, [string]$Remote, [string]$Pinned, [bool]$Refresh) {
    if (-not (Test-Path -LiteralPath $Path)) {
        $null = Invoke-ReleaseCommand $Git @('-c', 'core.autocrlf=false', 'clone', '--filter=blob:none', '--single-branch', '--branch', 'main', $Remote, $Path)
    }
    $actual = (Invoke-ReleaseCommand $Git @('-C', $Path, 'remote', 'get-url', 'origin')).Trim()
    if ($actual -ne $Remote) { throw 'Source origin differs from the selected repository; use another WorkRoot.' }
    if ((Invoke-ReleaseCommand $Git @('-C', $Path, 'branch', '--show-current')).Trim() -ne 'main') {
        throw 'The managed source must remain on main; no branch will be overwritten.'
    }
    if ((Invoke-ReleaseCommand $Git @('-C', $Path, 'status', '--porcelain')).Trim()) { throw 'Source is dirty; commit or move your work before continuing.' }
    $head = (Invoke-ReleaseCommand $Git @('-C', $Path, 'rev-parse', 'HEAD')).Trim()
    if ($Pinned -and -not $Refresh) {
        if ($head -ne $Pinned) { throw 'Source changed since the saved run; use -Update to start a new run.' }
        return $head
    }
    $null = Invoke-ReleaseCommand $Git @('-C', $Path, 'fetch', '--no-tags', 'origin', 'main')
    $null = Invoke-ReleaseCommand $Git @('-C', $Path, 'merge-base', '--is-ancestor', 'HEAD', 'origin/main')
    $null = Invoke-ReleaseCommand $Git @('-C', $Path, 'merge', '--ff-only', 'origin/main')
    return (Invoke-ReleaseCommand $Git @('-C', $Path, 'rev-parse', 'HEAD')).Trim()
}

function Test-ReleaseResult($State, [string]$Revision, [string]$Mode) {
    try {
        if ($State.revision -ne $Revision -or $State.mode -ne $Mode -or -not $State.report) { return $false }
        if (-not [IO.File]::Exists($State.report)) { return $false }
        if ((Get-FileHash -LiteralPath $State.report -Algorithm SHA256).Hash -ne $State.report_sha256) { return $false }
        $report = [IO.File]::ReadAllText($State.report) | ConvertFrom-Json
        $expected = 'BUILDS_CREATED_MANUAL_REVIEW_PENDING'
        if ($Mode -eq 'check') { $expected = 'GAME_CHECKS_PASSED_MANUAL_REVIEW_PENDING' }
        if ($report.source_commit -ne $Revision -or $report.state -ne $expected -or $report.source_tree_dirty) { return $false }
        if (@($report.checks).Count -eq 0) { return $false }
        foreach ($check in $report.checks) {
            if ($check.result -notin @('PASS', 'RECOVERED_IMPORT')) { return $false }
        }
        $directory = Split-Path $State.report -Parent
        $checksums = Join-Path $directory 'SHA256SUMS.txt'
        if (-not [IO.File]::Exists($checksums)) { return $false }
        $verified = @{}
        foreach ($line in [IO.File]::ReadAllLines($checksums)) {
            if ($line -notmatch '^([a-fA-F0-9]{64})  ([^/\\]+)$') { return $false }
            $hash = $Matches[1]; $name = $Matches[2]
            if ($name -in @('.', '..') -or $name.Contains(':')) { return $false }
            $path = Join-Path $directory $name
            if (-not [IO.File]::Exists($path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $hash) { return $false }
            $verified[$name] = $true
        }
        if (-not $verified.ContainsKey('release-report.json')) { return $false }
        foreach ($item in Get-ChildItem -LiteralPath $directory -File) {
            if ($item.Name -ne 'SHA256SUMS.txt' -and -not $verified.ContainsKey($item.Name)) { return $false }
        }
        foreach ($artifact in $report.artifacts) {
            if (-not $verified.ContainsKey($artifact.file)) { return $false }
        }
        return $true
    } catch { return $false }
}

function Find-ReleaseApp([string]$Name) {
    $app = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($app) { return $app.Source }
    return $null
}

function Require-ReleaseApp([string]$Name, [string]$Package) {
    $app = Find-ReleaseApp $Name
    if ($app) { return $app }
    $winget = Find-ReleaseApp 'winget'
    if (-not $winget) { throw "Install $Name ($Package), then run this same command again." }
    Invoke-ReleaseCommand $winget @('install', '--id', $Package, '--exact', '--source', 'winget', '--silent', '--accept-source-agreements', '--accept-package-agreements') | Out-Host
    $env:PATH = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:PATH
    $app = Find-ReleaseApp $Name
    if (-not $app) { throw "$Name installed; reopen PowerShell and run this same command again." }
    return $app
}

## Reads the KEY=value lines of the owner's signing file into this process only; values are never printed or written.
function Import-ReleaseSigning([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not [IO.File]::Exists($full)) { throw "Signing file not found: $full" }
    $values = @{}
    foreach ($line in [IO.File]::ReadAllLines($full)) {
        $text = $line.Trim()
        if (-not $text -or $text.StartsWith('#')) { continue }
        $at = $text.IndexOf('=')
        if ($at -lt 1) { throw 'Signing file lines must be KEY=value.' }
        $values[$text.Substring(0, $at).Trim()] = $text.Substring($at + 1).Trim().Trim('"').Trim("'")
    }
    $defaults = @{
        GODOT_ANDROID_KEYSTORE_RELEASE_PATH = Join-Path (Split-Path $full -Parent) 'tls-release.keystore'
        GODOT_ANDROID_KEYSTORE_RELEASE_USER = 'tls_release'
        GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $values['TLS_RELEASE_STOREPASS']
    }
    foreach ($name in $defaults.Keys) {
        $value = $defaults[$name]
        if ($values.ContainsKey($name)) { $value = $values[$name] }
        if (-not $value) { throw "Signing file gives no value for $name" }
        [Environment]::SetEnvironmentVariable($name, [string]$value, 'Process')
    }
    if (-not [IO.File]::Exists($env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH)) { throw 'Release keystore not found.' }
}

function Start-IgraRelease {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    if ($Repository -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$') { throw 'Repository must be owner/name.' }
    if ($CheckGame -and ($Android -or $DraftRelease)) { throw 'CheckGame cannot be combined with Android or DraftRelease.' }
    if ($SigningEnv) { Import-ReleaseSigning $SigningEnv }
    if ($Android -and -not $AndroidSdk) { $AndroidSdk = @((Join-Path $env:LOCALAPPDATA 'Android\Sdk'), 'C:\Android\Sdk') | Where-Object { [IO.Directory]::Exists($_) } | Select-Object -First 1 }
    if ($Android -and -not $JavaHome) { $JavaHome = Get-ChildItem -LiteralPath 'C:\Program Files\Eclipse Adoptium' -Directory -Filter 'jdk-17*' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
    if (-not $WorkRoot) { $WorkRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'IgraReleaseMain' }
    $WorkRoot = [IO.Path]::GetFullPath($WorkRoot)
    $null = [IO.Directory]::CreateDirectory($WorkRoot)
    $lockPath = Join-Path $WorkRoot 'run.lock'
    $lock = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $environment = @{}
    $variables = @('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_OBJECT_DIRECTORY', 'GIT_COMMON_DIR', 'GIT_ALTERNATE_OBJECT_DIRECTORIES', 'GIT_CONFIG_COUNT', 'GIT_CONFIG_PARAMETERS', 'GIT_TEMPLATE_DIR', 'PYTHONUTF8', 'PYTHONIOENCODING', 'PATH')
    foreach ($name in $variables) { $environment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
    try {
        foreach ($name in $variables | Where-Object { $_.StartsWith('GIT_') }) { [Environment]::SetEnvironmentVariable($name, $null, 'Process') }
        $env:PYTHONUTF8 = '1'; $env:PYTHONIOENCODING = 'utf-8'
        $git = Require-ReleaseApp 'git' 'Git.Git'
        $python = Require-ReleaseApp 'python' 'Python.Python.3.12'
        $null = Invoke-ReleaseCommand $python @('-c', 'import sys; assert sys.version_info >= (3,11), "Python 3.11 or newer required"')
        $null = Require-ReleaseApp 'ffmpeg' 'Gyan.FFmpeg'
        $statePath = Join-Path $WorkRoot 'run-state.json'
        $state = @{revision='';mode='';report='';report_sha256='';requirements_sha256='';repository=$Repository;signing_identity=''}
        if ([IO.File]::Exists($statePath)) {
            $saved = [IO.File]::ReadAllText($statePath) | ConvertFrom-Json
            foreach ($property in $saved.PSObject.Properties) { $state[$property.Name] = $property.Value }
            if ($state.repository -ne $Repository) { throw 'WorkRoot belongs to another repository.' }
        }
        $source = Join-Path $WorkRoot 'source'
        Write-Host 'Preparing main (saved source stays pinned unless -Update is supplied)...'
        $revision = Update-ReleaseCheckout $git $source ('https://github.com/' + $Repository + '.git') $state.revision ([bool]$Update)
        $mode = 'build'; if ($CheckGame) { $mode = 'check' }; if ($Android) { $mode = 'android' }
        $identity = ''
        if ($Android) {
            foreach ($key in @('GODOT_ANDROID_KEYSTORE_RELEASE_PATH', 'GODOT_ANDROID_KEYSTORE_RELEASE_USER', 'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD')) {
                if (-not [Environment]::GetEnvironmentVariable($key, 'Process')) { throw "Android requires existing signing environment: $key" }
            }
            if (-not $AndroidSdk -or -not $JavaHome) { throw 'Android requires -AndroidSdk and -JavaHome (JDK 17).' }
            $identity = (Get-FileHash -LiteralPath $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH -Algorithm SHA256).Hash + ':' + $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER + ':' + [IO.Path]::GetFullPath($AndroidSdk) + ':' + [IO.Path]::GetFullPath($JavaHome)
        }
        $reuse = $state.signing_identity -eq $identity -and (Test-ReleaseResult $state $revision $mode)
        $state.revision=$revision; $state.mode=$mode; $state.signing_identity=$identity
        if (-not $reuse) { $state.report=''; $state.report_sha256='' }
        Write-ReleaseJson $statePath $state
        if (-not $reuse) {
            $venv = Join-Path $WorkRoot 'venv'
            $venvPython = Join-Path $venv 'Scripts\python.exe'
            if (-not [IO.File]::Exists($venvPython)) {
                Invoke-ReleaseCommand $python @('-m', 'venv', $venv) | Out-Host
                $state.requirements_sha256=''
            }
            $requirements = Join-Path $source 'tools\release\requirements.txt'
            $requirementsHash = (Get-FileHash -LiteralPath $requirements -Algorithm SHA256).Hash
            $env:PATH = (Split-Path $venvPython -Parent) + ';' + $env:PATH
            if ($state.requirements_sha256 -ne $requirementsHash) {
                Invoke-ReleaseCommand $venvPython @('-m', 'pip', 'install', '--disable-pip-version-check', '-r', $requirements) | Out-Host
                $state.requirements_sha256=$requirementsHash; Write-ReleaseJson $statePath $state
            }
            $gitRoot = Split-Path (Split-Path $git -Parent) -Parent
            $bash = Join-Path $gitRoot 'bin\bash.exe'
            if (-not [IO.File]::Exists($bash)) { throw 'Git for Windows Bash is missing. Install the full Git for Windows distribution.' }
            $toolRoot = Join-Path $WorkRoot 'toolchain-4.7.2'
            $provision = @((Join-Path $source 'tools\release\provision.py'), '--root', $toolRoot)
            if ($CheckGame) { $provision += '--editor-only' }; if ($Android) { $provision += '--android' }
            Write-Host 'Verifying cached official toolchain; only missing downloads are fetched...'
            Invoke-ReleaseCommand $venvPython $provision | Out-Host
            $chain = [IO.File]::ReadAllText((Join-Path $toolRoot 'toolchain.json')) | ConvertFrom-Json
            $attempt = Join-Path $WorkRoot ('runs\' + $revision.Substring(0,12) + '-' + $mode + '-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,6))
            $state.attempt=$attempt; Write-ReleaseJson $statePath $state
            $arguments = @((Join-Path $source 'tools\release\pipeline.py'), '--source', $source, '--output', $attempt, '--godot', $chain.godot, '--templates', $chain.templates, '--bash', $bash, '--full-release')
            if ($CheckGame) { $arguments += '--verify-only' }
            if ($Android) { $arguments += @('--android-sdk', $AndroidSdk, '--java-home', $JavaHome, '--bundletool', $chain.bundletool) }
            Write-Host "Running complete verification. Live logs: $attempt\logs"
            Invoke-ReleaseCommand $venvPython $arguments | Out-Host
            $state.report = Join-Path $attempt 'artifacts\release-report.json'
            $state.report_sha256 = (Get-FileHash -LiteralPath $state.report -Algorithm SHA256).Hash
            if (-not (Test-ReleaseResult $state $revision $mode)) { throw 'Result or artifact verification failed; no release is accepted.' }
            Write-ReleaseJson $statePath $state
        } else { Write-Host 'Resumed: completed report and every artifact checksum verified.' }
        $artifactPath = Split-Path $state.report -Parent
        if ($DraftRelease) {
            $gh = Require-ReleaseApp 'gh' 'GitHub.cli'
            $null = Invoke-ReleaseCommand $gh @('auth', 'status', '--hostname', 'github.com')
            $tag = 'candidate-' + $revision.Substring(0,12) + '-' + $mode
            $existing = $null
            try { $existing = (Invoke-ReleaseCommand $gh @('release', 'view', $tag, '--repo', $Repository, '--json', 'url,isDraft,targetCommitish')) | ConvertFrom-Json } catch { }
            if ($existing) {
                if (-not $existing.isDraft -or $existing.targetCommitish -ne $revision) { throw 'Existing release does not match this draft source; it will not be changed.' }
                Write-Host ('Draft already exists: ' + $existing.url)
            }
            else {
                $notes = Join-Path $WorkRoot 'release-notes.md'
                [IO.File]::WriteAllText($notes, "Source: $revision`nFull automated checks passed. Physical-device, subjective audio/visual review, asset rights and store acceptance remain pending.`n", [Text.UTF8Encoding]::new($false))
                $releaseArguments = @('release', 'create', $tag, '--repo', $Repository, '--target', $revision, '--draft', '--title', 'Last Streetlight release candidate', '--notes-file', $notes)
                $releaseArguments += @([IO.Directory]::GetFiles($artifactPath))
                Invoke-ReleaseCommand $gh $releaseArguments | Out-Host
            }
        }
        Write-Host "COMPLETE: $artifactPath"
        Write-Host 'Manual review remains pending. Repeat to resume; use -Update to verify the newest main.'
    } finally {
        foreach ($name in $variables) { [Environment]::SetEnvironmentVariable($name, $environment[$name], 'Process') }
        $lock.Dispose()
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try { Start-IgraRelease } catch { Write-Error $_; exit 1 }
}
