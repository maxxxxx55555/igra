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

---

## German (de)

**Verdict:** the best locale of the set — consistent du-register, idiomatic lore prose ("Etwas anderes brennt", "Die Dunkelheit hat dich geholt"), correct electrical vocabulary (Umspannwerk, Abgriff). Defects concentrate in the legacy lowercase keys (umlauts transliterated as ae/oe/ue while newer keys use real umlauts), English Title Case in world-news headlines, and several terminology splits. No CRITICAL meaning breaks found. Counts: **CRITICAL 0** · **HIGH 36 (36 fixed)** · MEDIUM 9 · LOW 7.

| key | current | issue | suggested_fix | priority |
|---|---|---|---|---|
| ~11 keys: back_menu, music_vol, sfx_vol, next_level, select_slot, tip1, tip4, tutorial_done, tutorial_shoot, AD_SKIP, AD_TITLE | e.g. « Hauptmenue », « Naechstes Level », « Druecke M fuer die Karte », « Uberspringen », « Werbung fur Belohnung » | **Systemic umlaut transliteration** (ae/oe/ue + « fur ») in the legacy key set only; the rest of the file uses real umlauts (Straßenlaterne, Größe…) — reads as a bug to any German player | restore real umlauts (per-key rows in PROSE_CHANGES) | HIGH |
| DEATH_TITLE, SCR_VY_POGIBLI | « DU BIST GESTORBEN » | grammatical but robotic game-over German; the sibling key `you_died` correctly says « DU BIST TOT » | « DU BIST TOT » | HIGH |
| quests, CODEX_TAB_QUESTS | « Aufgaben », « Aufträge » | quest terminology split three ways (Aufgaben/Aufträge/Quests — « Keine aktiven Quests » already uses Quests) | unify on « Quests » | HIGH |
| JOURNAL_RELATED | « Verwandt: %s » | **wrong meaning** — « verwandt » = related by family; journal cross-references need « Siehe auch » | « Siehe auch: %s » | HIGH |
| CHAR_HOLSTER | « Wegstecken » | verb used as equipment-slot label | « Holster » | HIGH |
| ENEMY_ROTTER | « Fäulnis » | abstract noun (decay) as a creature name; MONSTER_ROTTER is « Verrotteter » | « Verrotteter » | HIGH |
| PROMPT_REPAIR, Q_FIND_FUSES_DESC, Q_REPAIR_DISTRICT1_DESC | « Tafel reparieren », « Verteilertafel » | « Tafel » = chalkboard; an electrical distribution board is a « Verteilerkasten » | unify to « Verteilerkasten » | HIGH |
| WORLD_NEWS_METERS_TEXT | « City Power gibt 'defekten Trommeln' die Schuld » | faction name left in English; lore (LORE_INDUSTRIAL_01) calls it « Stadtwerke » | « Die Stadtwerke geben … » | HIGH |
| WORLD_NEWS_ARCHITECT_TITLE, WORLD_NEWS_METERS_TITLE, WORLD_NEWS_OUTAGES_TITLE, WORLD_NEWS_TREES_TITLE, WORLD_NEWS_ARENA_TITLE | e.g. « Zähler Laufen auf Drei Straßen Rückwärts » | English Title Case in German newspaper headlines (+ straight quotes, + inconsistent « Zentralen »/« zentralen ») — looks machine-localized | German sentence case + „ “ quotes (per-key rows) | HIGH |
| WORLD_DIARY_K2_TITLE | « Die Nacht, in der es Erlosch » | wrong mid-sentence capitalization; « es » has no referent | « Die Nacht, in der das Licht erlosch » | HIGH |
| WORLD_CHAR_RADIOVOICE_TEXT | « …wird euch im Licht begegnen » | radio voice addresses the singular player as « euch »; WRADIO_01 correctly uses « dir » | « …wird dir im Licht begegnen » | HIGH |
| DIST_POLICE, SCR_POLICEYSKIY_UCHASTOK | « Polizeirevier », « Polizeistation » | three names for the same district (Polizeiwache/Polizeirevier/Polizeistation) | unify on « Polizeiwache » | HIGH |
| DIST_SUBURBS, SCR_PRIGOROD | « Vorort », « Vorstadt » | district-name drift vs DISTRICT_NAME_SUBURBS « Vororte » | « Vororte » | HIGH |
| DIST_WAREHOUSES, SCR_SKLADSKOY_KOMPLEKS | « Lagerhäuser » | vs DISTRICT_NAME_WAREHOUSES « Lagerkomplex » | « Lagerkomplex » | HIGH |
| LORE_INDUSTRIAL_05_TEXT | « DIE ZWEITE SPULE WICKELN, UM STROM DIE LEITUNG ZURÜCKZUZAHLEN. » | calque of "pay current back down the line"; « zurückzahlen » is a money verb — the technical term is einspeisen | « DIE ZWEITE SPULE SO WICKELN, DASS STROM IN DIE LEITUNG ZURÜCKGESPEIST WIRD. » | HIGH |
| MONSTER_BRUTE | « Brutalo » | colloquial-jokey register clash in a horror bestiary | « Schläger » | MEDIUM |
| Q_KILL_TANK_TITLE/_DESC | « Bring die Panzer zu Fall », « Gepanzerte Brutalos » | « Panzer » reads as the vehicle | « Schalte die Gepanzerten aus » | MEDIUM |
| WEAKSPOT_STROBE_COMBO | « Blitzlicht + Angriffskombo » | strobe rendered « Blitzlicht » here but « Stroboskop » in STROBE_READY | « Stroboskop + Angriffskombo » | MEDIUM |
| UPG_STABILITY_DESC | « bei niedrigem Akkustand » | flashlight runs on « Batterie » everywhere else | « Batteriestand » | MEDIUM |
| SKILL_COST_SP | « Kosten: %d SP » | unexplained EN abbreviation; skill points are « Fertigkeitspunkte » | « Kosten: %d FP » | MEDIUM |
| Level Up! Now level %d | « Level aufgestiegen! Jetzt Stufe %d. » | unidiomatic | « Level-Up! Jetzt Stufe %d. » | MEDIUM |
| ITEM_AUDIO_LOG | « Audioprotokoll » | stiff compound | « Audioaufzeichnung » | MEDIUM |
| Q_FIND_ENGINEERS_DESC | « Ingenieurscrew » | Denglish compound | « Ingenieursmannschaft » | LOW |
| ENEMY_HOUND | « Hund » | plain vs MONSTER_HOUND « Hetzhund » | « Hetzhund » | LOW |
| ACH_17_DESC, SHOP_SKIN_GRANTED | « Taschenlampen-Skins », « Skin freigeschaltet » | anglicism accepted in gamer DE | — | LOW |
| SKILL_XP_BOOST_NAME | « Schnelllerner » | triple-L is correct but reads as a typo | — | LOW |
| SCR keys PS_1–PS_8 | « UW-1 »… | fine (Umspannwerk prefix) — no action | — | LOW |

---

## Spanish (es / es_ES)

**Verdict:** confident, idiomatic transcreation overall (good register instincts, «toma/alimentador» electrical vocabulary, strong diary prose). Defects: missing accents + missing ¿¡ in the legacy key set, the recurring "recorder" character translated as «narrador» (narrator) in 7 lore notes, English Title Case in news headlines, and tú/ustedes flips inside the same note sets. Counts: **CRITICAL 0** · **HIGH 48 (48 fixed)** · MEDIUM 11 · LOW 8.

| key | current | issue | suggested_fix | priority |
|---|---|---|---|---|
| ~19 keys: diff_easy, diff_hard, empty_slot, graphics, menu_title, music_vol, tip1, yes, HUD_AMMO, DISTRICT_ALREADY_FULL, DISTRICT_STAGE_1/2, DIST_POLICE, DIST_POWER, DIST_SUBSTATION, INSPECT_NOTHING, FINAL_NIGHT_GOTO_STATION, SCR accents, confirm_quit, tutorial_done | « Facil », « LA ULTIMA FAROLA », « Volumen musica », « MUNICION », « Salir seguro? », « Suerte! » | **systemic accent loss + missing ¿¡** in the legacy set (newer keys are fine) | restore á/é/í/ó/ú + «¿…?» pairs (per-key rows) | HIGH |
| LORE_WAREHOUSES_08/INDUSTRIAL_08/SUBSTATION_07/SUBSTATION_08/POWER_STATION_01/07/08_TEXT | « la letra del narrador » ×7 | **wrong character word:** the crew's Recorder is « el Grabador » (WORLD_CHAR_RECORDER_TITLE); « narrador » = narrator — breaks codex cross-reference | « la letra del grabador » | HIGH |
| WORLD_NEWS_METERS_TEXT | « City Power culpa a… », « Algo aguas abajo está inyectando corriente…, no tomándola. » | faction left in EN; « aguas abajo » word order breaks; « no tomándola » clipped | « La compañía culpa a… », « Algo, más abajo en la línea, está inyectando corriente en los cables en lugar de consumirla. » | HIGH |
| WORLD_NEWS_ARCHITECT/ARENA/METERS/OUTAGES/TREES_TITLE | « El Consejo Niega el Programa 'Memoria de la Red' » | English Title Case + straight quotes in Spanish headlines | sentence case + « » (per-key rows) | HIGH |
| WORLD_CHAR_RADIOVOICE_TEXT | « Vayan a la central eléctrica… los recibirá » | radio voice addresses plural « ustedes » here but « tú » in WORLD_RADIO_01 (same quote) | « Ve a la central eléctrica… te recibirá » | HIGH |
| WORLD_RADIO_03_TEXT, LORE_POWER_STATION_03_TEXT | « Trae una espalda fuerte. » | calque of "Bring a strong back" | « Vas a necesitar una espalda fuerte. » | HIGH |
| WORLD_DIARY_K3_TEXT | « desmontar la 219, suburbios » | reads as "dismantle the (single) 219" — it is all 219 suburb lamps | « desmontar las 219 » | HIGH |
| Q_KILL_RUNNER_DESC | « Los corredores son lo más osado de esta noche. » | agreement error (singular neuter with plural subject) | « …los más atrevidos de esta noche. » | HIGH |
| LORE_POLICE_01_TEXT | « El calco propio de la comisaría de la lista dos » | false friend: « calco » = calque/trace, not carbon copy | « La copia en papel carbón de la comisaría… » | HIGH |
| LORE_POLICE_02_TEXT | « No pongan una lámpara… la luz solo les muestra » | ustedes flip mid-note-set (POLICE_03/08 use tú) | « No pongas… solo te muestra » | HIGH |
| LORE_POWER_STATION_02_TEXT | « No dejen que su quietud los engañe » | same ustedes flip | « No dejes que su quietud te engañe » | HIGH |
| LORE_POLICE_07_TEXT, LORE_GAS_STATION_07_TEXT | « …vayan a la central eléctrica… » | direct quotes of the radio loop must match WORLD_RADIO_01's « ve a la central eléctrica » | « …ve a la central… » | HIGH |
| CHAR_HOLSTER | « Enfundar » | verb as slot label | « Funda » | HIGH |
| enc_locked | « desbloquear la entrada » | encyclopedia entry, not entrance | « desbloquear su ficha » | HIGH |
| DISTRICT_NAME_SUBURBS | « Afueras » | district name drift (DIST_SUBURBS/SCR_PRIGOROD/diaries all say « Suburbios ») | « Suburbios » | HIGH |
| SKILL_COST_SP | « Costo: %d PH » | « Costo » (LatAm) vs « Coste » (es_ES) used elsewhere in the same file | « Coste: %d PH » | HIGH |
| NG_PLUS_STAT_ENEMY_HP | « PV enemigos » | HP rendered PS (ENC_STAT_HP, skill regen) and PV here | « PS enemigos » | HIGH |
| UPG_HINT | « Las monedas vienen de distritos, secretos y logros. » | clipped calque | « Las monedas se consiguen en los distritos, los secretos y los logros. » | HIGH |
| ENEMY_ARSONIST / MONSTER_BURNER | both « Incendiario » | name collision across roster/bestiary | « Incendiario » / « Quemador » if shown together | MEDIUM |
| ESLASHER | « Cortador » | weak creature name | « Acuchillador » | MEDIUM |
| Q_KILL_TANK_TITLE | « Derriba a los tanques » | « tanques » = the vehicle | « Derriba a los acorazados » | MEDIUM |
| TOAST_ITEM_FOUND | « ¡%s encontrado! » | gendered participle with dynamic %s | neutral « Objeto encontrado: %s » if code allows | MEDIUM |
| ACH_17_DESC / SHOP_SKIN_GRANTED | « skins de linterna », « Skin desbloqueada » | platform term is « aspectos » | — | LOW |
| select_slot | « Elige ranura » | missing article | « Elige una ranura » | LOW |
| msg_caught | « ¡Te atraparon! » | impersonal; es_ES would prefer « ¡Te han pillado! » | — | LOW |
| WORLD_FACTION_WATCH_TEXT | « No llamen… Tomen… » | ustedes in a neighbors' note reads LatAm for es_ES (vosotros expected) — diegetic, defensible | — | MEDIUM |
| LORE_POLICE_03_TEXT | « Caza el vano de la puerta » | technical « vano » odd for a creature habit | « Caza el umbral » | MEDIUM |
| LORE_POLICE_05_TEXT | « Dijo que no las robaron, las quitaron… » | active-voice ambiguity of EN passive ("were not stolen") | « Dijo que no eran un robo: las desmontaron… » | MEDIUM |
| LORE_POWER_STATION_04_TEXT | « la copia del pasaporte propio de la central » | "passport" = equipment datasheet → « ficha técnica » | — | MEDIUM |
| NEW_GAME_PLUS / NG keys | « Nueva Partida+ » | odd mid-word capital; es convention « Nueva partida+ » | — | LOW |
| LORE_POWER_STATION_08_TEXT | « el nombre de la ventana esquinera » | clunky compound | « el nombre de la ventana de la esquina » | LOW |
| Q_FIND_ENGINEERS_DESC | « el equipo de ingenieros » | fine (no action) | — | LOW |
