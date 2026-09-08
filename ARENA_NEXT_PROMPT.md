# Next Arena session — paste this whole file as the prompt

You are the CONTENT agent for THE LAST STREETLIGHT (Godot 4, GDD-driven
survival-stealth game about restoring a city's power grid district by
district). Work on a new branch `arena/<new-session-id>-igra`, open
**one PR** when done. Do not touch anything outside your ownership (see
below) — another agent (local/Claude, branch `main`) owns and wires
code, scenes, tools, `locales/**`, `data/i18n/**`.

## Ownership (hard boundary)
You may create/edit files ONLY under:
- `content/**`
- `levels/**`
- `assets/textures/**`, `assets/audio/**` (art/audio passes, e.g. lit
  tile twins — see `docs/STYLE_GUIDE.md` for the lit-twin convention)
- `docs/**` — EXCEPT `docs/GDD.md`, `docs/PRODUCTION_BIBLE.md` and
  `docs/HANDOFF.md`, which are frozen/owned elsewhere. Read them, never
  edit them.

Never touch: `*.gd`, `*.tscn`, `*.tres`, `tools/`, `locales/`,
`data/i18n/`, `PLAN.md`, `RELEASE_CHECKLIST.md`, `scenes/`, `data/`
(other than reading for reference/id validation), other `assets/**`
subfolders.

## Task: district `school` (deep content pass, same template as `suburbs`/`residential`/`park`)

Three districts are done and merged — read
`content/districts/park/` (most recent, uses `world_refs`) and
`content/README.md` for the exact schema. Follow it exactly: same
3-file set, same id conventions.

Deliverables (all under `content/districts/school/`):
1. `lore_notes.json` — 8 authored notes (mix of `document`/`photo`/
   `audio_log`), stage-gated (`min_stage` 0-3), ids `school_note_01`
   through `_08`, i18n keys `LORE_SCHOOL_<NN>_TITLE`/`_TEXT`. Use
   `world_refs` (see `docs/CONTENT_WORLD_BIBLE.md`) where a note
   naturally connects to an existing character/faction/history/radio/
   diary/news entry — don't invent new world-bible entries yourself,
   just reference by id.
2. `item_spawns.json` — 4 stage loot tables, fixed puzzle-critical
   spawns (this district's `cable`/`fuse`/`transistor` progression
   pieces — check `data/districts/district_school.tres` for
   `powered_by`, since the chain has had corrections before: verify,
   don't assume), container modifiers, rules (prose).
3. `prop_manifest.md` — zone plan (school = classrooms/gym/cafeteria
   per GDD canon), stage-state table, art/audio gaps listed explicitly.

Canon to follow: GDD.md §4 (district chain), §12.3 (Act I is D1-3:
suburbs/residential/park — school is Act II's start, the Project
Architect reveal begins gating around here per the world bible's act
mapping; don't reveal Act II facts before hospital STREETS per
`docs/CONTENT_WORLD_BIBLE.md` rule 3). Every item id must already exist
in `data/items/*.tres` — never invent new item ids. Every prop/audio
reference must point at an asset that already exists — content never
blocks on art (YAGNI).

## Handoff doc
Write `docs/CONTENT_DISTRICT_SCHOOL.md` (same shape as
`docs/CONTENT_DISTRICT_PARK.md`) — wiring checklist for the code agent,
i18n key list (16 keys, `LORE_SCHOOL_<NN>_TITLE`/`_TEXT`) for the
locale agent (currently the local/Claude session, not a separate Qwen
agent — just list the keys, don't assume who translates them).

## After this district
This file lives at the repo root, outside your ownership — don't edit
it. The local/code agent updates it to the next district (`hospital`,
then `gas_station → police → warehouses → industrial → substation →
power_station`) once your PR is merged.
