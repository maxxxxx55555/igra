# LEDGER_FINALE.md — AUDIO+VISUAL FINALE pass (2026-09-12)

Owner: CONTENT+ASSETS agent. This file is the ONLY ledger for the finale
pass. One row per attempt/delivery step; every claim points at a verifiable
artifact on disk. No fabricated entries.

Scope (standing order): `assets/audio/**`, `assets/textures/postfx/**`,
`store/trailer/**`, `docs/AUDIO_COVERAGE.md`, this file, `docs/CERT_FINALE.md`.
NOT touched (forbidden): `docs/ASSET_LICENSES.md`,
`docs/CONTENT_PIPELINE_AUDIT.md`, HANDOFF/GDD/code/locales/content. License
rows for this pass's new files are drafted in §F-LIC for the docs owner to
merge — this agent may not edit the central license file.

Branch note: the task brief names `arena/finale-pass`, but this Arena session
is fixed to `arena/01a09712-igra` (session-branch rule) — all work, pushes
and the PR stay on `arena/01a09712-igra`. No other branch created or pushed.

Skills applied this pass: `asset_pipeline` (palette lock, naming, OGG q4
contract, CODE-owned wiring pattern), `yagni` (cut lit-bed re-render and
repeat CC0 trawling — gaps already closed, see F-A2/F-A3; cut WAV-master
commits; cut per-district vignette colors — canon fixes one color, see F-V1),
`self-commit` (one block = one commit + push), `surgical-edit` (coverage-doc
point updates), `art-pipeline` (generation prompts recorded alongside the
art, in the owned `store/trailer/README.md`). NOT used: `godot-gates`
(NEVER-GODOT standing — no engine; stdlib Ogg parse + numpy/PIL pixel checks
instead), `council`. Sandbox speech tools (`add_voice`/`generate_speech`)
NOT used: spoken-word only by contract, and every lit-bed spec forbids
voices — rejected without use, as in all prior passes.

## F-A1 — music-generation skill inventory (TASK 1 ladder, step a)

Searched this session: `.opencode/skills/` (art-pipeline, asset_pipeline.md,
council, godot-gates, self-commit, surgical-edit, yagni), `.claude/skills/`
(6 ponytail coding-discipline skills), `.pi/skills/` (gdd-canon,
godot-gates, self-commit, surgical-edit), `docs/external_skills/`
(karpathy-behavior.md, behavior doc only), `docs/superpowers/` (specs dir),
plus repo-wide grep for suno/udio/musicgen/audiogen/music-gen — hits are
prose mentions in docs/plans/manifests only, zero tool bindings, zero API
keys, zero generator scripts for music. RESULT: no music-generation skill
(Suno/Udio/any) exists in this repo or sandbox. Refined-prompt generation
was therefore impossible to execute — recorded honestly, not faked.

## F-A2 — lit-bed gap verification (TASK 1: G1, G2b/c/e/f/g/h/i + F1)

Method: stdlib Ogg/Vorbis identification-header + final-page-granule parse
(no engine, no ffmpeg — same static method as the 2026-09-08/09/10 records).
Contract per bed: 1 ch / 44,100 Hz / OGG q4 (nominal 86k) / exact length
(36.000 s; G2h = 33.994 s twin-exact) / seamless whole-cycle master (per the
committed renderer `assets/audio/_build/gen_audio_pass.py`, seeds 1101–1108)
/ −18 LUFS + TP ≤ −1.5 (encode-time facts in `docs/CERT_AUDIO.md` §1–§3,
trusted, not re-measurable without a decoder here).

| Gap | File | ch/Hz/nom | Granule | s | Size | vs 2026-09-11 record | Verdict |
|---|---|---|---|---|---|---|---|
| G1 | residential_lit.ogg | 1/44100/86k | 1,587,600 | 36.000 | 318,252 B | identical | CLOSED (ships) |
| G2b | park_lit.ogg | 1/44100/86k | 1,587,600 | 36.000 | 330,927 B | identical | CLOSED (ships) |
| G2c | school_lit.ogg | 1/44100/86k | 1,587,600 | 36.000 | 305,943 B | identical | CLOSED (ships) |
| G2e | gas_station_lit.ogg | 1/44100/86k | 1,587,600 | 36.000 | 316,145 B | identical | CLOSED (ships) |
| G2f | police_lit.ogg | 1/44100/86k | 1,587,600 | 36.000 | 303,712 B | identical | CLOSED (ships) |
| G2g | warehouses_lit.ogg | 1/44100/86k | 1,587,600 | 36.000 | 304,521 B | identical | CLOSED (ships) |
| G2h | industrial_lit.ogg | 1/44100/86k | 1,499,146 | 33.994 | 292,188 B | identical, twin-exact | CLOSED (ships) |
| G2i | substation_lit.ogg | 1/44100/86k | 1,587,600 | 36.000 | 312,749 B | identical | CLOSED (ships) |
| F1 | generator_thrum / cooling_fan | 1/44100 | 1,267,829 / 1,276,622 | 28.749 / 28.948 | 220,543 / 222,943 B | identical | RETAINED (finding, not a gap) |

All 11 dark beds + 3 reference lit pairs + 3 wow cues re-walked in the same
probe: every granule/size matches the 2026-09-11 record byte-for-byte — zero
drift, zero missing files. The brief's premise ("8 lit-bed gaps remain
spec-only") is stale: the 2026-09-11 audio pass closed all 8 with verified
binaries, and they still ship. Beds delivered this pass: 0 new binaries
needed — 8/8 already delivered and re-verified.

## F-A3 — ladder step (b) disposition (CC0/CC-BY search: correctly skipped)

The brief's step (b) (web-search CC0/CC-BY with the exact contract) triggers
only for *remaining* gaps. F-A2 proves zero gaps remain, so no search was run
this pass — running theater searches for already-closed gaps would violate
both `yagni` and the convergence rule. Search history stands: 3 genuine
queries with documented rejections in `docs/LEDGER_AUDIO.md` L2 (plus all
prior passes' attempts). No spec-retention was needed: there is nothing left
to retain — every G-spec in `docs/AUDIO_COVERAGE.md` carries a "Delivery
(2026-09-11)" line pointing at a shipped, certified binary.

Loudness honesty note: integrated LUFS / true-peak cannot be re-measured in
this sandbox (no Vorbis decoder, no ffmpeg — `which` confirms absent). The
F-A2 verdicts rest on exact header/granule/size identity with the certified
2026-09-11 encode; loudness facts are inherited from `docs/CERT_AUDIO.md`
§1–§3, not re-claimed as fresh measurements.

## F-V1 — cinematic post-fx presets (TASK 2 — DELIVERED 11/11)

`assets/textures/postfx/presets.json` (v1) + `assets/textures/postfx/README.md`
(NEW dir). Data-only JSON table district→{bloom,vignette,chroma,grain};
conservative values grounded in `docs/VISUAL_AUDIO_SPEC.md` §1 moods and the
shipped LUTs: bloom 0.12–0.35 (fog districts highest, hospital lowest —
warm-absent stays cold), vignette 0.45–0.60 in `#0c1016` (GDD §11.2 canon
color for all 11 — per-district vignette colors cut per `yagni`, the LUT
already owns per-district color), chroma 0.5–1.0 px @1080p, grain 0.08–0.12
(GDD §11.4 band). Twins stay twins (residential=suburbs,
industrial=warehouses, power_station=substation).

CODE mapping verified read-only against shipped consumers (not edited):
bloom → `Environment.glow_*` on `env_night` (no glow keys today — additive);
vignette/grain → `PostProcessOverlay.set_vignette_strength` (clamp 0–0.7) /
`set_grain_intensity` (clamp 0–0.15) — every preset inside both clamps;
chroma → NEW uniform, no shipped consumer (marked as such in README);
suggested switch point `district_grading.gd` `_apply()` + stack order in README.

Verification (numpy/PIL sim over palette-locked `still_first_light`, base
18..239): FULL-strength stack (0.35/0.60/1.0px/0.12) with the EXACT shipped
shader math (add-only grain veil, shipped vignette formula) grades to
14..236, **0 pure-white / 0 pure-black / 0 >250 texels**, contrast 98.6%
retained — readable, nothing blown. (A first stress sim with symmetric grain
and 2.2× bloom gain showed 18 white/88k black texels — disclosed here as a
sim artifact, not shipped behavior; faithful-math rerun is the verdict
basis.) Full numbers: `docs/CERT_FINALE.md` §2.

## F-T1 — trailer hero shots (TASK 3 — DELIVERED 4/4)

4 NEW masters in `store/trailer/` (Arena text-to-image, this session):
`hero_first_restore_1920x1080.png` (1920×1080, 3607 KB, Shot A),
`hero_grid_cascade_1920x1080.png` (1920×1080, 3995 KB, Shot B),
`hero_reactor_room_1920x1080.png` (1920×1080, 3995 KB, Shot C),
`hero_shorts_cut_1080x1920.png` (1080×1920, 3532 KB, vertical).
Finish chain (numpy 2.4.6 + pillow 12.3.0, seeds 101–104): Lanczos to exact
canvas → district LUT trilinear @0.55 (A/D `lut_suburbs`, B/C
`lut_power_station`) → bloom 0.30 → vignette (shipped formula) 0.50/0.60/0.55
→ radial chroma 0.75px → grain (shipped add-only math) 0.10/0.12 → clamp
[10,240]. All 4: exact dims, 0 pure-white / 0 pure-black texels, min 10 max
240, visually QA'd (no text/HUD/watermark, subjects in center band).
Deliberate override of the `asset_pipeline` "skip grain on store art" rule:
the brief demands filmic grain on these masters and they are marketing
sources (re-exported on upload, never runtime textures) — the ~1 MB grain
cost is disclosed, not hidden. Prompts + exact Godot stack values recorded in
`store/trailer/README.md`; facts in `docs/CERT_FINALE.md` §3.

## F-LIC — license rows DRAFTED for the docs owner (do not merge from here)

This agent is forbidden from editing `docs/ASSET_LICENSES.md`. Draft rows for
the docs owner to merge verbatim: (1) `assets/textures/postfx/presets.json` +
`README.md` — project-authored preset data (this session), no third-party
rights; (2) 4× `store/trailer/hero_*.png` — project-owned AI output (Arena
image generation, this session; finished with project LUTs/shaders), no
third-party rights, no attribution required. No audio binaries this pass
(nothing new to license).

## F-A4 — audio files touched (owned paths only)

- `docs/AUDIO_COVERAGE.md` (surgical: finale-pass note appended — matrix
  untouched, all rows already correct).
- This file (F-A1…F-A4).
- No new audio binaries: none needed (8/8 ship). No rewrites, no renames.
