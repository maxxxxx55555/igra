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

## Task: district `police` (deep content pass, same template as the 6 done districts)

Six districts are done and merged (`suburbs`, `residential`, `park`,
`school`, `hospital`, `gas_station`). Read `content/districts/gas_station/`
(most recent) and `content/README.md` for the exact schema — it now
includes the reachability rule and the zone-id-is-district-scoped
contract added by `docs/CONTENT_PIPELINE_AUDIT.md`'s 2026-09-08 audit.
**Read that audit doc too** before starting — it found and fixed real
issues in earlier packs (a residential-gated `world_refs` leak in park,
a missing transistor in suburbs' DARK spawn table) that the same
mistakes could repeat here if skipped.

Deliverables (all under `content/districts/police/`):
1. `lore_notes.json` — 8 authored notes (mix of `document`/`photo`/
   `audio_log`), stage-gated (`min_stage` 0-3), ids `police_note_01`
   through `_08`, i18n keys `LORE_POLICE_<NN>_TITLE`/`_TEXT`.
   `world_refs` (see `docs/CONTENT_WORLD_BIBLE.md`) MUST be restricted
   to ids revealed by `police`'s own transitive `powered_by` closure —
   compute it yourself from `data/districts/district_police.tres`
   (`powered_by = [park]`, and park's own `powered_by = [suburbs]`), so
   the guaranteed history at arrival is **suburbs + park only** — no
   residential- or hospital-gated ids (same rule that caught the park
   pack's mistake). The Keeper/radio-voice material is legal here (park
   is guaranteed); Act II Architect ids are NOT (hospital is a separate
   branch, not guaranteed before police).
2. `item_spawns.json` — 4 stage loot tables, fixed puzzle-critical
   spawns guaranteeing the DARK→FULL chain (cable→PARTIAL, fuse→STREETS,
   transistor→FULL per `power_switch.gd`) — verify your own pack passes
   this, the way the audit's §3.1 fix did for suburbs. Container
   modifiers, rules (prose).
3. `prop_manifest.md` — zone plan (police = station front desk/holding
   cells/evidence room/armory per GDD canon), stage-state table, art/
   audio gaps listed explicitly. Zone ids are district-scoped (reuse
   across districts is fine and already happens elsewhere — see
   `content/README.md`), but must stay unique within this pack.

Canon to follow: GDD.md §4 (district chain), §12.3 (Act mapping — police
is still Act I/early Act II territory, same non-Architect restriction as
above). Every item id must already exist in `data/items/*.tres` — never
invent new item ids. Every prop/audio reference must point at an asset
that already exists — content never blocks on art (YAGNI).

## Handoff doc
Write `docs/CONTENT_DISTRICT_POLICE.md` (same shape as
`docs/CONTENT_DISTRICT_GAS_STATION.md`) — wiring checklist for the code
agent, i18n key list (16 keys, `LORE_POLICE_<NN>_TITLE`/`_TEXT`) for the
locale agent (currently the local/Claude session, not a separate Qwen
agent — just list the keys, don't assume who translates them). State
your computed `powered_by` closure explicitly in this doc, the way the
gas_station/school/hospital handoffs did — it's what the code agent
double-checks first.

## After this district
This file lives at the repo root, outside your ownership — don't edit
it. The local/code agent updates it to the next district (`warehouses`,
then `industrial → substation → power_station`) once your PR is merged.
