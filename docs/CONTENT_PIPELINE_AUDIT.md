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

## 10. Finishing pass re-run (2026-09-09) — certificate re-verified, 0 defects

Fourth re-run of the full static audit, this time as the **finishing pass** (new session). Scope
per §9 certificate PLUS the store-kit checklist (§10.4). Method identical to §6/§9 (pure static
python over `content/**` + `data/**` + `assets/**` + `store/**`; no Godot/engine). Every §9
certificate line re-verified and unchanged against the 1–11 re-run; no regression introduced by
this pass.

### 10.1 Content certificate re-run (all 11 districts)

| Check | Scope | Result |
|---|---|---|
| R1 | All content JSON parse (lore_notes, item_spawns, world, lore, districts.json) | ✔ PASS (0 failures) |
| R2 | 88 lore-note ids, globally unique; ids byte-unchanged vs `db6367d` | ✔ PASS (88/88, 0 dup, 0 renamed) |
| R3 | 103 fixed-spawn ids, globally unique | ✔ PASS (103/103) |
| R4 | 176 `LORE_*` i18n keys unique; ranges `01..08` × `TITLE/_TEXT` complete per district | ✔ PASS (176/176, no gaps) |
| R5 | Every `item`/`item_type` value ⊆ the 41 `data/items/*.tres` ids | ✔ PASS (41/41) |
| R6 | Every `world_ref` (154) resolves to a world/lore bible id | ✔ PASS (154/154) |
| R7 | Reveal-gate legality: each ref's `reveal.district` ∈ the district's `powered_by` closure ∪ self (min_stage respected) | ✔ PASS (0 violations) |
| R8 | All `location_hint` zones and all fixed-spawn zones are declared zones of that district | ✔ PASS (0 undeclared) |
| R9 | World-bible coverage: all 37 ids (char 9, faction 5, hist 11, radio 3, diary 4, news 5) referenced ≥ once | ✔ PASS (37/37) |
| R10 | District chain complete in `data/districts/*.tres` (11 districts, `powered_by` matches GDD §4.1) | ✔ PASS (11/11) |
| R11 | Zone-id/note-id/fixed-id contracts per content/README | ✔ PASS (unchanged) |
| R12 | No content audio/texture gap regressed this pass (this pass added no district binaries) | ✔ PASS (0 new gaps) |

Content verdict: **0 defects.**

### 10.2 Prose finishing pass (Task 1)

Full editorial re-read of all 88 lore notes + world-bible prose. Conclusion: prose was already
Play-Store grade (short, atmospheric, canon-consistent, zero filler). One real orthographic
inconsistency fixed: the canonical "the center" spelled `centre` in two in-world requisition
forms written by the Keeper (gas_station_note_06, police_note_06); all 24 other in-world uses
are `center`. Structural properties untouched (R2–R12). Machine-readable change record for the
locale handoff: `docs/PROSE_CHANGES.md` (KEY\<TAB\>final en text).

| Changed i18n key | Field | Change |
|---|---|---|
| `LORE_GAS_STATION_06_TEXT` | en text | `...needed at the centre.` → `...needed at the center.` |
| `LORE_POLICE_06_TEXT` | en text | `...needed at the centre.` → `...needed at the center.` |

### 10.3 Audio CC0 sourcing attempt (Task 2) — spec retained, no binary fabricated

Web searches run per gap class (lit beds G1, G2b/c/e/f/g/h/i; F1; optional). No CC0/CC-BY track
satisfies the lit-twin contract (faithful re-voice of the district's own dark bed, exact loop
length, district-true material, no voices/people, −18 LUFS) and no audio encoder/loudness tool
exists in this sandbox to deliver any binary to contract. Full search record + reasoning:
`docs/ASSET_LICENSES.md` §"finishing pass: CC0 audio sourcing attempts". All audio gaps remain
spec-only. No fabricated audio. **(This does not re-open §9 rows 8/12/13/15.)**

### 10.4 Store-kit checklist (Task 3, `store/**`)

| Check | Deliverable | Result |
|---|---|---|
| S1 | `store/listing.md` — EN + RU title | ✔ PASS |
| S2 | `store/listing.md` — short desc, full desc, feature bullets, tags (EN + RU) | ✔ PASS |
| S3 | `store/changelog.md` — v1.0, EN + RU | ✔ PASS |
| S4 | `store/screenshots-plan.md` — 8 shots with scene/state/settings/language | ✔ PASS |
| S5 | `store/privacy-policy-template.md` — plain template + RU, owner placeholders | ✔ PASS |
| S6 | `store/feature-graphic.png` — 1024×500 | ✔ PASS |
| S7 | `store/icon-512.png` — 512×512 | ✔ PASS |
| S8 | Store art palette-clean (0 pure #000/#fff px) per STYLE_GUIDE §2 | ✔ PASS (0) |
| S9 | Store art + text ledgered project-owned in `docs/ASSET_LICENSES.md` | ✔ PASS |

Store verdict: **8/8 checks PASS.** (Store art is AI-generated in-session from in-house-style,
palette-locked prompts → project-owned, no third-party rights; no CC0 needed.)

### 10.5 Ownership / forbidden-path audit (session diff vs `db6367d`)

Changed files: `content/districts/{gas_station,police}/lore_notes.json`,
`docs/{PROSE_CHANGES,ASSET_LICENSES,AUDIO_COVERAGE}.md`, `store/**` (6 files). Scanned against
CONTENT scope (`content/**`, `assets/textures|audio/**`, `store/**`, `docs/**` minus frozen
GDD/PRODUCTION_BIBLE/HANDOFF): **0 forbidden-path writes** — no `*.gd`/`*.tscn`/`*.tres`,
no `tools/`, `scenes/`, `scripts/`, `data/`, `locales/`/`localization/`, no root `.md`; frozen
`docs/GDD.md`, `docs/PRODUCTION_BIBLE.md`, `docs/HANDOFF.md` untouched.

### 10.6 Verdict

Finishing-pass re-run: **content 12/12 PASS, store kit 8/8 PASS, ownership clean, 0 defects.**
The CONTENT RELEASE CERTIFICATE (§9) remains valid with no regression.

## 11. Mega final pass re-run (2026-09-10) — certificate re-verified, 0 defects

Fifth re-run of the full static audit, this time as the **mega final pass** (new session,
RELEASE CANDIDATE v1). Scope per §9 certificate PLUS the store-kit checklist (§10.4,
extended: trailer kit) PLUS the audio ladder re-run. Method identical to §6/§9 (pure static
python over `content/**` + `data/**` + `assets/**` + `store/**`; no Godot/engine). Every §9
certificate line re-verified; no regression introduced by this pass. Three initial flags
(R7/R10/R11c) resolved as **checker bugs, not pack defects** (§3.6/§3.8 precedent): the
re-run script first used wrong `data/districts/<d>.tres` filenames (real: `district_<d>.tres`
with `&"..."` parents) and counted blueprint *districts* instead of blueprint *ids* — see
§11.1 notes. Content packs themselves untouched except 3 prose strings (Task 3).

### 11.1 Content certificate re-run (all 11 districts)

| Check | Scope | Result |
|---|---|---|
| R1 | All content JSON parse (22 pack files + 4 world + 2 lore) | ✔ PASS (28/28, 0 failures) |
| R2 | 88 lore-note ids, globally unique, exact `<district>_note_01..08` set | ✔ PASS (88/88, 0 dup) |
| R3 | 103 fixed-spawn ids, globally unique, `<district>_fix_*` form | ✔ PASS (103/103) |
| R4 | 176 `LORE_*` i18n keys unique; `01..08` × `TITLE/_TEXT` complete per district | ✔ PASS (176/176, no gaps) |
| R5 | Every `item`/`item_type` value ⊆ `data/items/*.tres` ids | ✔ PASS (38 used ⊆ 42 data) |
| R6 | Every `world_ref` (154) resolves to a world/lore bible id | ✔ PASS (154/154) |
| R7 | Reveal-gate legality: each ref's `reveal.district` ∈ the district's `powered_by` closure ∪ self (min_stage respected; self-gated min_stage re-checked) | ✔ PASS (0 violations) |
| R8 | All `location_hint` zones and all fixed-spawn zones are declared zones of that district (101 zones chain-wide) | ✔ PASS (0 undeclared) |
| R9 | World-bible coverage: all 37 ids referenced ≥ once | ✔ PASS (37/37) |
| R10 | District chain complete in `data/districts/*.tres` (11 files, `powered_by` matches GDD §4.1 incl. industrial ← warehouses+police; no cycles, all walks terminate at suburbs) | ✔ PASS (11/11) |
| R11 | Zone/fixed-id contracts (containers declared, manifests reference all notes+fixes); spawned blueprint ids ⊆ the 4 `data/items` blueprint ids | ✔ PASS (unchanged) |
| R12 | No audio/texture gap regressed (8 spec-only lit beds still absent = no fabrication; all 14 shipped beds present) | ✔ PASS (0 new gaps) |
| R13 | Source escaping clean in all `content/**/*.json` (no `\\\"`) | ✔ PASS |
| R14 | Power_station lore-only rule (no endings/boss-mechanic refs in D11 files) | ✔ PASS |
| P1 | `docs/PROSE_CHANGES.md` handoff rows (5) byte-match JSON canon | ✔ PASS (5/5) |
| DARK | Repair-chain proofs by qty: suburbs 3/2/2/1, warehouses 3/2/2/1, all others 2/2/2/1 + key | ✔ PASS (11/11, matches §1) |

Content verdict: **0 defects.**

### 11.2 Prose final polish (Task 3)

Full editorial re-read of all 88 lore notes + world-bible prose (characters, factions,
history, radio, diary, news). Typo scan (double spaces outside README alignment: none;
common misspellings: none), title-length scan (none > 60 chars), orthography
(`center` consistent; the one `centre` is a non-player-facing `location_hint`,
out of handoff scope per §10.2). Three surgical upgrades, all verified as a 3-line
diff after a formatting-churn fixup commit (the first attempt rewrote 2 files'
indentation; restored to byte-identical formatting + 3 changed lines):

| Changed i18n key | Field | Change |
|---|---|---|
| `LORE_PARK_02_TEXT` | en text | flat caption ending → quotable kicker `Nobody in the queue knew the order would never be given again.` |
| `LORE_PARK_07_TEXT` | en text | `The voice is the same one as the manifesto's seal.` → `The voice belongs to whoever pressed the seal.` (voice/seal precision; the manifesto itself is canon per `LORE_PARK_01_TITLE`) |
| `LORE_POLICE_05_TEXT` | en text | flat clerk-log ending → in-voice kicker `The property book has never cleared six items faster.` |

Machine-readable handoff: `docs/PROSE_CHANGES.md` §"Changed rows (mega final pass)"
(KEY\<TAB\>final en text, 3 rows, byte-verified vs canon in P1). Structural properties
untouched (R2–R14 re-verified above).

### 11.3 Audio ladder re-run (Task 1) — spec retained, no binary fabricated

Skill discovery: `.opencode/skills/` (code/process/texture only), `docs/external_skills/`
(behavior doc only), `docs/superpowers/specs/` (design doc only), sandbox toolset
(spoken-word TTS — outputs voices every lit-bed spec forbids, cannot render seamless
instrumental loops). **No audio-generation skill exists in this session** — step (a)
impossible, recorded honestly. Step (b): CC0/CC-BY exact-match search re-run per gap
class (signaturesounds CC0 pack, selektaudio CC0 drones, freesound IanStarGem industrial
CC0 43.878 s stereo, PtrMan CC0 list, Envato/123RF non-qualifying Standard tracks) — no
source adopted: none is a faithful re-voice of its in-repo dark bed at the exact loop
length, and no `ffmpeg`/`ffprobe` exists in-sandbox to normalize/verify. Step (c): all
gaps **remain spec-only**. Static re-verification: all 11 dark beds + 3 lit beds + 40
details measure byte-identically to the 2026-09-09 record (36.000 s mono 44.1 kHz;
industrial dark 33.994 s per G2h; F1 pair 28.749/28.948 s, finding not gap). Full record:
`docs/ASSET_LICENSES.md` §"mega final pass: audio gap re-attempt (Task 1)",
`docs/AUDIO_COVERAGE.md` §"Mega-final-pass note". **(Does not re-open §9 rows 8/12/13/15.)**

### 11.4 Store-kit final + trailer kit (Tasks 2+4, `store/**`)

| Check | Deliverable | Result |
|---|---|---|
| S1 | `store/listing.md` — EN + RU title + quotable tagline (`Restore the light. Every streetlight is life.` / `Верни свет. Каждый фонарь — жизнь.`) | ✔ PASS |
| S2 | `store/listing.md` — short desc, full desc, punchy feature bullets, tags (EN + RU) | ✔ PASS |
| S3 | `store/changelog.md` — v1.0, EN + RU | ✔ PASS |
| S4 | `store/screenshots-plan.md` — 8 shots with scene/state/settings/language | ✔ PASS |
| S5 | `store/privacy-policy-template.md` — plain template + RU, owner placeholders | ✔ PASS |
| S6 | `store/feature-graphic.png` — 1024×500 | ✔ PASS |
| S7 | `store/icon-512.png` — 512×512 | ✔ PASS |
| S8 | Store art palette-clean (0 pure #000/#fff px) per STYLE_GUIDE §2 | ✔ PASS (0) |
| S9 | Store art + text ledgered project-owned in `docs/ASSET_LICENSES.md` | ✔ PASS |
| T1 | 3 wow-moment stills 1920×1080 (first restore, first ending, grid cascade), no HUD | ✔ PASS |
| T2 | 1 vertical shorts shot 1080×1920 (silhouette vs lit skyline) | ✔ PASS |
| T3 | 1 press-kit header 1600×900 (logo + tagline + 3 district thumbs) | ✔ PASS |
| T4 | Trailer art palette-clean (0 pure #000/#fff px, verified per file) | ✔ PASS (0) |
| T5 | `store/trailer/README.md` use-cases + `store/trailer.md` index + `store/press-kit.md` (review-copy instructions, contact template); all referenced art exists on disk | ✔ PASS |
| T6 | Trailer art ledgered project-owned in `docs/ASSET_LICENSES.md` | ✔ PASS |

Store verdict: **9/9 + trailer 6/6 PASS.** (Trailer art AI-generated in-session from
palette-locked prompts, deterministic Pillow post-process → project-owned, no
third-party rights; no CC0 needed.)

### 11.5 Ownership / forbidden-path audit (session diff vs `72a7edf`)

Changed files (15 incl. this section): `content/districts/{park,police}/lore_notes.json`,
`docs/{CONTENT_PIPELINE_AUDIT,PROSE_CHANGES,ASSET_LICENSES,AUDIO_COVERAGE}.md`,
`store/{listing,trailer,press-kit}.md`, `store/trailer/{README + 5 PNG masters}`. Scanned
against CONTENT scope (`content/**`, `assets/textures|audio/**`, `store/**`, `docs/**`
minus frozen GDD/PRODUCTION_BIBLE/HANDOFF): **0 forbidden-path writes** — no
`*.gd`/`*.tscn`/`*.tres`, no `tools/`, `scenes/`, `scripts/`, `data/`,
`locales/`/`localization/`, no root `.md`; frozen `docs/GDD.md`,
`docs/PRODUCTION_BIBLE.md`, `docs/HANDOFF.md` untouched.

### 11.6 Verdict

Mega-final-pass re-run: **content 17/17 PASS, store kit 9/9 + trailer 6/6 PASS,
ownership clean, 0 defects.** The CONTENT RELEASE CERTIFICATE (§9) remains valid with
no regression. RELEASE CANDIDATE v1 content/store scope: **CERTIFIED.**

## 12. Store-release-pass recreate re-audit (2026-09-10, GOLD MASTER v2) — 0 defects

Arena sessions closed by the owner; `store/**` + `docs/{ASSET_LICENSES,
CONTENT_PIPELINE_AUDIT}.md` reassigned to CLAUDE for this pass. The
`store-release-pass.tar.gz` was not present in Downloads/Desktop and the
supplied sha256 manifest was malformed (58–62 hex chars, not 64), so
**Path B (recreate)** was taken.

### 12.1 store/listing.md — 13-locale expansion

- EN + RU master block: **byte-untouched** (`git diff` shows additions
  only, 0 deletions).
- 13 `### <loc> — <name>` sections generated by
  `tools/gen_store_listing_locales.py` (committed). Title + tagline are
  the shipped in-game `menu_title` / `menu_subtitle` verbatim
  (professionally translated, `i18n_audit.py` MISSING: 0). Short / full /
  8 bullets / ASO tags for the 11 non-master locales are transcreated
  from the same vetted in-game vocabulary — recommend one native pass
  before submission; every claim is GDD-true.
- Script check (`--check`): **13/13 sections present**, every **Short ≤ 80**
  (max 73, EN). GREEN.

### 12.2 store/icon-adaptive/ — Android adaptive icon

- `foreground_1080x1080.png`, `background_1080x1080.png`, `README.md`,
  generated by `tools/gen_adaptive_icon.py` (committed) from
  `store/icon-512.png`, deterministic (no randomness).
- Verified (`--check`): both exactly **1080×1080**; foreground content
  **inside the 66% safe zone**, opaque-region extrema in `[16,216]`,
  transparent field; background **fully opaque**, extrema in `[16,216]`;
  **0 pure `#000`/`#fff`** texels in either layer. GREEN.
- Ledgered: `docs/ASSET_LICENSES.md` §"Added 2026-09-10 — GOLD MASTER v2".

### 12.3 store/review-responses.md — review ops

- **5 review classes** (crash/save-loss · performance · progression ·
  ads · praise+request), each with an EN + RU paste-ready template and an
  owner **Escalation** line wired to the matching `docs/KNOWN_ISSUES.md`
  entry (draw-calls, `DistrictLoot.populate()` guard, `AdService` ad
  timing, boot/save gates). Quick-router table included.

### 12.4 Ownership / forbidden-path audit

Changed in this pass: `store/{listing,review-responses}.md`,
`store/icon-adaptive/{README.md + 2 PNG}`,
`docs/{CONTENT_PIPELINE_AUDIT,ASSET_LICENSES}.md`,
`tools/gen_store_listing_locales.py`, `tools/gen_adaptive_icon.py`,
`export_presets.cfg` (adaptive-icon wiring), plus the CLAUDE-owned code
files from the GAP_TO_IDEAL execution (tracked in `PLAN.md` GOLD MASTER
v2). `store/**` + the two reassigned docs are in scope for this pass by
owner instruction (Arena closed, no conflict risk). `tools/` +
`export_presets.cfg` are CLAUDE's standing zone. Frozen `docs/GDD.md`,
`docs/PRODUCTION_BIBLE.md`, `docs/HANDOFF.md` untouched.

### 12.5 Verdict

Store-release-pass recreate: **listing 13/13, adaptive icon 2/2 + README,
review ops 5/5 classes, ledger + audit complete — 0 defects.** The
CONTENT RELEASE CERTIFICATE (§9) remains valid, no regression.
