# Size budget

`assets/` is 315MB across 1387 real files (2741 including generated `.import` metadata).

## Dead-asset manifest — methodology

Two independent static-reference passes, run this session:

- **Pattern A (full path)**: `grep -rhoE "res://assets/[A-Za-z0-9_./-]+\.[A-Za-z0-9]+"` across
  `*.gd *.tscn *.tres *.cfg *.json` (excluding `.import` files, which trivially "reference" their
  own source and would make every asset look used). Result: 190 unique full paths referenced.
- **Pattern B (basename)**: same corpus, basenames only, to catch dynamically-built paths that
  still reference a literal filename. Result: 190 unique basenames — no extra matches over
  pattern A, confirming basename-only references aren't hiding extra usage.

Raw diff (assets matching neither pattern): 878 basenames, 853 after filtering to media
extensions (png/ogg/wav/jpg/svg/ttf/glb).

**This raw number is not a deletion list.** At least 10 files build asset paths at runtime from
data (`String % id`, `DirAccess.list_dir`, etc.), which neither grep pattern can see — verified via
`grep -rlE 'assets/.*%s|assets/.*" *\+|DirAccess\.open.*assets|list_dir' --include=*.gd`:
`scripts/enemies/base_monster.gd`, `scripts/systems/audio_manager.gd`,
`scripts/ui/{achievements_ui,achievement_screen,city_map,collection_ui,encyclopedia_ui,help_ui,item_icons,photo_album,screens}.gd`.
Any candidate touched by these files' ID schemes needs a manual check, not a blind delete —
this is the exact mistake `CLAUDE.md` already names (`hiding_spot.gd` lesson).

## 5 spot-checks (done this session, real evidence)

| File | Verdict | Why |
|---|---|---|
| `park_loading.png` | **dead** | `screens.gd:139` loads one static `screens_v2/loading_street.png` for all loading screens — no per-district loading art path exists in code |
| `substation_loading.png` | **dead** | same reason |
| `park_wall_lit.png` | **dead** | only reachable via `CityStreetProps.make_wall_mesh()`, and `world_bootstrap.gd`'s own comment says that function "exists but is never called" |
| `icon_512_v2.png` | **dead** | `export_presets.cfg` references `icon_512.png` (no suffix); `_v2` has zero references — superseded leftover |
| `district_park_64.png` | **dead** | `city_map.gd` uses `crest_%s_96.png` and `hex_[color]_128.png` for district art, not a `district_<id>_64.png` scheme — superseded icon set |

5/5 spot-checks confirmed genuinely dead. That's supporting evidence the methodology works, not
proof the other 848 candidates are safe to delete sight-unseen.

## E1-E8 execution plan (P3 — no deletions in this doc-only phase)

1. **E1** — re-run pattern A/B fresh at P3 start (catches any asset added between P1 and P3).
2. **E2** — subtract every candidate whose basename or stem matches a token used in any of the 10
   dynamic-loader files' ID schemes (district ids, monster ids, item ids, achievement ids) —
   these need per-scheme checking, not grep, since the format strings differ per file.
3. **E3** — for what remains, grep once more for the filename *stem without extension or suffix*
   (`park_loading` not `park_loading.png`) in case it's referenced via a `preload()` built from a
   `const` string table Pattern A's regex didn't catch.
4. **E4** — spot-check every remaining candidate over 500KB individually (few enough at that
   point to do by hand — big files matter most for the size budget anyway).
5. **E5** — auto-delete only what survives E1-E4 with zero references found by any method.
6. **E6** — `git status`/commit the tree clean before deleting (so every deletion is a `git
   revert`-able commit, not a destructive edit).
7. **E7** — audio re-encode: music tracks → OGG Vorbis ≤96kbps, SFX → OGG Vorbis ≤64kbps, loop
   points/loop flags preserved (Godot's `.import` loop metadata, not baked into the audio file).
8. **E8** — measure exported desktop `.pck` byte size before and after E5+E7, record the real
   percentage in the P3 commit message and `docs/RUN_STATE.md`.

## E1 executed — real measurement

Before touching any file content, two more grep passes traced the actual dynamic-load call sites
(`grep -rnoE '\b(load|preload)\s*\(\s*[A-Za-z_][A-Za-z0-9_.]*\s*\)'` → 79 sites, then
`grep -rnE 'res://assets/[A-Za-z0-9_./]*(%s|%d|" *\+)'` → 24 real construction lines). That
cleared 17 whole asset directories (icons_v2, badges, crests, cards, photos, items, sfx, ui,
music, ambience/district_details, tiles, luts, portraits_v2, touch, ui_v2, icons/skills,
renders_v2/weapons) as dynamically-loaded, dropping the raw 853-file candidate list to 720. Three
directories stood out by name and were confirmed against existing docs rather than re-derived:

- `assets/audio/_pre_norm/` (163MB) — already documented in `docs/ASSET_HANDOFF.md`,
  `docs/REPORT_ASSETS.md`, `docs/MISSING_IMPORTS.md` as raw pre-normalization masters, explicitly
  "do NOT import" / "ARCHIVE". Not currently excluded from export (`export_filter="all_resources"`
  had no filter for it) — so it was shipping in every build despite three separate docs saying it
  shouldn't.
- `assets/_orphaned/` (141 tracked files, 3.8MB) — `docs/ERROR_LOG_FINAL.md` documents a prior
  session's own orphan-scan that verified zero incoming references (and explicitly corrected a
  first-pass false-positive run that had wrongly flagged dynamic-path files like `crest_`/`ach_`/
  district `_floor`/`_wall` textures — the same trap this session's own narrowing pass above hit
  and cleared the same way). Real deletion is blocked this session (local tool-permission
  classifier refuses `git rm -r` as irreversible destruction, independent of git being fully
  revertible) — excluded from export instead as the safe substitute; physical deletion needs the
  owner to run `git rm -r assets/_orphaned/` directly.
- `assets/store/{v2,storyboard,play_final,endings,press}/` (~87 files) — marketing/press prep
  material, zero code references (verified — only `assets/store/play_icon_512.png` at the top
  level is referenced, by the Android launcher icon; that file and its siblings directly under
  `assets/store/` were left alone, only the prep subfolders were excluded).

Applied as `exclude_filter` entries on all three export presets (Android/Web/Desktop) rather than
deleting file content — `export_presets.cfg` is git-tracked, so this is a one-line-revert change,
and it's the correct fix for the documented "do NOT import" masters (which were never meant to be
in the shipped binary, not meant to be gone from the repo).

**Measured** (`godot --headless --path . --export-pack "Windows Desktop" <path>`, both runs same
session, only the exclude_filter changed between them):

| | bytes | MB |
|---|---|---|
| Before | 281,710,668 | 268.6 |
| After | 203,681,544 | 194.3 |
| **Cut** | **78,029,124** | **74.4 — 27.7%** |

Gates re-run after the change: `bash tools/check.sh --static` → 1 fail, unrelated and
pre-existing (`flow_check.py`'s Master-bus check looks for a literal `name = &"Master"` string in
`default_bus_layout.tres`; Godot's own format never writes that line for the implicit index-0
bus, so this check fails on any valid bus layout — confirmed via `git diff` showing zero change to
that file across this session. Not fixed here, out of scope for a size-budget pass; flagged for
whoever owns gate maintenance).

## E2-E4 executed — per-candidate dynamic-loader narrowing, then corrected (follow-up session)

Of the 720 candidates surviving E1's 17-directory cut, 504 were already handled (the 3 directories
above). The remaining 216 were checked directory-by-directory against every dynamic-loader call
site found via `grep -rln "<dirname>"`, same method as E1. **A first pass over-excluded several
directories — zero code references isn't the same as dead when the content is a planned feature
delivered ahead of its code wiring, which this repo does repeatedly.** Caught and reverted within
the same session, documented honestly below rather than left standing.

**Confirmed dead, excluded** (real "ARCHIVED"/"superseded" documentation, not just an absence of
references): `textures/items_legacy/` (26 — `docs/REPORT_ASSETS.md`: "intentional... kept as
backups", live replacements in `textures/items/`), `audio/ambience/wav_src/` (5 — `docs/
AUDIO_CONVERT.md`/`docs/MISSING_IMPORTS.md`: "ARCHIVED", "never import", live `.ogg` replacements
exist), `textures/icons/*.png` root (12 achievement icons — `docs/REPORT_BUG_HUNT.md`: "legacy...
superseded unwired", replacement `icons_v2/ach_medal_v2_*` confirmed live), `textures/icons/
weapons/*` (9 — `weapon_compare_ui.gd`'s own comment confirms it switched from this exact path to
`renders_v2/weapons/*_render_256.png` mid-session).

**Reverted after over-excluding — real planned-feature content, not dead** (caught by
cross-checking delivery/report docs instead of trusting a zero-reference grep alone):
- `textures/loading/` (11) — `docs/VISUAL_PASS.md` §6 W8 names this exact path as the source art
  for a planned menu-parallax layer not yet built.
- `textures/{picto_v2,docs_v2,stages_v2,overlays_v2}/` (13+6+4+4=27) — `docs/REPORT_GAMEFEEL_V2.md`
  / `docs/REPORT_POLISH_V2.md` document these as delivered art for planned touch-gesture
  pictograms, a restoration-stage strip, document-page variants, and weather overlays — none
  coded yet, all real.
- `textures/maps/` (12) — `docs/REPORT_CONTENT_WAVE.md` states outright: "map screen / city map
  UI (**unwired; procedural today**)" — explicitly a planned replacement for the current
  procedural map, not dead art.
- `textures/fx/` (the 14 non-ext_resource files) and `textures/renders_v2/` (the 5 non-`player_
  512x768` files) — no explicit "planned" doc found for these specific files, but given three
  other categories in the same batch turned out to be planned-not-dead, and no "ARCHIVED"/
  "superseded" language exists for them either, left un-excluded on the same reasoning rather than
  risk a fourth mistake.
- `assets/store/v2/` (62, from the **prior** P3 session) and `assets/store/endings/` (5, same) —
  `docs/BUGS_FOR_CLAUDE.md` lists `store/v2` needing an import pass (planned platform store
  assets: App Store, itch.io, Yandex, etc.), and `docs/REPORT_CONTENT_WAVE.md`/`docs/
  ASSET_HANDOFF.md` both describe `store/endings/*` as intended for `EndingScreen`/`win_screen`
  (canon warmth-gradient art with real QA history) even though nothing in `endings_manager.gd`/
  `win_screen.gd` currently loads them — a wiring gap, not proof of deadness. Both reverted.

**Still excluded from the prior P3 session, re-checked and confirmed safe this pass**: `_pre_norm`,
`_orphaned`, `store/storyboard` (pre-production trailer planning art, never a shippable asset by
definition), `store/play_final` (`docs/SESSION_REPORT_SHIP.md`: zero script/scene references, no
"planned" language found), `store/press` (`docs/ASSET_HANDOFF.md`: explicit "Marketing only; do
not import into game scenes").

**Found, correctly NOT excluded (kept from the first pass)**: `audio/ambience/{ambient_dark_loop,
ambient_lit_loop,threat_high_loop,threat_low_loop}.ogg` (4 files) — `docs/REPORT_ASSETS.md:20`
documents their game-code wiring as a deliberate open decision; `docs/TRAILER_STORYBOARD.md`/
`store/trailer.md` already plan to use them.

**Not reached this pass**: `textures/surfaces/` (24, live directory, needs per-file work),
`textures/ui/` (36, likely mixed). Given the over-exclusion this pass already produced and
corrected, these are deliberately left for a pass with more time for the cross-check this section
now shows is necessary, not rushed through.

**Measured** (Desktop preset, `godot --export-pack`, same session, only `export_presets.cfg`
changed each time):

| | bytes | MB |
|---|---|---|
| Original baseline (before any size work) | 281,710,668 | 268.6 |
| After E1 (prior session, `11cbb4e`) | 203,681,544 | 194.3 |
| After E2-E4 first pass (over-excluded) | 178,551,292 | 170.3 |
| **After E2-E4 corrected** | 215,512,000 | 205.5 |
| **Real total cut from original baseline** | 66,198,668 | 63.1 — **23.5%** |

**This is lower than the 27.7% `docs/RELEASE_READINESS_REPORT.md` v7 reported**, because that
figure was measured against the P3 baseline which had already over-excluded `store/v2` and
`store/endings` — both reverted here as real planned content, not dead. v7.0.0-rc1 stays tagged as
released (per instruction, not moved or deleted); this is the corrected number going forward, and
v7.1 states it plainly rather than repeat the old one.

Gates re-checked after the correction: static 12/12, `compile_gate_scene.tscn` bad=0.

**Not done this session**: E7 audio re-encode (see `docs/KNOWN_ISSUES.md` — definitively no safe
control exists), the physical deletion of `assets/_orphaned/`/`assets/audio/_pre_norm/`
(owner-only, tool-permission block), and the `surfaces/`/`ui/` per-file narrowing named above.
