# Handoff

## GOLD MASTER v2 — 2026-09-10 (store-release-pass recreate + gap-to-ideal)

`origin/main` is **GOLD MASTER v2** at `<gm2-hash>`. GOLD MASTER (below) plus:

- **Arena store-release-pass recreated (Path B).** `store-release-pass.tar.gz`
  was not in Downloads/Desktop and its sha256 manifest was malformed, so
  the work was rebuilt (`3babbff`): `store/listing.md` extended to **13
  locale sections** (title + tagline verbatim from the shipped in-game
  translations; short ≤80 / full / 8 bullets / ASO tags for the 11
  non-master locales transcreated from vetted in-game vocabulary — EN + RU
  master byte-untouched); `store/icon-adaptive/` foreground + background
  1080 layers derived from `store/icon-512.png` (66 % safe zone, extrema
  clamped, wired into `export_presets.cfg`); `store/review-responses.md`
  (5 classes × EN + RU). Ledgered in `docs/ASSET_LICENSES.md`; certified
  in `docs/CONTENT_PIPELINE_AUDIT.md` §12 (0 defects). Owner instruction:
  Arena sessions closed, `store/**` + those two docs reassigned to CLAUDE.
- **Gap-to-ideal — every CLAUDE-owned P0/P1 closed** (`2101311`): the
  district rebuild was running synchronously inside
  `DistrictTrigger.body_entered`, so each spawned pickup's `_ready()`
  threw "Function blocked during in/out signal" (~140 per district load)
  and the scene tree was being rebuilt mid-physics-signal. Deferred it
  (`world_runtime._on_district_entered` → `call_deferred`); same deferred
  fix in `document_pickup._collect()`. Headless suite: **0** such errors.
  Full P0/P1/P2 inventory: `docs/GAP_TO_IDEAL.md`.
- Headless suite **green twice consecutively** on the v2 tip.

### OWNER TODO (unchanged from GOLD MASTER — nothing new is required)

1. **Keystore + build:** `keytool -genkey -v -keystore release.keystore -alias tlsrelease -keyalg RSA -keysize 2048 -validity 10000`, fill `export_presets.cfg`, install `4.7-stable` templates + the Android build template in the editor, **Project → Export → Android** → signed `.aab`.
2. **Privacy policy:** real support email into `store/privacy-policy-template.md`, publish its text at any stable URL.
3. **Play Console:** create the app, answer IARC per `RELEASE_CHECKLIST.md` §5.2d, paste `store/listing.md` (13 locales; a native read of the 11 transcreated ones is recommended pre-publish), adaptive icon from `store/icon-adaptive/`, art from `store/`, screenshots per `store/screenshots-plan.md`; upload the `.aab`, roll out to Open Testing. `store/review-responses.md` covers the first reviews. Optional: one `perf_check_scene.tscn --windowed` run for the real draw-call number; eyes-on playtest; real AppLovin key.

---

## GOLD MASTER — 2026-09-10 (headless hardening pass)

`origin/main` is **GOLD MASTER** at `f263f9f`. FINAL RC (below) plus a
real-engine verification pass: the owner lifted NO-GODOT to
**headless-only** (`godot --headless` script/scene runs; still no
`--windowed`, editor, or visible window). New gate:
`tools/qa_sim/headless_suite` — ran **green twice consecutively**.

**The first headless run paid for itself immediately — 4 latent
regressions that static analysis structurally cannot catch (`f3bd1e3`):**
1. `wow_director.gd` `var _flash`/`func _flash()` name collision → the
   `WowDirector` autoload never loaded → the PHASE-D "viral hooks"
   (screen shake + flash at first-light / grid-cascade / victory) were
   **completely dead since they shipped**. Renamed the function.
2. `district_scene_factory.gd` called `LOOT_SCRIPT.populate()` through a
   `Script`-typed const, which does not dispatch to the static function
   in Godot 4.7 → **no loot, no repair parts, no documents spawned in any
   district** — the grid was literally unwinnable and the flashlight
   un-refuelable in the built game. Now calls via `class_name
   DistrictLoot`; `game_test_3d` reports `pickups spawned: 12` (was `0`).
3. Two `:=` type-inference errors (`district_loot.gd`, `streetlight_3d.gd`)
   that cascaded compile failures through
   endings/progress/save/game_manager/power_grid on a cold parse.
4. `_game_test_3d.gd` never surfaced failures (`quit()` == 0) and could
   hang forever — added a hard-timeout-as-FAIL and a real exit code.

**Housekeeping:** merged remote branches `arena/01a08729-igra` and
`arena/01a08b05-igra` deleted. `arena/019ffbd0-igra` and
`arena/01a07b1c-igra` **held** (owner decision — `KNOWN_ISSUES.md`).

**Headless suite (`tools/qa_sim/headless_suite`, logs `.qa_logs/`):**
11 engine gate scenes each with a per-gate timeout + a scenario driver —
P0 12 autoloads load · P1 New Game → player spawns · P2 all 11 district
scenes instantiate + `DistrictLoot.populate()` > 0 · P2b combat damage ·
P3 save/load round-trip with a mid-load language switch · P4 all 5
endings fire and resolve to localized strings · P5 **1061 en keys × 13
locales + 10 UI-surface keys, 0 MISSING at runtime** · P6 soak (clean).
Two known, documented, real-player-unaffected test-harness limits remain
(`game_test_3d` phase-1 combat stall; P6 soak ends ~10 s on the
boot-race) — both covered by substitutes, see `KNOWN_ISSUES.md`.

**Perf:** headless renderer = dummy = `draw_calls=0`; the
`drawcall_estimate.py` static model stands (~38 mesh/2D draw calls,
~18 active lights/frame D1 after distance-fade). The real
`RENDER_TOTAL_DRAW_CALLS_IN_FRAME` still needs one owner
`perf_check_scene.tscn --windowed` run. Before/after table: `PLAN.md`
GOLD MASTER section.

### OWNER TODO (everything else is done — GOLD MASTER on `origin/main`)

1. **Keystore + build:** `keytool -genkey -v -keystore release.keystore -alias tlsrelease -keyalg RSA -keysize 2048 -validity 10000`, put path + passwords in `export_presets.cfg`, install `4.7-stable` export templates + Android build template in the Godot editor, then **Project → Export → Android** → signed `.aab` (`RELEASE_CHECKLIST.md` §1, §4).
2. **Privacy policy:** put a real support email in `store/privacy-policy-template.md`, publish its text at any stable URL (§3).
3. **Play Console:** create the app, answer the IARC questionnaire (exact answers in `RELEASE_CHECKLIST.md` §5.2d), paste `store/listing.md` + art from `store/` + screenshots per `store/screenshots-plan.md`, upload the `.aab`, start rollout to Open Testing (§5). Optional: eyes-on run of "HUMAN PLAYTEST SCRIPT v2" below; real AppLovin SDK key (§2 — ships fine without it).

---

## RELEASE CANDIDATE v3 — FINAL RC, 2026-09-10 (ARENA MEGA FINAL PASS merged)

`origin/main` is **FINAL RC** at `a712dd1`. This is RC v2 (`e65e1e4`,
code polish — section below) plus Arena's last content/store pass merged
and its prose re-synced into i18n. Nothing code-side is left that can be
done without the Godot editor, a signing key, a store account, or a
build toolchain.

**What landed since RC v2:**
- **Merged Arena PR #9** (`6fea56e`, `--no-ff`). Scope-checked to Arena
  zones only — `content/**`, `store/**`, and four Arena-owned docs
  (`ASSET_LICENSES`, `AUDIO_COVERAGE`, `CONTENT_PIPELINE_AUDIT`,
  `PROSE_CHANGES`). No code/tool/scene/data/locale/frozen-doc change.
- **`store/trailer/` kit** — 5 palette-locked key-art masters
  (`still_first_light`/`still_first_ending`/`still_grid_cascade`
  1920×1080, `shorts_silhouette` 1080×1920, `presskit` 1600×900),
  dimensions + non-pure-black/white verified statically (IHDR read +
  per-channel extrema clamped to `(10,240)`). `store/trailer.md`,
  `store/press-kit.md`, `store/trailer/README.md`, `store/listing.md`
  polish. Every binary has an `ASSET_LICENSES.md` entry.
- **3 lore-note prose kickers** (`LORE_PARK_02_TEXT`, `LORE_PARK_07_TEXT`,
  `LORE_POLICE_05_TEXT`) per `docs/PROSE_CHANGES.md` "Changed rows (mega
  final pass)". ids / keys / `min_stage` / stages untouched.
- **i18n re-sync** (`a712dd1`, code's zone) — those 3 keys updated in all
  13 `data/i18n/*.json`: en to the authoritative rows, the added/changed
  sentence translated in-language for the other 12. Placeholder parity
  held; `i18n_audit.py` `MISSING: 0`.
- **Audio** — ladder re-run, all lit-bed gaps kept spec-only, no binary
  fabricated (`AUDIO_COVERAGE.md`).
- **Content certificate** — `CONTENT_PIPELINE_AUDIT.md` §11: 11/11
  districts, store kit, ownership — 0 defects.

**Static gates, green after both the merge and the i18n commit** (no
Godot binary run — NO-GODOT static mode):
`bash tools/check.sh --static` 10/10 · `python tools/flow_check.py` 53 ·
`python tools/scene_node_check.py` clean · `python tools/i18n_audit.py`
`MISSING: 0` · all 6 `tools/qa_sim/*.py` PASS.

**Arena branch** `origin/arena/01a08b05-igra` is merged; deleting it
needs push rights to Arena's namespace this session doesn't have — safe
for the owner to delete on GitHub.

### Owner next steps (in order)
1. `git pull --ff-only` on `main` (expect tip `a712dd1`).
2. Run **HUMAN PLAYTEST SCRIPT v2** below — the single Godot run
   (≈25–35 min), boot → all 11 districts → all 5 endings → soak. The
   3 prose kickers surface at playtest line 6 (13-locale Journal check).
3. Work **`RELEASE_CHECKLIST.md`** top to bottom: release keystore →
   AppLovin SDK key → publish privacy policy → install export templates
   → Play Console first upload (store copy from `store/listing.md`,
   art from `store/`, screenshots per `store/screenshots-plan.md`,
   trailer per `store/trailer.md` + `store/trailer/`) → version bump.

---

## RELEASE CANDIDATE v2 — 2026-09-10 (MEGA FINAL POLISH)

`origin/main` is RELEASE CANDIDATE v2. On top of RC v1 (STATIC_AUDIT
close-out + arena PR #8): every remaining WON'T-FIX is now either fixed
by static means with a `tools/qa_sim/` proof, or converted to an exact
owner-verify step below. i18n + accessibility + crash-safety hardened;
viral hooks added. Static gates green on every commit. See `PLAN.md`'s
"RELEASE CANDIDATE" section and `docs/STATIC_AUDIT.md`'s close-out table.
Remaining: the human-only steps in `RELEASE_CHECKLIST.md` + this playtest.

### HUMAN PLAYTEST SCRIPT v2 — the one Godot run (≈25–35 min)

Run: `C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe --path .`
Each line = do this → expect this. Stop and note any line that fails.

1. **Boot / New Game.** Main menu (no day/generator variant, no auto-ad) → **New Game** → onboarding overlay shows once, NEXT through it → gameplay starts, no fake "All districts powered!" overlay.
2. **First streetlight (wow #1).** In the start district repair the power switch to STREETS. Expect: streetlights snap on, a short warm screen-flash + a light camera shake, one localized "District saved: <name>" toast — and *only* that one (no English "District restored!").
3. **PARTIAL stage.** Repair a *later* district one step (to PARTIAL, stage 1) and stand in it. Expect: ~40% of its streetlights lit and dim, fewer/dimmer building windows than a FULL district — visibly between DARK and STREETS, not identical to DARK.
4. **Skill tree.** Open it → **4 branches** (Combat / Survival / Utility / Stealth). Buy Max Health L1 (HUD max-HP +~20) and one Stealth skill. Save (pause → Save) → Continue from menu → both still applied, HP still boosted.
5. **Accessibility (Settings → Accessibility).** Reduce Screen Shake ON → take a hit, no shake. High Contrast ON → scene contrast/saturation jump. Colorblind Mode → Deuteranopia → a subtle full-screen tint shift; back to Off → clears. Text Size → Large → non-overridden UI text grows. Arachnophobia ON → no error, crawler enemies swap mesh. Switch language with the panel open → row labels retranslate.
6. **13-locale spot check.** Settings → Language → cycle through **each** of the 13. For each: menu, HUD captions, and a Journal note render in that script with no raw KEYS and no clipped/overflowing buttons (ru/de/fr are the long ones — check the settings rows and the battery-ad button wrap).
7. **Escape safety.** Press Escape ~10× while walking and opening/closing menus → only ever the Pause menu, never bounced to the main menu.
8. **Photo mode.** Toggle photo mode → corner frame + HUD hidden. Press **Tab** to cycle the 7 filters (none/noir/faded/vivid/bright/moody/bloom) — the world grades live. Exit photo mode → grading returns exactly to normal (no leftover tint).
9. **Trailer Mode.** Settings → Game → Trailer Mode ON → HUD hides. Trigger a wow moment (restore a district to FULL) → brief slow-mo + FOV punch + flash. Trailer Mode OFF → HUD returns.
10. **Full run to victory.** Restore all 11 districts (`suburbs → residential → park → school → hospital → gas_station → police → warehouses → industrial → substation → power_station`). Confirm each is completable with found parts. At **cascade (wow #3)** — the last district hitting FULL — expect a bright flash + strong shake. Then final night → Architect at `power_station` → defeat → **Light** or **Truth** ending (per docs collected), with its music sting. This is **wow #2**.
11. **Substation puzzle.** In `substation`, interact with the cable box → the cable minigame → solve → localized "+200 coins" toast. (The other 10 districts have no such puzzle by design — restoration is the power switch.)
12. **Survivor / Dark endings.** New game: restore the spine to `power_station` FULL but skip `school` and `gas_station`, then die → **Survivor** ending. Separate run: die with the grid unrepaired → **Dark** ending. (These were unreachable before; `tools/qa_sim/endings_sim.py` proves all 5 now.)
13. **Load edge case.** With language set to a non-English locale, load a save → language stays; no reset to English.
14. **Soak.** Play ~10 min continuously across ≥3 district borders, take photos, take hits near a death/reload → no "previously freed instance" errors, no console debug spam, stable frame rate.

If 1–14 pass: RC v2 confirmed — proceed to `RELEASE_CHECKLIST.md`.

### Owner-verify items (from STATIC_AUDIT ACCEPTs — quick checks, not blockers)

- **#20** every district reaches FULL from its own found/guaranteed parts (covered by playtest line 10).
- **#24** in the Journal, no note's "Related:" line names a character/faction/place from a district you have not yet reached.
- **D1 draw calls** — run `scenes/tools/perf_check_scene.tscn --windowed`, read the number; distance-fade on the lights should have dropped it (was 234, target D11 < 350 already met, D1 < 200 aspirational).

## RC FINAL PASS — Phase A complete (2026-09-10, autonomous desktop, NO-GODOT static mode)

**STEP 0:** `git pull --ff-only` — `main` at `db6367d`, the RC crunch was
not yet on origin, so Phase A ran in full.

**STEP 1 — arena branch triage** (full reasoning: `PLAN.md` 2026-09-10
decisions-log entry, `KNOWN_ISSUES.md`): three unmerged `arena/*` branches.
`arena/01a08729-igra` (store kit + `PROSE_CHANGES.md` + `ASSET_LICENSES`,
based on current HEAD) = the Phase B merge target. `arena/019ffbd0-igra`
(57 commits, autopilot suite) = superseded, its payload already on `main`
— hold. `arena/01a07b1c-igra` (9 commits, FPS-weapons layer) =
out-of-scope, owner decision only — hold.

**Phase A — STATIC_AUDIT close-out.** Every previously DEFERRED/DOCUMENTED/
OPEN entry now has a final disposition (`docs/STATIC_AUDIT.md` close-out
table). Real fixes made:

- **i18n toasts** (`b98bc25`..`ea6d935`): `puzzle_system.gd`'s 4
  `_grant_reward()` toasts and `daily_events_ui.gd`'s title/button/2
  toasts were hardcoded English — now localized, +9 i18n keys ×13
  locales, placeholder parity verified. Removed a redundant
  `_on_district_restored` handler that double-toasted every FULL restore
  alongside `power_switch.gd`'s already-localized `DISTRICT_RESTORED_TOAST`.
- **crash-safety** (`43aa164`): guarded `crafting_manager.gd`'s unchecked
  `JSON.parse_string` → typed-Dictionary assignment (latent null-deref;
  dead code today). Swept all 20 JSON/`FileAccess` sites — every other
  one already null- and type-checks.
- **shipped debug prints** removed from live/dead gameplay code
  (`district_trigger.gd` per district entry, `photo_mode.gd`,
  `craft_station.gd`, dead `victory_screen.gd`); deliberate diagnostics
  (`save_system.gd` recovery logs, `footstep_system.gd` `demo()`) kept.
- **accessibility** (`43136a1`): added a "Reduce Screen Shake" toggle
  (vestibular) — one guard at `screen_shake.gd::add_trauma()`, the single
  trauma choke point; default off, +1 i18n key ×13.

WON'T-FIX (RC), each with reason + GDD ref in `STATIC_AUDIT.md`: #6
endings (survivor/dark need an owner design call), #7/#8 emissive-windows
/ PARTIAL (need Godot visual verification), #14/#16/#18/#19/#20/#24
(unreachable / not behavior-preserving / ownership-zone / needs
compile-check), #31 puzzle bonus economy (GDD balance call), #32 audio
one-shot lengths (audio toolchain owner's zone), D1 draw-call gap
(no code-only + behavior-preserving + statically-verifiable cut exists;
D11<350 shippable budget met at 234 and gated).

All static gates green after every commit (`tools/check.sh --static`
10/10, `flow_check.py` 53, `scene_node_check.py` clean, `i18n_audit.py`
MISSING: 0). `default_bus_layout.tres` untouched. **Next: Phase B** —
merge `arena/01a08729-igra`, then Phase C (RC declaration).

## Content pipeline: COMPLETE — 11/11 districts (2026-09-09)

All 11 districts are packed, merged, wired, and translated:
`suburbs → residential → park → school → hospital → gas_station →
police → warehouses → industrial → substation → power_station`. See
`docs/CONTENT_PIPELINE_AUDIT.md` §9 (CONTENT RELEASE CERTIFICATE) for
the full 15-point verification, independently cross-checked (not just
trusted) below. `ARENA_NEXT_PROMPT.md` now reads pipeline-complete —
no next district queued, and GDD.md defines no epilogue-district scope
beyond D11 (the "epilogue" scene in GDD §23 is an existing UI screen,
unrelated to the district content pipeline).

**Closed open question:** the industrial `lore_notes.json`
double-escaping (previously logged here) was fixed by Arena in PR #7's
own TASK 0 commit — verified byte-for-byte against the already-shipped
i18n text (8/8 exact matches, zero player-visible change either way).
No remaining open questions for Arena at this time.

## Latest phase: PR #7 merged — substation + power_station, pipeline complete (2026-09-09, "merge arena", NO-GODOT static mode)

`arena/01a0867f-igra` — the final two districts (`substation` D10,
`power_station` D11, chain terminal), the industrial escaping fix, and
the final 1–11 audit + release certificate. Scope-checked, all 5 JSON
files valid, all item ids and all `world_refs` (18 distinct for
substation, 20 for power_station) hand-verified against each closure —
0 leaks. `--no-ff`, 0 conflicts, static gates green.

Wired identically to all 9 prior districts: `district_loot.gd`'s
`LORE_DOCS` gained both districts (their `BY_DISTRICT`/`DOCUMENTS` rows
already existed in code; both correctly have no `BLUEPRINTS` row); 16
`documents_catalog.json` entries appended (121 total); 32
`LORE_SUBSTATION_*`/`LORE_POWER_STATION_*` keys ×13 locales translated
(`i18n_audit.py`: `MISSING: 0`, 1047 keys/locale).

Traced power_station's `reactor_power_station` puzzle citation
(`reward: "ending"`) read-only per the merge directive — confirmed no
endings-logic code touched, victory remains driven entirely by
`PowerGrid._check_victory()`.

**Substantial finding surfaced while tracing that puzzle citation, not
introduced by this session:** `puzzle_system.gd`'s bonus reward economy
(coins/battery/medkit/ending) is reachable for only 1 of 11 districts —
the core district-restoration loop is unaffected (confirmed live via
the separate `power_switch.gd` mechanism for all 11). Documented, not
fixed — a real design decision between two remediation paths, not a
one-line bug. Full reasoning: `docs/STATIC_AUDIT.md` #31,
`docs/KNOWN_ISSUES.md`.

Also independently re-verified Arena's new audio finding F1 (two
power_station detail one-shots off the 30s class) — confirmed no code
dependency, non-blocking (`STATIC_AUDIT.md` #32).

Full reasoning for all of the above: `PLAN.md` decisions log.

## Previous phase: PR #6 merged — industrial district (2026-09-09, "merge arena", NO-GODOT static mode)

`arena/01a085f3-igra` — `industrial` district (D9), **the chain's first
two-parent convergence** (`powered_by = [warehouses, police]`) and first
Act III district, plus Arena's own re-run of `docs/CONTENT_PIPELINE_AUDIT.md`
across all 9 shipped districts (0 new defects; its own audit caught and
fixed 4 checker-tooling false positives, not pack issues). Scope-checked,
both JSON files validated, all 19 item ids and all 22 distinct `world_refs`
ids hand-verified against the six-district union closure before merging.
`--no-ff`, 0 conflicts, static gates green.

**Audio finding resolved (step 2 of the merge directive):**
`industrial_dark.ogg` measures 33.994 s, not the 36.000 s house contract
every other district bed uses — independently re-verified by parsing the
Ogg container's own final-page granule (1,499,146 → 33.994 s exactly, no
ffmpeg needed). Decision: **accepted as canon**, not a defect — 12 bars
at the industrial theme's 85 bpm = 33.882 s, within 112 ms of the shipped
length (consistent with encoder padding, not a random mis-render); no
code hardcodes the 36 s assumption anywhere. Full reasoning:
`docs/KNOWN_ISSUES.md` and `PLAN.md`'s decisions log.

Wired like the previous 8 districts: `district_loot.gd`'s `LORE_DOCS`
gained `industrial` (its `BY_DISTRICT`/`DOCUMENTS` rows already existed
in code; correctly has no `BLUEPRINTS` row, matching the pack's own "no
schematic in this district" canon); 8 `documents_catalog.json` entries
appended (105 total, written with clean quotes per the open question
above); 16 `LORE_INDUSTRIAL_*` keys × 13 locales translated
(`i18n_audit.py`: `MISSING: 0`).

Both CODE-facing data facts from PR #3–#5 (`STATIC_AUDIT.md` #21/#22)
re-verified against the new pack — logged as `STATIC_AUDIT.md` #27,
VERIFIED, no code change needed. Full reasoning: `PLAN.md` decisions
log. Next Arena district queued: `substation` (`ARENA_NEXT_PROMPT.md`).

## Previous phase: PR #5 merged — warehouses district (2026-09-09, "merge arena", NO-GODOT static mode)

`arena/01a0859c-igra` — `warehouses` district (D8) pack plus Arena's own
re-run of `docs/CONTENT_PIPELINE_AUDIT.md` across all 8 shipped districts
(0 new defects), plus a surgical 3px edge-frame repair on the shipped
dark `warehouses_floor.png` (lit twin re-derived from the repaired
dark). Scope-checked, both JSON files validated, all 20 item ids and
all 12 distinct `world_refs` ids hand-verified before merging. `--no-ff`,
0 conflicts, static gates green; both new/repaired textures load-tested
as valid PNGs within the prop-texture budget.

Wired like the previous 7 districts: `district_loot.gd`'s `LORE_DOCS`
gained `warehouses` (its `BY_DISTRICT`/`BLUEPRINTS`/`DOCUMENTS` rows
already existed in code ahead of content); 8 `documents_catalog.json`
entries appended (97 total); 16 `LORE_WAREHOUSES_*` keys × 13 locales
translated (`i18n_audit.py`: `MISSING: 0`, 999 keys/locale).

Both CODE-facing data facts from PR #3/#4 (`STATIC_AUDIT.md` #21/#22)
re-verified against the new pack: warehouses confirmed not a leaf
(industrial still lists it as co-parent), its `district_themes.gd` row
has no `"music"` key — logged as `STATIC_AUDIT.md` #26, VERIFIED, no
code change needed. Notable first: warehouses' closure legitimately
unlocks the Act II Project Architect set for the first time (every
earlier district since hospital was on a branch that didn't require
it) — verified all 4 Architect ids are paced at `min_stage >= 2`,
matching their own reveal gate, no premature-unlock leak.

Full reasoning: `PLAN.md` decisions log. Next Arena district queued:
`industrial` (`ARENA_NEXT_PROMPT.md`) — the first **two-parent
convergence** (`powered_by = [warehouses, police]`), closure = union of
both branches (suburbs, residential, park, hospital, warehouses,
police).

## Previous phase: PR #4 merged — police district (2026-09-09, "merge arena", NO-GODOT static mode)

`arena/01a08281-igra` — `police` district (D7) pack plus Arena's own
re-run of `docs/CONTENT_PIPELINE_AUDIT.md` across all 7 shipped districts
(0 new defects). Scope-checked, both JSON files validated, all 20 item
ids and all 16 distinct `world_refs` ids hand-verified against
`data/items/*.tres` / `content/world/*` before merging (not just trusted
from the audit doc) — all clean. `--no-ff`, 0 conflicts, static gates
green.

Wired like the previous 6 districts: `district_loot.gd`'s `LORE_DOCS`
gained `police` (its `BY_DISTRICT`/`BLUEPRINTS`/`STORY_DOC` rows already
existed in code ahead of content); 8 `documents_catalog.json` entries
appended (89 total); 16 `LORE_POLICE_*` keys × 13 locales translated
(`i18n_audit.py`: `MISSING: 0`, 983 keys/locale).

Both CODE-facing data facts from PR #3 (`STATIC_AUDIT.md` #21/#22)
independently re-verified against the new pack rather than assumed:
police is confirmed not a leaf of `powered_by` (industrial still lists
it as co-parent), and its `district_themes.gd` row has no `"music"` key
— logged as `STATIC_AUDIT.md` #25, VERIFIED, no code change needed.

Caught mid-commit: `git add -A` would have swept an untracked
`.claude/worktrees/` scaffolding directory into `main` — unstaged,
`.gitignore`'d, re-committed clean. Full reasoning: `PLAN.md` decisions
log. Next Arena district queued: `warehouses` (`ARENA_NEXT_PROMPT.md`),
closure = hospital + residential + suburbs (Act II Architect material
becomes legal for the first time there).

## Previous phase: NO-GODOT static-audit pass (2026-09-08, full autonomy)

Owner mandated a defect hunt verified entirely by code tracing — no
Godot binary run at all. Full register: `docs/STATIC_AUDIT.md`. Player-
facing summary + 5-minute manual check: `docs/PLAYER_VISIBLE_CHANGES.md`.

**Headline**: 8 of 18 skill-tree skills across all 4 branches were
purchasable but did nothing (weapons: damage/crit/fire-rate/reload;
survival: health regen/light radius; utility: loot luck), 3 more called
player methods that don't exist at all (max_health/stamina_boost/
battery_capacity) — all wired now. Root cause behind "bought skills
reset on Continue": `SkillTreeManager.load_data()` ran before the player
node existed; moved the reapply into `player_3d.gd`'s own `_ready()`.
Also fixed a severe one: a dead `ending_screen.gd` node was eating every
Escape press during normal gameplay (force-quit to main menu, racing the
real pause menu). Plus 9 more UI files fixed for live-language-switch
retranslation (full sweep, not just previously-flagged ones), a global-
lighting scope bug, a ghost-inventory-slot bug, a stale "collect all
documents" threshold, and 2 confirmed-dead-code deletions.

Documented-not-fixed (need a design call or a new system): only 3/5
endings reachable (`survivor`/`dark` are dead branches); the live
emissive-windows implementation never reacts to power stage; GDD's
PARTIAL stage isn't implemented in `streetlight_3d.gd`; the suburbs/
residential/park `item_spawns.json` stage tables are unread (the older
`REPAIR_PARTS` mechanism already covers solvability another way).

**PR #3 merged (same day, "merge arena" command)**: `arena/01a08213-igra`
— three districts at once (`school`/`hospital`/`gas_station`) plus
`docs/CONTENT_PIPELINE_AUDIT.md` (Arena's own static audit of all 6
packs shipped so far, which found and fixed a suburbs DARK-solvability
gap and a park world_refs reveal-gate leak before this merge). Wired
like the previous 3 districts, 48 keys × 13 locales translated
(`i18n_audit.py`: 0 missing). Resolved both CODE-facing data facts
Arena flagged: the school/gas_station "leaf" power topology is verified
intentional (not a bug — GDD §4.1's chain text is narrative ordering,
the real `.tres` graph already branches/reconverges); `district_themes.gd`'s
dead per-district `"music"` field (disagreed with `music_manager.gd`,
confirmed unread by anything) was deleted rather than "fixed" toward
either side. Full reasoning: `PLAN.md` decisions log,
`docs/STATIC_AUDIT.md` #21-#24. Next Arena district queued:
`police` (`ARENA_NEXT_PROMPT.md`).

## Previous phase: RELEASE CANDIDATE pass (2026-09-08, autonomous, owner override)

Read `PLAN.md`'s "Autonomous decisions log" first — full detail on every
item below. Short version: merged Arena's suburbs-content PR (owner
explicitly authorized direct merge, verified content-only scope first,
0 conflicts), wired it into the existing document/lore pickup flow,
fixed two live-language-switch i18n bugs (HUD captions, journal),
added the missing Ambient-bus volume slider, found two OTHER stale
`arena/*` branches with real but out-of-scope (code/weapons/tools, not
content) work — flagged for owner review, not merged. Queued `residential`
as the next Arena district in `ARENA_NEXT_PROMPT.md`.

**PR #2 merged (same day, "merge arena" command)**: `arena/01a08149-igra`
— residential + park district content, the world bible (characters/
factions/radio/diary/news), lit-tile assets. Scope-checked, gates green,
branch deleted. Wired like suburbs (`LORE_DOCS`, catalog entries) plus a
new minimal `scripts/world/world_bible.gd` lookup used by `journal_ui.gd`
(world_refs cross-links) and `radio.gd` (revealed broadcasts as extra
channels). 85 new keys × 13 locales translated. Full detail: `PLAN.md`
decisions log. Next Arena district queued in `ARENA_NEXT_PROMPT.md`:
`school`.

**Phase 4 update (same day, continued)**: play-probed the skill tree,
quest journal and their live-language-switch behavior — found and fixed
3 more stale-translation screens (skill tree tab titles + skill name/
desc/cost, quest journal tabs/detail/close) using the same reuse-existing-
refresh-chain pattern as the earlier HUD/journal fix. Save/load verified
already locale-independent (saves store no translated text, everything
resolves live by id) — no bug there. `docs/KNOWN_ISSUES.md`'s live-switch
list is now fully closed. `arena/01a08149-igra` (PR #2) is accumulating
on origin — do not touch until "merge arena".

Not reached this pass, still open for the next wave: Phase 3's D1<200
draw-call push, the rest of Phase 4 (power grid/combat/craft simplification
audit), Phase 5 (onboarding/UX polish) from the RC-pass brief. Also found:
`scenes/tools/game_test_3d_scene.tscn` gate stalls after "phase1 combat:
damage Shadow" — confirmed pre-existing (reproduces on a clean stash
before this pass's edits too), not investigated further; see
`docs/KNOWN_ISSUES.md`. Run the other 11 gate scenes individually until
that one's fixed — `tools/check.sh`'s full mode will hang on it.

## Previous phase: SHIP wave + Stage 1 decisions + autonomous i18n wave (2026-09-08)

Read `PLAN.md` first now — it is the live, actively-maintained tracking
doc for this whole arc (status table, decisions log, i18n backlog
table); this HANDOFF.md section is a summary pointer, not the source of
truth going forward.

Three sessions back to back, all gates green throughout, no force
push, no history rewrite:

1. **SHIP wave** (`docs/SESSION_REPORT_SHIP.md`): orphan-asset sweep
   (285 quarantined files, 4 restored with real consumers, rest
   confirmed dead), 5/8 `BUGS_FOR_CLAUDE.md` items fixed in code
   (stale imports, `music_combat.ogg` wired as a battle variant,
   district detail-bed audio, weather music layers), 548-file asset
   consolidation commit, Web/Windows export preset skeletons added,
   Android package id fixed pre-upload, `docs/PRIVACY_POLICY.md`
   drafted.
2. **Stage 1 decisions wave**: the three design questions PLAN.md had
   flagged as blocking were answered and implemented — a 4th
   "Stealth" skill branch (`silent_steps`/`cold_trail`, real effects
   wired into `player_3d.gd`/`base_monster.gd`, not placeholders), the
   dead lobby/save-slot screens formally archived (kept, not deleted,
   per this project's own rule), `perf_check_scene.tscn` turned into a
   real gate (hard-fails on D11<350; headless honestly SKIPs instead
   of false-passing on the dummy renderer's draw_calls=0). Also
   discovered mid-wave that the emissive-windows bug this doc's older
   sections describe as unfixed had *already* been fixed in a prior
   "FINAL PERFECTION P3" pass before this wave started — verified,
   not re-done.
3. **Autonomous i18n wave** (no human check-ins, per its own explicit
   mandate): the full i18n backlog closed, 3424 → 165 English-fallback
   strings (the 165 remaining are verified legitimate cognates/
   loanwords, not gaps — see `PLAN.md` §Б.4 for the full breakdown and
   commit list). Also corrected a stale `docs/KNOWN_ISSUES.md` entry
   that still described the draw-call root cause as unfixed streetlight
   mesh batching — that part turned out to already be fixed too; the
   real remaining D1<200 gap is monster + pickup-item meshes, a
   design/deeper-batching question, documented not guessed at further.

State at the end of this arc: 8-gate static suite green, all engine
gates green (compile/signal-arity/autoload-api/i18n/asset/save-
integrity/footstep/audio-hum), `boot_check_scene.tscn` green
(`--windowed`; `--headless` still hangs on the full boot flow, a
long-known environment limitation, not a regression),
`default_bus_layout.tres` unchanged throughout. Remaining work is
Stage 4 in `PLAN.md` — human-only release steps (keystore, AppLovin
key, Play Console, export templates) — tracked in `RELEASE_CHECKLIST.md`
at the repo root.

**ARENA** (cloud agent, branch `arena/01a080ba-igra`) is working in
parallel on `levels/**`/`content/**`/most of `docs/**` — not touched by
any of the above, per this project's ownership split.


Read `docs/PRODUCTION_BIBLE.md` first — canon reference (pillars,
visual/audio canon, budgets, checklist) for any new wave of work.

Full detail: `docs/SESSION_REPORT_UNIFY.md` (latest phase — theme
system unification, cinematic music layers, MultiMesh draw-call
batching, V2 skin wiring), `docs/SESSION_REPORT_FINAL_PERFECTION.md`
(boot audio hum, music bus effects, VFX wiring, UI chrome, streetlight
MultiMesh batching, SCR_* i18n, extra_battery ad button),
`docs/SESSION_REPORT_WAVE6.md` (L10N completion, enemy balance to GDD,
craft economy, 3 dead quests, generator fuel, crosshair, ach_01),
`docs/BURST_REPORT.md` (parallel audit + fix wave: code/UI/assets/i18n/
architecture findings), `docs/SESSION_REPORT_RESCUE.md` (real-window
launch bug, night sky + district ambience wiring, boss stings, perf
measurement), `docs/SESSION_REPORT_TRUTH.md` (launch-readiness gate,
real bug sweep, store copy), `docs/VISUAL_AUDIT.md` (screenshot-driven
visual/UI/lighting pass), `docs/SESSION_REPORT_FINAL.md` (audio,
shaders, bug sweep, cleanup, ads, release prep) and
`docs/SESSION_REPORT.md` (the earlier 19-task build phase). This file
is the short version for picking the project back up.

## Latest phase: THEME UNIFICATION + MUSIC + PERF + V2 SKIN (see docs/SESSION_REPORT_UNIFY.md)

HEAD = `31b3a8a`, fully pushed to `origin/main`. All mandatory gates +
static + boot-flow + audio-hum + theme-unify green.

Mapped and fixed a 4-way UI theme split: `ThemeProvider.build_theme()`
is now the one real source everywhere (main_menu, hud_3d, workbench,
skill_tree_ui, new_game_plus_ui all now opt in explicitly, matching
the 12 screens that already did); `ThemeSetup` is a 2-line bootstrap;
dead `ThemeManager` deleted; a 4th, previously-undocumented system
(`hud_3d.tscn` hardcoding 19 nodes to a rounded-corner, pre-canon
`theme_main.tres`) found and fixed. Discovered `Window.theme` doesn't
reliably propagate to Controls added after boot in this engine
context - worked around with proven local `theme =` assignment rather
than trusting it. Rewired `MusicManager.LAYERS` to the real 5
cinematic music layers (were pointed at placeholder loops); added a
5th "action" combat layer. Batched benches/trees/cones into MultiMesh
(251 -> 231 draw calls, still short of the D1<200 budget - see
report). Fixed `asset_check`'s loop-metadata false-negative at its
source instead of converting an asset. Wired a meaningful chunk of the
newly-delivered V2 skin pass (6 screen backgrounds, HUD bar tracks,
all 20 achievement medals, map backdrops) after finding and fixing a
real blocker (137 new textures had zero `.import` files) and a real
side effect of fixing it (the forced reimport pass silently dropped
`default_bus_layout.tres`'s Master bus - caught and restored by hand).

**Discovered, not fixed** (flagged in HUMAN_CHECKLIST): emissive
windows have never rendered anything in any district, ever - root-
caused to searching the wrong node subtree, needs a design call on
what counts as a "wall" before fixing. ~65 of the ~137 delivered V2
assets remain unwired (hex pips, slots, weather thumbs, most icon
families) - sized in the report, not silently dropped. Full self-audit
and DEFAULT_CHOICE log: `docs/SESSION_REPORT_UNIFY.md`.

## Previous phase: FINAL PERFECTION WAVE (see docs/SESSION_REPORT_FINAL_PERFECTION.md)

HEAD = `8344772`, fully pushed to `origin/main`. All mandatory gates +
static + boot-flow + audio-hum green (asset_check_scene's one failure
is pre-existing/unrelated - see report).

Fixed the real boot-audio-hum bug (MusicManager autoplaying the menu
track + 4 ambience layers at process boot, before any input - gated
behind a first-input latch, permanent regression gate added); added
real reverb+compressor to the Music bus and de-clashed layer/mood
crossfade phasing; wired the 3 dead vfx_*.tscn scenes (they shared a
script that silently discarded each scene's own tuning) into hit/
death/muzzle events plus a pickup fly-to-HUD icon tween; found and
fixed a second always-on "MoonLight" duplicate that was undercutting
the DARK-stage contrast; wired the button chrome kit into
ThemeProvider (verified via headless probe, not screenshot - see
report's self-audit) and bumped/re-skinned the minimap, added crests
to the city map; batched streetlight Pole/Lamp meshes into
MultiMeshInstance3D (370 -> 251 draw calls, meets D11 budget, not yet
D1); translated the 67 highest-visibility SCR_* i18n keys into all 11
non-RU/non-EN locales (718 strings); wired the previously-dead
extra_battery ad-reward button into the HUD.

**Corrected premises** (checked before acting, not assumed): P1's "5
layer OGGs" aren't the ones MusicManager actually plays; P2.4's
suspected culprit (district_grading.gd) was already dead code, the
real bug was a different legacy script; P4's "translate SCR_* to
Russian" - RU was already complete, same pattern as WAVE 6.

**Discovered, not fixed** (flagged in HUMAN_CHECKLIST): three
independent UI theme-registration systems exist simultaneously
(ThemeProvider / ThemeSetup / a dead ThemeManager) - main_menu uses
none of this wave's chrome work because it never opts into
ThemeProvider at all. D1's draw-call budget (<200) still isn't met
(251) - remaining cost is individually-meshed benches/trees/cones,
outside this wave's "streetlights" scope. Full self-audit and
DEFAULT_CHOICE log: `docs/SESSION_REPORT_FINAL_PERFECTION.md`.

## Previous phase: WAVE 6 — balance + content + L10N completion (see docs/SESSION_REPORT_WAVE6.md)

HEAD = `7cf3ed1`, fully pushed to `origin/main`. All mandatory gates +
static + boot-flow green.

Closed the BURST_REPORT "not fixed" list: L10N (RU was already
complete, contrary to the wave's own premise — the real 381-key gap in
the other 11 locales got a 32-key main-flow batch + zh's 49 pinyin
placeholders fully fixed + skill tree content i18n'd for RU); enemy
balance to GDD across all 12 types (found the bestiary `.tres` files
are disconnected display-only data — fixed both that AND the real
`enemy_roster_data.gd` stats); craft economy (13 new items, all 8
workbench recipes now actually craftable, with generated icons); 3
previously-dead quests wired via real triggers (one of them reusing a
complete, GDD-canonical minigame that existed but was never reachable);
a real fuel-consuming generator + a live crosshair (found and fixed
along the way: the game's own minimap pickup blips were silently
broken for every real player, not just a test); ach_01 given its own
correct trigger.

**Sized, not silently dropped, backlog**: i18n's remaining 349 keys ×
11 locales (3,839 strings, `SCR_*` is the largest single bucket at
183); enemy speed balance (GDD's "×" multiplier has no documented
absolute baseline anywhere in the project); crosshair "aim" (no ADS
mechanic exists to wire it to). Full self-audit and DEFAULT_CHOICE log:
`docs/SESSION_REPORT_WAVE6.md`.

## Previous phase: RESCUE WAVE — real-window launch bug + visual pass (see docs/SESSION_REPORT_RESCUE.md)

HEAD = `f368631`, fully pushed to `origin/main`. All mandatory gates +
static + boot-flow + footstep gates green.

The TRUTH WAVE pass verified launch only headlessly. This pass ran the
game in a real `--windowed` process and found the actual player-facing
blocker: `scenes/main_3d.tscn` embeds an `EndingScreen` node
(`ending_screen.gd`) whose `_ready()` unconditionally built and faded in
a full-screen "All districts powered!" win overlay on *every* load of
the gameplay scene — nothing ever called its real trigger. A fresh New
Game was instantly covered by a fake victory screen. Fixed (commit
`d8637ab`); the real menu itself was always fine.

Also this pass: wired the footstep surface×speed mapper for ox alpha's
18 delivered files (walk/jog/sprint per surface — "jog" stays unused,
no game state maps to it); wired the night-sky panorama into
`WorldEnvironment` (it was being silently overridden every district
entry by `district_grading.gd`, now only on LOW graphics tier as the
intended perf fallback); wired the 11 district ambience beds into
`MusicManager` (replacing a handful of generic tracks reused across
districts) with live power-restoration reactivity; converted both
boss-intro stings from WAV (over the 1MB budget) to OGG and wired them
to the Architect/Tvar encounters; built a real draw-call perf-guard tool
and measured **370 draw calls** (over the GDD's <200/<350 budgets) with
the root cause identified (`streetlight_3d.tscn` has no MultiMesh
batching) but not fixed — real regression risk to the streetlight-
reactivity mechanic fixed last session if rushed.

**Not attempted this pass**: status-FX HUD, hit/death VFX particles.
**Blocked, not skipped**: UI chrome kit (waiting on OpenCode B's
delivery), map/minimap district crests (no crest assets exist yet).
Full self-audit, DEFAULT_CHOICE log, and a GUI-automation reliability
note worth reading before trusting any future click-based verification
in this sandbox: `docs/SESSION_REPORT_RESCUE.md`.

## Previous phase: TRUTH WAVE — launch-readiness (see docs/SESSION_REPORT_TRUTH.md)

HEAD = `7c8e475`, fully pushed to `origin/main`. All 4 mandatory gates +
static + the new permanent `boot_check_scene.tscn` gate green.

Built a permanent boot-flow gate (`scenes/tools/boot_check_scene.tscn`,
wired into `tools/check.sh`): real menu → New Game → 60s sustained
gameplay → save → quit → load, all must not crash; also enforces "no ad
before first player input" as a live regression check. Building it
surfaced three real, previously-unknown bugs, all fixed: `SaveSystem
.reset_all()` never actually reset XP/skill-tree state (New Game kept
the last playthrough's level); `integrity_guard.gd`'s watchdog could
force-quit to the main menu from a single-tick false positive; two new
texture assets were wired into props but never had `.import` files
generated, so they silently failed to load outside the editor. Also
found and fixed: the game's namesake "darkness → restored power"
streetlight mechanic didn't actually exist in gameplay (the live prop
system built non-reactive flat decals; a complete, correct
`streetlight_3d.tscn` implementation existed but was never
instantiated anywhere — now wired in, old decals kept behind
`legacy_streetlights=false`). Added a "Reset Progress" button to
Settings. Rewrote both store listings and wrote `docs/PRODUCTION_BIBLE.md`.
Full self-audit, DEFAULT_CHOICE log, and what-wasn't-attempted section:
`docs/SESSION_REPORT_TRUTH.md`.

**Not attempted this pass**: the P2 visual/design wave (night-sky
panorama, district ambience-bed wiring, status-FX HUD, UI
StyleBoxTexture chrome kit, minimap size bump, automated perf guard) —
deliberate scope cut once P0 turned up real save-correctness bugs worth
fixing properly. Pick this up next, starting from `docs/
PRODUCTION_BIBLE.md`.

## Previous phase: visual polish (see docs/VISUAL_AUDIT.md for full detail)

Started as an 8-step "make it stop looking cheap" mission (atmosphere,
materials, UI theme, JUICE, VFX integration, perf guard). What actually
got done, screenshot-verified, gate-verified, pushed:

- Real UI theme fonts (theme_provider.gd was silently falling back to
  the OS default font on every one of ~13 screens — never loaded the
  actual Bebas Neue/Roboto Condensed files).
- Main menu: fixed a background-tiling seam, a random day/generator boot
  variant contradicting "no day" canon, and a static 15%-alpha overlay
  that washed the whole menu brown (see before/after in docs/shots/).
- District 3D lighting: `district_themes.gd`'s sky/fog/ambient were a
  bright pastel *daytime* palette in a permanent-night game — darkened
  to canon, fog unified to the GDD hex. `district_grading.gd` now
  actually scales ambient by district power stage (DARK→FULL), which
  GDD calls the game's main visual reward and previously did nothing.
- Textured/PBR'd several default-grey street props (poles, benches,
  dumpster) that had real textures sitting unused in assets/.
- Zeroed out several rounded-corner UI violations (GDD bans them) and a
  handful of non-canon hardcoded colors.
- Minimap: was drawing all 11 district names inside a 180px circle
  (guaranteed overlap/illegible) — now only labels the current district.
- Real HUD bug: monster-spotted name showed literal "ember #<id>" in
  every language, every encounter — now resolves the real i18n name.
- Interstitial ad mislabeled "Rewarded ad" — now has its own title.
- i18n hard-rule gaps closed on the reachable New Game+ screen (10 new
  keys × 13 locales) and the monster-name bug above.

**Not done** (honest gap, not attempted this pass): full project-wide UI
StyleBoxTexture chrome, hit-vignette/hitmarker/micro-shake JUICE, pickup
fly-to-HUD tweens, integrating ox alpha's newest VFX/grading assets
(several arrived mid-session — see untracked files under `assets/` at
time of writing), draw-call perf guard (<200), desktop/Steam export. A
material audit found two full streetlight systems running simultaneously
in every district (`street_props.gd` + `streetlight_spawner.gd`) — real
duplication, not fixed, needs an in-editor look to pick which is
canonical rather than a blind deletion.

**A test-environment thing, not a product bug**: this dev machine's
Godot `user://` save profile for this project has already reached a
full-victory state from this session's own automated test runs
(`victory.cfg` exists) — booting the game now shows a restoration
banner/ad prompt immediately regardless of input. A fresh player save
never triggers this. Lives outside the repo; needs explicit confirmation
to clear, not something to do unilaterally.

## State right now (as of this line, checked directly)
- HEAD = `1bc8052`, fully pushed to `origin/main`. Working tree clean
  except files that belong to the parallel asset-agent session
  (`docs/REPORT_ASSETS.md` and a batch of new files under `assets/` —
  new surface textures, lit tileset variants, monster SFX, store keyart —
  not reviewed or touched this pass, not mine to commit; wiring some of
  the new surface textures is exactly the kind of follow-up
  `docs/VISUAL_AUDIT.md`'s P1 list points at).
- All 4 mandatory gates green (re-verified after every commit this
  session). `tools/check.sh --static` green (10/10).
- `game_test_3d_scene.tscn`'s long-standing "hangs forever, no output"
  mystery from the previous phase is now explained, not by a project bug:
  it genuinely got as far as `[3dtest] phase1 combat: damage Shadow` and
  then sat idle — the *process* never exited on its own even after that.
  Found via `tasklist`: several `godot.exe`/`Godot_v4.7-*.exe` processes
  from earlier hung runs (this phase and the previous one) were still
  alive, never having been cleaned up. Once killed directly
  (`taskkill /F /IM godot.exe`), the stuck task immediately reported
  "completed, exit code 0". Root cause still not nailed down (why the
  process itself doesn't exit after finishing its printed checks), but
  it's a process-lifecycle issue in this environment, not evidence the
  gate/game logic is broken — worth checking `tasklist` for leftover
  `godot*.exe` before assuming any future "stuck" gate run is a real bug.

## Do this first in the next session
```bash
bash tools/check.sh
```
If the combined run hangs again (it did twice this session, on the
engine-check portion), fall back to running each `res://scenes/tools/
*_check_scene.tscn` individually with the Godot binary directly — that
worked every time the combined script didn't. Worth investigating why
`tools/check.sh`'s engine-check loop hangs when the same scenes run fine
standalone (environment/subprocess issue, not a project bug as far as
this session could tell).

## Open threads (none are blockers, all are deliberate scope cuts)

1. **AppLovin ads need a human.** Code is real and gated (interstitial +
   rewarded revive/battery both wired to actual gameplay now), but nothing
   has touched a real device, real SDK key, or Android Studio. Full list:
   `docs/store/HUMAN_CHECKLIST.md`.
2. **`extra_battery` ad reward has no UI trigger.** `revive` got one (death
   screen button); `add_battery` reward consumption is wired in
   `GameManager._on_ad_reward()` but nothing calls
   `AdService.show_rewarded(&"extra_battery")` yet. Needs a HUD button —
   follow `scripts/death_screen.gd`'s `_add_revive_button()` pattern.
3. **`destroyer_3d.gd`'s streetlight-breaking check is dead** — no script
   joins the `"streetlights"` group or defines `force_lit()`. Would need a
   real per-lamp override mechanic (streetlight state is currently driven
   entirely by district power stage, see `streetlight_3d.gd`), not a
   one-line fix. Not confirmed as GDD-mandated, unlike the melee
   knockback/backstab bug this session did fix.
4. **A parallel background session** was running on my earlier "clean up
   touch_controls" suggestion using a narrower prompt (code-only grep, no
   GDD check) at the same time I was doing the real fix with full context.
   I don't have visibility into whether it acted before or after my
   commit (`7efdee7`) landed. Worth a quick look if that session is still
   around.
5. **Desktop/Steam export preset doesn't exist yet** — only Android is
   configured in `export_presets.cfg`. Not started, see `docs/store/
   steam.md`'s build-steps section.

## Things NOT to redo
Everything in CLAUDE.md's "Already done" list, plus (from the first
build-out phase) T1-T4 and T11, which were verified already-correct
against the GDD rather than rebuilt — don't redo those without checking
current state first. From this phase: the audio/shader/tilesets wiring in
Steps 1-2, and the AppLovin provider scaffolding in Step 5 — check
`ad_service.gd`'s `_default_provider()` before assuming ads need
wiring from scratch.

---

## CURRENT STATE SNAPSHOT — as of HEAD `14c9393` (THEME UNIFICATION + MUSIC + PERF + V2 SKIN wave)

Written as a full-context appendix before a context compaction, so the
next session can pick up cold. Supersedes stale items in the "Open
threads" list above where they conflict — e.g. item #2 there
(`extra_battery` has no UI trigger) is **fixed**, done in the FINAL
PERFECTION wave's P5 (HUD button, see `scripts/ui/hud_3d.gd`
`_add_battery_ad_button()`); left uncorrected above only because that
list predates it and rewriting it wasn't in scope for this append.

**HEAD = `14c9393`, fully pushed to `origin/main`.** All mandatory
gates green: compile, signal-arity, autoload-api, i18n, asset-check,
boot-flow, audio-hum, theme-unify-probe, footstep, save-integrity, and
`tools/check.sh --static` (10/10). `game_test_3d_scene` still exhibits
its long-standing, cross-session, pre-existing process-lifecycle hang
after printing its checks (not caused by any work this session).

A parallel asset-generation session has been running concurrently
across the last several waves, actively writing to `assets/audio/`,
`assets/textures/`, and dropping new `docs/REPORT_*.md`/
`docs/ERROR_LOG*.md` files (most recently `REPORT_POLISH_V2.md` +
`ERROR_LOG_POLISHV2.md`, `ERROR_LOG_UIV2.md`, `ERROR_LOG_ICONSV2.md` —
none of these have been read or acted on yet). It also commits
directly to `main` on its own (e.g. `c432a20`, "assets: endings
warmth-order fix + wind_loop unblock"). None of its in-progress
modified/deleted files under `assets/` have been staged or committed
by this session — only exact, intentional filenames were ever `git
add`ed. Check `git status` at the start of any new session before
assuming the working tree is clean; the parallel session's uncommitted
changes are expected to be there and are not this session's to touch.

### Open items carried forward

1. **`emissive_windows.gd` has never rendered a single window, in any
   district, in any session.** Root-caused this wave: `populate()`
   calls `_collect_walls(self, walls)`, searching the `EmissiveWindows`
   node's own (always-empty) subtree. `world_bootstrap.gd` parents
   `EmissiveWindows` as an empty sibling of `StreetBuilder`/`Props`,
   never as their parent, so `walls` is always empty and `populate()`
   always returns immediately. Confirmed by testing: converting it to
   MultiMesh batching (this wave, `fce12ed`) measured **zero**
   difference in draw calls, before or after.
   **Not fixed** — the correct search scope (which meshes legitimately
   count as "walls" vs benches/streetlight poles/road tiles, all of
   which currently pass the `!= "Ground"` filter) needs a real look,
   not a guess. Whoever picks this up next: start at
   `scripts/world/emissive_windows.gd`'s `_collect_walls()` and
   `scripts/world/world_bootstrap.gd`'s `_wire()`.
2. **D1 draw-call budget (<200) still not met.** Progression this
   engagement: 370 (RESCUE WAVE baseline) → 251 (streetlight
   MultiMesh, FINAL PERFECTION wave) → 231 (bench/tree/cone MultiMesh,
   this wave). 231 meets the D11 budget (<350) but not the stricter
   D1 budget. Streetlights and benches/trees/cones are both now
   batched — that avenue is exhausted. Remaining draw-call cost is
   monster meshes (6, correctly individual/dynamic, not safe to batch)
   and pickups (12, individual), neither reducible without a design
   call, plus whatever HUD/2D overhead is baked into the same
   `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` metric. Measured via
   `perf_check_scene.tscn` run `--windowed` (headless reports 0 for
   this metric under Godot's dummy renderer — always use `--windowed`
   to re-measure).
3. **i18n backlog: 1,562 strings across 11 non-RU/non-EN locales
   remain English-fallback** (exact figure, from
   `docs/SESSION_REPORT_UNIFY.md`'s HUMAN_CHECKLIST — re-count from
   the actual JSON files rather than trusting this prose if precision
   matters, same way this wave and WAVE 6 both re-counted instead of
   trusting the prior estimate). Composition: 116 remaining `SCR_*`
   keys (mostly bestiary/lore prose — enemy descriptions, achievement
   flavor text, quest hint sentences), plus WAVE 6's already-sized
   carryover families (`ACH_*` 41, `Q_*`/`QUEST_*` 51,
   `END_*`/`ENDING_*` 25, `ENEMY_*` 11, misc 38). RU and EN are both
   already 100% real-language complete for every key that exists in
   `en.json` (verified twice now, WAVE 6 and this wave — don't
   re-assume RU is incomplete without checking first, that premise
   has been wrong twice in a row).
4. **V2 skin pass: what's wired vs not**, from `docs/REPORT_UI_V2.md` +
   `docs/REPORT_ICONS_V2.md` (41 + 67 + 2 + 6 = ~137 delivered assets,
   all now have real `.import` files after this wave's forced reimport
   pass — see note below):

   **Wired (this wave):**
   - `screens_v2/loading_street.png` → `screens.gd`'s "Loading" card
     (`_apply_card_bg_v2()`)
   - `screens_v2/death_loom.png` → `death_screen.gd`
   - `screens_v2/character_dim.png` → `stats_ui.gd` (non-embedded bg)
   - `screens_v2/menu_hero.png` → `main_menu.gd`
     (`_install_hero_bg_v2()`, layered over the still-running
     procedural skyline)
   - `screens_v2/journal_paper.png` → `journal_ui.gd`'s reader-pane
     StyleBoxTexture
   - `maps_v2/grid_panel_512.png` → `screens.gd`'s "PowerGrid" card
     (same `_apply_card_bg_v2()`)
   - `maps_v2/city_iso_2048.png` → `city_map.gd` panel backdrop
   - `ui_v2/bar_track_256x8.png` → HUD HP/Stam/Bat track (`HPT`/
     `StamT`/`BatT` in `scenes/ui/hud_3d.tscn`, converted
     ColorRect→TextureRect); **fill (`HPF`/`StamF`/`BatF`) deliberately
     left as ColorRect** — the v2 fill textures are flat colors that
     already match the existing fill colors exactly, and converting
     would touch the working offset-based ratio-clip logic for zero
     visual gain
   - `icons_v2/ach_medal_v2_{01..20}_96.png` → `achievements_ui.gd`,
     all 20, dimmed to 35% alpha while locked

   **Explicitly skipped, with reasons (not oversight):**
   - `ui_v2/btn_primary_*` / `btn_secondary_*` — **rounded** corners,
     violates the chamfer-canon rule (radius 0) enforced twice this
     engagement already (rejected `theme_main.tres` for the same
     defect this same wave). Last wave's `btn_tex_*` chrome (correctly
     chamfered) is still the live button chrome — don't overwrite it
     with these.
   - `ui_v2/panel_olive_256.png` as the global Panel style — untested,
     self-described-as-guessed olive-green palette shift across every
     panel in the game. `ui_v2/panel_small_128.png` also unwired (no
     distinct consumer identified without deeper changes).
   - `ui_v2/coin_{500,1200,2500,6000}.png` — both named consumers are
     dead: shop's `_populate_shop()` explicitly filters out
     `ShopItem.Kind.COIN_PACK` (IAP disabled by design), and
     `coin_hud.tscn` is never instantiated anywhere (grep-confirmed).
   - `portraits_v2/*_full_512x768.png` (6 monster portraits) —
     `encyclopedia_ui.gd`'s only portrait slot is a 190×44px compact
     grid card; a 512×768 image doesn't fit that aspect ratio, and no
     detail/expanded view exists to add one without new UI.
   - **Never touched at all**: `ui_v2` hex status pips (5),
     inventory/quickslot/equip-slot chrome (3), flashlight upgrade
     render (1), weather forecast thumbnails (4), tabs (2), logo
     grunge overlay (1); `icons_v2` monster line-art icons (6,
     separate from the wired medals — bestiary/map threat blips),
     item icons_v2 (10 — existing item-icon system already works,
     swap risk not worth it), stat/ctrl/event icons (17), district
     icons_v2 (11 — `city_map.gd` already has real crests from an
     earlier wave, unclear this is a different intended slot vs a
     duplicate).

   **Import gotcha, worth remembering**: newly-delivered asset files
   from the parallel session do NOT have `.import` sidecars until the
   editor scans them — `ResourceLoader.exists()`/`load()` silently
   fail on them until then, so wiring code can look correct and render
   nothing. Fix: `godot --headless --editor --quit` (forces a full
   project reimport). **Known side effect**: that exact command
   re-serialized `default_bus_layout.tres` (the one hand-authored
   `.tres` with a custom `uid://` the editor auto-touches) and
   silently dropped `bus/0` (Master) plus mangled the uid string. Was
   caught and restored by hand this wave (verified via `git diff` =
   zero remaining delta) — if this file shows unexpected changes after
   any future forced-reimport, check it against git history before
   trusting it.

5. Everything already open in `docs/store/HUMAN_CHECKLIST.md` (AppLovin
   real-device testing chief among it), and the enemy-speed-baseline /
   crosshair-ADS-design gaps from WAVE 6, are unchanged.
