# RETENTION CONTENT PASS v2 — Spec (2026-09-13)

Owner: CONTENT agent. Source files: `content/daily_challenges.json`,
`content/ngp_modifiers.json`, `content/captions.json`. Certificate:
`docs/CERT_RETENTION.md`. Validator: `validate_retention.py` (this dir).

## 1. Reference spec (implemented verbatim)

- **60 daily challenges**: keep original 30 (`data/daily_challenges.json`
  schema: id, type, target, reward), append 30 new (`kill_01/02/12/25/40`,
  `secret_01/04/06/10/24`, `streets_05/07/09/12/16`, `restore_07/08/09/10/11`,
  `play_30/45/60/90/120`) + 2 new types: `photo_01/03/05` (`photo_subject`,
  `wired:false`, `requires_signal EventBus.photo_captured`), `dark_05/10`
  (`no_flashlight_segment`, `wired:false`). Streak rewards 7/150, 30/750,
  100/3000 preserved.
- **6 NG+ modifiers** in `content/ngp_modifiers.json`: `long_night`
  (battery ×0.80), `whisper` (hunter_hearing ×0.70, loot ×0.90),
  `blackout_plus` (+1 dark district), `keepers_pact` (hints false,
  lore ×2.0), `sprint` (time_pressure true, cycle ×0.85, rewards ×1.5),
  `ghost` (crawlers_ignore true, achievements false). Pure data:
  `effects{multipliers:float, toggles:bool}` only. Stack rules:
  `exclusive_with`, `same_knob:"multiply"`, `gates:"NG+≥1"`.
- **28 captions**: 12 moments (`achievement:first_light/photographer/overload`,
  `ending:light/darkness`, `ng_plus_activated`, lore-note ids) in Keeper-log
  voice; 16 gallery (11 districts + 5 specials
  `night_zero/the_keeper/the_architect/babka_lamp/last_streetlight`).
- **Cert**: `docs/CERT_RETENTION.md` + `validate_retention.py` asserting
  60/6/28 counts, id uniqueness, float/bool-only effects, original-30 byte-eq,
  new-type `wired:false` gating, canon id whitelist. New i18n keys
  (`DAILY_*_FLAVOR` ×60, `NGP_*` ×12, `CAPTION_*` ×28) in a CODE-sync table
  (locales untouched).
- **Artifacts**: `docs/artifacts/retention/` with spec, validator, verify log.

## 2. Council decisions (ambiguous points, options + pick)

1. **i18n total "110" vs components 60+12+28=100.**
   (a) Trust header, invent 10 keys / (b) trust components, document slip /
   (c) ask. Pick (b): components are explicit and checkable; the header is
   arithmetic. Validator asserts 100; cert discloses.
2. **Reward scaling for new dailies.**
   (a) Flat rewards / (b) extrapolate each type's observed ratio /
   (c) designer-picked curve. Pick (b): kill ×10, secrets ×15, streets ×40,
   restore ×60, play ×6.5→rounded-to-5, photo ×25, dark ×30. Predictable,
   matches existing economy.
3. **`blackout_plus` "+1 dark district" under float/bool-only effects.**
   (a) Break the constraint with an int / (b) `toggles:{blackout_plus:true}` /
   (c) `multipliers:{extra_dark_districts:1.0}` + CODE-additive note.
   Pick (c): constraint holds; `notes` field (outside `effects`) tells CODE
   to `int()` it as an additive count.
4. **`exclusive_with` pairs.** (a) All empty / (b) full matrix /
   (c) two justified symmetric pairs. Pick (c): `long_night↔blackout_plus`
   (double-darkness unfair), `whisper↔sprint` (stealth vs speed fantasy).
5. **Moment lore-note picks (6).** Chose arc-central canon docs from
   `data/documents.json`: `doc_streetlight_manifesto`, `doc_final_light`,
   `doc_protocol_dawn`, `doc_blackout_news`, `doc_first_death`,
   `doc_voice_in_wires`. All exist; all Keeper-voiceable.
6. **`ending:darkness` vs CODE ending id `dark`.** Keep content id
   `darkness` (spec-verbatim) with explicit `code_id:"dark"` mapping per
   caption (`ACH_15 Darkness` / `ending_dark`). No silent rename.
7. **New-entry envelope.** (a) Bare 4-key schema / (b) +`i18n_key`/`en`/
   gating keys. Pick (b) for the NEW 30 only (loader uses `.get()`, safe);
   original 30 stay byte-identical. Follows `content/` lore-notes `en`-source
   convention.

## 3. CODE handoff (CODE agent owns all wiring)

1. Copy/sync `content/daily_challenges.json` → `data/daily_challenges.json`
   (shape-identical; manager ignores unknown keys). Note: rotation index
   changes from `%30` to `%60` — intended.
2. Add `signal photo_captured(subject_id: String)` to
   `scripts/events/event_bus.gd`; emit from photo flow
   (`scripts/systems/photo_mode.gd`); add `_tick("photo_subject",1)` wiring
   in `daily_challenge_manager.gd`; then flip `wired:true` on `photo_*`.
3. Define `no_flashlight_segment` tracking (suggested: `zone_reached` while
   flashlight off), wire `_tick`, then flip `wired:true` on `dark_*`.
4. Apply NGP modifiers in `new_game_plus.gd` loadout: enforce `NG+≥1` gate,
   `exclusive_with`, `same_knob:multiply`; `extra_dark_districts` is
   additive (`int`); `achievements:false` blocks `AchievementManager.unlock`.
5. Caption triggers per `trigger` fields in `content/captions.json`;
   `darkness`→`dark` mapping noted. Gallery titles reuse listed `title_key`s.
6. Locale agent: add the 100 keys (CODE-sync table in cert) to all 13 locales.

## 4. Scope hygiene

- CONTENT touched only: `content/daily*`, `content/ngp*`, `content/captions*`,
  `docs/CERT_RETENTION.md`, `docs/artifacts/retention/**`.
- `data/daily_challenges.json` untouched (byte-eq reference).
  `data/i18n/*` and `localization/*` untouched (validator proves zero leak).
- No `.gd`/`.tscn` changes, no new systems (yagni).

---
Skills: yagni, surgical-edit, council, self-commit
