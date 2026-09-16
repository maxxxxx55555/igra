# QA_MATRIX — 40 manual test cases (feel & release scope)

Date: 2026-09-16 · Owner: game-feel & QA pass · Skill: `ponytail` (full)
Scope: test *specification* only — no code, no assets, no gate scripts edited.
Companion docs: `docs/GAMEFEEL_SPEC.md` (what we also assert feel against),
`docs/BALANCE_MATRIX.md` (data snapshot the expectations are read from).
Cross-referenced with `docs/VISUAL_PASS.md` §6/§10, the accessibility record
in `docs/KNOWN_ISSUES.md` ("Accessibility toggles — 5 of 7 were non-functional",
2026-09-10) and `docs/HOW_TO_TEST.md` (this matrix does not repeat its
menu/settings smoke items; IDs below are the deep checks).

## Executor legend

| Executor | Who / how | Environment |
|---|---|---|
| **bot** | deterministic script, exits 0/1 — `tools/check.sh --static`, `tools/flow_check.py`, `python3 tools/qa_sim/a11y_check.py`, `tools/qa_sim/balance_sim.py`, `tools/qa_sim/autoplay_bot` (seeds 1–10, see KNOWN_ISSUES: gas_station spine flake is *known-failing*, do not re-litigate from this matrix) | sandbox OK (no engine) |
| **local-agent** | agent with headless Godot 4.7 (owner's `TLS_Build` exe): gate scenes `compile/signal_arity/i18n/asset_check`, `tools/qa_sim/headless_suite`, `scripts/tools/_qa_*` probes, `shot_tool` captures | needs Godot binary — NOT available in this sandbox |
| **owner-eyes** | human on device: feel judgments, audio listening, real dailies, phone/pad, exported builds | device |

Rule: a case is only ✅ when *every* executor listed passes; a bot-only "pass"
never closes a feel or export case.

---

## A. Save / load (QA-SL-01 … QA-SL-07)

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-SL-01 | Start New Game, collect 1 battery; save to slot 1 from the save-slots screen (`scenes/ui/save_slots.tscn`); quit to menu; load slot 1 | Item present; district stage + position restored; `user://tls_savegame.save` atomic-write (no temp litter beside it); signal `game_loaded` fires and HUD bars refresh in the same frame | local-agent |
| QA-SL-02 | Play until an autosave fires; check slots UI | Autosave is **slot 4** and is marked `is_autosave`; the last **3** autosave backups exist (anti-tamper rotation, save_system STEP 4) — deleting the newest recovers the previous one, not an empty game | local-agent |
| QA-SL-03 | Find any secret (`secret_found` fires) without touching a save menu | Save happens implicitly (save_system connects `secret_found` → `_save()`); kill the process (SIGKILL) 3 s after finding the next secret; relaunch; secret still taken, journal intact, no toast replay | bot (static wiring) + owner-eyes (kill/relaunch) |
| QA-SL-04 | Export a save (`export_save_to_file` → `tls_save_export.json`), delete the live save, import it back | Import restores; **slot** saves are not touched by export/import (documented limitation, save_system header) — must match README/`docs/OWNER_RELEASE_PACKET` wording; foreign `user://` dir (fresh profile) also accepts the file | local-agent |
| QA-SL-05 | Take a valid save file and set `won=true` / bump coins above `MAX_COINS` (9 999 999) with a text editor; load it | A forged win must never *grant* win/progress state (documented policy in save_system.gd:111: "progress to empty rather than trusting a forged win" — record which branch ran: refuse-vs-zero-out, and it must be the *same* branch as the unit intent, not new behavior); `_read_validated` blocks the load cleanly — no crash, no partial state, playable from the last valid autosave; coins clamp via MAX_COINS watchdog | local-agent |
| QA-SL-06 | Main menu → "New Game" on a profile that already finished the game once | Fresh level/XP/skill points: `reset_all()` actually calls `XpManager.reset()` + `SkillTreeManager.reset()` (TRUTH WAVE regression — a claimed-done bug; re-verify, don't assume); district stages all DARK again (11 districts, stage 0) | local-agent |
| QA-SL-07 | Save with 13 locales cycled + 2 different graphics tiers across save/load | Settings live in `user://settings.cfg` and re-apply on boot (language index maps via LANGUAGES order — historical mismatch fixed; language survives); saved district parity matches loaded world (CLAUDE.md "already done" list — verify the verifier, not the claim) | bot + owner-eyes |

## B. New Game+ (QA-NG-01 … QA-NG-04)

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-NG-01 | Complete the game, start NG+, start again through the ceiling | `activate_ng_plus` advances 1→3 and returns false past `MAX_NG_PLUS=3`; scaling matches the live table (BALANCE_MATRIX §A: +25 % XP, +20 % enemy HP, +15 % enemy dmg, +10 % player dmg, +10 % loot **per level, additive**); `difficulty_scaled` emits once per activation | bot (balance_sim parses constants) |
| QA-NG-02 | NG+1: select `long_night`, then try `blackout_plus`; also select `whisper` then try `sprint` | Both refused (`exclusive_with` checked **both directions** — code guards against asymmetric content edits); selection persists across save/load (`_save_save`); after refusing, active list unchanged | local-agent |
| QA-NG-03 | NG+1 with `ghost` selected: kill a trash mob; complete an achievement trigger | `coins_changed` payout is *not* × rewards (ghost has no rewards knob) but achievement is **logged, never granted** (`achievements=false` blocks unlock per ngp contract notes); crawlers never aggro | local-agent |
| QA-NG-04 | Search the repo for consumers of `data/ng_plus_config.json` and the `ng_plus_start/ng_plus_complete/all_secrets/all_docs/pacifist` achievement IDs | **Expected finding:** zero code references (BALANCE_MATRIX outlier O1) — the five "unique_achievements" are NOT implemented; either content adds them to the achievements source or the dead JSON retires. This row documents the check so the promise never ships half-open. NOTE: this row can pass in two shapes (file removed **or** achievements wired); "file present + unreferenced + achievements referenced anywhere in UI" = FAIL | bot |

## C. Secrets (QA-SE-01 … QA-SE-05)

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-SE-01 | Boot, open `content/secrets.json` in-game path: visit suburb `secret_suburbs_01` at stage 0 | Interactable (group `interactable`, `can_interact()` true at min_stage 0); taking it emits `secret_found`, grants reward item ×amount, adds XP, advances `q_secrets_*` quest, ticks daily `find_secrets`, and **also** bumps ProgressTracker's persisted `secrets` counter; toast shows localized `SECRET_SUBURBS_01_TITLE` | local-agent |
| QA-SE-02 | Try to interact with a min_stage-2 secret while its district is at stage 0/1 | Node invisible and non-interactive; lights district up one stage → it appears without re-entering the district (`district_stage_changed` re-gate in `secret.gd::_refresh_gate`) | local-agent |
| QA-SE-03 | Autoplay-bot full spine run (seeds 1–10, `tools/qa_sim/autoplay_bot`) | Bot may touch secrets but must never **soft-lock** on one (the `home_district` naming trap documented in secret.gd header — bot duck-types `district_id`); run completes to boss. gas_station spine flake = known, pre-existing | bot |
| QA-SE-04 | Find 3 secrets in a run, reach the finale | Truth ending gate (`secrets >= 3` in endings) unlocks the option; endings UI states the requirement truthfully (reachability README + world_refs contract — a secret hint may only reference districts in its reveal closure: `audit_content_depth.py` enforces statically) | bot + owner-eyes (ending presentation) |
| QA-SE-05 | Take `secret_X` twice in one session, then reload the save from *before* it | Cannot re-take (`_taken`); after reload **before** the autosave captured it — if the pre-pickup save is loaded, the secret is available again and re-taking it must not double-count quest progress beyond target clamp | local-agent |

## D. Dailies (QA-DA-01 … QA-DA-05)

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-DA-01 | Fresh install; record today's challenge ID; restart the game 3× | Same ID each boot (`_roll_for_today` = `unix_day % 60` over `content/daily_challenges.json` templates; the 30-template `data/daily_challenges.json` is only a missing-file fallback, and when used the ID must still be stable); progress carries within the same UTC day | local-agent |
| QA-DA-02 | Complete today's daily (e.g. kill target) | `completed(reward)` emits once; coins land via wallet + streak bonus; `ui_daily_complete_sting.ogg` plays exactly once on the UI bus (UISFX); second trigger attempt same day is ignored (`_completed_today`); `user://tls_daily.json` records `last_completed_day` | local-agent |
| QA-DA-03 | Complete the daily, quit, change system date +1 day, relaunch | New daily rolls, `_completed_today` false, streak +1 per `SaveSystem.get_daily_streak()`; skip 2 days → streak resets, no phantom bonus; at day 7/30/100 exactly, `streak_milestone_sting` plays and 150/750/3000 coins pay once | owner-eyes (+ local-agent on clock control) |
| QA-DA-04 | Set a `play_minutes` or `no_flashlight_segment` daily; pause; open menus; alt-tab | Timer accrues **only while `GameManager.is_playing()`** (`_process` guard) — pause/inventory/menus must not tick; `no_flashlight_segment` resets `_dark_seconds` the moment the flashlight turns on mid-segment | local-agent |
| QA-DA-05 | Read all 60 daily flavor strings in all 13 locales | Each template has `i18n_key` + `en.flavor`; parity gate green (no locale missing a daily line); the 11th-of-each-type spread (10–780 coin rewards) matches BALANCE_MATRIX §D; nothing references removed mechanics | bot |

## E. Audio (QA-AU-01 … QA-AU-05)

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-AU-01 | Settings → Audio: move Master/Music/SFX/Voice/Ambient sliders one at a time during gameplay in a fog district | Five buses independent (`default_bus_layout.tres`, buses exist — static check 2026-09 pass asserts it); Ambient governs district atmosphere (PHASE 2 note); the new **Hum** bus (VISUAL_PASS L4) is audible but governed through SFX send — no sixth slider is required | owner-eyes |
| QA-AU-02 | Boss encounter (first player contact, not spawn): stand at 5 m and at 60 m in fog | `architect_sting.ogg` plays once at −2 dB 3D; Tvar's sting is once-per-encounter (`_sting_played`); cues are one-shots — the looping-player leak fix holds (WAV `loop_mode` stripped in `play_cue`); music switches via `MusicManager.enter_boss` | local-agent + owner-eyes |
| QA-AU-03 | Delete/rename `ui_secret_discovery_sting.ogg` in a throwaway build; find a secret; restore file | With the file: real sting only. Without it: procedural `_gen_chime()` fallback fires **and does not double-play** with the real one (`_has_ui_sting` guard); no error spam | local-agent |
| QA-AU-04 | Loudness spot-check: `sfx_hit.wav`, `thunder_near.wav`, rain loop vs ambience bed | SFX one-shots ≈ −14 LUFS / loops ≈ −18 LUFS per PRODUCTION_BIBLE §3 + `docs/AUDIO_LOUDNESS.md`; TP ≤ −1.5 dBFS per the Bible (the GAMEFEEL V2 batch delivered against a tighter ≤ −1.0 target — thunder at −1.45 passes both); thunder is *not* louder than gunfire by >3 LU momentary | owner-eyes (+ bot meter via `ffmpeg loudnorm` print) |
| QA-AU-05 | Death: measure the beat end-to-end | Death slow-mo + red fade completes within GAMEFEEL_SPEC 3.20 budget (≤ 1.0 s **real** — today's `create_timer(1.0)` under `time_scale 0.3` runs ≈ 3.33 s: this row FAILS until the 🟨 fix ships; file the finding, don't "expect 3.33 s" forever); `game_over` fade 0.6 s per VISUAL_PASS §6 | owner-eyes |

## F. i18n (QA-I18N-01 … QA-I18N-04)

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-I18N-01 | In-game, switch language on the Settings screen while the shop (or bestiary/achievements) is open | Live re-translation of the open screens (KNOWN_ISSUES: "All screens now cover live language switch" — re-verify the shop, since the fix predates the daily UI: daily card flavor must retranslate too); zero raw keys (`SECRET_SUBURBS_01_TITLE`) shown anywhere | owner-eyes |
| QA-I18N-02 | Run `bash tools/check.sh --static` after any content JSON edit | i18n parity: 13 locales × same key set; `missing_keys.json` stays `{}`; ru/en printf placeholders aligned; LANGUAGES order in settings_manager == LocalizationManager.SUPPORTED (index-mapping regression guard) | bot |
| QA-I18N-03 | Arabic + Japanese: open the daily UI, NG+ modifier picker (`NGP_*_NAME/DESC` from `content/ngp_modifiers.json` `en` source), secrets journal | CJK renders without tofu (font covers ja/ko/zh — `docs/STATIC_AUDIT`/font passes); ar flips layout *without* breaking the banner/HUD (district_banner uses fixed 440×48 box — check uppercase Latin-only district ids stay legible: banner shows `String(id).to_upper()`, which is **not localized** — that is a finding: expected = id label localized via `district_<id>` keys; see KNOWN_ISSUES "api/i18n/asset" pass) | owner-eyes |
| QA-I18N-04 | Diff `data/i18n/*.json` vs strings in code (`LocalizationManager.t(` calls) | Every settings label used by the a11y tab (incl. the three PROPOSED toggles from GAMEFEEL_SPEC §2 when they ship) resolves in all 13 locales; en-source contract honored for content files (`ngp_modifiers.json`: CONTENT never edits locales — i18n_keys only) | bot |

## G. Accessibility (QA-AC-01 … QA-AC-06)

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-AC-01 | Toggle each of the 5 live a11y controls (colorblind ×3 modes, text size ×3, high contrast, arachnophobia, reduce screen shake) then reboot | Effect visible *and* persists (`settings.cfg` + `apply_all_accessibility` deferred re-apply — the 2026-09-10 fix); arachnophobia swaps crawlers without crashing (historical `is_instance_valid` bug) | local-agent |
| QA-AC-02 | `reduce_screen_shake` on: trigger first-light WowDirector hit, boss intro trauma 0.30 (spec 3.12), death shake | Zero camera offset every frame (probe: `Camera3D.position == _base_position` during all three); `add_trauma` early-return is the single choke point | local-agent |
| QA-AC-03 | Text size = Large, HUD opacity = 50 %, high contrast on: open pause, daily UI, journal | No clipping/overflow (overflow_check: `python3 tools/qa_sim/overflow_check.py` green); text-size remains **partial by design** — screens with hard-overridden font size are *known gaps*, list any NEW offender in the ticket; contrast: brass/bone on panel readable, no pure #fff/#000 (palette ban) | bot + owner-eyes |
| QA-AC-04 | Colorblind tritanopia: play a full district with threat markers, LUT-graded fog district, brass interact prompts | Threat tiers stay distinguishable **by shape** (threat icons are green→amber→ember *and* bar-count, per REPORT_GAMEFEEL_V2 T2 — the count makes them CBI-safe); no information conveyed by red/green only (interact prompts, HP ember) | owner-eyes |
| QA-AC-05 | Photosensitive pass: record 30 s of the cascade wow (3.25), stinger vignette (3.11), and any shipped full-screen flash | ≤ 3 luminance flashes/s anywhere; full-screen high-alpha ≤ 2 frames (33 ms); shake peak measured ≤ 4 px @1080p at trauma 0.15/0.30/0.55 (method in GAMEFEEL_SPEC §6.4) — if 0.55 fails, the fix is the `shake_intensity` clamp, not lowering the cap | local-agent (record) + owner-eyes (review) |
| QA-AC-06 | Haptics off + `reduce_time_fx`/`reduce_flash`/`reduce_ui_motion` **on** (once the GAMEFEEL 🔍 rows ship): replay 3.1/3.4/3.13/3.17/3.20/3.24 | Each toggle strictly subtracts its layer and nothing else; death slow-mo falls back to a static ≥ 0.7 s hold; no effect is audio-only-or-motion-only for a deaf/blind player combination (captions/toasts still carry meaning per GAMEFEEL §4.5) | owner-eyes |

## H. Export (QA-EX-01 … QA-EX-04)

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-EX-01 | Windows Desktop preset export (`export_presets.cfg` preset.2), run the .exe from a *different* drive/folder than the repo | `user://` paths resolve per-platform; save/export/import (QA-SL-01/04) rerun green on the exported binary; no res:// write attempts; APK/exe size within `docs/artifacts/apk_size_report.md` band for the web/desktop analogue | local-agent + owner-eyes |
| QA-EX-02 | Android preset (preset.0, `build/TLS.apk`) on a low-tier device profile (`visual_quality.tres` `profile_mobile="medium"`, low tier: strobe kept — VISUAL_PASS V3 — but fog cards off) | 30 fps target holds during a boss fight with hit-stop active (60 ms pulse must not drop a frame *below* budget; if Web/Android `time_scale` pulses stutter, the spec already exempts Web: apply the same exemption on Android low tier as a follow-up decision); touch controls: haptics respect `SettingsManager.haptics_enabled()`; ad SDK stays behind `AdService` and off-build without the real key (store/HUMAN_CHECKLIST — owner item) | owner-eyes (device) |
| QA-EX-03 | Web preset (browser), play 10 min: one district restore, one boss hit, death | Hit-stop is skipped (GAMEFEEL_SPEC 3.4 "skip on Web"); `Engine.time_scale` usage limited to death sequence; audio autoplay prompt unlocks all five buses (no silent `Hum`/UI bus in Chrome); save files round-trip inside the browser FS sandbox (IndexedDB persistence prompt accepted/declined both behave) | owner-eyes |
| QA-EX-04 | Pre-release statics on the export tree: `bash tools/check.sh --static`, then `--all` gates on the same commit as the build; check `.gitignore`-only files absent from the build | Zero TODO/FIXME in shipped scripts, no debug scaffolding (`scripts/tools/_*` probes are excluded from the export presets' include filter — verify against `export_presets.cfg` include list), no BOM, `missing_keys.json` empty, gates exit 0; report pasted into release notes (RELEASE_CHECKLIST flow) | bot + owner-eyes |

---

## Coverage note (self-check)

- 7 + 4 + 5 + 5 + 5 + 4 + 6 + 4 = **40** cases. Areas: save/load, NG+,
  secrets, dailies, audio, i18n, accessibility, export — all eight named.
- Every row has an expected result that is *falsifiable without opinion* except
  the ones explicitly owned by **owner-eyes** (feel/listening/device).
- Rows intentionally encode known open findings (QA-AU-05, QA-NG-04,
  QA-I18N-03) rather than papering over them: a failing expectation with a
  named remedy is a test; a silent "works" claim is how the TRUTH WAVE bug
  happened (CLAUDE.md).
