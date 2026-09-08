# World Bible — index & contract

Owner: CONTENT. Single source of truth for factions, characters, timeline, radio, diary and
news lore. **District packs reference this data by id only — no copied text** (`world_refs`
arrays in `content/districts/*/lore_notes.json`; first pack to use it: `park`).

Frozen canon this file serves (never contradicts): `docs/GDD.md` §12.3 (three acts, radio
voice, Project Architect reveal, monsters = former people), §12.4 (endings), §4 (district
chain/stages). Visual/audio tone: `docs/STYLE_GUIDE.md`.

## Files

| File | Contents | Id prefix |
|---|---|---|
| `content/world/characters.json` | 9 characters incl. Keeper, crew, radio voice, Architect | `char_` |
| `content/world/factions.json` | 5 factions (City Power, Grid Crew, Street Watch, Keepers, Project Architect) | `faction_` |
| `content/world/history.json` | 11 timeline events, era vs. reveal split | `hist_` |
| `content/world/radio_transcripts.json` | 3 broadcasts (Act I call → Act III keeper answer) | `radio_` |
| `content/lore/diary_entries.json` | 4 diary fragments (Keeper ×3, Manya ×1) | `diary_` |
| `content/lore/news_clippings.json` | 5 clippings (outages, arena, trees, denial, meters) | `news_` |

## Rules

1. **Id discipline**: every `world_refs` / `refs` / `members` / `author` / `speaker` /
   `faction_refs` value must resolve to an id defined here or to a district note id
   (`<district>_note_NN`) that exists in that district's `lore_notes.json`. Validator:
   run each pack's cross-check (see PR gate notes).
2. **Stage-gating**: `reveal = {"district": <id>, "min_stage": 0..3}` uses
   `DistrictData.Stage` (GDD §4.2). `era` = when it happened; `reveal` = when the player
   learns it. CODE unlocks RADIO/JOURNAL entries by reveal.
3. **Act mapping** (GDD §12.3): Act I = D1–3 (suburbs/residential/park), Act II = D4–8
   (Project Architect reveal gates on hospital STREETS), Act III = D9–11.
   No Act II/III fact may reveal before its gate (validator enforces reveal pairs).
4. **i18n**: every user-facing entry carries `i18n_keys` + `en` source; pattern
   `WORLD_<TYPE>_<ID>_TITLE/_TEXT`. LOCALE agent adds to all 13 locales; count below.
5. Districts never inline character/faction prose — they point at ids (park notes do this;
   earlier packs predate the bible and may gain `world_refs` in polish passes).

## i18n key inventory (for LOCALE agent)

- Characters: 9 × 2 = 18 (`WORLD_CHAR_*`)
- Factions: 5 × 2 = 10 (`WORLD_FACTION_*`)
- Radio: 3 × 2 = 6 (`WORLD_RADIO_*`)
- Diary: 4 × 2 = 8 (`WORLD_DIARY_*`)
- News: 5 × 2 = 10 (`WORLD_NEWS_*`)
Total 52 keys; en source in the JSON `en` fields.

## Wiring checklist (CODE agent)

1. RADIO screen: unlock transcripts by `reveal` (radio_01 at park DARK = Act I call).
2. JOURNAL/bestiary-adjacent lore browser: characters/factions entries by reveal.
3. District pickup flow may attach `world_refs` metadata to notes for journal cross-links.
4. Gates after wiring: compile, signal arity, i18n, asset check (headless; CODE runs them —
   unavailable in this sandbox).
