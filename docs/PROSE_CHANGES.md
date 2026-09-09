# PROSE_CHANGES — finishing-pass English prose edits (canon source → locale handoff)

Owner: CONTENT agent. Machine-readable handoff for CLAUDE / the locale agent.
Scope of the finishing pass: all **88 district lore notes** (`content/districts/*/lore_notes.json`)
plus the **world bible prose** (`content/world/*.json`, `content/lore/*.json` — characters,
factions, history, radio, diary, news). Goals per task: fix typos, canon inconsistencies and
tone drift; keep every id / i18n key / stage / gate **unchanged**; Play-Store-grade writing
(short, atmospheric, zero filler). `content/**` JSON remains the canon source.

## How to consume

One row per changed **i18n text** below, as `KEY<TAB>final_en_text` (tab-separated). Keys are
the `i18n_keys` values already present in the content JSON — the text after the tab is the
**authoritative final English string** and must replace the current English source for that key
in `data/i18n/*.json` (en) and, for translators, be marked changed in all 13 locales. Do **not**
rename keys; do **not** re-derive text from anywhere but the row below.

## Review conclusion (2026-09-09)

Re-read in full (11 district packs + world bible). No typos, no canon contradictions, no tone
drift found that required edits beyond the two lines below. Every gate-visible structural
property (ids, i18n keys, `min_stage`, stages, world-refs reachability, repair-chain proofs)
was re-verified unchanged in the §10 re-run (`docs/CONTENT_PIPELINE_AUDIT.md`).

The single real defect: the canonical concept "the center (of the city / the grid)" was spelled
`centre` in two in-world requisition forms (gas station, police) written by the same recurring
character — the Keeper — while all **24** other in-world uses across the 88 notes and the world
bible spell it `center` (American throughout). Standardized the two requisition REASON lines to
`center` for orthographic/canon consistency. (The `gas_station` pack's `location_hint` metadata
string keeps `centre`; hints are not player-facing prose and are outside this handoff contract.)

## Changed rows

LORE_GAS_STATION_06_TEXT	A station requisition pad, one page filled in by a hand that does not belong to a petrol station. "ITEM: canopy floodlight transformer, one. REASON: it will be needed at the center. AUTHORISED BY: —" and there the signature is just a small drawing of a streetlight inside a circle. Underneath, the manager's own biro: "Old man came at dusk, took the transformer, left this. Knew which bolt to loosen first. Said the ones he takes down are the ones they cannot drink. I didn't argue. Nobody's buying petrol anyway."

LORE_POLICE_06_TEXT	A release form that is not in the station's typeface. "ITEM: yard flood transformer, one. REASON: it will be needed at the center. AUTHORISED BY: —" and there the signature is the small streetlight-in-a-circle again. Underneath, the duty sergeant's own biro: "He knew which cage. He knew which bolt. He said the ones he takes down are the ones they cannot drink. I signed because the floods had already come on once with the switch off, and I would rather they were gone."
