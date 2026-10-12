extends RefCounted
## What the guards saw (docs/SECURITY_HARDENING.md): a kind and a detail per violation, in an encrypted file for later analysis. Godot's encrypted FileAccess
## (AES-256) holds the last MAX_ENTRIES. The key ships in the game, so this keeps the log from a casual reader; it is not secrecy against the owner of the device.

const PATH := "user://security.log"
const KEY := "TLS-seclog-v1-7c3e91b04d5a28f6"
const MAX_ENTRIES: int = 50

static func record(kind: String, detail: String, path: String = PATH) -> void:
	var entries: Array = read(path)
	entries.append({"t": Time.get_unix_time_from_system(), "kind": kind, "detail": detail})
	if entries.size() > MAX_ENTRIES:
		entries = entries.slice(entries.size() - MAX_ENTRIES)
	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, KEY)
	if file != null:
		file.store_string(JSON.stringify(entries))

static func read(path: String = PATH) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open_encrypted_with_pass(path, FileAccess.READ, KEY)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Array if parsed is Array else []
