class_name WorldBible
## Minimal read-only lookups over content/world/*.json and content/lore/*.json
## (the CONTENT team's world bible - characters, factions, radio, diary, news).
## Plain id->dict tables, same shape as DistrictLoot's static-utility style.
## No caching needed: these files are small and read rarely (note detail view,
## radio screen open).

const CHARACTERS_PATH := "res://content/world/characters.json"
const FACTIONS_PATH := "res://content/world/factions.json"
const RADIO_PATH := "res://content/world/radio_transcripts.json"

static func get_character(id: String) -> Dictionary:
	return _find_by_id(_load_list(CHARACTERS_PATH, "characters"), id)

static func get_faction(id: String) -> Dictionary:
	return _find_by_id(_load_list(FACTIONS_PATH, "factions"), id)

## Radio transcripts already unlocked given current district stages
## (docs/CONTENT_WORLD_BIBLE.md rule 2: reveal = {district, min_stage}).
static func get_revealed_radio_transcripts() -> Array:
	var out: Array = []
	for t in _load_list(RADIO_PATH, "transcripts"):
		if t is Dictionary and is_revealed(t.get("reveal", {})):
			out.append(t)
	return out

## Public: also used by journal_ui.gd to gate "Related" character/faction
## cross-links on notes so a world_refs id can't spoil an unrevealed reveal.
static func is_revealed(reveal: Dictionary) -> bool:
	if reveal.is_empty():
		return true
	var dm := _root().get_node_or_null("/root/DistrictManager")
	if dm == null:
		return false
	var district := StringName(reveal.get("district", ""))
	return int(dm.get_stage(district)) >= int(reveal.get("min_stage", 0))

static func _load_list(path: String, list_key: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary and parsed.get(list_key) is Array:
		return parsed[list_key]
	return []

static func _find_by_id(list: Array, id: String) -> Dictionary:
	for entry in list:
		if entry is Dictionary and String(entry.get("id", "")) == id:
			return entry
	return {}

static func _root() -> Node:
	return Engine.get_main_loop().root
