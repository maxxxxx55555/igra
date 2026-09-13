# assets/audio/ui — UI Audio Pack v2 README (CODE wiring bus routing)

Owner: ASSETS/UI AUDIO agent. **CODE owns all wiring** — this file is advisory.

## Files shipped (7 OGG Vorbis q4 mono 44.1k, ≤3s, no voices, dark brass/wood, no casino shine)

| File | Cue | Length | Centroid | Character |
|---|---|---|---|---|
| `ui_menu_click.ogg` | soft mechanical click | 0.103 s | — | Kenney click, neutral soft |
| `ui_achievement_sting.ogg` | warm 2-note | 0.911 s | 671 Hz | zen warm wood |
| `ui_secret_discovery_sting.ogg` | mysterious chime | 0.393 s | 556 Hz | zen quiet chime |
| `ui_daily_complete_sting.ogg` | short uplift | 0.637 s | 639 Hz | zen warm restraint |
| `ui_streak_milestone_sting.ogg` | subdued triumphant | 0.584 s | 661 Hz | zen warm wood |
| `ui_boss_sting.ogg` | low brass hit | 0.481 s | 429 Hz | zen low brass |
| `ui_ending_sting.ogg` | resolved warm chord | 0.571 s | 567 Hz | zen warm chord |

All peaks ≤ -6 dBFS, RMS -22 to -24 dBFS, decode-able, granule = frames.

## Bus routing (Godot `default_bus_layout.tres`: `Master -> Music | SFX | Voice | Ambient | UI`)

**All 7 → `UI` bus as one-shots (loop = false).** `UI` is dry (no compressor/reverb). Do NOT place on `Music` (has compressor+reverb) or `Ambient`/`SFX`.

```gdscript
# UISFX autoload example
const UI_DIR := "res://assets/audio/ui/"
func play_ui(name: StringName) -> void:
    var path := UI_DIR + "ui_%s.ogg" % name
    if not ResourceLoader.exists(path): return
    var p := AudioStreamPlayer.new()
    p.bus = &"UI"
    p.stream = load(path)
    add_child(p)
    p.play()
    p.finished.connect(p.queue_free)
```

## Event → sound map (wire in CODE, not here)

| Signal (EventBus) | Sound | Notes |
|---|---|---|
| `ui_screen_opened` / button pressed | `ui_menu_click.ogg` | Replace procedural `_beep` in `scripts/systems/uisfx.gd` and `audio_manager.gd` |
| `achievement_unlocked` | `ui_achievement_sting.ogg` | Warm 2-note |
| `secret_found` / `document_unlocked` / `encyclopedia_unlocked` | `ui_secret_discovery_sting.ogg` | Mysterious chime |
| `quest_completed` / `level_completed` / daily | `ui_daily_complete_sting.ogg` | Short uplift |
| streak milestone (e.g. 7-day streak) / `wave_completed` | `ui_streak_milestone_sting.ogg` | Subdued triumphant |
| `boss_spawned` / `boss_defeated` | `ui_boss_sting.ogg` | Low brass hit |
| `game_won` (any of 5 endings) | `ui_ending_sting.ogg` | Resolved warm chord |

Keep unity gain (0 dB). Files already at -11 dB peak.

## Re-render

Sources: `https://github.com/Calinou/kenney-ui-audio` (CC0) + `https://github.com/romainsimon/uisfx` zen pack (CC0). Script: `docs/artifacts/ui-audio/_build_ui_audio.py` (needs `numpy`, `soundfile`, `Pillow`, `imageio-ffmpeg` ffmpeg 7.0.2). Run: `python3 docs/artifacts/ui-audio/_build_ui_audio.py`. Verify: `python3 docs/artifacts/ui-audio/verify.py`.

## License

All 7 are CC0 1.0 Universal (https://creativecommons.org/publicdomain/zero/1.0/) — no attribution required. See `docs/LEDGER_UIAUDIO.md` for provenance rows.
