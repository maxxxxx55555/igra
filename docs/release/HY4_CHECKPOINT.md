# HY4 checkpoint — 2026-11-10

- Source: `06c782ddf8fdaf9538b36e0f19f145f0b6e1213a` (main, PR #67 merged).
- Changed files: `tools/check.sh` (merged), `tools/release/export_current.py`,
  `tools/release/serve_web_check.py`, `docs/release/RELEASE_RECORD_2026-11-10.md`,
  `docs/artifacts/release-20261110/current-main/*`.
- Fixed: Windows `qa_guard_e2e` cleanup left a damaged `.qa_snapshot`; bare `rm -rf`
  refused by safe-delete for `C:\...` paths. Now uses `_udg_rm_rf`.
- Passed: static 71/71; full engine battery 100/100 on disposable APPDATA;
  pipeline engine gates 16/16 before an external bulk-delete guard stopped the run;
  Windows EXE headless (300 f) and windowed (900 f, OpenGL 3.3/AMD) exit 0, zero errors;
  Web boot in real Chromium 157 (WebGL2, canvas 1262x568, zero page errors, menu rendered).
- Built: Windows + Web archives from current main, with third-party notices and
  SHA-256 checksums (see `docs/release/RELEASE_RECORD_2026-11-10.md`).
- Blockers (NOT READY): owner-rejected world materials, clean human navigation
  (autoplay WIN had 2 deaths + 14 nudges), human audio listening, Android signing/SDK,
  physical-phone DPI/touch/perf, unsigned Windows EXE, store submission, Cloudflare.
- Not done: no new art candidates/reviews, no mechanic changes without reproduced
  defects, no faked listening or device results, no force push.
- Next: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\Finish-IgraRelease.ps1 -Update`
- Full record: `docs/release/RELEASE_RECORD_2026-11-10.md`;
  decisions: `docs/artifacts/decisions_vlog.md`.
