# NATIVE_QA_FINDINGS — final native-speaker localization pass (GOLD MASTER v2)

- **Date:** 2026-09-10 · **Agent:** NATIVE QA (static text review only — Godot never run, per protocol)
- **Scope:** every user-visible key of the 11 non-EN/RU shipped locales (menu strings, HUD, toasts, journal/lore prose, settings, endings, accessibility toggles, bestiary/codex, quests, achievements, SCR screen labels, store/trailer-facing strings).
- **Inputs:** `data/i18n/*.json` (1061 keys each), `store/listing.md`, `store/trailer.md`, `store/press-kit.md`, `content/**` (canon cross-check only).
- **Outputs:** CRITICAL + HIGH fixes applied as handoff rows in `docs/PROSE_CHANGES.md` (§ Locale native-QA fixes). MEDIUM/LOW are documented below only.

## Locale inventory discrepancy (blocker note for the owner)

The task brief lists the 11 non-EN/RU locales as `fr, de, es_ES, ja, ko, zh_CN, zh_TW, pt_BR, tr, pl, uk`.
The repo actually ships **13 locales**: `en, ru` + **`ar, de, es, fr, it, ja, ko, pt_BR, tr, zh, zh_TW`**.

- `pl` (Polish) and `uk` (Ukrainian) **do not exist** in `data/i18n/` (already tracked in `findings.md` T6: "PL нет — вместо него ar").
- `ar` (Arabic) and `it` (Italian) **are shipped** and were therefore reviewed too (they are live player-facing text).

This pass reviews the **actual 11** non-EN/RU locales: `fr, de, es, it, pt_BR, tr, ja, ko, zh, zh_TW, ar`. If `pl`/`uk` are still planned, they must be created from scratch — nothing to review there.

## Coverage & method (honest audit trail)

- **100% scripted checks, all 1061 keys × 11 locales:** key parity (0 missing / 0 extra everywhere), `%s`/`%d` placeholder parity (0 mismatches), whitespace parity, double-space scan, adjacent-duplicate-word scan, register-mixing scan (tu/vous, du/Sie, tú/usted, sen/siz), French typography (space before `! ? :`), Spanish inverted `¿¡`, length-ratio outliers, Latin-script leftovers in CJK/AR text, `zh` vs `zh_TW` genuine-rewording diff.
- **100% native read of all non-LORE keys** (885 keys: menus, HUD, toasts, settings, a11y, tutorials, tips, onboarding, quests, achievements, skills, items, shop, ads, endings, radio, world codex, bestiary, SCR screen labels) for every locale.
- **LORE prose (176 keys/locale):** all 88 note TITLES read per locale + rotating deep sample of 16 TEXTs per locale (every district covered, samples rotated per locale so no district's prose went unread) + scripted scans over all 88 TEXTs per locale (terminology, register, loanwords, quote style).
- Register/intimacy choices inside diegetic voice (radio broadcasts, hand-written notes) are judged as in-character prose, not as UI register.

## Priority rubric

- **CRITICAL** — breaks meaning or causes offense · **HIGH** — robotic/unnatural to a native, or systemic quality defect · **MEDIUM** — acceptable but non-idiomatic · **LOW** — stylistic nit.

---

## French (fr)

**Verdict:** strong literary transcreation of the lore prose, undermined by a systemic accent-loss defect (~30 keys), tu/vous register mixing in system voice, and one real meaning-breaker ("une prise" = wall socket for "a tap"). Terminology drift between "sous-station" and "poste électrique". Counts: **CRITICAL 4 (4 fixed)** · **HIGH 49 (49 fixed)** · MEDIUM 12 · LOW 9.

| key | current | issue | suggested_fix | priority |
|---|---|---|---|---|
| WORLD_NEWS_METERS_TEXT | « …City Power blâme des « tambours défectueux ». … c'est une prise. » | **Meaning break:** "une prise" = a wall socket; EN "a tap" = illegal line tap. Also entity "City Power" left in EN while the same faction is "Compagnie d'électricité municipale" elsewhere | « …La compagnie invoque des « tambours défectueux ». … c'est un branchement clandestin… au lieu de le prélever. » | CRITICAL |
| LORE_HOSPITAL_06_TITLE | « Boîte d'archives 14 — sous-alimentation quatre » | **Meaning break:** "sous-alimentation" = malnutrition (of people); EN "sub-feed four" is an electrical feeder | « Boîte d'archives 14 — alimentation secondaire quatre » | CRITICAL |
| LORE_HOSPITAL_06_TEXT | « Sous-alimentation quatre : circuit de nuit dédié… » | same electrical-term meaning break | « Alimentation secondaire quatre : … » | CRITICAL |
| LORE_HOSPITAL_07_TEXT | « Sous-alimentation quatre, première lumière. » | same | « Alimentation secondaire quatre, première lumière. » | CRITICAL |
| ~30 keys: AD_CLAIM, AD_READY, AD_TITLE, AD_WATCHING, BLUEPRINT_APPLIED, DISTRICT_ALREADY_FULL, DISTRICT_STAGE_1/2/3, INSPECT_NOTHING, JOURNAL_FOUND, WIN_SUMMARY, controls, difficulty, fullscreen, quests, retry, sens, tutorial_done, tutorial_move, CHECKPOINT_SET, HUD_STEALTH, HUD_VISIBILITY, DOC_FOUND, you_died, FINAL_NIGHT_BEGINS, FINAL_NIGHT_GOTO_STATION, VICTORY_STATS (+3 lore/world keys) | e.g. « Difficulte », « FURTIVITE », « DOCUMENT TROUVE », « Districts restaures » | **Systemic accent loss** — reads as a typo/bug to every francophone; some strings accented, others not (font already renders é/È elsewhere, e.g. HUD_HP « SANTÉ ») | restore accents on every affected key (full per-key list in PROSE_CHANGES) | HIGH |
| tip1, tip3, tip4, menu_subtitle, tutorial tips | « Garde la lampe… », « Mets-toi a couvert… », « Rends sa lumière à la ville. » | **Register mixing:** system voice flips tu/vous; game UI is otherwise consistently vous (ACH/ONBOARD/PROMPT all use vous). (Diegetic radio "tu" in WORLD_RADIO_01/03 is intentional and kept) | unify system voice to vous | HIGH |
| msg_caught | « Vous avez été attrapé ! » | "attrapé" = childish (caught like a ball); robotic for a horror death screen | « Vous vous êtes fait prendre ! » | HIGH |
| confirm_quit | « Quitter vraiment? » | unidiomatic + missing French space before "?" | « Voulez-vous vraiment quitter ? » | HIGH |
| CHAR_HOLSTER | « Rengainer » | verb ("to holster") used as a body-slot label | « Étui » | HIGH |
| enc_locked | « …débloquer l'entrée. » | "l'entrée" = entrance; here it's an encyclopedia entry | « …débloquer sa fiche. » | HIGH |
| DIST_SUBSTATION, Q_REPAIR_DISTRICT1_TITLE, RADIO_TRANSCRIPT_E2, SCR_AKTIVNYE_PODSTANCII_3_8, SCR_AVARIYA_NA_PODSTANCII, SCR_PODSTANCIYA, SCR_PODSTANCIY | « Sous-station », « Redémarrez la sous-station résidentielle » | **Terminology inconsistency:** same object is « poste électrique » in DISTRICT_NAME_SUBSTATION/WORLD keys but « sous-station » elsewhere; "Redémarrez une sous-station" is also an odd collocation | unify to « poste électrique » / « Rétablissez le poste électrique résidentiel » | HIGH |
| WORLD_DIARY_K1_TEXT | « J'entends qu'on se souvienne de moi comme de l'homme qui n'a jamais laissé une rue être oubliée. » | contorted calque of "I intend to be remembered as the man who never let the street be forgot" | « Je veux qu'on se souvienne de moi comme de l'homme qui n'a jamais laissé une rue sombrer dans l'oubli. » | HIGH |
| WORLD_DIARY_K3_TEXT | « Ordre 14 208 : démonter le 219, banlieue » | reads as "dismantle the (id) 219" — 219 is a count (all 219 lamps) | « …démonter les 219, banlieue… » | HIGH |
| WORLD_RADIO_02_TEXT | « Troisième équipe à qui écoute : » | calque of "Third shift to anyone:"; not a French radio register | « Troisième équipe à tous ceux qui écoutent : » | HIGH |
| WORLD_RADIO_03_TEXT | « Apporte un dos solide. » | calque of "Bring a strong back" (FR "avoir un bon dos" means something else entirely) | « Il te faudra de bons bras. » | HIGH |
| LORE_HOSPITAL_08_TEXT | « ce ne sont pas quelque chose venu à leur place. C'est eux. » | agreement error in the note's emotional punchline | « ce n'est pas quelque chose venu les remplacer. Ce sont eux. » | HIGH |
| UPG_HINT | « Les pièces viennent des quartiers, secrets et succès. » | clipped, robotic | « Les pièces se gagnent dans les districts, les secrets et les succès. » | HIGH |
| ENEMY_ARSONIST / MONSTER_BURNER | both « Incendiaire » | name collision across roster/bestiary systems (different enemies) | keep « Incendiaire »; consider « Brûleur » for MONSTER_BURNER if both ever shown together | MEDIUM |
| TOAST_ITEM_FOUND | « %s trouvé ! » | gendered participle with dynamic %s (feminine items read wrong) | neutral pattern « Objet trouvé : %s » if code allows | MEDIUM |
| EWHELP / ESLASHER / EROTTER | « Petit », « Tailladeur », « Putréfié » | invented/weak creature names | « Bêteau » / « Entailleur » / « le Pourri » | MEDIUM |
| Q_KILL_TANK_TITLE / _DESC | « Abattez les tanks » | anglicism "tanks" (EN means armored brutes) | « Abattez les blindés » | MEDIUM |
| ACH_17_DESC / SHOP_SKIN_GRANTED | « skins de lampe torche », « Skin débloqué » | anglicism acceptable in gamer jargon, but « apparences » is the platform term | — | LOW |
| MAP_PROGRESS | « %d district(s) sur %d » | "(s)" parenthesis is clunky | « Districts alimentés : %d sur %d » | MEDIUM |
| LEVEL_UP_NOTICE | « Niveau supérieur ! Niveau %d désormais » | repetitive | « Niveau supérieur ! Vous êtes désormais niveau %d » | LOW |
| SKILL_COST_SP | « Coût : %d PC » | "PC" reads as "computer"; not a standard abbreviation for points de compétence | « Coût : %d pts » | MEDIUM |
| SKILL_BATTERY_CAPACITY_DESC | « +25 batterie max » | missing preposition | « +25 de batterie max » | LOW |
| WORLD_NEWS_TREES_TEXT | « …les arbres 'se penchent…' » | straight quotes vs « » used elsewhere | « … » | LOW |
| dg_double | « Double tap » | anglicism; FR platform convention « Double appui » | — | LOW |
| LGAS_STATION_02_TEXT | « La moitié est restée dans sa voiture » | singular "sa voiture" for "half of them … their cars" | « La moitié d'entre eux est restée dans leur voiture » | MEDIUM |
| LGAS_STATION_04_TEXT | « …nette jusqu'à 2h00, puis plus. » | flat | « …puis plus rien de net. » | LOW |
| LHOSPITAL_03_TEXT | « une lumière qui marche n'est que du temps qu'il fait » | clever but unidiomatic | « une lumière qui se déplace passe pour de la météo » | MEDIUM |
| VICTORY_TITLE | « La ville brille » | loses "burns bright" | « La ville brille de mille feux » | LOW |
