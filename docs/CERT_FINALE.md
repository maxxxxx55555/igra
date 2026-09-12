# CERT_FINALE.md — AUDIO+VISUAL FINALE certificate (2026-09-12)

Owner: CONTENT+ASSETS agent. Verdicts below rest on static measurements run
this session: stdlib Ogg/Vorbis header + granule parse, JSON schema assert,
numpy/PIL pixel checks (dims, range, pure-texel counts). No engine
(NEVER-GODOT standing). Attempt log: `docs/LEDGER_FINALE.md`.

## 1. Audio — lit beds (honest headers, loudness inherited)

Static re-verification of the 8 TASK 1 beds (contract: Vorbis, 1 ch,
44,100 Hz, nominal 86k, exact granule):

| File | Granule | s | Size | Verdict |
|---|---|---|---|---|
| `residential_lit.ogg` | 1,587,600 | 36.000 | 318,252 B | PASS (byte-identical to 2026-09-11 cert) |
| `park_lit.ogg` | 1,587,600 | 36.000 | 330,927 B | PASS |
| `school_lit.ogg` | 1,587,600 | 36.000 | 305,943 B | PASS |
| `gas_station_lit.ogg` | 1,587,600 | 36.000 | 316,145 B | PASS |
| `police_lit.ogg` | 1,587,600 | 36.000 | 303,712 B | PASS |
| `warehouses_lit.ogg` | 1,587,600 | 36.000 | 304,521 B | PASS |
| `industrial_lit.ogg` | 1,499,146 | 33.994 | 292,188 B | PASS (twin-exact per G2h) |
| `substation_lit.ogg` | 1,587,600 | 36.000 | 312,749 B | PASS |
| F1 `generator_thrum` / `cooling_fan` | 1,267,829 / 1,276,622 | 28.749 / 28.948 | 220,543 / 222,943 B | RETAINED (finding, not a gap) |

Loudness (−18 LUFS / TP ≤ −1.5) is NOT re-measured here — no Vorbis decoder
or ffmpeg exists in this sandbox (verified absent). Verdict basis: exact
header/granule/size identity with the `docs/CERT_AUDIO.md` §1–§3 encode,
whose loudness was measured at encode time. Stated, not hidden. No new audio
binaries this pass — none were needed (8/8 ship).

## 2. Post-fx presets — schema + full-strength simulation

- Schema: `presets.json` v1 parses; exactly the 11 canon districts; every row
  carries bloom/vignette/chroma/grain; bloom 0.12–0.35, vignette 0.45–0.60 in
  `#0c1016` (inside the shipped 0.0–0.7 clamp), chroma 0.5–1.0 px, grain
  0.08–0.12 (GDD §11.4 band, inside the shipped 0.0–0.15 clamp). PASS.
- Full-strength simulation (numpy/PIL over palette-locked `still_first_light`,
  base range 18..239) with the EXACT shipped shader math (add-only grain veil,
  shipped vignette formula, threshold-235 bloom, radial chroma): graded range
  **14..236, 0 pure-white / 0 pure-black / 0 >250 texels**, contrast 98.6%
  retained, mean +24% (the already-shipped grain veil's lift, presets stay in
  its live band). Readable, nothing blown. PASS. (A harsher stress sim is
  disclosed in `docs/LEDGER_FINALE.md` §F-V1 — not the verdict basis.)

## 3. Trailer heroes — dims / palette / purity

| File | Dims | Range | Pure W/B | Size | Visual QA |
|---|---|---|---|---|---|
| `hero_first_restore_1920x1080.png` | 1920×1080 exact | 10..240 | 0 / 0 | 3,607 KB | PASS (no text/HUD, center band) |
| `hero_grid_cascade_1920x1080.png` | 1920×1080 exact | 10..240 | 0 / 0 | 3,995 KB | PASS |
| `hero_reactor_room_1920x1080.png` | 1920×1080 exact | 10..240 | 0 / 0 | 3,995 KB | PASS (spoiler-safe) |
| `hero_shorts_cut_1080x1920.png` | 1080×1920 exact | 10..240 | 0 / 0 | 3,532 KB | PASS |

Full stack baked per file (LUT trilinear @0.55 + bloom 0.30 + vignette +
chroma 0.75px + grain), exact Godot values in `store/trailer/README.md`.
Sizes 3.5–4.0 MB (grain cost disclosed — marketing masters, re-exported on
upload, never runtime textures).

## 4. Scope hygiene

Changed paths this pass (9 + this file): `assets/textures/postfx/` (2 new),
`store/trailer/` (4 new + README), `docs/AUDIO_COVERAGE.md` (surgical note),
`docs/LEDGER_FINALE.md`, `docs/CERT_FINALE.md`. Zero writes to
`docs/ASSET_LICENSES.md`, `docs/CONTENT_PIPELINE_AUDIT.md`, HANDOFF/GDD,
code, locales, or content. License rows for new files drafted in
`docs/LEDGER_FINALE.md` §F-LIC for the docs owner.

## 5. Defects: **0** (target met)

0 missing files, 0 header mismatches, 0 schema violations, 0 clamp
violations, 0 pure-texel failures, 0 dimension misses, 0 forbidden-path
writes, 0 fabricated assets (every binary on disk is verified or disclosed;
the brief's "8 gaps remain" premise was stale — §1 proves 8/8 ship). Wiring
remains CODE-owned (advisories in `assets/textures/postfx/README.md`,
`store/trailer/README.md`, `assets/audio/README.md`).
