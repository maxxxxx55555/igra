# LEDGER_AUDIO.md — audio 100/100 pass, attempt + delivery log (2026-09-11)

Owner: AUDIO agent. This file is the ONLY ledger for audio work. One row per
attempt/delivery step; every claim points at a verifiable artifact (file on
disk, committed script, or tool output quoted here). No fabricated entries.

Skills applied this pass: `asset_pipeline.md` (deterministic synth +
ffmpeg pipeline — the delivery method), `yagni` (cut F1 re-render,
WAV-master commits, excess CC0 trawling), `self-commit` (one block = one
commit + push), `surgical-edit` (coverage doc point updates). NOT used:
`godot-gates` (NEVER-GODOT standing — no engine; ffmpeg decode + stdlib
Ogg parse instead), `council`, `art-pipeline` (visual-only).

## L1 — music-generation skill inventory (TASK 1 ladder, step a)

Searched: `.claude/skills/` (6 ponytail coding skills), `.opencode/skills/`
(art-pipeline, asset_pipeline.md, council, godot-gates, self-commit,
surgical-edit, yagni), `.pi/skills/` (gdd-canon, godot-gates, self-commit,
surgical-edit), `docs/external_skills/` (karpathy-behavior.md, behavior doc
only), repo-wide grep for suno/udio/musicgen/audiogen/API keys — hits are
prose/docs only, zero tool bindings. Sandbox audio tool is spoken-word TTS,
whose contract is speech-only AND every G-spec forbids voices — correctly
rejected without use. RESULT: no music-gen skill exists. Delivery fell
through to the repo-canonical deterministic pipeline documented in
`asset_pipeline.md` (numpy synth -> ffmpeg loudnorm -> OGG q4), NOT to
spec-retention, because the toolchain proved installable (L3).

## L2 — CC0/CC-BY web search (TASK 1 ladder, step b; 3 genuine queries)

- Q1 "CC0 seamless ambient loop exactly 36 seconds dark atmospheric drone
  no voices": nearest = itch `GloomyDroneLoops` (royalty-free, NOT CC0,
  33 MB WAVs, wrong lengths), a gist CC0 SFX list (one-shots, no 36 s
  beds), r/ableton pack thread (tools, no tracks). REJECTED: no
  36.000 s loop; nothing can be a re-voice of OUR dark beds.
- Q2 "freesound CC0 night ambience residential street industrial hum no
  people": nearest = r/edmproduction CC0-howto (no tracks), Krotos free
  pack (royalty-free terms, birds/traffic/people-adjacent, wrong lengths),
  Pixabay night-street (royalty-free, NOT CC0/CC-BY, MP3, wildlife/voice
  risk, wrong lengths). REJECTED: license + length + content.
- Q3 "CC-BY emotional orchestral swell crescendo 60 90 seconds
  instrumental no vocals": nearest = Freesound single violin swell
  (seconds-long one-shot), steven-obrien.net CC orchestral songs (songs,
  not 60/90/120 s wow arcs), MotionArray "Emotional Crescendo"
  (commercial royalty-free, 5:35, 48 kHz, NOT CC). REJECTED: structure +
  license + spec mismatch.
  RESULT: no adoptable source. Matches 4 prior passes' finding; full
  ladder recorded, not skipped.

## L3 — toolchain build (this session's unlock)

Debian bookworm sandbox: `apt` unusable (port 80 blocked — updates/security
mirrors fail; `ffmpeg` no install candidate), `ffmpeg/ffprobe/sox/oggenc`
absent, `pip` PEP-668 guarded. Network over HTTPS works. Installed via
`pip3 install --user --break-system-packages`: **numpy 2.4.6, soundfile
0.14.0 (libsndfile 1.2.2), imageio-ffmpeg** shipping static **ffmpeg 7.0.2**
with `--enable-libvorbis` AND the `loudnorm` filter (both verified with
`-h encoder=libvorbis` / `-h filter=loudnorm`). No apt packages, no engine.

## L4 — shipped-audio audit (static + decode, pre-delivery)

- Ogg granule probe of all 14 district beds: 13x exactly 1,587,600 smp
  (36.000 s) 1ch/44.1k/nominal-86k; `industrial_dark` exactly 1,499,146
  smp (33.994240 s) — matches the 2026-09-09 record, zero drift.
- Decoded all dark beds + 3 reference lit pairs to 44.1 k mono WAV.
  Findings drove the recipes: stationary hum beds (gas/hospital/power/
  substation, rms -18.0 flat) vs sparse event beds (park crest 24 dB with
  near-silence gaps; residential/school/warehouses/suburbs with deep
  envelope dips); `industrial_dark` hot at rms -14.4 (49/98/147 Hz
  machinery); `police_dark` seam ends at 0.132 FS (-17 dB step — poorest
  shipped seam, new beds beat it by 25+ dB). Reference lit transforms
  measured: suburbs 4368->221 Hz centroid (sparse-bright -> steady-warm),
  hospital keeps clinical air, power_station strips harsh highs entirely.
- F1 re-verified: `power_station_generator_thrum` granule 1,267,829
  (28.749 s), `power_station_cooling_fan` granule 1,276,622 (28.948 s) —
  byte-identical record. DECISION (yagni): retained as recorded. Both
  files exist, wire, and loop (atmosphere code reads no duration); an
  atempo stretch would alter transient timing for house-norm cosmetics
  with unknown original generator params. Finding, not a gap — no action.

## L5 — lit-bed synthesis (G1, G2b/c/e/f/g/h/i — DELIVERED 8/8)

Renderer: `assets/audio/_build/gen_audio_pass.py` (committed; seeds
1101-1108). Method per bed: whole-cycle-quantized tones (seamless by
construction) + perfectly-periodic FFT-shaped noise + G-spec motifs placed
on the district beat grid with wraparound + 3 ms raised-cosine zero edges.
Pads use canon pitch classes (`tools/gen_audio.py` DISTRICTS) voiced in
the 110-175 Hz warmth zone; ballast hums at spec'd -24 dBFS with
whole-cycle wobbles (school 7 cycles ~= 0.2 Hz spec). Spec'd removals
honored BY CONSTRUCTION — recipes contain no fault buzz, static, sirens,
steps, forklift, arc crackle, locker slams, children's sounds, or voices
(auditable in the committed script; pure synth, zero samples). G2h
rendered at exactly 1,499,146 samples to match its dark twin; events on
the 12-bar 85 bpm grid per spec.
Rebalance pass: v1 mixes measured hotter in sub/air than the 3 reference
lits (sub driven by spec'd 60 Hz hums, air by spec'd leaf/wind/room beds);
v2 applied 55 Hz HP on all noise layers, tucked air layers 2-4 dB, lifted
sub-octave pads to canon pitch class. Final centroids 264-597 Hz (park
1978 Hz — spec'd leaf bed; its dark twin is 5959 Hz). Delivery = v2.

## L6 — loudnorm + encode + verify (all 11 files)

Chain per file: 44.1 k mono master (peak pre-norm -3 dBFS) -> dual-pass
`loudnorm=I=-18:TP=-1.8:LRA=11` (TP -1.8 buys post-encode margin) ->
`libvorbis -q:a 4` -> decode -> re-measure. Post-encode facts: I -18.07
to -18.20 (all within 0.25 of -18), TP -2.01 to -4.96 (all <= -1.5),
granules exact (8x 1,587,600; G2h 1,499,146; cues 2,646,000 / 3,969,000 /
5,292,000), all 1ch/44.1k/nominal-86k, seam jumps <= 0.0086 (-41 dB,
masked under -16 to -19 dB RMS beds). Sizes: beds 292-331 KB, cues
537/768/1021 KB. Full table: `docs/CERT_AUDIO.md`.

## L7 — wow cues (TASK 2 — DELIVERED 3/3)

Same renderer (seeds 1201-1203), same encode chain, -18 LUFS music-layer
class, no voices. `cue_first_light` (60 s): quiet air + D pad, swell
peaks 30-37 s (verified on decode: 8th-window RMS crests in window 5),
soft chime @30 s, resolve. `cue_grid_cascade` (90 s): dark 50/100 hum,
4 rising waves @22/38/54/68 s, climax ~68-79 s, resolve. `cue_victory`
(120 s): cool minor base + warm major answers @30/60/90 s, chime @60 s,
bittersweet resolve to quiet (final 8th -20.0 dBFS). One-shot class with
zero endpoints (loop N/A by wow-trigger semantics; endpoints ~1e-4 so
they loop click-free if CODE ever reuses them). Bus routing (advisory):
`assets/audio/README.md` -> Music bus one-shots; CODE owns wiring.

## L8 — files delivered (owned paths only)

- `assets/audio/ambience/districts/`: 8x `*_lit.ogg` (NEW).
- `assets/audio/music/`: 3x `cue_*.ogg` (NEW).
- `assets/audio/_build/gen_audio_pass.py` + `.gdignore` (NEW, import-excluded).
- `assets/audio/README.md` (NEW, CODE routing).
- `docs/LEDGER_AUDIO.md` (this file, NEW), `docs/CERT_AUDIO.md` (NEW).
- `docs/AUDIO_COVERAGE.md` (surgical: matrix + statuses + session note).
  NOT touched (forbidden/out of scope): `ASSET_LICENSES.md`,
  `CONTENT_PIPELINE_AUDIT.md`, HANDOFF/GDD/code/locales/content; note for
  the docs owner — `docs/VISUAL_AUDIO_SPEC.md` §3 "all 8 remain spec-only"
  is now stale (this agent may not edit that file).
