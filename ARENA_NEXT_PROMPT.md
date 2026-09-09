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

## Task: district `warehouses` (deep content pass, same template as the 7 done districts)

Seven districts are done and merged (`suburbs`, `residential`, `park`,
`school`, `hospital`, `gas_station`, `police`). Read
`content/districts/police/` (most recent) and `content/README.md` for
the exact schema — it includes the reachability rule and the
zone-id-is-district-scoped contract. **Read `docs/CONTENT_PIPELINE_AUDIT.md`
too** before starting — its re-run after each district (most recently
1–7, 0 new defects) has repeatedly caught real mistakes early (a
residential-gated `world_refs` leak in park, a missing transistor in
suburbs' DARK spawn table); the same classes of mistake could repeat
here if skipped.

Deliverables (all under `content/districts/warehouses/`):
1. `lore_notes.json` — 8 authored notes (mix of `document`/`photo`/
   `audio_log`), stage-gated (`min_stage` 0-3), ids `warehouses_note_01`
   through `_08`, i18n keys `LORE_WAREHOUSES_<NN>_TITLE`/`_TEXT`.
   `world_refs` (see `docs/CONTENT_WORLD_BIBLE.md`) MUST be restricted
   to ids revealed by `warehouses`'s own transitive `powered_by`
   closure — compute it yourself from `data/districts/district_warehouses.tres`
   (`powered_by = [hospital]`; hospital's own `powered_by = [residential]`;
   residential's own `powered_by = [suburbs]`), so the guaranteed
   history at arrival is **hospital + residential + suburbs only** — no
   park-, school-, gas_station-, or police-gated ids (those are
   separate branches, not required for hospital to reach FULL). This
   means the Act II "Project Architect" reveal (hospital STREETS,
   gated on `hospital` itself, not on warehouses) IS legal here — the
   player has necessarily seen hospital at FULL to arrive, so anything
   gated at hospital/STREETS or earlier is guaranteed. Park/gas_station/
   police material (Keeper, radio-voice, Channel 3) is NOT guaranteed
   and must not be referenced.
2. `item_spawns.json` — 4 stage loot tables, fixed puzzle-critical
   spawns guaranteeing the DARK→FULL chain (cable→PARTIAL, fuse→STREETS,
   transistor→FULL per `power_switch.gd`) — verify your own pack passes
   this, the way the audit's §3.1 fix did for suburbs. Container
   modifiers, rules (prose). Check `district_loot.gd`'s `BY_DISTRICT`/
   `BLUEPRINTS`/`STORY_DOC` dictionaries for warehouses' already-decided
   themed loot/blueprint/story-doc canon (these are code-owned and
   pre-exist your pass, same as they did for police) and build the pack
   consistent with them — do not invent new item ids.
3. `prop_manifest.md` — zone plan (warehouses = loading dock/storage
   racks/office/loading yard per GDD canon), stage-state table, art/
   audio gaps listed explicitly. Zone ids are district-scoped (reuse
   across districts is fine and already happens elsewhere — see
   `content/README.md`), but must stay unique within this pack.

Canon to follow: GDD.md §4 (district chain), §12.3 (Act mapping —
warehouses is D8, Act II territory; confirm against §12.3's Act
boundaries before deciding what's legal to reference beyond the
`powered_by` closure above). Every item id must already exist in
`data/items/*.tres` — never invent new item ids. Every prop/audio
reference must point at an asset that already exists — content never
blocks on art (YAGNI).

## Handoff doc
Write `docs/CONTENT_DISTRICT_WAREHOUSES.md` (same shape as
`docs/CONTENT_DISTRICT_POLICE.md`) — wiring checklist for the code
agent, i18n key list (16 keys, `LORE_WAREHOUSES_<NN>_TITLE`/`_TEXT`) for
the locale agent (currently the local/Claude session, not a separate
Qwen agent — just list the keys, don't assume who translates them).
State your computed `powered_by` closure explicitly in this doc, the
way the police/gas_station/school handoffs did — it's what the code
agent double-checks first.

## After this district
This file lives at the repo root, outside your ownership — don't edit
it. The local/code agent updates it to the next district
(`industrial` — note `industrial.powered_by = [warehouses, police]`,
a two-parent convergence, so its guaranteed closure is the union of
both branches' histories — then `substation → power_station`) once
your PR is merged.
