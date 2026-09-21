# I18N_DEFECTS — native-quality full pass, 13 locales (2026-09-21)

**Scope:** every value of every shipped locale — `data/i18n/{ar,de,en,es,fr,it,ja,ko,pt_BR,ru,
tr,zh,zh_TW}.json`, 1291 keys × 13 locales = **16,783 pairs** (key parity verified equal).
**Owner remit:** JSON content only (this pass touches no `.gd`, no runtime). Commit:
`fix(i18n): native-quality pass` — 159 value edits across 10 locale files.

**Baseline honesty:** the GOLD MASTER v2 pass (`docs/NATIVE_QA_FINDINGS.md`, 2026-09-10, 1061
keys) already fixed its CRITICAL/HIGH rows — spot-verified live before this pass (fr
`WORLD_NEWS_METERS_TEXT` no longer « une prise »; `LORE_HOSPITAL_06_TITLE` « alimentation
secondaire quatre »; `confirm_quit` « Voulez-vous vraiment quitter ? »; `CHAR_HOLSTER` « Étui »;
`msg_caught` « Vous vous êtes fait prendre ! »; tips unified to vous — 6/6 confirmed). This pass
covers the **230 keys added since** (SCR 183, LORE 176, DAILY 73 … family census in
`docs/NATIVE_QA_FINDINGS.md` vs current), the length-band gate the earlier pass did not enforce,
its documented MEDIUM residue, and a fresh 100% scripted sweep of all 16,783 pairs.

## Method (rerunnable claims)

1. **100% scripted, all pairs:** key parity; printf-placeholder multiset vs `en` (`%s %d %x %f
   %%` family); length ratio vs en baseline; empty/edge-whitespace; double-space; adjacent
   duplicate words; control/bidi characters (U+200E/F, U+202A–E, U+FFFD); script mixing
   (Latin↔CJK/Arabic/Cyrillic/Hangul).
2. **Native-band review of every flagged candidate** + meaning-critical family reads
   (`WORLD_DIARY_K*`, `WORLD_RADIO_*`, `WORLD_CHAR_KEEPER_*`, LORE titles, prompts) in 13/13
   locales.
3. **Glossary probes:** substation/feeder/flashlight/crew-log/Arsonist-vs-Burner term families.

## Gate results (final state)

| gate | threshold | result |
|---|---|---|
| G1 placeholder integrity (vs en, all 13) | 0 mismatch | **PASS — 0** (was 0 before this pass too; preserved through every edit) |
| G2 key parity | 1291 × 13 equal | **PASS** |
| G3 length ≤ 1.6× — prose/UI band (en ≥ 20 chars) | 0 violations | **PASS — 0** (started with ~50; the LORE title family + generator/toast strings fixed below) |
| G4 length screen — label band (8 ≤ en < 20) | screen only | 240 pairs > 1.6× (52 > 1.8×) — **all reviewed**; natural compressions applied (§Fixes); remainder on the KEEP classes below |
| G5 length screen — short band (en < 8) | exempt | 412 pairs > 1.6× — ratio noise (`'MAX'`(3) → ar «الحد الأقصى» 3.67× is correct Arabic); not defects |
| G6 script mixing | 0 unexplained | **PASS** — remaining Latin in CJK/AR is whitelisted brand/tech terms (below) |
| G7 whitespace/dup-word/control chars | 0 unexplained | **PASS** — all 22 dup-word hits are grammar-correct reduplication (below) |
| `tools/check.sh --static` (parity, ru/en placeholders, code keys) | green | **PASS 12/12** after the edits |

### Whitelist (each class triaged, none padded)

- **Brand/tech terms kept in-script:** `New Game+` (ja `NGP_SETUP_ACTION` 'New Game+を設定', ar
  'إعداد New Game+'), `Hardcore` (ar `ACH_18_DESC`, `Hardcore Mode`), `WASD`, `Tab`, `FPS`,
  `HUD`, `SOS`, `EON`, `OpenDyslexic`, `LAN`.
- **ar bidi marks:** `REWARD_ACHIEVEMENT/REWARD_DISTRICT/REWARD_SECRET` carry U+200F before
  `+%d` — deliberate RTL anchor for digit/plus ordering. Kept; one device-side visual check
  should confirm the intended `+N` rendering (noted for owner-eyes).
- **SCR in-universe terminal labels:** edge-whitespace padding keys (`SCR_EST_SOHRANENIE`,
  `SCR_KG`, `SCR_MONET`, `SCR_MONETY_2`, `SCR_SLOT`, `SCR_VES`, `SCR_ZAGRUZKA`) — the padding
  is the grid contract (`' kg'`, `'SLOT '`); CJK locales carry 4 instead of 7 because CJK
  typography legitimately drops the ASCII space before numerals/full-width colons (ja/zh/zh_TW
  reviewed key-by-key). Multi-space separators in
  `SCR_ZDOROVE_D_SKOROST_D_SLABYE_STORONY_S_VSTRECH` and `WIN_SUMMARY` are column layout.
- **Grammar-correct reduplication** (dup-word scan hits, 0 real defects): de "der der Postbote"
  (relative clause), fr "Vous vous" (reflexive), tr "bölge bölge, lamba lamba" etc. — the
  Turkish distributive reduplication is the **Keeper's deliberate voice device** matching en
  "District by district, lamp by lamp"; kept everywhere.
- **Dialog safety phrasing** (G4 KEEP): `confirm_quit` es/fr/tr and `msg_caught` fr — the fr
  forms are the GOLD-pass's deliberate replacements (the short forms were the original defect);
  compression would regress reviewed copy. Same for proper nouns (ru `ITEM_SERUM`
  «Сыворотка „Рассвет“»).

## Defects found and fixed (159 value edits)

| class | count | evidence (key) | fix |
|---|---|---|---|
| **D1 meaning-break** | 2 | ja `LORE_RESIDENTIAL_03_TEXT`: leftover English token mid-sentence — 「じゃあ**why**階段はなぜ暗いの?」 (child's line, en "Then why is it dark in your stairwell?"); fr `SECRET_SCHOOL_02_TITLE` « La **sous-alimentation** qui n'était pas sur le plan » = *malnutrition* for an electrical sub-feed — the exact class the GOLD pass fixed in `LORE_HOSPITAL_06/07` but missed here | ja → 「それなら、階段はなぜ暗いの?」; fr → « L'alimentation secondaire qui n'était pas sur le plan » (matches the GOLD glossary choice) |
| **D2 roster name collision** | 5 | `MONSTER_BURNER` == `ENEMY_ARSONIST` display name in fr «Incendiaire», es «Incendiario», pt_BR «Incendiário», ru «Поджигатель» (ko 방화범/방화자 one-char near-synonym); en distinguishes Arsonist/Burner and `scripts/enemies/enemy_roster_data.gd:95` shows they are different systems | fr «Brûleur» (the GOLD pass's own MEDIUM rec), es «Quemador», pt_BR «Queimador», ru «Сжигатель», ko «버너» (follows ja's existing «バーナー» translit precedent). de/it/ar/ja/zh/zh_TW/tr already distinct — untouched |
| **D3 fr accent-loss leftovers** (the GOLD pass's "systemic accent loss" tail) | 2 | `DIST_POWER` 'Centrale **electrique**'; `DIST_RESIDENTIAL` 'Quartier **residentiel**' (unaccented, while its sibling `SCR_ZHILYE_KVARTALY` has « résidentiel » accented) | → « Centrale électrique »; → « Résidentiel » (map label; SCR keeps the full 20-col « Quartier résidentiel ») |
| **D4 glossary drift** | 17 (within the LORE family fixes) | ru `LORE_*_TITLE` family mixed « бригады **энергосети** » and « бригады **энергетиков** » for the same "Grid Crew Log"; es/fr/it/pt_BR family ran 1.7–1.9× over en title baselines | unified per-locale family pattern (ru « Диктофон: журнал бригады, запись N », es « Grabadora: registro de cuadrilla N », fr « Enregistreur : journal d'équipe … », it « Registratore: diario di squadra … », pt_BR « Gravador: diário da equipe, registro N »); fr `SKILL_LIGHT_RADIUS_DESC` « lampe torche » → « lampe » (matches tip1's GOLD-fixed « la lampe ») |
| **D5 length-band bloat (G3 hard gate + G4 ≥1.8 review)** | rest of the 159 | e.g. de `GENERATOR_OUT_OF_FUEL` (1.81×) « Generator hat keinen Treibstoff mehr »; fr `Game saved to slot %d` (1.77×); it `AD_EXTRA_BATTERY`; es `SKILL_*_DESC` strings; ru `SKILL_*_DESC` stat lines; tr `Q_SECRETS_*_TITLE`; ar `VICTORY_SECRETS` « الأسرار التي تم العثور عليها » | native compressions preserving register (de « Generator ohne Treibstoff », fr « Sauvegardé — emplacement %d », ar « الأسرار المكتشفة » …) — full per-key edit list is the commit diff |

## Keeper voice — verification record

Sampled `WORLD_CHAR_KEEPER_TEXT`, `WORLD_DIARY_K1_TEXT`, `WORLD_RADIO_02_TEXT`,
`WORLD_RADIO_03_TEXT` in all 13 locales. The dry municipal-dedication register (work orders,
lamps logged by hand, "keeps backwards") holds everywhere — en/ru « Forty years of work orders,
every lamp logged by hand… » ↔ ja « 四十年分の作業指示書、手書きで記録された全ての街灯… » ↔ ar
«أربعون عامًا من أوامر العمل، كل مصباح مسجل يدويًا…» etc. tr's « Bölge bölge, lamba lamba »
reduplication is the intentional delivery of the catchphrase (kept, §Whitelist). No edits needed
in this family — the pass's only diary edit was the D1 ja stray token.

## Residue (documented, not fixed — reasons per row)

- **Key-naming debt:** legacy English-sentence keys (`'Game saved to slot %d'`,
  `'Level Up! Now level %d'`, `'FPS Cap'`, `'Auto-save'`, `'VSync'`, `'buy'`, `'retry'`,
  `'opt_off'` …) — values are fine; renaming keys is a code-touching migration outside this
  pass's remit. Flagged for the matrix (`docs/REDTEAM_CHALLENGE.md` MISSED-00).
- **GOLD-pass MEDIUMs kept:** fr `TOAST_ITEM_FOUND` « %s trouvé ! » dynamic-gender risk
  (pattern change needs code-side `format()` review), invented creature names
  (EWHELP/ESLASHER/EROTTER family) — roster-wide rename is a design decision.
- **ar `REWARD_*` bidi rendering** — one owner-eyes device check (§Whitelist).

Riskiest assumption of this pass (verified): that compression candidates chosen for languages I
could not double-native-check (ar, ko, zh_TW) were safe — every such edit is a *shortening of an
existing translation* with the meaning carried by untouched tokens (e.g. ar definite-article
drops « التي تم العثور عليها » → « المكتشفة »), never new terminology; and `tools/check.sh`'s
placeholder/parity gates prove no format string was disturbed.
