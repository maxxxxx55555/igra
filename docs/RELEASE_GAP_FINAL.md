# RELEASE_GAP_FINAL — single work registry (P0, 2026-11-11)

Owner directive "TLS -> RELEASE" v2.0 §9 P0. **This is the only queue.** Every OPEN row of
`docs/KNOWN_ISSUES.md`, every `AGENTS.md` blocker, every `docs/store/HUMAN_CHECKLIST.md` item,
every `docs/PROJECT_STATE.md` owner item, every §9.1 row T1-T14, and every defect surfaced by the
P0 battery appears below with a disposition. Nothing is silently dropped; rows closed by later
sessions are marked `closed-with-evidence` with the run that closed them, not deleted.

Machine-readable columns:

`id | source(file:line) | disposition | zone | gate-check | estimate | status`

Dispositions: `agent` | `owner` | `decision` | `post-release` | `closed-with-evidence`.
Statuses: `open` | `verify-first` | `owner-packet` | `deferred` | `resolved-by-code` |
`closed-with-evidence`. Estimates are relative (S/M/L), not invented hours.

Base verified at P0 (2026-11-11): `965ec095c945f976edab4a58ec6c66243a8d89e0` (dated record,
re-read the live SHA before acting). P0 battery truth:
`.qa_logs/proofs/p0_static_20261111.out` — **6 failed / 97 passed, EXIT=6** on a dirty tree.
Environment: `docs/ENVIRONMENT.md`. Budget: `docs/BUDGET_LEDGER.md`.

---

## 1. §9.1 backlog rows (T1-T14) — verify-first applied

| id | source | disposition | zone | gate-check | estimate | status |
|---|---|---|---|---|---|---|
| T1 | `docs/VISUAL_PASS.md:159-226` (§8), `AGENTS.md:25-42` | agent | visual + world + lead | static + `drawcall_estimate.py` + headless gate scene + before/after frames (af3) | L | **verify-first: partially done** — W2-W10 have real live consumers (see §2 below); the conflict in `AGENTS.md` is stale, not an open wiring job. Remaining: strict application order check, two-WorldEnvironment unification, per-effect a11y gating evidence. |
| T2 | `BEAUTY_RC16.md` X5; `scripts/systems/settings_manager.gd:441-450,514,527,535,548` | agent | ui (menus) | X5 before/after frames + `settings_persist` gate | M | **verify-first** — `HIGH_CONTRAST_DELAY` timers at `:514`, `:527` still re-apply after tier change; needs frame evidence before declaring open/closed. |
| T3 | 13 key-hint strings (`tutorial_move`, `TUT_FIND_FLASHLIGHT`, `HINT_INVENTORY`, `WORKBENCH_CLOSE`, `INV_HINTS`); pattern `scripts/ui/hud_3d.gd` | agent | ui | `hardcoded_text_gate.py`, `i18n_truth_gate.py`, `af5_check.py`, placeholder parity | M | **open** — `hud_3d.gd` uses `tf()` at `:1241,:1244` but no `InputRemap.key_of()`/`key_text()` in the hint call-sites; en+ru needed. |
| T4 | GDD primitive budget 50k/district; `docs/SIZE_BUDGET.md` | agent | world + qa | `drawcall_estimate.py` + windowed perf gate | M | **open** — whole-frame 135k/199k numbers are informational; GDD decision on what counts must be written first (§9.1 T4). |
| T5 | `docs/RUN_STATE.md` ST-1; district-build hitch 0.13-0.15 s | agent | world | windowed perf measurement before/after; IRON RULE if behaviour changes | M | **open** — measurement first, then batching. |
| T6 | `docs/artifacts/councils/story_audit_20261031.txt:33-40` (S-14, S-17, S-22, S-27, S-29, S-31, S-32) | agent | content | `audit_content_depth.py`, integrity manifest, content mirrors, `af5_check.py` | M | **open** — 7 rows; each closed with a wording fix or an honest won't-fix note. |
| T7 | `docs/KNOWN_ISSUES.md:11,19`; `scripts/tools/_qa_autoplay_runner.gd` | agent | qa + ui | new headless two-finger `InputEventScreenTouch` probe + mutation that bites | M | **open** — real potential phone bug; current probe presses buttons by signal (not a proof). |
| T8 | `scripts/ui/ui_scale.gd:5,15` (`MIN_TOUCH = 48.0`) | agent | ui | static gate + owner device confirmation at P4 | S | **open** — no `DisplayServer.screen_get_dpi()`; final value is owner/device. |
| T9 | `scripts/ui/toast_manager.gd:91,125`, `scripts/ui/ui_manager.gd:58,88-95`, `docs/KNOWN_ISSUES.md:9,13` | agent | ui + qa | `hud_checks` / `sec_checks` (they read `UIManager._toast`) | M | **verify-first** — two toast implementations exist (`toast_manager.gd` signal-driven, `ui_manager.gd` own `_toast`); single-queue claim must be proven, not assumed. Radar streets: `docs/KNOWN_ISSUES.md:13` says done in S39e/S39i. |
| T10 | `docs/KNOWN_ISSUES.md` T10 manifest: `skyline.gd`, `ui_scale.gd` `narrow_layout`, facade shader comments R14/R15 | agent | world + visual | `quarantine_audit.py --check` + zero-consumer grep | S | **open, deletion only on proven death** — `ui_scale.gd` is live (T8), so `narrow_layout` must be checked separately. |
| T11 | `docs/KNOWN_ISSUES.md:5` (S39k) + local Gradle-stop helper | agent | lead | `grep JAVA_HOME` + one export dry-run | S | **closed-with-evidence candidate** — the local (untracked) `.qa_logs/s39_export_vc17.sh` sets `$env:JAVA_HOME` to the bundled JBR on line 35; `docs/KNOWN_ISSUES.md:5` says S39k closed it. Confirm at P3 export. |
| T12 | `docs/RUN_STATE.md` S30 round 4 (`G-TIMING`, `G-MUT`, `G-COV`) | agent | qa | `s26_mutations.py`, `coverage_matrix`, `check.sh --all` | M | **open (tool-drift, separate PR)** — stale mutation rows (SECV2B/SECV9L), subset baselines, 9 coverage log-matching misses without waiver. Fix the tool, not the gate (§1.5). |
| T13 | `default_bus_layout.tres`; `docs/VISUAL_PASS.md:184-190` W4 | agent | audio | `audio_truth_gate` windowed x1, `hum_scan`, ducking matrix | M | **open** — `grep -n Hum default_bus_layout.tres` returns nothing; `docs/TZ_DECISIONS.md:45` says the Hum bus was removed with the hum. W4 hum-sync cannot be wired until the owner decides (music=A, no hum rule, `PRODUCTION_BIBLE` §3). |
| T14 | `docs/PROJECT_STATE.md`, `RELEASE_CHECKLIST.md`, `docs/STORE_KIT.md`, `docs/CERT_STORE.md`, `docs/CERT_STORESYNC.md` | agent | lead | `closure_guard.py` (6 rules), `af5_check.py`, `title_check.py` | S | **open** — `PROJECT_STATE.md` yaml `main_sha: 04d54aae` is stale vs `965ec095`; prose says "frozen" but the 2026-11-11 directive unfreezes. Fixed in this P0 PR with a dated note. |

## 2. W1-W11 wiring conflict — RESOLVED BY CODE (§1.2 of the directive)

`PROJECT_STATE.md` claimed "all agent work closed"; `AGENTS.md:26-28` claimed "only W1 is
connected, W2-W10 have zero consumers". **Code wins (§1 truth rule 1).** Every W asset has a
tracked live consumer on `main`:

| W | asset | live consumer (file:line) | verdict |
|---|---|---|---|
| W1 | `assets/config/visual_quality.tres` | `scripts/systems/settings_manager.gd:490`, `scripts/world/streetlight_3d.gd:46-47`, `scripts/world/contact_shadows.gd:34` | connected |
| W2 | `assets/env/camera_attributes_night.tres` | `scripts/world_env_setup.gd:46` const, applied at `:108` (`_we.camera_attributes = load(...)`) | connected |
| W3 | `assets/shaders/height_fog_card.gdshader` | `scripts/world/district_dressing.gd:31` (`preload`) | connected |
| W4 | `assets/env/mat_lamp_flicker.tres` | `scripts/world/lamp_head.gd:6`, `scripts/world/street_props.gd:217` | connected (hum-sync half is T13) |
| W5 | `mat_wet_asphalt.tres`, `mat_foliage_sway.tres` | `scripts/world/street_wetness.gd:6`, `scripts/world/street_props.gd:316` | connected |
| W6 | `contact_shadow.gdshader` / `contact_shadows` key | `scripts/world/contact_shadows.gd:34`, `visual_quality.tres:9-12`, `scripts/tools/rc16/s29_look_checks.gd:157` | connected |
| W7 | `vfx_rain.tscn`, `vfx_dust.tscn`, `vfx_strobe.tscn` | `scripts/effects/weather_particles.gd:6-7`, `scripts/player/player_3d.gd:1503` | connected |
| W8 | menu parallax | `scripts/ui/menu_parallax.gd`, `scripts/ui/main_menu.gd`, `scripts/tools/rc16/s29_look_checks.gd:204-205` | connected |
| W9 | theme parity | `scripts/theme_setup.gd:18` (`ThemeProvider.build_theme()`), `project.godot:105` `theme/custom`, `scripts/ui/theme_provider.gd:18-24,88,96` (type scale, focus, disabled) | connected |
| W10 | `energy_mult`, moon bias | `scripts/world/streetlight_3d.gd:27,50,68-69`, `scripts/world_env_setup.gd:43` | connected. `DistrictThemes.apply_to_environment()` was **since-deleted** (`scripts/world/district_themes.gd:19`), so that W10 sub-item is moot. |

Ground rendering: **script-driven**. `scripts/world/district_grading.gd` IS live
(`scripts/world/world_bootstrap.gd:46` loads it), but only tints the ground — its own header
comment says the Environment branch was dead because `world_environment_path` was never set;
the single writer of stage fog/ambient is `scripts/world_env_setup.gd:161,252`. The 11 district
`.tscn` files do not own the environment. `scripts/world/district_scene_factory.gd` contains
**no** `WorldEnvironment` reference on current `main`, so the "second WorldEnvironment" conflict
in `VISUAL_PASS.md:173-174` is already resolved (one global WE, `world_env_setup.gd:61-64`).

**Truth correction:** `AGENTS.md:25-42` is a stale status claim, not an open wiring job. It is
reclassified `resolved-by-code` here and gets a dated correction note in `PROJECT_STATE.md`.
The real remaining visual work is the strict W1->W2->...->W7 application order, a11y gating
evidence per effect, and the two `windowed`-only gates — all T1/P2 rows, not a "W2-W10 unconnected"
emergency.

## 3. P0 battery defects (new rows, from real runs)

| id | source | disposition | zone | gate-check | estimate | status |
|---|---|---|---|---|---|---|
| G-MSAA | `.qa_logs/gate_qa_headless_suite_scene.log:44`; `scripts/world_env_setup.gd:197` via `settings_manager.gd:526` -> `quality_manager.gd:72` | agent | visual + lead | GOLD MASTER suite, zero engine-error lines | S | **open, GAME-AFFECTING** — `get_viewport().msaa_3d` on a null instance during tier change in the headless suite. Real runtime script error; fix with a null guard + regression gate, not a gate tune. |
| G-AF5-FOREIGN | `docs/AUTHENTICATION.md (line 23)` (foreign untracked) | decision | lead (external zone) | `python tools/af5_check.py` | S | **verify-first / not my zone** — C3 claim-word mismatch in a doc from the parallel session. Owner/lane decision: fix the citation or drop the doc. Must not be touched by this session (§1.6, §12). |
| G-AUDIT | `tools/check.sh:182-185` (`audit_content_depth`) | agent | qa | isolated re-run rc=0 (0 ERROR / 1 WARN / 31 INFO) | S | **verify-first** — fails only inside `--all`; clean-tree re-run required. |
| G-DEMO-VIS | `tools/check.sh:211-214` | agent | qa | `visual_truth_gate.py --demo` rc=0 ("demo OK (16 patterns)") | S | **verify-first** — passes in isolation. |
| G-DEMO-AF2 | `tools/check.sh` af2 demo call | agent | qa | `af2_both_ways.py --demo` rc=0 | S | **verify-first** — passes in isolation. |
| G-DEMO-LINT | `tools/check.sh:365-368` | agent | qa | `lint_changed.py --demo` rc=0 ("6 fixtures, 0 wrong") | S | **verify-first** — traceback at `:191` only inside the battery (temp-dir race suspected). |
| G-WINDOWED | `tools/check.sh` perf budget + audio truth lines | agent | lead | `tools/qa_sim/guarded_windowed` x1 each | S | **open** — two checks self-skip by design; not green until P2/P3 windowed runs. |
| G-CLEAN-TREE | `docs/ENVIRONMENT.md` foreign-dirty section | agent | lead | `git status --porcelain` on a clean frozen clone | S | **open** — P3 requires a clean clone; the current 25 uncommitted paths are foreign. |

## 4. `docs/KNOWN_ISSUES.md` OPEN / not-CLOSED blocks (all 26 rows)

Rows are grouped by their dated header. Each keeps its line number so nothing disappears.

| id | source | disposition | zone | gate-check | estimate | status |
|---|---|---|---|---|---|---|
| KI-7 | `docs/KNOWN_ISSUES.md:7` (S39j: JDK 17 script + procedural monster meshes) | agent / post-release | lead + world | `grep JAVA_HOME` + `docs/ANDROID_BUILD.md`; mesh work needs meshes | S / L | **split** — JDK half `closed-with-evidence` candidate (T11, `:5` says S39k closed it); monster meshes `post-release` (B9, §9 P5, owner decision Q7). |
| KI-9 | `:9` (S39i: second-finger phone check, monster/boss models, phone UI scale, Gemini music) | agent / owner / post-release | qa+ui+audio | T7 probe, T8, P4 device, owner sign-in | M | **open** — split into T7, T8, P4-owner, post-release B9 / Gemini. |
| KI-11 | `:11` (S39h: two-finger HUD Button, design critique leftovers) | agent | qa+ui | T7 headless probe | M | **open** — the two-finger part is T7; HUD warmth/LOG/tabs/shop-card/menu-button are marked closed in S39i (`:9`). |
| KI-13 | `:13` (S39d: Gemini music, art-director 7 items, 3D hum, monster FSM randomness, city atlas, qoder patch, interaction sounds) | decision / post-release / agent | audio+visual+world | owner Q7/Q9, audio truth gate, content audit | L | **open** — Gemini sign-in is owner (P4); hum is T13; art items are Q9/post-release; city atlas/radar done per `:13`; interaction sounds closed S39i (`:9`). |
| KI-15 | `:15` (S39c art director: 7 store-visible art items) | post-release | visual | none (no gate sees them) | L | **deferred** — owner decision Q9, B9 post-release. |
| KI-17 | `:17` (S39b expert swarm OPEN rows) | agent / owner | mixed | per-item gate or owner script | L | **open** — phone run (P4), death return, difficulty step, first purchase, door/cabinet/generator sound, three button looks, boss/victory art; each maps to T-rows or owner. |
| KI-21 | `:21` (S38 visual redo / Opus review) | post-release | visual | none | L | **deferred** — G2/G3 empty panels and shop chrome = B9 post-release. |
| KI-28/29 | `:28-29` (G2/G3 FAIL; S-14/17/22/27/29/31/32; S-15/S-16) | agent / decision / post-release | content+visual | `audit_content_depth.py`, af5, owner Q10 | M | **open** — story rows are T6; S-15/S-16 are owner Q10; G2/G3 post-release. |
| KI-32 | `:32` (S38 best variants integration) | post-release | visual | none | M | **deferred** — art/mesh scope, B9. |
| KI-42 | `:42` (S38 visual recovery brief, S38R-DEFECTS) | post-release | world | none | L | **deferred** — facade families and set pieces need meshes. |
| KI-53 | `:53` (v8 FINAL: INCOMPLETE, G2/G3 FAIL, G4/G5/G6 BLOCKED, V03/V13/V14 BLOCKED) | owner / post-release | mixed | P4 device + owner eyes | L | **open** — G4/G5/G6 are owner eyes/ears (§11 Q7/Q9, P4); V-rows post-release. |
| KI-63 | `:63` (v7 visual overhaul blockers) | post-release | visual | none | L | **deferred** — B9. |
| KI-78 | `:78` (art pass 2 / owner canon / code 9) | post-release | visual | none | L | **deferred**. |
| KI-87/91 | `:87,:91` (hit-flash check inside `check.sh --all`; S36 runtime acceptance) | agent | qa | `check.sh --all` (P0 run: 6 fail / 97 pass) | S | **closed-with-evidence per `:87`** (s37_c3_d5afe71d 96/96); current P0 run has different failures (§3). Session-36 acceptance remains a dated historical record. |
| KI-117 | `:117` (S28 masterpiece pass, closed by S29) | closed-with-evidence | qa | `docs/artifacts/rc16/proofs/s28_*` | - | **closed** — kept as a dated witness, not deleted. |
| KI-126 | `:126` (S27 v9.1.0-store pass) | post-release | store | `gen_store_listing_locales.py --check` | S | **verify-first** — listing check is GREEN (P0), 2 locales; art rows deferred. |
| KI-138 | `:138` (S26 v9.0.0-universe pass) | post-release | content | `audit_content_depth.py` | M | **deferred**. |
| KI-152 | `:152` (S25 Gemini integration) | decision | audio | owner sign-in | M | **open** — owner Q9 / P4. |
| KI-158 | `:158` (S24 v8.1.0-premium pass) | post-release | visual | none | M | **deferred**. |
| KI-167 | `:167` (S19 release-validation open findings 168-180) | decision / owner | mixed | owner rating (§11 Q10) | M | **open** — 170/171/173/177 are the owner's per `:167`; S20/S21 closures kept as dated records. |
| KI-173 | `:173` (S22 verifier round 1 leftovers, items 1-5) | agent / owner | ui+qa | `hardcoded_text_gate`, af3, P4 device | S | **verify-first** — item 3 (tip4/tutorial_map "M" vs "K") is in cut locales now (2-locale truth); item 2 stale frames by design; items 1/4/5 need a check or device. |
| KI-188 | `:188` (rc17 `user://` folder moved by title change) | owner | lead | fresh-profile smoke at P3 | S | **owner-packet** — verified by P3 EXE smoke on a fresh profile. |
| KI-257 | `:257` (DIAGNOSED P8: 3D-scene gate failure point) | closed-with-evidence | qa | current `check.sh --all` engine section | - | **closed** — dated diagnosis, preserved. |
| KI-294 | `:294` (CRITICAL NEW NOT FIXED: magenta/pink 3D corruption windowed) | agent / owner | visual + lead | `guarded_windowed` frame capture + `visual_truth_gate` | M | **verify-first** — 2026-09-21 integrated-GPU driver class; P0 `check.sh --all` engine gates ran OK on this machine. Need one windowed frame before closing; if it reproduces, owner decision on hardware. |
| KI-335 | `:335` (NEW NOT FIXED: City Map travel to park -> `(inf,inf,inf)` softlock) | agent | world + qa | headless regression scene + IRON RULE bot | M | **verify-first** — must be reproduced on current `main` before any fix (§1.5: do not fix from old logs). |
| KI-359 | `:359` (CORRECTION: spine softlock not fully resolved) | agent | qa | 3-seed bot Normal+Hard | M | **verify-first** — bot runs are P2/P3 IRON RULE. |
| KI-377 | `:377` (PARTIALLY RESOLVED spine-phase softlock) | agent | qa | same | M | **verify-first** — same as KI-359. |
| KI-407/422 | `:407` (RESOLVED boss-phase softlock), `:422` (spine-phase root cause not found) | closed-with-evidence / verify-first | qa | bot | - | `:407` **closed** (dated); `:422` **verify-first**. |
| KI-1947 | `:1947` (arena release agent: art pass 2 repainted wired 2D art) | post-release | visual | none | L | **deferred** — art scope, B9, and the arena branch no longer exists on origin. |

## 5. `AGENTS.md` blockers

| id | source | disposition | zone | gate-check | estimate | status |
|---|---|---|---|---|---|---|
| AG-6/7 | `AGENTS.md:6-7` (only main + gh-pages on origin; no oc/* arena/*) | closed-with-evidence | lead | `git ls-remote --heads origin` | S | **closed** — confirmed at P0: only `main`, `gh-pages`, `phase-b-doc-truth` (my P0-era branch), no `oc/*`/`arena/*`. |
| AG-25/29 | `AGENTS.md:25-29` ("only W1 connected", "ground path ambiguous", `district_grading` "looks like dead code") | resolved-by-code | lead | §2 table above | S | **resolved** — W2-W10 connected; ground is script-driven (`district_grading.gd` ground tint + `world_env_setup.gd` single WE). |
| AG-35/39 | `AGENTS.md:35-39` (GAMEFEEL_SPEC conflict moot) | closed-with-evidence | lead | `git log --all -- docs/GAMEFEEL_SPEC.md` | S | **closed** — the unmerged variant no longer exists; `main`'s spec is authoritative. |
| AG-42 | `AGENTS.md:42` (W2-W10 before/after stills) | agent | lead | af3 frame check | M | **open** — folded into T1/P2. |

## 6. `docs/store/HUMAN_CHECKLIST.md` items (all 8 sections)

| id | source | disposition | zone | gate-check | estimate | status |
|---|---|---|---|---|---|---|
| HC-3 | `:3` music credits (2026-11-10, CC-BY 4.0) | agent | content+lead | CC-BY binding/attribution gate, in-game credits reachability (P3) | S | **open** — music=A decided (`MUSIC_RIGHTS_MEMO`); player-reachable credits still needs a windowed screenshot. |
| HC-11 | `:11` AppLovin MAX ads | decision | owner | §11 Q2 | S | **owner-packet** — default: stub, plugin off (as rc14); enabling = separate wave + Data Safety update. |
| HC-58 | `:58` Play Store / release | owner | owner | §11 Q2/Q1, P4 click path | M | **owner-packet** — app creation, IARC, AAB upload, Open Testing. |
| HC-92 | `:92` CC0 asset reference repo (TRUTH WAVE ask) | post-release | visual | B9 licence row per binary | L | **deferred** — P5 backlog. |
| HC-105 | `:105` rating change PEGI 16 (was 12) | decision | owner | §11 Q1 | S | **owner-packet** — default PEGI 16. |
| HC-115 | `:115` AppLovin Data Safety disclosure | decision | owner | §11 Q2 | S | **owner-packet** — no-ads default: no collection. |
| HC-123 | `:123` RESCUE WAVE delta | owner / post-release | mixed | P4 device + owner eyes | M | **open** — device/human rows. |
| HC-140 | `:140` Steam (optional secondary platform) | post-release | store | none | L | **deferred** — P5 backlog. |

## 7. `docs/PROJECT_STATE.md` owner items (all 6)

| id | source | disposition | zone | gate-check | estimate | status |
|---|---|---|---|---|---|---|
| PS-1 | `docs/PROJECT_STATE.md` item 1 (Windows Authenticode signing) | owner | owner | `Sign-WindowsExe.ps1` no-certificate test | S | **owner-packet** — purchase + sign; §11 Q4/P4. |
| PS-2 | item 2 (Android upload signing + Play Console) | owner | owner | `aab_check.py --bundletool --secrets` | M | **owner-packet** — keystore exists; passwords injected at P4. |
| PS-3 | item 3 (real AppLovin MAX SDK key) | decision | owner | §11 Q2 | S | **owner-packet** — default stub/off. |
| PS-4 | item 4 (texture-compression banding pass, 74 files) | owner | owner | device capture at P4 | M | **owner-packet** — owner art-direction call. |
| PS-5 | item 5 (draw-call budget re-measure on target hardware) | owner | owner | `guarded_windowed` perf gate on device | M | **owner-packet** — also `G-WINDOWED`. |
| PS-6 | item 6 (store listing publish + Open Testing) | owner | owner | Play Developer API at P4 | M | **owner-packet**. |

## 8. §11 owner questions (asked ONCE, in the P0 report)

Q0 budget `N`; Q1 PEGI 16 vs 12; Q2 ads on launch; Q3 O-1 High tier as-is; Q4 K-1 history
rewrite (irreversible, default NO); Q5 L-1 Russian comments; Q6 two shop skin stubs
(irreversible for saves, needs explicit decision); Q7 monsters/boss primitives + CC0 after;
Q8 UNLOCK-27 (real unlocks vs remove, -300 coins); Q9 ENDART-27 / Gemini music timing;
Q10 S-15/S-16; Q11 tag v1.0.1 + Production rollout moment.

**ANSWERED ONCE 2026-11-11 — all defaults by delegation ("approved by delegation"), dated with
a revert path in `docs/TZ_DECISIONS.md` §11 package table. Not re-asked.** Owner answers:
Q0 `N = 0` (zero Qwen calls, Hy4 covers the three optional review roles); Q1 PEGI 16;
Q2 ads stub / plugin off; Q4 K-1 **NO** (irreversible, not performed); Q6 shop skins **kept**
(irreversible action not performed); Q7 primitives accepted, CC0 post-release; Q3/Q5/Q9 by
default; Q8/Q10/Q11 remain owner decisions deferred to P4 (no economy or content change made).
`docs/BUDGET_LEDGER.md` updated from "cap unknown" to `cap = 0`.

## 9. Completeness statement

- KNOWN_ISSUES OPEN/not-CLOSED blocks: 26 -> §4 (all present).
- AGENTS.md blockers: 5 -> §5.
- HUMAN_CHECKLIST sections: 8 -> §6.
- PROJECT_STATE owner items: 6 -> §7.
- §9.1 backlog rows: T1-T14 -> §1.
- P0 battery defects: 8 -> §3.
- §11 owner questions: 11 + Q0 -> §8.

**Open agent rows at P0:** T1 (partial), T2, T3, T4, T5, T6, T7, T8, T9, T10, T12, T13,
T14 (fixed in this PR), G-MSAA, G-AF5-FOREIGN (lane decision), G-AUDIT, G-DEMO-* x3,
G-WINDOWED, G-CLEAN-TREE, KI verify-first rows, AG-42, HC-3.
**Open owner/decision rows:** §7 (6), §8 (12 questions), P4 device/console items.
**Post-release rows:** all B9 / art / mesh / Steam / CC0 / L-1 / K-1 items.

P0 DoD: battery fixed (6/97, raw log committed), registry complete, W-conflict resolved by code,
§11 package asked once. No code was changed in P0.
