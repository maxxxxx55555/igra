# Content Pipeline Audit — all district packs

Owner: CONTENT/assets agent. Static audit (no engine, no Godot) of every pack under
`content/districts/**` against `content/README.md`, `docs/CONTENT_WORLD_BIBLE.md`,
`docs/GDD.md` §4/§12.3 and the shipped data in `data/`.
Run: **2026-09-08**, districts 1–6 (`suburbs`, `residential`, `park`, `school`, `hospital`,
`gas_station`). Re-run same day, districts 1–7 (added `police`). Re-run **2026-09-09**,
districts 1–8 (added `warehouses`, district 8 of the §4.1 chain). Method: python — JSON parse,
regex id extraction from `data/items/*.tres` and `data/districts/*.tres`, transitive
`powered_by` closure, glob path existence, Ogg/Vorbis header parse, Pillow/numpy image
metrics.

## 1. Per-district matrix

| District | # | Notes | Zones | Fixed | Rules | Item ids ⊆ data/items | i18n keys | DARK chain (cable/fuse/transistor + key) | world_refs | Gate violations | Handoff |
|---|---|---|---|---|---|---|---|---|---|---|---|
| suburbs | 1 | 8 | 8 | 9 | R1–R5 | ✔ | ✔ 01–08 | ✔ 3/2/**2**/1 *(transistor added by this audit)* | 0 | none | ✔ (range form) |
| residential | 2 | 8 | 8 | 8 | R1–R6 | ✔ | ✔ 01–08 | ✔ 2/2/2/1 | 0 | none | ✔ (range form) |
| park | 3 | 8 | 9 | 8 | R1–R6 | ✔ | ✔ 01–08 | ✔ 2/2/2/1 | 12 *(13 before this audit)* | **1 fixed** (see §3.2) | ✔ |
| school | 4 | 8 | 9 | 9 | R1–R7 | ✔ | ✔ 01–08 | ✔ 2/2/2/1 | 13 | none | ✔ |
| hospital | 5 | 8 | 10 | 10 | R1–R8 | ✔ | ✔ 01–08 | ✔ 2/2/2/1 | 14 | none | ✔ |
| gas_station | 6 | 8 | 9 | 9 | R1–R8 | ✔ | ✔ 01–08 | ✔ 2/2/2/1 | 17 | none | ✔ |
| police | 7 | 8 | 9 | 10 | R1–R8 | ✔ | ✔ 01–08 | ✔ 2/2/2/1 | 20 | none | ✔ |
| warehouses | 8 | 8 | 9 | 10 | R1–R8 | ✔ | ✔ 01–08 | ✔ 3/2/2/1 | 15 | none | ✔ |

Totals **after district-8 re-run**: 64 notes, 71 zones, 73 fixed spawns, 91 world_refs,
128 `LORE_*` i18n keys (8 districts × 16). Every `item` / `item_type` value in every pack
resolves to one of the 41 ids in `data/items/*.tres`; no pack invents an item id.
Before/after vs the 1–7 re-run: see §7.

## 2. Global id checks

| Check | Result |
|---|---|
| Note ids unique across all districts (64 ids) | ✔ no collisions |
| Fixed-spawn ids unique across all districts (73 ids) | ✔ no collisions |
| Zone ids unique **within** each district | ✔ |
| Zone ids reused **across** districts | `z_exit_east` (residential, park, gas_station), `z_exit_north` (suburbs, school), `z_boiler_room` (residential, school), `z_generator_room` (hospital, police) — **no new reuse added by the warehouses pack** (all 9 of its zones are first-use) |
| Zone ids identical across the three files of a pack | ✔ all 8 packs |
| Note ids referenced by their own `prop_manifest.md` | ✔ all 8 packs |
| Fixed-spawn ids referenced by their own `prop_manifest.md` | ✔ all 8 packs |
| Container in every fixed spawn declared in `container_modifiers` | ✔ all 8 packs |
| `world_refs` resolve to an id in `content/world/*` or `content/lore/*` | ✔ 91/91 |
| Referenced prop scenes exist (`scenes/props/*.tscn`) | ✔ |
| Referenced audio files exist | ✔ except documented spec-only files: `school_lit.ogg`, `school_pipe_whisper.ogg`, `gas_station_lit.ogg`, `police_lit.ogg`, **`warehouses_lit.ogg` (spec G2g)** (+ optional `hospital_ward_curtain_drag.ogg`) |
| Referenced textures exist | ✔ (warehouses pass shipped `warehouses_floor_lit.png`, `warehouses_wall_lit.png`; dark floor edge-repaired) |

## 3. Findings and fixes

### 3.1 suburbs could not reach FULL from its own guaranteed spawns — **fixed**
`content/districts/suburbs/item_spawns.json` guaranteed fuse (2), cable (3) and wiring (2)
in DARK but **no transistor**, while `power_switch.gd` needs cable → PARTIAL, fuse →
STREETS, transistor → FULL. Suburbs is district 1: nothing can be imported, and both
`residential` and `park` require suburbs at FULL (GDD §4.3), so the guarantee was
incomplete — the district relied on procedural `DistrictLoot.REPAIR_PARTS` scatter alone.
**Fix:** added `suburbs_fix_puzzle_04` (2× transistor, `z_garage_row` / `garage_shelf`,
`min_stage 0`) and rewrote R1 to cover the whole chain; recorded in the suburbs
`prop_manifest.md` garage-row entry. All six districts now pass the same DARK-solvability
proof.

### 3.2 park referenced a residential-gated character — **fixed**
`park_note_05` carried `world_refs: ["char_babka_manya"]`, whose reveal is
`residential / DARK`. But `park.powered_by = [suburbs]`, so a player can reach park with
residential never visited, and reading the note would unlock her journal entry ahead of her
own gate (CONTENT_WORLD_BIBLE rule 2/3).
**Fix:** `world_refs` cleared to `[]` with an `_audit_note` in the JSON. The prose keeps the
"same careful hand as house 24" hint, so nothing is lost narratively; only the premature
journal unlock is removed.

### 3.3 zone-id reuse across districts was undocumented — **fixed (spec)**
Three zone ids appear in more than one pack. Rather than churn ids in already-merged packs,
the contract is now explicit in `content/README.md`: **zone ids are district-scoped**, only
meaningful as `(district_id, zone_id)`; note ids and fixed-spawn ids remain globally unique.
Code must not build a flat global zone table.

### 3.4 reachability rule generalised — **fixed (spec)**
The rule the school/hospital/gas_station packs were written against is now written into
`content/README.md` for every future pack: a district may reference only world ids revealed
by itself (min_stage respected) or by its transitive `powered_by` closure, which is
guaranteed at FULL per GDD §4.3. Computed closures:

| District | powered_by | guaranteed history at arrival |
|---|---|---|
| suburbs | — | — |
| residential | suburbs | suburbs |
| park | suburbs | suburbs |
| school | residential | residential, suburbs |
| hospital | residential | residential, suburbs |
| gas_station | park | park, suburbs |
| police | park | park, suburbs |
| warehouses | hospital | hospital, residential, suburbs |

(Districts 9–11 are data-known but not yet packed: `industrial.powered_by = [warehouses,
police]`, `substation.powered_by = [industrial]`, `power_station.powered_by =
[substation]`.)

### 3.5 warehouses dark floor carried a 3 px edge frame (wrap seam 18.8) — **fixed**
The §4.1 probe (seam probe on all 7 shipped dark floors) found `tiles/warehouses_floor.png`
at a wrap seam of 18.8 per channel vs the 3.8–4.4 house range: an asymmetric dark frame
on the top/left 3 px (mean Y 33 vs interior 45) — a generation edge artifact, not
pattern. **Fix (in the warehouses asset pass):** the 3 frame rows/cols were mirror-filled
from the interior (1,467 px of 65,536 changed, mean abs diff 0.32/255; palette 21..69
untouched); seam now 3.85. The lit twin was then derived from the **repaired** dark so
the pair stays geometry-locked (corr 0.982). The dark floor ships repaired in the same
commit as its lit twin; ledgered in `docs/ASSET_LICENSES.md`.

## 4. Reveal-gate conformance (GDD §12.3 / world bible rule 3)

- Act II Architect ids (`char_architect`, `faction_project_architect`,
  `hist_project_architect`, `news_architect_denied`) appear **only** in
  `hospital_note_06/07/08` and `warehouses_note_06/07`, all at `min_stage >= 2` — exactly
  their `hospital / STREETS` gate. Hospital is warehouses' own required prerequisite, so
  the ids are guaranteed revealed at arrival (closure §3.4); warehouses still paces them
  at STREETS+ for district rhythm. No other district mentions the project by name;
  `school_note_08` and `gas_station_note_03` hint via "the draw" / "the fourth feeder"
  only. ✔
- Act I Keeper/radio ids are used where they are guaranteed: park (their home),
  gas_station and police (park is the prerequisite of both). ✔
- Police is D7 and warehouses is D8 / Act II *chain territory* (GDD §12.3 D4–8). Police
  carries **zero** Architect ids (hospital is a separate branch, not in its closure).
  Warehouses is the *only* non-hospital pack that may carry them, precisely because
  hospital is on its `powered_by` path — and keeps the park/radio/Act-I-Keeper set out
  (park is not on its path). Same rule that caught park's residential leak, applied in
  both directions. ✔
- No Act III id (`radio_02_grid_crew_relay`, `radio_03_keeper_reversal`) is referenced by
  any district pack. ✔

## 5. Observations (no fix applied — for the next passes)

1. `suburbs` and `residential` notes carry **no** `world_refs` at all (they predate the
   world bible). Adding refs is safe polish — both districts guarantee only themselves /
   suburbs, so `char_marat`, `char_grid_crew_recorder`, `faction_city_power`,
   `hist_blackout_night`, `news_rolling_outages` are all legal there.
2. Districts 1–3 use `min_stage` 0–2 only; districts 4–8 use the full 0–3 range (a
   FULL-gated note as the district's last word — `warehouses_note_08` is the crew's
   east-gate photo, only visible after the district is restored). Harmonising 1–3 is
   optional flavour, not a defect.
3. Data-side facts still open (CODE's call, outside content ownership): `school` and
   `gas_station` are **leaves** of the `powered_by` graph (nothing lists them as a
   prerequisite). `warehouses` is **not** a leaf — `industrial.powered_by = [warehouses,
   police]` (two-parent convergence, first in the chain; industrial's guaranteed closure
   will be the union of both branches' histories). `district_themes.gd` `"music"` rows
   still disagree with `music_manager.gd` for school/hospital/gas_station; police's and
   warehouses' theme dicts are colour-only (music from `music_manager.gd` →
   `downtown.wav` / `harbor.wav`).
4. Audio: lit beds specced but not fabricated (`residential_lit`, `park_lit`, `school_lit`,
   `gas_station_lit`, `police_lit` / G2f, **`warehouses_lit` / G2g**; `industrial_lit` /
   `substation_lit` remain one-liners in G3); no binary audio has ever been faked by this
   pipeline. Loudness (−18 LUFS / TP) remains unverifiable in this sandbox — no ffmpeg.
5. The warehouses pass ran the §4.1 probe on all shipped dark floors as part of the lit
   pass and found exactly one out-of-range seam (warehouses floor, fixed — §3.5).
   residential's dark floor (15.3) is the only remaining outlier above ~4.5; it was
   deliberately left untouched (its lit twin already matches it, and re-deriving a shipped
   pair is a texture pass on its own).

## 6. How to re-run this audit

All checks are pure static python over `content/**` + `data/**` + `assets/**`:
JSON parse → item-id set from `data/items/*.tres` → per-pack id cross-refs → transitive
`powered_by` closure from `data/districts/*.tres` → `world_refs` reveal comparison →
glob existence for scenes/audio/textures → `git diff --name-only origin/main...HEAD` for the
ownership audit. No Godot, no engine, no headless run is required or permitted here.

## 7. Before/after — district-7 re-run (2026-09-08) → district-8 re-run (2026-09-09)

| Metric | 1–7 re-run | 1–8 re-run | Delta |
|---|---|---|---|
| Districts packed | 7 | 8 | +1 (`warehouses`) |
| Lore notes | 56 | 64 | +8 (`warehouses_note_01..08`) |
| Zones | 62 | 71 | +9 (all first-use ids, no new cross-district reuse) |
| Fixed spawns | 63 | 73 | +10 (`warehouses_fix_*`) |
| `world_refs` | 76 | 91 | +15 (all inside warehouses' closure: hospital/residential/suburbs) |
| `LORE_*` i18n keys | 112 | 128 | +16 (`LORE_WAREHOUSES_01..08_TITLE/_TEXT`) |
| DARK repair-chain proofs (≥2 cable/fuse/transistor + key) | 7/7 | 8/8 | +1 (3/2/2/1) |
| Reveal-gate violations found | 0 | 0 | — |
| New defects introduced by the pass | — | 0 | — |
| Textures shipped | — | 2 lit twins + 1 dark-floor edge repair | see §3.5 |
| Audio facts appended | — | bed + 4 one-shots header-verified; G2g spec | spec only, no binaries |
