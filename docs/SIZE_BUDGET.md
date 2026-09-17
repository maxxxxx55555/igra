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

## E2-E4 executed — per-candidate dynamic-loader narrowing (follow-up session)

Of the 720 candidates surviving E1's 17-directory cut, 504 were already handled (the 3 directories
above). The remaining 216 were checked directory-by-directory against every dynamic-loader call
site found via `grep -rln "<dirname>"` then narrowed to the exact `assets/<path>` prefix each
call site actually builds, same method as E1:

**Confirmed dead, excluded** (directory-level, zero references anywhere, no dynamic construction
found): `textures/items_legacy/` (26), `textures/picto_v2/` (13), `textures/docs_v2/` (6),
`textures/stages_v2/` (4), `textures/overlays_v2/` (4), `textures/maps/` (12 — `maps_v2/` is the
live directory `city_map.gd` actually uses), `textures/loading/` (11 — confirms the P1 spot-check
finding: `screens.gd:139` uses one static `screens_v2/loading_street.png` for every loading
screen), `audio/ambience/wav_src/` (5 — explicitly documented in `docs/AUDIO_CONVERT.md`/
`docs/MISSING_IMPORTS.md`/`docs/REPORT_ASSETS.md` as archived WAV masters, "never import",
same category as `_pre_norm`).

**Confirmed dead, excluded** (file-level, directory has other live files so directory-level
exclusion would have broken them): `textures/icons/*.png` root (12 achievement icons — superseded
by `icons_v2/ach_medal_v2_*`, `icons/skills/` subfolder untouched, still dynamic-live) +
`textures/icons/weapons/*` (9 — superseded by `icons_v2` weapon renders); `textures/fx/` 14 of its
19 files (the other 5 — `blood_splatter.png`, `dust.png`, `muzzle_flash.png`, `spark_alt_64.png`,
`strobe_flash_128.png` — are real `ext_resource` targets in `scenes/vfx/*.tscn`, confirmed live,
left alone); `textures/renders_v2/` 5 of its files (`backpack_256.png`, `battery_pack_256.png`,
`bundle_survivor_256.png`, `medkit_256.png`, `tools_256.png` — `player_512x768.png` in the same
directory is a real static reference in `stats_ui.gd:52`, confirmed live, left alone).

**Found, NOT excluded — a real planned-feature catch**: `audio/ambience/{ambient_dark_loop,
ambient_lit_loop,threat_high_loop,threat_low_loop}.ogg` (4 files) have zero current code
references, but `docs/REPORT_ASSETS.md:20` explicitly documents them as prepared assets whose
game-code wiring was a deliberate, still-open decision ("whether new OGGs replace `Ambient_*.ogg`
layers is a code-wiring decision outside assets ownership"), and `docs/TRAILER_STORYBOARD.md`/
`store/trailer.md` already plan to use them. This is exactly the `hiding_spot.gd`-class mistake
`CLAUDE.md` warns about — zero references does not mean dead when a real doc calls it a planned
feature. Left alone, not excluded, not deleted.

**Not reached this pass** (mixed live+dead directories, per-file work not completed — still real
candidates, just not verified yet): `textures/surfaces/` (24, directory is live via
`hiding_spot.gd`/`street_props.gd`/`streetlight_spawner.gd`), `textures/ui/` (36, almost certainly
mixed given its generic role). `assets/store/*.png` top-level (14 loose marketing images) and
`assets/art/*`/`assets/grading/night_grade.png` (6 loose single files) also untouched — small
enough to be low-value versus the risk of a rushed per-file call.

**Measured**, before/after this pass (Desktop preset, `godot --export-pack`, both runs same
session, only `export_presets.cfg` changed):

| | bytes | MB |
|---|---|---|
| After E1 (prior session) | 203,681,544 | 194.3 |
| After E2-E4 | 178,551,292 | 170.3 |
| **This pass's cut** | 25,130,252 | 24.0 |
| **Total cut from original baseline** | 103,159,376 | 98.4 — **36.6%** |

Gates re-checked after the change: static 12/12, `compile_gate_scene.tscn` bad=0.

**Not done this session**: E7 audio re-encode (see `docs/KNOWN_ISSUES.md`), the physical deletion
of `assets/_orphaned/`/`assets/audio/_pre_norm/` (owner-only, same tool-permission block), and the
`surfaces/`/`ui/` per-file narrowing named above.
