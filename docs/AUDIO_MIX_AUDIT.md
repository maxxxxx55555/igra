# AUDIO_MIX_AUDIT — static audit of `assets/audio/` (2026-09-20)

Owner: audio director (this doc + `docs/MUSIC_SPEC.md` only). Static analysis — no decode,
no engine, no audio generation. Forward spec: `docs/MUSIC_SPEC.md`.

## Method (and its limits)

- **Durations:** Ogg = last-page granule ÷ id-header rate; WAV = `data` chunk size ÷
  byterate; MP3 = frame walk (measured, not estimated). Same method as `docs/AUDIO_COVERAGE.md` F1.
- **Loudness proxy:** Ogg KB/s density (nominal q4 ≈ 86 kbps at −18 LUFS per README class).
  Density ∝ loudness only for same-codec same-material files; rows below are flagged only
  where the gap exceeds ~3 dB-equivalent (> ~×2 density) or where a documented pass already
  measured real values. Density is NOT a substitute for `ffmpeg loudnorm` — every fix below
  ends in a measured normalization.
- **Loop flags:** no `.import` files tracked in git (`git ls-files … .import` → 0); loops are
  forced in code — `_force_loop()` applies `LOOP_FORWARD`/`loop=true` to every Mood track and
  heartbeat/breath beds (`music_manager.gd:291`, `audio_manager.gd:57,61`); wow cues play
  once (`_play_wow_cue` → plain `.play()`); district beds loop via
  `AudioStreamOggVorbis.loop` in `district_atmosphere.gd` (AUDIO_COVERAGE F1).
- **Consumers:** `grep -rl <file> scripts/ scenes/ --include=*.gd --include=*.tscn`,
  generator tools excluded.

## Verified-clean baseline (no action)

- 22 district beds (11 dark + 11 lit): 36.000 s class (industrial pair 33.994 s byte-matched),
  −18 LUFS / TP ≤ −1.5 documented + certified (`README`, `CERT_AUDIO.md`).
- 3 wow cues (`cue_first_light` 60.000 s, `cue_grid_cascade` 90.000 s, `cue_victory` 120.000 s):
  consistent 66–70 kbps density class, one-shot, never looped in code.
- Weather (`rain_loop`, `wind_loop` 45 s), threat beds (`threat_low_loop` 60 s,
  `threat_high_loop` 37.991 s), `action_sting_loop` 15.983 s: normalized per
  `docs/AUDIO_LOUDNESS.md`, wired.
- `layer_threat_low/high.ogg`, `layer_action.ogg`: uniform 60.000 s stems, wired, −12 dB mix.

## a) Loudness normalization gaps

| file | issue | evidence | fix |
|---|---|---|---|
| `music/*` (24 files) | the entire music/ class never went through the loudness pass | `docs/AUDIO_LOUDNESS.md` covers 37 files, all `ambience/` + `sfx/`; zero `music/` rows | one `loudnorm` pass: music/beds −18 LUFS, stingers −14; record in AUDIO_LOUDNESS.md |
| `music/layer_dark.ogg` vs `music/layer_action.ogg` | > ~3 dB-equivalent apart; layer action fades in at 1.5 s lerp → audible level pop | density 287 KB/118.004 s = 19.8 kbps vs 568 KB/60 s = 75.7 kbps (×3.8); lit sits between (543 KB/118.490 s = 36.7) | normalize the 5 `layer_*` files as a set to matched −18 LUFS int. |
| `jingles/ach_unlock.ogg` vs `quest_complete`/`skill_unlock` | ach jingle ≈ 5–6 dB under its siblings | 13 KB/2.000 s = 52 kbps vs 37 KB/3.000 s = 99 / 26 KB/2.000 s = 104 kbps | loudnorm jingles/ to −14 LUFS |
| `music/abandoned_hallways.mp3` + `_alt.mp3` | only MP3s consumed in tree; VBR, unnormalized; MENU plays 234 s at unknown integrated level vs −18 house | 4661 KB/234.0 s (≈159 kbps avg, first frame 224); `_alt` 5869 KB/282.2 s (≈166, first frame 64) | transcode to OGG q4 mono 44.1 kHz, loudnorm −18 (or retire from MENU per MUSIC_SPEC §a) |
| `music/Threat_High.ogg` / `Threat_Low.ogg` | if ever re-wired they sit ≥ ~6 dB under the layer class they duplicate | 65 KB/24 s = 21.7 / 59 KB/26 s = 18.2 kbps vs `layer_threat_high` 73 kbps | resolved by deletion (row d1) — do not normalize |
| `ending_music/ending_dark_full.ogg` vs `ending_light_full.ogg` | dark ending bed ≈ 3 dB-equivalent under light twin | 135 KB/60 s = 18.0 vs 200 KB/60 s = 26.7 kbps | normalize the pair to matched −18 LUFS |
| `ui/ui_boss_sting.ogg` | hot side of the ui/ sting class (~1 dB over sibling max, but 2× `ui_achievement_sting` density) | 5 KB/0.481 s = 83 kbps vs `ui_achievement_sting` 7 KB/0.911 s = 61 kbps | loudnorm ui/ stingers as a set to −14 LUFS |

## b) Loop-flag inconsistencies

| file | issue | evidence | fix |
|---|---|---|---|
| `music/music_victory.wav` | 14.5 s victory figure **loops forever** on the win screen under the 120 s `cue_victory` arc — `_force_loop` is applied to every Mood track, VICTORY included | `music_manager.gd:291` `_force_loop` called in `_load()` for all `TRACKS`; `_on_game_won()` → `set_mood(VICTORY)`; consumers grep: only music_manager | REPLACE with a ≥60 s victory bed at the same path (MUSIC_SPEC §e) or exempt VICTORY from `_force_loop` (CODE-owned) |
| `music/abandoned_hallways.mp3` (MENU) | whole-file MP3 loop; MP3 encoder padding makes the 234 s wrap seam audible (gapless unreliable), and it is the only MP3 the engine plays | consumers grep: `music_manager.gd:23` only; `ls music/*.mp3` → 2 files | transcode OGG with 3 ms zero-edge fades (house seam style), or retire per MUSIC_SPEC §a |
| wow cues + `ui/*_sting.ogg` | correctly NOT looped — pass | `_play_wow_cue` uses bare `.play()` (`music_manager.gd:435`); `uisfx.play_ui` plays + frees on `finished` | none (recorded as verified) |
| district beds | correctly loop whole-file with 3 ms zero edges — pass | `district_atmosphere.gd` sets `AudioStreamOggVorbis.loop`; README cert | none |
| `ambience/ambient_dark_loop.ogg`, `ambient_lit_loop.ogg` | loop flags moot — 0 consumers | grep `ambient_dark_loop\|ambient_lit_loop` scripts+scenes → 0 files (legacy pre-district beds, 120 s class) | retire to `_pre_norm/` or delete (row d6) |

## c) Missing stems for dynamic layering

| file | issue | evidence | fix |
|---|---|---|---|
| `music/music_boss_dark.wav` | single 30.5 s loop scored to a 3-phase boss; no per-phase material despite `Phase {P1,P2,P3}` in `boss_3d.gd:6` | `enum Phase { P1, P2, P3 }`; `enter_boss()`/`Mood.BOSS` has one track (`music_manager.gd:27`) | spec 3 phase stems `music_boss_dark_p{1,2,3}.ogg` (MUSIC_SPEC §d) |
| `music/layer_lit.ogg` | lit layer is 0.486 s longer than dark twin → phase drift across the most frequent transition (district lit state swap) | dark 118.004 s vs lit 118.490 s (granule-measured); layers share one player family with 1.5 s lerp | re-render lit as exact 118.004 s twin of dark (precedent: industrial lit twin G2h) |
| `music/music_battle.wav` + `music/music_combat.ogg` | intensity variants, not stems: random pick (`BATTLE_VARIANTS`, `BUGS_FOR_CLAUDE` #3), 24.5 s vs 45 s, no shared grid | `music_manager.gd:34–36`; durations 24.500/45.000 s | keep as documented transition variants; intensity path stays the `layer_*` stack (MUSIC_SPEC §c) — no re-render required |
| district themes (`downtown/harbor/…`) | static single-loop themes; adaptive claim rests solely on the city-wide `layer_*` family (store copy: "5 adaptive music layers") | `AMBIENT_BY_DISTRICT` maps 11 districts → 6 files; no stems exist for any district theme | MUSIC_SPEC §b2 one theme per district; per-district stems explicitly out of scope (YAGNI) |

## d) Duplicate / variant tracks to consolidate

| file | issue | evidence | fix |
|---|---|---|---|
| `music/Threat_Low.ogg`, `music/Threat_High.ogg` | legacy pre-layer copies of the wired `layer_threat_*` stems; 0 stream consumers | grep scripts+scenes: matches only inside music_manager comment block (`:9`); no load path | delete (or move to `_pre_norm/`); do not re-wire |
| `music/music_menu_dark.ogg` | generated by the repo's own tool but never shipped; MENU silently falls back to the 234 s MP3 | `_gen_music.gd:318` `_save("music_menu_dark")`; file absent from shipped `music/` (exists only under `_pre_norm/final_polish/`); `music_manager.gd:23` wires `abandoned_hallways.mp3` | promote a proper render to `music/music_menu_dark.ogg` and rewire `Mood.MENU` (CODE), then retire the MP3 |
| `sfx/architect_sting.*`, `sfx/tvar_sting.*` | dual-format duplicates; only `.ogg` is wired | consumers grep: `architect_sting.ogg` → boss_3d.gd:45; `.wav` twin → 0 references | delete the two `.wav` twins |
| `jingles/ach_unlock.ogg`, `ui/ui_ending_sting.ogg`, `ui/ui_streak_milestone_sting.ogg` | unwired near-duplicates of wired sounds (`ui_achievement_sting` = ach moment; `cue_victory` + ending jingles = ending moment; streak milestone has no consumer event) | grep → 0 consumer files each, while `uisfx.gd:112` wires `ui_achievement_sting.ogg` and `endings_manager.gd:38–39` wires ending stings | wire or delete; default delete for `ui_ending_sting`/`ui_streak_milestone_sting`, keep `ach_unlock` only if achievements gain a banner moment |
| `sfx/interact/save_success.wav`, `save_fail.wav`, `sfx/ui_back.wav`, `ui_tab.wav`, `sfx/interact/loot_pickup_generic.wav` (+`_rare`) | shipped with 0 consumers; save results and back/tab are real UX moments currently silent | grep → 0 consumer files each; `uisfx.gd` exposes only click/hover/error/save(menu) | wire save_success/fail + back/tab via `uisfx` (cheap UX win), or delete; keep pickup rare as loot polish hook |
| `ambience/ambient_dark_loop.ogg`, `ambient_lit_loop.ogg` | generic 120 s beds superseded by the 22 per-district beds | 0 consumers (§b row); README documents per-district beds as the shipped system | retire to `_pre_norm/` |
| adjacent out-of-scope (recorded, not owned here): `sfx/footstep_{concrete,metal,wood}.wav` vs `sfx/footsteps/*` vs `sfx/step_*`; `sfx/monster_*` vs `sfx/mon_*` | parallel naming families from legacy passes; consumers split across both | e.g. `footstep_concrete` 1 consumer while `footsteps/concrete_*` family wired elsewhere; `mon_*` wired per enemy | CODE+ AUDIO joint naming consolidation pass; no music-scope action |

## Riskiest assumptions (one line per category, all verified this turn)

- **Loudness (a):** KB/s density stands in for LUFS — coarse; rows only flagged >×2 density
  or where a doc measured real deltas; final fix is measured loudnorm, not the proxy.
- **Loop flags (b):** assumed `.import` loop bits exist — verified FALSE (0 tracked), so
  "loop-flag inconsistencies" are code-path findings, not import settings.
- **Stems (c):** assumed boss had phase music — verified FALSE (single loop vs 3-phase enum),
  and assumed lit/dark layers twin-length — verified FALSE (118.004 vs 118.490).
- **Duplicates (d):** assumed `music_combat.ogg` was a dead duplicate — verified FALSE
  (wired as a BATTLE variant, `BUGS_FOR_CLAUDE` #3); true orphans are the Threat_*/ach_unlock/
  ui_ending_sting/ambient_*_loop set above (all 0-consumer, grepped).
