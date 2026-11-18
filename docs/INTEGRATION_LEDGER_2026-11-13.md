# Integration requirement ledger — 13 November 2026

Candidate branch `integration/igra-20261112-141210-a74feb40`, worktree
`C:/Users/Maxsim/Desktop/TLS_Build.integration-20261112-141210-a74feb40`.
Frozen base `6667fd92951efffce610206b2adb0f4c8739c0ed` (`origin/main`).
The original checkout `C:/Users/Maxsim/Desktop/TLS_Build` was left intact.
No push, merge, tag, export or store publication was performed from the agent
session. Evidence bundle: `docs/artifacts/integration-20261113/`.

Status words: `closed` (implemented, gate passes, real evidence in the bundle),
`verified` (measured on this machine, no code change), `owner` (a decision or a
physical prerequisite outside this environment), `NOT_READY` (a mandatory gate
not demonstrated).

## 1. Requirement ledger

| id | requirement | implementation commit | test / gate | evidence | status |
|---|---|---|---|---|---|
| R1 | T2: keep the district LUT enabled across a graphics-tier change; restore base contrast and saturation on high-contrast off | `92891bea` | settings-persist engine probe, full battery | `docs/artifacts/integration-20261113/verification.out` | closed |
| R2 | T3: consolidate the settings-persist probe preload and realign the doc citations the T2 edit moved | `92891bea` | `af5_check` 879 citations, 0 findings | same | closed |
| R3 | T7: headless two-finger touch probe and an index-agnostic HUD touch gate | `92891bea` | `two_finger_touch_check --demo` BITES, real 0 findings, headless suite | same | closed for code and test; a physical two-finger device test is still `owner` |
| R4 | T6: English and Russian story corrections, content mirrors, integrity manifest | `a23e0310` | `audit_content_depth` 0 ERROR, `gen_integrity_manifest --check` 37 files match | same | closed |
| R5 | T8: 48 raw-px touch-target floor with DPI scaling, mutation-proof | `a23e0310` | `touch_target_gate --demo` BITES, real 0 findings | same | closed for code; physical-size confirmation is `owner` |
| R6 | P1: real touch routing (look ownership before swipe/pinch, cancel and focus-out cleanup) | `a23e0310` | two-finger probe, closeout suite, full battery | same | closed for code; device routing is `owner` |
| R7 | P1: the enemy HUD bar follows the target instance, not the first monster of the species | `a23e0310` | closeout suite, full battery | same | closed |
| R8 | Every UI screen dressed in the main-menu palette, with a biting canon gate | `c804350c` | `menu_style_unify_check --demo` BITES, real 19 tokens / 109 files / 0 findings | same | closed |
| R9 | A blocking screen can never stay visible after `close()` (inventory soft lock) | `c804350c` | `ui_close_check --demo` BITES, repeated closeout V.5 runs | same | closed |
| R10 | AF3: eight sign-off frames that name the code tree and capture time actually shipped | `87353569` | `af3_frame_check` 8 frames 0 fail, `visual_truth_gate` 8 PASS | `docs/stills/store/` | closed by a real windowed re-shoot at `c804350c`; the stale `a2672e77` set was archived unmodified, no F4 scope exemption was added |
| R11 | Draw-call and frame-time budget on supported hardware | none | windowed `perf_check_scene`, rc 0, fails 0, D1 102, D11 107, p95 18.06 ms | `docs/artifacts/integration-20261113/verification.out` | verified on this machine |
| R12 | Music bus not silent, stems cross over with the threat level | none | windowed `audio_truth_gate_scene`, rc 0, Music bus peak -11.2 dB, PASS overall | same | verified on this machine; listening to an exported build is `owner` |
| R13 | Rendered English and Russian checks | none | windowed `final_frames_scene`, 18 frames, EN and RU at text size 2 read by eye | `docs/artifacts/integration-20261113/01_menu_en_s2.png`, `01_menu_ru_s2.png` | verified; no clipped or overflowing text, all glyphs drawn |
| R14 | Production reusable 3D assets (facades, props, creatures, hands) | `f37072d7` (B9), `0be66b1c` (B10), `d5e77c48` (lamp) | `production_asset_check --demo` BITES 5 mutants, real 0 findings; `b10_asset_check --demo` bites its mutants, real 0 findings, 6 authored meshes (facade bay, creature shell, first-person hands + LOD) with UV/normal/colour, each wired to a live consumer with materials/collision/LOD; 7 triangulated B9 props in `assets/mesh/`, every `.gd` preload resolves | `docs/artifacts/rc16/all_2026-11-14.out`, `b10_generator_updated.out`, `b10_asset_check.py` | closed for props, facades, creatures and hands as project-authored reusable meshes in live gameplay; AI key-art still blocked (no `OPENAI_API_KEY`) |
| R15a | Exported-package startup (Windows Desktop and Web) | 15 Nov 2026 (this pass) | real `--export-release` for both presets, exit 0; Windows exe launched headless and windowed (OpenGL 3.3 / AMD Radeon), 0 script/parse errors, 4 real 1920x1080 frames captured from the exported exe, 0% magenta, non-blank; Web wasm/pck magic valid, all 6 local refs resolve; user-data restored byte-identical on every launch | `docs/artifacts/rc16/windows_export_2026-11-15.out`, `web_export_2026-11-15.out`, `windows_startup_2026-11-15.out`, `windows_startup_windowed_2026-11-15.out`, `windows_frame_capture2_2026-11-15.out`, `docs/artifacts/integration-20261113/windows_export_frame.png` | closed for Windows/Web startup; builds are unsigned and local, in gitignored `build/` |
| R15b | Android signed `.aab`, physical device stability, signing, store publication | none | not run: Android SDK/build template absent, JDK 1.8 only, keystore fields empty (owner-held secret), no device, no account rights | `export_presets.cfg`, `docs/RELEASE_CHECKLIST.md` | NOT_READY, `owner` |
| R16 | Sustained frame times and touch targets on a real phone, rendered before/after pairs with identical settings from this pass | none | not demonstrated | — | NOT_READY, `owner` |
| R17 | Owner decisions: T4 primitive-budget definition, T11 export environment confirmation, T12 mutation/coverage engine chain, premium-art scope | 15 Nov 2026 (this pass) | T12 coverage re-measured 103/106 (3 A3-waived misses). Full 18-set mutation chain: `S26 MUTATIONS verdict=PASS mutations=105 bad=0`, exit 0 — every mutant bites, no stray. Four stale anchors and one QA order dependency were found and repaired on the way (see section 2). | `docs/artifacts/rc16/t12_pass_run.out`, `t12_pass_mutations.txt`, `docs/artifacts/rc16/proofs/t12_pass_mutations.*`, `t12_coverage.txt`, `s29_baseline_2026-11-15.out`, `s29_baseline_fixed_2026-11-15.out` | `closed` for the T12 engine chain; the four owner decisions remain `owner` |
| R18 | Release landing page self-contained, canon-correct and keyboard-accessible | 2026-11-15 (this pass) | `release_page_check --demo` bites all 4 mutants, real 0 findings, wired into `check.sh`; 14 local refs resolve, 0 external URLs | `web/store/`, `docs/artifacts/integration-20261113/RECHECK_2026-11-14.md` | closed |
| R20 | Missing store shot03/04/06 captured from real gameplay | 17 Nov 2026 (`d5e77c48`) | windowed `TLS_STORE_SHOTS=1` run of the B10 verifier: `STORE_DONE failures=0`; three real 1920x1080 RGB engine frames of the residential playground under flashlight, the Keeper's shed bench under its brass lamp, and Workshop B under its single warm overhead lamp; 0% blown-out white, non-blank; user-data restored byte-identical | `store/screenshots/shot03_stealth_horror_1920x1080_en.png`, `shot04_keeper_lore_1920x1080_en.png`, `shot06_mystery_inside_1920x1080_en.png`, `.qa_logs/b10_verify_scene.log` | closed (real captures, not painted substitutes) |
| R21 | Skill tree reads as the same game as the menu (no opaque black wall) | 18 Nov 2026 (`dc43b3f0`, merged at `5024b288`) | the 96 % wall and flat paper are gone: the shop's own dim street art, a translucent tactical scrim, an in-project canvas shader vignette, a 1 px steel frame and an amber rule; unlock paths are drawn from the live `requires` table; `skill_tree_canon_check --demo` bites 4 mutants, `menu_style_unify_check` 0 findings, closeout `s29` 89/0 and `finish` 4/0, engine boot 0, real GPU frame read and accepted; AF3 stills re-shot against this commit | `scripts/ui/skill_tree_chrome.gd`, `scripts/ui/skill_paths.gd`, `tools/qa_sim/skill_tree_canon_check.py`, `docs/stills/store/` | closed |
| R22 | Darker, non-blinding night lighting and a map that charts only lit ground (PR #81) | 18 Nov 2026 (`2c48612e`, merged into the candidate) | PR #81 changed 26 runtime files but kept the pre-change stills, so `af3_frame_check` failed every frame with F4; the eight stills were re-shot on the real GPU against the PR's own code, `af3_frame_check` 8/0, `visual_truth_gate` 8 PASS, press kit regenerated, CI green (25 pass, 3 neutral), merged as `2c48612e` and the temporary branch deleted. The candidate then merged the PR, re-shot all eight stills again against the merged tree and re-ran the full battery | `docs/artifacts/rc16/all_merged_final_2026-11-18.out`, `docs/stills/store/` | closed |
| R19 | Gameplay stability re-runs on the final candidate | none (verification only) | two standalone `closeout_check 420` runs, each 655 checks / 0 fails / exit 0, profile restored byte-identical | `docs/artifacts/rc16/closeout_stability_1_2026-11-15.out`, `closeout_stability_2_2026-11-15.out` | verified |

## 2. Verified runs

- Static battery before the re-shoot, three passes: 78 passed, 1 failed each time; the single failure was `af3_frame_check`.
- Static battery after the re-shoot: 79 passed, all green.
- Full `tools/check.sh --all` on the frozen candidate: 110 passed, 0 failed, exit 0. Two windowed-only checks are reported as skips by the battery, not as passes; both were then run separately and passed (R11, R12).
- `af5_check` 879 citations, 0 findings. Integrity manifest 37 files match. Content depth 0 ERROR. Press kit regenerated from code and checked.
- AF3 8 frames 0 fail; `visual_truth_gate` PASS on all eight (no magenta corruption, no blank frames).
- Repeated closeout V.5 runs after the UI-close fix were clean; the full battery's closeout gate is green.
- Re-verification on 14/15 November 2026 on this exact tree (`6e328877`), after the B9 art pass: `tools/check.sh --static` 80 passed / 0 failed / exit 0, and `tools/check.sh --all` 111 passed / 0 failed / exit 0 with Godot 4.7.stable (includes `timing_equiv` at 30/60/120 FPS and a byte-identical user-data restore). The two windowed-only gates are skipped by the battery, not passed; they were verified separately on real rendering and audio in the earlier pass (R11, R12). Raw logs: `docs/artifacts/rc16/static_2026-11-14.out`, `docs/artifacts/rc16/all_2026-11-14.out`. Full detail: `docs/artifacts/integration-20261113/RECHECK_2026-11-14.md`.
- `coverage_matrix.py` re-measured 103/106, exit 0, the same 3 waived misses (FOV kick, exploding barrels, radio — A3, Session 30). `s26_mutations.py --demo` and `coverage_matrix.py --demo` both pass. The full T12 mutation chain is NOT complete: 8 of 18 set logs exist, set 2 has 8 vacuous checks, sets 8-17 never ran. Not claimed as a pass.
- Two standalone closeout re-runs on 15 November: 655 checks / 0 fails / exit 0 each, profile restored byte-identical.
- Final full `tools/check.sh --all` on 16 November after every QA/asset fix: 112 passed / 0 failed / exit 0 (`docs/artifacts/rc16/all_clean_2026-11-16.out`), including `audit_content_depth`, `visual_truth_gate --demo`, `af2_both_ways --demo`, `release_page_check`, `lint_changed` with no skipped tools, `timing_equiv` and a byte-identical profile restore. An earlier attempted run (`all_final_2026-11-16.out`, 108/4) is kept as honest evidence of a measurement error: four static gates failed only because this agent ran the same file-writing checks concurrently with the battery on Windows; a clean re-run with no concurrent access is green. No code was changed between the two runs.
- Release landing page: four defects fixed (external font CDN, owner title canon, "Four districts" vs the real 11, no keyboard focus), locked by `release_page_check.py` whose `--demo` bites all four mutants; real page 0 findings. `lint_changed` 292 gd / 96 py / 24 sh, 0 findings, no skipped tools.
- Modeled B10 assets (17 November): a project-owned generator (`scripts/tools/_gen_meshes_b10.gd`, scene `gen_meshes_b10_scene.tscn`) writes 6 `ArrayMesh` resources — facade bay, creature shell and first-person hands, each with a real LOD. Each has UV/normal/vertex colour, a PBR material and a live gameplay consumer (`b10_assets.gd` in `skyline.gd`, `monster_rig.gd`, `weapon_manager.gd`; `b10_setpieces.gd` in `district_dressing.gd`). `b10_asset_check.py` is wired into `check.sh` and bites its mutants on the real page. The 17 November visual pass added a visible warm lens under the Workshop B overhead lamp, so the "one warm lamp over an empty bench" shot reads as a lamp rather than a white speck.
- Three missing store shots were captured from the real windowed game (not painted art) on 17 November with `TLS_STORE_SHOTS=1` and the B10 verifier's per-zone framing in each setpiece's local basis: `STORE_DONE failures=0`, three 1920x1080 RGB frames with 0% blown-out white and 0% magenta. The AF3 sign-off set was re-shot against the final code tree and `press_kit.py --write` regenerated (no F4 exemption).
- T12 mutation engine: the earlier 8-of-18 interruption was traced, not guessed. Read-only inspection found 4 stale anchors (SOV6, MUS2, MUS3, ONE3: `count=0` against current source), which is why set 2 read 8 vacuous checks. All 105 anchors were repaired to the current text with mutants that still break their checks; `--demo` passes and check ids stay unique. A first full 18-set run then bit all 105 mutants but judged FAIL with 18 strays; the strays were ONE2/ONE4 in sets 8-17. A clean-tree `CLOSEOUT_ONLY=s29` run reproduced those two failures (89/2), proving a QA order dependency: UISFX honours the shipped silence-before-first-input rule and the isolated group never unlocked audio. `_one_shots` now saves/sets/restores `_audio_unlocked`; the clean group is 89/0. A second full 18-set run then passed: `S26 MUTATIONS verdict=PASS mutations=105 bad=0`, exit 0, no vacuous, no stray. Assertions unchanged, no gameplay code touched, no gate weakened. Logs: `docs/artifacts/rc16/t12_final_run.out` (FAIL + diagnosis), `s29_baseline_2026-11-15.out` (2 fails), `s29_baseline_fixed_2026-11-15.out` (0 fails), `t12_pass_run.out` and `t12_pass_mutations.txt` (PASS), 18 attached raw set logs under `docs/artifacts/rc16/proofs/`.
- Real exports on 15 November 2026: the older checklist claim that export templates are missing is stale — Godot 4.7.stable templates (2.0 GiB) are installed. `--export-release` produced a 233,849,760-byte Windows exe (sha256 `0da91bee…`) and a Web set (39.5 MiB wasm, 124.7 MiB pck), both exit 0. The exported exe was launched headless (`--quit-after 120`) and windowed (`--resolution 1280x720`), both exit 0 with 0 script/parse errors; 4 real frames captured from the exported exe at 1920x1080 (mean luminance 0.114, std 0.098, 0.00% magenta) show the shipped main menu and street. Every launch ran under the user-data guard with byte-identical restore. These are local, unsigned builds in gitignored `build/` — no publication. Android remains blocked (R15b).

## 3. Branch selection record

`git merge-base --is-ancestor` proved none of the p1 commits below is an ancestor of the frozen main, so the lane was ported semantically rather than merged.

| commit | decision | reason |
|---|---|---|
| `53638bd4` (T2 / X5 LUT) | selected | real LUT-on-tier fix; ported with the base contrast and saturation restoration the contract asks for, plus the probe state gate |
| `e4f8c140` (T7 two-finger probe) | selected | headless probe and biting index-agnostic HUD gate; registered in the headless suite and the release pipeline |
| `c9409e96` (probe preload + citation realign) | selected | preload consolidation and the doc citations that the T2 edit shifted |
| `718a4fad` (G-MSAA null viewport) | rejected | main already holds the identical guarded viewport write and its own `viewport_write_guard` gate; porting would duplicate a fix |
| `612d8c8d` (T3 bound key hints) | rejected | main already reads live bindings through `InputRemap` in `help_ui.gd` and `inventory_ui.gd`, enforced by `hint_binding_check` |
| `380b3241`, `b06c0d31` (p1 stills and press kit) | rejected | frames and press-kit rows of a different code tree; the contract forbids copying another tree's evidence |
| `8cc30df9`, `30ce7e23`, `fac1b5bb`, `67852c51` (merges) | rejected | topology only, no new content; the underlying commits are decided above |
| `arena/8966ccea-igra`, `p0/audit-20261111`, `phase-b-doc-truth`, `gh-pages` | not touched | already represented in main or a separate privacy site; `gh-pages` stays separate. No branch was deleted. |

## 4. Verdict

**NOT_READY.** Every enforced code, content, citation, visual-canon, close,
fresh-frame and engine gate is green on this candidate, re-verified through
18 November 2026 (final full battery 118/0 exit 0 in
`docs/artifacts/rc16/all_merged_final_2026-11-18.out`; two standalone closeout re-runs
655/0 each; coverage 103/106; T12 mutation chain 105/105 PASS), and the two windowed-only gates
pass on real rendering and audio. Seven B9 production 3D prop meshes and six
B10 meshes (facade bay, creature shell and first-person hands with LOD) were
authored, wired to live consumers and gated, so R14 is closed for props,
facades, creatures and hands as project-owned reusable geometry. The three
missing store shots (03/04/06) are now real 1920x1080 engine captures from the
windowed game, not painted substitutes (R20), the skill tree is a translucent
tactical overlay over the street instead of an opaque wall (R21), and the
darker night lighting with the light-gated map of PR #81 was merged with its
own stills re-shot on the real GPU (R22). The AF3 still set was re-shot
against the final tree with the press kit regenerated. The release landing page is now self-contained,
canon-correct and keyboard-accessible (R18), gameplay stability was
re-verified twice (R19), and the T12 mutation/coverage engine chain now has a
full 18-set PASS (105/105 mutants bite, 0 stray, exit 0) plus coverage 103/106
with 3 A3-waived misses (R17). Exported-package startup is now demonstrated for
Windows Desktop and Web (R15a): both presets exported with exit 0, the
exported exe launched headless and windowed with 0 errors, and four real
1920x1080 frames were captured from that packaged build — one is committed
as `docs/artifacts/integration-20261113/windows_export_frame.png`. Those
builds are local and unsigned in gitignored `build/`, not a store release.
The release state is still NOT_READY because the signed Android `.aab`
(R15b: no Android SDK or build template, JDK 1.8 only, empty owner-held
keystore), physical-device testing, signing, a hosted privacy-policy URL and
store publication were not demonstrated, and because the four owner decisions
of R17 (T4, T11, premium-art scope and the like) remain open. No gate was
weakened, no F4 exemption was added, and no art, device, audio, signature or
publication proof was fabricated. AI key-art was not generated: no
`OPENAI_API_KEY` is configured in this environment.
