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
| R14 | Production reusable 3D assets (facades, props, creatures, hands) | `f37072d7` (B9) | `production_asset_check --demo` BITES 5 mutants, real 0 findings in both batteries; 7 triangulated project-authored `ArrayMesh` resources in `assets/mesh/`, every `.gd` preload resolves, each has a live world consumer | `docs/artifacts/integration-20261113/RECHECK_2026-11-14.md`, `docs/artifacts/rc16/all_2026-11-14.out` | closed for props (car, cabinet, fence, cart, crate, barrel, debris); facades, creatures and hands still NOT_READY |
| R15 | Exported-package startup, physical device stability, signing, store publication | none | not run: no device, no account rights, no signing identity in this session | — | NOT_READY, `owner` |
| R16 | Sustained frame times and touch targets on a real phone, rendered before/after pairs with identical settings from this pass | none | not demonstrated | — | NOT_READY, `owner` |
| R17 | Owner decisions: T4 primitive-budget definition, T11 export environment confirmation, T12 mutation/coverage engine chain, premium-art scope | none | T12 coverage re-measured 103/106 (3 waived misses); both engine self-checks pass; the 18-set mutation chain was interrupted after 8 sets, set 2 has 8 vacuous checks, sets 8-17 never ran — judge returns FAIL, not claimed as evidence | `docs/artifacts/rc16/t12_coverage.txt`, `docs/artifacts/integration-20261113/RECHECK_2026-11-14.md` | `owner` (decisions remain open; coverage measured, mutation chain incomplete) |
| R18 | Release landing page self-contained, canon-correct and keyboard-accessible | 2026-11-15 (this pass) | `release_page_check --demo` bites all 4 mutants, real 0 findings, wired into `check.sh`; 14 local refs resolve, 0 external URLs | `web/store/`, `docs/artifacts/integration-20261113/RECHECK_2026-11-14.md` | closed |
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
- Release landing page: four defects fixed (external font CDN, owner title canon, "Four districts" vs the real 11, no keyboard focus), locked by `release_page_check.py` whose `--demo` bites all four mutants; real page 0 findings. `lint_changed` 292 gd / 96 py / 24 sh, 0 findings, no skipped tools.

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
fresh-frame and engine gate is green on this candidate, re-verified 14/15
November 2026 (full battery 111/0 exit 0; two standalone closeout re-runs
655/0 each; final static battery after the release-page fix in
`docs/artifacts/rc16/static_2026-11-14.out`), and the two windowed-only gates
pass on real rendering and audio. Seven production 3D prop meshes were
authored, wired to live consumers and gated (R14, `f37072d7`), so R14 is
closed for props; facades, creatures and hands remain NOT_READY (the shipped
creature, weapon-viewmodel and facade geometry is procedural in-code, not a
reusable modelled asset). The release landing page is now self-contained,
canon-correct and keyboard-accessible (R18), and gameplay stability was
re-verified twice (R19). The release state is still NOT_READY because
production assets for facades/creatures/hands, physical-device testing,
exported-package startup, signing, a hosted privacy-policy URL and store
publication were not demonstrated, because the T12 mutation chain is
incomplete, and because the owner decisions of R17 remain open. No gate was
weakened, no F4 exemption was added, and no art, device, audio, signature or
publication proof was fabricated. AI key-art was not generated: no
`OPENAI_API_KEY` is configured in this environment.
