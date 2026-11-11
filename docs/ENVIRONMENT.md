# ENVIRONMENT — session qualification (2026-11-11)

Owner directive "TLS -> RELEASE" v2.0 §2. Written by the lead (Hy4) at P0, before any code
change. Facts only; no gate is claimed green unless it was actually run. Repo canon: English.

## Session capability

- Shell, filesystem and git access: **present**. This is NOT a "patches-only" fallback session.
- `git` 2.55.0.windows.3; `python` / `python3` 3.13.14.
- `git ls-remote origin main` = `965ec095c945f976edab4a58ec6c66243a8d89e0`; local `main` equals it.
- `gh` 2.97.0, authenticated as `maxxxxx55555`, token scopes include `repo` and `workflow`.
- Parallel subagents: the platform exposes an Agent tool, but per §2 the worker lanes are
  emulated **sequentially** in one session with the SAME zone contracts and report format.
  P0 is audit-only, so no worker worktrees were created.

## Godot

- Binary: `C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe`
  (also `Godot_v4.7-stable_win64.exe`, `godot.exe`).
- `--version` -> `4.7.stable.official.5b4e0cb0f`. Confirmed by running it (P0).
- Export templates: `C:\Users\Maxsim\AppData\Roaming\Godot\export_templates\4.7.stable\`
  contains `android_debug.apk`, `android_release.apk`, `android_source.zip`,
  `web_nothreads_*` templates and the other platform templates. `version.txt` present.
- All engine runs go through `tools/qa_sim/proof_run --launch <id> -- <cmd>`; `check.sh --all`
  is run with `TLS_SKIP_REIMPORT=1`. `qa_snapshot` was verified ABSENT before the P0 run.

## Android / JDK / Gradle

- SDK present at `C:/Android/Sdk` (`build-tools`, `cmdline-tools`, `emulator`, `licenses`,
  `platform-tools`, `platforms`, `system-images`). **`ANDROID_HOME` is unset in this shell.**
- Android Build Template installed: `android/build/` with `gradlew`, `gradlew.bat`,
  `build.gradle`, `config.gradle`, `gradle/`, `res/`, `libs/`.
- Gradle 8.11.1 cached: `C:\Users\Maxsim\.gradle\wrapper\dists\gradle-8.11.1-bin\...\gradle-8.11.1`.
- JDK 21 = Android Studio bundled JBR: `C:\Program Files\Android\Android Studio\jbr`,
  `java -version` -> `openjdk version "21.0.10"`. `keytool.exe` present there.
- **Hazard recorded, not silently fixed:** `JAVA_HOME` still points at the deleted
  `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot\` and the bare `java` on PATH is
  `1.8.0_51`. The JDK 17 directory no longer exists. Per §2/§11 of the directive, JDK 17 must
  not be referenced; any Gradle/export command must set `JAVA_HOME` to the JBR explicitly.
- `.qa_logs/s39_export_vc17.sh:35` already sets `$env:JAVA_HOME` to the bundled JBR for its
  Gradle stop, so the T11 "JDK 17 path" row is a **verify-first candidate for closed-with-evidence**,
  not an open code task (see `RELEASE_GAP_FINAL.md` T11).
- `.signing/` holds `tls-release.keystore` and `release.env`; both are gitignored
  (`.gitignore:104` `*.env`, `.gitignore:94` `.signing/`). **No password was read, printed or
  committed.** Release passwords are injected by the owner at P4 via
  `GODOT_ANDROID_KEYSTORE_RELEASE_*`.

## Toolchain / lint (the §1.2 false-green trap)

- `shutil.which()` for `gdparse`, `gdlint`, `ruff`, `shellcheck`, `actionlint` returns `None`:
  they are **not on PATH as executables**.
- The pinned Python distributions ARE installed: `gdtoolkit==4.5.0`, `ruff==0.16.9`,
  `shellcheck_py==0.11.0.1`, `actionlint_py==1.7.12.25`, `pillow==13.0.0`, `numpy==2.5.4`,
  `soundfile==0.14.0`. `tools/lint_changed.py:52-60` resolves them next to `sys.executable`
  (`Scripts/`, `bin/`), which is why the full-toolchain gate is legitimately comparable to CI.
  `tools/check.sh --require-full-toolchain` is wired (Phase A) and must be used.
- `ffmpeg` 8.1.2 (Winget Gyan build) resolves on PATH — required by the audio gates.

## Foreign uncommitted state (§1.6 — DO NOT TOUCH)

At session start the tree was already dirty from a parallel external session. These paths are
**excluded from all my commits**:

- Modified: `docs/artifacts/rc16/launch_ledger.tsv`, `scripts/systems/music_manager.gd`,
  `scripts/tools/_audio_lifecycle_check.gd`.
- Untracked: `docs/AUTHENTICATION.md`, `docs/artifacts/rc16/proofs/codex_*`,
  `docs/stills/mega_release/`, `scenes/tools/streetlight_regression_check_scene.tscn`,
  `scripts/tools/streetlight_regression_check.gd`, `.claude/agents/*`, `.claude/skills/*`,
  `.opencode/agents/`, `.qa_logs/evidence/*`, `_fix_crlf*.py`, `_grep_all.txt`,
  `godot_extracted/`.
- `proof_run` recorded `uncommitted paths: 25` in the P0 proof header — honest, expected.
- `docs/AUTHENTICATION.md:23` is the sole cause of the `af5_check` failure in the P0 battery
  (a citation in a foreign, untracked doc). It is NOT my zone; it goes to the registry, not a fix.

## P0 battery truth (fixed, not cleaned up)

`tools/qa_sim/proof_run --launch p0_static_20261111 -- bash tools/check.sh --all`
(raw log `.qa_logs/proofs/p0_static_20261111.out`, copy
`docs/artifacts/rc16/proofs/p0_static_20261111.out`):

- **Result: 6 failed / 97 passed, `# EXIT=6`** on `965ec095` with a dirty tree.
- Six failures: `audit_content_depth`, `visual_truth_gate --demo`, `af2_both_ways --demo`,
  `lint_changed self-check (--demo)`, `af5_check`, `GOLD MASTER suite (engine errors in log)`.
- Re-run in isolation: `audit_content_depth` 0 ERROR / 1 WARN / 31 INFO (rc 0);
  `visual_truth_gate --demo` "demo OK (16 patterns)" (rc 0); `af2_both_ways --demo` OK (rc 0);
  `lint_changed --demo` "6 fixtures, 0 wrong" (rc 0); `af5_check --demo` "5 cases, 0 wrong" (rc 0).
  => four of the six are order/working-tree artifacts, not code defects; they need a clean-tree
  re-run before being closed (registry rows `G-DEMO-*`, `G-AUDIT`).
- `af5_check` real finding: 1, from the foreign `docs/AUTHENTICATION.md:23` (C3 claim word).
- `GOLD MASTER suite` real engine error:
  `SCRIPT ERROR: Invalid assignment of property or key 'msaa_3d' ... on a base object of type
  'null instance'` at `scripts/world_env_setup.gd:197` in `_apply_graphics_tier`, reached from
  `settings_manager.gd:526` -> `quality_manager.gd:72` (log
  `.qa_logs/gate_qa_headless_suite_scene.log:44`). Registry row `G-MSAA`.
- Two `windowed`-only checks self-skip by design (perf budget, audio truth). They are NOT
  failures, but they are NOT green either; P2/P3 must run them through `guarded_windowed`.
- No gate was weakened, no threshold tuned (§7 R6).
