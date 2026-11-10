# Release record — 2026-11-10 (current main `06c782dd`)

This record supersedes the build identity of `docs/release/RELEASE_CANDIDATE_2026-11-10.md`,
whose Windows/Web archives were exported from the older `a2672e77`. Everything below was
built and verified from the *current* merged main, with no force push or protection bypass.

## Source and toolchain

| Item | Value |
|---|---|
| Source commit | `06c782ddf8fdaf9538b36e0f19f145f0b6e1213a` (PR #67, merged) |
| Source tree | clean frozen clone, `git status --porcelain` empty |
| Editor / templates | Godot `4.7.2.stable.official.ed1daf0bf`, official cached toolchain |
| Import | canonical `--editor --import --quit` with `theme/custom` cleared; `project.godot` restored byte-identical |
| Python deps | `numpy`, `Pillow`, `soundfile` installed for the gate interpreter (environment only) |

PR #67 fixed a real reproducible defect: `tools/check.sh`'s `qa_guard_e2e()` cleaned its
deliberately damaged fake `.qa_snapshot` with a bare `rm -rf`, which the Windows safe-delete
wrapper refuses for paths with an embedded drive prefix (`C:\Users\...`). The damaged copy
survived and `QaLaunchGuard._block()` crashed every later engine gate (`OS.crash` -> exit 132).
The four cleanup calls now use the existing `_udg_rm_rf` helper (converts via `cygpath`).

## Verification actually performed

| Check | Result |
|---|---|
| `tools/check.sh --static` on current main | **71 passed, 0 failed** |
| `tools/check.sh` (full engine battery, disposable `APPDATA`) | **100 passed, 0 failed** (2 intentional windowed-only skips) |
| `QaLaunchGuard` lifecycle | OK (was FAIL before PR #67) |
| Canonical pipeline engine gates | 16/16 PASS before the run was stopped by a sandbox bulk-delete guard (see below) |
| Windows EXE, headless 300 frames | exit 0, zero error lines |
| Windows EXE, windowed 900 frames | exit 0, OpenGL 3.3 Core / AMD Radeon, zero error lines |
| Web in real Chromium 157 | see below |

The canonical `tools/release/pipeline.py` run reached `[16] boot` with all 16 checks PASS and
then failed in `reset_profile()`: the sandbox's bulk-delete guard refused deletion of the
pipeline's own disposable `__TLS_QA_*` profile (54 files > 50 threshold,
`SAFE_DELETE_BULK_CONFIRM_REQUIRED`). This is an environment guard, not a game or pipeline
defect. No guard was weakened or bypassed: the exports were produced by
`tools/release/export_current.py`, which mirrors the pipeline's import/export steps without
the QA-profile loop. The full engine battery was already run separately (100 passed).

### Web browser acceptance (previously open)

`RELEASE_CANDIDATE_2026-11-10.md` states "Web is built but has not been verified in a browser".
That gap is now closed with real browser evidence:

- Served with `tools/release/serve_web_check.py` (correct `application/wasm`, COOP/COEP).
- Real Chromium 157 loaded `index.html`: console reports
  `Godot Engine v4.7.2.stable.official.ed1daf0bf`, WebGL 2.0, single-threaded.
- Canvas present at 1262x568; `document.title == "Last Streetlight"`.
- **Zero page errors.** The only warning is the expected CrazyGames stub notice
  (SDK not connected, ads disabled, game continues).
- The rendered main menu is captured in
  [`../artifacts/release-20261110/current-main/web-browser-startup.png`](../artifacts/release-20261110/current-main/web-browser-startup.png):
  the preserved street artwork, Russian wordmark and all five menu entries draw correctly.

A Play-button interaction test was attempted but the browser daemon timed out while the
114 MB PCK loaded; **no interactive Web gameplay is claimed**.

## Artifacts

Built to `TLS_Release_Out/export-run/artifacts/` (outside the repo). Each archive contains
`BUILD_INFO.json` with the exact source commit plus a `THIRD_PARTY_NOTICES/` directory:
`ASSET_LICENSES.md`, `LICENSED_MUSIC_REFRESH.md`, `THIRD_PARTY_FONTS.md`,
`RobotoCondensed-Full-VF.LICENSE.md` (Apache 2.0) and `.SOURCE.md`. CC-BY 4.0 music and
SIL OFL 1.1 / Apache 2.0 fonts therefore ship with their attribution and licence text.

| Archive | Bytes | SHA-256 |
|---|---|---|
| `LastStreetlight-1.0.1-windows.zip` | 121,169,018 | `52a557ef4e20850fb35b7cdfa0fd3c8128a5e8e19c5680aa90a17f8ce48cc152` |
| `LastStreetlight-1.0.1-web.zip` | 96,355,881 | `68e8c888b4a715c935c95b2775140d1536be921e3b632ca911145966bcc5e945` |

Checksums are in [`../artifacts/release-20261110/current-main/SHA256SUMS.txt`](../artifacts/release-20261110/current-main/SHA256SUMS.txt)
and were re-verified after repackaging. The build report is
[`../artifacts/release-20261110/current-main/export-report.json`](../artifacts/release-20261110/current-main/export-report.json).

## Honest acceptance status: NOT READY

Green automation is not release acceptance. The following remain open and are **not** claimed:

1. **World visual fidelity** — the owner rejected the existing material candidates for distant
   facade repetition and weak Low-tier detail. No new candidates were generated, reviewed or
   shipped; no post-processing was added to conceal defects. Whole-world parity with the
   menu reference is unfinished.
2. **Comfortable progression** — the recorded assisted autoplay WIN used 2 deaths and 14 nudge
   rescues. No collision/traversal fault was reproduced, so no mechanic was changed. Clean
   human navigation is unverified.
3. **Audio** — licensed Scott Buckley Hymn/Moonlight bindings, mastering, routing and
   in-game CC-BY attribution are present and gated, but no human listening test was possible.
   Numerical decode/loop-seam checks do not certify subjective pleasantness.
4. **Android** — no release keystore or signing identity exists in this checkout, and no
   Android SDK/JDK is installed. No AAB was built or signed. The older signed AAB does not
   certify this source.
5. **Physical device** — no phone DPI, safe-area, multitouch, readability or performance test.
6. **Windows signing** — the EXE is unsigned; CA re-sign remains an owner action
   (`tools/release/Sign-WindowsExe.ps1`).
7. **Store submission / Cloudflare** — no submission, no deployment, no account connection.

## Exact next command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\Finish-IgraRelease.ps1 -Update
```

On a machine without the sandbox bulk-delete guard, that driver re-runs the complete
verification and rebuilds Windows/Web from the newest main. Android additionally needs the
existing release signing environment, SDK and JDK 17.

## Correction note (2026-11-10, FINAL_CLOSURE_BRIEF §B2)

The static / engine / verification results above apply to the **source commit recorded in this
file** (`06c782dd` as built here). Per the FINAL_CLOSURE_BRIEF, the GitHub `main` tip at
brief-authoring time was CI-red and was restored green by Phase A; do not read this dated build
record as the live CI status of the current tip. The authoritative, machine-checked status is
`docs/PROJECT_STATE.md` (enforced by `tools/closure_guard.py`).
