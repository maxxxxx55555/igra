extends RefCounted
## Session 23 (docs/SECURITY_HARDENING.md): what an offline game can hold on the client: the clocks, the encrypted log of violations, the data scan, the
## Android flags. Wired into _closeout_check_runner.gd as `await Rc23Sec.run(self)`; CLOSEOUT_ONLY=s23 runs it with the others. The log file and the guard's
## flags are put back.

const _Log := preload("res://scripts/security/security_log.gd")
const _Scan := preload("res://scripts/security/integrity_scan.gd")

static func run(r: Node) -> void:
	r._playing()
	_clocks(r)
	_log_and_leaderboard(r)
	_scan(r)
	_android_flags(r)

## SEC1: the monotonic clock and the wall clock keep step; a window where they part is off, one off window is a clock set or a sleep, two in a row are a speed hack.
static func _clocks(r: Node) -> void:
	var guard: Node = IntegrityGuard
	var steady: bool = not IntegrityGuard.window_is_off(10.0, 10.0) and not IntegrityGuard.window_is_off(10.0, 10.2)
	var hacked: bool = IntegrityGuard.window_is_off(10.0, 20.0) and IntegrityGuard.window_is_off(10.0, 5.0)
	var tampered0: bool = guard.tampered
	guard.set("_off_windows", 0)
	var now_ticks: int = Time.get_ticks_usec()
	var now_wall: float = Time.get_unix_time_from_system()
	guard.set("_window_ticks", now_ticks - 11000000)
	guard.set("_window_wall", now_wall - 31.0)
	guard.call("_watch_clocks")
	var after_one: bool = not guard.tampered and int(guard.get("_off_windows")) == 1
	guard.set("_window_ticks", Time.get_ticks_usec() - 11000000)
	guard.set("_window_wall", Time.get_unix_time_from_system() - 11.0)
	guard.call("_watch_clocks")
	var reset: bool = not guard.tampered and int(guard.get("_off_windows")) == 0
	for i in 2:
		guard.set("_window_ticks", Time.get_ticks_usec() - 11000000)
		guard.set("_window_wall", Time.get_unix_time_from_system() - 31.0)
		guard.call("_watch_clocks")
	var flagged: bool = guard.tampered
	guard.set("tampered", tampered0)
	guard.set("_window_ticks", Time.get_ticks_usec())
	guard.set("_window_wall", Time.get_unix_time_from_system())
	guard.set("_off_windows", 0)
	r._ok(steady and hacked and after_one and reset and flagged, "SEC1 speed clocks: in step %s, parted %s; one off window is not a verdict (%s), a normal window after it clears it (%s), two in a row flag a speed hack (%s)" % [steady, hacked, after_one, reset, flagged])

## SEC2: a violation is a line in the encrypted log (the file does not hold the text in the clear) and, when it taints, stops the leaderboard.
static func _log_and_leaderboard(r: Node) -> void:
	var guard: Node = IntegrityGuard
	var tampered0: bool = guard.tampered
	var before: int = _Log.read().size()
	var started: float = Time.get_unix_time_from_system()
	guard.call("flag", "check_untainted", "the emulator of a test", false)
	var lines: Array = _Log.read()  # a full log (MAX_ENTRIES) takes the new line in and drops the oldest, so the count does not move: the newest line has to be this flag
	var newest: Dictionary = lines.back() as Dictionary if not lines.is_empty() else {}
	var kept: bool = lines.size() == mini(before + 1, _Log.MAX_ENTRIES) and newest.get("kind", "") == "check_untainted" and float(newest.get("t", 0.0)) >= started and not guard.tampered
	var raw: String = FileAccess.get_file_as_bytes(_Log.PATH).get_string_from_utf8()
	var encrypted: bool = not raw.contains("check_untainted") and not raw.contains("emulator")
	var runs0: Array = (LocalLeaderboard.get("_runs") as Array).duplicate()
	LocalLeaderboard.set("_runs", [])  # a profile with ten records is full: the eleventh pushes one out and the count does not move
	guard.call("flag", "check_tainted", "a changed data file")
	var tainted: bool = guard.tampered
	LocalLeaderboard.record_run(12.0, 3, 2, "light")
	var blocked: bool = (LocalLeaderboard.get("_runs") as Array).is_empty()
	guard.set("tampered", false)
	LocalLeaderboard.record_run(12.0, 3, 2, "light")
	var recorded: bool = (LocalLeaderboard.get("_runs") as Array).size() == 1
	LocalLeaderboard.set("_runs", runs0)
	LocalLeaderboard.call("_save")
	guard.set("tampered", tampered0)
	r._ok(kept and encrypted and tainted and blocked and recorded, "SEC2 log and leaderboard: a flag adds a line (%s) and the file is encrypted (%s), a tainting flag stops the leaderboard (%s) and a clean guard records (%s)" % [kept, encrypted, blocked, recorded])

## SEC3: the data scan finds a changed hash, a missing file and a missing manifest, and finds nothing wrong with the shipped files.
static func _scan(r: Node) -> void:
	var clean: bool = _Scan.mismatches().is_empty()
	var changed: Array[String] = _Scan.mismatches({"files": {"res://content/captions.json": "0000"}})
	var gone: Array[String] = _Scan.mismatches({"files": {"res://content/not_there.json": "0000"}})
	var none: Array[String] = _Scan.mismatches({"version": 1})
	var crlf: bool = "a\r\nb".replace("\r\n", "\n").sha256_text() == "a\nb".sha256_text()
	r._ok(clean and changed == ["res://content/captions.json"] and gone == ["res://content/not_there.json"] and none == ["manifest"] and crlf, "SEC3 data scan: every file of the manifest is in the game and hashes as listed (%s), a changed hash (%s), a missing file (%s) and a missing manifest (%s) are named, line ends do not matter (%s)" % [clean, changed.size() == 1, gone.size() == 1, none == ["manifest"], crlf])

## SEC4: an emulator model is told from a phone (the Android check logs it and does not taint), and the checks do nothing off Android.
static func _android_flags(r: Node) -> void:
	var emulators: bool = IntegrityGuard.looks_like_emulator("sdk_gphone64_x86_64") and IntegrityGuard.looks_like_emulator("Genymotion Pixel 6") and IntegrityGuard.looks_like_emulator("Android SDK built for x86")
	var phones: bool = not IntegrityGuard.looks_like_emulator("Pixel 8") and not IntegrityGuard.looks_like_emulator("SM-S918B") and not IntegrityGuard.looks_like_emulator("")
	var guard: Node = IntegrityGuard
	var tampered0: bool = guard.tampered
	guard.call("_android_checks")
	r._ok(emulators and phones and guard.tampered == tampered0, "SEC4 android flags: emulator models are told from phones (%s, %s), the checks leave the guard alone off Android (%s)" % [emulators, phones, guard.tampered == tampered0])
