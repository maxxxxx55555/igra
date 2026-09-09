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

## Task: district `substation` (deep content pass, same template as the 9 done districts)

Nine districts are done and merged (`suburbs`, `residential`, `park`,
`school`, `hospital`, `gas_station`, `police`, `warehouses`,
`industrial`). Read `content/districts/industrial/` (most recent) and
`content/README.md` for the exact schema. **Read
`docs/CONTENT_PIPELINE_AUDIT.md` too** before starting — its re-run
after each district (most recently 1–9, 0 new defects) has repeatedly
caught real mistakes early; the same classes of mistake could repeat
here if skipped.

**Closure computation:** `data/districts/district_substation.tres` has
`powered_by = [&"industrial"]` — a single parent, but `industrial`
itself is the first two-parent convergence, so walk its own closure
too: `industrial → {warehouses → hospital → residential → suburbs} ∪
{police → park → suburbs}`. **Guaranteed history at arrival: suburbs,
residential, park, hospital, warehouses, police, industrial — seven
districts, all stages.** Every world id gated on any of those seven is
safe here. **NOT guaranteed:** `school`, `gas_station` (never on this
path) and `power_station` (a descendant, not an ancestor — substation
feeds *it*, not the other way around).

**Reveal-gate note, read carefully:** `radio_02_grid_crew_relay` is
gated on **substation** itself per `docs/CONTENT_WORLD_BIBLE.md` — this
is the first district where that id becomes legal to reference, but
only at whatever `min_stage` its own reveal entry specifies (check
`content/world/radio_transcripts.json` for the exact gate before using
it — a note in *this* pack referencing it must still respect
substation's *own* stage progression, not just "district reached").
`radio_03_keeper_reversal` remains gated on `power_station` (district
11) and stays out of this pack entirely.

Deliverables (all under `content/districts/substation/`):
1. `lore_notes.json` — 8 authored notes (mix of `document`/`photo`/
   `audio_log`), stage-gated (`min_stage` 0-3), ids `substation_note_01`
   through `_08`, i18n keys `LORE_SUBSTATION_<NN>_TITLE`/`_TEXT`.
   `world_refs` MUST be restricted to ids revealed by the seven-district
   closure above (plus `radio_02_grid_crew_relay` once substation's own
   gate gets checked, per the note above).
2. `item_spawns.json` — 4 stage loot tables, fixed puzzle-critical
   spawns guaranteeing the DARK→FULL chain (cable→PARTIAL, fuse→STREETS,
   transistor→FULL per `power_switch.gd`) — verify your own pack passes
   this. Container modifiers, rules (prose). Check `district_loot.gd`'s
   `BY_DISTRICT`/`BLUEPRINTS`/`STORY_DOC` dictionaries for substation's
   already-decided themed loot/blueprint/story-doc canon (code-owned,
   pre-exist your pass) and build the pack consistent with them — do
   not invent new item ids.
3. `prop_manifest.md` — zone plan (substation = transformer yard/relay
   room/control room/arc-flash cage per GDD canon), stage-state table,
   art/audio gaps listed explicitly. Zone ids are district-scoped (reuse
   across districts is fine — see `content/README.md`), but must stay
   unique within this pack.

Canon to follow: GDD.md §4 (district chain), §12.3 (Act mapping —
substation is D10, Act III territory, one step from the finale; confirm
its exact reveal boundary before deciding what's legal beyond the
seven-district closure). Every item id must already exist in
`data/items/*.tres` — never invent new item ids. Every prop/audio
reference must point at an asset that already exists — content never
blocks on art (YAGNI).

## Handoff doc
Write `docs/CONTENT_DISTRICT_SUBSTATION.md` (same shape as
`docs/CONTENT_DISTRICT_INDUSTRIAL.md`) — wiring checklist for the code
agent, i18n key list (16 keys, `LORE_SUBSTATION_<NN>_TITLE`/`_TEXT`) for
the locale agent (currently the local/Claude session, not a separate
Qwen agent — just list the keys, don't assume who translates them).
State your computed closure explicitly in this doc — it's what the code
agent double-checks first.

## Housekeeping (low priority, only if time allows)
`content/districts/industrial/lore_notes.json`'s `en.text` fields have
a literal double-escaped `\"` instead of a plain `"` wherever a note
quotes dialogue (all 8 notes) — cosmetic, already worked around on the
code side (see `docs/STATIC_AUDIT.md` #28), but worth cleaning up in
the source file next time `industrial` content is touched, so future
translators copying straight from the JSON don't inherit it.

## After this district
This file lives at the repo root, outside your ownership — don't edit
it. The local/code agent updates it to the final district
(`power_station`) once your PR is merged.
