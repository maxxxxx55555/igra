# Cleanup ledger (Session 23, K1)

Written before anything was deleted (K1.0), completed as each step landed. Every deletion is its own commit, `chore(cleanup): ...`, so each one is `git revert`-able; nothing leaves the history.

## 0. The baseline and the way back

| | |
|---|---|
| HEAD before the cleanup | `dfce976` on `main`, equal to `origin/main` |
| Backup tag | `cleanup-backup-dfce976`, annotated, **local only, never pushed**: `git show cleanup-backup-dfce976:<path>` restores any file the cleanup removed; `git checkout cleanup-backup-dfce976 -- <path>` puts it back |
| Tracked before | 4,305 files, 671,512,348 bytes (640.4 MB) |
| `.git` before | 885 MB on disk (the pack 774 MiB, 3,094 loose objects of 99.6 MiB) |
| Local worktrees before | 5, 2.1 GB (`.claude/worktrees/` three, and two beside the repository) |
| Remote branches before | 31 (17 merged into `main`, 14 not) |

## 1. The test of "dead" (K1.1)

A path is deleted only when **two independent greps over every tracked text file** find no use outside the path itself and its own sidecars, **and** the four planned-feature documents and the three
other canon documents do not name it as a thing to keep, **and** (for an asset) no `uid://` of its sidecars appears elsewhere. Pattern A: the repository path, with and without `res://`.
Pattern B: the bare name. The scan covers `.gd .tscn .tres .import .cfg .py .md .json .sh .yml .gdshader .godot .txt .tsv .ps1 .csv .uid`, leaving out the raw evidence (`docs/artifacts/`, `docs/stills/`), the
caches and the worktrees. A mention in a document is not a use, but a document that **cites a file as evidence** keeps it (a claim rests on it). The `_QUARANTINE` entries are judged by the existing
`tools/quarantine_audit.py`, which is the same two greps with the review documents read, and only the entries it calls AUTO-DELETABLE both in `docs/QUARANTINE_AUDIT.md` and in a fresh run at HEAD go.
When in doubt a path stays, and is listed in section 3.

## 2. Deleted

| # | Path | Files | Bytes | Proof | Commit |
|---|---|---|---|---|---|
| 1 | `assets/audio/_pre_norm/` | 280 | 168,585,261 | pattern A hits only in 12 documents, `AGENTS.md` and the export exclusion of `export_presets.cfg`, pattern B in 7 documents, no `uid` hit; the shipped bundle never contained it (the exclusion filter); every blob stays in the history and in the backup tag, so the originals of the loudness pass are one `git show` away; `docs/KNOWN_ISSUES.md` (section "Owner-only cleanup", with the command) names it for deletion | pending |
| 2 | `assets/_orphaned/` | 141 | 3,167,515 | the same two greps: documents and the export exclusion only; verified dead twice before (`docs/KNOWN_ISSUES.md`, `docs/SIZE_BUDGET.md`) | pending |
| 3 | `assets/textures/items_legacy/` | 52 | 145,878 | documents and the export exclusion only (`docs/REPORT_ASSETS.md`, `docs/REPORT_BUG_HUNT.md`); the live icons are `assets/textures/items/`, and 13 of the 26 images (the other 26 files are their sidecars) are byte-identical to them | pending |
| 4 | `assets/grading/` (and its `.gitignore` line) | 2 | 1,427 | a stray top-level duplicate of `assets/textures/grading/night_grade.png` (`docs/SESSION_REPORT_SHIP.md`); the only code mention is the texture-import tool's list of folders to walk | pending |
| 5 | ten files of `_QUARANTINE/`: six fonts (`ChakraPetch-Bold`, `Rajdhani-SemiBold`, `SairaCondensed-Bold` and `-Regular`, `bebas_neue_bold`, `roboto_condensed`) and four effect scenes (`blood_particles`, `footstep_dust`, `hit_spark`, `muzzle_flash`) | 10 | 996,797 | `tools/quarantine_audit.py`: no A or B hit, no dynamic loader, the review documents record each as a duplicate or unlinked (`docs/ERROR_LOG_FINAL.md:53`, `:56`, `:74`); AUTO-DELETABLE in the committed audit and in a run at HEAD | pending |
| 6 | scratch: `_topsort.py`, `docs/runtime_log3.txt` (a copy of `runtime_log.txt`), the three empty `docs/runtime_log*.txt.err`, the empty `docs/_final_violations.txt`, `docs/p2_consistency_probe.txt`, `docs/regress_hud_probe.txt`, `docs/regress_map_probe.txt`, `docs/folder_screenshot.png` | 10 | 198,288 | no mention in any tracked text file, nor in the raw evidence folders | pending |

## 3. Kept, with the reason

| Path | Why it stays |
|---|---|
| `content/cards/twins/` (7 files, 3.3 MB, identical to `assets/textures/cards/`) | read by `scripts/audit_card_clusters.py` and `scripts/make_locked_cards.py`, named by `docs/CARD_ART_BRIEF.md` as the 512 px twins of the card masters |
| `assets/textures/grading/` (`lut_night.png`, `night_grade.png`, identical) | unused by code today, but the grading folder of the LUT pass; owner decision |
| the 36 UNCERTAIN and 24 KEEP-PLANNED rows of `_QUARANTINE/` | the audit's own rule: owner eyes (`docs/QUARANTINE_AUDIT.md`) |
| `docs/shots/` (30.5 MB), `docs/reference/`, the dated `docs/*_probe.txt`, `docs/runtime_log.txt`, `docs/runtime_log2.txt`, `docs/stills/gui/results.txt` | cited as evidence by session reports, the production bible, the plans or the style canon; deleting one would orphan a claim |
| `assets/store/background_1920x1080.png`, `loading_screen_1920x1080.png` and `press/press_cover_1920x1080.png` (identical), `assets/store/v2/itch/*` against `assets/store/v2/shots/*` | each is read by path from a store document or the store tooling; repointing for 1 to 2 MB is a risk without a gain |
| root `findings.md`, `progress.md`, `task_plan.md`, `knowledge.md`, `IDEA.md`, `PROMPT.md`, `ARENA_NEXT_PROMPT.md`, `missing_keys.json`, `RELEASE_NOTES.md`, `RELEASE_CHECKLIST.md` | working notes and the first documents of the project, named by `PLAN.md`, the skills or the tools; a few kilobytes each |
| `store/press-kit.md` | carries its own "Superseded" banner pointing at the generated `store/PRESS_KIT.md`, and is cited by 13 files |
| `docs/jules/` content of `origin/jules/parallel-audit-1403790779115270347` | see section 5 |

## 4. Case collision and near duplicates (K1.4)

The index holds `docs/release_checklist.md` (lowercase) while the Windows disk showed `docs/RELEASE_CHECKLIST.md`: a case difference that a case-sensitive checkout (Linux CI, a phone's file manager)
would turn into a missing file for the three documents that cite the uppercase name. History: the arena merge added an uppercase twin on 2026-09-20 (`a365088`) and `91230eb` resolved it by keeping the
lowercase file, which is the one every later commit and 17 citations use. Resolution: the disk name is made equal to the index name by a two-step `git mv`, and the three uppercase citations
(`docs/IDEAL_GAP_REPORT.md`, `docs/KNOWN_ISSUES.md`, `docs/OWNER_HANDOFF.md`) are re-pointed to the lowercase path. There are no case-only collisions inside the index (0 groups). The root
`RELEASE_CHECKLIST.md` (the human-only steps of 2026-09-12) and `docs/release_checklist.md` (the steps of the shipped build) are different documents.

## 5. Branches and worktrees (K1.5)

Pending: see the commit that fills this section.

## 6. The rest of K1

K1.6 `.gitignore`, K1.7 the secret sweep, K1.8 the history rewrite (owner approval needed) and K1.9 the totals are filled in by the commits that do them.
