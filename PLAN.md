# PLAN.md — точка передачи контекста

Этот файл — единая точка входа для любого человека или ИИ-агента,
который продолжает проект. Составлен на основе `docs/GDD.md` (ТЗ,
844 строки, канон механик/чисел), `docs/PRODUCTION_BIBLE.md` (визуал/
аудио/бюджеты, читается первым в начале каждой волны — см. `CLAUDE.md`),
`docs/KNOWN_ISSUES.md` и `docs/HANDOFF.md` (история находок), плюс живая
проверка текущего кода (не только чтение старых отчётов).

**Правило работы по этому плану**: один пункт за раз, гейты после
каждого пункта, коммит + пуш, отметить `[x]` в этом файле. Если пункт
неоднозначен — остановиться и спросить, не выдумывать.

**Ownership (autonomous mode, 2026-09-08):** `locales/**`, `data/i18n/**`
and all i18n tooling (`tools/i18n_*.py`) are the local agent's from now
on — the Qwen agent that previously worked this area is not running.
ARENA (cloud agent) owns `levels/**`, `content/**`, `docs/**` except
`docs/GDD.md`/`docs/PRODUCTION_BIBLE.md` (frozen) — never edit those
paths, never touch its branch/PR except to merge a completed,
in-scope-only PR per `ARENA_NEXT_PROMPT.md`'s protocol. `arena/01a080ba-
igra` (suburbs district content, PR #1) was merged and deleted
2026-09-08 — see decisions log below.

## GOLD MASTER v2 — declared 2026-09-10 (store-release-pass recreate + gap-to-ideal)

**`origin/main` is GOLD MASTER v2 at `e5d4f99`.** GOLD MASTER (below) plus
the Arena store-release-pass rescued-or-recreated (Path B: the tarball was
absent and its sha256 manifest malformed) and every remaining
CLAUDE-owned P0/P1 closed. Arena sessions closed by the owner;
`store/**` + `docs/{ASSET_LICENSES,CONTENT_PIPELINE_AUDIT}.md` reassigned
to CLAUDE for this pass (no parallel session → no zone-conflict risk).

**Store-release-pass recreate (`3babbff`):**
- `store/listing.md` — **13 locale sections**. Title + tagline are the
  shipped in-game `menu_title` / `menu_subtitle` verbatim (13 locales,
  `i18n_audit.py` MISSING: 0); short (≤80, script-verified, max 73 EN) /
  full / 8 bullets / ASO tags for the 11 non-master locales transcreated
  from vetted in-game vocabulary. EN + RU master block byte-untouched.
  Generator + `--check` gate: `tools/gen_store_listing_locales.py`.
- `store/icon-adaptive/` — `foreground_1080x1080.png` +
  `background_1080x1080.png` + README, derived deterministically from
  `store/icon-512.png` by `tools/gen_adaptive_icon.py`. Crest in the
  inner 66 % safe zone on a transparent field; flat `#141b24` opaque
  background; per-channel extrema clamped to `[16,216]` → 0 pure
  `#000`/`#fff`. `export_presets.cfg` Android `launcher_icons/adaptive_*`
  repointed here; `_asset_check.gd` gate updated to match.
- `store/review-responses.md` — 5 review classes × EN + RU templates,
  each with an owner escalation line wired to a `KNOWN_ISSUES.md` entry.
- `docs/ASSET_LICENSES.md` +2 binaries; `docs/CONTENT_PIPELINE_AUDIT.md`
  §12 re-audit — listing 13/13, icon 2/2, review ops 5/5, **0 defects**.

**Gap-to-ideal execution — CLAUDE-owned P0/P1, all closed:**
- **G5 (`2101311`)** — the district rebuild ran synchronously *inside*
  `DistrictTrigger.body_entered`, so every spawned pickup's `_ready()`
  hit "Function blocked during in/out signal" (~140 per district load)
  and tree surgery happened mid-physics-signal. `world_runtime
  ._on_district_entered` now `call_deferred("load_district", …)`.
  Headless suite: **0** such errors (was ~140/load).
- **G6 (`2101311`)** — `document_pickup._collect()` set
  `collect_area.monitoring` directly from `body_entered`; now
  `set_deferred(...)`, matching `item_pickup_3d.gd`.
- Full inventory + the P2/OWNER residue: **`docs/GAP_TO_IDEAL.md`**.

**Headless suite:** green twice consecutively on the v2 tip
(`tools/qa_sim/headless_suite`). Static gates green.

**P2 / OWNER residue** (unchanged, see `GAP_TO_IDEAL.md` / `RELEASE_CHECKLIST.md`):
one `perf_check_scene.tscn --windowed` run for the real draw-call number;
release keystore + signed AAB; Play Console upload + IARC + localized
listing paste; privacy-policy URL; real AppLovin key (optional — ships on
the debug stub); native QA pass on the 11 transcreated locales; optional
eyes-on playtest. Plus two documented, real-player-unaffected harness
limits (`game_test_3d` phase-1 stall; P6 soak ~10 s).

---

## GOLD MASTER — declared 2026-09-10 (headless hardening pass)

**`origin/main` is GOLD MASTER at `f263f9f`.** FINAL RC (below) plus a
headless verification pass after the owner lifted NO-GODOT to
headless-only (`godot --headless` script/scene runs; still no
`--windowed`/editor/visible window). New gate: `tools/qa_sim/headless_suite`.

**Fixed (4 latent regressions only a real engine run could surface,
`f3bd1e3`):**
- `wow_director.gd` — `var _flash` / `func _flash()` name collision →
  parse error → the `WowDirector` autoload never loaded → PHASE-D viral
  hooks (shake/flash at first-light/cascade/victory) were dead. Renamed
  the func.
- `district_scene_factory.gd` — `LOOT_SCRIPT.populate()` through a
  `Script`-typed const does not dispatch to the static func in 4.7 →
  **zero loot / repair-parts / documents spawned in any district** (grid
  unwinnable, flashlight un-refuelable). Now calls via `class_name
  DistrictLoot`. `game_test_3d` reports `pickups spawned: 12` (was 0).
- `district_loot.gd`, `streetlight_3d.gd` — `:=` on an untyped expression
  → "Cannot infer the type" SCRIPT ERROR, cascading compile failures on a
  cold parse. Both vars given explicit types.
- `_game_test_3d.gd` — never propagated failures (`quit()` == 0) and could
  hang forever; added a 150 s hard-timeout-as-FAIL and `quit(fails)`.

**Housekeeping:** merged remote branches `arena/01a08729-igra` and
`arena/01a08b05-igra` deleted; `arena/019ffbd0-igra` and
`arena/01a07b1c-igra` held (owner decision, `KNOWN_ISSUES.md`).

**Headless suite result (green twice consecutively):**
`headless_suite` = 11 engine gate scenes (per-gate timeout) + the
scenario driver: P0 all 12 autoloads load · P1 New Game → player · P2 all
11 district scenes instantiate + `DistrictLoot.populate()` > 0 · P2b
combat damage · P3 save/load round-trip with mid-load language switch ·
P4 all 5 endings fire + resolve to localized strings · P5 **1061 en keys
× 13 locales + 10 surface keys, 0 MISSING at runtime** · P6 soak (clean;
ends ~10 s on the pre-existing test-runner MENU race — `KNOWN_ISSUES.md`).

**Perf (Task 4) — headless renderer reports `draw_calls=0` (dummy), so
the static estimate stands; owner still needs one `perf_check_scene.tscn
--windowed` run for the real number):**

| D1 (suburbs) metric | before this pass | after this pass | note |
|---|---|---|---|
| loot pickups actually spawned | **0** (populate() broke) | **12** | `game_test_3d` headless |
| structural mesh/2D draw calls (est.) | ~38 | ~38 | unchanged — loot was already in the estimate |
| real-time lights sent to shader (est.) | ~16 (no pickup lights existed) | **18** (2 pickup lights in fade range) | `drawcall_estimate.py`; distance-fade caps lamp+pickup lights |
| measured baseline (last `--windowed`) | 234 | pending owner run | D11 < 350 target already met at 234 |

The loot fix *adds* 2 pickup lights/frame vs the broken state but lands
exactly on the `drawcall_estimate.py` model's "AFTER 18" figure — the
distance-fade guard (`streetlight_3d.gd`, pickup lights) still holds it
69 % below the naive 58.

---

## RELEASE CANDIDATE v3 — FINAL RC, declared 2026-09-10 (ARENA MEGA FINAL PASS merged)

**`origin/main` is FINAL RC (`a712dd1`).** RC v2 code polish (`e65e1e4`)
plus Arena's mega final content/store/trailer pass merged clean:

- **Arena PR #9 merged** (`6fea56e`, `git merge --no-ff arena/01a08b05`)
  — scope-checked to Arena zones only (`content/**`, `store/**`,
  `docs/{ASSET_LICENSES,AUDIO_COVERAGE,CONTENT_PIPELINE_AUDIT,PROSE_CHANGES}.md`);
  zero code/tool/scene/data/locale/frozen-doc edits from Arena.
- **Trailer + press kit** — `store/trailer/` 5 palette-locked masters
  (3×1920×1080, 1×1080×1920, 1×1600×900; 0 pure `#000`/`#fff` texels,
  verified via IHDR + per-channel extrema `(10,240)`), `store/trailer.md`
  index, `store/press-kit.md`, `store/trailer/README.md` use-cases,
  `store/listing.md` polish. Every binary has an `ASSET_LICENSES.md` entry.
- **Prose polish** — 3 surgical lore kickers (`LORE_PARK_02_TEXT`,
  `LORE_PARK_07_TEXT`, `LORE_POLICE_05_TEXT`) per `docs/PROSE_CHANGES.md`
  "Changed rows (mega final pass)"; ids/keys/stages unchanged.
- **i18n re-sync** (`a712dd1`, code's zone) — those 3 keys synced across
  all 13 locales (en → authoritative rows, new sentence translated
  in-language); placeholder parity held; `i18n_audit.py` `MISSING: 0`.
- **Audio** — ladder re-run, all lit-bed gaps honestly retained as
  spec-only, **no binary fabricated** (`AUDIO_COVERAGE.md`).
- **Content certificate** — `CONTENT_PIPELINE_AUDIT.md` §11 mega-final
  re-run: 11/11 districts, store kit, ownership all **0 defects**.

Static gates green post-merge and post-i18n: `check.sh --static` 10/10,
`flow_check.py` 53, `scene_node_check.py` clean, `i18n_audit.py`
`MISSING: 0`, all 6 `tools/qa_sim/` sims PASS. No Godot binary run.
Human playtest: `docs/HANDOFF.md` "HUMAN PLAYTEST SCRIPT".

---

## RELEASE CANDIDATE v2 — declared 2026-09-10 (MEGA FINAL POLISH)

**`origin/main` is RELEASE CANDIDATE v2.** RC v1 (below) plus a deep
static-only pass that closed every remaining WON'T-FIX:

- **Endings** — all 5 GDD §12.4 endings now reachable (Dark/Survivor
  wired to `trigger_death()`); `tools/qa_sim/endings_sim.py` proves it.
- **PARTIAL power stage** — `streetlight_3d.gd` + `emissive_windows.gd`
  now render PARTIAL distinctly from DARK; `tools/qa_sim/lighting_stage_sim.py`.
- **Puzzle bonus economy (#31)** — trimmed to the one reachable row
  (`tools/qa_sim/puzzle_economy_sim.py`); `power_grid` emit symmetry
  (#14) fixed.
- **i18n hardening** — a hardcoded Polish string, a "coming soon" tab, and
  dev "ERROR:" toasts removed/localized; `tools/qa_sim/overflow_check.py`
  → 0 fixed-width overflow sites (settings labels + battery-ad button
  widened/wrapped).
- **Accessibility** — 5 of 7 toggles were non-functional or crashed
  (`tools/qa_sim/a11y_check.py`): Colorblind is now a real post shader,
  Text Size rewired, High Contrast dispatched, Arachnophobia crash fixed;
  Auto-aim + Dyslexia Font removed from the UI (no code path / no font
  asset — owner follow-ups in `KNOWN_ISSUES.md`).
- **Crash-safety deep dive** — 3 latent crash paths fixed (`screens.gd`
  null-cast, `settings_manager.from_dict` language reset, `hud_3d`
  after-free); STATIC_AUDIT #38–42.
- **Viral hooks** — `WowDirector` autoload (shake + flash at first-light /
  cascade / victory), opt-in **Trailer Mode** (HUD hide + slow-mo/FOV),
  7 photo-mode colour filters with proper env snapshot/restore.

Static gates green on every commit throughout. Sims live in
`tools/qa_sim/` and are committed. Human playtest: `docs/HANDOFF.md`
"HUMAN PLAYTEST SCRIPT v2" (14 lines).

---

## RELEASE CANDIDATE — declared 2026-09-10

**The build on `origin/main` is a RELEASE CANDIDATE.** Everything that
can be done without a Godot editor, a signing key, a store account, or a
build toolchain is done:

- Content pipeline complete — 11/11 districts packed, wired, translated
  (88 lore notes ×13 locales, `i18n_audit.py` `MISSING: 0`).
- `docs/STATIC_AUDIT.md` fully closed out — every entry FIXED or
  WON'T-FIX (RC) with a reason + GDD ref (see its close-out table).
- Arena finishing work merged (PR #8) — Play Store kit (`store/`),
  finishing-pass prose, `ASSET_LICENSES`/`AUDIO_COVERAGE`/pipeline-audit
  updates.
- Static gate suite green on every commit: `tools/check.sh --static`
  10/10, `flow_check.py` 53, `scene_node_check.py` clean, `i18n_audit.py`
  `MISSING: 0`. `default_bus_layout.tres` untouched.
- `docs/KNOWN_ISSUES.md` contains only deliberate accepts (each with the
  reason it's accepted for RC).

**Remaining work is human-only** — the 7 steps in `RELEASE_CHECKLIST.md`
(keystore, AppLovin key, host privacy policy, install export templates,
Play Console upload, optional platforms, version bump) plus one manual
in-game playtest (10-line script in the RC final report / this session's
chat output). Nothing on that list is a code or content task.

## Autonomous decisions log

Format: what / why / alternatives considered. Appended to, never
rewritten.

---

**2026-09-08 (RELEASE CANDIDATE PASS, autonomous, owner override):**
Owner explicitly authorized merging Arena's open PR directly from this
session (GitHub UI/`gh` unusable on their machine) — a prior wave's hard
stop against touching Arena's branch/PR was lifted for this one action
only. Verified before merging: Arena's own 4 commits (merge-base to
branch tip) touched only `content/**` + `docs/CONTENT_DISTRICT_SUBURBS.md`
— 5 new files, 0 deletions, 0 conflicts with `main`. Merged
`arena/01a080ba-igra` (`--no-ff`), pushed, deleted the remote branch.

Two OTHER `arena/*` branches existed on origin (`019ffbd0-igra`,
`01a07b1c-igra`) — inspected but **not merged**: their own commits touch
`scripts/`, `tools/`, `weapons/`, an entire autopilot test framework —
far outside the `content/**`/`levels/**`/`docs/**` scope this project's
own PR-integration protocol requires for a self-merge, and old enough
(merge-base 13+ commits behind current `main`) that a blind merge risked
large silent conflicts with work already shipped since. Left alone,
flagged for the owner to review manually — see final chat report.

Wired the merged suburbs content: `document_pickup.gd`/`journal_ui.gd`
now resolve optional `title_key`/`content_key` catalog fields through
`LocalizationManager` (legacy raw-text catalog entries unchanged), so
content-authored lore translates without a new content pipeline; 8 notes
spawn via a new extensible `LORE_DOCS` dict in `district_loot.gd`
(reuses the existing one-shot procedural scatter, same as `DOCUMENTS`).
16 `LORE_SUBURBS_*` keys translated x13 locales directly (Qwen is not
running). Skipped the corner-shop key-lock and per-zone prop placement
from Arena's wiring checklist — real scene editing, higher risk/effort
for narrative polish that isn't required for the core loop; not
attempted blind, documented as backlog instead (ponytail: don't guess at
scene changes without visual verification).

Found and fixed two live i18n regressions while auditing "instant
language switch": `hud_3d.gd`'s HP/Stamina/Battery/Noise/Visibility/
Ammo/Radar/Sprint/Stealth captions and `journal_ui.gd`'s note list were
built once and never listened for `LocalizationManager.language_changed`
— stale text survived a live Settings → Language change until the scene
reloaded. Both now reconnect on that signal. `quest_journal.gd`/
`skill_tree_ui.gd` have the same shape of gap but weren't fixed this
pass (lower priority — see `docs/KNOWN_ISSUES.md`).

Audio: `SettingsManager`'s volume sliders covered Master/Music/SFX/Voice
but not `Ambient` — the bus `audio_system.gd`/`district_atmosphere.gd`
actually route district ambience through, with zero player-facing
control. Added the slider (same pattern as its siblings). Left the `UI`
bus without a slider — nothing in the project currently routes any sound
to it, so a control for it would be speculative, not a fix.

Follow-up (same day): fixed the same live-language-switch gap in
`quest_journal.gd` (rebuild-on-language_changed, matching
`settings_screen.gd`'s pattern) and `skill_tree_ui.gd`/`skill_button.gd`
(tab titles + skill name/desc/cost retranslate via the existing
`refresh()` chain). `docs/KNOWN_ISSUES.md`'s live-switch list is now
fully closed.

**2026-09-08 ("merge arena" command, PR #2):** owner sent the exact
command to merge Arena's second PR (`arena/01a08149-igra`: residential +
park district content, the world bible, lit-tile assets). Scope-checked
first (own commits vs merge-base: `content/**`, `docs/**` except frozen,
`assets/textures/**` only — in bounds), all 8 new JSON files
syntax-validated, merged `--no-ff`, 0 conflicts, full 5-gate + windowed
boot/perf suite green, branch deleted.

Wired everything the same way suburbs was: `residential`/`park` note ids
added to `district_loot.gd`'s `LORE_DOCS`, their catalog entries added to
`documents_catalog.json` with `title_key`/`content_key`. Added a new
`scripts/world/world_bible.gd` — minimal static id→dict lookups over
`content/world/*.json`/`content/lore/*.json` (characters, factions,
revealed radio transcripts), stage-gated through `DistrictManager`, no
new systems (same style as `district_loot.gd`'s own static utility
methods). Used it in two places: `journal_ui.gd` shows an already-
revealed "Related: X, Y" line under a note's text when it carries
`world_refs` (park notes only, so far); `radio.gd` appends revealed
`content/world/radio_transcripts.json` broadcasts as extra channels next
to its 5 fixed demo ones (same `tr()`-via-`TranslationServer` path the
screen already used — `LocalizationManager` registers every JSON key
with Godot's real `TranslationServer`, confirmed by reading
`localization_manager.gd`, so this isn't the same class of bug as the
raw-`tr()`-never-resolves issue from earlier waves).

Deliberately NOT built: a UI to browse the whole world bible (characters/
factions list, timeline) — the brief said "minimal APIs only, no new
systems," and nothing in the merged content requires more than the two
cross-link points above to be functional. `history.json` (`hist_*`)
entries have no `i18n_keys` field by the world bible's own contract (not
directly shown to the player) — not translated, correctly.

85 new keys × 13 locales translated directly (not Qwen, not a
placeholder pass): `LORE_RESIDENTIAL_*`(16), `LORE_PARK_*`(16),
`WORLD_CHAR_*`(18), `WORLD_FACTION_*`(10), `WORLD_RADIO_*`(6),
`WORLD_DIARY_*`(8), `WORLD_NEWS_*`(10), `JOURNAL_RELATED`(1).
`content/world/history.json` intentionally excluded (see above).

Caught and reverted before commit: registering `WorldBible`'s new
`class_name` required one `godot --headless --editor --quit` run (a
plain `--path . --quit` doesn't rebuild `global_script_class_cache.cfg`)
— that editor pass silently corrupted `default_bus_layout.tres` on its
own resave (dropped the whole Master bus block, dropped `room_size` from
the reverb, mangled the resource `uid`). Caught by manually diffing the
file before staging, reverted with `git checkout --`, documented in
`docs/KNOWN_ISSUES.md` as a standing gotcha for next time.

---

**2026-09-09 (merge arena PR #4, autonomous, NO-GODOT static mode):**
Merged `arena/01a08281-igra` (police district pack + Arena's
`docs/CONTENT_PIPELINE_AUDIT.md` re-run across districts 1–7, 0 new
defects) — scope-checked (content/districts/police, assets/textures,
docs/** only, all within Arena's zones), both JSON files valid, all 20
item ids and all 16 distinct `world_refs` ids cross-checked against
`data/items/*.tres` and `content/world/*`/`content/lore/*` by hand
before merging (not just trusted from the audit doc). `--no-ff`, 0
conflicts, pushed, branch deleted, static gates green.

Wired identically to prior districts: `district_loot.gd`'s `LORE_DOCS`
gained the `police` entry (`BY_DISTRICT`/`BLUEPRINTS`/`STORY_DOC` already
had `police` rows pre-existing in code, ahead of content — only the
lore-note id list was new); 8 `documents_catalog.json` entries generated
the same way as prior batches (89 entries total, 0 duplicates). 16
`LORE_POLICE_*` keys translated ×13 locales (983 keys/locale,
`i18n_audit.py` confirms `MISSING: 0`).

Re-verified (not just trusted) both open CODE-facing facts from PR #3
still hold for the new pack: police is not a leaf of `powered_by`
(`industrial` still lists it as a co-parent — #21 stays correct as
written), and `district_themes.gd`'s `police` row has no `"music"` key
(colour-only, per the #22 fix already applied) — logged as
`STATIC_AUDIT.md` #25, status VERIFIED, no code change needed either
time.

Caught and fixed before commit: `git add -A` swept in an untracked
`.claude/worktrees/` directory (unrelated local worktree scaffolding,
flagged at session start as `?? .claude/worktrees/` in git status, not
authored by this session) that would otherwise have been committed to
`main`. Unstaged, added `.claude/worktrees/` to `.gitignore`, re-staged
only the intended files. Lesson: `git add -A` is unsafe when untracked
non-project directories exist; prefer explicit paths after checking
`git status` for surprises, especially right after a fresh session
resume.

`ARENA_NEXT_PROMPT.md` rewritten to queue district 8 (`warehouses` per
GDD §4.1) with its computed `powered_by` closure spelled out
(`hospital → residential → suburbs`, so Act II Architect material
*is* legal there for the first time, unlike every district since
hospital) and a heads-up about `industrial`'s two-parent convergence
for the district after that.

---

**2026-09-09 (merge arena PR #5, autonomous, NO-GODOT static mode):**
Merged `arena/01a0859c-igra` (warehouses district pack + Arena's
`docs/CONTENT_PIPELINE_AUDIT.md` re-run across districts 1–8, 0 new
defects; plus a surgical repair of a 3px edge-frame defect on the
shipped dark `warehouses_floor.png`, re-deriving the lit twin from the
repaired dark). Scope-checked, both JSON files valid, all 20 item ids
and all 12 distinct `world_refs` ids cross-checked by hand against
`data/items/*.tres` and `content/world/*`/`content/lore/*` before
merging. `--no-ff`, 0 conflicts, pushed, branch deleted, static gates
green.

Wired identically to prior districts: `district_loot.gd`'s `LORE_DOCS`
gained `warehouses` (its `BY_DISTRICT`/`BLUEPRINTS`/`DOCUMENTS` rows
already existed in code ahead of content); 8 `documents_catalog.json`
entries appended (97 total, 2 correctly carry no `world_refs` key since
their source notes had an empty array); 16 `LORE_WAREHOUSES_*` keys
translated ×13 locales (999 keys/locale, `i18n_audit.py`: `MISSING: 0`).

Re-verified both open CODE-facing facts from PR #3/#4 (`STATIC_AUDIT.md`
#21/#22) against the new pack: warehouses confirmed not a leaf
(`industrial.powered_by = [warehouses, police]`), its `district_themes.gd`
row has no `"music"` key — logged as `STATIC_AUDIT.md` #26, VERIFIED,
no code change needed. Also load-tested the Arena-side texture repair
(dark floor + both new lit twins) as valid PNGs within the prop-texture
budget (`docs/PRODUCTION_BIBLE.md` §4) — clean.

Notable first: warehouses' closure (hospital→residential→suburbs)
legitimately unlocks the Act II Project Architect world-bible set for
the first time (every district since hospital was on a branch that
didn't require it); verified all three Architect ids plus the fourth
(`char_architect`) are used at `min_stage >= 2` in the pack, matching
their own `hospital/STREETS` reveal gate exactly — no premature-unlock
leak of the kind #24 (park/`char_babka_manya`) originally found.

`ARENA_NEXT_PROMPT.md` rewritten to queue district 9 (`industrial` per
GDD §4.1) — the first **two-parent convergence**
(`powered_by = [warehouses, police]`), so its guaranteed closure is
the *union* of both branches (suburbs, residential, park, hospital,
warehouses, police — six districts), not a single chain. Flagged this
explicitly in the prompt since it's the first closure computation of
this shape and the easiest one to get wrong.

---

**2026-09-09 (merge arena PR #6, autonomous, NO-GODOT static mode):**
Merged `arena/01a085f3-igra` (industrial district pack, district 9, the
chain's first two-parent convergence — `powered_by = [warehouses,
police]` — plus Arena's `docs/CONTENT_PIPELINE_AUDIT.md` re-run across
1–9, 0 new defects; its own audit traced and fixed 4 checker-tooling
false positives, not pack issues). Scope-checked, both JSON files valid,
all 19 item ids and all 22 distinct `world_refs` ids cross-checked by
hand against the six-district union closure (suburbs, residential,
park, hospital, warehouses, police) before merging — 0 leaks, including
the first-ever simultaneous use of the Act II Architect set (via the
warehouses branch) and the Keeper/radio set (via the police branch).
`--no-ff`, 0 conflicts, pushed, branch deleted, static gates green.

**Audio decision (merge directive step 2):** `industrial_dark.ogg`
measures 33.994 s, the only district bed off the shipped 36.000 s house
contract. Independently re-verified by parsing the Ogg container's own
final-page granule directly (1,499,146 → 33.994 s exactly, no ffmpeg
needed) rather than trusting Arena's header-verification claim blind.
Computed the alternate theory precisely: 12 bars at the industrial
theme's 85 bpm = 33.882 s, within 112 ms of the shipped length —
consistent with normal encoder frame-padding, not a random mis-render
(36 s at 85 bpm would be a non-whole 12.75 bars). Grepped
`music_manager.gd` and `district_atmosphere.gd` for any hardcoded 36 s
assumption — none exists; loop handling is duration-agnostic, driven by
the actual resource. **Decision: accepted as canon, not a defect.**
Chose not to re-render for two independent reasons, either alone
sufficient: (a) the evidence favors "deliberate" over "render error",
and (b) `assets/audio/**` is Arena's ownership zone, not code's — even
if re-rendering were clearly correct, fabricating/replacing binary
audio myself would cross the same ownership boundary the standing mode
already establishes for `.gd`/`.tscn`/content files, and NO-GODOT
static-only verification doesn't license generating new binary assets
either. Documented in `docs/KNOWN_ISSUES.md`.

**Content defect found and worked around, not hand-edited (ownership
boundary respected):** `content/districts/industrial/lore_notes.json`'s
`en.text` fields carry a literal double-escaped `\"` (backslash+quote)
instead of a plain `"` in all 8 notes wherever they quote in-world
dialogue — confirmed via `repr()` on the parsed Python string, confirmed
absent from `warehouses`' equivalent file as a control. Since the raw
JSON is Arena's reference/source material (`content/**`, not my zone)
and the actual player-facing text lives in `data/i18n/*.json` under the
keys I write, the fix was to write clean quotes into the 16
`LORE_INDUSTRIAL_*` i18n keys directly rather than propagate the
artifact — no player ever sees it, and the source file goes untouched.
Registered `STATIC_AUDIT.md` #28, logged as an open question in
`docs/HANDOFF.md` for Arena to clean up the source whenever `industrial`
gets touched again.

Also caught and fixed a self-inflicted bug from an earlier session
turn: an edit in the previous ("warehouses") PR had accidentally
dropped the `## CONFIRMED WORKING` section heading from
`docs/STATIC_AUDIT.md` (its `old_string`/`new_string` pair omitted the
heading line). Restored in this pass.

Wired identically to prior districts: `district_loot.gd`'s `LORE_DOCS`
gained `industrial` (its `BY_DISTRICT`/`DOCUMENTS` rows already existed
in code; correctly has no `BLUEPRINTS` row, matching the pack's own "no
schematic here" canon, R7); 8 `documents_catalog.json` entries appended
(105 total); 16 `LORE_INDUSTRIAL_*` keys translated ×13 locales (1015
keys/locale, `i18n_audit.py`: `MISSING: 0`).

`ARENA_NEXT_PROMPT.md` rewritten to queue district 10 (`substation` per
GDD §4.1) — a single direct parent (`industrial`) whose own closure is
itself a union, so substation's guaranteed history is seven districts
(suburbs, residential, park, hospital, warehouses, police, industrial).
Flagged that `radio_02_grid_crew_relay` becomes legal to reference here
for the first time (gated on `substation`/`min_stage 1` per
`content/world/radio_transcripts.json`, verified directly), while
`radio_03_keeper_reversal` stays out (gated on `power_station`, the
final district).

---

**2026-09-09 (merge arena PR #7, autonomous, NO-GODOT static mode) —
CONTENT PIPELINE COMPLETE: 11/11 DISTRICTS:**
Merged `arena/01a0867f-igra` — the final two districts (`substation`
D10, `power_station` D11, chain terminal), plus Arena's own fix for the
industrial `lore_notes.json` double-escaping (`STATIC_AUDIT.md` #28)
and the final 1–11 re-run + 15-point CONTENT RELEASE CERTIFICATE in
`docs/CONTENT_PIPELINE_AUDIT.md` §9. Scope-checked, all 5 JSON files
valid, all item ids and all `world_refs` (18 distinct for substation,
20 for power_station) hand-verified against each district's computed
closure before merging — 0 leaks either way. `--no-ff`, 0 conflicts,
pushed, branch deleted, static gates green.

Verified the industrial escaping fix before trusting it: parsed
Arena's fixed `lore_notes.json` and diffed all 8 texts byte-for-byte
against the already-shipped `LORE_INDUSTRIAL_*` i18n values — 8/8
exact matches, confirming zero player-visible change from either side
of that fix (satisfied the merge directive's step 4 by direct
comparison, not by assumption).

Wired both districts identically to all 9 prior ones:
`district_loot.gd`'s `LORE_DOCS` gained `substation` and
`power_station` (their `BY_DISTRICT`/`DOCUMENTS` rows already existed
in code; both correctly have no `BLUEPRINTS` row); 16
`documents_catalog.json` entries appended (121 total, 0 duplicates); 32
`LORE_SUBSTATION_*`/`LORE_POWER_STATION_*` keys translated ×13 locales
(1047 keys/locale, `i18n_audit.py`: `MISSING: 0`).

Traced `power_station`'s `reactor_power_station` puzzle citation
(`reward: "ending"`) read-only per the merge directive's explicit
step 2 instruction: confirmed `_grant_reward()`'s `"ending"` branch
only emits a toast, and victory is driven entirely by
`PowerGrid._check_victory()` (all 11 FULL) → `GameManager.trigger_win()`
— unrelated to this dictionary. No endings-logic code touched.

**Substantial finding this pass, not introduced by this session:**
while tracing the "ending" reward, followed `PuzzleSystem.start_puzzle()`
to its only live caller and discovered `puzzle_system.gd`'s entire
reward dictionary (coins/battery/medkit/ending, one entry per district,
cited as canon by all 11 content packs) is reachable for only 1 of 11
districts — the other 10 have no interactable node wired to
`start_puzzle()` at all. Traced carefully before concluding anything:
confirmed the CORE district-restoration loop is unaffected (fully live
via the separate, independent `power_switch.gd` mechanism for all 11
districts, already `CONFIRMED WORKING` in a prior pass) — this is a
missing SECONDARY bonus layer, not a broken core loop. Deliberately did
NOT attempt a fix: building 9 more scene-level interactable nodes is
real scene-editing work I can't visually verify in NO-GODOT mode (same
class of risk the very first suburbs wave already declined for a
similar reason), and the alternative — wiring `power_switch.gd` itself
into `PuzzleSystem.mark_solved()` — would change what every player
receives on every district completion, a balance/design call that
isn't mine to make unilaterally without a decision from the owner.
Registered as `STATIC_AUDIT.md` #31 and a `KNOWN_ISSUES.md` entry,
DOCUMENTED not fixed, with both remediation paths spelled out for
whoever makes that call.

Also independently re-verified Arena's new audio finding F1
(`power_station_generator_thrum.ogg`/`cooling_fan.ogg`, 28.7-28.9s vs
the 30.000s detail-bed class) via the same direct Ogg-granule parsing
method used for the industrial bed — confirmed no code dependency on
detail-bed duration, documented as non-blocking (`STATIC_AUDIT.md` #32).

**Content pipeline complete: 11/11 districts.** Independently
re-verified Arena's release certificate rather than trusting it:
recomputed note-id and fixed-spawn-id counts across all 11
`content/districts/*/lore_notes.json` and `item_spawns.json` files by
hand (88 notes, 103 fixed spawns, both confirmed 100% globally unique)
— matches the certificate's own count exactly. `ARENA_NEXT_PROMPT.md`
set to pipeline-complete (no next district queued); GDD.md has no
epilogue-district scope beyond D11, so no further content wave is
expected from Arena barring the owner requesting one.

---

**2026-09-10 (RC FINAL PASS — arena triage + Phase A crunch, autonomous
desktop, NO-GODOT static mode):**

STEP 0 state sync: `git fetch` + `git pull --ff-only origin main` — `main`
already at `db6367d`, the 12-commit RC crunch was NOT on `origin/main`, so
Phase A (the STATIC_AUDIT close-out) executed in full — see the crunch
commits and the STATIC_AUDIT.md status column.

STEP 1 — three unmerged `arena/*` branches on origin, triaged before
touching anything:

- **`arena/01a08729-igra`** — 4 commits (`a2ed603`..`965d020`), branched
  directly off the current `main` HEAD (`db6367d`). Scope: `store/**`
  (listing EN+RU, changelog, feature-graphic.png, icon-512.png,
  screenshots-plan, privacy-policy-template), `docs/{PROSE_CHANGES,
  ASSET_LICENSES,AUDIO_COVERAGE,CONTENT_PIPELINE_AUDIT}.md`, and a 2-word
  `centre→center` prose fix in `content/districts/{gas_station,police}/
  lore_notes.json`. All inside the MERGE POLICY scope (store-kit +
  PROSE_CHANGES + ASSET_LICENSES finishing work). All 5 JSON/`.md`
  additions valid; the 2 lore edits are pure prose (no id renames — grep
  cross-checked against `district_loot.gd`'s `LORE_DOCS`).
  **Classification: fresh, in-scope Arena finishing work → the Phase B
  merge target.** This is the "finishing session" branch the RC brief
  refers to; being based on current HEAD it either *is* PR #8's branch or
  supersedes it — same merge target either way.
- **`arena/019ffbd0-igra`** — 57 commits, merge-base `f841ad6` (~60
  commits behind `main`). Payload = the autopilot in-engine test suite +
  a large gameplay-fix batch (stealth/doors/medkits/save-system/tutorial/
  photo-mode/finale reachability). **Already on `main`** through earlier
  integration: `tools/autopilot/`, `tools/flow_check.py`,
  `tools/orphan_check.py` are all present on `main` and CLAUDE.md's
  "Already done" list enumerates every one of these fixes.
  **Classification: stale / superseded. NOT merged** — replaying 56 stale
  commits would produce large conflicts for zero gain. `KNOWN_ISSUES.md`
  note added; left on origin for archival only.
- **`arena/01a07b1c-igra`** — 9 commits (Russian messages), an FPS-weapons
  gameplay layer (`scripts/weapons/**`, `project.godot`, player/weapon
  `.tscn`, `docs/IDEA_CONFORMANCE.md`, `data/items/ammo.tres`). Touches
  code far outside the content/store/docs scope this project's self-merge
  protocol permits, and is a separate feature initiative (GDD §18), not RC
  finishing work. **Classification: stale, out-of-scope. NOT merged,
  untouched** — needs an explicit owner decision. `KNOWN_ISSUES.md` note
  added.

Arena merge target chosen: **`arena/01a08729-igra`** (executed in Phase B).

Phase sequencing: Phase A (STATIC_AUDIT crunch) run before Phase B (arena
merge) — Phase A is the RC milestone (`RC FINAL PASS Phase A complete` is
its own closing commit subject), it must land regardless of arena branch
state, and Phase B carries a "static gates red → revert merge, STOP" clause
that could otherwise abort the run before the crunch. `arena/01a08729-igra`
is based on `db6367d` and merges cleanly on top of the Phase A commits
(disjoint file sets — store/** + content prose vs. scripts/** + i18n).

**Phase B executed — `Merge PR #8` (`--no-ff`, 0 conflicts, static gates
green).** Brought `store/**` (6 files), `docs/PROSE_CHANGES.md`,
`docs/ASSET_LICENSES.md` + `AUDIO_COVERAGE.md` +
`CONTENT_PIPELINE_AUDIT.md` §10, and the `centre→center` fix in
`gas_station`/`police` `lore_notes.json`. All within the MERGE POLICY
scope / Arena's ownership zones.

i18n re-sync per `PROSE_CHANGES.md`: the 2 changed rows
(`LORE_GAS_STATION_06_TEXT`, `LORE_POLICE_06_TEXT`) are a British→American
spelling normalization of one word ("centre"→"center") in the recurring
Keeper's requisition forms. `data/i18n/en.json` updated byte-for-byte
from the merged content JSON (verified equal). The other 12 locales need
no byte change: `fr` legitimately keeps "centre" (correct French), and
`ru/de/es/it/pt_BR/ja/ko/zh/zh_TW/ar` already render the concept in-
language (центр / Zentrum / 中心 / …) with no English loanword to fix.
Key parity confirmed across all 13 (`i18n_audit.py`: `MISSING: 0`,
placeholder parity N/A — no `%` specifiers in these keys).

Store-kit checklist verified: `store/listing.md` (Title / Short / Full,
EN+RU), `store/changelog.md` (v1.0 EN+RU), `store/feature-graphic.png`
(1024×500, exact Play spec), `store/icon-512.png` (512×512),
`store/screenshots-plan.md` (8-shot plan), `store/privacy-policy-
template.md` (full template) — all present, well-formed, correct PNG
dimensions.

---

**2026-09-10 (MEGA FINAL POLISH — deep-static WON'T-FIX close-out, autonomous
desktop, NO-GODOT absolute):** every remaining WON'T-FIX either fixed by
static means (with a `tools/qa_sim/` simulation as evidence) or converted to
a precise owner-verify step.

- **#6 endings** → FIXED. `GameManager.trigger_death()` now calls
  `EndingsManager.evaluate_death_ending()`; `_determine_ending()` gained
  `is_death` + `power_station_full`. Dark = death, grid unrepaired.
  Survivor = death with `power_station` FULL but `full < 11` — reachable
  because `school`/`gas_station` are optional leaf districts (the sim
  parses `data/districts/*.tres` to prove it). Win path unchanged.
  `tools/qa_sim/endings_sim.py` walks the reachable state space →
  all 5 endings reachable, `PASS`. Also fixed `core/endings.gd`'s stale
  `"powerplant"` → `"power_station"` id.
- **#7/#8 emissive-windows / PARTIAL** → FIXED. `streetlight_3d.gd` lights
  a deterministic ~40% lamp subset (hash of world position) dimly at
  PARTIAL; `emissive_windows.gd` reads its district id from
  `../StreetBuilder` and scales lit-fraction + brightness per stage
  (FULL byte-identical to the old fixed behaviour — no regression for
  already-restored districts). `tools/qa_sim/lighting_stage_sim.py`
  tabulates all 4 stages and confirms them mutually distinct post-fix.
- **#14 power_grid** → FIXED. `reset()`/`from_dict()` now emit
  `district_stage_changed` per district (symmetry with
  `_set_stage_direct`); persistent autoload listeners stay in sync on
  load/New-Game. `finale_director` listens to `district_restored`
  (FULL-only) so no spurious finale.
- **#18 weather_system** → already FIXED in an earlier pass
  (`call_deferred("_emit")`); doc entry lagged the code.
- **#16 / #19** → ACCEPT: `puzzle_base.gd` and root-level
  `death_screen.tscn`/`.gd` re-confirmed not instanced; kept per the
  no-delete rule.
- **#20 / #24** → ACCEPT + owner-verify steps in the playtest script
  (every district completable; no journal "Related:" line names a place
  from a district not yet reached). Neither is a live defect.
- **#31 puzzle bonus economy** → decided (b) **delete the dead path**.
  `tools/qa_sim/puzzle_economy_sim.py` resolves every `_puzzle_data` id
  against the ids a real interactable can pass to `start_puzzle()`:
  pre-fix **1 of 11** rows reachable (only `fuse_substation`, via
  `cable_box_interactable.gd` in `substation.tscn`). Wiring the other 9
  into `power_switch.gd` would double-count `puzzle_solved` for
  `progress_tracker`/`xp_manager` and change the reward economy on every
  district completion (a GDD §3.3/§8 balance call, not code's). Trimmed
  `_puzzle_data` to the one reachable row; `_grant_reward()` kept general
  so a future real per-district puzzle interactable can re-add its row.
  Core restoration DARK→FULL for all 11 districts is unaffected (separate
  `power_switch.gd` loop).
- **#32 audio length** → ACCEPT as canon (12-bar @ 85 bpm math already
  verified, `KNOWN_ISSUES.md`); re-render is Arena's call if ever wanted.
- **D1 draw calls** → static per-district estimate from the scene graphs
  + code-side reductions, see its own commit and
  `tools/qa_sim/drawcall_estimate.py`.

---

## А. Что уже работает (проверено, не предположение)

Ядро игры полностью играбельно — подтверждено `boot_check_scene.tscn`
(меню → новая игра → 60с реального геймплея → сохранение → выход →
загрузка, без падений) и `tools/check.sh --static` (10/10 зелёных гейтов).

| Система | Файлы | Статус |
|---|---|---|
| Игровой цикл, состояния | `scripts/core/game_manager.gd`, `scripts/core/routes.gd` | Работает, гейт `boot_check_scene.tscn` зелёный |
| Электросеть, 11 районов, 4 стадии питания | `scripts/systems/power_grid.gd`, `scripts/world/district_atmosphere.gd` | Работает; уличные фонари реально реагируют на стадию района (исправлено в TRUTH WAVE — раньше не реагировали вообще, см. `docs/KNOWN_ISSUES.md`) |
| Стелс: шум + видимость (не полоса детекции) | `scripts/systems/footstep_system.gd`, монстры (`vision_range`/`vision_angle`) | Работает по формуле GDD §7 |
| Бой: комбо, dodge, хитбоксы, смерть/респавн | player/enemy скрипты, `scripts/enemies/base_monster.gd` | Работает |
| 12 типов врагов + босс | `scripts/enemies/*_3d.gd` (12 файлов) | Все звучат в бою (`_set_cues` на всех), баланс подтянут к GDD §6.2 (WAVE 6 P1) |
| Оружие: pistol/rifle/shotgun | `scripts/weapons/weapon_*.gd` | Работает, у каждого своё имя/звук/иконка |
| Фонарик + дерево улучшений батареи/яркости/etc | `scripts/systems/flashlight_upgrade_manager.gd` | Работает, стоимость улучшений сверена с GDD §3.3 |
| Крафт (верстак) | `scripts/ui/workbench.gd`, `data/items/*.tres` | Все 8/8 рецептов craftable (WAVE 6 P2) |
| Скилл-дерево | `scripts/systems/skill_tree_manager.gd` | Работает, все 4 ветки GDD §8 (combat/survival/utility/stealth, `b861b14`), названия/описания через `SKILL_*` i18n-ключи ×13 |
| Сохранения | `scripts/core/save_system.gd` | Работает; `reset_all()` реально сбрасывает XP/скиллы при New Game (это было сломано, исправлено — см. `CLAUDE.md` «TRUTH WAVE») |
| 5 концовок | `scripts/systems/endings_manager.gd` | Работает: у каждой концовки своя музыка (стинг для 3, полный трек для 2) |
| Достижения | `scripts/systems/achievements_manager.gd` | 20 достижений, реальные пороги (не «срабатывает на первом же событии», это было багом — исправлено) |
| Квесты | `scripts/systems/quest_manager.gd` | Все квесты, которые GDD подразумевает достижимыми, реально достижимы (3 «мёртвых» квеста оживлены через зоны/пазл) |
| 5-слойная адаптивная музыка + погода + звуки района | `scripts/systems/music_manager.gd`, `scripts/systems/district_atmosphere.gd`, `scripts/systems/weather_system.gd` | Работает, включая только что подключённые дождь/ветер и 40 звуковых деталей района |
| i18n-инфраструктура (13 языков) | `scripts/core/localization_manager.gd`, `data/i18n/*.json`, гейт `i18n_check_scene.tscn` | Инфраструктура полная и без ошибок; **контент переведён не на 100%** — см. раздел Б |
| Онбординг для новых игроков | `scripts/ui/onboarding_overlay.gd` | Показывается один раз на новом профиле сохранения |
| Энциклопедия монстров с детальным просмотром | `scripts/ui/encyclopedia_ui.gd` | Работает |
| Реклама (AppLovin MAX) | `scripts/monetization/ad_service.gd` | Код реальный и подключён к геймплею (interstitial + rewarded revive/battery), но без настоящего SDK-ключа — см. раздел Б |

---

## Б. Что отсутствует или сломано (по приоритету)

1. **Draw calls превышают бюджет D1 (<200) для стартового района.**
   Последнее измеренное значение — 234 (после батчинга скамеек/деревьев/
   конусов/фонарей в MultiMesh), бюджет D11 (<350) выполнен, D1 — нет.
   **Перепроверено 2026-09-08**: сначала ошибочно заподозрил уже
   исправленную (в "FINAL PERFECTION P3") причину — Pole/Lamp фонарей;
   `git blame`/чтение `streetlight_3d.gd` подтвердило, что это давно
   батчится. Актуальный источник остатка (анализ из прошлой волны,
   подтверждён) — меши монстров (6, намеренно не батчатся, они
   динамические) и подбираемые предметы (12, индивидуальные). Точную
   разбивку по draw call'ам без редакторского Visual Profiler (не
   запускается в headless/CLI-сессии) получить нельзя — дальше без
   дизайнерского решения (меньше предметов одновременно) или глубокого
   батчинга анимированных/подбираемых мешей не продвинуться. См.
   `docs/PRODUCTION_BIBLE.md` п.7 и `docs/KNOWN_ISSUES.md`.

2. ~~`emissive_windows.gd` никогда не рендерил ни одного окна~~ —
   **ОКАЗАЛОСЬ УЖЕ ИСПРАВЛЕНО** до начала этой волны (коммит `c917ab1`,
   до моего вмешательства): старый `scripts/world/emissive_windows.gd`
   (искавший несуществующую геометрию стен) удалён, реальные окна во
   всех 11 районах рисует `scripts/visual/emissive_windows.gd` —
   самодостаточный `MultiMeshInstance3D`, вручную размещённый в каждой
   `.tscn` района, без зависимости от поиска стен вообще (в проекте
   нигде не спавнится геометрия стен — фильтровать было физически
   нечего). Проверено: `EmissiveWindows` есть во всех 11
   `scenes/districts/*.tscn`. Никакого дизайнерского решения не
   потребовалось — задача снята с плана. Файлы: `scripts/world/emissive_windows.gd`,
   `scripts/world/world_bootstrap.gd`.

3. ~~**Скилл-дерево: 3 ветки вместо 4.**~~ **ЗАКРЫТО** — 4-я ветка
   (Stealth: `silent_steps`/`cold_trail`, реальные эффекты в
   `player_3d.gd`/`base_monster.gd`) добавлена в Этапе 3, коммит
   `b861b14`. Названия/описания всех навыков — `SKILL_*` i18n-ключи ×13
   локалей (`i18n_audit.py`: `MISSING: 0`). Стейл-запись в
   `docs/KNOWN_ISSUES.md` тоже поправлена (RC-проход 2026-09-10).

4. **i18n-контент: ЗАВЕРШЕНО 2026-09-08 (автономная волна).** Было 3424
   строки-заглушки на английском (817 ключей × 11 языков) на начало
   волны. Переведено батчами, гейты зелёные после каждого коммита:
   `SCR_*` (122, `d329308`), `Q_*` (40, `98da3e1`), `SKILL_*` (28,
   `88bd6a0`), `ACH_*` (22, `4ce4f69`), `QUEST_*` (11, `455e2a1`),
   `END_*`/`ENDING_*` (25, `d2e9b02`), `MAP_*`/`UPG_*`/`WEAKSPOT_*` (22,
   `e904d98`), остальной хвост — `INV_*`/`ITEM_*`/`JOURNAL_*`/`PROMPT_*`/
   `SHOP_*`/`STATS_*`/`TIP_*`/`ONBOARD_*`/`ENC_*`/`hud_*`/`menu_*`/
   `msg_*`/`cb_*` и разное (90, `e4dac8d`).

   **Финальный пересчёт**: 165 строк всё ещё формально "= английскому",
   но это **не пробел** — вручную сверено, каждая: легитимный когнат/
   заимствование (Auto, Park, Normal, AUDIO, Journal, Radio, SS-N-коды,
   " kg" как единица СИ и т.п. — реально одинаково пишутся в этих
   языках) либо мой сознательный выбор при переводе (например
   "Speedrunner"/"Endurance" как игровой термин-заимствование в
   de/fr/it/pt_BR). Ни разу не оставлено непереведённым по недосмотру.
   Инфраструктура: гейт зелёный, 0 «сырых» `tr()`-багов, **0
   romanized-placeholder текста** (детектор запускался дважды за волну).
   i18n-контент можно считать закрытым; если появятся НОВЫЕ ключи в
   будущих волнах — переводить сразу, не копить новый backlog.

5. **Релиз ещё не готов физически** (код готов, ручных шагов не
   хватает — полный список в `docs/SESSION_REPORT_SHIP.md`'s
   `FINAL HUMAN_CHECKLIST`):
   - релизный keystore не создан (`tools/make_keystore.ps1` для этого
     есть);
   - реальный AppLovin SDK-ключ не установлен;
   - приватная политика не опубликована по стабильному URL
     (`docs/PRIVACY_POLICY.md` готов как черновик);
   - Web/Windows export templates физически не установлены в Godot —
     новые пресеты в `export_presets.cfg` ещё не проверялись реальным
     экспортом.

6. **Draw-call бюджет — только измеряется, не гейтуется автоматически.**
   `docs/PRODUCTION_BIBLE.md`'s п.7 checklist явно просит сделать это
   автоматической проверкой (`perf_check_scene.tscn` существует и
   печатает число, но не проваливает гейт при превышении). Инфраструктурная
   задача, независимая от пункта 1.

7. **Два известных «мёртвых» экрана-дубля не удалены** (сознательно,
   по правилу «не удалять непроверенное мёртвым И не запланированное»):
   `scripts/ui/lobby_menu.gd` (LAN-лобби, никуда не подключён) и
   `scripts/ui/save_slot_entry.gd`/`save_slots_ui.gd` (мультислотовый
   выбор сохранения, тоже не подключён — реальный слот один, через
   кнопку Continue). Нужно решение: либо подключить (это реальные
   фичи), либо официально списать в архив.

8. **Один тестовый гейт (`game_test_3d_scene.tscn`) имеет известную
   особенность окружения** — процесс не завершается сам после печати
   результатов (не баг игры, баг жизненного цикла процесса в этой
   песочнице), из-за чего им неудобно пользоваться без `tasklist`/
   принудительного завершения. Не блокирует разработку, но стоит
   один раз разобраться, если будет время.

---

**2026-09-08 (FULL AUTONOMY, NO-GODOT static-audit pass):** owner
mandated a defect hunt verified entirely by code tracing — no Godot
binary run at all this pass (a prior pass's `--editor --quit` had
silently corrupted `default_bus_layout.tres`; this mode removes that
risk class entirely). Used 3 parallel Explore subagents (power grid/
emissive windows; save+load/endings; settings+i18n screen sweep) plus
my own tracing (boot order, loot flow, skill tree all 4 branches,
journal/world-bible, radio). Full register with file:line evidence:
`docs/STATIC_AUDIT.md`. Player-facing summary + a 5-minute manual check
list: `docs/PLAYER_VISIBLE_CHANGES.md`.

Headline finding: **8 of 18 skill-tree skills across all 4 branches
were purchasable (real skill-point cost) but did literally nothing** —
`damage_boost_1/2`, `crit_chance`, `fire_rate`, `reload_speed` (combat),
`health_regen`, `light_radius` (survival), `loot_luck` (utility). Three
more (`max_health`, `stamina_boost`, `battery_capacity`) called player
methods (`set_max_health` etc.) that don't exist anywhere in the
codebase. And the root cause behind all "push once" skills losing their
effect on every Continue: `SkillTreeManager.load_data()` runs during
`SaveSystem`'s data-parse phase, before the player node exists, so its
effect-replay loop always no-op'd. All wired/fixed this pass — see
`STATIC_AUDIT.md` #2-#5 for the exact fix per skill.

Also severe: `ending_screen.gd` was a completely dead, never-shown node
whose `_unhandled_input` was nonetheless always live (its only guard
depended on a `Tween` that's never created) — every Escape press during
ordinary gameplay called `Endings.mark_ended()` and force-quit to the
main menu, racing the real pause menu on the same keypress. Fixed with
a one-line guard.

Decisions on what NOT to fix (would need a design call or a new system,
not a wire-up — documented in `STATIC_AUDIT.md`, not guessed at):
- Only 3 of 5 GDD endings (`light`/`hope`/`truth`) are reachable;
  `survivor`/`dark` are dead branches because `all_restored()` is
  always true by the time the ending evaluator ever runs, and death
  never triggers an evaluation at all. Needs a real design decision
  (when should "Survivor" fire? should death show a real "Dark" ending
  instead of the current static death screen?).
- `scripts/visual/emissive_windows.gd` (the live implementation) never
  reacts to district power stage at all — pure one-time randomness,
  contradicting its own design brief. A real fix needs per-instance
  MultiMesh color updates keyed by stage, not a one-line wire-up.
- GDD's PARTIAL stage ("some streetlights lit") isn't implemented in
  `streetlight_3d.gd` — PARTIAL looks identical to DARK. Same reasoning
  as the windows above.
- `content/districts/*/item_spawns.json`'s stage-gated tables/fixed-
  spawns are never read by any script; `district_loot.gd`'s own
  `REPAIR_PARTS` already guarantees the same solvability goal via an
  older, simpler, already-working flat mechanism. Wiring the JSON would
  mean building a new stage-aware spawn system to replace a working
  one — out of scope for a defect-fix pass.

Also fixed (major/minor, not skill-tree): a global lighting handler
reacting to every district's stage change instead of just the player's
current one; a renamed/removed inventory item id restoring as a
permanent ghost slot; `TOTAL_DOCUMENTS` (endings threshold) was a
hand-typed const that had already drifted stale after the suburbs/
residential/park lore-note additions, made "collect all documents"
trivial — now computed from the live spawn tables; save-slot UI always
showed "Level: 1" and the 1970 epoch date; two confirmed 100%-dead-code
no-ops deleted (a duplicate signal emit, an always-false sync
condition); 9 more UI files (found via a full sweep, not just the ones
flagged in earlier passes) fixed for live-language-switch retranslation
— `docs/KNOWN_ISSUES.md`'s list should now be genuinely complete.

Process note: caught and fixed one self-introduced bug this pass by
re-reading every edited function before committing (a mid-file edit had
left an orphaned tail — the flashlight battery-bonus code — sitting
outside its function, referencing an undefined variable). With no
compile gate available in no-Godot mode, this manual re-read step is
now the only defense against exactly that class of mistake — treat it
as mandatory, not optional, for the rest of this mode.

---

**2026-09-08 ("merge arena" command, PR #3):** merged
`arena/01a08213-igra` — three districts at once (`school`, `hospital`,
`gas_station`) plus `docs/CONTENT_PIPELINE_AUDIT.md`, a static audit of
all 6 packs shipped so far. Scope-checked (content/**, docs/**, assets/
textures/** only, including two in-scope edits to already-merged
`suburbs`/`park` content files — verified those didn't rename any note
id my earlier wiring depends on), 8 JSON files validated, merged
`--no-ff`, 0 conflicts, static gates green, branch deleted.

Wired the same way as suburbs/residential/park: 24 new note ids added to
`district_loot.gd`'s `LORE_DOCS`, matching catalog entries generated via
a small one-off python script (not hand-typed — 24 entries with nested
`world_refs` arrays is exactly the kind of transcription work a script
should do). 48 keys × 13 locales translated directly, `i18n_audit.py`
confirms 0 missing.

Resolved both data facts Arena's own audit flagged as CODE's call
(full reasoning + evidence: `docs/STATIC_AUDIT.md` #21-#22):
- **school/gas_station power topology vs GDD §4.1**: verified NOT a bug.
  `data/districts/*.tres` already forms a branching, reconverging DAG
  (`industrial` needs BOTH `warehouses` AND `police`) that predates this
  session entirely; GDD §4.1's single arrow-chain is a narrative/display
  ordering, not a literal unlock-dependency spec. Left the `.tres` files
  untouched — rewriting them to force a strict chain would invalidate
  Arena's own already-shipped `world_refs` reveal-gate closures (computed
  against the real branching topology in `CONTENT_PIPELINE_AUDIT.md`
  §3.4), a much larger and riskier change than the "fix" would be worth.
- **`district_themes.gd` vs `music_manager.gd` music-row disagreement**:
  traced both to their actual call sites. `district_themes.gd`'s
  per-district `"music"` key is read by nothing anywhere in the
  codebase (confirmed dead — its own values were suspicious copy-paste,
  5 districts sharing one file). `music_manager.gd`'s `AMBIENT_BY_
  DISTRICT` is itself a documented-unreachable fallback, since
  `AMBIENCE_DARK_BY_DISTRICT`/`AMBIENCE_LIT_BY_DISTRICT` already cover
  all 11 districts and are what actually plays. Reconciled by deleting
  the dead field rather than picking a "winning" value nothing would
  ever read — the one true source of per-district audio stays the
  `AMBIENCE_*_BY_DISTRICT` pair.

Also surfaced (not fixed, logged as `STATIC_AUDIT.md` #24): Arena's own
`park_note_05` fix exposed a real imprecision in `WorldBible.is_revealed()`
— it checks `stage >= min_stage`, and every district defaults to `DARK`
(0) whether visited or not, so a `min_stage: 0` reveal is trivially true
for a district the player hasn't reached. Not a live bug today (content
authoring discipline — §3.4's reachability rule — is the actual guardrail,
and it's followed correctly in all 6 shipped packs), but a real gap in
the primitive itself if a future pack or a UI feature ever trusts it
without also checking district visitation. Deferred rather than risk an
uncompiled change to a lookup two live features depend on.

`ARENA_NEXT_PROMPT.md` updated to queue `police` (district 7, GDD §4.1),
with its own reachability closure spelled out explicitly (`suburbs +
park` only) so the next Arena pass doesn't have to rediscover the same
rule the audit caught park breaking once already.

---

## В. План работ по порядку

### Этап 1 — decisions needed (дизайнерские решения, не код)
Эти три пункта блокируют реальную работу, а не могут быть решены
программистом в одиночку — нужен ответ от вас, прежде чем делать любой
из пунктов Б.2/Б.3/Б.7:

- [x] Что должна делать 4-я ветка скилл-дерева? (Б.3) → **DECIDED: Stealth branch** (noise/visibility stats)
- [x] Какие меши считать «стеной» для окон? Или отложить фичу вообще?
      (Б.2) → **DECIDED: only building-facade meshes**, exclude street props
- [x] Судьба lobby/save-slots экранов: подключить или архивировать? (Б.7) → **DECIDED: archive** (document as intentionally dead)

### Этап 2 — измеримые технические задачи (можно делать без дизайн-решений)
- [x] Пересчитать реальный i18n-backlog заново — done, see Б.4 table (~3424 strings, no code change).
- [x] Превратить `perf_check_scene.tscn` в настоящий гейт. Done: commit `7c76569` (гейтит D11<350; headless честно SKIP, реальная проверка требует --windowed).
- [x] Задокументировано: D1<200 остаток = монстры (6) + подбираемые
      предметы (12), обе причины требуют дизайн-решения или глубокого
      батчинга, не быстрой правки. См. п.1 выше и `docs/KNOWN_ISSUES.md`.

### Этап 3 — контентная работа (после Этапа 1, зависит от решений)
- [x] Реализовать 4-ю ветку скилл-дерева. Done: commit `b861b14`.
- [x] Эмиссивные окна — уже исправлены до этой волны (commit `c917ab1`), проверено.
- [x] Перевести i18n-backlog — ЗАВЕРШЕНО. 8 коммитов, 3424 → 165 строк
      (все оставшиеся — проверенные легитимные когнаты, не пробелы).
      Детали и коммиты см. Б.4 выше.

### Этап 4 — релиз (только человеческие шаги, не могу выполнить сам)
Полный пошаговый чек-лист теперь в **`RELEASE_CHECKLIST.md`** (корень
репозитория) — что кликать, в каком порядке, с исправленными местами
(package name, готовые Web/Windows пресеты).
- [ ] Сгенерировать релизный keystore, заполнить `export_presets.cfg`.
- [ ] Получить и вписать реальный AppLovin SDK-ключ.
- [ ] Опубликовать `docs/PRIVACY_POLICY.md` по стабильному URL.
- [ ] Проверить реальный Web-экспорт (шаблоны теперь нужно только
      установить в редакторе — пресет уже есть в `export_presets.cfg`).
- [ ] Проверить реальный Windows-экспорт (аналогично — пресет готов).
- [ ] Первая загрузка в Play Console (открытое тестирование).

### Финальная проверка — ЗАВЕРШЕНО 2026-09-08 (автономная волна)
- [x] Полный прогон всех гейтов: `tools/check.sh --static` 10/10,
      compile/signal-arity/autoload-api/i18n/asset/save-integrity/
      footstep/audio-hum все `fails=0`/`bad=0`, `boot_check_scene.tscn`
      (`--windowed`) `fails=0` чистый прогон меню→новая игра→60с
      геймплея→сейв→выход→загрузка, `perf_check_scene.tscn`
      `draw_calls=234` (D11<350 OK). `default_bus_layout.tres` не
      тронут за всю волну.
- [x] Обновлён `docs/HANDOFF.md` реальным состоянием (новая секция
      "Latest phase" вверху, история ниже не тронута).
- [x] Итоговый отчёт — см. коммит-сообщение финального коммита этой
      волны и `RELEASE_CHECKLIST.md`.
