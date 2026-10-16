# Provenance of `docs/_archive/`

Documents moved here by the cleanup of Session 26 (`docs/CLEANUP_MANIFEST.md`, section 6). Each was named by no other tracked text file, by file name or by stem, and
none holds a `path:line` citation (`tools/af5_check.py` has nothing to hold in them). A document is moved, never deleted: `git mv docs/_archive/<name> docs/<name>`
puts one back, and `git log --follow` keeps its history.

| Archived file | Was | Last commit | Bytes |
|---|---|---|---|
| `docs/_archive/ERROR_LOG_DEVICESV2.md` | `docs/ERROR_LOG_DEVICESV2.md` | 2026-09-08 | 1544 |
| `docs/_archive/ERROR_LOG_PLAY_FINAL.md` | `docs/ERROR_LOG_PLAY_FINAL.md` | 2026-09-08 | 2998 |
| `docs/_archive/REPORT_MARKET_V2.md` | `docs/REPORT_MARKET_V2.md` | 2026-09-08 | 3445 |
| `docs/_archive/REPORT_PLAY_FINAL.md` | `docs/REPORT_PLAY_FINAL.md` | 2026-09-08 | 3105 |
| `docs/_archive/STAGES_REPORT.md` | `docs/STAGES_REPORT.md` | 2026-08-13 | 11027 |
| `docs/_archive/ROLES.md` | `docs/ROLES.md` | 2026-08-07 | 684 |
| `docs/_archive/PACKAGES.md` | `docs/PACKAGES.md` | 2026-08-07 | 593 |
| `docs/_archive/PHASE_2_DESIGN_SPEC.md` | `docs/PHASE_2_DESIGN_SPEC.md` | 2026-08-08 | 1704 |
| `docs/_archive/PHASE_A_DESIGN_SPEC.md` | `docs/PHASE_A_DESIGN_SPEC.md` | 2026-08-08 | 816 |
| `docs/_archive/CONTEXT_CACHE.md` | `docs/CONTEXT_CACHE.md` | 2026-08-23 | 834 |
| `docs/_archive/BLOCK4_PROJECTGODOT_PATCH.md` | `docs/BLOCK4_PROJECTGODOT_PATCH.md` | 2026-08-09 | 693 |

Nothing under `docs/_archive/` is a source of truth for a gate, a store listing or the production bible; `docs/PRODUCTION_BIBLE.md` is.
