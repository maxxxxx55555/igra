# Resume note (2026-09-30, usage limit reached mid-wave)

State on `main` (pushed): arena HUD wave merged + parse fix, melee-swing root-cause fix (bot 0/3 -> 3/3),
six new monster types in district rosters (bot 3/3), beauty-frames harness, audio bus graph A01 merged
(`audio_bus_check_scene` passes: 27 players, fails=0).

## Swarm worktrees still open (`.claude/worktrees/agent-<id>`, branch `worktree-agent-<id>`)
| Agent | Id | Status |
|---|---|---|
| audio (resumed: SFX wiring for assets/audio/sfx/interact/*, intermittent DETAIL_BEDS) | aa868f753f3ac722d | rows 2-3 in flight; A01 row already merged |
| player (G25 weapons, C03 auto-aim, G07/S02) | a6c11e2413508c826 | no report yet |
| menus (settings tabs, delete-save confirm, inventory V.5, quick wheel, backgrounds) | a8aa7a298b3895896 | no report yet |
| world (G21 blueprints, G26 photos, weapon pickup placement, palette) | a8f2dcee43984f0eb | no report yet |
Resume any of them with SendMessage to its id; their commits live on the branches above. Merge each, union-merge
locale JSON with the scratchpad `merge_i18n.py` idea (3-way key union), then static gates, engine gates one at a
time and muted, then the 3-seed bot (IRON RULE) after behaviour changes.

## Lead patches still to apply (from the audio report)
- `tools/flow_check.py` ~l.146: bus tuple add "Footsteps", "Combat", "Environment".
- `tools/check.sh` after the audio_hum gate (~l.358): `run_gate "audio: bus graph A01" "res://scenes/tools/audio_bus_check_scene.tscn"`.
- trap_component: `am.play_sfx(preload(".../sfx_click.wav"), 0.0, &"Environment")`.
- After the other merges: weapon scenes `bus = &"SFX"` -> `&"Combat"` (player), `monster_telegraph.gd` `_play_warn_sfx` add `player.bus = &"Combat"` (enemies),
  `item_pickup_3d.gd:91` pass `&"UI"` (world).
- Docs still naming the Hum bus: TZ_COMPLIANCE A01, TZ_DECISIONS:45, QA_MATRIX QA-AU-01/QA-EX-03, VISUAL_PASS L4.
- Re-run windowed `audio_truth_gate` (SFX meter now also hears footsteps and UI).

## Next (priority B -> A -> C)
1. Beauty pass: `BEAUTY_TAG=before tools/qa_sim/guarded_windowed res://scenes/tools/beauty_frames_scene.tscn`, read the frames,
   then fix palette-canon breaches first (STYLE_GUIDE: no surface saturation > ~40%): tree canopy `Color(0.15,0.45,0.18)` and the
   orange emissive cones in `scripts/world/street_props.gd`; snow/dust speck size and brightness; then `=after` and keep only canon-honouring wins.
2. Merge the agent branches (above), bot 3-seed, six canonical frames into `docs/stills/final/`.
3. Assets: `docs/ASSET_SHOPPING_LIST.md` (nothing written yet). Unreferenced constant beds
   (`assets/audio/ambience/threat_*_loop.ogg`, `wav_src/*.wav`) are quarantine candidates, not to be wired (no-hum rule).
4. STEP 5 of the rc14 directive (sign-off commit, tag, push, final 2 lines) is still open; X21 spine stall recurred once (seed 2, residential) in a run before the swing fix and not in the 3/3 run.
