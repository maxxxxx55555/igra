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
| Remote branches before | 32 (`main`, 17 merged into `main`, 14 not) |

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
| 1 | `assets/audio/_pre_norm/` | 280 | 168,585,261 | pattern A hits only in 12 documents, `AGENTS.md` and the export exclusion of `export_presets.cfg`, pattern B in 7 documents, no `uid` hit; the shipped bundle never contained it (the exclusion filter); every blob stays in the history and in the backup tag, so the originals of the loudness pass are one `git show` away; `docs/KNOWN_ISSUES.md` (section "Owner-only cleanup", with the command) names it for deletion | `7d00f6a` |
| 2 | `assets/_orphaned/` | 141 | 3,167,515 | the same two greps: documents and the export exclusion only; verified dead twice before (`docs/KNOWN_ISSUES.md`, `docs/SIZE_BUDGET.md`) | `040d6fb` |
| 3 | `assets/textures/items_legacy/` | 52 | 145,878 | documents and the export exclusion only (`docs/REPORT_ASSETS.md`, `docs/REPORT_BUG_HUNT.md`); the live icons are `assets/textures/items/`, and 13 of the 26 images (the other 26 files are their sidecars) are byte-identical to them | `f25ad69` |
| 4 | `assets/grading/` (and its `.gitignore` line) | 2 | 1,427 | a stray top-level duplicate of `assets/textures/grading/night_grade.png` (`docs/SESSION_REPORT_SHIP.md`); the only code mention is the texture-import tool's list of folders to walk | `6a905e2` |
| 5 | ten files of `_QUARANTINE/`: six fonts (`ChakraPetch-Bold`, `Rajdhani-SemiBold`, `SairaCondensed-Bold` and `-Regular`, `bebas_neue_bold`, `roboto_condensed`) and four effect scenes (`blood_particles`, `footstep_dust`, `hit_spark`, `muzzle_flash`) | 10 | 996,797 | `tools/quarantine_audit.py`: no A or B hit, no dynamic loader, the review documents record each as a duplicate or unlinked (`docs/ERROR_LOG_FINAL.md:53`, `:56`, `:74`); AUTO-DELETABLE in the committed audit and in a run at HEAD | `2224d32` |
| 6 | scratch: `_topsort.py`, `docs/runtime_log3.txt` (a copy of `runtime_log.txt`), the three empty `docs/runtime_log*.txt.err`, the empty `docs/_final_violations.txt`, `docs/p2_consistency_probe.txt`, `docs/regress_hud_probe.txt`, `docs/regress_map_probe.txt`, `docs/folder_screenshot.png` | 10 | 198,288 | no mention in any tracked text file, nor in the raw evidence folders | `1984577` |

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

**Worktrees (5, removed with `git worktree remove`, each clean, 0 commits ahead of `main`, an ancestor of `main` by `git merge-base --is-ancestor`):**
`.claude/worktrees/agent-a2d98b0eb4e6daa56` (`worktree-agent-a2d98b0eb4e6daa56`, `60dac76`), `.claude/worktrees/agent-a9d93688011f12bdb` (`9f8b032`),
`.claude/worktrees/agent-ac5abdf50f70def2b` (`a82814d`) and, beside the repository, `opencode-assets` (`opencode/mesh-opt`, `6994411`) and `qwen-i18n` (`qwen/i18n-content`, `987faf6`): 2.1 GB freed
(`.claude/` went from 1.7 GB to 0.9 MB).

**Local branches deleted (7, `git branch -d`, which refuses an unmerged branch):** `cl/a11y-i18n` (`86228c6`), `oc/visual-w10` (`86228c6`), `opencode/mesh-opt` (`6994411`), `qwen/i18n-content`
(`987faf6`), `worktree-agent-a2d98b0eb4e6daa56` (`60dac76`), `worktree-agent-a9d93688011f12bdb` (`9f8b032`), `worktree-agent-ac5abdf50f70def2b` (`a82814d`). Way back: `git branch <name> <hash>`.

**Remote branches deleted (17, `git push origin --delete`, each re-proved an ancestor of `origin/main` in the same command):**

| Branch | Tip |
|---|---|
| `arena/01a08c53-igra`, `arena/01a0902d-igra`, `arena/01a09030-igra`, `arena/01a09aec-igra` | `540c57a`, `f724e93`, `b3c1651`, `1870389` |
| `arena/01a0a4c3-igra`, `arena/01a0ab23-igra`, `arena/01a0b08a-igra`, `arena/01a0bdfa-igra` | `9c2263f`, `77d11ac`, `75d64c1`, `a365088` |
| `arena/01a0bfe8-igra`, `arena/01a0c324-igra`, `arena/01a0e817-igra`, `arena/9ff86ab5-igra` | `2f48bf1`, `6ae3af7`, `596bb03`, `f6ceafa` |
| `arena/texture-optimization`, `backup-3d`, `cloud/audit-ce782f8`, `opencode/mesh-opt`, `qwen/i18n-content` | `b563f11`, `5f0c803`, `c27d270`, `6994411`, `987faf6` |

Way back for any of them: `git push origin <tip>:refs/heads/<name>` (every tip is reachable from `main`, so the object is there).

**Kept (14 remote branches not merged into `main`), reviewable:**

| Branch | Commits ahead | What it holds | Why it stays |
|---|---|---|---|
| `arena/019ffbd0-igra` | 56 | the first arena's autopilot tests and fixes (August) | unmerged work; owner review |
| `arena/01a07b1c-igra` | 9 | the UI wave notes | unmerged |
| `arena/01a09af1-igra` | 2 | the district card textures merge | unmerged |
| `arena/01a0ab24-igra`, `arena/01a0c589-igra`, `arena/01a0c619-igra`, `arena/01a0c61a-igra`, `arena/01a0c87e-igra` | 1, 2, 3, 1, 1 | QA, rendering, compliance, slop and design documents | unmerged |
| `arena/01a0f956-igra` | 14 | the art plates of Tier 1 (73 plates) | unmerged; large binaries |
| `arena/card-unique-rescue` | 1 | the district card uniqueness pass | named in the directive: kept |
| `claude/keen-cori-0sc9uo`, `claude/serene-sagan-wynb3r` | 2, 8 | a music prompt pack and agent notes | unmerged |
| `gh-pages` (also the local branch) | 1 | the hosted privacy policy page | it is the page the store links to |
| `jules/parallel-audit-1403790779115270347` | 3 | the parallel audit of 2026-10-12: two workflows, a glossary, four documents, four simulations | compared file by file with this pass's own (S2): the pass's are the engine-driven or longer ones (the save sim re-implements the signature in Python and repeats the client's key literal; this pass runs the real `SaveSystem._read_validated`), the workflows are the 34 and 43 line first drafts of `pr-sims` and `weekly-full`, and the 19-achievement expansion proposal is a spec nobody has verified at HEAD; **nothing was absorbed, so the branch is not deleted** (the rule: delete only after the artifacts are provably in `main`); it is the owner's to read or drop |

A fetch with `--prune` before the deletion showed the Jules branch, which the remote-tracking list of the start of the pass did not have: it was pushed on 2026-10-12.

## 6. The rest of K1

## 7. `.gitignore` (K1.6)

`tools/qa_sim/gitignore_check.py` (a static gate of `tools/check.sh`, with a demo) asks `git check-ignore` about 27 generated, exported or secret paths that must never be tracked (the import cache, the QA logs,
`.signing/`, the keystore and key suffixes, `build/`, `exports/`, the editor and patch scratch) and 8 that must be (the committed texture sidecars, the attached proof logs, the evidence), and fails on a tracked file that a rule
ignores. Its first run found five paths with no rule (`*.patch`, `*.orig`, `*.rej`, `*.tmp`, `*.swp`) and three tracked files behind a rule: `scripts/enemies/status_effects.gd.uid` (an engine sidecar committed by accident in `193f637`,
referenced by no scene; untracked with `git rm --cached`, the file stays on disk) and two pieces of cited evidence (`docs/artifacts/ui-audio/verify.log`, `docs/artifacts/rc16/s21_b5_fix.patch`, which `docs/LEDGER_UIAUDIO.md` and
`docs/CORRECTION_LOG.md` cite; kept, with a negation rule each). The rules added: `*.patch *.orig *.rej *.tmp *.swp build/ exports/ _tmp_*`. 0 faults after.

## 8. The secret sweep (K1.7)

`tools/qa_sim/secret_scan.py` (a static gate, with a demo) reads every tracked text file (1,808) for the shapes of a Google, OpenAI-style, Anthropic, GitHub, Slack and AWS key, a private key block, a JWT and an assigned secret, and prints
the file and line, never the value. At HEAD before this pass it found **two real credentials and two false positives**:

| File:line | Kind | Verdict |
|---|---|---|
| `opencode.json:9` | an OpenAI-style key (`sk-`, 35 characters) in `apiKey` of the provider `omniroute`, whose `baseURL` is `http://localhost:20128/v1` | a key of the owner's **local** OmniRoute router, committed in `5553c2e` (2026-08-07). Replaced in the tree by `{env:OMNIROUTE_API_KEY}` (OmniRoute is disabled by the owner's rescue directive). It stays in the history. **ROTATE** (below) |
| `tools/make_keystore.ps1:10` | a PowerShell assignment `$pass = "..."` of 8 characters (the first scan did not know the shape; the scan does now) | the password of a **debug** keystore (alias `tlsdebug`, a local test key, never the release key), a literal since `7066810` (2026-08-08). Replaced by `$env:TLS_DEBUG_KEYSTORE_PASS`, else a fresh value that the script prints. It stays in the history. **ROTATE** (below) |
| `data/integrity_manifest.json:30` | a 64-hex literal near the word "secrets" | false positive: the SHA-256 of `content/secrets.json` |
| `tools/qa_sim/release_export_check.py:69` | `sk-` and 24 characters | false positive: the fake key of the scanner's own fixture, introduced in `717e132` |

Both ways: `scan_text` on `git show HEAD:opencode.json` returns the two hits of line 9, on the file of this tree none. History, by `git log --all -G` over every pattern: Google, GitHub, Slack, AWS, Anthropic keys and private key blocks
0 commits each; `sk-` shapes 2 commits (the two above); the words storepass/keypass 3 commits: `5553c2e` and `6e06710` carry the **public default** `android` of a debug keystore script (not a secret), `7066810` the 8-character literal of the table above. The signing key is not
in the repository: `export_presets.cfg` has all six keystore and password fields empty (the Gradle build reads `.signing/release.env`, which is untracked and ignored; its contents were never opened by this pass), and `*.keystore *.jks *.p12
release.env .signing/` are ignored. The save HMAC key of `scripts/core/save_system.gd:21` is a client-side constant by design (`docs/SECURITY_THREAT_MODEL.md`): it ships in every bundle and rotating it would orphan every save.

**Rotate list (the owner's, none can be done from here):**
1. The OmniRoute local API key that was in `opencode.json` (`sk-` + 31 characters): generate a new one in the OmniRoute dashboard (`http://localhost:20128`), set it as `OMNIROUTE_API_KEY` where OpenCode runs, revoke the old one.
2. The debug keystore password that `tools/make_keystore.ps1` held in git (8 characters, alias `tlsdebug`): if the debug keystore made with it is on a machine, generate a new one with the script (it now draws a fresh password) and set it in the Godot export dialog; no release is signed with it.
3. The AppLovin MAX SDK key is still not set (`docs/store/HUMAN_CHECKLIST.md`): when it is, it goes in the owner's environment, never in a tracked file; `secret_scan` will fail the commit that does.
4. The release keystore and its passwords stay in `.signing/` outside git; keep an offline copy: a lost keystore cannot be recovered from this repository.

## 9. The history rewrite (K1.8): not done, an owner row

The directive allows a rewrite with a force-push **only with the owner's approval logged in `docs/CORRECTION_LOG.md`**; none is logged, and a force-push cannot be undone for a clone that pulled, so it is not done.
Measured by `git rev-list --objects --all` and `git cat-file --batch-check` (868 MB of blobs, compressed): 193 blobs are over 1 MB (505 MB), **114 of them are in no commit of the tip** (254 MB): the loudness originals
(`assets/audio/_pre_norm`, 74.8 MB), two old music `.wav` files (`school.wav`, `hospital.wav`, 77 MB), old screen and loading art (29.5 MB), earlier endings art (9.2 MB), raw frames (17 MB) and trailer stills. Removing exactly
those would take the history from 868 MB to about 614 MB; **the directive's 500 MB needs 114 MB more**, and the rest is the tip's own large files (110.7 MB of evidence frames in `docs/stills`, 58 MB of audio, 26 MB of
trailer, 23 MB of card art, 19 MB of shots) that a rewrite may not take. **Owner row K-1, executable** (after saying yes in `docs/CORRECTION_LOG.md`, with every other clone and the GitHub forks told to re-clone):

```bash
git clone --mirror . ../tls-history-backup.git                     # a full copy first
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk '$1=="blob" && $3>1048576 {print $2}' | sort -u > big.txt
git ls-tree -r HEAD | awk '{print $3}' | sort -u > keep.txt
comm -23 big.txt keep.txt > strip.txt                                # large and not in the tip: 114 blobs
git filter-repo --strip-blobs-with-ids strip.txt                     # NOT --strip-blobs-bigger-than: that would take the tip's own files too
git remote add origin https://github.com/maxxxxx55555/igra.git && git push --force-with-lease origin main && git push --force --tags origin
```

The same rewrite takes the `opencode.json` key out of the history if `git filter-repo --replace-text` is added with the old value (not written here).

## 10. Totals (K1.9)

| | Before | After |
|---|---|---|
| Tracked files | 4,305 | 3,810 (495 deleted, 1 added: the ledger; `status_effects.gd.uid` untracked) |
| Tracked bytes | 671,512,348 (640.4 MB) | 498,423,643 (475.3 MB): **173,088,705 bytes (165.1 MB) removed** |
| Directories removed | 0 | 4 (`assets/audio/_pre_norm`, `assets/_orphaned`, `assets/textures/items_legacy`, `assets/grading`) |
| Files removed | 0 | 495 (the four directories 475, ten quarantined, ten scratch) |
| Local worktrees | 5 (2.1 GB) | 0 |
| Local branches | 9 | 2 (`main`, `gh-pages`) |
| Remote branches | 32 (`main`, 17 merged, 14 not) | 15 (`main` and 14 unmerged, section 5) |
| `.git` on disk | 885 MB | 883 MB (the history is untouched, section 9) |
| The shipped `pck` and bundle | - | unchanged by this cleanup: every removed path was on the export exclusion list; the bundle is rebuilt at the ship step and its size recorded in `docs/RELEASE_ARTIFACTS.md` |

## 11. After the cleanup (K1.10)

The static battery, `flow_check` and `scene_node_check` read the same after as before (the run is in `docs/RUN_STATE.md`, S23-K1); the engine side (the compile gate, the closeout and the boot check) is in the battery of the
verification step, run on the tree that ships. A red check there is a path to restore from the backup tag the same turn, and a row here.

## 12. Session 24 (the v8.1.0-premium pass, C1): what was left after Session 23

Baseline `68e6c9d` (`main` = `origin/main`, the tag `v9.0.0-ultimate`). The pass found the directive's purge already done by Session 23 in all but five places; this section is those five. The rules of section 1 held
(two independent greps, the planning documents read, the uid of every sidecar, batches of at most 50, the static gates after each); the proofs are in `docs/artifacts/rc16/proofs/s24_*.out`.

### 12.1 Branches

`git branch -r --merged origin/main` lists nothing: no remote branch is an ancestor of `main`, so the rule "delete what is merged" deletes nothing. `autoclaw/*`: no such branch was ever pushed (`git for-each-ref`, and `git log --all`
finds no commit that names it); `docs/ABSORB_PLAN.md` has every branch that is on origin, with its disposition, and `tools/qa_sim/branch_absorb_sim.py --check` holds it.

| Branch | Tip | Why it goes | The way back |
|---|---|---|---|
| `arena/card-unique-rescue` | `b1d7830` | **rejected for a fabricated certificate**: its `docs/CERT_ARTFINAL.md` claims four regenerated cards and "Scene match: 22/22" while its commit changes no card blob (its 22 are those of its parent, which `main` held; `main` regenerated seven districts the next day, `1870389`, so 14 of the 22 differ from `HEAD` today), its contact sheet replaces the real 1024 x 1536 one with a thumbnail sheet, and its `scripts/regen_cards.py` hardcodes `/home/user/igra` (`docs/KNOWN_ISSUES.md`, "arena/card-unique-rescue delivered no card art"; `docs/HANDOFF.md`; `PLAN.md`; `docs/CARD_ART_BRIEF.md` section 1: "rejected for shipping zero card changes"). Not an ancestor of `main` (`git merge-base --is-ancestor` exits 1). The card art it was meant to fix was produced by the pipeline of `docs/CARD_ART_BRIEF.md`; 11 of 11 districts have a unique card there. | a thin bundle of the one commit, `..\_BACKUPS\2026-10-15_18-55\arena-card-unique-rescue-thin.bundle` (499,340 bytes, sha256 `45ced23bf3542d25826316c68d1f01863247b2747f06f14516137b80c24182b4`, requires `631e3a5`, `git bundle verify` okay); `git fetch <bundle> refs/remotes/origin/arena/card-unique-rescue:refs/heads/arena/card-unique-rescue` restores it |

The deletion of `arena/card-unique-rescue` is the one the owner's directive of this pass names (C1: that branch, and any rejected for fabrication, go only after the reason is logged, and the reason is the row above). The other 13 branches stay (section 5 of this ledger and `docs/ABSORB_PLAN.md`): not merged, and none is documented as rejected for fabrication. Two of them hold nothing `main` lacks (`arena/01a0c61a-igra`: its one file is blob-identical; `arena/01a0c619-igra`: three of its four files are, the
fourth differs); they are not ancestors, so the rule does not take them, and `git push origin --delete` is the owner's if the list should be shorter.
### 12.2 Files: three batches, each its own commit

The candidates were the manifests read strictly: the AUTO-DELETABLE rows of `docs/QUARANTINE_AUDIT.md` (all ten went in Session 23), of `docs/SURFACES_UI_NARROWING.md` (none: its surfaces and ui rows read 0 AUTO-DELETABLE) and the
"confirmed dead" list of `docs/SIZE_BUDGET.md` E2 to E4 (`items_legacy` went in Session 23; `wav_src`, the legacy achievement icons and the legacy weapon icons were left), plus a fresh run of `tools/quarantine_audit.py`, whose
inventory now holds the quarantined scripts (16 scripts AUTO-DELETABLE on the tracked tree of `68e6c9d`, rebuilt from `git archive` by `docs/artifacts/rc16/proofs/s24_audit_pair.out`; the working directory also held ignored `.uid` sidecars, which the editor regenerates and git does not have). Three checks per candidate, run by scripts kept in the proofs: two independent greps over every tracked text file (`docs/artifacts/rc16/proofs/s24_dead_proof_c1.out`: the path
with and without `res://`, and the whole file name with word boundaries, since `local_leaderboard.gd` is not `leaderboard.gd`), the planning and canon documents read for the name and the stem (`docs/artifacts/rc16/proofs/s24_planned_xcheck_c1.out`:
VISUAL_PASS, STORE_KIT, CARD_ART_BRIEF, MUSIC_BRIEF, MUSIC_SPEC, GAMEFEEL_SPEC, PRODUCTION_BIBLE, PLAN and every GDD), and the uid of each sidecar and the live replacement (`docs/artifacts/rc16/proofs/s24_uid_replace_c1.out`).
The static gates, `flow_check` and `scene_node_check` ran after each batch.

| # | Path | Files | Bytes (git blobs) | Proof | Commit |
|---|---|---|---|---|---|
| 1 | `_QUARANTINE/scripts/`: `audio/proc_audio.gd`, `audio_atmosphere.gd`, `components/attack_component_3d.gd`, `core/progression_system.gd`, `effects/footstep_dust.gd`, `effects/hit_spark.gd`, `environment/world_env.gd`, `system/particle_manager.gd`, `systems/leaderboard.gd`, `ui/controls.gd`, `ui/ui_theme.gd`, `visual/moon_disc.gd`, `world/ftue_generator_3d.gd`, and the 13 ignored `.uid` sidecars beside them | 13 tracked, 13 untracked | 24,454 | two greps: 0 code and 0 tool hits for each; the planning documents name none of the 13 as a thing to build or keep (the stems `controls`, `leaderboard` and `world_env` match prose or another file: `local_leaderboard.gd`, `world_env.tscn`, `world_env_setup.gd`); no uid is used elsewhere | `8ec7da4` |
| 2 | `assets/audio/ambience/wav_src/action_sting_loop.wav`, `threat_high_loop.wav`, `threat_low_loop.wav` (and three ignored `.import`) | 3 tracked, 3 untracked | 10,231,332 | `docs/AUDIO_CONVERT.md` and `docs/REPORT_ASSETS.md` call them archived masters ("never import"); the `.ogg` of each is in `assets/audio/ambience/`; on the export exclusion list; no code, scene or uid names them | `8338ad7` |
| 3 | `assets/textures/icons/ach_*_96.png` (12) and `assets/textures/icons/weapons/*_128.png` (9), with their 21 sidecars | 42 | 39,477 | superseded by `assets/textures/icons_v2/ach_medal_v2_*` (read by `scripts/ui/achievements_ui.gd`) and `assets/textures/renders_v2/weapons/*_render_256.png` (read by `scripts/ui/weapon_compare_ui.gd`); on the export exclusion list; `docs/SIZE_BUDGET.md` E2 to E4 | `663633d` |

Bytes are the sizes of the git blobs (24,454 + 10,231,332 + 39,477 = 10,295,263). The backup folder holds 74 files: these 58 and 16 ignored sidecars (13 `.uid`, 3 `.import`); the working copies on disk add the sidecars and CRLF line ends and sum to 25,438, 10,232,939 and 39,477 bytes.

### 12.3 Kept, with the reason

| Path | Why it stays |
|---|---|
| `_QUARANTINE/scripts/player/death_sequence.gd` | `docs/GAMEFEEL_SPEC.md:14` names `scripts/player/death_sequence.gd` as the implementation of the death beat (the beat itself now lives in `scripts/systems/wow_director.gd`); the planning document still points at it |
| `_QUARANTINE/scripts/ui/onboarding.gd` | `docs/GDD.md:810` lists it in the conformance table as an existing file; the live screen is `scripts/ui/onboarding_overlay.gd` |
| `_QUARANTINE/scripts/world/city_decorator.gd` | `docs/VISUAL_PASS.md:199` plans contact shadows for "street_props / city_decorator" |
| `_QUARANTINE/scripts/world/ftue_generator.gd` | the audit lists it AUTO-DELETABLE at `HEAD` and did not at `68e6c9d` (a result of the purge: `docs/artifacts/rc16/proofs/s24_audit_pair.out`); the two greps and the planning documents were not run for it, so it is the next batch's candidate and is not taken here |
| `assets/audio/ambience/wav_src/ambient_dark_loop.wav` and `ambient_lit_loop.wav` (10.6 MB each) | their `.ogg` was retired in `39b2254` (the 22 per-district beds replaced them: `docs/AUDIO_MIX_AUDIT.md`), so these two masters are the only copies in the tree, and `store/trailer.md:32` still plans both beds for the trailer |
| the 17 UNCERTAIN, 1 KEEP-PLANNED and 10 KEEP-LIVE files of the quarantine root (16, 1 and 10 at `HEAD`: `docs/artifacts/rc16/proofs/s24_audit_pair.out`) | the audit's own rule: owner eyes (section 3 above) |
| the 25 sha256 duplicate groups (18.7 MB: `docs/stills/final` against `docs/stills/ultimate`, `docs/shots`, `content/cards/twins`, `assets/store/v2/itch`, three store covers, two LUTs; `docs/artifacts/rc16/proofs/s24_purge_probe.out`) | not examined file by file: evidence frames and shots are cited by path from reports (Session 23's rule keeps a file a document cites as evidence), the card twins are read by two scripts, the store images by path from store documents and tools, and the two LUTs by name from code; a deletion needs each citation read, which this pass did not do |

### 12.4 QA logs and the ignore rule

`.qa_logs/` (ignored) held 1,769 files, 401 MB when the purge was planned (the first run of the probe; its log was overwritten by the run after the deletion, which is the committed `docs/artifacts/rc16/proofs/s24_purge_probe.out`: 0 files older, 608 newer, 177,556,501 bytes). The 1,178 older than the tag date of `v8.0.0-shipping` (2026-10-12), 224,043,661 bytes, were archived with `tarfile` to
`..\_BACKUPS\2026-10-15_19-36\qa_logs_before_2026-10-12.tar.gz` (154,807,929 bytes, read back and counted: 1,178 members) and then deleted; 17 empty directories went with them; 608 files, 177.6 MB, are newer and stay (the count of that probe).
`.gitignore` had every pattern of the directive's list but `*.autosave.*`; it has it now, with `*.autosave`, and `tools/qa_sim/gitignore_check.py` holds a path of each (29 must-ignore paths, 8 must-track, 0 faults).

### 12.5 The confession (AF7): batches pushed with a red gate

The batches of 12.2 ran the static gates **before** their commit, and the frame gate (F4) reads the committed `HEAD`, so batch 1's commit left it green (0 runtime paths differ from `0752c9b`), batch 2's made it red (3: the wavs), batch 3's run saw those 3 and its commit made 45 (`af3_frame_check`: runtime paths that differ between
`0752c9b` and `HEAD`, first `assets/audio/ambience/wav_src/action_sting_loop.wav`). The batch script committed on a clean tree, not on a green run, and the three commits (`8ec7da4`, `8338ad7`, `663633d`) went up in one push (19:27 on 2026-10-15), red. The cause was in the gate, not in
the batches: `tools/qa_sim/af3_frame_check.py` counted every path under `assets/` as runtime, but all 45 files are on the Android preset's `exclude_filter`, so none was ever in the bundle and no frame can show it. The fix is the
gate's own definition ("everything the game ships"): `is_runtime` now returns False for a path the first preset's `exclude_filter` matches (commit `7c9440f`; the demo asserts an excluded path is not runtime and a shipped one is;
`af3 frames=8 fail=0`, and no runtime path differs from `0752c9b` at `HEAD`). It is a gate input and is logged as such in `docs/CORRECTION_LOG.md`. The rule that stands for the rest of the pass: commit, then run the gates on the
commit, and revert the batch the same turn on red.

### 12.6 Totals of this pass

| | Before (`68e6c9d`) | After |
|---|---|---|
| Tracked files | 4,105 | 4,071 at `aaf2e87` (58 removed, 4,047, and 24 documents, tools and proofs added; 4,055 at `663633d`) |
| Tracked bytes removed | - | 10,295,263 (9.8 MB) |
| Untracked files removed | - | 1,194: 16 ignored sidecars of the batches and the 1,178 QA logs (224.0 MB, archived) |
| Working directory freed | - | about 234 MB (9.8 MB tracked, 224.0 MB logs); the archive of the logs, 154.8 MB, sits in `..\_BACKUPS\` |
| Remote branches | 14 besides `main` | 13 (`arena/card-unique-rescue` deleted, 12.1) |
| Local branches, worktrees, stashes | 2 (`main`, `gh-pages`), 1, 0 | the same |
| `.git` on disk | not recorded before the pass | 1,028,361,267 bytes (980.7 MiB) at `aaf2e87`; the history is not rewritten (owner row K-1) |
| The shipped bundle | `build/tls.aab`, 136,653,029 bytes | unchanged by construction: every removed path was on the export exclusion list or outside the project's scan roots; the runtime paths differ from the bundle's commit by none |
| Backups | - | tag `pre-purge-68e6c9d` (local, never pushed); the 74 files of the batches in `..\_BACKUPS\2026-10-15_18-58\`; the thin bundle of the rejected branch; the log archive |

Session 25 (2026-10-16): the cleanup of ten branches, eight tags and 246 ignored files is logged in `docs/CLEANUP_LOG.md`; the branch counts of 12.6 are the state at the end of Session 24.

## 13. Session 38 (the v10 swarm pass, branch sweep): the merged branches, verified and NOT yet deleted

`origin/main` was `9efeb89b` on 2026-10-30 when these 18 remote branches were verified as deletable. **They are still on the remote: the deletion was refused by the permission classifier (Git Destructive) and needs the owner's yes**; the owner's command is `git push origin --delete` followed by the 18 names of the table. Each tip is an ancestor of `origin/main`, so no commit becomes unreachable and a full bundle (the repository pack is 1.09 GiB) would only copy `main` again; the tip and a restore command are the backup. The ancestry was read twice by the queen (`git merge-base --is-ancestor` and `git rev-list --count origin/main..<tip>`) and once more, independently, by the read-only subagent B-BRANCH (report in `docs/RUN_STATE.md`, S38W-SWEEP). `gh-pages` (the privacy policy page), `claude/*`, `qoder/premium-visual-recovery` and `integrate/best-variants` were not touched.

| Branch | Tip | Proof | Restore |
|---|---|---|---|
| `art/monsters-final` | `2c346b18` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin 2c346b181a81b412e33844e255eece08488b7696:refs/heads/art/monsters-final` |
| `art/v7-slots` | `815470ac` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin 815470ac563ca6270df5edf76e5bc507645ce5ed:refs/heads/art/v7-slots` |
| `chore/session37-records` | `f9d4f478` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin f9d4f47818d5821febe7c7a23d3ba8fe53aadad5:refs/heads/chore/session37-records` |
| `close/v10.0.0` | `8658cabc` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin 8658cabc604348ea2800701054699bac68b9c824:refs/heads/close/v10.0.0` |
| `land/v10.0.0` | `a3a9a8a4` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin a3a9a8a41678d84506677ccd1d8330c18b4af8fd:refs/heads/land/v10.0.0` |
| `tag/v10.0.0` | `3520ec17` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin 3520ec17b4e6c180a91cd9076aecd1a5cd3555f0:refs/heads/tag/v10.0.0` |
| `release/1.0.1-20261026-bf563cc9` | `bf563cc9` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin bf563cc9353dd1fb3717943b416530e6a9e4fb2c:refs/heads/release/1.0.1-20261026-bf563cc9` |
| `release/1.0.1-20261028-102602-8865a0` | `dc47fb8c` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin dc47fb8c5d21d3f2c73b30504efd82fb156ec723:refs/heads/release/1.0.1-20261028-102602-8865a0` |
| `release/1.0.2-artpass2-20261028` | `16128543` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin 16128543d47a5b39749f973f58fc46b8b5214e66:refs/heads/release/1.0.2-artpass2-20261028` |
| `release/1.0.2-canon` | `58a5a8fa` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin 58a5a8fa03201e12d83b26bcc94888cc18b94e82:refs/heads/release/1.0.2-canon` |
| `release/1.0.2-v8` | `e3f26319` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin e3f26319381fc8d6a454f440690efd323956a8bd:refs/heads/release/1.0.2-v8` |
| `release/1.0.3-v7` | `cd058f84` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin cd058f840a3597472f97d6a906c17a5aef8e5f09:refs/heads/release/1.0.3-v7` |
| `release/1.0.3-v7-close` | `42a159d0` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin 42a159d09486baff6372667a0d88a2f40d60c328:refs/heads/release/1.0.3-v7-close` |
| `release/1.0.3-v7b` | `a201c659` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin a201c659b575fa5381633d696a381351dac8ae2c:refs/heads/release/1.0.3-v7b` |
| `release/final-1.0.1` | `0420a314` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin 0420a314a4030bcc5a9c93b15ccc39cc8251eacf:refs/heads/release/final-1.0.1` |
| `release/final-v7` | `7c82989f` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin 7c82989fc847b072499e73e0162ea3fd472ce4d4:refs/heads/release/final-v7` |
| `release/v10.1.0` | `a4b1943d` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin a4b1943d1d6fbcee4eeffeff795b0a959fdb8dea:refs/heads/release/v10.1.0` |
| `release/v8-final` | `d4a4b037` | ancestor of `origin/main` (`merge-base --is-ancestor` exit 0), 0 commits ahead; no open pull request, no protection, no tag, no release, no live reference (B-BRANCH) | `git push origin d4a4b037689948fcab8d6026a2fd705d6fc9903d:refs/heads/release/v8-final` |
