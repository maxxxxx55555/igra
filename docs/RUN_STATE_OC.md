<!-- LOCALE TRUTH (2026-11-10): the shipped build supports exactly 2 locales (en, ru); the owner cut the other 11 on 2026-11-10. Body mentions of other (pre-cut) locale counts are historical records, not the current build. -->

# Single-file source delivery — 2026-10-28

Branch: work/single-script-final, based on public PR #31 bf563cc9.
Main read earlier: aacc5d8c; no owner remote write, merge or Console action.
One PowerShell includes source delta, AI handoff, Console list and report.
SourceHead is authoritative; no previous chat artifact is required.
Default: new branch upload. Offline: -Instructions, -PlayChecklist.
-CheckGame: full Godot/bot checks without exports; -Build/-Android: builds.

Source fixes: early First Light grant, Truth bunker eligibility, deferred
milestone autosaves, daily reward persistence, saved quick-wheel bindings
and pause ownership, initial HUD capacities, district grading on tier change.
Warmth now follows district power without a separate survival loop.
New night-street art, menu composition, readable HUD/objectives, adaptive
shop and wheel icons; toasts queue behind modals. Six locales, 1570 keys.
Earlier Android signature/manifest, loop seams and proof-log fixes retained.

Verification: 20 tool tests, 13 pass / 7 real-PowerShell skips.
Native changed-file lint: 20 GD / 7 Python / 2 Bash / 1 workflow, 0 findings.
Locale truth/fuzz (504 calls), integrity and 31-achievement audit pass.
Source hashes and logs: docs/artifacts/rc16/proofs/s35_*.
Artwork rasterization inspected; new Godot regressions parsed, not run.

Pending: fresh AF3/GPU frames, engine battery twice, three WIN seeds,
real windowed performance/audio, signed AAB and physical device review.
Old frames retain their actual dates; no threshold was weakened for a pass.
Owner provides contact, existing key, rights decisions and Console actions.
Continue: docs/RELEASE_HANDOFF_20261027.md, embedded in the PowerShell.

## Phase A — CI to green (2026-11-10)
PR #69 → merged main 04d54aae. A1: dropped unused `import os` in export_current.py (F401 that reddened static/pr-sims).
A2: killed the lint false-green class — check.sh now fails on any skipped linter; new `--require-full-toolchain`; static.yml+weekly-full.yml use it; lint_changed.py tool() also resolves the prefix-scheme scripts dir.
A3: proven both ways. Green (full toolchain): 72 pass / 0 fail. Red (shellcheck hidden): 1 fail "lint_changed ran with a partial toolchain". Artifacts: docs/artifacts/2026-11-10-phaseA/.
A4: weekly-full now installs soundfile+ffmpeg → success (run 42849108468), ending the 4-week failure.
A5: all four workflows green on main (static, pr-sims, weekly-full, release-wrapper); issues #21/#30/#48/#62 closed.
A6: branch protection now requires the `static` status check (force-push stays disabled).
Next: Phase B — doc-truth reconciliation + tools/closure_guard.py (6 rules).

## P0 — audit & registry (2026-11-11)
P0 DONE: base 965ec095 | battery 6 FAIL / 97 PASS (dirty tree) | Qwen 0 | UNFROZEN by owner directive v2.0.
Visual lane: W1-W11 conflict RESOLVED BY CODE — W2-W10 have live consumers; AGENTS.md:25-29 stale; ground script-driven; one WorldEnvironment. Table: docs/RELEASE_GAP_FINAL.md §2.
Artifacts: ENVIRONMENT.md, RELEASE_GAP_FINAL.md, BUDGET_LEDGER.md, WORKBUDDY_SKILLS.md, p0_static_20261111.out.
Next: one §11 owner package -> P1 (T2,T3,T7 real bugs -> T1 wiring -> T4,T5 perf -> T6,T8-T14).

## P1 wave 1 — G-MSAA (2026-11-11)
Visual lane: null-guarded msaa_3d tier write (world_env_setup.gd); regression gate msaa_guard_check.py + mutation; headless suite + explicit scene both green (proofs p1_msaa_*).
Next P1: T2 (X5 LUT), then T1/T4/T5, then T6/T8-T14.
Frames: 8 store stills re-shot at 718a4fad (AF3 F4), PRESS_KIT.md regenerated. af3 8/8 green. No scope-file bypass.

## P1 wave 2 — T7 + T3 (2026-11-11)
T7 (two-finger probe) closed-with-evidence: PR #73 stacked on #72. Hard headless constraint documented (parse_input_event cannot drive a Control in --headless); game touch code is index-agnostic (joystick holds first finger, HUD slot accepts any index, BtnInteract/BtnAttack wired to InputService). Gate two_finger_touch_check.py BITES under --demo.
T3 (key hints) closed-with-evidence: 3 live call-sites (`help_ui.gd`, `inventory_ui.gd`) now show the real bound key via InputRemap.key_of/key_text; en+ru `%s` parity kept. Remaining named keys are dead (no call-site) — flagged to owner.
