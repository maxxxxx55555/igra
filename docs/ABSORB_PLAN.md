# Absorb plan (Session 24, U0): the parallel work on origin

Written at `68e6c9d` (`main` = `origin/main`, the tag `v9.0.0-ultimate`) after `git fetch --prune`. `python tools/qa_sim/branch_absorb_sim.py --check docs/ABSORB_PLAN.md` holds it (a static gate of `tools/check.sh`):
every branch on origin has a row in section 3 with a disposition word, and a row for a branch that is gone says "deleted".

## 1. How it was read

- **Inventory.** `git branch -r`: 13 branches besides `main` when this plan was written (14 before Session 24 deleted one, section 3; Session 25 then deleted ten, so 3 remain, section 6). Each is compared with its merge base with `main`; every file it changes is **SAME** (same path, same blob in `main`), **MOVED** (the blob is at another
  path), **DIVERGED** (the path exists with other bytes), **MISSING** (absent from `main`) or **GONE** (the branch deletes it). The table of section 2 is the tool's own output.
- **Decision per artifact.** An artifact is *done* (in `main`, SAME or MOVED, or `main` holds a later or fuller version), *partial* or *missing*; the decision is *absorb* (a new file under `docs/**`, `store/**`,
  `tools/qa_sim/*_sim.py` or `.github/workflows/*`, with its source commit), *finish* (write the missing part as a new file of the pass) or *skip* with the reason. No binary is absorbed (the directive: zero new binaries).
  A file whose text is not English is not absorbed (`docs/TZ_DECISIONS.md` LANG-23: every line a pass writes is English). A document whose citations cite lines that no longer exist is not absorbed (it would fail
  `tools/af5_check.py`).
- **AutoClaw.** No branch, no ref and no commit of the repository names it (`git for-each-ref`; `git log --all -i --grep autoclaw` and `--author autoclaw` find nothing). Its only trace is a process on the build machine
  (`docs/LONG_SESSION_TEST.md`, the machine-shared note). 0 branches, 0 files.
- **Jules.** One branch (`jules/parallel-audit-...`, 2026-10-12). Session 23 compared it file by file with its own (`docs/CLEANUP_LEDGER.md` section 5); this pass re-measured it (section 5 below).

## 2. Inventory (the tool's output at `68e6c9d`)

| Branch | Commits ahead | SAME | MOVED | DIVERGED | MISSING | GONE |
|---|---|---|---|---|---|---|
| `origin/arena/019ffbd0-igra` | 56 | 2 | 1 | 50 | 11 | 13 |
| `origin/arena/01a07b1c-igra` | 9 | 0 | 0 | 39 | 2 | 4 |
| `origin/arena/01a09af1-igra` | 2 | 3 | 1 | 520 | 28 | 0 |
| `origin/arena/01a0ab24-igra` | 1 | 0 | 0 | 2 | 1 | 0 |
| `origin/arena/01a0c589-igra` | 2 | 0 | 0 | 10 | 3 | 0 |
| `origin/arena/01a0c619-igra` | 3 | 3 | 0 | 1 | 0 | 0 |
| `origin/arena/01a0c61a-igra` | 1 | 1 | 0 | 0 | 0 | 0 |
| `origin/arena/01a0c87e-igra` | 1 | 0 | 0 | 0 | 2 | 0 |
| `origin/arena/01a0f956-igra` | 14 | 4 | 1 | 101 | 5 | 0 |
| `origin/claude/keen-cori-0sc9uo` | 2 | 0 | 0 | 0 | 2 | 0 |
| `origin/claude/serene-sagan-wynb3r` | 8 | 4 | 1 | 25 | 1 | 0 |
| `origin/gh-pages` | 1 | 0 | 0 | 0 | 0 | 0 |
| `origin/jules/parallel-audit-1403790779115270347` | 3 | 0 | 0 | 7 | 4 | 0 |

## 3. Dispositions

Disposition words: **absorbed** (a file of it is in `main` now, section 4), **kept** (the branch stays; nothing of it is needed), **skipped** (its artifacts are not absorbed, with the reason), **deleted** (this pass
removed the branch, with the reason and the way back in `docs/CLEANUP_LEDGER.md` section 12).

| Branch | What it holds | State of its artifacts | Disposition |
|---|---|---|---|
| `origin/arena/019ffbd0-igra` | the first arena's autopilot tests and fixes, 56 commits of 2026-08-13 | 50 DIVERGED where `main` moved on, 13 GONE, 11 MISSING: three Russian setup and checklist documents (one says the game "never ran"), the old `tools/autopilot*` files and `tools/orphan_check.py`, which `tools/qa_sim/` and `tools/quarantine_audit.py` replaced, and two scripts `main` does not use | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: skipped: a real merge conflict (`docs/RUN_STATE.md`, the arena table of 2026-09-20), nothing in an allowed destination that is English and current |
| `origin/arena/01a07b1c-igra` | the UI wave: weapon HUD, no physical bullets, tutorial steps; 9 commits of 2026-09-07 and 08 | 39 DIVERGED (the weapon system in `main` is a later one), 2 MISSING: `docs/IDEA_CONFORMANCE.md` (a Russian audit of `IDEA.md`, baseline 2026-09-07) and `data/items/ammo.tres` (`main` keeps ammo in `ProgressTracker`) | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: skipped: conflicts on the 13 locale files and the weapon scripts; the audit is Russian and its baseline is gone |
| `origin/arena/01a09af1-igra` | the district-card texture merge; 2 merge commits of 2026-09-14, 552 files | 520 DIVERGED, 28 MISSING (`.import` sidecars of folders Session 23 removed, one script); its own history is a merge of two branches already in `main` | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: skipped: stale, several merge bases (`docs/IDEAL_GAP_REPORT.md`, `docs/RUN_STATE.md`) |
| `origin/arena/01a0ab24-igra` | game-feel spec, QA matrix and balance matrix; 1 commit of 2026-09-16 | `docs/BALANCE_MATRIX.md` MISSING; the other two DIVERGED (`main`'s `docs/QA_MATRIX.md` is a later, extended version) | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: skipped: the matrix is a snapshot of 2026-09-16 values; `docs/NGPLUS_TABLE.md` and `docs/DIFFICULTY_CURVE.md` are read from the code |
| `origin/arena/01a0c589-igra` | rendering diagnosis, red-team of the truth gates, i18n native-quality pass; 2 commits of 2026-09-21 | three documents MISSING (baseline `c1ebeec`), 10 locale and doc files DIVERGED | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: skipped: the magenta defect it diagnoses was closed (`docs/CORRECTION_LOG.md` row 1: the district LUTs imported as `Texture3D`, `bafb740`), the gates it asks for exist as tools, the i18n parity is held by `tools/qa_sim/i18n_placeholder_fuzz.py` |
| `origin/arena/01a0c619-igra` | TZ audit, break report, security patch spec; 3 commits | SAME 3, DIVERGED 1 (`docs/SECURITY_PATCH_SPEC.md`: 779 lines on both sides, `main` has later edits) | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: absorbed before this pass: three of its four files are blob-identical in `main`; not an ancestor, so it stays |
| `origin/arena/01a0c61a-igra` | the slop report; 1 commit | SAME 1 | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: absorbed before this pass: its one file is blob-identical in `main`; not an ancestor, so it stays |
| `origin/arena/01a0c87e-igra` | design decisions and voice fixes; 1 commit of 2026-09-22 | 2 MISSING: `docs/DESIGN_DECISIONS.md`, `docs/I18N_VOICE_FIXES.md` ("exact new strings, the locale owner applies") | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: skipped: written against baseline `6f4c841`, whose audit files it says are absent; `docs/TZ_DECISIONS.md` and the later i18n passes supersede it |
| `origin/arena/01a0f956-igra` | the art plates of Tier 1 (73 plates and 7 derived squares); 14 commits of 2026-09-28 to 2026-10-02 | 101 DIVERGED images, 5 MISSING: three `menu_hero_*` images, `tools/art_finish.py`, `docs/ASSET_PROMPT_PACK.md` | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: skipped: binaries (zero new binaries) and a grade script outside the allowed destinations; the prompt pack is absorbed from the other branch that carries it (section 4); kept for the owner's art review |
| `origin/claude/keen-cori-0sc9uo` | the music prompt packs; 2 commits of 2026-10-07 and 08 | 2 MISSING: `docs/MUSIC_PROMPTS_FULL.md` (English, 69 prompts, a superset of `docs/MUSIC_RECIPE.md`) and `docs/GEMINI_MUSIC_PROMPTS.txt` (the same 69 prompts as Russian phone text) | absorbed: the English list (section 4); the Russian copy is skipped by LANG-23 and stays on the branch |
| `origin/claude/serene-sagan-wynb3r` | the ZCode handoff branch: the rename to Last Streetlight, the image prompt pack, agent documents; 8 commits | 25 DIVERGED (the rename and the agent documents, where `main` has the later versions), 4 SAME, 1 MOVED, 1 MISSING: `docs/ASSET_PROMPT_PACK.md` | absorbed: the prompt pack (section 4); the rest skipped: `main` holds the later versions |
| `origin/gh-pages` | the hosted privacy policy page (`index.html`); 1 commit, no relation to `main` | not code; the page the store listing links to (`docs/PRIVACY_POLICY_FINAL.md`) | kept: it is the page the privacy-policy URL of the listing points at |
| `origin/oc/visual-w10` | another session of the owner (opencode): visual wave 10, a moon, materials, quarantine deletions and five frames; 3 commits of 2026-10-21, pushed beside the v10 pass | not merged; its unique hunk is duplicated by pv10 (KNOWN_ISSUES `origin/oc/visual-w10` disposition, X0) | deleted: owner-authorized in the v10.0.0-close prompt (C4); content dispositioned, nothing unique lost |
| `origin/jules/parallel-audit-1403790779115270347` | a parallel audit of 2026-10-12: 2 workflows, a glossary, 4 simulations, 4 documents | 7 DIVERGED at paths `main` has (section 5), 4 MISSING under `docs/jules/` | Deleted on 2026-10-16 (the owner's directive of Session 25; tip, bundle and restore command in `docs/CLEANUP_LOG.md`). Disposition before: skipped: ten of the eleven files have a counterpart in `main` that is fuller, generated from the code or a gate (section 5); the eleventh, `ACHIEVEMENT_TRIGGER_SPEC.md`, is a design proposal and not an absorb; kept for the owner's reading |
| `origin/arena/card-unique-rescue` | a district-card uniqueness pass; 1 commit of 2026-09-13 | its certificate says "Scene match: 22/22" while its commit changes no card blob (its 22 are those of its parent, which `main` held; `main` regenerated seven districts the next day, `1870389`, so 14 of the 22 differ from `HEAD` today; `docs/KNOWN_ISSUES.md`: "arena/card-unique-rescue delivered no card art") | deleted: rejected for a fabricated certificate, logged in `docs/CLEANUP_LEDGER.md` section 12.1, a thin bundle of its commit kept |
| `origin/qoder/premium-visual-recovery` | another agent's (Qoder) line for the visual recovery brief of 2026-10-30: 13 commits ahead of `9efeb89b` at its tip `352240aa` (skyline, facades, street tiles, lamps, UI scale and safe area, its planning documents and its frames) | its code was integrated up to its commit `44a374a1` (merge `0ef1d3c6`, fixes `b87c46be`); the three later commits `5556161e`, `20af0da1`, `352240aa` are not in `main` | absorbed up to `44a374a1`: skyline and facade shader, 2 m street tiles with curbs, urban props, lamp halos, `UiScale`, the HUD safe area, the terminal layout, the phone defaults; main's inventory, theme, workbench and map are kept (THEME1 and the unify probe hold their canon); its frames, planning documents and press kit are skipped. Kept, not taken: the three later commits, which darken the road and the props and add normal maps to a road shader that main replaced; the branch stays the other agent's to continue |

## 4. Absorbed (provenance)

| File | Source branch | Source commit | Kept or dropped | Note |
|---|---|---|---|---|
| `docs/MUSIC_PROMPTS_FULL.md` | `origin/claude/keen-cori-0sc9uo` | `22f3b8c` (2026-10-07) | kept, whole | the game's name in the title corrected (the owner's line, Session 23); the prompts feed `docs/GEMINI_HANDOFF.md` |
| `docs/ASSET_PROMPT_PACK.md` | `origin/claude/serene-sagan-wynb3r` | `7f5a6a1` (2026-10-01) | kept, whole | its counts are of 2026-10-01 and say so; the copy on `origin/arena/01a0f956-igra` adds a status section about that branch's own plates and is dropped |
| `docs/GEMINI_MUSIC_PROMPTS.txt` | `origin/claude/keen-cori-0sc9uo` | `fc34836` (2026-10-08) | dropped | Russian text (LANG-23); the same prompts are in the English list |
| `docs/ASSET_PROMPT_PACK.md` (arena copy) | `origin/arena/01a0f956-igra` | `832ac86` (2026-10-02) | dropped | a status section about plates `main` does not hold |

Both absorbed files pass `tools/af5_check.py` (0 findings) and `tools/qa_sim/doc_ctrl_check.py`; neither is audio or an image.

## 5. The Jules branch, file by file (re-measured at `68e6c9d`)

| Jules file (lines) | `main` counterpart (lines) | What decided it |
|---|---|---|
| `.github/workflows/pr-sims.yml` (34) | same path (62) | `main`'s is the fuller workflow (static gates, `actionlint`, the sims) |
| `.github/workflows/weekly-full.yml` (43) | same path (47) | the same shape; `main`'s adds the gates of Session 23 |
| `data/i18n_glossary.json` (416) | same path (1,029) | `main`'s holds the terms of all 13 locales read by the fuzz |
| `tools/qa_sim/achievements_sim.py` (115) | same path (176) | `main`'s reads the trigger table and the bridge (`docs/ACHIEVEMENT_TRIGGER_SPEC.md`) |
| `tools/qa_sim/daily_sim.py` (112) | same path (137) | `main`'s covers the day edge and the streak (`docs/DAILY_SIM.md`) |
| `tools/qa_sim/i18n_placeholder_fuzz.py` (135) | same path (149) | the same job, `main`'s is a gate |
| `tools/qa_sim/save_migration_sim.py` (184) | same path (116) | the Jules one re-implements the signature in Python and repeats the client's key literal; `main`'s runs the real `SaveSystem._read_validated` through a closeout check |
| `docs/jules/ACHIEVEMENT_TRIGGER_SPEC.md` (80) | `docs/ACHIEVEMENT_TRIGGER_SPEC.md` (39) | the longer one proposes 19 more achievements; nobody has verified them at HEAD (a design change, not an absorb) |
| `docs/jules/CROSS_AUDIT.md` (26) | `docs/CROSS_AUDIT.md` (52) | `main`'s is the fuller audit |
| `docs/jules/NGPLUS_TABLE.md` (46) | `docs/NGPLUS_TABLE.md` (59) | `main`'s is generated from the code (`tools/qa_sim/ngplus_table.py`) |
| `docs/jules/SAVE_MIGRATION_MATRIX.md` (56) | `docs/SAVE_MIGRATION_MATRIX.md` (31) | the longer one prints the client's HMAC key literal and cites lines of a file that moved; `main`'s is written by the sim from the closeout log |

Nothing of the Jules branch is absorbed; the branch was kept in Sessions 23 and 24 for the same reasons, now with the counts, and deleted in Session 25 (section 6).

## 6. What this plan did not do

- No file of an `arena/*` branch was absorbed: the useful ones are old snapshots that cite a past baseline (`c1ebeec`, `6f4c841`, 2026-09-07), and the allowed destinations exclude the images and the grade script.
- No branch was deleted for being "probably merged": the rule is an ancestor proof, and only the one branch documented as rejected for fabrication was taken (`docs/CLEANUP_LEDGER.md` section 12.1).
- The ten `arena/*` and `jules/*` branches were deleted on 2026-10-16 under the owner's directive of Session 25 (`docs/CLEANUP_LOG.md`: tips, a bundle that restores them); `gh-pages` and the two `claude/*` branches remain, and the table above is the record of what each of the ten held.

## 7. The missing union of the directive (U0.3), file by file

The directive's list of what the parallel work should have left, checked against the tree at `68e6c9d` plus this pass. Every path below was asserted to exist when this section was written; nothing in it is a new file of the
absorb, because Session 23 had already written each one from the code (the Jules and arena versions are the first drafts of section 5). Only the proofs audit was missing, and it is written.

| Item of the directive | Files | Gate or proof |
|---|---|---|
| Privacy policy final, English and Russian, the hosting recipe, the network-call audit | `docs/PRIVACY_POLICY_FINAL.md`, `docs/PRIVACY_AUDIT.md` | `tools/qa_sim/privacy_audit.py` (static gate, CI matrix) |
| IARC and data-safety answers with the grep justification | `store/IARC_ANSWERS.md`, `tools/qa_sim/store_answers.py` | `store_answers.py` (CI matrix) |
| Screenshot recipes, 8 and 2, with reachability proofs | `store/SCREENSHOT_RECIPES.md`, `tools/qa_sim/store_frames_check.py` | `store_frames_check.py` over `store/screenshots/recipes/` |
| Music briefs per lit-bed gap (no binaries) | `docs/MUSIC_BRIEF.md`, `tools/qa_sim/music_brief.py` | `music_brief.py --check` (static gate) |
| Listing audit, 13 locales, the vaporware check | `store/LISTING_AUDIT.md`, `tools/qa_sim/listing_audit.py` | `listing_audit.py` (static gate, CI matrix) |
| Proofs audit | `tools/qa_sim/proofs_audit_sim.py` | written in this pass; static gate |
| Secret sweep | `tools/qa_sim/secret_scan.py`, `docs/CLEANUP_LEDGER.md` | `secret_scan.py` (static gate); the ledger's section 8 is the sweep of the history |
| Achievements reachability sim and the trigger spec | `tools/qa_sim/achievements_sim.py`, `docs/ACHIEVEMENT_TRIGGER_SPEC.md` | `achievements_sim.py` (CI matrix) |
| Save-migration sim | `tools/qa_sim/save_migration_sim.py`, `docs/SAVE_MIGRATION_MATRIX.md` | `--static` in the CI matrix; the closeout check SAVEMIG runs the real reader |
| i18n placeholder fuzz and the glossary | `tools/qa_sim/i18n_placeholder_fuzz.py`, `data/i18n_glossary.json` | `i18n_placeholder_fuzz.py` (CI matrix) |
| Daily-coverage sim | `tools/qa_sim/daily_sim.py`, `docs/DAILY_SIM.md` | `daily_sim.py` (CI matrix) |
| New Game+ carry-over table from the code | `tools/qa_sim/ngplus_table.py`, `docs/NGPLUS_TABLE.md` | `ngplus_table.py` (CI matrix) |
| Cross-audit | `docs/CROSS_AUDIT.md` | a document, read by the verifier rounds of Session 23 |
| CI workflows | `.github/workflows/pr-sims.yml`, `.github/workflows/weekly-full.yml`, `.github/workflows/static.yml` | `actionlint` through `tools/lint_changed.py` (static gate) |

| `origin/pass/v10.0.0-ship` | the v10.0.0-ship programme: 66 commits over `3ca44bb` (the pass that this land pass finishes) | the base of `land/v10.0.0`; nothing is missing from it here | deleted: merged into `main` by PR #25; owner-authorized in the v10.0.0-close prompt (C4) |
| `origin/pass/v1.0.0-ship` | an earlier draft of the same programme: 28 commits, superseded by `pass/v10.0.0-ship` | superseded; its work is inside `pass/v10.0.0-ship` | deleted: superseded by `pass/v10.0.0-ship` which is merged; owner-authorized in the v10.0.0-close prompt (C4) |
| `origin/dsh/work` | empty branch created by another agent and never used; tip `3ca44bb` | no commit of its own, nothing to absorb | deleted: empty and unused (tip `3ca44bb`, an ancestor of `main`); owner-authorized in the v10.0.0-close prompt (C4) |
| `origin/close/v10.0.0` | the v10.0.0-close pass branch: the five battery rows closed (frames re-shot, cites fixed, proof regenerated, strays deleted) | the PR into protected `main` is the landing | kept: the close pass's branch until its PR merges; the pull requests #28 and #29 merged and the tip is an ancestor of `main`, so the branch is deleted once the owner runs the command of `docs/CLEANUP_LEDGER.md` section 13 |
| `origin/land/v10.0.0` | the landing branch of Session 30: `pass/v10.0.0-ship` plus the two engine-gate alignments and the land evidence | the pass itself; the PR into protected `main` is the landing | kept until the PR merges into `main`; then `main` names the same commit; the pull requests #22 to #25 merged, so the branch is deleted once the owner runs the command of `docs/CLEANUP_LEDGER.md` section 13 |
