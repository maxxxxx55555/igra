extends RefCounted
## Session 29 (the v10.0.0-ship pass), G-RED2: the vectors that attack_sim.gd and the 50 mutants of _save_integrity_check.gd did not read.
## SECV9 the key that signs the saves is not a string constant of the script (two byte tables meet in _key(); the signature of every file already on a device is unchanged);
## SECV7 the integrity manifest holds on the shipped tree, trips on a forged hash or a missing file and clears when it is put back;
## SECV6 an item or a language the build does not have is refused, and no path is built from it;
## SECV2 the craft and the pack refuse a negative, a zero and an overflowing amount (a craft of 1 << 62 locks counted 2 x 2^62 as a negative and asked for nothing);
## SECV8 no shipped script prints a secret, grants anything behind OS.is_debug_build() or carries a cheat word.
## Wired into _closeout_check_runner.gd.

const _WB := preload("res://scripts/crafting/workbench_logic.gd")
const _SCAN := preload("res://scripts/security/integrity_scan.gd")
## HMAC-SHA256 of "x" under the key that every signed file on a device was written with: the key left the strings of the script, its value did not change.
const _DIGEST_OF_X: String = "dc34a87a2b4eded96b295c748d0257f141ac3dd58413a4049d3c71befd4ee533"

static func run(r: Node) -> void:
	_key(r)
	_manifest(r)
	_unknown(r)
	_amounts(r)
	_debug_surface(r)

static func _key(r: Node) -> void:
	var rx := RegEx.new()
	rx.compile('(?m)^\\s*(?:static\\s+)?(?:const|var)\\s+\\w*KEY\\w*[^\\n=]*=\\s*"[^"\\n]{12,}"')
	var literal: RegExMatch = rx.search(FileAccess.get_file_as_string("res://scripts/core/save_system.gd"))
	var signed: String = SaveSystem.call("_sign", "x")
	r._ok(literal == null and signed == _DIGEST_OF_X, "SECV9 the save key is no string literal of save_system.gd (%s) and signs as before (%s)" % [literal == null, signed == _DIGEST_OF_X])

static func _manifest(r: Node) -> void:
	var honest: Array[String] = _SCAN.mismatches()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_SCAN.MANIFEST))
	var files: Dictionary = (parsed as Dictionary).get("files", {}) if parsed is Dictionary else {}
	var first: String = String(files.keys()[0]) if not files.is_empty() else ""
	var forged: Dictionary = files.duplicate()
	forged[first] = "0".repeat(64)
	forged["res://data/not_a_file.json"] = "0".repeat(64)
	var tripped: Array[String] = _SCAN.mismatches({"files": forged})
	var restored: Array[String] = _SCAN.mismatches()
	r._ok(not files.is_empty() and honest.is_empty() and tripped.has(first) and tripped.has("res://data/not_a_file.json") and restored.is_empty(), "SECV7 the manifest of %d files flags no honest tree (%d), flags a forged hash and a missing file (%d) and clears when put back (%d)" % [files.size(), honest.size(), tripped.size(), restored.size()])

static func _unknown(r: Node) -> void:
	var added: bool = InventoryManager.try_add(&"no_such_item", 1)
	var lang0: String = LocalizationManager.current_lang
	LocalizationManager.set_language("ru")
	for bad: String in ["xx", "../data/dialogs", "zh_TW", "ar", "klingon"]:
		LocalizationManager.set_language(bad)
	var held: bool = LocalizationManager.current_lang == "ru"
	LocalizationManager.set_language(lang0)
	r._ok(not added and InventoryManager.count_of(&"no_such_item") == 0 and held, "SECV6 an item id the database lacks is refused (%s) and five language codes outside the six leave ru as it was (%s)" % [not added, held])

static func _amounts(r: Node) -> void:
	var rec: Dictionary = _WB.find("lockpick")
	var metal0: int = InventoryManager.count_of(&"metal")
	var refused: bool = not rec.is_empty()
	for qty: int in [-5, 0, 1 << 40, 1 << 62]:
		refused = refused and not _WB.can_craft(rec, qty) and not _WB.craft(rec, qty)
	var negative_remove: bool = InventoryManager.remove(&"metal", -3)
	r._ok(refused and not negative_remove and InventoryManager.count_of(&"metal") == metal0, "SECV2 a craft of -5, 0, 2^40 and 2^62 and a remove of -3 are refused and the pack is as it was (refused %s, negative remove %s)" % [refused, negative_remove])

static func _debug_surface(r: Node) -> void:
	var scripts: Array[String] = []
	_scripts("res://scripts", scripts)
	var secret := RegEx.new()
	secret.compile("(?i)^\\s*(?:print|print_rich|print_debug|push_warning)\\(.*(?:hmac|secret|password|token|api_key|_KEY\\b)")
	var grant := RegEx.new()
	grant.compile("(?i)(add_coins|CoinWallet\\.add|CoinWallet\\.set|unlock_weapon|unlock_all|set_coins|\\bgive_\\w+\\()")
	var cheat := RegEx.new()
	cheat.compile("(?i)\\b(god_?mode|cheat_?code|debug_?menu|dev_?console|infinite_?ammo|noclip)\\b")
	var hits: Array[String] = []
	for path: String in scripts:
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for i: int in lines.size():
			var code: String = lines[i].split("#")[0]
			if secret.search(code) != null or cheat.search(code) != null:
				hits.append("%s:%d" % [path, i + 1])
			if code.contains("is_debug_build()"):
				for j: int in range(i, mini(i + 6, lines.size())):
					if grant.search(lines[j].split("#")[0]) != null:
						hits.append("%s:%d" % [path, j + 1])
	r._ok(scripts.size() > 200 and hits.is_empty(), "SECV8 %d shipped scripts: no print of a secret, no cheat word and no grant within six lines of OS.is_debug_build() (%s)" % [scripts.size(), hits.slice(0, 3)])

static func _scripts(dir: String, out: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		if sub != "tools":
			_scripts(dir.path_join(sub), out)
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd") and f != "attack_sim.gd":
			out.append(dir.path_join(f))
