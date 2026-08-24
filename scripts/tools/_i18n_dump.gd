extends Node
## RU FIRST proof dump (WAVE 6 P0.4): forces the ru locale and prints a
## sample of keys spanning several screens, to prove real Russian text
## is actually returned by LocalizationManager, not a fallback key.
## Scene: scenes/tools/i18n_dump_scene.tscn

const SAMPLE_KEYS: PackedStringArray = [
	"menu_title", "new_game", "continue", "quests", "difficulty",
	"HUD_NOISE", "HUD_VISIBILITY", "SKILL_LOCKED", "ACH_01_NAME",
	"DIST_SUBURBS", "DISTRICT_STAGE_2", "CHECKPOINT_SET", "BOSS_APPEARS",
	"BTN_CLOSE", "you_died",
]

## FINAL PERFECTION P4.4: SCR_* proof sample - separate from SAMPLE_KEYS
## above since P0's dump already proved the main i18n system works; this
## one is specifically about the SCR_* family this wave translated.
const SCR_SAMPLE_KEYS: PackedStringArray = [
	"SCR_IGRAT", "SCR_NASTROYKI", "SCR_VYHOD", "SCR_PRODOLZHIT",
	"SCR_GLAVNOE_MENYU", "SCR_GRAFIKA", "SCR_SLOZHNOST", "SCR_LEGKO",
	"SCR_KACHESTVO", "SCR_SOHRANIT", "SCR_ZAGRUZIT", "SCR_ZAKRYT",
	"SCR_VY_POGIBLI", "SCR_BOLNICA", "SCR_ELEKTROSTANCIYA",
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	LocalizationManager.set_language("ru")
	print("[i18n-dump] lang=", LocalizationManager.current_lang)
	for key in SAMPLE_KEYS:
		print("[i18n-dump] ", key, " = ", LocalizationManager.t(key))
	for key in SCR_SAMPLE_KEYS:
		print("[i18n-dump-scr] ", key, " = ", LocalizationManager.t(key))
	get_tree().quit(0)
