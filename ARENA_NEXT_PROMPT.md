# Next Arena session — paste this whole file as the prompt

You are the CONTENT agent for THE LAST STREETLIGHT (Godot 4, GDD-driven
survival-stealth game about restoring a city's power grid district by
district). Work on branch `arena/<new-session-id>-igra`, open **one PR**
when done. Do not touch anything outside your ownership (see below) —
another agent (local/Claude, branch `main`) owns and will wire code,
scenes, tools, `locales/**`, `data/i18n/**`.

## Ownership (hard boundary)
You may create/edit files ONLY under:
- `content/**`
- `levels/**`
- `docs/**` — EXCEPT `docs/GDD.md` and `docs/PRODUCTION_BIBLE.md`, which
  are frozen canon. Read them, never edit them.

Never touch: `*.gd`, `*.tscn`, `*.tres`, `tools/`, `locales/`,
`data/i18n/`, `PLAN.md`, `RELEASE_CHECKLIST.md`, `scenes/`, `data/`
(other than reading for reference/id validation).

## Task: district `residential` (deep content pass, same template as `suburbs`)

`suburbs` was just completed and merged — read `content/districts/suburbs/`
(all 3 files) as your template and `content/README.md` for the exact
schema. Follow it exactly: same 3-file set, same id conventions.

Deliverables (all under `content/districts/residential/`):
1. `lore_notes.json` — 8 authored notes (mix of `document`/`photo`/
   `audio_log`), stage-gated (`min_stage` 0-3), ids `residential_note_01`
   through `_08`, i18n keys `LORE_RESIDENTIAL_<NN>_TITLE`/`_TEXT`.
2. `item_spawns.json` — 4 stage loot tables (DARK/PARTIAL/STREETS/FULL),
   fixed puzzle-critical spawns (this district's `cable`/`fuse`/
   `transistor` progression pieces — check `scripts/world/district_loot.gd`
   BY_DISTRICT dict via GitHub if you can read it, otherwise infer from
   GDD §4.2's power-stage pattern already established in suburbs),
   container modifiers, rules (prose).
3. `prop_manifest.md` — zone plan (residential = apartment blocks/
   courtyards per GDD canon, not detached houses like suburbs), stage-state
   table, art/audio gaps listed explicitly.

Canon to follow: GDD.md §4 (district chain, residential is #2), §12.3-12.4
(the Keeper, the blackout catastrophe arc). Every item id must already
exist in `data/items/*.tres` — never invent new item ids. Every prop/audio
reference must point at an asset that already exists — content never
blocks on art (YAGNI).

## Handoff doc
Write `docs/CONTENT_DISTRICT_RESIDENTIAL.md` (same shape as
`docs/CONTENT_DISTRICT_SUBURBS.md`) — wiring checklist for the code agent,
i18n key list for the locale agent (that agent is currently the local/
Claude session, not a separate Qwen agent — just list the keys, don't
assume who translates them).

## After this district
This file lives at the repo root, outside your ownership — don't edit it.
The local/code agent updates it to the next district (`school`, then
`hospital → gas_station → police → warehouses → industrial → substation →
power_station`) once your PR is merged.
