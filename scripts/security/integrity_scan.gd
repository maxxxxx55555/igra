extends RefCounted
## The file integrity scanner (docs/SECURITY_HARDENING.md): the content and data JSON that decide the game's rules against the SHA-256 of their text kept in
## data/integrity_manifest.json (tools/gen_integrity_manifest.py writes it, a static gate holds it). The text is taken with CRLF turned into LF, so a build
## from a checkout with other line ends passes. A client-side check: a repackager who edits a file can edit the manifest too, so this raises the bar and
## leaves a log entry; it proves nothing against a determined one.

const MANIFEST := "res://data/integrity_manifest.json"

## The paths whose text no longer hashes to the manifest, or that are gone; "manifest" when the manifest itself is missing or unreadable.
static func mismatches(manifest: Dictionary = {}) -> Array[String]:
	var files: Dictionary = (manifest if not manifest.is_empty() else _load()).get("files", {})
	if files.is_empty():
		return ["manifest"]
	var bad: Array[String] = []
	for path: String in files:
		if not FileAccess.file_exists(path) or hash_of(path) != String(files[path]):
			bad.append(path)
	return bad

static func hash_of(path: String) -> String:
	return FileAccess.get_file_as_string(path).replace("\r\n", "\n").sha256_text()

static func _load() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	return parsed as Dictionary if parsed is Dictionary else {}
