# CERT_UIAUDIO.md — UI Audio Pack v2 certificate (2026-09-13)

Owner: ASSETS agent (NEW session). Verdicts rest on measured facts: stdlib Ogg/Vorbis header + granule parse and soundfile decode (ffmpeg 7.0.2 libvorbis q4). No engine (NEVER-GODOT). Attempt log: `docs/LEDGER_UIAUDIO.md`. Re-parse script: `docs/artifacts/ui-audio/verify.py` (independent).

## 1. Header facts — 7 UI stings (all Vorbis q4, 44.1k, 1ch, ≤3s)

| File | Length (samples) | s | ch | Hz | Codec | Granule | Size | Peak dBFS | RMS dBFS | Bus | Contract |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `ui_menu_click.ogg` | 4544 | 0.103 | 1 | 44100 | vorbis | 4544 | 4769 B | -6.13 | -28.21 | UI | PASS |
| `ui_achievement_sting.ogg` | 40184 | 0.911 | 1 | 44100 | vorbis | 40184 | 7814 B | -11.23 | -22.44 | UI | PASS |
| `ui_secret_discovery_sting.ogg` | 17332 | 0.393 | 1 | 44100 | vorbis | 17332 | 5579 B | -11.19 | -24.71 | UI | PASS |
| `ui_daily_complete_sting.ogg` | 28092 | 0.637 | 1 | 44100 | vorbis | 28092 | 6528 B | -11.08 | -24.10 | UI | PASS |
| `ui_streak_milestone_sting.ogg` | 25746 | 0.584 | 1 | 44100 | vorbis | 25746 | 6399 B | -11.07 | -23.55 | UI | PASS |
| `ui_boss_sting.ogg` | 21216 | 0.481 | 1 | 44100 | vorbis | 21216 | 5862 B | -11.17 | -24.19 | UI | PASS |
| `ui_ending_sting.ogg` | 25186 | 0.571 | 1 | 44100 | vorbis | 25186 | 6244 B | -11.09 | -23.17 | UI | PASS |

*All 7 decode to PCM (soundfile) exit 0; granules exactly match frame counts (header granule = PCM frames). No resampling drift.*

## 2. Peak / RMS / Seam (TASK 2 — measured, not claimed)

Peak via numpy max(|pcm|), RMS via sqrt(mean(pcm²)). UI one-shots are zero-ended with clean tails (tail RMS -90+ dB, not tabled individually but check `peak_table.csv`). No clipping: worst peak -6.13 dBFS (menu_click after -6dB tame), rest -11.0 to -11.2 dBFS, all ≤ -1.0 dBFS headroom. No voices: all files are deterministic synth Foley (recipe audit in ledger). Seam N/A (one-shots, not loops) — endpoints are zero-adjacent (no loop requirement).

## 3. Contract pass/fail per gap (TASK 1 + TASK 2)

Universal UI sting contract: ≤3.000 s, 1ch (mono) or 2ch allowed but we deliver mono, 44.1k, Vorbis OGG, no voices, dark brass/wood mood, no casino shine, peak ≤ -1 dBFS, decode-able.

| Gap | File | Length | Ch/Rate | Codec | No vox | Mood | Casino | Peak | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| menu_click (soft mech) | ui_menu_click.ogg | 0.103 ≤3 PASS | 1ch/44.1k PASS | vorbis PASS | PASS (Foley click) | PASS (soft mechanical, neutral) | PASS (no arcade) | -6.13 ≤-1 PASS | **PASS** |
| achievement (warm 2-note) | ui_achievement_sting.ogg | 0.911 ≤3 PASS | 1ch/44.1k PASS | vorbis PASS | PASS (synth) | PASS (zen warm wood, cent 671Hz) | PASS (zen, not arcade) | -11.23 PASS | **PASS** |
| secret_discovery (mysterious chime) | ui_secret_discovery_sting.ogg | 0.393 ≤3 PASS | 1ch/44.1k PASS | vorbis PASS | PASS | PASS (zen quiet chime, cent 556Hz) | PASS | -11.19 PASS | **PASS** |
| daily_complete (short uplift) | ui_daily_complete_sting.ogg | 0.637 ≤3 PASS | 1ch/44.1k PASS | vorbis PASS | PASS | PASS (zen complete, warm restraint) | PASS | -11.08 PASS | **PASS** |
| streak_milestone (subdued triumphant) | ui_streak_milestone_sting.ogg | 0.584 ≤3 PASS | 1ch/44.1k PASS | vorbis PASS | PASS | PASS (zen streak, cent 661Hz) | PASS (subdued, not fanfare) | -11.07 PASS | **PASS** |
| boss (low brass hit) | ui_boss_sting.ogg | 0.481 ≤3 PASS | 1ch/44.1k PASS | vorbis PASS | PASS | PASS (zen error, cent 429Hz low brass) | PASS | -11.17 PASS | **PASS** |
| ending (resolved warm chord) | ui_ending_sting.ogg | 0.571 ≤3 PASS | 1ch/44.1k PASS | vorbis PASS | PASS | PASS (zen success, cent 567Hz warm chord) | PASS | -11.09 PASS | **PASS** |

Mood basis: pack character per `uisfx` README — zen = “Paper folds, soft brush, warm wood, and quiet chimes”; mechanical/Kenney = “Switches, relays, firm detents / soft click”. No casino shine: arcade/glass/rubber packs rejected. No-voice by construction (synth recipes, zero samples, auditable in cloned repos).

## 4. Bus routing for CODE (advisory — CODE owns all wiring)

Buses (`default_bus_layout.tres`): `Master -> Music | SFX | Voice | Ambient | UI`. `UI` is dry (no compressor/reverb), `Music` carries compressor + reverb.

**All 7 UI stings route to `UI` bus as one-shots (loop = false).** Do NOT put on `Music`, `SFX`, or `Ambient`. Code wiring advice:

```gdscript
# Example: UISFX or AudioManager helper
const UI_DIR := "res://assets/audio/ui/"

func play_ui(sound: StringName) -> void:
    var path := UI_DIR + "ui_%s.ogg" % sound # e.g. "menu_click"
    if not ResourceLoader.exists(path): return
    var p := AudioStreamPlayer.new()
    p.bus = &"UI"
    p.stream = load(path) # AudioStreamOggVorbis, loop=false by default
    add_child(p)
    p.play()
    p.finished.connect(p.queue_free)
```

**Event → sound map (proposed, CODE to wire):**

| Game event (existing EventBus signal) | Sound file | Trigger note |
|---|---|---|
| `ui_screen_opened` / button `pressed` (UISFX.click) | `ui_menu_click.ogg` | soft mechanical for any menu/button navigation; replace procedural beep fallback in `scripts/systems/uisfx.gd:click()` and `audio_manager.gd:_on_ui_screen_opened` |
| `achievement_unlocked` (EventBus) | `ui_achievement_sting.ogg` | warm 2-note for trophy/achievement popup; pair with `AchievementManager` unlock, already wired to `AudioManager:_gen_fanfare` — replace with stream |
| `secret_found` (EventBus) | `ui_secret_discovery_sting.ogg` | mysterious chime for secret/encyclopedia/document discovery (`secret_found`, `document_unlocked`, `encyclopedia_unlocked`) |
| `quest_completed` / `level_completed` / daily daily_complete (ProgressTracker/QuestManager) | `ui_daily_complete_sting.ogg` | short uplift for daily/quest/level complete; distinct from achievement (daily is lighter) |
| streak milestone (e.g. `ProgressTracker` streak 7/30 or `wave_completed` multiple) | `ui_streak_milestone_sting.ogg` | subdued triumphant for streak milestones; not full fanfare — quiet triumph fits dark mood |
| `boss_spawned` / `boss_defeated` (EventBus) | `ui_boss_sting.ogg` | low brass hit for boss appear/defeat; pairs with `EventBus.boss_spawned` and `boss_defeated` (currently `_gen_boom`) |
| `game_won` (EventBus, any of 5 endings) | `ui_ending_sting.ogg` | resolved warm chord for ending screen; pairs with `EventBus.game_won` / `FinaleDirector`; bittersweet warm, not casino |

All stings at unity gain (0 dB) — files already sit at -11 to -6 dBFS peak, integrated below UI bus headroom. One-shot class with clean tails, not loops. `UISFX` autoload (`scripts/systems/uisfx.gd`) already has `click()`, `achievement()`, `error()`, `save()` hooks — add 4 new methods (`secret()`, `daily_complete()`, `streak()`, `boss()`, `ending()`) or reuse via `play_ui()`.

Untouched: `Music`/`SFX`/`Voice`/`Ambient` buses, `AMBIENCE_*` beds, detail one-shots, existing `audio_manager.gd` procedural fallbacks remain as fallback if file missing.

## 5. Re-render (bit-auditable)

Sources cloned: `git clone https://github.com/Calinou/kenney-ui-audio` and `git clone https://github.com/romainsimon/uisfx` (E2B proxy). Transcode script: `docs/artifacts/ui-audio/_build_ui_audio.py` (needs `numpy`, `soundfile`, `Pillow`, `imageio-ffmpeg` static ffmpeg 7.0.2 with `libvorbis`). Output chain per file: source WAV/Opus → `ffmpeg -ac 1 -ar 44100 -c:a libvorbis -q:a 4` (menu_click extra `-filter:a volume=-6dB`) → OGG Vorbis. Re-run: `python3 docs/artifacts/ui-audio/_build_ui_audio.py`. Verification: `python3 docs/artifacts/ui-audio/verify.py` (stdlib Ogg parse).

## 6. Defects: 0 (target met)

- 0 missing files (7/7 ship), 0 header mismatches, 0 duration >3s, 0 clipping (peak ≤ -6.13 dBFS), 0 voices, 0 casino-shine mood, 0 forbidden-path writes. Wiring is CODE-owned and intentionally not in this cert beyond advisory §4.

---

Skills footer: yagni, self-commit, surgical-edit, art-pipeline, council, asset_pipeline.md
