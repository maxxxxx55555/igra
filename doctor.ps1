# ============================================================================
# doctor.ps1 -- THE_LAST_STREETLIGHT (STANDALONE, идемпотентный)
#   powershell -ExecutionPolicy Bypass -File doctor.ps1
#   если godot не найден:
#   powershell -ExecutionPolicy Bypass -File doctor.ps1 -GodotExe "C:\путь\Godot_v4.7-stable_win64_console.exe"
# ============================================================================
param(
	[string]$GodotExe = ''
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$utf8 = New-Object System.Text.UTF8Encoding($false)

# ----------------------------- counters -----------------------------------
$script:FilesWritten = 0
$script:StubsCreated = 0
$script:AutoloadsVerified = 0
$script:AutoloadsFixed = 0
$script:SceneRefsFixed = 0
$script:BusSignalsAdded = 0
$script:CompileStatus = 'UNKNOWN'
$script:BadParse = @()

# ----------------------------- helpers ------------------------------------
function Write-Utf8([string]$rel, [string]$content) {
	$full = Join-Path $root $rel
	$dir = Split-Path -Parent $full
	if ($dir -and -not (Test-Path $dir)) { [void](New-Item -ItemType Directory -Force -Path $dir) }
	[System.IO.File]::WriteAllText($full, $content, $utf8)
	Write-Host ('WROTE    ' + $rel)
	$script:FilesWritten++
}

function Ensure-Dir([string]$rel) {
	$full = Join-Path $root $rel
	if (-not (Test-Path $full)) {
		[void](New-Item -ItemType Directory -Force -Path $full)
		Write-Host ('MKDIR    ' + $rel)
	}
}

function Read-Utf8([string]$rel) {
	$full = Join-Path $root $rel
	if (Test-Path $full) { return [System.IO.File]::ReadAllText($full, $utf8) }
	return $null
}

function Resolve-Godot() {
	if ($GodotExe -and (Test-Path $GodotExe)) { return (Resolve-Path $GodotExe).Path }
	foreach ($n in @('godot', 'Godot_v4.7-stable_win64_console.exe')) {
		$g = Get-Command $n -ErrorAction SilentlyContinue
		if ($g) { return $g.Source }
	}
	$d = $root
	for ($i = 0; $i -lt 6; $i++) {
		foreach ($sub in @('', 'Godot', 'godot', 'tools')) {
			$sd = if ($sub) { Join-Path $d $sub } else { $d }
			if (-not (Test-Path $sd)) { continue }
			$hit = Get-ChildItem -Path $sd -Filter 'Godot_*_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
			if (-not $hit) { $hit = Get-ChildItem -Path $sd -Filter 'Godot*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1 }
			if ($hit) { return $hit.FullName }
		}
		$parent = Split-Path $d -Parent
		if (-not $parent -or $parent -eq $d) { break }
		$d = $parent
	}
	return $null
}

function Invoke-Godot([string[]]$gargs) {
	$godot = Resolve-Godot
	if (-not $godot) { return 'NO_GODOT' }
	$full = @('--headless', '--path', $root) + $gargs
	$tmpOut = Join-Path $root '.doctor_out.tmp'
	$tmpErr = Join-Path $root '.doctor_err.tmp'
	[void](Start-Process -FilePath $godot -ArgumentList $full -NoNewWindow -PassThru -Wait `
		-RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr)
	$out = ''
	if (Test-Path $tmpOut) { $out += [System.IO.File]::ReadAllText($tmpOut, $utf8) }
	if (Test-Path $tmpErr) { $out += [System.IO.File]::ReadAllText($tmpErr, $utf8) }
	Remove-Item $tmpOut, $tmpErr -ErrorAction SilentlyContinue
	return $out
}

# ============================================================================
Write-Host '================== DOCTOR =================='
Write-Host ('Root  : ' + $root)
Ensure-Dir 'scripts'
Ensure-Dir 'scenes'
Ensure-Dir 'audio'
Ensure-Dir 'tools'

# ---- PHASE 1: parse audit -------------------------------------------------
Write-Host '---- PHASE 1  audit parse ----'
$checkOut = Invoke-Godot @('--check-only', '--quit')
if ($checkOut -eq 'NO_GODOT') {
	Write-Host 'SKIP    godot not found'
} else {
	$curFile = ''
	foreach ($ln in ($checkOut -split "`r?`n")) {
		if ($ln -match '^(res://[^\s:]+\.gd):') { $curFile = $Matches[1]; continue }
		if ($ln -match 'Parse Error|Parse error|SCRIPT ERROR') { $script:BadParse += ("$curFile : $ln".Trim()) }
	}
	Write-Host ('PARSE   ' + $script:BadParse.Count + ' issue(s)')
	foreach ($b in $script:BadParse) { Write-Host ('  - ' + $b) }
}

# ---- PHASE 2: indent audit (report only) ----------------------------------
Write-Host '---- PHASE 2  indent audit ----'
$tabIssues = @()
$gdFiles = Get-ChildItem -Path (Join-Path $root 'scripts') -Recurse -Filter '*.gd' -ErrorAction SilentlyContinue
foreach ($f in $gdFiles) {
	$lines = [System.IO.File]::ReadAllLines($f.FullName)
	for ($i = 0; $i -lt $lines.Count; $i++) {
		if ($lines[$i].Length -gt 0 -and $lines[$i][0] -eq ' ' -and $lines[$i] -match '^(    )+\S') {
			$tabIssues += ($f.FullName.Substring($root.Length + 1) + ':' + ($i + 1)); break
		}
	}
}
Write-Host ('INDENT  ' + $tabIssues.Count + ' file(s) with spaces (report only)')

# ---- PHASE 3: autoload audit + stubs --------------------------------------
Write-Host '---- PHASE 3  autoload audit ----'
$pf = Read-Utf8 'project.godot'
if ($pf -eq $null) { Write-Host 'FATAL   project.godot missing'; exit 9 }
$alBlock = ''
if ($pf -match '(?s)\[autoload\]\s*\r?\n(.*?)(?=\r?\n\[|$)') { $alBlock = $Matches[1] }
foreach ($ln in ($alBlock -split "`r?`n")) {
	if ($ln -notmatch '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"?\*?([^"]*)"?') { continue }
	$name = $Matches[1]
	$p = $Matches[2] -replace '^\*', '' -replace '^res://', ''
	$full = Join-Path $root $p
	if (Test-Path $full) {
		Write-Host ('OK     ' + $name + ' -> ' + $p)
		$script:AutoloadsVerified++
	} else {
		Write-Host ('MISS   ' + $name + ' -> ' + $p + '  (creating stub)')
		$stub = "extends Node`n## AUTO-GENERATED stub for $name (doctor.ps1)`n`nfunc _ready() -> void:`n`tpass`n"
		Write-Utf8 $p $stub
		$script:StubsCreated++
		$script:AutoloadsFixed++
	}
}

# ---- PHASE 3B: EventBus missing signals ------------------------------------
Write-Host '---- PHASE 3B event bus patch ----'
$busPath = $null
if ($pf -match 'EventBus\s*=\s*"\*?res://([^"]+)"') { $busPath = Join-Path $root ($Matches[1] -replace '/', '\') }
if (-not $busPath -or -not (Test-Path $busPath)) {
	foreach ($c in @('scripts\events\event_bus.gd', 'scripts\event_bus.gd')) {
		$p2 = Join-Path $root $c
		if (Test-Path $p2) { $busPath = $p2; break }
	}
}
if (-not $busPath -or -not (Test-Path $busPath)) {
	Write-Host 'WARN    event_bus.gd not found, skip'
} else {
	$sigMap = [ordered]@{
		enemy_killed = 'signal enemy_killed(monster_id: StringName)'
		enemy_spawned = 'signal enemy_spawned(enemy: Node3D)'
		enemy_died = 'signal enemy_died(position: Vector3)'
		enemy_attack = 'signal enemy_attack(damage: int)'
		enemy_hp_updated = 'signal enemy_hp_updated(monster_id: StringName, hp: float)'
		player_died = 'signal player_died'
		player_damaged = 'signal player_damaged(amount: float)'
		player_health_changed = 'signal player_health_changed(health: float)'
		player_stamina_changed = 'signal player_stamina_changed(stamina: float)'
		player_battery_changed = 'signal player_battery_changed(level: float)'
		player_state_changed = 'signal player_state_changed(state: String)'
		player_stealth_changed = 'signal player_stealth_changed(stealth: float)'
		player_detected = 'signal player_detected'
		player_hiding_changed = 'signal player_hiding_changed(hiding: bool)'
		player_interact_available = 'signal player_interact_available(available: bool)'
		item_picked_up = 'signal item_picked_up(item_data: Resource)'
		item_consumed = 'signal item_consumed(item_id: String)'
		inventory_changed = 'signal inventory_changed'
		inventory_weight_changed = 'signal inventory_weight_changed(weight: float)'
		inventory_notice = 'signal inventory_notice(message: String)'
		inventory_toggle_requested = 'signal inventory_toggle_requested'
		health_changed = 'signal health_changed(new_health: int)'
		ammo_changed = 'signal ammo_changed(current: int, max: int)'
		quest_updated = 'signal quest_updated(quest_id: String)'
		quest_completed = 'signal quest_completed(quest_id: String)'
		coin_changed = 'signal coin_changed(amount: int)'
		coins_changed = 'signal coins_changed(amount: int)'
		district_entered = 'signal district_entered(district_id: StringName)'
		district_powered = 'signal district_powered(district_id: StringName)'
		district_blackout = 'signal district_blackout(district_id: StringName)'
		district_restored = 'signal district_restored(district_id: StringName)'
		district_stage_changed = 'signal district_stage_changed(district_id: StringName, stage: int)'
		streetlight_activated = 'signal streetlight_activated(streetlight_id: String)'
		light_level_changed = 'signal light_level_changed(level: float)'
		light_disrupted = 'signal light_disrupted'
		flashlight_toggled = 'signal flashlight_toggled(on: bool)'
		flashlight_changed = 'signal flashlight_changed(state: bool)'
		flashlight_depleted = 'signal flashlight_depleted'
		flashlight_state_changed = 'signal flashlight_state_changed(on: bool)'
		game_saved = 'signal game_saved'
		game_loaded = 'signal game_loaded'
		game_started = 'signal game_started'
		game_over = 'signal game_over'
		game_won = 'signal game_won'
		game_state_changed = 'signal game_state_changed(state: String)'
		player_caught = 'signal player_caught'
		level_completed = 'signal level_completed(level_id: String)'
		final_night_started = 'signal final_night_started'
		wave_completed = 'signal wave_completed(wave_number: int)'
		boss_defeated = 'signal boss_defeated(boss_id: String)'
		achievement_unlocked = 'signal achievement_unlocked(achievement_id: String)'
		document_unlocked = 'signal document_unlocked(document_id: String)'
		encyclopedia_unlocked = 'signal encyclopedia_unlocked(entry_id: String)'
		secret_found = 'signal secret_found(secret_id: String)'
		skin_unlocked = 'signal skin_unlocked(skin_id: String)'
		shop_purchased = 'signal shop_purchased(item: StringName)'
		purchase_done = 'signal purchase_done(item_id: String)'
		purchase_failed = 'signal purchase_failed(item_id: String, reason: String)'
		purchase_success = 'signal purchase_success(item_id: String)'
		shop_toggle_requested = 'signal shop_toggle_requested'
		puzzle_started = 'signal puzzle_started(puzzle_id: String)'
		puzzle_solved = 'signal puzzle_solved(puzzle_id: String)'
		examine_text = 'signal examine_text(text: String)'
		interaction_done = 'signal interaction_done(object_id: String)'
		noise_emitted = 'signal noise_emitted(position: Vector3, intensity: float)'
		monster_spotted = 'signal monster_spotted(monster_id: StringName)'
		weather_changed = 'signal weather_changed(weather_id: String)'
		power_grid_updated = 'signal power_grid_updated'
		xp_gained = 'signal xp_gained(amount: int)'
		radar_marker_added = 'signal radar_marker_added(marker_id: String, position: Vector3)'
		zone_reached = 'signal zone_reached(zone_id: String)'
		ui_screen_opened = 'signal ui_screen_opened(screen_id: String)'
		ui_screen_closed = 'signal ui_screen_closed(screen_id: String)'
		hud_visibility_changed = 'signal hud_visibility_changed(visible: bool)'
		settings_changed = 'signal settings_changed'
		remote_player_state = 'signal remote_player_state(peer_id: int, pos: Vector3, yaw: float, district: StringName)'
		remote_power_changed = 'signal remote_power_changed(district: StringName, powered: bool)'
		lan_hosted = 'signal lan_hosted(port: int)'
		lan_joined = 'signal lan_joined(peer_id: int)'
		lan_disconnected = 'signal lan_disconnected'
	}
	$builtin = @('has_signal', 'connect', 'emit_signal', 'disconnect', 'is_connected', 'has_method', 'has_node', 'get_node', 'get_node_or_null', 'call', 'call_deferred', 'set', 'get', 'get_meta', 'set_meta', 'get_signal_list', 'get_tree', 'add_child', 'remove_child', 'queue_free', 'is_instance_valid', 'duplicate', 'get_class', 'is_class', 'set_name', 'get_name')
	$busSrc = [System.IO.File]::ReadAllText($busPath)
	$defined = @{}
	[regex]::Matches($busSrc, 'signal\s+([A-Za-z_]\w*)') | ForEach-Object { $defined[$_.Groups[1].Value] = $true }
	$used = @{}
	Get-ChildItem -Path $root -Recurse -Filter *.gd -File | ForEach-Object {
		$t = [System.IO.File]::ReadAllText($_.FullName)
		[regex]::Matches($t, 'EventBus\.([A-Za-z_]\w*)') | ForEach-Object { $used[$_.Groups[1].Value] = $true }
	}
	$add = @(); $warn = @()
	foreach ($name in ($used.Keys | Sort-Object)) {
		if ($defined.ContainsKey($name)) { continue }
		if ($builtin -contains $name) { continue }
		if ($sigMap.Contains($name)) { $add += $sigMap[$name] }
		else { $add += ('signal ' + $name + '  # auto (signature unknown)'); $warn += $name }
	}
	if ($add.Count) {
		[System.IO.File]::AppendAllText($busPath, ("`n" + ($add -join "`n") + "`n"))
		$script:BusSignalsAdded = $add.Count
		Write-Host ('BUS     patched +' + $add.Count + ' signal(s)')
	} else { Write-Host 'BUS     OK' }
	if ($warn.Count) { Write-Host ('BUS     WARN unknown sig: ' + ($warn -join ', ')) }
}

# ---- PHASE 4: .tscn script refs + stubs ------------------------------------
Write-Host '---- PHASE 4  scene ref audit ----'
$tscnFiles = Get-ChildItem -Path (Join-Path $root 'scenes') -Recurse -Filter '*.tscn' -ErrorAction SilentlyContinue
$rx = [regex]'path="(res://[^"]+\.gd)"'
foreach ($f in $tscnFiles) {
	$txt = [System.IO.File]::ReadAllText($f.FullName, $utf8)
	foreach ($m in $rx.Matches($txt)) {
		$rel = $m.Groups[1].Value -replace '^res://', ''
		if (Test-Path (Join-Path $root $rel)) { continue }
		$baseName = [System.IO.Path]::GetFileNameWithoutExtension($rel)
		$stub = "extends Node3D`n## AUTO-GENERATED stub for $baseName (doctor.ps1)`n`nfunc _ready() -> void:`n`tpass`n"
		Write-Host ('STUB   ' + $rel)
		Write-Utf8 $rel $stub
		$script:StubsCreated++
		$script:SceneRefsFixed++
	}
}

# ---- PHASE 5: essentials ---------------------------------------------------
Write-Host '---- PHASE 5  essentials ----'
foreach ($rel in @('export_presets.cfg', 'scripts\_bootstrap.gd')) {
	if (Test-Path (Join-Path $root $rel)) { Write-Host ('OK     ' + $rel) }
	else { Write-Host ('MISS   ' + $rel + '  (WARN only)') }
}
$ks = Join-Path $root 'tls-debug.keystore'
if (-not (Test-Path $ks)) {
	$kt = Get-Command 'keytool' -ErrorAction SilentlyContinue
	if ($kt) {
		Write-Host 'GEN    tls-debug.keystore via keytool'
		$kargs = @('-genkeypair', '-alias', 'tls-debug', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000', '-keystore', $ks, '-storepass', 'android', '-keypass', 'android', '-dname', 'CN=TLS Debug, OU=Dev, O=TLS, C=US')
		[void](Start-Process -FilePath $kt.Source -ArgumentList $kargs -NoNewWindow -Wait)
	} else { Write-Host 'WARN   tls-debug.keystore missing, keytool not found' }
}

# ---- PHASE 6: final headless compile ---------------------------------------
Write-Host '---- PHASE 6  final compile ----'
$godot = Resolve-Godot
if (-not $godot) {
	Write-Host 'WARN   godot not found; compile skipped'
	$script:CompileStatus = 'NO_GODOT'
} else {
	Write-Host ('GODOT  ' + $godot)
	$scene = 'res://scenes/tools/compile_scene.tscn'
	if (-not (Test-Path (Join-Path $root 'scenes\tools\compile_scene.tscn'))) { $scene = '--quit' }
	$log = Join-Path $root 'compile.log'
	$prev = $ErrorActionPreference
	$ErrorActionPreference = 'Continue'
	if ($scene -eq '--quit') { & $godot --headless --path $root --quit *> $log }
	else { & $godot --headless --path $root $scene *> $log }
	$exit = $LASTEXITCODE
	$ErrorActionPreference = $prev
	$bad = Select-String -Path $log -Pattern 'SCRIPT ERROR|Parse Error|Failed to load|Cannot open file' -ErrorAction SilentlyContinue
	if ($exit -ne 0 -or $bad) {
		$script:CompileStatus = 'FAIL'
		Write-Host 'COMPILE FAIL:'
		if ($bad) { $bad | Select-Object -First 20 | ForEach-Object { Write-Host ('  - ' + $_.Line) } }
	} else {
		$script:CompileStatus = 'OK'
		Write-Host 'COMPILE OK'
	}
}

# ---- SUMMARY ----------------------------------------------------------------
Write-Host '================== SUMMARY =================='
Write-Host ('Files written : ' + $script:FilesWritten)
Write-Host ('Stubs created : ' + $script:StubsCreated)
Write-Host ('Autoloads OK  : ' + $script:AutoloadsVerified)
Write-Host ('Autoloads fix : ' + $script:AutoloadsFixed)
Write-Host ('Scene refs fix: ' + $script:SceneRefsFixed)
Write-Host ('Bus signals + : ' + $script:BusSignalsAdded)
Write-Host ('Parse issues  : ' + $script:BadParse.Count)
Write-Host ('Indent issues : ' + $tabIssues.Count)
Write-Host ('Compile       : ' + $script:CompileStatus)
Write-Host '================== DONE ====================='