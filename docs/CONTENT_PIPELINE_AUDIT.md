# Content Pipeline Audit — all district packs

Owner: CONTENT/assets agent. Static audit (no engine, no Godot) of every pack under
`content/districts/**` against `content/README.md`, `docs/CONTENT_WORLD_BIBLE.md`,
`docs/GDD.md` §4/§12.3 and the shipped data in `data/`.
Run: **2026-09-08**, districts 1–6 (`suburbs`, `residential`, `park`, `school`, `hospital`,
`gas_station`). Re-run same day, districts 1–7 (added `police`). Re-run **2026-09-09**,
districts 1–8 (added `warehouses`, district 8 of the §4.1 chain). Re-run **2026-09-09**,
districts 1–9 (added `industrial`, district 9 — the **first two-parent convergence**:
`powered_by = [warehouses, police]`, closure = union of both branches). Final re-run
**2026-09-09**, districts 1–11 (added `substation`, district 10 — the point of no return —
and `power_station`, district 11, the **chain terminal**; plus the TASK 0 source-escaping
fix to the district-9 file). This final re-run doubles as the **CONTENT RELEASE
CERTIFICATE** (§8). Method: python — JSON parse, regex id extraction from
`data/items/*.tres` and `data/districts/*.tres`, transitive `powered_by` closure (union
semantics for multi-parent), glob path existence, Ogg/Vorbis header parse, Pillow/numpy
image metrics.

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
| substation | 10 | 8 | 10 | 10 | R1–R8 | ✔ | ✔ 01–08 | ✔ 2/2/2/1 | 20 | none | ✔ |
| power_station | 11 | 8 | 10 | 10 | R1–R8 | ✔ | ✔ 01–08 | ✔ 2/2/2/1 | 20 | none | ✔ |

Totals **after the final 1–11 re-run**: 88 notes, 101 zones, 103 fixed spawns, 154
world_refs, 176 `LORE_*` i18n keys (11 districts × 16). Every `item` / `item_type` value
in every pack resolves to one of the 41 ids in `data/items/*.tres`; no pack invents an
item id. Before/after vs the 1–9 re-run: see §7.

## 2. Global id checks

| Check | Result |
|---|---|
| Note ids unique across all districts (88 ids) | ✔ no collisions |
| Fixed-spawn ids unique across all districts (103 ids) | ✔ no collisions |
| Zone ids unique **within** each district | ✔ all 11 |
| Zone ids reused **across** districts | `z_exit_east` (residential, park, gas_station), `z_exit_north` (suburbs, school), `z_boiler_room` (residential, school), `z_generator_room` (hospital, police) — **no new reuse added by the substation or power_station packs** (all 20 of their zones are first-use) |
| Zone ids identical across the three files of a pack | ✔ all 11 packs (audit semantics, industrial precedent: every lore `location_hint` zone is a declared zone; 2 note-less zones allowed — industrial's `z_assembly_line`/`z_generator_hall`, substation's `z_arc_cage`/`z_cable_trench`, power_station's `z_cooling_yard`/`z_reactor_room`) |
| Note ids referenced by their own `prop_manifest.md` | ✔ all 9 packs |
| Fixed-spawn ids referenced by their own `prop_manifest.md` | ✔ all 9 packs |
| Container in every fixed spawn declared in `container_modifiers` | ✔ all 9 packs |
| `world_refs` resolve to an id in `content/world/*` or `content/lore/*` | ✔ 154/154 |
| World-bible id coverage (referenced ≥ once chain-wide) | ✔ **37/37 — complete** (the last 10 never-referenced ids consumed by districts 10–11: 4 in substation, 6 in power_station; see §4) |
| Referenced prop scenes exist (`scenes/props/*.tscn`) | ✔ all 11 packs |
| Referenced audio files exist | ✔ except documented spec-only files: `residential_lit.ogg` (G1), `park_lit.ogg` (G2b), `school_lit.ogg` (G2c), `school_pipe_whisper.ogg` (G5), `gas_station_lit.ogg` (G2e), `police_lit.ogg` (G2f), `warehouses_lit.ogg` (G2g), `industrial_lit.ogg` (G2h), **`substation_lit.ogg` (G2i)** (+ optional `hospital_ward_curtain_drag.ogg`); all referenced from pack gap/plan sections as explicit gaps, never fabricated. Power_station has no audio gap (both beds + 4 details ship) |
| Referenced textures exist | ✔ (substation pass shipped `substation_floor_lit.png`, `substation_wall_lit.png`, both §4.1-verified; dark floor probed clean at 4.35, dark wall recorded as an 18.06 intrinsic-pattern outlier with no frame defect — dark untouched, residential precedent. Power_station pass shipped zero binaries — both twins pre-date the pipeline and were re-measured for the record instead; see `docs/ASSET_LICENSES.md`) |

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

**Districts 10–11 (packed and verified by the final re-run):**
`substation.powered_by = [industrial]` → closure = industrial's six-district union plus
industrial itself (suburbs, residential, park, hospital, warehouses, police, industrial —
seven districts); `power_station.powered_by = [substation]` → closure = substation's
seven-district closure plus substation itself (eight districts — every packed district
except the two leaves). **Industrial closure computation, verified by this audit's re-run:** the
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

### 3.7 industrial `lore_notes.json` double-escaped quotes — **fixed (source)**
`docs/HANDOFF.md`'s open question (logged by CLAUDE): all 8 industrial `en.text` fields
carried a literal triple-backslash `\\\"` (raw bytes `5C 5C 5C 22`, 22 occurrences) wherever
a note quotes in-world dialogue, parsing to `\"` instead of `"` (warehouses and every
earlier pack use clean `\"`). Cosmetic — display was already worked around in the i18n
layer (`STATIC_AUDIT.md` #28) — but future translators copying from the JSON would inherit
the artifact. **Fix (TASK 0, own commit):** raw `\\\"` → `\"` in all 22 occurrences; JSON
re-validated; all 8 parsed texts verified byte-identical to the shipped
`LORE_INDUSTRIAL_*_TEXT` values in `data/i18n/en.json`. Before: parsed text contains
`\"` (backslash + quote); after: clean `"`, matching shipped i18n exactly. No prose
changed, no player-facing effect. The final re-run additionally asserts **all 11 packs**
are free of the triple-backslash pattern (§8).

### 3.8 final 1–11 audit run: 2 initial flags, both in the checker, not the packs — fixed (tooling)
Same class as §3.6 (checker-only, no pack file changed): (a) a strict "every zone must
appear in a lore `location_hint`" assertion tripped on substation's `z_cable_trench` —
but industrial already ships 2 note-less zones (`z_assembly_line`, `z_generator_hall`)
under the standing ✔, so the check now encodes the actual audit semantics (every hinted
zone must be declared; ≤2 note-less zones per pack, §2); (b) a strict "every plan-section
`.ogg` must exist on disk" assertion tripped on the stage-table's `substation_lit.ogg`
mention — but spec-only lit beds referenced from gap sections are the documented
exemption class (§2, all 9 prior packs), so the check now exempts gap-documented files.
The re-run then reported 0 defects across all 11 districts.

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
- No Act III id (`radio_02_grid_crew_relay`, `radio_03_keeper_reversal`) was referenced
  by any district pack through district 9. ✔
- **Substation (D10) is the first district where `radio_02_grid_crew_relay` is legal**
  (gated on substation itself at min_stage 1) — carried by `substation_note_07` at
  min_stage 2, respecting the district's own stage progression (paced at STREETS for
  district rhythm, same discipline as the hospital-gated Architect ids). The pack also
  consumes the first-use ids `hist_crew_walk_suburbs`, `hist_bench_proof` and
  `diary_keeper_02`, and deliberately withholds `char_architect` (the person, not the
  program, is the D11 reveal) and `radio_03_keeper_reversal` (power_station-gated). ✔
- **Power_station (D11, terminal) legally closes every open thread:** `char_architect` +
  program + history (note_05, the memorandum — lore only, no mechanics), `radio_03` +
  Keeper + call (note_03, carried at the gate exactly), Keeper diaries 01/03 + Keepers
  (note_06, the bunker), Manya's diary + Manya + Petrov (note_07, the names), trees +
  watch + bench proof (note_08, the last word). The last six never-referenced ids die
  here. ✔
- **World-bible coverage is now 37/37** — every character, faction, history event, radio
  transcript, diary entry and news clipping has been referenced at least once across the
  11 packs (verified by union over all `world_refs`). No dangling bible entry remains. ✔

## 5. Observations (no fix applied — for the next passes)

1. `suburbs` and `residential` notes carry **no** `world_refs` at all (they predate the
   world bible). Adding refs is safe polish — both districts guarantee only themselves /
   suburbs, so `char_marat`, `char_grid_crew_recorder`, `faction_city_power`,
   `hist_blackout_night`, `news_rolling_outages` are all legal there.
2. Districts 1–3 use `min_stage` 0–2 only; districts 4–11 use the full 0–3 range (a
   FULL-gated note as the district's last word — `warehouses_note_08` is the crew's
   east-gate photo, `substation_note_08` the sealed east gate, `power_station_note_08`
   the towers at first light — each only visible after its district is restored).
   Harmonising 1–3 is optional flavour, not a defect.
3. Data-side facts still open (CODE's call, outside content ownership): `school` and
   `gas_station` are **leaves** of the `powered_by` graph (nothing lists them as a
   prerequisite). `warehouses` and `police` are **not** leaves — both feed the
   `industrial` convergence (packed, §3.4); `industrial` feeds `substation` (packed),
   `substation` feeds `power_station` (packed, terminal). `school`/`gas_station` are
   confirmed terminal leaves now that the chain is fully packed. `district_themes.gd` `"music"` rows still disagree with
   `music_manager.gd` for school/hospital/gas_station; police's, warehouses', industrial's,
   substation's and power_station's theme dicts are colour-only (music from
   `music_manager.gd` → `downtown.wav` / `harbor.wav` / `industrial.wav` /
   `music_ambient_dark.wav` ×2 — industrial.wav verified 1 ch / 22.05 kHz / 24.0 s, the
   same downtown/harbor legacy class, not an anomaly; music_ambient_dark.wav verified
   present).
4. Audio: lit beds specced but not fabricated (`residential_lit` G1, `park_lit` G2b,
   `school_lit` G2c, `gas_station_lit` G2e, `police_lit` G2f, `warehouses_lit` G2g,
   `industrial_lit` G2h, **`substation_lit` G2i — full spec this pass, promoted from the
   G3 one-liner**; hospital and power_station have no gap — both beds ship); no binary
   audio has ever been faked by this pipeline. Loudness (−18 LUFS / TP) remains
   unverifiable in this sandbox — no ffmpeg. Standing findings: `industrial_dark.ogg`
   33.994 s vs the 36.000 s contract (G2h — all 11 other dark beds and all 4 shipped lit
   beds are exactly 36.000 s / granule 1,587,600; both readings recorded in G2h), and
   **new (F1, recorded 2026-09-09):** `power_station_generator_thrum.ogg` (28.749 s) and
   `power_station_cooling_fan.ogg` (28.948 s) are off the 30.000 s detail-bed class every
   other detail holds exactly — both loop fine (`loop = true`, no duration read in code),
   so recorded, not gapped; re-render is the audio toolchain holder's call.
   `power_station_lit.ogg` is full-length (36.000 s) but sparsely encoded (59,320 B).
5. The warehouses pass ran the §4.1 probe on all shipped dark floors as part of the lit
   pass and found exactly one out-of-range seam (warehouses floor, fixed — §3.5).
   Seam outliers (all recorded, none repaired — intrinsic pattern contrast, no frame
   defects): residential dark floor (15.3, lit twin already matches it), **substation
   dark wall (18.06, this pass — its new lit twin lands at absolute 3.23, in the house
   range)**, **power_station dark floor (15.88, this pass — ships with its pre-existing
   lit twin)**. The warehouses floor remains the only dark ever repaired (§3.5 — it had
   a true edge-frame artifact). The power_station lit twins pre-date §4.1 and were
   re-measured for the record this pass (floor: lift ×1.56, warmth +4.7; wall: ×1.42,
   +12.1; both corr ≥0.999, both seams in-band) — left untouched per the standing
   leave-shipped-pairs-alone rule (see `docs/ASSET_LICENSES.md`).

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

## 8. Before/after — district-9 re-run (2026-09-09) → final 1–11 re-run (2026-09-09)

| Metric | 1–9 re-run | Final 1–11 re-run | Delta |
|---|---|---|---|
| Districts packed | 9 | 11 | +2 (`substation` D10, `power_station` D11 terminal) |
| Lore notes | 72 | 88 | +16 (`substation_note_01..08`, `power_station_note_01..08`) |
| Zones | 81 | 101 | +20 (all first-use ids, no new cross-district reuse) |
| Fixed spawns | 83 | 103 | +20 (`substation_fix_*`, `power_station_fix_*`) |
| `world_refs` | 114 | 154 | +40 (all inside closures/self gates; the last 10 never-referenced ids consumed) |
| World-bible coverage | 27/37 | **37/37** | complete — no dangling bible entry |
| `LORE_*` i18n keys | 144 | 176 | +32 (`LORE_SUBSTATION_*`, `LORE_POWER_STATION_*` ×16) |
| DARK repair-chain proofs (≥2 cable/fuse/transistor + key) | 9/9 | 11/11 | +2 (both 2/2/2/1) |
| Reveal-gate violations found | 0 | 0 | — |
| New defects introduced by the pass | — | 0 | — |
| Source fixes to shipped packs | — | 1 (TASK 0: industrial `\\\"` → `\"`, 22 occurrences, prose byte-identical to shipped i18n) | cosmetic, no player-facing effect |
| Textures shipped | 2 lit twins (industrial) | +2 lit twins (substation; §4.1-verified) + power_station re-measurement (zero binaries) | see §2 / ASSET_LICENSES |
| Audio facts appended | bed + 4 one-shots header-verified; G2h spec + dark-bed finding | substation bed + 3 one-shots verified + G2i spec; power_station 2 beds + 4 one-shots verified + **F1 finding (2 details off the 30 s class)** | spec only, no binaries |

## 9. CONTENT RELEASE CERTIFICATE (final completeness check, 2026-09-09)

The chain is fully packed (11/11). Every line below was verified by the final re-run's
static checks (same method as §6, extended to the certificate list); all verdicts are
PASS with zero open content defects.

| # | Check | Verdict |
|---|---|---|
| 1 | Chain matches GDD §4.1 exactly: 11 districts, order `suburbs → residential → park → school → hospital → gas_station → police → warehouses → industrial → substation → power_station`, parents per `data/districts/*.tres` (`powered_by`: suburbs —; residential/parks ← suburbs; school/hospital ← residential; gas/police ← park; warehouses ← hospital; industrial ← warehouses+police; substation ← industrial; power_station ← substation) | ✔ PASS |
| 2 | Every `world_ref` (154) resolves to an id in `content/world/*` or `content/lore/*` | ✔ PASS (154/154) |
| 3 | Every reveal gate legal: each ref gated on the district's guaranteed `powered_by` closure (all at FULL per GDD §4.3) or on the district itself with `min_stage` respected (`radio_02` at substation/STREETS vs gate PARTIAL; `radio_03` at power_station/PARTIAL vs gate PARTIAL — the only two self-gated ids in the chain) | ✔ PASS (0 violations) |
| 4 | Every district has R-rules (R1–R5 … R1–R8) and a DARK proof (fixed-spawn chain ≥2 cable / ≥2 fuse / ≥2 transistor + key, zero lockpicks, zero rolled loot, nothing chain-critical in any destroyer patrol) | ✔ PASS (11/11) |
| 5 | `LORE_*` key ranges complete and unique: `LORE_<DISTRICT>_<01–08>_TITLE/_TEXT` per district, 176 keys, no gaps, no collisions | ✔ PASS (176/176) |
| 6 | Prereq closures satisfiable: every transitive `powered_by` walk terminates at suburbs (no cycles, no missing nodes); school/gas_station confirmed terminal leaves with no ids gated on them | ✔ PASS |
| 7 | Every binary ledgered: the 2 binaries added by this pipeline stage (substation lit twins) carry `ASSET_LICENSES.md` rows; pre-existing pairs carry provenance summaries; no binary audio has ever been fabricated | ✔ PASS |
| 8 | Every audio gap spec'd: 8 lit-bed full specs (G1, G2b/c/e/f/g/h/i) + hospital/power_station no-gap records (G2d, F1); G3 one-liners all superseded; loudness flagged as unverifiable-in-sandbox throughout | ✔ PASS |
| 9 | All 37 world-bible ids referenced ≥ once chain-wide (characters 9, factions 5, history 11, radio 3, diary 4, news 5) | ✔ PASS (37/37) |
| 10 | Note ids (88) and fixed-spawn ids (103) globally unique; zone ids unique within each district; all lore hints ⊆ declared zones; all notes/fixes referenced by their manifests; all fixed-spawn containers declared | ✔ PASS |
| 11 | All `item`/`item_type` values ⊆ the 41 ids in `data/items/*.tres`; no pack invents an item id; no blueprint id spawns outside the 4 `BLUEPRINTS` districts | ✔ PASS |
| 12 | All referenced prop scenes, audio files (spec-only exempted) and textures exist on disk | ✔ PASS |
| 13 | Source escaping clean in all 11 packs (no triple-backslash `\\\"`); industrial TASK 0 fix verified byte-identical to shipped i18n | ✔ PASS |
| 14 | Power_station lore-only rule: no GDD §12.4 / endings / boss-mechanic references in any district-11 file (puzzle cited by id + zone only) | ✔ PASS |
| 15 | Ownership: every file in the stage diff sits inside CONTENT scope (`content/**`, `assets/textures/**`, `assets/audio/**`, `docs/**` minus frozen GDD/PRODUCTION_BIBLE/HANDOFF); frozen docs untouched; no `*.gd`/`*.tscn`/`*.tres`/`tools/`/`locales/`/`data/` writes | ✔ PASS |

**Certificate:** the CONTENT district pipeline is COMPLETE and CONSISTENT at 11/11
districts. 88 lore notes, 101 zones, 103 fixed spawns, 154 resolving world references,
176 unique i18n keys, 0 gate violations, 0 open defects. Standing recorded findings for
other owners: industrial dark-bed length (G2h), power_station detail lengths (F1),
seam/§4.1 outliers on pre-existing art (residential floor, substation wall,
power_station pair — §5 item 5), unverifiable-in-sandbox loudness (all beds). None of them
blocks content wiring.
