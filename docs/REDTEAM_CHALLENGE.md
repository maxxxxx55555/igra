# REDTEAM_CHALLENGE — truth gates hardened, missed features, fixed-vs-symptom audit

**Role:** independent static red-team. Evidence baseline `c1ebeec`. Every claim cites
`file:line` or a config key. Companion: `docs/RENDERING_DIAGNOSIS.md`, `docs/I18N_DEFECTS.md`.

**Ground-truth note (one line):** `tools/*truth_gate*.py` has NOT landed (`ls tools/` = 23
entries, zero truth-gate scripts), so this document names and hardens the three truth gates
against the repo's *actual* truth-claiming stand-ins — the ones whose green output a reader
would reasonably mistake for "the player sees/hears/plays the real game".

---

## 1. The three truth gates — each: a concrete PASS-while-broken scenario + exact hardening

### TG-SEE — the frame is what the design says (visual truth)

**Current stand-in:** `res://scenes/tools/capture_stills_scene.tscn` +
`scripts/tools/_capture_stills_bootstrap.gd` (8 canonical stills; success = `img.save_png()`
returns OK, `_capture_stills_bootstrap.gd:41-52`) and `theme_unify_probe_scene.tscn`
("chrome visible on all screens", wired at `tools/check.sh:205`).

**PASS-while-broken scenario (this is not hypothetical — it is the live bug):** the 2026-09-21
capture run produced 8 successfully-saved PNGs and a clean theme probe while the 3D world was
severe magenta corruption (`docs/KNOWN_ISSUES.md`, "CRITICAL, NEW, NOT FIXED"). `_shot()` only
asserts the PNG *write* (`_capture_stills_bootstrap.gd:47` `_shots_taken[name] = err == OK`);
theme_unify only reads UI chrome styleboxes (`scripts/tools/_theme_unify_probe.gd:24-39`).
A build that renders the whole world magenta passes both.

**Hardening patch (exact):**
1. *Extra frame regions + threshold* — extend `_shot()` with a pixel probe before
   `save_png`: split `img` into (r1) HUD-top band `Rect2i(0,0,w,h*0.18)` (health/stamina/
   battery + radar live here per `scenes/ui/hud_3d.tscn:47-303`), (r2) world band
   `Rect2i(0, h*0.30, w, h*0.55)`, (r3) quickbar band bottom `Rect2i(0, h*0.85, w, h*0.15)`.
   In r2 compute `magenta_ratio` = share of pixels with `R > 0.35 && B > 0.35 && G <
   min(R,B)*0.75` (magenta/purple hue) **or** per-pixel saturation > 0.55 while the frame's
   median saturation < 0.2 (colored-noise outlier — catches the dot/streak pattern that is
   magenta-*biased* rather than pure magenta). **FAIL the shot if `magenta_ratio > 0.005`**,
   and always print the ratio (trend data even on pass).
2. *Reference-color probe* — r2 must contain no more than 2% pixels within ΔRGB 0.12 of the
   project clear color `Color(0.03, 0.03, 0.05)` (`project.godot:313`,
   `environment/defaults/default_clear_color`) in districts at FULL stage (a flood of clear-color
   pixels = the world failed to draw at all).
3. *Readback-artifact discriminator* — the probe runs on `get_image()` (the same readback that
   the open question in `docs/KNOWN_ISSUES.md` suspects); add a `--windowed` mode where a human
   confirms the on-screen frame against the saved PNG once per release. Until that eye-check
   exists, the gate result must print `REBACK_UNVERIFIED` next to its verdict — a magenta PNG
   cannot be honestly called "world broken" or "capture broken" by this gate alone.

### TG-HEAR — the player hears the designed mix (audio truth)

**Current stand-in:** `res://scenes/tools/audio_hum_check_scene.tscn` +
`scripts/tools/_audio_hum_check.gd` — after 10 idle frames asserts `_audio_unlocked == false`
and that MusicManager's `_a`/`_b`/`_layers` players are not `.playing` (`_audio_hum_check.gd:14-31`).

**PASS-while-broken scenario:** the gate only proves the *pre-input silence* invariant. A build
where the post-unlock mix is permanently silent passes it forever: the player who presses a key
hears no music, no hum, no footsteps — total audio breakage — while TG-HEAR is green. Second
scenario: broken bus routing (e.g. the Hum bus fed through the SFX send per
`docs/QA_MATRIX.md:88`) — every `AudioStreamPlayer.playing` flag is `true` (state is fine) while
the device outputs silence/overs; headless runs on the dummy audio driver and never mixes a
sample, so no existing probe can see this.

**Hardening patch (exact):**
1. *Post-input phase + bus-peak thresholds* — after the existing pre-input assertions, synthesize
   one `Input.action_press("move_up")` / `InputService` touch equivalent (the unlock path per
   `docs/SESSION_REPORT_TRUTH.md` P0.2: `InputService.player_acted` gates audio unlock), then at
   3 gameplay moments (boot→menu music start, first in-range streetlight hum, one injected
   footstep) sample `AudioServer.get_bus_peak_volume_left_db(idx, 0)` for `Master/Music/SFX/
   Ambient/Hum` over ≥ 30 frames each. Thresholds: pre-input all buses ≤ −80 dBFS (true silence,
   replaces the flag-only check); post-unlock `Music` peak ≥ −45 dB within 120 frames of menu
   ready; `SFX` peak ≥ −40 dB in the injected-footstep window; **no bus peak > −1.5 dBFS**
   (`docs/STYLE_GUIDE.md:80` audio budget: "true peak ≤ −1.5 dBFS") and no `Master` clip.
2. *Extra probe — the un-probed player:* assert `StreetlightHumPool`
   (`project.godot:92`, `scripts/systems/streetlight_hum_pool.gd`) actually starts/stops a voice
   as the player crosses a lamp radius — flag-check `get_children()`-level players or pool
   counters; today "hum" coverage is one slider row (`docs/QA_MATRIX.md:88`), the pool itself has
   zero tests (§2 MISSED-03).
3. *Flag honesty* — while the run is `--headless`, print `DUMMY_AUDIO` and treat volume
   thresholds as SKIP-not-OK (same pattern as the draw-call gate's honest skip,
   `tools/check.sh:206-208`); real thresholds only apply in `--windowed` runs.

### TG-PLAY — the real game loop completes where a player can see it (gameplay truth)

**Current stand-in:** `game_test_3d_scene.tscn` (phases 1–7, `scripts/tools/_game_test_3d.gd`)
+ the autoplay bot 3-seed wins + `tools/flow_check.py` (53 static assertions,
`tools/check.sh:225-228`).

**PASS-while-broken scenario (already happened):** 3 separate all-headless 3-seed bot re-runs
won clean on the exact codebase where a windowed run reached `park` via the City Map **Travel**
button and produced `player.global_position = (inf, inf, inf)` until the 45s watchdog called it
(`docs/KNOWN_ISSUES.md`, "City Map \"Travel\" to `park`…"). The bot's steering depends on a live
camera (`_qa_autoplay_runner.gd` `_dir_to()` → `get_viewport().get_camera_3d()`) and never took
that entrypoint windowed — the gameplay gate suite was green across 3 seeds while a
player-observable softlock was one click away.

**Hardening patch (exact):**
1. *Invariant probe (cheap, always-on)* — in the runner's existing per-heartbeat watchdog add
   `is_finite` on `player.global_position` and require `get_viewport().get_camera_3d() != null`
   once PLAYING; **inf/NaN ⇒ immediate FAIL line `INVARIANT_FAIL pos/camera`** (not a 45s
   no-progress timeout). Threshold: 0 invariant failures, 0 `SOFTLOCK` lines per seed.
2. *Extra probe — entrypoint coverage* — count `DistrictManager.transition_to` call sites
   exercised per run (walk-in vs `city_map.gd:_travel`); a run that wins without touching every
   public entrypoint must exit `INCOMPLETE`, not 0. This is the exact hole the park bug came
   through.
3. *Nudge-as-mask counter* — log and cap stuck-nudge events (`docs/KNOWN_ISSUES.md` documents
   nudge rescues masking navigation failures; `scripts/player/player_3d.gd` nudge window was
   itself the previous bug). A "clean" 3-seed claim requires the win with **nudge count ≤ 1 per
   seed** — wins bought by nudges are navigation defects, not passes.

Riskiest assumption of §1 (verified by reads): that the three stand-ins above are what the team
means by "the three truth gates" — `tools/*truth_gate*.py` never landed (proof in the ground-truth
note) and these are the only artifacts asserting see/hears/play truth today (`tools/check.sh:149-228`).

---

## 2. Independent feature inventory vs FUNCTION_MATRIX → MISSED list

**Method:** inventory built from `project.godot` `[autoload]` (57 entries, `project.godot:44-116`),
`[input]` action map (`project.godot:18-285`), and UI signal wiring observed in
`scripts/ui/*.gd` (`EventBus.district_stage_changed/boss_spawned/game_won/player_detected/
settings_changed/item_consumed/secret_found/district_entered` call sites). Diffed against the
matrix artifacts that actually exist.

**FUNCTION_MATRIX.md does not exist** — `docs/` has no such file (full `ls docs/`); the closest
living artifacts are `docs/QA_MATRIX.md` (70 cases, sections A–N) and `docs/GDD_CONFORMANCE.md`
(GDD §-rows). `→ MISSED-00` is structural; the rows below are features present in code that
**both** living matrices leave unproven (grep counts over `docs/QA_MATRIX.md` given).

| id | feature (code evidence) | QA_MATRIX hits | gap |
|---|---|---|---|
| MISSED-00 | the FUNCTION_MATRIX artifact itself | — | no canonical feature↔test matrix exists; inventories must be rebuilt per session (this table) |
| MISSED-01 | `LocalLeaderboard` (`project.godot:107`, `scripts/systems/local_leaderboard.gd`) | 0 | local high-score flow has no case row |
| MISSED-02 | quick wheel — input action `quick_wheel` (`project.godot:272-277`) + `scripts/ui/quick_wheel_ui.gd` spawned at `scripts/ui/hud_3d.gd:275-282` | 0 | hold+analog-select UI never exercised by any case |
| MISSED-03 | `StreetlightHumPool` per-lamp spatial hum (`project.godot:92`) | 0 (the 4 "hum" hits are QA-AU-01's bus slider + the word "human") | pool start/stop vs lamp radius, `hum_sync` behavior untested (see TG-HEAR hardening 2) |
| MISSED-04 | `RandomEvents` (`project.godot:112`, `scripts/systems/random_events.gd`; note the commented duplicate at `project.godot:87`) | 0 | runtime random-event dispatch has no case row |
| MISSED-05 | `PlayIntegrityService` (`project.godot:114`, `scripts/systems/play_integrity_service.gd`) | "integrity" hits are all save-envelope rows (QA-SEC-01…04, `docs/QA_MATRIX.md:153-168`) | store-side Play Integrity path is unprobed — word collision with save integrity hides it |

Riskiest assumption of §2 (verified): that a zero grep count means "untested", not "tested
under another name" — spot-checked each zero-hit term in its likely synonyms (`leaderboard/
high-score`, `quick wheel/weapon wheel`, `hum pool/lamp hum`, `random event/event`, `play
integrity/attestation`) before assigning the ID.

## 3. FIXED-THIS-PASS verification — root cause vs symptom-mask

Rows cover the current session's fixes and the fixes the repo's own docs claim recently
(squashed history (`git log` = single commit `c1ebeec`) means diff-verification reads the
claimed diffs in `docs/KNOWN_ISSUES.md`/`docs/PLAN.md` instead of commit patches).

| id | claimed fix | root cause addressed? | verdict |
|---|---|---|---|
| FIX-01 | i18n native-quality pass (this session, `fix(i18n): native-quality pass`, 161 value edits — see `docs/I18N_DEFECTS.md`) | yes — meaning-breaks (fr `SECRET_SCHOOL_02_TITLE` "sous-alimentation", ja `LORE_RESIDENTIAL_03_TEXT` stray "why"), name collisions (MONSTER_BURNER vs ENEMY_ARSONIST in 5 locales), glossary drift (ru "бригады энергосети/энергетиков"), length-band bloat | verified: 1291-key parity ×13, printf-placeholder multiset 0 mismatch vs en, `tools/check.sh --static` 12/12 green |
| FIX-02 | `tools/check.sh` game_test_3d timeout 90s→170s (`docs/KNOWN_ISSUES.md` "DIAGNOSED … P8") | partial by design — it fixes *opacity* (the scene's own 150s diagnostic now fires, `scripts/tools/_game_test_3d.gd:24`) but not the phase-7 stall it revealed | **CHALLENGE-01:** phase-7 synthetic boss harness still fails (`_game_test_3d.gd:138-162` null boss `get()` errors). The gate currently reports FAIL every full run — do not file the timeout bump as a gameplay fix, and don't let "it times out with a message now" become "it passes". |
| FIX-03 | stuck-nudge duration 1.2s→0.25s `b7213ac` (spine softlock) | **symptom-reduction** — the repo's own CORRECTION entry records the exact signature recurring after the fix (`docs/KNOWN_ISSUES.md` "CORRECTION … much rarer, reproduced once more") | **CHALLENGE-02:** mechanism (bot stop distance 1.4–1.5m vs 1.0m true contact radius) is alive; any "RESOLVED" needs ≥10 seeds with nudge-count ≤ 1/seed (TG-PLAY hardening 3). Don't re-try the two rejected hypotheses listed there. |
| FIX-04 | boss Y-dip rescue `acddc80` (vertical separation check in `_boss_keep_near_player`) | yes — matches the measured mechanism (`boss_pos.y` 1→−33 with 3D-distance-only rescue, `docs/KNOWN_ISSUES.md` "RESOLVED … root cause was the Y-dip") | verified against the entry's telemetry; watch the 2/3-win residual as budget, not as a new bug report |
| FIX-05 | "SSR/SSIL/SSAO/volumetric ruled out" (`docs/KNOWN_ISSUES.md` magenta entry) | **invalid elimination** — the A/B edited `assets/env/night_environment_desktop.tres`, which has zero load sites; the live toggles are `scripts/world_env_setup.gd:182-184` + `scripts/systems/settings_manager.gd:494-495` (see `docs/RENDERING_DIAGNOSIS.md` §d) | **CHALLENGE-03:** re-run the A/B on the live path before this "ruled out" line is cited again; ranked fix 1 in the diagnosis menu |

Riskiest assumption of §3 (verified): that `b7213ac`/`acddc80` refer to real diff contents —
both are described in enough detail in `docs/KNOWN_ISSUES.md` to reconstruct the exact changed
condition (nudge window duration; vertical-vs-3D separation) and both carry their own honest
residuals, which is what the verdicts above check against.
