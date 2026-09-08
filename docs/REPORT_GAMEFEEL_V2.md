# REPORT_GAMEFEEL_V2 — picto + stages + docs + bundle + state audio

Session: 2026-08-24 (after POLISH V2 48/48). Ownership respected: only NEW folders
picto_v2/, stages_v2/, docs_v2/, audio/one_shots/, one appended render, + these 2 docs.
29 files created. Generators: %TEMP%/opencode/tls_gen/{gen_gamefeel_v2,gen_one_shots}.py;
QA: qa_gamefeel_v2.py + in-generator audio verifier — **ALL PASS**.
Canon: V2 line-art (olive #8f9464 + brass #c9a24a, bone/ember/teal accents), textless
(docs carry illegible wavy scrawl only — zero readable glyphs by construction).

Grep locks: DistrictData.Stage 0..3 = DARK/PARTIAL/STREETS/FULL (world_env_setup.gd:148,
power_grid.gd); difficulty 0/1/2 = easy/normal/hard (difficulty_manager.gd, settings_manager
DIFFICULTY_LABELS); weather {CLEAR,RAIN,FOG,STORM,WIND} (weather_system.gd:2) — brief's
rain/fog/storm/wind = the 4 non-clear states.

## T1 — Touch gesture pictograms → picto_v2/ (96px line-art, olive+brass)

| File | Size | Consumer hint |
|---|---|---|
| gesture_tap_96, gesture_hold_96 (progress ring), gesture_doubletap_96, gesture_swipe_96, gesture_drag_96 (joystick), gesture_look_96 (.png) | ~1 KB | Tutorial toasts / onboarding / touch settings (FTUE) |

## T2 — Difficulty + threat icons → picto_v2/

| File | Size | Consumer hint |
|---|---|---|
| difficulty_calm_64 (green #5f8a4e), difficulty_normal_64 (amber #c08a2e), difficulty_hard_64 (ember #b4452f, cracked shield) | <1 KB | Settings difficulty rows / new-game flow. Canon mapping: calm→easy idx 0, normal→1, hard→2 |
| threat_low_48 / threat_med_48 / threat_high_48 (1/2/3 bars, green→amber→ember) | <1 KB | Map legend / HUD threat indicator |
| threat_critical_48 (bone skull + ember eyes) | <1 KB | max-threat state marker |

## T3 — Restoration stage strip → stages_v2/ (256×144, identical camera/geometry)

| File | Size | Consumer hint |
|---|---|---|
| stage_dark_256x144.png | 3 KB | District screen stage strip, Stage.DARK (0): near-black, zero lights (verified 0 brass px) |
| stage_partial_256x144.png | 3 KB | Stage.PARTIAL (1): few window glows |
| stage_streets_256x144.png | 4 KB | Stage.STREETS (2): streetlight cones on |
| stage_full_256x144.png | 12 KB | Stage.FULL (3): all windows + warm horizon (1689 brass px) |

Series consistency verified: geometry strip (poles/ground) pixel-identical across
dark/partial/streets (max diff 0); brass ordering 0 < 15 < 39 < 1689.

## T4 — Document page variants → docs_v2/ (256×340 aged paper, scrawl-only)

| File | Size | Consumer hint |
|---|---|---|
| doc_circuit_256x340.png | 3 KB | Journal doc thumb (Project Architect circuit sketch) |
| doc_map_sketch_256x340.png | 3 KB | journal (district map + ember X mark) |
| doc_letter_256x340.png | 4 KB | journal (fold crease + signature squiggle) |
| doc_photo_street_256x340.png | 3 KB | journal photo slot (streetlight polaroid; pairs with achievements photographer) |
| doc_photo_monster_256x340.png | 3 KB | journal photo slot (creature polaroid, ember eyes) |
| doc_blueprint_256x340.png | 2 KB | journal/workbench (generator blueprint, dashed schematic) |

## T5 — Bundle art → renders_v2/ (append)

| File | Size | Consumer hint |
|---|---|---|
| bundle_survivor_256.png | 1.4 KB | Shop bundle card (crate + backpack + medkit + batteries, brass rim, near-black bg) |

## T6 — State/weather one-shots → audio/one_shots/ (≤1MB, sfx −14 / loops −18 LUFS, TP ≤ −1.0)

| File | Size | Verified | Consumer hint |
|---|---|---|---|
| thunder_near.wav | 224 KB | 2.60s, I=−13.96, TP=−1.45 | STORM weather crack (one-shot; transient clean) |
| thunder_far.wav | 387 KB | 4.50s, I=−14.28, TP=−1.40 | distant rumble roll |
| rain_on_metal_loop.ogg | 264 KB | 30.00s, I=−18.22, seam +0.21dB | RAIN state loop (metal ping layer, wrap-mirrored) |
| heartbeat_low_loop.ogg | 129 KB | 20.00s, I=−17.99, seam_pm +0.04dB | low-HP state loop, 60bpm (20×1s sample-identical tiles, wrap diff 0.0104; standard head/tail seam N/A — beat-phase artifact, see ERROR_LOG) |
| breath_low_loop.ogg | 154 KB | 20.00s, I=−18.25, seam −0.16dB | strained exertion loop (5×4s cycles, sin envelopes zero at wrap) |

## T7 — QA summary

- Palette: 0 pure #000/#fff visible pixels, max channel ≤246 across all 24 art files.
- Readability: picto at 24/32/64 via tonal-spread metric (p90−p10 ≥ 15; single-hue glyphs
  measure 0–10, two-tone 17–42 — metric revision rationale in ERROR_LOG_GAMEFEELV2.md).
- Distinctness: gestures 0.594, difficulty 0.851, threat 0.605 (< 0.90 cap).
- Stages: brass ordering 0 < 15 < 39 < 1689; geometry strip max diff 0.
- Audio: 5/5 PASS (loudness targets, TP caps, seam/loop evidence per type).
- Textless: scrawl = random smooth waves (no glyph shapes drawn); visual sheets verified.
