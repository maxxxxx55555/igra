# STORE-SYNC CERTIFICATE — THE LAST STREETLIGHT (2026-09-13)

Owner: CONTENT+ASSETS+STORE agent, pass-name **store-sync**. Scope: final Play-Store
sync at **RELEASE CANDIDATE FINAL v2** — `store/listing.md`, `store/press-kit.md`,
`store/changelog.md`, `store/privacy-policy-template.md`,
`store/screenshot-plan-detailed.md`, this certificate, `docs/artifacts/store-sync/**`.
Method: static + script verification only (standing **NEVER-GODOT** policy: no engine
run, no window opened; every number below was re-derived from shipped data/code on
2026-09-13, not quoted from memory). Verification scripts and their raw outputs:
`docs/artifacts/store-sync/verify_listing.py` and `verify_paths_and_numbers.py` — run
together, raw combined output recorded in `docs/artifacts/store-sync/verify_all.out`
(`verify_listing.out` holds the listing pass standalone) — independent re-checks
re-runnable by the owner.

**Verdict: PASS — claims verified 25/25, locale parity 13/13, 0 defects.**
**Zero-vaporware rule: the listing states only what the shipped build does; unbacked
forward promises were deleted, not softened.**

## 1. Claim → source cross-table (full description + bullets + data safety, EN master; RU + 11 locales mirror 1:1 — parity proven in §2)

Each row = one verifiable statement in the FINAL `store/listing.md`. "Where" is the
evidence a reviewer can re-run today. No row rests on intent, roadmap, or an
unmerged branch.

| # | Claim as now written on the page | Where verified (shipped) | Status |
|---|---|---|---|
| 1 | Setting: blackout city, "Architect Project" disaster, permanent night | `docs/GDD.md` canon; 88 lore notes across 11 districts; `store/trailer.md` | ✅ backed |
| 2 | "one flashlight, a fading battery" | `data/balance/flashlight_stats.tres`, `data/items/battery.tres` | ✅ backed |
| 3 | 11 connected districts, one continuous city, no level-select | `data/districts/*.tres` = 11; chain `docs/ARENA_NEXT_PROMPT.md`; City Map = view/travel UI, not level-select | ✅ backed |
| 4 | Every restored district stays lit (light as reward, map fills in) | `DistrictData.Stage` ladder DARK→FULL, never down-stages (PLAN conformance table) | ✅ backed |
| 5 | 12 enemy types, each with own senses/weaknesses/behaviour | `scripts/enemies/*_3d.gd` = 12 (incl. boss), `data/monsters/*.tres` = 12, resistances in `data/balance/enemy_stats.tres`; PLAN table "12 типов врагов … Работает" | ✅ backed |
| 6 | 5 endings decided by how much city + truth you recover | `scripts/systems/endings_manager.gd` enum (5); `tools/qa_sim/endings_sim.py` PASS — "all 5 GDD endings reachable" (`docs/artifacts/final_gate_report.md`) | ✅ backed |
| 7 | 13 fully localized languages | `data/i18n/*.json` = 13; `tools/i18n_audit.py` → "tr() keys used: 341 … MISSING: 0" (`final_gate_report.md`) | ✅ backed |
| 8 | 5-layer adaptive music that shifts with danger | `scripts/systems/music_manager.gd` `LAYERS` (ambient_dark/lit, threat_low/high, action; + rain/wind beds); PLAN: "Работает" incl. weather hooks wired | ✅ backed |
| 9 | Stealth built on noise + visibility, not a detection meter | `scripts/systems/noise_propagation.gd`, `base_monster.gd` DetectArea/vision checks; crouch line-of-sight tutorial panel (Batch 12) | ✅ backed |
| 10 | Crafting + workbench to upgrade the flashlight | `data/recipes/recipes.json` (12 recipes incl. `flashlight_upgrade`), `scripts/gameplay/craft_station.gd` + `scripts/ui/workbench.gd`, `FlashlightUpgradeManager` autoload | ✅ backed |
| 11 | Checksum-verified saves with automatic backup recovery | save-integrity gate PASS "incl. 50-mutant fuzz, export/import, backup-rotation, forgery" (`final_gate_report.md`); HMAC signing `docs/artifacts/security_report.md` | ✅ backed |
| 12 | New: 30 daily challenges, 31 achievements, New Game+ | `data/daily_challenges.json` templates = 30 (+7/30/100-day streaks); `achievements_manager.gd` = ach_01–20 + 11 district-full = 31; `data/ng_plus_config.json` + Batch 13 "One More Run" | ✅ backed (added) |
| 13 | Flashlight = "only weapon against some of what hunts you", reveals you when on | `base_monster.gd` `light_damage_per_sec` → FIRE damage under beam (select enemies only — the "some" is load-bearing and true); light also draws attention per stealth system | ✅ backed |
| 14 | Touch: virtual joystick + buttons + double-tap dodge | `player_3d.gd` double-tap dodge path (`_dodge_input_timer`, `isv.dodge_requested`); touch presets + calibration (Batch 15) | ✅ backed |
| 15 | PC: WASD+mouse, same game, same save file | `project.godot` input map; single save format across exports (save-integrity gate covers both) | ✅ backed |
| 16 | New: save export/import between devices, no account, no server | Batch 14 (`tls_save_export.json`), `docs/PLAYER_VISIBLE_CHANGES.md` | ✅ backed (added) |
| 17 | New: "whole city on day one — story, puzzles, lore, endings complete at launch" | content pipeline COMPLETE (11/11 districts merged+wired+translated, `docs/ARENA_NEXT_PROMPT.md`); cable-box puzzle rewards (Batch 7); `puzzle_economy_sim.py` PASS | ✅ backed (replaces removed promise) |
| 18 | No paywalled content, no season pass | no IAP SDK; `data/economy/shop_catalog.json` prices are in-game coins only; AdService grants no paid goods | ✅ backed |
| 19 | Fully offline | game code opens no connections; only INTERNET declared for the inert optional ad plugin (`export_presets.cfg`) | ✅ backed |
| 20 | Short description EN 70/80, RU 66/80 (hook + genre terms) | script `verify_listing.py` re-counts real `len()` vs labels — equal, ≤80 | ✅ backed |
| 21 | Titles ≤30 in all 13 locales, EN/RU byte-identical to shipped `menu_title`/`menu_subtitle` | `verify_listing.py` + `data/i18n/{en,ru}.json` diff (git: untouched) | ✅ backed |
| 22 | Tags/keywords incl. new ASO terms (blackout, flashlight, survival puzzle, story-driven, offline) | density audit per locale — §4 | ✅ backed |
| 23 | Data-safety: no account, no analytics, no data collected | privacy §2/§3 same facts; no analytics SDK in build | ✅ backed |
| 24 | Data-safety (rewritten): no multiplayer ships; AppLovin plugin inert w/o key, offline placeholder only; 2 permissions only | `scripts/ui/lobby_menu.gd` header "ARCHIVED … no button opens it"; `ad_service.gd` `_default_provider()` stub path; `export_presets.cfg` | ✅ backed (LAN claim DELETED as unbacked) |
| 25 | Category Action (secondary Adventure); *expected* PEGI 16, clearly marked as expectation pending IARC | owner-only IARC step `docs/artifacts/known_owner_only_items.md` §2; word "Expected" retained | ✅ backed |

**Deleted this pass (unbacked / vaporware):**
- "Free updates as the city gets built out further" (EN+RU+11 locales) — the city ships
  complete and `ARENA_NEXT_PROMPT.md` explicitly queues no expansion; a forward promise is
  exactly what "match shipped reality" forbids. Replaced by row 17's day-one-complete fact.
- "LAN multiplayer connects only to devices the player explicitly joins" (data-safety) —
  the LAN prototype is archived and unreachable from any UI; stating it as a feature was
  the single biggest vaporware item on the page. Row 24 now states the opposite truth.
- Press-kit "20 Achievements" — stale since Batch 13 (31 shipped; recount in §5).

## 2. 13-locale parity — 13/13

Recomputed by `docs/artifacts/store-sync/verify_listing.py` (raw output: `verify_listing.out`):
13 generated sections (en, ru, es, de, fr, it, pt_BR, tr, ja, ko, zh, zh_TW, ar); every locale
carries Title / Tagline / labeled Short / full description / 8 benefit-led bullets / ASO tags;
every `Short (N/80)` label equals the real string length; 0 over-limit; every WHAT'S-INSIDE
code-block list is 9 lines (8 original + the new daily/achievements line) in all 13 — the two
new facts exist in every language, wording transcreated from the shipped vetted vocabulary.
Repo gate `python3 tools/gen_store_listing_locales.py --check`: **GREEN**.
EN/RU title+tagline still byte-identical to shipped `data/i18n/{en,ru}.json`
(`menu_title`/`menu_subtitle`), which this pass did not touch (git diff clean — recorded §3).

## 3. EN/RU masters: what "byte-untouched" meant here, and the exact edit ledger

The in-game masters `data/i18n/en.json` and `data/i18n/ru.json` are **byte-untouched**
(`git diff --exit-code` → clean; consistent with Batch 11's masters-unchanged rule).
The **EN/RU store-copy master blocks** in `store/listing.md` were edited *only* where the
claim audit forced it — no stylistic rewrites. Ledger of every touched master line:

| Master line touched | Change | Forced by |
|---|---|---|
| Short-description char labels | `EN (71/80)` → `(70/80)`, `RU (~64/80)` → `(66/80)` | labels were numerically wrong; text bytes themselves unchanged |
| EN+RU full desc, WHAT'S INSIDE | +1 line: daily challenges / achievements / NG+ | row 12 |
| EN+RU full desc, CONTROLS | +save export/import clause | row 16 |
| EN+RU full desc, closing paragraph | "Free updates…" replaced by "THE WHOLE CITY ON DAY ONE / …" | rows 17–19; vaporware rule |
| Tags/keywords EN+RU | +3 keyword lines (story-driven, survival puzzle, offline horror, flashlight game / RU mirrors) | TASK 2 ASO |
| Data-safety block | LAN line deleted; ads line rewritten to stub truth; +permissions line; header re-dated to "confirmed against the shipped RC FINAL v2 build" | row 24 |
| Generated-block intro | pointer sentence updated to reference this cert | accuracy of the parity note |

Feature bullets (8) and every other master sentence are byte-identical to the pre-pass text.
Post-sync prefix (everything above the `BEGIN GENERATED` marker): recorded in
`docs/artifacts/store-sync/listing_master_prefix.sha256`.

## 4. ASO pass — method + density audit

Benchmarked current top mobile survival/horror/puzzle listings and 2026 Play-ASO guidance
(Google indexes title+short+full text; no hidden keyword field; 1 primary term in title,
1–2 natural keywords in short, long-tail woven a handful of times into the full text —
sources recorded in `aso-research.md`). Findings applied:

- Kept the 30-char titles as pure brand (brand + localization integrity > keyword stuffing;
  competitor horror hits do the same — the hook lives in the short line).
- Short lines already carry "stealth horror FPS" and stay untouched (70/80, 66/80).
- Wove, per locale, all five target terms **in-language and naturally** (once or twice, never
  as lists): flashlight / blackout / survival puzzle / story-driven / offline — closing
  paragraph now ends "…this blackout is a survival puzzle box, and the story is yours to
  drive." (EN) and mirrors in 12 more languages; tags/keywords section extended in EN+RU.
- Density audit: `verify_listing.py` requires each of the 5 keyword groups ≥1 hit and ≤9 hits
  per locale text (≈0.6% ceiling) → **13/13 in range, 0 stuffing flags**.
- No emoji/bullet-spam patterns were copied from ad-heavy competitors (our copy stays "short
  and atmospheric" per house rule).

## 5. Assets & numbers — path + count verification (TASK 3/4 verify-agent)

`docs/artifacts/store-sync/verify_paths_and_numbers.py` (output: `verify_all.out`):
**67 exact + 6 glob cited paths re-stat'd, 0 missing** across the five synced files; 27 PNGs
IHDR size-checked against filename claims (all 1920×1080 / 1080×1920 / 1600×900 / 1024×500 /
512×512 as named). Press-kit numbers recomputed from shipped data:
11 districts, 88 lore notes (8×11 recounted), 13 locales, 31 achievements, 30 challenges,
12 enemy scripts, 5 endings, 4 skill branches — **all reproduce**; release-state quotables
(10/10 static, 22/23 gates, MISSING: 0, 3–6 h, 11/11 autoplay) verified present in
`docs/artifacts/final_gate_report.md` before quoting.

`store/screenshot-plan-detailed.md` §0.5 status table marks, with exact filenames: ✅ 5 plan
shots + 3 touch shots already delivered in `store/screenshots/` (8/8 Play gallery slots filled
→ day-1 upload needs no capture), 🎨 trailer masters directly usable as *art* with the honesty
rule stated (never caption AI key-art as footage), ⛔ shots 3/4/6 + RU variants = in-game
capture only. Recipes updated (photo-mode no-write-PNG limit, composited-HUD disclosure,
pad-never-crop for phone aspect).

## 6. Residuals flagged, NOT defects of this pass (owner/CODE follow-ups)

1. **`tools/gen_store_listing_locales.py` is stale vs the listing** (it embeds the pre-sync
   closers + pre-polish bullet order; the 2026-09-11 manual polish had already diverged it).
   The `--check` gate is format-only and passes, but **do not run the generator without
   `--check`** or it will revert rows 17/12/18 and the bullet polish. Generator re-sync is
   CODE-owned → out of this pass's ownership; recommended as a one-data-structure update.
2. `docs/store/play_store.md` §Data-safety still carries the old LAN-multiplayer line
   (80–81); docs owner should mirror row 24. `store/trailer/README.md` file table matches
   disk (all 9 masters exist) ✅ no action.
3. Play Console-side only (unchanged, `known_owner_only_items.md`): keystore + signed AAB,
   IARC answers, 13-locale paste, privacy URL hosting with the 4 remaining `[email/URL]`
   placeholders filled, and the AppLovin key **decision** — if the key is ever set, re-run
   this sync because rows 18/24 and privacy §4/§5 must change with it.

**0 defects.** Verified claims: **25/25**. Locale parity: **13/13**. Skills applied:
yagni/ponytail (no new tooling — reused the repo's own gate), surgical-edit (master edits are
the audit-forced minimum), self-commit (4 commits, one per logical block), godot-gates
honored-by-record (engine gates quoted from `final_gate_report.md`, never re-run — NEVER-GODOT).
