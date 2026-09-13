# CERT_CONTENTDEPTH — Content Depth & Cross-Consistency Certificate

Pass: `content-depth` · Date: 2026-09-13 · Agent: CONTENT
Zone owned: `content/**` **except** `content/daily*` and `content/ngp*`; `docs/CERT_CONTENTDEPTH.md`; `docs/artifacts/content-depth/**`.
Base commit: `631e3a5` · Branch: `arena/01a09a11-igra`

**Result: 0 defects.** 3 pre-existing canon defects found and fixed in-zone; 26 canon
secrets authored; 17 i18n-only texts handed to CODE. Auditor re-resolves every ref by
construction (see §2).

---

## 1. Scope audited

29 JSON files under `content/**` (the `daily*`/`ngp*` exclusion matched nothing — no such
files exist in this repo, verified by the walk in `audit_content_depth.py`).

| Layer | Files | Entries |
|---|---|---|
| `content/districts/*/lore_notes.json` | 11 | 88 notes (8 per district) |
| `content/districts/*/item_spawns.json` | 11 | 103 fixed spawns, 101 zones |
| `content/world/{characters,factions,history,radio_transcripts}.json` | 4 | 9 + 5 + 11 + 3 |
| `content/lore/{diary_entries,news_clippings}.json` | 2 | 4 + 5 |
| `content/secrets.json` *(new this pass)* | 1 | 26 |

Cross-checked against: `docs/GDD.md` §4.1/§4.2/§4.3/§12.3, `docs/CONTENT_WORLD_BIBLE.md`,
`content/README.md` (id-scoping + reachability contract), `data/items/*.tres` (41 ids),
`data/districts/district_*.tres` (`powered_by`), `data/i18n/en.json` (1110 keys),
`docs/PLAYER_VISIBLE_CHANGES.md`.

---

## 2. Method — the auditor

`docs/artifacts/content-depth/audit_content_depth.py` (run: `python3
docs/artifacts/content-depth/audit_content_depth.py`; exit 0 = 0 defects). Raw run output
committed at `docs/artifacts/content-depth/audit_output.txt`.

This is the "verify-agent re-resolves every ref by grep post-fix" requirement, satisfied
mechanically rather than by hand: the auditor rebuilds the id table from source on every
run and resolves **243** references against it — 154 `world_refs` in district packs, 45
internal world-bible refs (`refs`/`members`/`faction_refs`), 44 `world_refs` in secrets —
plus 103 fixed-spawn `zone` values and 101 zone ids against their district's `zones` array,
and every `item`/`reward.item` against `data/items/*.tres`.

Checks: id uniqueness and naming contracts; ref resolution; GDD §12.3 act-gate legality;
the README `powered_by` reachability closure; `reveal.min_stage` domain; en.json canon
parity; orphan i18n keys; PLAYER_VISIBLE_CHANGES lore-count claims.

**Act-gate semantics are per-file**, and getting this wrong produced the pass's only
false positives. `radio_transcripts.json` and `secrets.json` derive `act` from
`reveal.district`/`district`, so a disagreement is a defect. `history.json`'s own
`_contract` defines `act` as the act of the **era** the event happened in (`era` = when it
happened, `reveal` = when the player learns it), so `act: 0` = pre-story and is legal for
the three pre-blackout entries regardless of where they surface. The auditor therefore
enforces act-vs-reveal equality only for the derived files, and for `history.json` forbids
only a post-story era (`act >= 1`) surfacing in an *earlier* act than it belongs to.

### 2.1 §12.3 gate legality — verified

Act mapping (GDD §12.3): Act I = D1–3 `suburbs, residential, park`; Act II = D4–8 `school,
hospital, gas_station, police, warehouses`; Act III = D9–11 `industrial, substation,
power_station`.

- All 37 world-bible entries have a `reveal{district, min_stage∈0..3}`; no reveal lands
  outside the chain.
- The Project Architect gate holds: `char_architect`, `faction_project_architect`,
  `hist_project_architect`, `news_architect_denied` all reveal at **hospital / min_stage 2**
  (STREETS), and every pack that references them either *is* hospital or has hospital in its
  guaranteed closure — and uses them at `min_stage >= 2` (warehouses/industrial/substation
  precedent).
- Reachability closure computed from `data/districts/district_*.tres` `powered_by`, walked
  transitively. `industrial` is the two-parent convergence (`powered_by = [warehouses,
  police]`), so its closure is the **union** of both branches — six districts. 0 violations.
- No Act II/III fact reveals before the hospital STREETS gate. 0 violations.

### 2.2 Id uniqueness — verified

88 note ids (`<district>_note_NN`), 103 fixed-spawn ids (`<district>_fix_<purpose>_NN`), 37
world ids, 26 secret ids (`secret_<district>_NN`): **all globally unique, 0 collisions**,
and no cross-namespace collision (no secret id equals a world or note id). Zone ids are
district-scoped per the README contract; 0 duplicates within any district.

---

## 3. TASK 1 — cross-consistency audit: findings and fixes

**3 defects found, 3 fixed, all in-zone.**

### 3.1 `radio_02_grid_crew_relay`: `act: 2` → `3`
**Defect (gate mismatch).** The `act` field disagreed with its own reveal gate:
`reveal = {substation, min_stage 1}`, and `substation` is D10 = **Act III**.
**Which side was wrong — evidence.** Three independent packs already documented this id as
Act III: `industrial/lore_notes.json` `_reachability_rule` ("the Act III broadcasts
radio_02/radio_03"), `warehouses/lore_notes.json` `_reachability_rule` ("No Act III ids
(radio_02_grid_crew_relay, radio_03_keeper_reversal)"), `substation/item_spawns.json`
`_comment` ("the first district where radio_02_grid_crew_relay … is legal"). `reveal` is
authoritative because CODE unlocks RADIO entries by `reveal` (world bible rule 2).
**Fix.** Metadata corrected to match the reveal. Pacing is unchanged and still matches the
bible's own summary ("Act I call → Act III keeper answer"): broadcast 1 is Act I, 2 and 3
are Act III.

### 3.2 `char_architect.first_mention`: `{school, null}` → `{hospital, hospital_note_07}`
**Defect (dead ref + reachability violation).** `note: null` resolved to nothing, and
`district: school` was unreachable: `district_school.tres` has `powered_by = [residential]`,
so school's guaranteed closure is `{residential, suburbs}` — no school note may carry a
hospital-gated id. School's own `prop_manifest.md` says so explicitly: "Architect reveal
gates at hospital STREETS — **nothing here may pre-empt it**."
**Fix.** Repointed to the first note that actually carries `char_architect`:
`hospital_note_07` ("Photo: Test Feeder Crew"), at `min_stage 2` — exactly the character's
reveal gate. (`hospital_note_06` introduces PROJECT ARCHITECT the *programme* via
`hist_`/`faction_`/`news_` ids, not the man.)

### 3.3 `char_architect.summary_en`: "from school onward" → "from hospital onward"
**Defect (canon slip).** Same reachability error as 3.2, in prose. The districts that may
legally reference `char_architect` are hospital plus those whose closure contains it —
`warehouses, industrial, substation, power_station`. `school` and `gas_station` are leaves
off that branch and may not.
**Fix.** Corrected and enumerated. `summary_en` is internal prose, **not** an i18n source
(no key maps to it — verified absent from `en.json`), so no locale sync is required.

### 3.4 Explicit non-defects (recorded so they are not "fixed" later)
The three `history.json` entries with `act: 0` (`hist_grid_built`, `hist_project_architect`,
`hist_trees_complaint`) are **correct** — see §2. `hist_project_architect` is the clearest
case: an Act-0 *era* (the project existed 12–3 years pre-blackout) with an Act-II *reveal*
(hospital/2) is exactly what the bible prescribes.

---

## 4. TASK 2 — secrets framework: branch decision and delivery

**Branch taken: expand to canon secrets** (not `codex_lore.json`). The framework **does**
exist in code — verified, not assumed:

| Component | Location |
|---|---|
| Working pickup (grants item, emits signal, toast) | `scripts/world/secret.gd` |
| Signal | `scripts/events/event_bus.gd:91` `signal secret_found(secret_id: String)` |
| Placeable scene | `scenes/props/secret.tscn` |
| 3 SECRET quests | `scripts/core/quest_manager.gd` `q_secrets_1..3` |
| Achievements | `scripts/systems/achievements_manager.gd` `secret_hunter`, `secrets_10` |
| Coin reward | `scripts/economy/rewards_manager.gd` `REWARD_SECRET = 50` |
| Persisted counter | `scripts/systems/progress_tracker.gd` `var secrets` |
| Ending gate | `scripts/core/endings.gd:52` `secrets >= 3` → `truth` ending |

**But the canon was empty.** No `secret_id` was set anywhere in the repo, `secret.tscn` was
instanced by no district scene (only `scripts/tools/_probe_inst.gd` references it), and all
12 `scenes/secrets/secret_room_*.tscn` were bare `Node3D` stubs with zero repo-wide
references. Consequence: the entire `secret_found` chain was unreachable in play, so the
Truth ending could never fire and 3 quests + 2 achievements were unobtainable. See §7 —
this is a CODE-zone handoff.

**Delivered: `content/secrets.json`, 26 canon secrets** (task band 24–30).

| District | Act | n | District | Act | n |
|---|---|---|---|---|---|
| suburbs | I | 2 | police | II | 2 |
| residential | I | 2 | warehouses | II | 2 |
| park | I | 3 | industrial | III | 3 |
| school | II | 2 | substation | III | 2 |
| hospital | II | 3 | power_station | III | 3 |
| gas_station | II | 2 | | | **26** |

Act split 7 / 11 / 8. Every entry carries: a `zone` id that exists in that district's
`item_spawns.json` `zones`; `act` **derived** from district; `min_stage ∈ 0..3`; a
`reward.item` verified against `data/items/*.tres` (22 distinct reward items, all valid);
`world_refs` restricted to the district's guaranteed closure (44 refs, 0 unreachable);
`SECRET_<DISTRICT>_<NN>_TITLE/_TEXT` keys with `en` source; and a `location_hint` whose
`(z_*)` mentions all resolve.

**Deep-lore brief satisfied through the secrets vehicle**, via four declared threads:

| Thread | n | Carries |
|---|---|---|
| `keeper_past` | 6 | Forty years of work orders, the height mark on the maple-row pole, house 24's tin, forty unfinished chess games, the sorted lamp boneyard, locker 41 |
| `architect_motive` | 7 | 206 consent forms, the cold-room calibration logs, the original proposal ("the city is already watching, we only propose to let it keep what it sees"), workshop B's nine-year private shift log |
| `center_fall` | 9 | Night zero, the shelter roster (11 of 90), morgue drawer nine opened from the inside, the night-three consignment "the ones from ward B", the last live feeder, the bunker's chalk night-count, the two-handed signal-loft logbook |
| `grid_crew` | 4 | Marat's lockbox, the bowser that was never a tanker, the broadcast log and its one caller, the made-up sixth bunk |

**Council pass on canon + tone.** Canon: Act I secrets hint at "the draw" and never name the
Architect (`secret_school_02` and `secret_residential_02` reference no gated id at all);
Act II/III facts stay behind their gates; no secret contradicts §12.3–12.4, the 40-years /
14,207-orders / 219-lamps figures, the "monsters are former people" rule, or the Keeper's
"keeps backwards" reversal. Tone: matches the existing packs — concrete artefacts, second
hand annotations, understated dread, ending on a quotable line; no mechanics talk, no UI
voice. Existing prose was **never** quoted or restated; secrets extend it (the pond glass
extends `diary_keeper_02`, the annotated clipping extends `news_architect_denied`).

---

## 5. TASK 3 — texts living only in i18n → CODE-sync table

`docs/artifacts/content-depth/i18n_only_texts.md` — **17 keys** whose prose exists in
`data/i18n/*.json`, is backed by no `content/**` entry, and appears in no `.gd`/`.tscn`/
`.tres` under `scripts/`, `scenes/` or `components/`. For these the locale file is the sole
source of truth, which inverts the repo rule that `content/**` owns authored content.

Keys: `tip1`, `tip2`, `tip3`, `menu_subtitle`, `tutorial_done`, `TUT_TO_GARAGE`,
`TUT_FIND_FLASHLIGHT`, `TUT_FIRST_SHADOW`, `TUT_GENERATOR_STEP1`, `DISTRICT_2_TOAST`,
`SCR_VKLYUCHITE_PERVYY_FONAR`, `SCR_VOSSTANOVITE_100_FONAREY`,
`SCR_PROGRESS_DOSTIZHENIY_28_56_50`, `SCR_PRODERZHALIS_S_DOKUMENTOV_NAYDENO_D_VOSSTANO`,
`Server created! Waiting for players...`, `Dyslexia Font (OpenDyslexic)`, and one
multi-line stats format key. Each is listed with its proposed `en` (current value verbatim)
for CODE to adopt or delete. **Locales were not touched.**

Related, and *not* a defect: `data/documents.json` and `data/districts.json` are legacy
Russian-only artefacts whose district ids (`outskirts`, `downtown`, `harbor`, `underground`)
are not in the GDD §4.1 chain. Both live in `data/`, outside this pass's zone. Flagged for
CODE, not fixed here.

---

## 6. TASK 4 — certification

| Assertion | Result | Evidence |
|---|---|---|
| Ids unique | **PASS** | 88 note + 103 fixed-spawn + 37 world + 26 secret ids, 0 collisions (§2.2) |
| Refs resolve | **PASS** | 243 world refs + 103 zone refs + 101 zone ids + 634 item refs, 0 dead (§2) |
| §12.3 gates legal | **PASS** | act mapping, Architect gate, reachability closure, reveal domain — 0 violations (§2.1) |
| Existing note texts frozen | **PASS** | see below |
| 0 defects | **PASS** | `0 ERROR, 53 WARN, 31 INFO`; both WARN classes are non-defects (§6.1) |

**Existing note texts frozen — proven by diff, not asserted.** Over `631e3a5..HEAD`:

```
content/secrets.json                 | 429 +++++++  (new file)
content/world/characters.json        |   5 +-
content/world/radio_transcripts.json |   5 +-
```

- `git diff --name-only 631e3a5..HEAD -- 'content/districts/*/lore_notes.json'` → **0 files**.
  All 88 notes across all 11 packs are byte-identical to base.
- `git diff` filtered to `"title":` / `"text":` lines in `content/world/` → **0 changes**.
  Every `en.title` and `en.text` — the i18n source strings for all 52 `WORLD_*` keys — is
  untouched. The only world-file edits are §3's `act`, `first_mention`, `summary_en`, two
  `_contract` clarifications, and two `_audit_2026_09_13` annotations.
- `data/i18n/**` and `locales/`: **not touched** (verified: no such paths in the diff).

### 6.1 The 53 WARNs are not defects
- **52 × `I18N_KEY_PENDING`** — the 26 secrets × 2 keys authored this pass and not yet in
  `en.json`. `content/README.md` assigns locale population to the LOCALE agent and forbids
  CONTENT from editing `data/i18n/`, so a freshly authored key awaiting handoff is the
  documented normal state, not a slip. Table:
  `docs/artifacts/content-depth/pending_locale_handoff.md`.
- **1 × `SECRET_ROOM_STUB`** — the 12 empty `secret_room_*.tscn`. CODE zone; see §7.

### 6.2 Reproduce

```
python3 docs/artifacts/content-depth/audit_content_depth.py   # exit 0 = 0 defects
```

---

## 7. Findings outside this zone (CODE handoff — not fixed here)

1. **Secrets are unreachable; the Truth ending cannot fire.** `scenes/secrets/secret_room_01..12.tscn`
   are bare `[node name="SecretRoomN" type="Node3D"]` with no script and no `secret_id`;
   nothing in the repo instances them or `scenes/props/secret.tscn`. With zero secrets
   obtainable, `endings.gd:52`'s `secrets >= 3` gate is unreachable, as are `q_secrets_1..3`,
   `secret_hunter` and `secrets_10`. `content/secrets.json` now supplies the canon: instance
   `scenes/props/secret.tscn` per entry, set `secret_id`/`item_id`/`amount` from `id`/`reward`,
   and gate on `min_stage`. 12 existing stub rooms cover 12 of the 26; the other 14 want
   placement inside existing district scenes.
2. **`content/districts/*/item_spawns.json` is not read by any script** (already recorded in
   `PLAN.md`: `district_loot.gd`'s flat `REPAIR_PARTS` covers the same solvability goal).
   The packs remain the authored source of truth; wiring is a CODE decision.
3. **Legacy `data/` files contradict the 11-district canon** — `data/districts.json`
   (5 districts: downtown/harbor/underground/…) and `data/documents.json` (`district:
   "outskirts"`, Russian-only, unlocalized).

## 8. Pending handoffs

| To | What | Where |
|---|---|---|
| LOCALE | 52 `SECRET_*` keys → 13 locales | `docs/artifacts/content-depth/pending_locale_handoff.md` |
| CODE | Adopt or delete 17 i18n-only texts | `docs/artifacts/content-depth/i18n_only_texts.md` |
| CODE | Wire 26 secrets from `content/secrets.json` | §7.1 |
