# Content Pipeline Audit — all district packs

Owner: CONTENT/assets agent. Static audit (no engine, no Godot) of every pack under
`content/districts/**` against `content/README.md`, `docs/CONTENT_WORLD_BIBLE.md`,
`docs/GDD.md` §4/§12.3 and the shipped data in `data/`.
Run: **2026-09-08**, districts 1–6 (`suburbs`, `residential`, `park`, `school`, `hospital`,
`gas_station`). Re-run same day, districts 1–7 (added `police`). Re-run **2026-09-09**,
districts 1–8 (added `warehouses`, district 8 of the §4.1 chain). Re-run **2026-09-09**,
districts 1–9 (added `industrial`, district 9 — the **first two-parent convergence**:
`powered_by = [warehouses, police]`, closure = union of both branches). Method: python —
JSON parse, regex id extraction from `data/items/*.tres` and `data/districts/*.tres`,
transitive `powered_by` closure (union semantics for multi-parent), glob path existence,
Ogg/Vorbis header parse, Pillow/numpy image metrics.

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
| industrial | 9 | 8 | 10 | 10 | R1–R8 | ✔ | ✔ 01–08 | ✔ 2/2/2/1 | 23 | none | ✔ |

Totals **after district-9 re-run**: 72 notes, 81 zones, 83 fixed spawns, 114 world_refs,
144 `LORE_*` i18n keys (9 districts × 16). Every `item` / `item_type` value in every pack
resolves to one of the 41 ids in `data/items/*.tres`; no pack invents an item id.
Before/after vs the 1–8 re-run: see §7.

## 2. Global id checks

| Check | Result |
|---|---|
| Note ids unique across all districts (64 ids) | ✔ no collisions |
| Fixed-spawn ids unique across all districts (73 ids) | ✔ no collisions |
| Zone ids unique **within** each district | ✔ |
| Zone ids reused **across** districts | `z_exit_east` (residential, park, gas_station), `z_exit_north` (suburbs, school), `z_boiler_room` (residential, school), `z_generator_room` (hospital, police) — **no new reuse added by the industrial pack** (all 10 of its zones are first-use; audit regex now also matches digit-bearing ids like residential's `z_house24`) |
| Zone ids identical across the three files of a pack | ✔ all 9 packs |
| Note ids referenced by their own `prop_manifest.md` | ✔ all 9 packs |
| Fixed-spawn ids referenced by their own `prop_manifest.md` | ✔ all 9 packs |
| Container in every fixed spawn declared in `container_modifiers` | ✔ all 9 packs |
| `world_refs` resolve to an id in `content/world/*` or `content/lore/*` | ✔ 114/114 |
| Referenced prop scenes exist (`scenes/props/*.tscn`) | ✔ |
| Referenced audio files exist | ✔ except documented spec-only files: `residential_lit.ogg` (G1), `park_lit.ogg` (G2b), `school_lit.ogg` (G2c), `school_pipe_whisper.ogg` (G5), `gas_station_lit.ogg` (G2e), `police_lit.ogg` (G2f), `warehouses_lit.ogg` (G2g), **`industrial_lit.ogg` (G2h)** (+ optional `hospital_ward_curtain_drag.ogg`); all referenced from pack gap/plan sections as explicit gaps, never fabricated |
| Referenced textures exist | ✔ (industrial pass shipped `industrial_floor_lit.png`, `industrial_wall_lit.png`, both §4.1-verified; both shipped industrial dark twins seam-probed clean first — floor 3.81, wall 3.08, no edge-frame defect, no repair needed) |

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
| **industrial** | **warehouses + police** (first two-parent) | **suburbs, residential, park, hospital, warehouses, police — the UNION of both branches** (warehouses → hospital → residential → suburbs ∪ police → park → suburbs) |

(Districts 10–11 are data-known but not yet packed: `substation.powered_by = [industrial]`,
`power_station.powered_by = [substation]` — both closures will be the industrial union plus
their ancestors.) **Industrial closure computation, verified by this audit's re-run:** the
union is six districts because GDD §4.3 requires *every* `powered_by` entry at FULL — a
player standing in industrial has necessarily completed both branches entire. NOT guaranteed:
`school`, `gas_station` (leaves — no district lists them as a prerequisite) and
`substation`, `power_station` (descendants). The industrial pack's 23 `world_refs` were each
checked against this union; the Act III broadcasts (`radio_02_grid_crew_relay`,
`radio_03_keeper_reversal`) are gated on substation/power_station and are therefore illegal
in industrial **even though it is D9 / the first Act III district** — the §12.3 act boundary
moves the story, not the reveal gates.

### 3.5 warehouses dark floor carried a 3 px edge frame (wrap seam 18.8) — **fixed**
The §4.1 probe (seam probe on all 7 shipped dark floors) found `tiles/warehouses_floor.png`
at a wrap seam of 18.8 per channel vs the 3.8–4.4 house range: an asymmetric dark frame
on the top/left 3 px (mean Y 33 vs interior 45) — a generation edge artifact, not
pattern. **Fix (in the warehouses asset pass):** the 3 frame rows/cols were mirror-filled
from the interior (1,467 px of 65,536 changed, mean abs diff 0.32/255; palette 21..69
untouched); seam now 3.85. The lit twin was then derived from the **repaired** dark so
the pair stays geometry-locked (corr 0.982). The dark floor ships repaired in the same
commit as its lit twin; ledgered in `docs/ASSET_LICENSES.md`.

### 3.6 district-9 audit run: 4 initial flags, all four in the checker, not the packs — fixed (tooling)
The 1–9 re-run's first pass flagged 4 "defects"; triage showed **all four were audit-script
bugs**, and the packs were clean: (a) the zone regex `z_[a-z_]+` did not match digit-bearing
zone ids (residential's `z_house24` — shipped since district 2), producing two false
mismatches; (b) the gap-section split only recognized the later packs' `## Art / audio
gaps` header, not the early packs' `## Content gaps`, so documented spec-only audio
(`residential_lit.ogg` G1, `park_lit.ogg` G2b) was scanned as a plan-section reference.
Fix: regex `[a-z0-9_]+` + split on any `^## .*gaps` header. Both fixes are checker-only;
no pack file changed; the re-run then reported 0 defects across all 9 districts. Recorded
so the next pass does not re-trip on the same false-positive classes.

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
- **Industrial (D9) is the first two-parent convergence and the first Act III district
  (GDD §12.3 D9–11) — and the first pack that legally carries BOTH threads:** 4 Architect
  ids (`industrial_note_05`/`_06`, both `min_stage 2`, matching their own hospital/STREETS
  gate and the warehouses pacing precedent) via the warehouses→hospital branch, and 9
  Keeper/radio ids (`industrial_note_04`/`_07`/`_08`) via the police→park branch. Every id
  checked against the six-district union closure (§3.4). The Act III broadcasts stay out
  (substation/power_station-gated, not in the closure) — the act boundary moves the story,
  not the gates; industrial's Act III opening is prose-only (`industrial_note_08`'s south
  gate / point-of-no-return framing). ✔
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
   prerequisite). `warehouses` and `police` are **not** leaves — both feed the
   `industrial` convergence (now packed, §3.4); `industrial` in turn feeds `substation`
   (next district). `district_themes.gd` `"music"` rows still disagree with
   `music_manager.gd` for school/hospital/gas_station; police's, warehouses' and
   industrial's theme dicts are colour-only (music from `music_manager.gd` →
   `downtown.wav` / `harbor.wav` / `industrial.wav` — industrial.wav verified 1 ch /
   22.05 kHz / 24.0 s, the same downtown/harbor legacy class, not an anomaly).
4. Audio: lit beds specced but not fabricated (`residential_lit` G1, `park_lit` G2b,
   `school_lit` G2c, `gas_station_lit` G2e, `police_lit` G2f, `warehouses_lit` G2g,
   **`industrial_lit` G2h — full spec this pass**; `substation_lit` remains a G3
   one-liner); no binary audio has ever been faked by this pipeline. Loudness
   (−18 LUFS / TP) remains unverifiable in this sandbox — no ffmpeg. **New finding
   (G2h, recorded 2026-09-09):** `industrial_dark.ogg` is the **only** district bed off
   the 36.000 s house contract — header-verified 33.994 s (all 10 other dark beds and
   all 3 shipped lit beds are exactly 36.000 s / granule 1,587,600). Both readings
   recorded in G2h (render defect vs the 12-bar industrial theme canon at 85 bpm =
   33.88 s); the G2h lit-twin spec pins its length to the shipped dark bed so the pair
   crossfades, and flags the 36 s contract question to the audio toolchain holder.
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

## 7. Before/after — district-8 re-run (2026-09-09) → district-9 re-run (2026-09-09)

| Metric | 1–8 re-run | 1–9 re-run | Delta |
|---|---|---|---|
| Districts packed | 8 | 9 | +1 (`industrial`, first two-parent convergence) |
| Lore notes | 64 | 72 | +8 (`industrial_note_01..08`) |
| Zones | 71 | 81 | +10 (all first-use ids, no new cross-district reuse) |
| Fixed spawns | 73 | 83 | +10 (`industrial_fix_*`) |
| `world_refs` | 91 | 114 | +23 (all inside the six-district union closure; first pack carrying both the Architect and Keeper/radio threads) |
| `LORE_*` i18n keys | 128 | 144 | +16 (`LORE_INDUSTRIAL_01..08_TITLE/_TEXT`) |
| DARK repair-chain proofs (≥2 cable/fuse/transistor + key) | 8/8 | 9/9 | +1 (2/2/2/1) |
| Reveal-gate violations found | 0 | 0 | — |
| New defects introduced by the pass | — | 0 | — |
| Textures shipped | 2 lit twins + 1 dark-floor edge repair (warehouses) | +2 lit twins (industrial; dark twins probed clean, no repair) | see §2 / ASSET_LICENSES |
| Audio facts appended | bed + 4 one-shots header-verified; G2g spec | bed + 4 one-shots header-verified; G2h spec + **real finding: dark bed 33.994 s vs 36.000 s contract** | spec only, no binaries |
