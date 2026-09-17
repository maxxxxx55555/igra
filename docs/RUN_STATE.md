# Run state — premium release push

## Phases done
- Turn 1: truth check + self-config. No CLAUDE.md hygiene commit — file is already 41 lines (≤150 limit), nothing to trim.
- P1 DONE: `6d356f6` "docs: premium spec pack" — 5 docs written, pushed to origin/main (ls-remote verified == rev-parse).
- P2 DONE, no new commit: save-signing + tamper-probe already existed (`scripts/core/save_system.gd` HMAC-SHA256, `scripts/tools/_save_integrity_check.gd` fuzz/tamper probe wired into `tools/check.sh` as gate "целостность сейва"). Re-ran it fresh this session: `fails=0 exit=0` after clearing a stale `.godot` import-cache artifact (same class of issue v6 already documented, not a code bug). Building a second signer would have duplicated this — reused instead, documented in `docs/SECURITY_THREAT_MODEL.md`.

## Blocked — needs owner input before P3/P4/P5 continue
1. **Working-tree churn from the P2 verification re-import**: running `godot --headless --path . --import` to clear the stale cache (needed to get a real pass/fail reading, not a false negative) regenerated ~540 tracked `.import` files with new random `uid://` values, plus `default_bus_layout.tres`. Tree was clean before that command. Discarding it (`git checkout -- .`) was blocked by the local auto-mode permission classifier ("Irreversible Local Destruction"). Nothing has been committed with this churn in it — it's sitting in the working tree. **Owner action**: run `git checkout -- .` (or approve a Bash permission rule for it) to get back to clean before P3 touches any files, so a real deletion diff isn't mixed with cache noise.
2. **P3 real deletion**: `docs/SIZE_BUDGET.md`'s E1-E4 (narrow candidates against the 10 dynamic-loader ID schemes) is real per-file work, not yet done past the 5 spot-checks already in the doc — only ~850 raw candidates have had methodology applied, not individual verification. Doing E5 (delete) without that risks the exact `hiding_spot.gd`-class mistake `CLAUDE.md` warns about. Next step if resumed: work E2-E4 file by file before any delete.
3. **P4/P5 windowed screenshot capture**: no tool in this session's toolset can drive a native Godot game window (the available browser automation only controls a web browser pane, not a Win32 game window). Stills/store-screenshot capture as specified needs either the owner to run it, or a different capture method (e.g. a Godot script using `Viewport.get_texture().get_image().save_png()` driven by a scripted playthrough, headless-renderable) — worth deciding which before P4 starts.
4. **Key art**: no image-generation tool available this session — will skip with this honest note per the run's own fallback instruction, not fabricate a placeholder.

- P3 PARTIAL: `export_presets.cfg` exclude_filter now drops `assets/audio/_pre_norm/` (163MB, documented archive masters), `assets/_orphaned/` (3.8MB, prior-verified dead), and `assets/store/{v2,storyboard,play_final,endings,press}/` (~87 files, marketing prep) from all 3 export presets. Measured real `.pck` cut via `godot --headless --export-pack`: 281,710,668 → 203,681,544 bytes = **27.7% cut**. Full evidence in `docs/SIZE_BUDGET.md`'s new "E1 executed" section. Gates re-checked: 1 static fail, confirmed pre-existing/unrelated (flow_check.py Master-bus string check, doesn't match Godot's own bus-layout format — zero diff on that file this session).
- STEP 0 blocker (import-cache churn) resolved this turn: `git checkout -- .` succeeded (classifier allowed it this time — no workaround used).

## New blocker this turn
`git rm -r assets/_orphaned/` was refused by the same local tool-permission classifier ("Irreversible Local Destruction") even though the folder is git-tracked and fully revertible. This blocks **any** file deletion in this session, not just this one — same will apply to P3's E5 and any future delete. Substituted export-filter exclusion where possible (done above); physical deletion needs the owner to run it directly, or grant a Bash permission rule for `git rm`.

## Next phase
P3 remainder — audio re-encode (E7), then P4/P5 code (juice + accessibility toggles; stills stay owner-run per the codebase's own documented headless-capture limitation, see below)

## STEP 1 finding
`scripts/tools/viewport_capture.gd` was NOT built. `tools/qa_sim/capture_stills.gd` (already exists, wired to `scenes/tools/capture_stills_scene.tscn`) already tried headless capture and documented why it can't work: `DisplayServer.get_name() == "headless"` → no compositor → no-op by design. Building a new headless capture script would just rediscover the same failure. Stills/store-screenshot capture stays a windowed, owner-run step using the existing tool.

## Repo facts (Turn 1)
- tip: 9b5aec0 "docs: release readiness v6 + fix probe's real-settings side effect"
- current readiness doc: v6, 2 FAIL rows (bot restores 11/11 districts; boss winnability note is PASS-with-caveat, not counted)
- engine gates measured in v6: 25/26 (report's own count — not 24/25 as an external plan assumed; using the real number going forward)
- premium docs present: docs/VISUAL_PASS.md only. Missing: GAMEFEEL_SPEC.md, SECURITY_THREAT_MODEL.md, EXPORT_HARDENING.md, SIZE_BUDGET.md, STORE_KIT.md, store/keyart/
- godot: ok (4.7.stable.official.5b4e0cb0f)
- rtk: not on PATH — using plain rg/grep with head limits instead
- gh: not authenticated (`gh auth status` fails); git push itself not yet tested this session — will verify on first push and report if it fails
- remote: origin = https://github.com/maxxxxx55555/igra.git

## Decisions taken autonomously
- Skipped CLAUDE.md hygiene commit: file already under the 150-line cap, no-op commits aren't made.
- Treating this as a genuinely large, multi-session build (security code, asset deletion, audio re-encode, screenshot capture, release tag) — proceeding one phase per turn rather than collapsing phases, so each destructive/high-risk step (P2 security, P3 deletions, P6 tag+push) lands as its own reviewable commit instead of one unreviewable batch.
