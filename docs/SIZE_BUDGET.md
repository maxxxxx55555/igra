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

**Not done this session** (real, not deleted-and-hidden): E7 audio re-encode (music/SFX bitrate
pass) and the physical deletion of `assets/_orphaned/` once the owner clears the tool-permission
block. The 720-candidate narrowed list beyond the 3 directories above still needs E3-E4's
per-file spot-checking before any further export exclusion or deletion.
