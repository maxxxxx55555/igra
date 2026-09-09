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

## Task: district `industrial` (deep content pass, same template as the 8 done districts)

Eight districts are done and merged (`suburbs`, `residential`, `park`,
`school`, `hospital`, `gas_station`, `police`, `warehouses`). Read
`content/districts/warehouses/` (most recent) and `content/README.md`
for the exact schema. **Read `docs/CONTENT_PIPELINE_AUDIT.md` too**
before starting — its re-run after each district (most recently 1–8,
0 new defects) has repeatedly caught real mistakes early; the same
classes of mistake could repeat here if skipped.

**This district is different from every one so far: it is the first
two-parent convergence.** `data/districts/district_industrial.tres`
has `powered_by = [&"warehouses", &"police"]` — GDD §4.3 requires
*both* prerequisites at FULL, not just one, so compute the closure as
the union of both branches, not a single chain:
- `warehouses` branch: `warehouses → hospital → residential → suburbs`
- `police` branch: `police → park → suburbs`
- **Union (guaranteed history at arrival): `suburbs`, `residential`,
  `park`, `hospital`, `warehouses`, `police` — six districts, all
  stages.** Every world id gated on any of those six is safe here
  regardless of its own `min_stage`, including the Act II Project
  Architect set (hospital-gated, already guaranteed via the warehouses
  branch) and Keeper/radio-voice material (park-gated, guaranteed via
  the police branch) — this is the first district where *both* of
  those threads can be referenced together.
- **NOT guaranteed:** `school`, `gas_station` — neither is an ancestor
  of either branch. No ids gated on those two.

Deliverables (all under `content/districts/industrial/`):
1. `lore_notes.json` — 8 authored notes (mix of `document`/`photo`/
   `audio_log`), stage-gated (`min_stage` 0-3), ids `industrial_note_01`
   through `_08`, i18n keys `LORE_INDUSTRIAL_<NN>_TITLE`/`_TEXT`.
   `world_refs` (see `docs/CONTENT_WORLD_BIBLE.md`) MUST be restricted
   to ids revealed by the six-district union above — double-check every
   id against both branches before use, since this is the easiest
   closure computation to get wrong so far (a single-parent mistake
   here means checking the wrong branch, not just the wrong depth).
2. `item_spawns.json` — 4 stage loot tables, fixed puzzle-critical
   spawns guaranteeing the DARK→FULL chain (cable→PARTIAL, fuse→STREETS,
   transistor→FULL per `power_switch.gd`) — verify your own pack passes
   this. Container modifiers, rules (prose). Check `district_loot.gd`'s
   `BY_DISTRICT`/`BLUEPRINTS`/`STORY_DOC` dictionaries for industrial's
   already-decided themed loot/blueprint/story-doc canon (code-owned,
   pre-exist your pass) and build the pack consistent with them — do
   not invent new item ids.
3. `prop_manifest.md` — zone plan (industrial = factory floor/assembly
   line/loading dock/foreman catwalk per GDD canon), stage-state table,
   art/audio gaps listed explicitly. Zone ids are district-scoped (reuse
   across districts is fine — see `content/README.md`), but must stay
   unique within this pack.

Canon to follow: GDD.md §4 (district chain), §12.3 (Act mapping —
industrial is D9; confirm its Act boundary before deciding what's legal
beyond the six-district closure above). Every item id must already
exist in `data/items/*.tres` — never invent new item ids. Every prop/
audio reference must point at an asset that already exists — content
never blocks on art (YAGNI).

## Handoff doc
Write `docs/CONTENT_DISTRICT_INDUSTRIAL.md` (same shape as
`docs/CONTENT_DISTRICT_WAREHOUSES.md`) — wiring checklist for the code
agent, i18n key list (16 keys, `LORE_INDUSTRIAL_<NN>_TITLE`/`_TEXT`) for
the locale agent (currently the local/Claude session, not a separate
Qwen agent — just list the keys, don't assume who translates them).
State your computed **two-branch union** closure explicitly in this
doc — it's what the code agent double-checks first, and it's the part
most likely to need a second look given the new convergence shape.

## After this district
This file lives at the repo root, outside your ownership — don't edit
it. The local/code agent updates it to the next district (`substation`,
then `power_station` — the final district) once your PR is merged.
