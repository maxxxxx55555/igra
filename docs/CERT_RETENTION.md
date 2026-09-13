# CERT_RETENTION.md — Retention Content Pass v2 certificate (2026-09-13)

Owner: CONTENT agent. Verdict basis: `docs/artifacts/retention/validate_retention.py`
(270 checks, ALL PASS, exit 0) + inline VERIFY-AGENT runs logged in
`docs/artifacts/retention/verify_log.md`. No engine runs (content-only pass;
`godot-gates` needs the Windows-only Godot binary — N/A in this sandbox).

## 1. Counts — PASS

| Deliverable | Spec | Shipped | File |
|---|---|---|---|
| Daily challenges | 60 (30 orig + 30 new) | 60 | `content/daily_challenges.json` |
| NG+ modifiers | 6 | 6 | `content/ngp_modifiers.json` |
| Captions (12 moments + 16 gallery) | 28 | 28 | `content/captions.json` |
| New i18n keys (CODE-sync, locales untouched) | 60+12+28 (see §6) | 100 | this file, §7 |

Validator: `PASS 270 checks / RESULT: ALL PASS`.

## 2. Daily challenges — PASS

- Original 30 entries **byte-equal** to `data/daily_challenges.json`
  (per-line comparison modulo the list-separator comma on entry #30, which
  must gain one because the list continues; plus per-field assertion on
  `id/type/target/reward`).
- New 30 ids exactly the spec set: `kill_01/02/12/25/40`,
  `secret_01/04/06/10/24`, `streets_05/07/09/12/16`, `restore_07–11`,
  `play_30/45/60/90/120`, `photo_01/03/05`, `dark_05/10`.
- Rewards extrapolate each type's observed ratio (kill ×10, secrets ×15,
  streets ×40, restore ×60, play ×6.5→rounded-to-5, photo ×25, dark ×30).
- Streak rewards preserved: 7/150, 30/750, 100/3000.
- File shape mirrors `data/` (`templates` + `streak_rewards`) so CODE can
  sync it directly; the live loader uses `.get()`, so the new entries'
  extra keys (`i18n_key`, `en`, `wired`, `requires_signal`) are inert.
- `data/daily_challenges.json` untouched — sha256 still
  `c8f5bf7d6084ff9e35e8fd1825a7793858407d604fe522a1309f8e87b12a952c`.

## 3. New-type gating — PASS (honest `wired:false`)

- `photo_subject` (3 entries): `wired:false` +
  `requires_signal:"EventBus.photo_captured"`. Verified: that signal does
  NOT exist in `scripts/events/event_bus.gd` yet — CODE must add it, emit
  from the photo flow, and wire `_tick("photo_subject",1)`.
- `no_flashlight_segment` (2 entries): `wired:false`, no signal yet —
  CODE defines tracking (suggested: `zone_reached` while flashlight off).
- All other 55 entries use the 5 live-tracked types and are NOT gated.
- `dark_*/photo_*` semantics + CODE steps: `RETENTION_SPEC.md` §3.

## 4. NG+ modifiers — PASS

- 6/6 ids, unique; `effects` keys exactly `{multipliers, toggles}`;
  every multiplier is float, every toggle is bool (bool-excluded check).
- `gates:"NG+≥1"` global + per modifier (NG+ cap is 3 per
  `scripts/systems/new_game_plus.gd`); `stacking.same_knob:"multiply"`.
- `exclusive_with` symmetric: `long_night↔blackout_plus`
  (double-darkness unfair), `whisper↔sprint` (stealth vs speed fantasy);
  `keepers_pact`/`ghost` open.
- `blackout_plus` "+1 dark district" is carried as
  `multipliers:{extra_dark_districts:1.0}` with a CODE-additive note
  (constraint preserved; see spec §2.3).

## 5. Captions — PASS

- 12 moments, Keeper-log voice: 3 achievements (`first_light`→ach_01,
  `photographer`→ach_09, `overload`→ach_08), 2 endings (`light`,
  `darkness`→CODE id `dark`, mapped explicitly), `ng_plus_activated`,
  6 canon lore-notes (all exist in `data/documents.json`).
- 16 gallery: 11 districts in exact GDD §4 chain order + 5 specials
  (`night_zero`, `the_keeper`, `the_architect`, `babka_lamp`,
  `last_streetlight`).
- Every `title_key` exists in `data/i18n/en.json` (or is null for
  self-titled specials); gallery titles reuse `DISTRICT_NAME_*` /
  `WORLD_CHAR_*` keys — no new title keys needed.

## 6. Disclosures (nothing hidden)

1. **Brief says "110 keys" but itemizes 60+12+28=100.** Components win;
   validator asserts `i18n-total-100`. Council note in spec §2.1.
2. **`ending:darkness` vs CODE `dark`.** Content id kept spec-verbatim;
   each caption carries explicit `code_id:"dark"` (`ACH_15` / `ending_dark`).
3. **Verify log filename.** `verify.log` is uncommittable (`*.log` is
   gitignored; AGENTS.md forbids `.log` commits) → shipped as
   `docs/artifacts/retention/verify_log.md` (same content role).
4. **Rotation consequence.** Syncing 60 templates changes the daily rotation
   from `%30` to `%60` — intended per spec ("append 30 new").
5. **Loudness-style caveat, retention edition:** flavor/caption prose is
   certified as authored en source only; translation quality in 13 locales
   is the locale agent's gate, not this cert's.

## 7. CODE-sync i18n table — 100 keys, status: PENDING (locales untouched)

Validator proves zero of these keys exist in `data/i18n/en.json` today
(`i18n-not-in-locales`). Locale agent: add all rows to all 13 locales.
CODE: `tr()` them at the listed sites. `en` = source string.

### 7a. DAILY_*_FLAVOR ×60 (daily card flavor; first 30 = original challenges)

| Key | Challenge | en source | Status |
|---|---|---|---|
| `DAILY_KILL_03_FLAVOR` | `kill_03` kill_enemies×3 | Three shadows. Three reunions with the dark. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_KILL_05_FLAVOR` | `kill_05` kill_enemies×5 | Five gone. The street breathes easier. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_KILL_08_FLAVOR` | `kill_08` kill_enemies×8 | Eight. Count the lamps you saved, not the kills. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_KILL_10_FLAVOR` | `kill_10` kill_enemies×10 | Ten shadows. A full night's honest work. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_KILL_15_FLAVOR` | `kill_15` kill_enemies×15 | Fifteen. The grid crew would pin a medal on you. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_KILL_20_FLAVOR` | `kill_20` kill_enemies×20 | Twenty. Tonight the dark learns your name. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_SECRET_02_FLAVOR` | `secret_02` find_secrets×2 | Two secrets. The city hides; you seek. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_SECRET_03_FLAVOR` | `secret_03` find_secrets×3 | Three secrets. Tucked where only the patient look. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_SECRET_05_FLAVOR` | `secret_05` find_secrets×5 | Five secrets. Someone left them for you. Find them. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_SECRET_08_FLAVOR` | `secret_08` find_secrets×8 | Eight secrets. The walls are starting to trust you. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_SECRET_12_FLAVOR` | `secret_12` find_secrets×12 | Twelve secrets. Archivist of the blackout. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_SECRET_16_FLAVOR` | `secret_16` find_secrets×16 | Sixteen secrets. Nothing stays buried tonight. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_STREETS_01_FLAVOR` | `streets_01` light_streets×1 | One street. Light it like it's the last one. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_STREETS_02_FLAVOR` | `streets_02` light_streets×2 | Two streets. The grid remembers every lamp. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_STREETS_03_FLAVOR` | `streets_03` light_streets×3 | Three streets. A constellation, wired by hand. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_STREETS_04_FLAVOR` | `streets_04` light_streets×4 | Four streets. Walk home under your own light. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_STREETS_06_FLAVOR` | `streets_06` light_streets×6 | Six streets. The dark retreats block by block. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_STREETS_08_FLAVOR` | `streets_08` light_streets×8 | Eight streets. Tonight the map glows. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_RESTORE_01_FLAVOR` | `restore_01` restore_districts×1 | One district. Bring it back to FULL. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_RESTORE_02_FLAVOR` | `restore_02` restore_districts×2 | Two districts. The grid wakes up hungry. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_RESTORE_03_FLAVOR` | `restore_03` restore_districts×3 | Three districts. Momentum is a kind of fuel. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_RESTORE_04_FLAVOR` | `restore_04` restore_districts×4 | Four districts. The Keeper is watching. Proudly. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_RESTORE_05_FLAVOR` | `restore_05` restore_districts×5 | Five districts. Half the city owes you light. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_RESTORE_06_FLAVOR` | `restore_06` restore_districts×6 | Six districts. Past the point of no return — forward. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_PLAY_03_FLAVOR` | `play_03` play_minutes×3 | Three minutes. A short patrol. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_PLAY_05_FLAVOR` | `play_05` play_minutes×5 | Five minutes. Walk the beat. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_PLAY_08_FLAVOR` | `play_08` play_minutes×8 | Eight minutes. The night shift begins. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_PLAY_12_FLAVOR` | `play_12` play_minutes×12 | Twelve minutes. Settle in; the dark is patient. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_PLAY_15_FLAVOR` | `play_15` play_minutes×15 | Fifteen minutes. A quarter hour of held light. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_PLAY_20_FLAVOR` | `play_20` play_minutes×20 | Twenty minutes. A real shift. | PENDING (cert-only (orig entry byte-eq)) |
| `DAILY_KILL_01_FLAVOR` | `kill_01` kill_enemies×1 | One shadow. Every long night starts with one. | PENDING (content JSON) |
| `DAILY_KILL_02_FLAVOR` | `kill_02` kill_enemies×2 | Two shadows. Warm up the flashlight. | PENDING (content JSON) |
| `DAILY_KILL_12_FLAVOR` | `kill_12` kill_enemies×12 | Twelve. A dozen reasons the lamps stay lit. | PENDING (content JSON) |
| `DAILY_KILL_25_FLAVOR` | `kill_25` kill_enemies×25 | Twenty-five. Marat's whole shift quota in one night. | PENDING (content JSON) |
| `DAILY_KILL_40_FLAVOR` | `kill_40` kill_enemies×40 | Forty. One for every year the Keeper kept the lamps. | PENDING (content JSON) |
| `DAILY_SECRET_01_FLAVOR` | `secret_01` find_secrets×1 | One secret. Start where the wiring hums. | PENDING (content JSON) |
| `DAILY_SECRET_04_FLAVOR` | `secret_04` find_secrets×4 | Four secrets. Check behind the fuse boxes. | PENDING (content JSON) |
| `DAILY_SECRET_06_FLAVOR` | `secret_06` find_secrets×6 | Six secrets. The quiet corners pay out. | PENDING (content JSON) |
| `DAILY_SECRET_10_FLAVOR` | `secret_10` find_secrets×10 | Ten secrets. A full page in the Keeper's log. | PENDING (content JSON) |
| `DAILY_SECRET_24_FLAVOR` | `secret_24` find_secrets×24 | Twenty-four. Every hidden thing in one night. Legend work. | PENDING (content JSON) |
| `DAILY_STREETS_05_FLAVOR` | `streets_05` light_streets×5 | Five streets. A fistful of dawn. | PENDING (content JSON) |
| `DAILY_STREETS_07_FLAVOR` | `streets_07` light_streets×7 | Seven streets. Lucky current. | PENDING (content JSON) |
| `DAILY_STREETS_09_FLAVOR` | `streets_09` light_streets×9 | Nine streets. The grid hums your name. | PENDING (content JSON) |
| `DAILY_STREETS_12_FLAVOR` | `streets_12` light_streets×12 | Twelve streets. A whole district's worth of dawn. | PENDING (content JSON) |
| `DAILY_STREETS_16_FLAVOR` | `streets_16` light_streets×16 | Sixteen streets. Light the city like it's Night Zero in reverse. | PENDING (content JSON) |
| `DAILY_RESTORE_07_FLAVOR` | `restore_07` restore_districts×7 | Seven districts. The blackout is losing. | PENDING (content JSON) |
| `DAILY_RESTORE_08_FLAVOR` | `restore_08` restore_districts×8 | Eight districts. Hold the line, lamp by lamp. | PENDING (content JSON) |
| `DAILY_RESTORE_09_FLAVOR` | `restore_09` restore_districts×9 | Nine districts. Almost the whole grid humming. | PENDING (content JSON) |
| `DAILY_RESTORE_10_FLAVOR` | `restore_10` restore_districts×10 | Ten districts. One short of a miracle. | PENDING (content JSON) |
| `DAILY_RESTORE_11_FLAVOR` | `restore_11` restore_districts×11 | Eleven districts. The whole city. All of it. FULL. | PENDING (content JSON) |
| `DAILY_PLAY_30_FLAVOR` | `play_30` play_minutes×30 | Thirty minutes. Half an hour against the dark. | PENDING (content JSON) |
| `DAILY_PLAY_45_FLAVOR` | `play_45` play_minutes×45 | Forty-five. The lamps know your footsteps by now. | PENDING (content JSON) |
| `DAILY_PLAY_60_FLAVOR` | `play_60` play_minutes×60 | Sixty minutes. A full hour. The Keeper nods. | PENDING (content JSON) |
| `DAILY_PLAY_90_FLAVOR` | `play_90` play_minutes×90 | Ninety minutes. Overtime in the light brigade. | PENDING (content JSON) |
| `DAILY_PLAY_120_FLAVOR` | `play_120` play_minutes×120 | Two hours. A full watch. Log it with pride. | PENDING (content JSON) |
| `DAILY_PHOTO_01_FLAVOR` | `photo_01` photo_subject×1 | One subject. Frame something worth remembering. | PENDING (content JSON) |
| `DAILY_PHOTO_03_FLAVOR` | `photo_03` photo_subject×3 | Three subjects. The city's portrait, one frame at a time. | PENDING (content JSON) |
| `DAILY_PHOTO_05_FLAVOR` | `photo_05` photo_subject×5 | Five subjects. A gallery of the almost-lost. | PENDING (content JSON) |
| `DAILY_DARK_05_FLAVOR` | `dark_05` no_flashlight_segment×5 | Five segments, flashlight OFF. Trust the lamps. | PENDING (content JSON) |
| `DAILY_DARK_10_FLAVOR` | `dark_10` no_flashlight_segment×10 | Ten segments in lamp-light only. Walk like the Keeper. | PENDING (content JSON) |

### 7b. NGP_* ×12 (modifier name/desc; NG+ loadout screen)

| Key | Modifier | en source | Status |
|---|---|---|---|
| `NGP_LONG_NIGHT_NAME` | `long_night` name | Long Night | PENDING |
| `NGP_LONG_NIGHT_DESC` | `long_night` desc | Battery yields 20% less light. The dark is patient; your cells are not. | PENDING |
| `NGP_WHISPER_NAME` | `whisper` name | Whisper | PENDING |
| `NGP_WHISPER_DESC` | `whisper` desc | Hunters hear 30% less, but loot yields 10% less. Tread soft, carry little. | PENDING |
| `NGP_BLACKOUT_PLUS_NAME` | `blackout_plus` name | Blackout+ | PENDING |
| `NGP_BLACKOUT_PLUS_DESC` | `blackout_plus` desc | One extra district starts DARK. No head start, no mercy. | PENDING |
| `NGP_KEEPERS_PACT_NAME` | `keepers_pact` name | Keeper's Pact | PENDING |
| `NGP_KEEPERS_PACT_DESC` | `keepers_pact` desc | No hints. Lore insight doubled. He never explained either. | PENDING |
| `NGP_SPRINT_NAME` | `sprint` name | Sprint | PENDING |
| `NGP_SPRINT_DESC` | `sprint` desc | Night cycle 15% shorter, rewards +50%. Run the light home. | PENDING |
| `NGP_GHOST_NAME` | `ghost` name | Ghost | PENDING |
| `NGP_GHOST_DESC` | `ghost` desc | Crawlers ignore you. Achievements disabled. Unseen, unrecorded. | PENDING |

### 7c. CAPTION_* ×28 (moment toasts + gallery plates)

| Key | Caption | en source | Status |
|---|---|---|---|
| `CAPTION_MOMENT_FIRST_LIGHT` | `moment_first_light` | Night 1. One lamp. Mine. The street remembered what morning was. | PENDING |
| `CAPTION_MOMENT_PHOTOGRAPHER` | `moment_photographer` | Night 40. Ten frames kept. If the grid forgets us, the film won't. | PENDING |
| `CAPTION_MOMENT_OVERLOAD` | `moment_overload` | Night 63. Pack's too heavy; back's too old. Still carried it home. | PENDING |
| `CAPTION_MOMENT_ENDING_LIGHT` | `moment_ending_light` | Last night. The grid held. Forty years of work orders — paid in full. | PENDING |
| `CAPTION_MOMENT_ENDING_DARKNESS` | `moment_ending_darkness` | Last night. I blew the lamps out myself. Forgive me. It was the only way to starve it. | PENDING |
| `CAPTION_MOMENT_NG_PLUS` | `moment_ng_plus` | Night 1, again. The city reset; I didn't. The log continues. It always continues. | PENDING |
| `CAPTION_MOMENT_DOC_MANIFESTO` | `moment_doc_streetlight_manifesto` | Found my own manifesto by the last lamp. Younger handwriting. Same promise. | PENDING |
| `CAPTION_MOMENT_DOC_FINAL_LIGHT` | `moment_doc_final_light` | "While one lamp burns, the city lives." I wrote that. I still believe it. | PENDING |
| `CAPTION_MOMENT_DOC_PROTOCOL_DAWN` | `moment_doc_protocol_dawn` | EON's Protocol Dawn: lock the grid, save the staff. They locked it. Nobody saved anybody. | PENDING |
| `CAPTION_MOMENT_DOC_BLACKOUT_NEWS` | `moment_doc_blackout_news` | The last paper says one day. It has been years. Somebody tore the date out — hope or mercy. | PENDING |
| `CAPTION_MOMENT_DOC_FIRST_DEATH` | `moment_doc_first_death` | A dead man's note: "Light is the only prayer." He was right. He is still right. | PENDING |
| `CAPTION_MOMENT_DOC_VOICE_IN_WIRES` | `moment_doc_voice_in_wires` | Something talks on the wires at night. I log the words. I do not answer. | PENDING |
| `CAPTION_GALLERY_SUBURBS` | `gallery_suburbs` | Where the lights went out first, and where they'll come back first. | PENDING |
| `CAPTION_GALLERY_RESIDENTIAL` | `gallery_residential` | A thousand windows. I count the lit ones every night. The count grows. | PENDING |
| `CAPTION_GALLERY_PARK` | `gallery_park` | The lamps here drink the fog. Pretty. Hungry. Both. | PENDING |
| `CAPTION_GALLERY_SCHOOL` | `gallery_school` | Somebody chalked a sun on the blackboard. It outlasted the grid. | PENDING |
| `CAPTION_GALLERY_HOSPITAL` | `gallery_hospital` | The generators held longest here. So did the nurses. | PENDING |
| `CAPTION_GALLERY_GAS_STATION` | `gallery_gas_station` | Fuel, fumes, and one fluorescent that refuses to die. | PENDING |
| `CAPTION_GALLERY_POLICE` | `gallery_police` | The holding cells are empty. The radio isn't. Don't ask. | PENDING |
| `CAPTION_GALLERY_WAREHOUSES` | `gallery_warehouses` | Crates of lamps nobody installed. I installed them. You're welcome. | PENDING |
| `CAPTION_GALLERY_INDUSTRIAL` | `gallery_industrial` | The presses stopped mid-stroke. The dark likes the echo in here. | PENDING |
| `CAPTION_GALLERY_SUBSTATION` | `gallery_substation` | Marat walked in here and never walked out. Mind the hum. | PENDING |
| `CAPTION_GALLERY_POWER_STATION` | `gallery_power_station` | The center. My forty years end here — one way or another. | PENDING |
| `CAPTION_GALLERY_NIGHT_ZERO` | `gallery_night_zero` | Night Zero. 03:14. The city exhaled, and the dark inhaled. | PENDING |
| `CAPTION_GALLERY_THE_KEEPER` | `gallery_the_keeper` | Forty years of work orders. This face kept every lamp logged by hand. | PENDING |
| `CAPTION_GALLERY_THE_ARCHITECT` | `gallery_the_architect` | It built its nest in the dead grid. Tonight we evict it. | PENDING |
| `CAPTION_GALLERY_BABKA_LAMP` | `gallery_babka_lamp` | Babka Manya's lamp. "The light in this city is not electricity." | PENDING |
| `CAPTION_GALLERY_LAST_STREETLIGHT` | `gallery_last_streetlight` | The last streetlight. While it burns, the city lives. | PENDING |

## 8. Scope hygiene — PASS

Touched only (this branch): `content/daily_challenges.json`,
`content/ngp_modifiers.json`, `content/captions.json`,
`docs/CERT_RETENTION.md`, `docs/artifacts/retention/**`.
No `.gd`/`.tscn`/locale/`data/` changes. No new systems.

---
Skills: yagni, surgical-edit, council, self-commit
