# Release report — The Last Streetlight, 7 November 2026

Scope: the integration candidate `integration/igra-20261107-112445-cd7797a6b4`, built from
`origin/main` `1c185dc913d16bea1a70be74c93e466763e6129d`. This report states what was done,
what the automated checks actually measured, and what remains a human/owner decision. It is a
status record, not a marketing sheet: a check that did not run is named as not run.

## 1. Honest verdict

| Gate | State |
|---|---|
| Source integration (the other AI's 38 files + this pass's fixes) | DONE, committed |
| Static battery `tools/check.sh --static` | **PASS 72/72** (with the project venv Python) |
| Full battery `tools/check.sh --all` | run by the release workflow; see section 6 |
| Workflow `Verify -CheckSet Full` | see section 6 |
| Windows Desktop export | see section 6 |
| Merge into protected `main` | see section 6 |
| Physical devices, signing, asset rights, store acceptance | **NOT VERIFIED** (owner-side, cannot be automated here) |

The release workflow is deliberately conservative: even a fully green automated run leaves
`release_status = NOT_READY` until a human reviews the PR, checks a real windowed build on real
hardware, and answers the content-rating and rights questions. No step in this pass claims
otherwise.

## 2. What the other AI delivered (preserved verbatim)

`docs/release/handoff/00_OTHER_AI_RESPONSE_2026-11-07.md` is the first file committed in this pass
and holds the other agent's completion report word for word. Its 38 uncommitted source changes were
preserved, not discarded:

- Darkness and fog: one owner of the environment (`scripts/world_env_setup.gd`), district grading
  lights only the ground (`scripts/world/district_grading.gd`).
- Enemy visibility: `is_perceptible` = camera + light + line of sight; blind hits no longer reveal
  a position (`scripts/enemies/base_monster.gd`, `scripts/lighting/light_grid.gd`).
- Architectural map: real building footprints (`scripts/world/skyline.gd`,
  `scripts/ui/district_map.gd`) and cartography driven only by restored light with a per-lamp
  cursor (`scripts/systems/cartography.gd`).
- Mobile UI and multitouch: finger ownership, 1920×1080 stretch, splash, contrast
  (`scripts/player/player_3d.gd`, `scripts/ui/hud_3d.gd`, `project.godot`).
- New QA gates `perception_checks.gd` (VIS/DN/CART/WX/CFG) and corrected citations in 12 docs.

## 3. The three gates it left failing — all fixed and re-run in the engine

| Gate | Fault | Fix | Proof |
|---|---|---|---|
| `compile` (exit 2) | `scripts/tools/rc16/perception_checks.gd`: two `for lamp` loops collided with the function's own `var lamp`, which cascaded into `_closeout_check_runner.gd` via `const RcPerception` | both sweep loops renamed | `compile_gate_scene.tscn` green; the closeout scene parses again |
| `af5_check` (1 finding) | `docs/PERF_PASS.md` cited the old LOD line of `project.godot` for `mesh_lod/threshold_pixels`; the line had moved | citation refreshed | `python tools/af5_check.py` → 0 findings |
| `asset_check` (fails=1) | the gate demanded `permissions/internet=true` "for LAN multiplayer" while the release brief demands an offline build | gate replaced with the stronger offline rule: no `internet=true` **and** no enabled Android plugin that could re-add INTERNET to the merged manifest | `asset_check_scene.tscn` green; `closeout_check_scene.tscn` green |

The INTERNET decision was not a weakening of a gate. `docs/KNOWN_ISSUES.md` records the LAN lobby as
archived/unwired, the Android plugins are all disabled, the brief mandates offline, and the other
agent had already added `CFG1` asserting `permissions/internet=false` for every preset — the old
assertion directly contradicted the shipping policy. It was replaced by an assertion of that
policy, not deleted.

### 3b. Full-battery failures closed (the `-CheckSet Full` run)

The first Full run reported `Провалено: 2, пройдено: 101`: one transient tooling fault and five
`rc15 closeout` checks. All were fixed and the closeout gate re-run in the engine:
`[closeout] DONE checks=654 fails=0`.

- **lint_changed (transient Windows fault).** `tools/lint_changed.py --demo` created its fixture
  tree inside the repository and removed it with a plain `TemporaryDirectory` cleanup; Windows
  briefly keeps a just-written file handle open, so the cleanup raised and the demo exited non-zero
  even though all six fixtures were judged correctly (a leftover `.lint-demo-*` tree at the exact
  time of the failing run confirmed it). The demo now passes `ignore_cleanup_errors=True`, so a
  leftover ignored scratch tree cannot fail the self-check. The verdict logic, all six fixtures and
  every line-number citation in `docs/UTILITIES_REPORT.md` are unchanged.
- **C03 / UIFX4 / BOSSHIT1 (stale perception fixtures).** The other AI's visibility rules made
  damage numbers, hit markers and auto-aim legal only for a monster the player can *actually*
  perceive (camera frustum + rendered light + clear eye line). The three QA checks still set a bare
  `_seen_in_beam` flag and expected the old unconditional feedback. Their fixtures now stand a
  check camera on the target on the empty flat, exactly as the new `RcPerception` gate does, and
  assert perceptibility where relevant. No assertion was relaxed: C03 still proves the aim bends
  only toward a visible monster, UIFX4 still proves the pool of 12 recycles, BOSSHIT1 still
  requires both the number and the hit marker.
- **CT7 (touch look ownership).** The new "one finger owns the look" rule means a finger landing
  after `PINCH_PAIR_MS` must neither zoom nor steal the look. The old check expected it to turn
  the view. It now asserts three things instead of two: no zoom, no stolen look, **and** that the
  owning first finger still turns the view.
- **HUDP10 (joystick rest alpha).** The touch-contrast pass raised `REST_ALPHA` from `0.55` to
  `0.8`; the check pinned the literal `0.55`. It now reads `REST_ALPHA` from the shipped
  `virtual_joystick.gd` and asserts the ring returns to that value, so it cannot drift again.

## 4. Release workflow bug found and fixed

The supplied fixture harness `tests/Test-Igra-Release-Workflow.ps1` failed in `Prepare` on Windows
PowerShell 5.1. Root cause, isolated with a standalone probe: `ProcessStartInfo.EnvironmentVariables`
is lazily materialised and its **first read returns `$null`**. The fix primes the getter once before
use. The repaired script passes **11/11** harness cases and is kept both in the kit and in
`tools/release/owner_handoff/`; `run-state.json` records the new hash and the reason.

## 5. Frame freshness (AF3) — recaptured, not bypassed

`tools/qa_sim/af3_frame_check.py` failed 8/8: the store stills were shot at `650aea4`, while the
integrated runtime had changed 23 shipped paths. The gate exists to stop exactly that. The eight
frames were recaptured from the current HEAD with
`release_frames_scene.tscn` under the shell user-data guard (`proof s40_store_b61f669c`, exit 0),
the stale set was archived to `docs/stills/archive/pre_s40_20261107/`, and
`store/PRESS_KIT.md` was regenerated from the code.

- `af3_frame_check.py`: `frames=8 fail=0`
- `press_kit.py --check`: PASS
- `visual_truth_gate`, the sign-off and beauty frames, and the store frame tools all remain green.

## 6. Verification, export and landing chain

The supplied workflow is the authority for the release chain:
`-Mode Verify -CheckSet Full` → commit evidence → `-Mode Export` (Windows Desktop) →
`-Mode Publish` (push the integration branch) → PR into protected `main`. `main` enforces PRs even
for admins (`enforce_admins=true`, 0 required approvals), so a direct push is impossible by design.
The final state of that chain is recorded in
`C:\Users\Maxsim\Desktop\igra-release-runs\20261107-112445-cd7797a6b4\run-state.json` and in the
PR itself; this report does not guess its outcome in advance.

## 7. Branch analysis and cleanup

Read after `git fetch --prune origin`. Seven feature branches had **0 commits ahead of `main`** and
were ancestors of it, with no open pull requests: every change they held was already in `main`.
They were therefore deleted, with their tips recorded in `docs/ABSORB_PLAN.md` section 8 so any can
be restored. `origin/gh-pages` was kept — it hosts the privacy-policy page the store listing links
to, and is not game code. Nothing was lost, and nothing was left unabsorbed.

## 8. Deliverables added in this pass

| File | What it is |
|---|---|
| `docs/release/handoff/00_OTHER_AI_RESPONSE_2026-11-07.md` | the other AI's answer, first file, verbatim |
| `docs/release/UI_DESIGN_REVIEW_2026-11-07.md` | code-grounded UI review with prioritised, concrete optimisation proposals |
| `docs/release/ART_DIRECTION_RU.md` | the requested Russian art-direction description (atmosphere, deep but careful lighting, detailed non-default assets) |
| `docs/release/references/FPP_REPAIR_CONCEPT.png` + `ART_REFERENCE_NOTES.md` | the labelled concept reference, hash-matched to the kit manifest |
| `docs/release/RELEASE_REPORT_2026-11-07.md` | this report |
| `docs/ABSORB_PLAN.md` section 8 | the branch analysis and deletion record |

## 9. What is still NOT verified (carried over honestly)

- Android export: empty keystore, no Gradle/JDK release toolchain; the brief allows the Windows
  desktop build only.
- Production art and the provenance/licensing of the music; AI-generated reference images are
  labelled as references, not shipped frames.
- Windowed appearance, rendered performance, audible output and subjective audio on real devices.
- Physical device/signing checks and store acceptance. These are owner-side by the workflow's own
  contract and are reported as `NOT_VERIFIED`, never as a pass.
