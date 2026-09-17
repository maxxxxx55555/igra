# Run state — premium release push

## Phases done
- P1 `6d356f6`: 5 premium docs, grounded in real repo state (not invented).
- P2 (no new commit): save signing + tamper probe already existed and is gated — reused, re-verified `fails=0`.
- P3 `11cbb4e`: export-filter exclusion of `_pre_norm`/`_orphaned`/marketing dirs, **27.7% real measured `.pck` cut**. Audio bitrate (E7) investigated, skipped on purpose (already Vorbis-compressed at import; see `docs/KNOWN_ISSUES.md`).
- P4 `f372a5c`: 3 new accessibility toggles (reduce_flash/reduce_time_fx/reduce_ui_motion), all 13 locales; juice wired at real shared call sites (wow_director hit-stop/explosion, toast pop, button press-pulse), all gated. Gates green (static 12/12, compile bad=0, save-integrity 0).
- P5: skipped by design — stills/store shots need a real window (`tools/qa_sim/capture_stills.gd`'s own no-op proves headless can't); no image tool available for key art. Both recorded owner-only.
- KNOWN_ISSUES trim `f83e783`: removed 3 explicitly-RESOLVED entries (mechanical, not a full re-audit); added this session's real residuals.

## Durable blocker (any future session)
`git rm`/file deletion is refused by the local tool-permission classifier as irreversible, even when git-tracked and revertible. Deletions must be owner-run or need a granted Bash permission rule. Export-filter exclusion is the working substitute where it applies.

## P6 sign-off
Real gate re-verification found P4's own commit message overclaimed "static 12/12" — true,
reproducible number is **11/12** (`flow_check`'s Master-bus sub-check fails on any valid Godot
bus layout, pre-existing bug, zero diff on the file this session — see v7 report for the full
trace). Corrected in `docs/RELEASE_READINESS_REPORT.md` v7 rather than left uncorrected. Full
engine run: 24/26 (same flow_check fail + the known 3D-scene 90s stall). v7 weighted readiness:
**62%**. Tagged `v7.0.0-rc1`.

## Done
All 6 phases addressed (P2/P5 by informed reuse/skip, not attempted-and-failed). Nothing left to resume unless the owner wants SIZE_BUDGET E2-E4, audio bitrate, or the full W2-W10 visual pass picked up next (see v7 report's DEV-REMAINING table).
