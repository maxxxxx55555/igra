#requires -Version 5.1
<#
.SYNOPSIS
Preserve local work, prepare an isolated implementation branch, check it, and export or push it.
.DESCRIPTION
Requires an existing Git checkout and installed tools. This is an orchestration and
evidence script, not an asset generator or proof that a game is professionally finished.
Prepare never applies, stages, resets, commits, or cleans the owner's working tree.
Claude must recover/adapt the preserved changes, implement the companion prompt, and
commit the candidate before Verify. Full automated checks do not certify appearance,
audio, physical devices, signing, licensing, store acceptance, or release readiness.
Publish pushes only the integration branch. Review and CI on a PR are required for main.
No software, agent, signing key, or credential is installed or imported by this script.
Backups include committed history and local diffs; keep the run directory private.
.PARAMETER NoFetch
Prepare only: use cached origin/main and explicitly record STALE_OFFLINE. Publish always fetches.
.PARAMETER CheckSet
Static runs existing static, flow, and scene checks. Full also runs tools/check.sh --all.
Only a successful Full verification of the same committed source can export or publish.
.PARAMETER ExportFile
An absolute new artifact path outside both worktrees. Use an otherwise empty directory
so Godot cannot overwrite a neighboring .pck or other companion artifact.
.EXAMPLE
.\Igra-Release-Workflow.ps1 -Mode Prepare -RepoPath 'C:\Games\igra'
.EXAMPLE
.\Igra-Release-Workflow.ps1 -Mode Verify -RepoPath 'C:\Games\igra' -RunDirectory 'C:\Games\igra-release-runs\RUN_ID' -GodotPath 'C:\Tools\Godot.exe'
.EXAMPLE
.\Igra-Release-Workflow.ps1 -Mode Export -RepoPath 'C:\Games\igra' -RunDirectory 'C:\Games\igra-release-runs\RUN_ID' -GodotPath 'C:\Tools\Godot.exe' -ExportPreset 'Windows Desktop' -ExportFile 'C:\Builds\candidate-001\LastStreetlight.exe'
#>
[CmdletBinding()]
param(
    [ValidateSet('Prepare','Verify','Export','Publish')][string]$Mode = 'Prepare',
    [Parameter(Mandatory=$true)][string]$RepoPath,
    [string]$RunDirectory, [string]$OutputRoot,
    [string]$BashPath, [string]$PythonPath, [string]$GodotPath,
    [string]$ExportPreset, [string]$ExportFile,
    [ValidateSet('Static','Full')][string]$CheckSet = 'Full',
    [switch]$NoFetch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:WorkflowPath = $PSCommandPath
$script:LogRoot = $null
$script:State = $null
$script:StatePath = $null
$script:Commands = New-Object 'System.Collections.Generic.List[object]'
$script:Git = $null
$script:Utf8 = New-Object Text.UTF8Encoding($false)

function Full-Path([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'A required path is empty.' }
    $full = [IO.Path]::GetFullPath($Path)
    if ($full -eq [IO.Path]::GetPathRoot($full)) { return $full }
    return $full.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}
function Is-Within([string]$Child, [string]$Parent) {
    $comparison = [StringComparison]::Ordinal
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { $comparison = [StringComparison]::OrdinalIgnoreCase }
    $prefix = $Parent.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    return $Child.Equals($Parent, $comparison) -or $Child.StartsWith($prefix, $comparison)
}
function Assert-Separate([string]$A, [string]$B) {
    if ((Is-Within $A $B) -or (Is-Within $B $A)) { throw 'Source, candidate, and output locations must not contain one another.' }
}
function Assert-NoReparse([string]$Path) {
    $part = Full-Path $Path
    while ($part) {
        if (Test-Path -LiteralPath $part) {
            $item = Get-Item -LiteralPath $part -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'A selected path contains a symlink or reparse point; choose a real local directory.' }
        }
        $parent = [IO.Directory]::GetParent($part)
        if ($null -eq $parent) { break }
        $part = $parent.FullName
    }
}
function Write-Json([string]$Path, $Value) {
    $temp = $Path + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
    [IO.File]::WriteAllText($temp, ($Value | ConvertTo-Json -Depth 30), $script:Utf8)
    if ([IO.File]::Exists($Path)) {
        # Current .NET Framework rejects a null backup path; use a real one and remove it.
        $bak = $Path + '.' + [Guid]::NewGuid().ToString('N') + '.bak'
        [IO.File]::Replace($temp, $Path, $bak)
        [IO.File]::Delete($bak)
    }
    else { [IO.File]::Move($temp, $Path) }
}
function Save-State {
    if ($script:State -and $script:StatePath) {
        $script:State.updated_utc = [DateTime]::UtcNow.ToString('o')
        $script:State.release_status = 'NOT_READY'
        Write-Json $script:StatePath $script:State
    }
}
function File-Hash([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Text-Hash([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($script:Utf8.GetBytes($Text))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Native-Argument([AllowEmptyString()][string]$Value) {
    # Windows CRT argv quoting; also accepted by ProcessStartInfo on PS7 Unix.
    # Do not replace with PowerShell 5's native-call string joining or Invoke-Expression.
    $b = New-Object Text.StringBuilder
    $null = $b.Append('"'); $slashes = 0
    foreach ($c in $Value.ToCharArray()) {
        if ($c -eq '\') { $slashes++; continue }
        if ($c -eq '"') { $null = $b.Append(('\' * (2 * $slashes + 1))); $null = $b.Append('"') }
        else { $null = $b.Append(('\' * $slashes)); $null = $b.Append($c) }
        $slashes = 0
    }
    $null = $b.Append(('\' * (2 * $slashes))); $null = $b.Append('"')
    return $b.ToString()
}
function Safe-Log([string]$Text) {
    $text = [regex]::Replace($Text, '(?i)(https?://)[^\s/@]+(?::[^\s/@]*)?@', '$1[REDACTED]@')
    $text = [regex]::Replace($text, '(?im)((?:password|passwd|token|secret|authorization|api[_-]?key|private[_-]?key)\s*[=:]\s*)[^\r\n]+', '$1[REDACTED]')
    return [regex]::Replace($text, '(?i)\bBearer\s+\S+', 'Bearer [REDACTED]')
}
function Find-App([string]$Explicit, [string[]]$Names, [string]$Help) {
    if ($Explicit) {
        $full = Full-Path $Explicit
        if (-not [IO.File]::Exists($full)) { throw $Help }
        return $full
    }
    foreach ($name in $Names) {
        $app = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($app -and $app.Source -notmatch '[\\/]WindowsApps[\\/]') { return $app.Source }
    }
    throw $Help
}
function Invoke-Native([string]$Name, [string]$File, [string[]]$Arguments, [string]$Directory, [hashtable]$Environment = @{}, [switch]$AllowFailure) {
    $id = [Guid]::NewGuid().ToString('N').Substring(0,10)
    $record = [ordered]@{name=$Name; executable=$File; arguments=$Arguments; started_utc=[DateTime]::UtcNow.ToString('o'); exit_code=$null; status='RUNNING'; stdout_log=$null; stderr_log=$null; stdout_sha256=$null; stderr_sha256=$null}
    $p = New-Object Diagnostics.Process
    $p.StartInfo.FileName = $File
    $p.StartInfo.Arguments = (($Arguments | ForEach-Object { Native-Argument $_ }) -join ' ')
    $p.StartInfo.WorkingDirectory = $Directory
    $p.StartInfo.UseShellExecute = $false
    $p.StartInfo.CreateNoWindow = $true
    $p.StartInfo.RedirectStandardOutput = $true
    $p.StartInfo.RedirectStandardError = $true
    $p.StartInfo.StandardOutputEncoding = $script:Utf8
    $p.StartInfo.StandardErrorEncoding = $script:Utf8
    # Isolate Git's addressing from caller overrides without printing the environment.
    # Windows PowerShell 5.1 lazily materialises ProcessStartInfo.EnvironmentVariables:
    # the FIRST read of the property returns $null and only the second returns the
    # StringDictionary. Prime the getter once, then hold the dictionary in a local.
    # Calling .Remove() directly on the first-read property chain aborted every Git
    # call in the fixture harness ("You cannot call a method on a null-valued
    # expression"). The child environment stays explicit and identical otherwise.
    $null = $p.StartInfo.EnvironmentVariables
    $childEnv = $p.StartInfo.EnvironmentVariables
    if ($null -eq $childEnv) { throw 'Process environment dictionary is unavailable.' }
    foreach ($key in @('GIT_DIR','GIT_WORK_TREE','GIT_INDEX_FILE','GIT_OBJECT_DIRECTORY','GIT_COMMON_DIR','GIT_ALTERNATE_OBJECT_DIRECTORIES','GIT_CONFIG_COUNT','GIT_CONFIG_PARAMETERS')) {
        if ($childEnv.ContainsKey($key)) { $null = $childEnv.Remove($key) }
    }
    $childEnv['GIT_OPTIONAL_LOCKS'] = '0'
    $childEnv['GIT_TERMINAL_PROMPT'] = '0'
    $childEnv['GIT_PAGER'] = 'cat'
    foreach ($key in $Environment.Keys) { $childEnv[$key] = [string]$Environment[$key] }
    $stdout = ''; $stderr = ''; $code = -1
    try {
        $null = $p.Start()
        $outTask = $p.StandardOutput.ReadToEndAsync(); $errTask = $p.StandardError.ReadToEndAsync()
        $p.WaitForExit()
        $stdout = $outTask.GetAwaiter().GetResult(); $stderr = $errTask.GetAwaiter().GetResult(); $code = $p.ExitCode
        $record.exit_code = $code
        $record.status = 'FAIL'; if ($code -eq 0) { $record.status = 'PASS' }
    } catch { $record.status = 'ERROR'; $stderr = 'Process could not be started or captured. Check executable, permissions, and working directory.' }
    finally {
        $p.Dispose(); $record.completed_utc = [DateTime]::UtcNow.ToString('o')
        if ($script:LogRoot) {
            $stem = Join-Path $script:LogRoot ($Name + '-' + $id)
            $record.stdout_log = $stem + '.stdout.log'; $record.stderr_log = $stem + '.stderr.log'
            [IO.File]::WriteAllText($record.stdout_log, (Safe-Log $stdout), $script:Utf8)
            [IO.File]::WriteAllText($record.stderr_log, (Safe-Log $stderr), $script:Utf8)
            $record.stdout_sha256 = File-Hash $record.stdout_log; $record.stderr_sha256 = File-Hash $record.stderr_log
            Write-Json ($stem + '.command.json') $record
        }
        $script:Commands.Add([pscustomobject]$record)
    }
    if ($code -ne 0 -and -not $AllowFailure) { throw "$Name failed (exit $code). See this run's command logs; no success was recorded." }
    return [pscustomobject]@{ExitCode=$code; StdOut=$stdout; StdErr=$stderr; Record=[pscustomobject]$record}
}
function Git-Text([string]$Path, [string[]]$Arguments, [string]$Name = 'git-read') {
    return (Invoke-Native $Name $script:Git (@('-C',$Path) + $Arguments) $Path).StdOut
}
function Git-Root([string]$Path) {
    $root = Full-Path ((Git-Text $Path @('rev-parse','--show-toplevel')).Trim())
    if (-not (Is-Within $root (Full-Path $Path)) -or -not (Is-Within (Full-Path $Path) $root)) { throw 'RepoPath must name the repository root, not a subdirectory.' }
    return $root
}
function Is-Evidence([string]$Path) {
    return $Path.StartsWith('docs/artifacts/rc16/proofs/', [StringComparison]::Ordinal) -or
        $Path.Equals('docs/artifacts/rc16/launch_ledger.tsv', [StringComparison]::Ordinal) -or
        $Path.StartsWith('.qa_logs/', [StringComparison]::Ordinal)
}
function Assert-SourceClean([string]$Path) {
    $changed = Git-Text $Path @('diff','--name-only','--no-renames','--ignore-submodules=none','-z','HEAD','--')
    $untracked = Git-Text $Path @('ls-files','--others','--exclude-standard','-z')
    foreach ($name in (($changed + $untracked).Split([char]0))) {
        if ($name -and -not (Is-Evidence $name)) { throw 'Uncommitted source or untracked non-evidence files exist in the candidate. Review and commit them before verification.' }
    }
    if ((Git-Text $Path @('ls-files','--unmerged','-z')).Length -gt 0) { throw 'Resolve and commit merge conflicts first.' }
}
function Get-SourceFingerprint([string]$Path) {
    $entries = (Git-Text $Path @('ls-tree','-r','-z','--full-tree','HEAD')).Split([char]0)
    $kept = New-Object 'System.Collections.Generic.List[string]'
    foreach ($entry in $entries) {
        if (-not $entry) { continue }
        $tab = $entry.IndexOf("`t")
        if ($tab -lt 0) { throw 'Unexpected Git tree entry; fingerprint unavailable.' }
        if (-not (Is-Evidence $entry.Substring($tab + 1))) { $kept.Add($entry) }
    }
    # Git's tree order and raw paths are stable; modes and object IDs are included.
    return Text-Hash (($kept -join [string][char]0) + [char]0)
}
function Is-ExcludedBackup([string]$Path) {
    $parts = $Path.ToLowerInvariant().Split('/')
    $blocked = @('.git','.godot','.qa_logs','.venv','venv','node_modules','__pycache__','.mypy_cache','.pytest_cache','.ruff_cache','build','builds','dist','exports','export','logs','cache','.cache','.signing','signing','secrets','.secrets','credentials','.aws','.ssh','.azure','.kube','.android','.gradle')
    foreach ($part in $parts) { if ($blocked -contains $part) { return $true } }
    $leaf = $parts[-1]
    return $leaf -match '(^\.env($|\.)|^id_(rsa|ed25519)|^credentials|^service[-_]account|\.(pem|key|p12|pfx|jks|keystore|aab|apk|exe|msi|dmg|zip|7z|tar|gz|pyc)$)'
}
function Copy-Untracked([string]$Source, [string]$Destination) {
    $saved = New-Object 'System.Collections.Generic.List[object]'; $skipped = New-Object 'System.Collections.Generic.List[string]'
    $total = [long]0
    foreach ($rel in (Git-Text $Source @('ls-files','--others','--exclude-standard','-z')).Split([char]0)) {
        if (-not $rel) { continue }
        if (Is-ExcludedBackup $rel) { $skipped.Add($rel); continue }
        $path = Full-Path (Join-Path $Source $rel)
        if (-not (Is-Within $path $Source)) { throw 'Unsafe untracked path; original files were left untouched.' }
        Assert-NoReparse $path
        $item = Get-Item -LiteralPath $path -Force
        if ($item.PSIsContainer) { throw 'An untracked nested repository or directory was encountered. Preserve it separately; do not follow it automatically.' }
        $total += $item.Length
        if ($saved.Count -ge 5000 -or $item.Length -gt 134217728 -or $total -gt 536870912) { throw 'Untracked backup limit reached (5000 files, 128 MiB/file, 512 MiB total). Preserve large work separately and exclude caches with .git/info/exclude, then retry.' }
        $dest = Join-Path (Join-Path $Destination 'files') $rel
        $null = [IO.Directory]::CreateDirectory((Split-Path $dest -Parent))
        [IO.File]::Copy($path, $dest, $false)
        $hash = File-Hash $path
        if ((File-Hash $dest) -ne $hash) { throw 'Untracked backup hash mismatch; original files were left untouched.' }
        $saved.Add([pscustomobject]@{path=$rel; sha256=$hash; bytes=$item.Length})
    }
    Write-Json (Join-Path $Destination 'untracked-manifest.json') @{files=@($saved.ToArray()); excluded_paths=@($skipped.ToArray()); excluded_content_copied=$false}
    return @($saved.ToArray())
}
function Add-Handoff([string]$Source, [string]$BaseDirectory, [string]$Leaf) {
    $hash = File-Hash $Source; $folder = Join-Path $BaseDirectory ('v1-' + $hash.Substring(0,12))
    Assert-NoReparse $folder
    $null = [IO.Directory]::CreateDirectory($folder); $destination = Join-Path $folder $Leaf
    Assert-NoReparse $destination
    if ([IO.File]::Exists($destination)) {
        if ((File-Hash $destination) -ne $hash) {
            $folder = Join-Path $BaseDirectory ('v1-' + $hash.Substring(0,12) + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8))
            $null = [IO.Directory]::CreateDirectory($folder); $destination = Join-Path $folder $Leaf
        }
    }
    if (-not [IO.File]::Exists($destination)) { [IO.File]::Copy($Source, $destination, $false) }
    return [pscustomobject]@{path=$destination; sha256=$hash}
}

function Prepare-Run {
    if ($RunDirectory) { throw 'RunDirectory is for Verify, Export, and Publish. Prepare creates a unique run under OutputRoot.' }
    $repo = Git-Root (Full-Path $RepoPath); Assert-NoReparse $repo
    $head = (Git-Text $repo @('rev-parse','--verify','HEAD')).Trim()
    $runId = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,10)
    $parent = Split-Path $repo -Parent
    if (-not $OutputRoot) { $OutputRoot = Join-Path $parent 'igra-release-runs' }
    $output = Full-Path $OutputRoot; Assert-NoReparse $output; Assert-Separate $repo $output
    $candidate = Join-Path $parent ((Split-Path $repo -Leaf) + '.integration-' + $runId)
    Assert-Separate $candidate $output; Assert-NoReparse $candidate
    if (Test-Path -LiteralPath $candidate) { throw 'Candidate path already exists; nothing will be overwritten.' }
    $worktrees = Git-Text $repo @('worktree','list','--porcelain')
    foreach ($line in ($worktrees -split "`n")) {
        if ($line.StartsWith('worktree ')) {
            $worktreePath = $line.Substring(9).TrimEnd([char]13)
            Assert-Separate (Full-Path $worktreePath) $output
        }
    }
    $prompt = Join-Path (Split-Path $script:WorkflowPath -Parent) 'IGRA_FINAL_RELEASE_PROMPT.md'
    if (-not [IO.File]::Exists($prompt)) { throw 'Place IGRA_FINAL_RELEASE_PROMPT.md beside this workflow before Prepare.' }
    $run = Join-Path $output $runId
    $null = [IO.Directory]::CreateDirectory($run)
    $script:LogRoot = Join-Path $run 'logs'; $null = [IO.Directory]::CreateDirectory($script:LogRoot)
    $script:StatePath = Join-Path $run 'run-state.json'
    $branch = 'integration/igra-' + $runId
    $script:State = [ordered]@{schema_version=1; run_id=$runId; repo_path=$repo; candidate_path=$candidate; candidate_branch=$branch; baseline_commit=$null; original_head=$head; fetch_status='NOT_RUN'; release_status='NOT_READY'; phase='PREPARING'; created_utc=[DateTime]::UtcNow.ToString('o'); updated_utc=''; backups=@(); handoff=@(); verification=@{status='NOT_RUN'}; exports=@(); publication=@{status='NOT_PUBLISHED'}; last_error=$null}
    Save-State
    $backup = Join-Path $run 'backup'; $null = [IO.Directory]::CreateDirectory($backup)
    $untracked = Join-Path $backup 'untracked'; $null = [IO.Directory]::CreateDirectory($untracked)
    Write-Host 'Preserving committed history and local changes; the original checkout stays in place.'
    $null = Git-Text $repo @('bundle','create',(Join-Path $backup 'HEAD.bundle'),'HEAD') 'backup-head'
    $null = Git-Text $repo @('bundle','verify',(Join-Path $backup 'HEAD.bundle')) 'verify-backup'
    # Git writes binary-capable patches directly; never pass patch bytes through PS redirection.
    # Precompute the --output argument: a '+' inside an array literal splits into two elements.
    $unstagedPatch = Join-Path $backup 'unstaged.patch'
    $stagedPatch = Join-Path $backup 'staged.patch'
    $null = Git-Text $repo @('diff','--binary','--full-index','--no-ext-diff','--no-textconv',"--output=$unstagedPatch",'--') 'backup-unstaged'
    $null = Git-Text $repo @('diff','--cached','--binary','--full-index','--no-ext-diff','--no-textconv',"--output=$stagedPatch",'--') 'backup-staged'
    $metadata = [ordered]@{head=$head; refs=(Git-Text $repo @('for-each-ref','--format=%(refname) %(objectname)')); status=(Git-Text $repo @('status','--porcelain=v1','-z','--untracked-files=all')); worktrees=$worktrees; branches=(Git-Text $repo @('branch','--all','--no-color')); scope='HEAD history, staged/unstaged patches, and bounded nonignored untracked files. Exclusions remain in the original checkout.'}
    Write-Json (Join-Path $backup 'metadata.json') $metadata
    $null = Copy-Untracked $repo $untracked
    foreach ($file in Get-ChildItem -LiteralPath $backup -File) { $script:State.backups += @{path=$file.FullName; sha256=(File-Hash $file.FullName)} }
    $script:State.backups += @{path=(Join-Path $untracked 'untracked-manifest.json'); sha256=(File-Hash (Join-Path $untracked 'untracked-manifest.json'))}
    Save-State
    if ($NoFetch) { $script:State.fetch_status = 'STALE_OFFLINE' }
    else {
        $null = Git-Text $repo @('fetch','--no-prune','--no-tags','origin','+refs/heads/*:refs/remotes/origin/*') 'fetch-origin'
        $script:State.fetch_status = 'FRESH'
    }
    $baseline = (Git-Text $repo @('rev-parse','--verify','refs/remotes/origin/main^{commit}')).Trim()
    $script:State.baseline_commit = $baseline
    [IO.File]::WriteAllText((Join-Path $run 'branches-after-fetch.txt'), (Git-Text $repo @('branch','--all','--no-color')), $script:Utf8)
    $null = Git-Text $repo @('worktree','add','-b',$branch,$candidate,$baseline) 'create-candidate'
    $script:State.handoff = @(
        (Add-Handoff $prompt (Join-Path $candidate 'docs/release') 'IGRA_FINAL_RELEASE_PROMPT.md'),
        (Add-Handoff $script:WorkflowPath (Join-Path $candidate 'tools/release/owner_handoff') 'Igra-Release-Workflow.ps1')
    )
    $script:State.phase = 'IMPLEMENTATION_REQUIRED'; Save-State
    $instructions = @"
NOT_READY. Fetch status: $($script:State.fetch_status)
Original checkout: $repo
Candidate checkout: $candidate
Expected branch: $branch
Baseline origin/main: $baseline
Backups: $backup
Prompt: $($script:State.handoff[0].path)
Open only the candidate in Claude. Read the prompt and repository instructions.
Inventory all branches; inspect and recover/adapt relevant owner diffs from the backup.
Do not apply patches blindly or copy secrets/caches. Excluded files remain at the original.
Implement and review the actual game and licensed assets; commit source and handoff files.
Then run Verify -CheckSet Full using this run directory. Review and commit generated
evidence before Publish. Evidence-only commits preserve the source fingerprint.
Static checks, exports, and branch pushes never mean the game is ready for release.
"@
    [IO.File]::WriteAllText((Join-Path $run 'NEXT_STEPS.txt'), $instructions, $script:Utf8)
    Write-Host "Prepared candidate: $candidate"
    Write-Host "RunDirectory: $run"
    Write-Host "State: NOT_READY / IMPLEMENTATION_REQUIRED / $($script:State.fetch_status)"
}

function Load-Run {
    if (-not $RunDirectory) { throw 'Specify the RunDirectory printed by Prepare.' }
    if ($OutputRoot -or $NoFetch) { throw 'OutputRoot and NoFetch are Prepare-only options.' }
    $run = Full-Path $RunDirectory; Assert-NoReparse $run
    $stateFile = Join-Path $run 'run-state.json'
    if (-not [IO.File]::Exists($stateFile)) { throw 'run-state.json is missing. Use a completed Prepare run.' }
    $loaded = [IO.File]::ReadAllText($stateFile) | ConvertFrom-Json
    $state = [ordered]@{}; foreach ($property in $loaded.PSObject.Properties) { $state[$property.Name] = $property.Value }
    if ($state.schema_version -ne 1 -or $state.run_id -notmatch '^\d{8}-\d{6}-[a-f0-9]{10}$' -or $state.run_id -ne (Split-Path $run -Leaf)) { throw 'Invalid run identity.' }
    $repo = Git-Root (Full-Path $RepoPath); Assert-NoReparse $repo
    if ((Full-Path $state.repo_path) -ne $repo) { throw 'RunDirectory belongs to a different RepoPath.' }
    $candidate = Full-Path $state.candidate_path
    $expected = Join-Path (Split-Path $repo -Parent) ((Split-Path $repo -Leaf) + '.integration-' + $state.run_id)
    if ($candidate -ne $expected -or $state.candidate_branch -cne ('integration/igra-' + $state.run_id)) { throw 'Candidate identity does not match this run.' }
    Assert-NoReparse $candidate; Assert-Separate $candidate $run; Assert-Separate $repo $run
    $null = Git-Root $candidate
    $originalCommon = (Git-Text $repo @('rev-parse','--git-common-dir')).Trim()
    $candidateCommon = (Git-Text $candidate @('rev-parse','--git-common-dir')).Trim()
    if (-not [IO.Path]::IsPathRooted($originalCommon)) { $originalCommon = Join-Path $repo $originalCommon }
    if (-not [IO.Path]::IsPathRooted($candidateCommon)) { $candidateCommon = Join-Path $candidate $candidateCommon }
    $originalCommon = Full-Path $originalCommon; $candidateCommon = Full-Path $candidateCommon
    if ($originalCommon -ne $candidateCommon) { throw 'Candidate is not a worktree of the selected repository.' }
    if ((Git-Text $candidate @('symbolic-ref','--short','HEAD')).Trim() -cne $state.candidate_branch) { throw 'Candidate is on the wrong branch. No branch will be switched automatically.' }
    $script:LogRoot = Join-Path $run 'logs'; $null = [IO.Directory]::CreateDirectory($script:LogRoot)
    $script:StatePath = $stateFile; $script:State = $state
    return $candidate
}
function Resolve-Bash {
    if ($BashPath) { return Find-App $BashPath @() 'BashPath does not exist. Use Git for Windows bin\bash.exe.' }
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        $gitBase = Split-Path (Split-Path $script:Git -Parent) -Parent
        foreach ($path in @((Join-Path $gitBase 'bin/bash.exe'), (Join-Path $gitBase 'usr/bin/bash.exe'))) { if ([IO.File]::Exists($path)) { return $path } }
        throw 'Git Bash was not found. Supply -BashPath to Git for Windows bin\bash.exe (not the WSL launcher).'
    }
    return Find-App '' @('bash') 'Install Bash separately or supply BashPath.'
}
function Gate-Environment([string]$Python, [string]$Godot = '') {
    $environment = @{PY=$Python.Replace('\','/'); PYTHONUTF8='1'; PYTHONIOENCODING='utf-8'; TLS_SKIP_REIMPORT='0'}
    if ($Godot) { $environment.GODOT = $Godot.Replace('\','/') }
    return $environment
}
function Assert-RequiredFiles([string]$Candidate) {
    foreach ($file in @('project.godot','tools/check.sh','tools/flow_check.py','tools/scene_node_check.py')) {
        if (-not [IO.File]::Exists((Join-Path $Candidate $file))) { throw "Required gate/project file missing: $file. Restore the repository's real checks; do not substitute passing stubs." }
    }
}
function Check-Skips([string]$Output, [bool]$AllowHeadless) {
    $clean = [regex]::Replace($Output, '\x1b\[[0-9;]*[A-Za-z]', '')
    foreach ($line in ($clean -split "`n")) {
        if ($line -notmatch '(?i)\bSKIP(?:PED)?\b|\u043f\u0440\u043e\u043f\u0443\u0441\u043a') { continue }
        # Inspected check.sh prints these two known exit-3 gates with these labels.
        # They remain SKIPPED and cannot establish visual/audio/device acceptance.
        if ($AllowHeadless -and $line -match '(draw calls|Music bus)' -and $line -match '--windowed') {
            $script:State.verification.skipped_checks += @{status='SKIPPED'; scope='MANUAL_WINDOWED_REQUIRED'; detail=(Safe-Log $line.Trim())}
        } else {
            $script:Commands[$script:Commands.Count - 1].status = 'INCOMPLETE'
            throw 'Suite reported an unexpected skipped check. Resolve prerequisites or inspect the logs; skipped checks are not passes.'
        }
    }
}
function Verify-Run([string]$Candidate) {
    $script:State.verification = @{status='RUNNING'; check_set=$CheckSet; head=$null; source_fingerprint=$null; commands=@(); skipped_checks=@(); manual_checks=@('NOT_TESTED: windowed appearance and rendered performance','NOT_TESTED: audible output and subjective audio','NOT_TESTED: physical devices, signing, asset rights, store acceptance')}
    $script:State.phase = 'VERIFYING'; Save-State
    $start = $script:Commands.Count
    try {
        Assert-SourceClean $Candidate; Assert-RequiredFiles $Candidate
        $fingerprint = Get-SourceFingerprint $Candidate
        $head = (Git-Text $Candidate @('rev-parse','HEAD')).Trim()
        $bash = Resolve-Bash
        $python = Find-App $PythonPath @('python3','python','py') 'Python 3.10+ was not found. Install it separately or specify -PythonPath.'
        $godot = ''
        if ($CheckSet -eq 'Full') { $godot = Find-App $GodotPath @('godot4','godot') 'Full verification needs an installed Godot and export-compatible version. Supply -GodotPath; nothing will be downloaded.' }
        $environment = Gate-Environment $python $godot
        $null = Invoke-Native 'python-prerequisites' $python @('-c','import sys, importlib.util; assert sys.version_info >= (3,10), "Python 3.10+ required"; import numpy, PIL; assert importlib.util.find_spec("ruff") or importlib.util.find_spec("pyflakes"), "Install the repository lint dependencies (ruff or pyflakes) separately"') $Candidate $environment
        $null = Invoke-Native 'bash-prerequisites' $bash @('--noprofile','--norc','-c','export PATH="/usr/bin:/bin:$PATH"; for tool in bash git timeout ffmpeg; do command -v "$tool" >/dev/null || { printf "Missing prerequisite: %s\n" "$tool" >&2; exit 1; }; done') $Candidate $environment
        if ($godot) { $null = Invoke-Native 'godot-version' $godot @('--version') $Candidate $environment }
        Write-Host 'Running repository static, flow, and scene checks. Results are recorded separately.'
        $static = Invoke-Native 'gate-static' $bash @('--noprofile','--norc','-c','export PATH="/usr/bin:/bin:$PATH"; exec bash tools/check.sh "$1"','igra-workflow','--static') $Candidate $environment
        Check-Skips ($static.StdOut + $static.StdErr) $false
        $null = Invoke-Native 'gate-flow' $python @('tools/flow_check.py') $Candidate $environment
        $null = Invoke-Native 'gate-scene' $python @('tools/scene_node_check.py') $Candidate $environment
        if ($CheckSet -eq 'Full') {
            Write-Host 'Running tools/check.sh --all. Headless checks do not measure real audio or rendered device performance.'
            $full = Invoke-Native 'gate-full' $bash @('--noprofile','--norc','-c','export PATH="/usr/bin:/bin:$PATH"; exec bash tools/check.sh "$1"','igra-workflow','--all') $Candidate $environment
            Check-Skips ($full.StdOut + $full.StdErr) $true
        }
        Assert-SourceClean $Candidate
        if ((Get-SourceFingerprint $Candidate) -ne $fingerprint) { throw 'The committed source changed during verification. Run Verify again.' }
        if ((Git-Text $Candidate @('symbolic-ref','--short','HEAD')).Trim() -cne $script:State.candidate_branch) { throw 'Candidate branch changed during verification.' }
        $script:State.verification.status = 'PASS'; $script:State.verification.head = $head
        $script:State.verification.source_fingerprint = $fingerprint
        $script:State.verification.completed_utc = [DateTime]::UtcNow.ToString('o')
        $script:State.phase = 'AUTOMATED_CHECKS_PASSED_MANUAL_REVIEW_PENDING'
    } catch { $script:State.verification.status = 'FAIL'; $script:State.phase = 'VERIFY_FAILED'; throw }
    finally { $script:State.verification.commands = @($script:Commands.ToArray() | Select-Object -Skip $start); Save-State }
    Write-Host "Verification: $CheckSet PASS (automated scope only). Release state: NOT_READY."
}
function Require-FullVerification([string]$Candidate) {
    Assert-SourceClean $Candidate
    $v = $script:State.verification
    if ($v.status -ne 'PASS' -or $v.check_set -ne 'Full') { throw 'A successful Verify -CheckSet Full is required first.' }
    if ((Get-SourceFingerprint $Candidate) -ne $v.source_fingerprint) {
        $script:State.verification.status = 'INVALIDATED'; Save-State
        throw 'Source fingerprint changed. Run Full Verify on the current committed source.'
    }
    foreach ($name in @('python-prerequisites','bash-prerequisites','godot-version','gate-static','gate-flow','gate-scene','gate-full')) {
        $records = @($v.commands | Where-Object { $_.name -eq $name })
        if ($records.Count -ne 1 -or $records[0].status -ne 'PASS' -or $records[0].exit_code -ne 0) { throw 'Full verification has a missing or unsuccessful required command.' }
        foreach ($kind in @('stdout','stderr')) {
            $path = $records[0].($kind + '_log'); $hash = $records[0].($kind + '_sha256')
            if (-not (Is-Within (Full-Path $path) (Full-Path $script:LogRoot)) -or -not [IO.File]::Exists($path) -or (File-Hash $path) -ne $hash) { throw 'Verification log is missing, moved, or changed. Run Full Verify again.' }
        }
    }
}
function Export-Run([string]$Candidate) {
    Require-FullVerification $Candidate
    if (-not $GodotPath -or -not $ExportPreset -or -not $ExportFile) { throw 'Export requires explicit -GodotPath, -ExportPreset, and -ExportFile.' }
    if (-not [IO.Path]::IsPathRooted($ExportFile)) { throw 'ExportFile must be an absolute path.' }
    $godot = Find-App $GodotPath @() 'GodotPath must name the installed Godot executable.'
    $artifact = Full-Path $ExportFile; Assert-NoReparse $artifact
    Assert-Separate $artifact $Candidate; Assert-Separate $artifact $script:State.repo_path
    $folder = Split-Path $artifact -Parent
    Assert-Separate $folder $Candidate; Assert-Separate $folder $script:State.repo_path
    if (Test-Path -LiteralPath $folder) {
        if (@(Get-ChildItem -LiteralPath $folder -Force).Count -ne 0) { throw 'Export destination must be an empty directory; existing artifacts and companion files will not be overwritten.' }
    } else { $null = [IO.Directory]::CreateDirectory($folder) }
    if (-not [IO.File]::Exists((Join-Path $Candidate 'export_presets.cfg'))) { throw 'export_presets.cfg is missing. Configure the named preset in the candidate first.' }
    $python = Find-App $PythonPath @('python3','python','py') 'Supply the PythonPath used for verification.'
    $environment = Gate-Environment $python $godot
    $entry = [ordered]@{status='FAILED'; source_fingerprint=$script:State.verification.source_fingerprint; head=(Git-Text $Candidate @('rev-parse','HEAD')).Trim(); preset=$ExportPreset; file=$artifact; sha256=$null; files=@(); command=$null; reference_check='NOT_RUN'; signing='NOT_VERIFIED'; devices='NOT_VERIFIED'}
    try {
        # Inspected repository contract: --preset checks all platforms; --bundle understands Android AAB layout only.
        $refs = Join-Path $Candidate 'tools/qa_sim/export_refs_check.py'
        if (-not [IO.File]::Exists($refs)) { throw 'The repository export_refs_check.py is required; restore its real implementation.' }
        $null = Invoke-Native 'export-references-preset' $python @('tools/qa_sim/export_refs_check.py','--preset',$ExportPreset) $Candidate $environment
        $result = Invoke-Native 'godot-export-release' $godot @('--headless','--path',$Candidate,'--export-release',$ExportPreset,$artifact) $Candidate $environment
        $entry.command = $result.Record
        if (-not [IO.File]::Exists($artifact) -or (Get-Item -LiteralPath $artifact).Length -eq 0) { throw 'Godot did not produce a nonempty requested artifact.' }
        $entry.sha256 = File-Hash $artifact; $entry.reference_check = 'PRESET_PASS'
        if ([IO.Path]::GetExtension($artifact) -ieq '.aab') {
            $null = Invoke-Native 'export-references-aab' $python @('tools/qa_sim/export_refs_check.py','--preset',$ExportPreset,'--bundle',$artifact) $Candidate $environment
            $entry.reference_check = 'PRESET_AND_AAB_PASS'
        }
        Assert-SourceClean $Candidate
        if ((Get-SourceFingerprint $Candidate) -ne $entry.source_fingerprint) { $script:State.verification.status = 'INVALIDATED'; throw 'Export changed the committed source; rerun Full Verify.' }
        foreach ($file in Get-ChildItem -LiteralPath $folder -File -Recurse) { Assert-NoReparse $file.FullName; $entry.files += @{path=$file.FullName; sha256=(File-Hash $file.FullName); bytes=$file.Length} }
        $entry.status = 'CANDIDATE'; $script:State.phase = 'EXPORTED_CANDIDATE_MANUAL_REVIEW_PENDING'
    } finally { $script:State.exports += [pscustomobject]$entry; Save-State }
    Write-Host "Exported candidate: $artifact"
    Write-Host 'Export state: CANDIDATE. Signing/device checks remain NOT_VERIFIED; release state remains NOT_READY.'
}
function Publish-Run([string]$Candidate) {
    Require-FullVerification $Candidate
    if ((Git-Text $Candidate @('status','--porcelain=v1','-z','--untracked-files=all','--ignore-submodules=none')).Length -gt 0) { throw 'Publish requires all source, handoff, and evidence changes committed. Nothing will be staged automatically.' }
    $null = Git-Text $Candidate @('fetch','--no-prune','--no-tags','origin','+refs/heads/*:refs/remotes/origin/*') 'publish-fetch-origin'
    $main = (Git-Text $Candidate @('rev-parse','--verify','refs/remotes/origin/main^{commit}')).Trim()
    $null = Git-Text $Candidate @('merge-base','--is-ancestor',$main,'HEAD') 'check-main-ancestor'
    Require-FullVerification $Candidate
    if ((Git-Text $Candidate @('symbolic-ref','--short','HEAD')).Trim() -cne $script:State.candidate_branch) { throw 'Candidate branch changed; refusing push.' }
    $head = (Git-Text $Candidate @('rev-parse','HEAD')).Trim(); $branch = $script:State.candidate_branch
    $null = Git-Text $Candidate @('push','--no-follow-tags','origin',('HEAD:refs/heads/' + $branch)) 'push-integration-branch'
    $remote = (Git-Text $Candidate @('ls-remote','--exit-code','origin',('refs/heads/' + $branch)) 'verify-remote-branch').Trim()
    if ($remote -notmatch ('^' + [regex]::Escape($head) + '\s+refs/heads/' + [regex]::Escape($branch) + '$')) { throw 'Remote branch verification failed. Inspect the remote; no retry or force push was attempted.' }
    $script:State.publication = @{status='BRANCH_PUSHED'; branch=$branch; head=$head; origin_main=$main; utc=[DateTime]::UtcNow.ToString('o')}
    $script:State.phase = 'PR_REVIEW_REQUIRED'; Save-State
    Write-Host "Pushed integration branch: $branch"
    Write-Host 'Open a PR, run required CI, and review it before merging main. No tag or public release was created. State: NOT_READY.'
}
function Start-Workflow {
    $script:Git = Find-App '' @('git') 'Git is required. Install Git separately and reopen PowerShell.'
    if ($Mode -eq 'Prepare') { Prepare-Run; return }
    $candidate = Load-Run
    $lock = $null
    try {
        $lock = [IO.File]::Open((Join-Path (Full-Path $RunDirectory) 'workflow.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        switch ($Mode) {
            'Verify' { Verify-Run $candidate }
            'Export' { Export-Run $candidate }
            'Publish' { Publish-Run $candidate }
        }
    } finally { if ($lock) { $lock.Dispose() } }
}
if ($MyInvocation.InvocationName -ne '.') {
    try { Start-Workflow }
    catch {
        if ($script:State) { $script:State.last_error = Safe-Log $_.Exception.Message; Save-State }
        Write-Error (Safe-Log $_.Exception.Message)
        exit 1
    }
}
