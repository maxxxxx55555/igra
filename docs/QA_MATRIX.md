# QA_MATRIX — 40 base + 30 RC-extension manual test cases (feel & release scope)

Base date: 2026-09-16 · base owner: game-feel & QA pass · skill: `ponytail` (full)
Extended: 2026-09-20 · QA lead: RC verification pack for the 2026-09-20 audit/fix pass

**Provenance.** Sections A–H (40 cases) are transplanted verbatim from the existing
matrix on the unmerged branch `arena/01a0ab24-igra` @ `19111b2`
(AGENTS.md describes that branch as carrying "a companion `docs/QA_MATRIX.md`"; the
conflict it names is on `docs/GAMEFEEL_SPEC.md`, not this file). This file EXTENDS that
base — no existing case is rewritten, no case is duplicated (see the non-duplication
cross-refs inside each new section). Companion doc caveat: `docs/BALANCE_MATRIX.md`
exists only on that same branch @ `19111b2`; rows QA-NG-01 and QA-DA-05 read their
numbers from it.

**Hash policy.** Commit hashes cited inside repo docs (`54f1b31`, `a712dd1`, `653d0a8`,
…) were recorded by earlier sessions against the pre-squash history and do NOT resolve
in this clone — treat them as doc-recorded provenance. The only hash this clone
contains is `d736c37` (main tip, the 2026-09-20 audit/fix pass recorded in
`docs/GAME_AUDIT.md`). New sections cite live `file:line` evidence verified on
`d736c37` the same day they were written.

Scope: test *specification* only — no code, no assets, no gate scripts edited.
Companion docs: `docs/GAMEFEEL_SPEC.md` (what we also assert feel against),
`docs/BALANCE_MATRIX.md` (data snapshot the expectations are read from — see caveat).
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

# RC EXTENSION (2026-09-20) — sections I–N

## I. 2026-09-20 audit/fix-pass regression (QA-FX-01 … QA-FX-10)

**Evidence (whole section):** `docs/GAME_AUDIT.md` "TOP issues found and fixed this
session" (issues #1–#9, dated 2026-09-20, committed as `d736c37`); code refs verified
line-by-line on `d736c37` 2026-09-20. Row mapping: audit #1 → QA-FX-01; #3 → two rows
(FX-02 tracking, FX-03 damage — the "not trackable/hittable" pair); #5 → FX-04; #4 →
FX-05; #2 → FX-06; #6 → FX-07; #7 → FX-08; #8 → FX-09; #9 → FX-10. The 7 named fix
groups in the RC brief are covered by FX-01…06 + FX-08/09; FX-07/FX-10 cover the audit
session's two additional fixes from the same pass (no other matrix duplicates them).

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-FX-01 | Finish a run → on the victory screen press the NG+ button (`victory_screen.gd` calls `NewGamePlus.activate_ng_plus()`), return to menu → press Play (`start_new_game()` → `SaveSystem.reset_all()`) | NG+ level **survives** the reset: static negation grep finds zero calls into `NewGamePlus` inside the `reset_all()` body (`save_system.gd:325+`; header note line ~71 "NOT touched by reset_all()"); in the new run `NewGamePlus.get_current_ng_plus() >= 1`; a genuinely fresh profile (level 0) behaves exactly as before. Scaling of the new run is asserted separately by QA-NG-01 (not re-run here) | bot (grep) + local-agent |
| QA-FX-02 | Aggro any monster into CHASE, then enter a hiding spot mid-chase (`player_3d.gd` emits `EventBus.player_hiding_changed(true)`) | Monster breaks off into INVESTIGATE at the last-seen position (`base_monster.gd:400-401` → `_enter_investigate_at()` helper), and never resumes pathing to the exact hiding position while `_player_hiding` stays true (`base_monster.gd:120-125` subscription); after the player leaves hiding and re-exposes, normal chase/investigate rules resume | local-agent + owner-eyes (chase readability) |
| QA-FX-03 | Keep a monster in ATTACK at point-blank of the *hidden* player; let the telegraph-warn delay fully elapse to the damage tick | `_deal_damage` is gated on `_player_hiding` (`base_monster.gd:466-475` — the warn path at :473 and the direct path at :475 both route through the gate): zero damage through the warn window and while hidden; HP bar unchanged; no hit SFX/VFX; this single gate covers the telegraph-delay race per `docs/GAME_AUDIT.md` §3 | local-agent |
| QA-FX-04 | Reach Architect phase 1; observe the ranged attack repeatedly, including immediately after a teleport-in (`boss_3d.gd:82-92`) | Every `_throw_energy_ball` is preceded by a visible + audible telegraph — routed via `_telegraph.warn(_throw_energy_ball)` (`boss_3d.gd:91`), same pattern as `base_monster.gd:_perform_attack`; no same-frame projectile spawn after teleport; other boss attacks unchanged. Owner judges whether the wind-up reads as fair (open HYPOTHESIS in GAME_AUDIT "Boss P1 melee-during-teleport-windup" stays separate) | local-agent + owner-eyes |
| QA-FX-05 | With the HUD quickbar visible: pick up 2 batteries, use 1 medkit, craft anything that consumes slotted stock | The badge counter on every affected quickslot updates on the same frame as `EventBus.inventory_changed` — `hud_3d.gd:99-101` connects `_refresh_slot_badges()` (defined :894), iterating the shared `_SLOT_ITEMS` const (:7); badge numbers match the inventory screen's exact counts at every step. Pre-fix behavior (set once in `_setup_slot_placeholders()` at `_ready()`) must not reappear | local-agent + owner-eyes |
| QA-FX-06 | Static: parse `data/balance/player_stats.tres` walk/run/stealth and `enemy_roster_data.gd` speeds; assert ranges + ratio. Runtime: sprint away from the fastest roster type on flat ground, then from the slowest | `walk/run/stealth = 1.7 / 3.0 / 0.9 m/s` (tres values, verified `d736c37`); original 170:300:90 ratio preserved (÷100, audit §2); roster stays 1.2–6.0 m/s; player sprint 3.0 ≤ fastest monster 6.0 — the 15× outlier is gone. Owner-eyes: escape is possible vs slow types, not vs fast ones — the intended tension of the fix | bot (parse) + owner-eyes |
| QA-FX-07 | Reach a later district (e.g. `hospital`), save; then (a) die → death screen New Game (`death_screen.gd:53` calls `start_new_game()` directly), and (b) menu New Game after a completed run | On new-run boot `DistrictManager.current_district` is reset to the default `"suburbs"` — `reset_all()` resets it (audit §6; death-screen path verified covered by the same fix per audit's own "Findings documented" note); the world loads suburbs, not the stale district; save/load mid-run still restores the pointer correctly (`save_system.gd:304-307`) | local-agent |
| QA-FX-08 | Bot byte-scan the shipped surface: `grep -rIlP '^\xEF\xBB\xBF' scenes data project.godot`; then JSON-parse every file named in audit §7 (6 × `data/dialogs/dialog_*.json`, `data/economy/economy_config.json`, `data/economy/shop_catalog.json`, `data/loot/loot_table.json`, `data/ng_plus_config.json`) | Zero BOM hits across `scenes/`, `data/`, `project.godot` (CLAUDE.md:17 "Zero shipped: … BOM" rule; 13 files were stripped in `d736c37`); all named JSON files re-parse cleanly. Scoped exception recorded, not widened: `scripts/tools/gen_district_music.py` still carries a BOM (dev tool, outside the shipped runtime surface) — flag it to the code owner, never widen this matrix's docs-only scope | bot |
| QA-FX-09 | Bot: grep shipped runtime GDScript (`scripts/`, `*.gd` only) for live `print(` call sites (comments excluded — `save_system.gd:150` is a comment, do not match); re-audit the three files named in audit §8 + `scripts/multiplayer/lan_discovery.gd:37` | Zero live raw `print()` calls in `save_system.gd`, `net/lan_network.gd`, `monetization/stub_crazy_games.gd` — diagnostics use `push_warning()` per the established 9-file convention (audit §8); `lan_discovery.gd:37`'s `push_warning()` is restored to ACTIVE (not commented). "No console debug spam" during play is separately owned by QA-AU/HANDOFF soak line — not duplicated here | bot |
| QA-FX-10 | Bot: read the `coin_wallet.gd:31-32` comment and cross-check against `data/shop/*.tres` price ranges | Comment's stated rationale now matches the data (real catalog 1500–4000, audit §9 — the stale "30–100" claim is gone); the `MAX_COINS` 9 999 999 anti-tamper cap itself is intentionally untouched (audit: "the cap itself was already fine either way") — its clamp behavior remains owned by QA-SL-05, not re-specified here | bot |

## J. Signed saves + tamper paths (QA-SEC-01 … QA-SEC-04)

**Evidence:** `docs/SECURITY_THREAT_MODEL.md` (system verified against a real run —
`[save-integrity] DONE fails=0` — and honest about out-of-scope vectors);
`scripts/core/save_system.gd:21-24` (HMAC-SHA256), `:102-113` (progress signature,
`_verify_progress`), `:123`,`:177` (envelope sign/verify), `_migrate`; gate
"целостность сейва" wired at `tools/check.sh:214` →
`res://scenes/tools/save_integrity_check_scene.tscn`; `RELEASE_CHECKLIST.md` §8
(export/import HMAC + `.bak`-before-import).
**Non-duplication:** QA-SL-04 owns the export/import happy-path round-trip; QA-SL-05
owns forged *progress* (`won`/coins). These four rows cover the *envelope/tamper*
surface the threat model's table names — no overlap.

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-SEC-01 | Copy `user://tls_savegame.save`; flip one byte inside `data_json` (leave the envelope `hmac` untouched); place it back as the live save; boot and load | Envelope HMAC mismatch → load rejected (`save_system.gd:177` `signed_ok` check); the game recovers from the 3-generation `.bak` rotation (`_rotate_backups`) instead of loading a corrupt or empty profile; no crash; diagnostic surfaced via warning, not raw print (QA-FX-09). Gate-level shortcut: `save_integrity_check_scene.tscn` already exercises corrupt-file rejection + 50-mutant byte-fuzz (threat-model "Test probe") — re-running it green satisfies this row's bot half | local-agent |
| QA-SEC-02 | Hand-edit an exported `tls_save_export.json` (change one value, leave its signature stale); then Settings → Game tab → **Import Save** | Import is refused — the same HMAC check runs on `import_save_from_file` (threat-model row "Exported save file tampered before re-import", residual risk none); the live save is untouched — and had a valid import been accepted, a `.bak` of the previous save would exist first (`RELEASE_CHECKLIST.md` §8) | local-agent |
| QA-SEC-03 | Fabricate a legacy pre-HMAC save in the old envelope shape (`_read_envelope` still accepts "a pre-HMAC save signed with the old" format, `save_system.gd` ~:105); load it on the current build | The `_migrate()` path loads it and RE-SIGNS on the next save — it must NOT be rejected (documented compat path, residual risk "none — intentional"); after the next save the file carries the new HMAC envelope and loads offline by the new signature | local-agent |
| QA-SEC-04 | On a dev build, push an out-of-range wallet/stat value into the live runtime (debugger) between autosaves; also confirm the disk-side property | `scripts/systems/integrity_guard.gd` re-validates wallet/stat ranges on its next tick — detection/correction happens (the threat model is explicit it cannot *prevent* the edit; expectations must say so); the disk save remains HMAC-rejected if tampered (QA-SEC-01). OUT OF SCOPE by design and never to be added to this row: PCK-dump of `_HMAC_KEY` + resigned-save forgery — threat-model "NOT protectable client-side" section governs | local-agent + owner-eyes |

## K. Accessibility toggles × juice sites (QA-JU-01 … QA-JU-05)

**Evidence:** `docs/GAMEFEEL_SPEC.md` (main @ `d736c37`; its P4 table is a *spec* —
rows below assert live-vs-spec truth; the more detailed branch version @ `19111b2` is
not followed here per the AGENTS.md conflict note — "a real content decision, not a
mechanical merge"); live-gate truth table grep-verified on `d736c37`:
`scripts/ui/settings_screen.gd:262-267` (Reduce Screen Shake / Reduce Flash / Reduce
Time Effects rows), `scripts/effects/screen_shake.gd:21`, `scripts/systems/
wow_director.gd:52,70,75,87-90`, `scripts/player/death_sequence.gd:21-24`,
`scripts/player/player.gd:105`, `scripts/systems/audio_manager.gd:67`.
**Non-duplication:** QA-AC-02 owns camera-zero measurement for shake; QA-AC-05 owns
measured flash rates; QA-AC-06 owns the combined-toggles replay once 🔍 rows ship.
These rows pin the *gate wiring* per site — a different artifact.

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-JU-01 | Bot choke-point sweep: `grep -rn "Engine.time_scale" scripts/ --include=*.gd` then drop `scripts/tools/**` hits, and the same sweep for the tokens `add_trauma` and `flash_a`; for every hit, verify a `reduce_*` guard exists inside the same function | Truth table must match exactly — time_scale writers: `wow_director.gd` :70 (GUARDED by `reduce_time_fx`), :73/:75 set/restore under that guard, :87-90 boss slow-mo (GUARDED); `death_sequence.gd:21` (UNGUARDED — the recorded fail is QA-JU-04); trauma adds: `screen_shake.gd:21` (GUARDED by `reduce_screen_shake`); full-screen flash: `wow_director.gd:52` (GUARDED by `reduce_flash`). ANY new effect site landing without its toggle check = FAIL (GAMEFEEL_SPEC P4 rule: "No new effect ships without checking its toggle first") | bot |
| QA-JU-02 | In-game with **Reduce Flash** ON (`settings_screen.gd:266`): trigger a district-FULL cascade wow and a boss-intro flash; repeat with the toggle OFF | ON → zero full-screen flash on both (`_setting("reduce_flash", false)` gate at `wow_director.gd:52`: `flash_a > 0` paths skip); the non-flash wow layers (slow-mo, shake) still play; OFF → the flash returns. Label text: "Reduce Flash" | local-agent (frame probe) + owner-eyes |
| QA-JU-03 | **Reduce Time Effects** ON: take a heavy/crit hit-stop and reach a boss phase slow-mo; then OFF and repeat | ON → `Engine.time_scale` never dips: the hit-stop early-returns at `wow_director.gd:70` and the boss slow-mo branch at :87-90 is skipped and restores 1.0; OFF → hit-stop runs capped at ≤ 80 ms wall-clock via ignore_time_scale timer (:65-66 comment); two effects never stack multiplicatively (spec rule — boss+hit combo resolves at the shared choke points) | local-agent |
| QA-JU-04 | EXPECTED-FAIL row (known open gap with a named remedy — the matrix records it RED by design): **Reduce Time Effects** ON, then die | Intended end-state: the death beat does NOT enter `time_scale = 0.3`. Live truth on `d736c37`: `death_sequence.gd:21-24` sets `Engine.time_scale = 0.3` + `create_timer(1.0)` (≈ 3.3 s real) with NO `reduce_time_fx` check — matches GAMEFEEL_SPEC's own "not yet gated" admission and base row QA-AU-05's open finding. Remedy when scheduled: gate on `reduce_time_fx` (spec top-section decision). Do NOT close this row by editing expectations; do NOT treat as a new regression | local-agent |
| QA-JU-05 | Photosensitivity contract for the P4 blackout/disrupted flash — the spec's only "hard requirement, never skip the gate" site (GAMEFEEL_SPEC event table + rules): bot greps shipped code for any full-screen flash consuming `district_blackout` / `light_disrupted` | Live truth: NO such flash is shipped — consumers are `streetlight.gd` (lights-off), `audio_manager.gd:67` (glitch one-shot audio), `player.gd:105` (flashlight disable) — so the row PASSES as "nothing to gate". If a blackout flash ever ships without the `reduce_flash` check = instant FAIL, not waivable under any settings combination (spec rules §3). Measured flash-rate once one exists stays with QA-AC-05 | bot |

## L. Graphics presets × mobile tiers (QA-GP-01 … QA-GP-04)

**Evidence:** `scripts/systems/settings_manager.gd:262-266` (`GRAPHICS_TIERS` — 4
tiers × 5 knobs), `:429-438` (`set_graphics_tier` clamps, applies all five setters,
emits `settings_changed`); `docs/VISUAL_PASS.md` §7 (`visual_quality.tres`:
`profile_desktop="high"`, `profile_mobile="medium"`, `graphics_tier_map={low:0,
medium:1, high:2}`, Ultra tier 3 reuses the `high` dicts); `docs/GDD.md:377` (§14 canon
Low/Medium/High/Ultra); persist gate `settings_persist_probe_scene.tscn`
(`tools/check.sh:219`); perf reference `docs/HANDOFF.md` owner-verify D1/D11.
**Non-duplication:** QA-EX-02 owns Android low-tier device perf + strobe; QA-SL-07 owns
tier persistence across save/load. These rows own the preset *matrix* application +
profile selection.

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-GP-01 | Bot: parse `GRAPHICS_TIERS` (`settings_manager.gd:262-266`) — assert exactly 4 entries, each dict with keys {shadows, textures, effects, fps, resolution}, values in 0..2; tier3 shadows/textures/effects equal tier2's (Ultra reuses High's visual knobs; fps/resolution may differ) | Table shape matches the shipped constants; `set_graphics_tier` clamps idx to `0..GRAPHICS_TIERS.size()-1` (:430) so an out-of-range saved value can never crash the preset | bot |
| QA-GP-02 | Swing each tier 0→3 in Settings → Graphics on a desktop boot; capture `settings_changed` payloads and re-read `get_setting("graphics_tier")` | Each selection calls exactly once each of `set_shadow_quality/set_texture_quality/set_effects_quality/set_fps_cap/set_resolution` (:433-437) and emits `settings_changed("graphics_tier", idx)` (:438); the `visual_quality.tres` meta lookup succeeds for every tier via `graphics_tier_map` {low:0, medium:1, high:2} with tier 3 → `high` dict (VISUAL_PASS §7); no missing-meta error in the log | local-agent |
| QA-GP-03 | Set tier High on desktop, reboot; set tier Low, reboot twice; check the tier + an accessibility toggle both times | Tier and a11y state survive restart — the persist gate `settings_persist_probe_scene.tscn` ("настройки: тир графики и accessibility переживают рестарт", `tools/check.sh:219`) passes; UI tier labels match GDD §14 canon (Low/Medium/High/Ultra, `GDD.md:377`) with no phantom fifth tier | local-agent |
| QA-GP-04 | Boot on each available mobile device class (low/mid/high phone tier): check the boot profile, walk one DARK district, fight the boss once; record draw calls via `scenes/tools/perf_check_scene.tscn --windowed` | Mobile boot resolves `profile_mobile="medium"` (`OS.has_feature("mobile")` selection per VISUAL_PASS §8 W1); on low tier, strobe is kept and fog cards are off (VISUAL_PASS V3 fallback contract); recorded numbers compared against the doc-recorded references (HANDOFF D11 < 350 met / D1 < 200 aspirational); device-tier pacing judgment is owner-eyes — a low-tier miss is a "P1 design call" per GAP_TO_IDEAL, not a code-edit-from-matrix action | owner-eyes + local-agent |

## M. New i18n keys (QA-IK-01 … QA-IK-03)

**Evidence:** `docs/KNOWN_ISSUES.md` entry "The 155 formerly-English content strings
are now translated in all 12 non-English locales (2026-09-13)" — 52 `SECRET_*`, 60
`DAILY_*_FLAVOR`, 28 `CAPTION_*`, 14 `NGP_*`, `TUT_JOURNAL`; intentional
English-identical strings limited to the listed cognates + `NG_PLUS_LABEL`;
`docs/NATIVE_QA_FINDINGS.md` (native read of 885 non-LORE keys, 468 fixes);
`docs/GAME_AUDIT.md` "Findings documented, NOT fixed" (`lan_menu.gd` unlocalized —
zoned to `cl/a11y-i18n` per `docs/AGENT_ZONES.md`); `data/i18n/*.json` (13 files;
en master = 1268 keys on `d736c37`).
**Non-duplication:** QA-I18N-01…04 own whole-repo parity/live-switch/CJK-RTL/source
contract gates. These rows own the 155-key wave specifically + the one documented
unlocalized screen.

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-IK-01 | Bot: scoped parity + placeholder sweep over key families `SECRET_*`, `DAILY_*_FLAVOR`, `CAPTION_*`, `NGP_*`, `TUT_JOURNAL` across all 13 `data/i18n/*.json`: identical key set per locale, printf tokens aligned, `missing_keys.json` == `{}`; English-identical values outside the documented cognates + `NG_PLUS_LABEL` list | All five families parity-clean in 13/13 locales (baseline 2026-09-13: 1265×13, MISSING 0); grow-only additions are acceptable ONLY if all 13 locales carry them with translations — any asymmetric or English-fallback add = FAIL | bot |
| QA-IK-02 | Owner-eyes native render in ≥ 2 non-EN locales (recommend one CJK + ar, the fragile pair from QA-I18N-03): open a secrets-journal entry, the daily-challenge card, the NG+ modifier picker (`NGP_*`), and a photo caption line | New-wave strings render in-locale in the established Keeper voice (transcreated + native-QA'd per KNOWN_ISSUES/NATIVE_QA_FINDINGS — not machine-literal); no raw keys, no tofu, no clipping at 100 % text scale | owner-eyes |
| QA-IK-03 | EXPECTED-FAIL row (documented open finding, named remedy, zone-restricted): open the LAN menu (`scripts/net/lan_menu.gd`, wired live in `scenes/main_3d.tscn`) in any non-EN locale; bot half: grep the file for un-tr()'d string literals | Intended end-state: LAN/Host/Join and placeholder texts (lines ~28,33,37,41,45 per GAME_AUDIT) resolve via LocalizationManager in all 13 locales. Live truth: entirely hardcoded English — FAILS until a `cl/a11y-i18n`-zone session lands the keys (adding i18n keys is NOT this matrix's zone per `docs/AGENT_ZONES.md`). RC consequence: the LAN menu must not be presented as "fully localized" in store/demo copy until this row flips | bot + local-agent |

## N. Store listings render (QA-ST-01 … QA-ST-04)

**Evidence:** `store/listing.md` ("FINAL STORE SYNC 2026-09-13", 13 locale sections,
EN 70/80 + RU 66/80 short-description char counts); `docs/CERT_STORESYNC.md`
(per-claim cross-table); `docs/artifacts/store-sync/verify_listing.py` +
`verify_all.out`; `docs/store/play_store.md` (EN/RU source, Data-safety TODO);
`store/privacy-policy-template.md`; `docs/OWNER_RELEASE_PACKET.md` §(d) paste order +
§(e) screenshot delivery table; `store/screenshot-plan-detailed.md`;
`store/changelog.md` v1.0 blocks; `tools/gen_store_listing_locales.py`.

| ID | Steps | Expected result | Executor |
|---|---|---|---|
| QA-ST-01 | Bot: run `python3 docs/artifacts/store-sync/verify_listing.py`; parse `store/listing.md` — assert 13 locale-labeled sections, each with Title + Short + Full description; re-measure every short description ≤ 80 chars (headers claim EN 70/80, RU 66/80) | Verifier exits clean (prior recorded result: `verify_all.out` clean); all 13 sections self-contained per OWNER_RELEASE_PACKET §(d); no unresolved fill-in-bracket placeholders in any pasted-listing field (the privacy-policy URL field is expected to reference the published URL from `docs/RELEASE_CHECKLIST.md` STEP 4 — currently open by design, see that step's NEEDS-OWNER-CONFIRMATION) | bot |
| QA-ST-02 | In Play Console → Store presence → Main store listing → paste per OWNER_RELEASE_PACKET §(d) order (en default first, then the 12 via **Store listing → Manage translations**); open each translations' preview on desktop and on one narrow Android viewport | Every locale renders: EN/RU without truncation; the 11 transcreated sections with no mojibake or stripped punctuation; ar renders RTL end-to-end; the app name string `THE LAST STREETLIGHT` matches exactly everywhere (permanent identifier check — package `com.maxsimkasky.laststreetlight`, RELEASE_CHECKLIST §5 warning) | owner-eyes |
| QA-ST-03 | Render-check the visual listing surface on device + desktop: `store/icon-512.png` (shrink-test to 48dp), `store/feature-graphic.png` at phone width, and the gallery with only the ✅-delivered shots uploaded | Icon stays sharp at 48 dp; feature graphic legible at phone width; gallery contains only delivered art (shots 1,2,5,7,8 + the three touch-HUD shots per OWNER_RELEASE_PACKET §(e)) — the ⛔ in-game captures 3/4/6 stay OUT until captured post-playtest (their absence is expected state pre-capture, an owner-scheduling item, not a store defect); adaptive icon layer renders per `store/icon-adaptive/` spec | owner-eyes |
| QA-ST-04 | Bot: store-claim consistency vs shipped masters — `data/i18n/en.json` `menu_title`/`ru.json` vs `store/listing.md` Title/Tagline lines; `store/changelog.md` v1.0 block present and free of removed-feature claims; re-hash vs `docs/artifacts/store-sync/listing_master_prefix.sha256` | Titles/taglines still byte-consistent with the masters (certification per CERT_STORESYNC); the v1.0 changelog block exists for EN + RU with the `<en-US>`/`<ru-RU>` paste markers assumed by RELEASE_CHECKLIST.md §5.4; any content/claim drift after 2026-09-13 (e.g. claiming LAN co-op "fully localized" while QA-IK-03 is RED) = FAIL and routes back to a store-sync pass | bot |

---

## Coverage note (self-check)

- Base A–H: 7+4+5+5+5+4+6+4 = **40** cases (unchanged from `19111b2`).
- RC extension I–N: 10+4+5+4+3+4 = **30** cases. Total **70**.
- The 9 named fix groups of the 2026-09-20 pass are covered (FX-01…06, FX-08, FX-09),
  plus the audit's two further same-pass fixes (FX-07 district pointer, FX-10 stale
  economy comment) so the pass leaves zero uncovered fix.
- Intentionally RED rows with named remedies (failing expectation > silent "works"
  claim — base matrix doctrine, CLAUDE.md TRUTH WAVE): QA-AU-05 (base), QA-NG-04
  (base), QA-I18N-03 (base), QA-JU-04, QA-IK-03. Do not flip these without the remedy
  landing; do not re-file them as new bugs.
- Every new row carries its evidence reference inline (doc + section and/or
  `file:line` verified on `d736c37`); bot-executable steps use only tools that exist
  in-tree at `d736c37`.
- Executor rule carried over from the base: a case is ✅ only when *every* listed
  executor has passed it. Rows requiring owner-eyes stay open until the owner device
  session (`docs/RELEASE_CHECKLIST.md` STEP 6) records them.
