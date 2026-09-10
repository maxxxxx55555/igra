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

---

## Italian (it)

**Verdict:** the strongest literary prose of the Latin-script set (lore notes read natively written — « I corridoi mentono in questo edificio », « La differenza sta cercando vos » register work is excellent). Defects mirror the pipeline pattern: unaccented legacy keys, one CRITICAL malnutrition/false-friend ("sotto-alimentazione" for sub-feed), a codex name collision (Superintendent = « Il Custode del Palazzo » vs the Keeper = « Il Custode »), Title Case headlines, and one skill name from the wrong semantic field (« Accumulatore » = battery/accumulator for Pack Rat). Counts: **CRITICAL 1 (1 fixed)** · **HIGH 27 (27 fixed)** · MEDIUM 10 · LOW 7. (28 HIGH were identified; hud_power «Energia» and MAP_STAGE_1 «Energia parziale» proved already correct — no-ops, no row emitted.)

| key | current | issue | suggested_fix | priority |
|---|---|---|---|---|
| WORLD_NEWS_ARCHITECT_TEXT | « …collegate tramite la sotto-alimentazione dell'ospedale… » | **meaning break:** « sotto-alimentazione » = malnutrition; "sub-feed" is an electrical feeder | « …tramite l'alimentazione secondaria dell'ospedale… » | CRITICAL |
| ACHIEVEMENTS_TITLE | « Trofei » | achievements split between « Trofei » (here) and « Obiettivi » (legacy key, REWARD_ACHIEVEMENT, UPG_HINT, SCR labels); Google Play it uses « Obiettivi » | « Obiettivi » | HIGH |
| ~10 keys: difficulty, sens, AD_WATCHING, DISTRICT_ALREADY_FULL, FINAL_NIGHT_BEGINS, HUD_STEALTH, HUD_VISIBILITY, yes, (see rows) | « Difficolta », « FURTIVITA », « e gia », « citta e », « Si » | systemic accent loss in the legacy set | restore à/è/é/ì (per-key rows) | HIGH |
| msg_caught | « Sei stato catturato! » | gendered (assumes male player) | « Ti hanno preso! » | HIGH |
| ENEMY_ROTTER | « Marcio » | vs MONSTER_ROTTER « Putrefatto » — same creature two names | « Putrefatto » | HIGH |
| CHAR_HOLSTER | « Ripone » | verb as equipment-slot label | « Fondina » | HIGH |
| SKILL_INVENTORY_SPACE_NAME | « Accumulatore » | wrong semantic field — accumulator = battery in an electrical game | « Accaparratore » | HIGH |
| WORLD_CHAR_SUPERINTENDENT_TITLE | « Il Custode del Palazzo » | **name collision** with the Keeper (« Il Custode ») in the codex | « L'Amministratore » | HIGH |
| WORLD_CHAR_RADIOVOICE_TEXT | « Andate alla centrale… vi incontrerà » | radio voice uses voi here, tu in WORLD_RADIO_01 (same canon quote) | « Va' alla centrale… ti incontrerà » | HIGH |
| WORLD_DIARY_K3_TEXT | « smontare il 219, sobborgo » | "the 219" (single) vs all 219 lamps | « smontare i 219 » | HIGH |
| WORLD_DIARY_K1_TEXT | « l'uomo che non ha mai lasciato dimenticare una strada » | calque ("let forget") | « …che non ha mai permesso che una strada fosse dimenticata » | HIGH |
| WORLD_DIARY_K2_TITLE | « La Notte in cui si è Spento » | wrong mid-title capital + missing subject | « La notte in cui la luce si è spente » | HIGH |
| WORLD_NEWS_METERS_TEXT | « City Power incolpa » | faction left in EN (faction = « Azienda Elettrica Comunale ») | « L'azienda incolpa » | HIGH |
| WORLD_NEWS_ARCHITECT/ARENA/METERS/OUTAGES/TREES_TITLE | « Il Consiglio Nega il Programma 'Memoria della Rete' » | English Title Case + straight quotes in it headlines | sentence case + « » (per-key rows) | HIGH |
| WORLD_RADIO_03_TEXT | « Porta una schiena forte. » | calque of "Bring a strong back" | « Ti servirà una schiena forte. » | HIGH |
| UPG_HINT | « Le monete arrivano da distretti, segreti e obiettivi. » | clipped calque | « Le monete si ottengono nei distretti, dai segreti e dagli obiettivi. » | HIGH |
| CODEX_TITLE | « Codice » | reads as "code"; games keep « Codex » | « Codex » | MEDIUM |
| DIST_GAS vs DISTRICT_NAME_GAS_STATION | « Stazione di servizio » vs « Distributore » | two names for one district | « Distributore » | MEDIUM |
| ENEMY_HOUND vs MONSTER_HOUND | « Segugio » vs « Molosso » | creature-name drift | « Segugio » | MEDIUM |
| Q_KILL_TANK_TITLE | « Abbatti i tank » | anglicism | « Abbatti i corazzati » | MEDIUM |
| TOAST_ITEM_FOUND | « %s trovato! » | gendered participle with dynamic %s | « Oggetto trovato: %s » if code allows | MEDIUM |
| ACH_17_DESC / SHOP_SKIN_GRANTED | « skin della torcia » | platform term « aspetti » | — | LOW |
| QCOLLECT_SCRAP_DESC | « utili per il crafting » | anglicism accepted in gamer it | — | LOW |
| ACH_15_DESC | « finale negativo » | it gaming says « finale cattivo » | — | LOW |
| RADIO_TRANSCRIPT_E1/E2, WORLD_RADIO_02 | « Se ci sentite », « State attenti », « Ricordatelo » | radio voi vs WRADIO_01 tu — defensible (broadcast to all listeners) | — | MEDIUM |
| LSCHOOL_03 vs LSCHOOL_06/08 | « Cammina oltre » vs « Contate… andate » | tu/voi flip between lore notes addressed to the same "whoever follows" | — | MEDIUM |
| WORLD_NEWS_OUTAGES_TEXT | « "Una formalità di manutenzione" » | straight quotes vs « » elsewhere | — | LOW |

---

## Portuguese, Brazil (pt_BR)

**Verdict:** best overall consistency of the Latin set (uniform você, « Companhia de Energia Municipal » kept in EN-free form inside lore, « Catador »/« Gazuá » are genuinely native). Same pipeline defects elsewhere: accent loss in legacy keys, the « subalimentação » malnutrition false-friend (CRITICAL), « narrador » for the Recorder, Title Case headlines, and the game title itself disagreeing with in-game vocabulary (« O ULTIMO LAMPIAO » vs « poste de luz » everywhere else — a lampião is an oil lamp). Counts: **CRITICAL 1 (1 fixed)** · **HIGH 46 (46 fixed)** · MEDIUM 9 · LOW 7.

| key | current | issue | suggested_fix | priority |
|---|---|---|---|---|
| WORLD_NEWS_ARCHITECT_TEXT | « …pela subalimentação do hospital… » | **meaning break:** « subalimentação » = malnutrition; electrical sub-feed | « …pela alimentação secundária do hospital… » | CRITICAL |
| ~27 keys: diff_easy, diff_hard, graphics, inventory, music_vol, next_level, quests, tutorial_done, tutorial_jump, victory, you_died, AD_REVIVE, AD_TITLE, AD_WATCHING, DISTRICT_ALREADY_FULL, DISTRICT_STAGE_2, DIST_SUBSTATION, DIST_SUBURBS, DIST_WAREHOUSES, HUD_AMMO, HUD_NOISE, FINAL_NIGHT_BEGINS, NEED_DISTRICT_FIRST, NEED_ITEM, menu_title… | « Facil », « Graficos », « Missoes », « VOCE MORREU », « MUNICAO », « RUIDO », « ja esta », « estao » | **systemic accent loss** in the legacy set (newer keys accented correctly) | restore ç/á/é/í/ó/ú (per-key rows) | HIGH |
| menu_title | « O ULTIMO LAMPIAO » | title word disagrees with the entire game: a « lampião » is an oil lamp; all gameplay text says « poste de luz » (A01_DESC, FINAL_NIGHT, lore) | « O ÚLTIMO POSTE DE LUZ » | HIGH |
| CHAR_HOLSTER | « Guardar » | verb as equipment-slot label | « Coldre » | HIGH |
| enc_locked | « desbloquear a entrada » | encyclopedia entry | « desbloquear o verbete » | HIGH |
| NG_PLUS_STAT_ENEMY_HP | « HP dos inimigos » | HP rendered « PV » in bestiary/skills, « HP » here | « PV dos inimigos » | HIGH |
| Q_KILL_SNIPER_DESC / _TITLE | « Snipers dominam os telhados », « Caçador de snipers » | anglicism vs ENEMY_SNIPER « Franco-atirador » | « Franco-atiradores… », « Caçador de franco-atiradores » | HIGH |
| LORE_SUBSTATION_07/08_TEXT | « a letra do narrador » ×2 | wrong character word: the Recorder is « O Gravador » | « a letra do gravador » | HIGH |
| LORE_SUBSTATION_08_TEXT | « — vão para a usina. » | quote of the radio loop must match WORLD_RADIO_01's « Vá até a usina » | « — vá para a usina. » | HIGH |
| LORE_SUBSTATION_01_TEXT | « às 03h00 a porta ficando aberta sozinha sem nada na soleira » | broken gerund construction in the official log | « às 03h00 a porta aberta sozinha, sem nada na soleira » | HIGH |
| LORE_SUBSTATION_03_TEXT | « essa é a cerca até onde caminhamos dois distritos para chegar » | tangled calque of "the fence we walked two districts to reach" | « essa é a cerca pela qual caminhamos dois distritos até chegar » | HIGH |
| LORE_SUBSTATION_05_TEXT | « pelo subalimentador do hospital » | invented term; align with the CRITICAL sub-feed fix | « pelo alimentador secundário do hospital » | HIGH |
| WORLD_NEWS_METERS_TEXT | « A City Power culpa » | faction left in EN | « A companhia culpa » | HIGH |
| WORLD_NEWS_ARCHITECT/ARENA/METERS/OUTAGES/TREES_TITLE | « Medidores Giram para Trás em Três Ruas » | English Title Case + straight quotes in pt headlines | sentence case + « » (per-key rows) | HIGH |
| WORLD_CHAR_RADIOVOICE_TEXT | « Vão até a usina… vai encontrá-los » | radio voice plural here vs « você » in WORLD_RADIO_01 | « Vá até a usina… vai encontrar você » | HIGH |
| WORLD_RADIO_03_TEXT | « esfaima a coisa no centro », « Traga as costas fortes. » | rare verb « esfaimar » + calque of "Bring a strong back" | « mata de fome a coisa no centro », « Você vai precisar de costas fortes. » | HIGH |
| WORLD_DIARY_K3_TEXT | « desmontar o 219, subúrbio » | "the 219" (single) vs all 219 lamps | « desmontar os 219 » | HIGH |
| WORLD_DIARY_K2_TITLE | « A Noite em que Apagou » | missing subject + odd capitalization | « A noite em que a luz se apagou » | HIGH |
| UPG_HINT | « As moedas vêm de distritos, segredos e conquistas. » | missing articles (clipped) | « As moedas vêm dos distritos, dos segredos e das conquistas. » | HIGH |
| ENEMY_ARSONIST / MONSTER_BURNER | both « Incendiário » | name collision across roster/bestiary | « Incendiário » / « Queimador » if shown together | MEDIUM |
| Q_KILL_TANK_TITLE | « Derrube os tanques » | « tanques » = vehicles | « Derrube os blindados » | MEDIUM |
| DISTRICT_NAME_SUBURBS | « Subúrbios » | pt_BR « subúrbio » = working-class outskirts (cultural shift vs EN leafy suburbs) — acceptable, worth an eye | — | MEDIUM |
| ACH_06_NAME | « Quieto como um Rato » | calque of "Quiet as a mouse"; pt idiom prefers « Silencioso como um rato » | — | MEDIUM |
| WEAKSPOT_STROBE_COMBO | « Combo de flash + ataque » | « flash » vs « Estroboscópio » elsewhere | « Combo de estroboscópio + ataque » | MEDIUM |
| TOAST_ITEM_FOUND | « %s encontrado! » | gendered participle with dynamic %s | « Item encontrado: %s » if code allows | MEDIUM |
| ACH_17_DESC / SHOP_SKIN_GRANTED | « skins de lanterna » | pt platform term « visuais » | — | LOW |
| SCR_PEREDVIGAETSYA… | « Move-se de quatro. » | clipped | « Move-se sobre quatro patas. » | LOW |
| LORE_SUBSTATION_02_TEXT | « sua geada derretida num anel limpo » | possessive participle construction | « com a geada derretida num anel limpo » | LOW |
| LORE_SUBSTATION_06_TEXT | « Ele as expõe. » | "He stages them" — « dispõe » is closer | — | LOW |

## Turkish (tr)

**Verdict:** Readable, surprisingly strong lore prose (LWAREHOUSES_04 "Yerinin alınması budur", LGAS_STATION_02 "hiç gerçekten ağarmadı" are genuinely good), but the legacy UI keys (~26) shipped with stripped Turkish diacritics — a longstanding tell of Russian-made games in Turkey and instantly visible on the very first screen. Beyond that: a 3-way coin-terminology split (jeton / para / madeni para), two enemy-name collisions, "City Power" left untranslated, water-tap false friend "musluk" for an electrical tap, and "Bring a strong back" calqued literally. Counts: CRITICAL 2, HIGH 54, MEDIUM 9, LOW 7.

**CRITICAL (2, fixed):**
| Key | Was | Fix | Why |
|---|---|---|---|
| LORE_WAREHOUSES_05_TEXT | Arıza değil: bir musluk. | Arıza değil: kaçak bir bağlantı. | "Musluk" = water faucet; EN "not a fault: a tap" means an illegal electrical tap — "kaçak bağlantı" is the standard TR term. Meaning break in a canon document. |
| WORLD_DIARY_K3_TEXT | 219'u sök, banliyö, trafo merkeze. | 219'u sök, banliyö, transformatörü merkeze götür. | "trafo merkeze" misparses as "to the trafo merkezi" (= the substation, the game's own term); EN means "transformer → the center" (the Architect's lair). Canon destination flipped. |

**HIGH (54, fixed):**
| Key | Was | Fix | Why |
|---|---|---|---|
| achievements | Basarımlar | Başarımlar | Diacritic loss (ş) — first screen. |
| back_menu | Ana Menu | Ana Menü | Diacritic loss (ü). |
| confirm_quit | Cikmak istedigine emin misin? | Çıkmak istediğine emin misin? | Diacritics (Ç, ğ). |
| empty_slot | Bos | Boş | Diacritic (ş). |
| loading | Yukleniyor... | Yükleniyor... | Diacritic (ü). |
| multiplayer | Coklu Oyuncu | Çoklu Oyuncu | Diacritic (Ç). |
| music_vol | Muzik Sesi | Müzik Sesi | Diacritic (ü). |
| next_level | Sonraki Bolum | Sonraki Bölüm | Diacritic (ü). |
| paused | Duraklatildi | Duraklatıldı | Diacritic (ı). |
| quests | Gorevler | Görevler | Diacritic (ö). |
| quit | Cikis | Çıkış | Diacritics (Ç, ı). |
| select_slot | Yuva Sec | Yuva Seç | Diacritic (ç). |
| shop | Magaza | Mağaza | Diacritic (ğ). |
| tip1 | Feneri acik tut - dusmanlar isiktan korkar. | Feneri açık tut - düşmanlar ışıktan korkar. | Diacritics ×5. |
| tip2 | Sarj etmek 1,5 saniye surer. | Şarj etmek 1,5 saniye sürer. | Diacritics. |
| tip3 | Canin azken siginak kullan. | Canın azken sığınak kullan. | Diacritics. |
| tip4 | Harita icin M'ye bas. | Harita için M'ye bas. | Diacritics (i→için). |
| tutorial_done | Egitim tamamlandi. İyi sanslar! | Eğitim tamamlandı. İyi şanslar! | Diacritics. |
| tutorial_interact | E - etkilesim | E - etkileşim | Diacritic (ş). |
| tutorial_jump | BOSLUK - zipla | BOŞLUK - zıpla | Diacritics; all-caps of "boşluk" is BOŞLUK. |
| tutorial_shoot | SOL TIK - ates | SOL TIK - ateş | Diacritic (ş). |
| victory | BOLUM TAMAMLANDI | BÖLÜM TAMAMLANDI | All-caps needs Ö (TR İ/ı rule respected elsewhere; this key missed). |
| weight | Agirlik | Ağırlık | Diacritics. |
| AD_CLAIM | Odulu al | Ödülü al | Diacritics. |
| AD_READY | Odul hazir | Ödül hazır | Diacritics. |
| AD_REVIVE | Yeniden dirilmek icin reklam izle | Yeniden dirilmek için reklam izle | "icin"→"için". |
| AD_TITLE | Odullu reklam | Ödüllü reklam | Diacritics. |
| COINS_AMOUNT | Para: %d | Jeton: %d | Coin-term unification on "jeton" (hud_coins, quest toasts already use it). |
| NOT_ENOUGH_COINS | Yeterli para yok | Yeterli jeton yok | Same unification. |
| UPG_HINT | Paralar bölgelerden… | Jetonlar bölgelerden… | Same unification. |
| REWARD_ACHIEVEMENT / _DISTRICT / _SECRET | +%d madeni para | +%d jeton | Same unification (3 keys). |
| TOAST_COINS_GAINED | +%s madeni para | +%s jeton | Same unification. |
| ENEMY_ROTTER | Çürük | Çürümüş | "Çürük" also means "bruise"; MONSTER_ROTTER is "Çürümüş" — unify. |
| MONSTER_BRUTE | Canavar | Zorba | Collided with ENEMY_BEAST "Canavar"; "Zorba" (bullying brute) separates them. |
| CHAR_HOLSTER | Kılıfa Koy | Kılıf | Verb as equipment-slot label. |
| PHOTO_MODE | Foto modu | Fotoğraf modu | PHOTO_MODE_ON/OFF say "Fotoğraf modu" — unify. |
| DIST_RESIDENTIAL + SCR_ZHILYE_KVARTALY | Yerleşim Bölgesi | Konut Bölgesi | DNAME_RESIDENTIAL says "Konut bölgesi" — 2 keys unified (counts as 2 rows). |
| WORLD_NEWS_METERS_TEXT | City Power 'arızalı tamburları' suçluyor… bir bağlantıdır. Aşağı akışta… | Şirket 'arızalı tamburları' suçluyor… bir kaçak bağlantıdır. Hattın aşağısında bir şey akımı kablolara veriyor, çekmiyor. | Untranslated entity ("City Power" → the faction is "Şehir Elektrik Şirketi"); "bağlantı" alone = any connection, tap needs "kaçak"; "aşağı akış" is a water metaphor, "hattın aşağısı" is the grid term. |
| WORLD_NEWS_ARCHITECT_TEXT | hastane alt beslemesi | hastanenin ikincil besleme hattı | "alt besleme" reads as "under-feeding" (sub-feed malnutrition trap); "ikincil besleme hattı" = secondary feeder line. |
| WORLD_NEWS_ARCHITECT_TITLE | Konsey 'Şebeke Belleği' Programını Yalanlıyor | Konsey «Şebeke Belleği» programını yalanlıyor | TR newspaper headlines are sentence case (not Title Case); «» quote marks for tabloid register. |
| WORLD_NEWS_ARENA_TITLE | Merkezi Arenada Toplanma Noktası | Merkezi arenada toplanma noktası | Headline sentence case. |
| WORLD_NEWS_METERS_TITLE | Üç Sokakta Sayaçlar Geriye Dönüyor | Üç sokakta sayaçlar geriye dönüyor | Headline sentence case. |
| WORLD_NEWS_OUTAGES_TITLE | Dönüşümlü Kesintiler Bu Gece Başlıyor | Dönüşümlü kesintiler bu gece başlıyor | Headline sentence case. |
| WORLD_NEWS_TREES_TITLE | 'Ağaç' Şikayetleri Sonrası Park Kapatıldı | «Ağaç» şikayetleri sonrası park kapatıldı | Headline sentence case + «». |
| WORLD_CHAR_RADIOVOICE_TEXT | Elektrik santraline gidin… sizinle ışıkta buluşacak. | Elektrik santraline git… seninle ışıkta buluşacak. | Radio voice uses "sen" in WORLD_RADIO_01 ("seninle"); plural "siz" here breaks the speaker's identity. |
| WORLD_RADIO_03_TEXT | Güçlü bir sırt getir. | Sırtın sağlam olsun. | Literal calque of "Bring a strong back"; "Sırtın sağlam olsun" is the exact TR idiom said before heavy work. |
| WORLD_DIARY_M1_TEXT | lambamı yakık tutuyorum | lambamı yanık tutuyorum | "yakık" is a common misspelling; the adjective is "yanık" ("keep my lamp burning"). |
| WORLD_CHAR_RECORDER_TITLE | Kayıt Yapan | Kayıtçı | "The one who records" as a codex name reads like a description; "Kayıtçı" is a real noun. |
| LORE_WAREHOUSES_08_TEXT | anlatıcının eliyle | kaydedenin eliyle | "Anlatıcı" = narrator; EN "the recorder's hand" — wrong character word (same trap as ES narrador / PT narrador). |
| LORE_GAS_STATION_06_TEXT | Söktüklerinin, onların içemeyeceği olanlar olduğunu söyledi. | Söktüklerinin, onların içemeyecekleri olduğunu söyledi. | Broken syntax: "the ones that are the ones they cannot drink" — double relative tangle. |
| LORE_GAS_STATION_03_TEXT | bir motorla koşan bir adamın … aynı ses olduğunu söylüyor | bir motor ile koşan bir adamın sesinin … aynı geldiğini söylüyor | Misparse risk: "bir motorla koşan bir adam" = "a man running with an engine"; EN is "an engine and a man running sound the same". |

**MEDIUM (9, documented only):** A16_NAME "Hız Koşucusu" (calque; TR gamers say "Speedrunner"); QKILL_TANK_TITLE "Tankları indir" + QKILL_TANK_DESC (vehicles vs armored monsters — "Zırhlıları indir" clearer); A07_DESC "kombo-3 zinciri" (calque "combo-3"; "3'lü kombo" natural); SKILL_RELOAD_SPEED_NAME "Hızlı Şarjör" ("fast magazine"; should be "Hızlı Doldurma"); WEAPON_COMPARE_RELOAD "Şarjör değişimi" (magazine swap; reload = "yeniden doldurma"); QSECRETS_1/2/3_TITLE "No.1" without space (TR: "No. 1" or "1."); ENEMY_ARSONIST "Kundakçı" / MONSTER_BURNER "Yakıcı" — near-collision but distinguishable, acceptable; WORLD_NEWS_METERS_TEXT "Emekli bir sayaç okuyucusu:" colon usage slightly telegraphic. LOW (7): DGAS title-case vs DNAME lowercase; DNAME_POLICE "Karakol" vs DPOLICE "Polis Karakolu" uneven; "Boss'u yen" anglicism (fine in TR gaming); ¢MONETY_2 "JETON: " trailing space; ¢EST_SOHRANENIE trailing "\|"; ¢ZAGRUZKA "YÜKLENİYOR.. " missing third dot + trailing space; ¢SLOT trailing space.

## Japanese (ja)

**Verdict:** The strongest CJK locale so far — natural idiom choices everywhere (残機 for lives, 真夏の夜の夢 for "A Midsummer Night's Dream", ネズミのように静かに for "quiet as a mouse", well-formed headline style 「議会、「送電網の記憶」計画を否定」). Weaknesses cluster in terminology drift (狙撃兵/狙撃手, 工業地区/工業地帯, 救急箱/救急キット, two 管理人 characters, skill 収集家 colliding with achievement 収集家), the "City Power" entity left in katakana シティ・パワー in one news item while everything else says 市電力公社, half-width punctuation in Japanese prose (!?: and a lone "-"), and two translation slips ("Bring a strong back" rendered literally as 頑丈な背中を持ってこい, and "if you hear us" flipped to 私たちが聞こえるなら). No meaning-breaking errors. Counts: CRITICAL 0, HIGH 28, MEDIUM 8, LOW 7.

**HIGH (28, fixed):**
| Key | Was | Fix | Why |
|---|---|---|---|
| WORLD_NEWS_METERS_TEXT | シティ・パワーは「故障したドラム」のせい… タップだ。…電流を電線に払い込んでいる…取っているのではない | 市電力公社は「故障したドラム」のせい… 盗電だ。…電流を電線に流し込んでいる…吸い取っているのではない | Entity left as katakana "City Power" (faction is 市電力公社 everywhere else); "tap" = illegal electrical tap → 盗電 (electricity theft), the precise JA term; 払い込む is for paying money, current is 流し込む/吸い取る; half-width ":" → full-width. |
| WORLD_NEWS_ARCHITECT_TEXT | 病院の副系統 | 病院の二次フィーダー | "Hospital sub-feed" — 副系統 is not an electrical term; WDIARY_K2 already uses フィーダー for feeder. |
| WORLD_RADIO_03_TEXT | 頑丈な背中を持ってこい | 万全の体で来い | Literal calque of "Bring a strong back"; 万全の体で来い ("come in full readiness") is the natural equivalent. |
| WORLD_CHAR_RADIOVOICE_TEXT | 光を守ってきた者が、光の中で会うだろう | …光の中でお前と会うだろう | Missing indirect object — as written, "will meet in the light" (with whom?); WRADIO_01 gets it right (お前を迎える). |
| WORLD_CHAR_SUPERINTENDENT_TITLE | 管理人（住宅） | 大家 | Collides with Keeper = 管理人 (diaries are 管理人の日記); a housing-block superintendent obsessed with apartment meters is exactly a 大家. |
| WORLD_DIARY_K3_TEXT | 命令14,208番:219番を撤去せよ | 命令14,208番：219番を撤去せよ | Half-width colon in JA prose. |
| WORLD_RADIO_02_TEXT | 三交代目から全員へ:四系統は… | 三交代目から全員へ：四系統は… | Half-width colon. |
| RADIO_TRANSCRIPT_E1 | 私たちが聞こえるなら-光を守って。 | これが聞こえているなら――光を守って。 | "If you hear us" flipped to "if we can hear"; lone half-width hyphen → JA dash ――. |
| DISTRICT_RESTORED_TOAST | 地区を救済：%s | 地区を復旧：%s | 救済 = relief/alms; restoring a district is 復旧 (used everywhere else). |
| CHAR_HOLSTER | 収納 | ホルスター | "Storage" for the holster slot; ホルスター is the standard loanword. |
| ACH_03_NAME | 標 | 希望の灯 | Lone kanji "signpost" for "Beacon"; unreadable as an achievement title. |
| ACH_11_NAME | 経済家 | エコノミスト | 経済家 is not a real Japanese word. |
| SKILL_INVENTORY_SPACE_NAME | 収集家 | ため込み屋 | EN "Pack Rat"; 収集家 collides with ACH_17_NAME "Collector" (収集家). |
| ITEM_SERUM | 血清「ドーン」 | 「夜明け」の血清 | ドーン reads as "Done"/"boom"; the name is Dawn → 夜明け. |
| SKILL_LOOT_LUCK_NAME | 漁り屋 | スカベンジャー | 漁り屋 misreads as "fisherman" (漁); EN "Scavenger". |
| Q_KILL_SNIPER_DESC | 狙撃兵が屋上を占拠… | 狙撃手が屋上を占拠… | ENEMY_SNIPER is 狙撃手 — unify the enemy's name. |
| Q_KILL_SNIPER_TITLE | 狙撃兵ハンター | 狙撃手ハンター | Same unification. |
| DIST_INDUSTRIAL | 工業地区 | 工業地帯 | DNAME_INDUSTRIAL is 工業地帯 — map vs quest drift. |
| Q_RESTORE_DISTRICT2_DESC | 工業地区に光を取り戻せ | 工業地帯に光を取り戻せ | Same unification. |
| Q_REPAIR_DISTRICT1_DESC | 分電盤を見つけ | 配電盤を見つけ | 分電盤 = household breaker panel; PROMPT_REPAIR already says 配電盤. |
| shop_medkit | 救急箱 | 救急キット | ITEM_MEDKIT is 救急キット — unify item name. |
| Q_COLLECT_MEDKIT_DESC | 救急箱を3個集めろ | 救急キットを3個集めろ | Same unification. |
| Q_COLLECT_MEDKIT_TITLE | 救急箱 | 救急キット | Same unification. |
| SCR_APTECHKA | 救急箱 | 救急キット | Same unification. |
| WEAKSPOT_FIRE_IMMUNE | 火に免疫 | 炎耐性 | 免疫 is medical; enemy stat panels say 耐性. |
| JOURNAL_RELATED | 関連:%s | 関連：%s | Half-width colon; rest of the file uses ：. |
| confirm_quit | 終了しますか? | 終了しますか？ | Half-width "?" in JA sentence. |
| tutorial_done | チュートリアル完了。頑張れ! | …頑張れ！ | Half-width "!". |

**MEDIUM (8, documented only):** PROMPT_INTERACT 操作 vs tutorial_interact 調べる (mixed interact verbs); MAP_LOCKED_BY ロック要因 (要因 = contributing factor; ロック原因 cleaner); SHOP_SKIN_GRANTED スキン解除 vs Unlocked: %s 解放 (both words used for "unlock"); Q_FIND_ENGINEERS_TITLE 技術者 vs DESC 技術班; ACH_12_NAME 傷一つなく (adverbial fragment as title; 傷ひとつ負わず reads better); WEAPON_COMPARE_MAG 弾倉 (military register; マガジン is the game norm); WORKBENCH_CRAFTABLE 可 (terse; 作成可 clearer). LOW (7): SCR_MONETY_2 trailing space after コイン：; SCR_SLOT, SCR_VES trailing spaces; SCR_EST_SOHRANENIE trailing "\|"; SCR_ZAGRUZKA "ロード中.. " missing third dot + trailing space; LEVEL_UP_NOTICE mixes half-width space after ！; RADIO_EMERGENCY2 "緊急2" bare numeral.

## Korean (ko)

**Verdict:** Solid, game-native register (해라체 for quest objectives, 합니다체 for UI, punchy toast style), with a couple of genuine howlers: DISTRICT_2_TOAST says "지구 2" — "Earth 2 restored" instead of "district 2" — and the color-blindness settings read as "green medicine / red medicine / blue medicine" (녹색약/적색약/청색약) instead of color-vision deficiency (녹색맹 etc.). "City Power" is left as 시티 파워 in one news item (faction is 시 전력공사), district names drift across three variants (공업 지대/지구/구역, 주택가/주거 지역/주택 구역), "Bring a strong back" is translated literally (튼튼한 등을 가져와라), and the Grid Crew faction is named after a switchboard (배전반 작업조). Counts: CRITICAL 1, HIGH 29, MEDIUM 7, LOW 6.

**CRITICAL (1, fixed):**
| Key | Was | Fix | Why |
|---|---|---|---|
| DISTRICT_2_TOAST | 지구 2 복구! 도시가 다시 숨쉰다. | 2구역 복구! 도시가 다시 숨쉽니다. | "지구 2" reads "Earth 2" — the game's own word for district is 구역; toast register aligned with the rest of the toast family. |

**HIGH (29, fixed):**
| Key | Was | Fix | Why |
|---|---|---|---|
| WORLD_NEWS_METERS_TEXT | 시티 파워는 '고장 난 드럼' 탓이라고 한다… 드럼이 아니라 탭이다 | 시 전력공사는… 드럼이 아니라 무단 탭이다 | Untranslated entity; bare "탭" is the UI word for "tab" — an illegal electrical tap is 무단 탭. |
| WORLD_NEWS_ARCHITECT_TEXT | 병원 부속 배전선 | 병원 보조 배전선 | "Sub-feed": 부속 (accessory) → 보조 (secondary/auxiliary), the standard KO electrical term. |
| WORLD_RADIO_03_TEXT | 튼튼한 등을 가져와라 | 허리 튼튼히 하고 와라 | Literal "bring a sturdy back"; the natural equivalent said before heavy work. |
| WORLD_CHAR_SUPERINTENDENT_TITLE | 관리인 (주택) | 관리소장 | Collides with Keeper = 관리인 (diaries: 관리인의 일기); housing-office superintendent = 관리소장. |
| WORLD_FACTION_GRIDCREW_TITLE | 배전반 작업조 | 전력망 작업조 | 배전반 = switchboard panel; "The Grid Crew" works the grid → 전력망 작업조. |
| WORLD_CHAR_MARAT_TEXT | 뭔가가 전력망에서 끌어당기고 있다 | 뭔가가 전력망에서 전기를 끌어내고 있다 | 끌어당기다 = pull toward oneself physically; drawing power = 끌어내다. |
| VICTORY_DISTRICTS | 복구된 지구 | 복구된 구역 | 지구 (Earth/precinct) vs the game's 구역. |
| msg_win | 모든 구역에 전력이 공급되었다! | …공급되었습니다! | Toast family is 합니다체 (저장되었습니다, 복구되었습니다) — this one plain past. |
| cb_prot / cb_deut / cb_trit | 적색약 / 녹색약 / 청색약 | 적색맹 / 녹색맹 / 청색맹 | "-색약" parses as "…-colored medicine"; color-vision deficiency is 색맹 (3 keys). |
| enc_title | 괴물 백과사전 | 몬스터 도감 | Bestiary is 도감 (BESTIARY·t already says 몬스터 도감); "encyclopedia" is a book, not a UI. |
| CHAR_HOLSTER | 수납 | 홀스터 | "Storage" for the holster slot. |
| ACH_03_NAME | 등대 | 봉화 | "Beacon" → 등대 is a sea lighthouse; for the city relit, 봉화 (signal fire). |
| SKILL_INVENTORY_SPACE_NAME | 수집가 | 수집꾼 | EN "Pack Rat"; collides with ACH_17_NAME 수집가 (Collector). |
| ITEM_SERUM | 혈청 「새벽」 | 혈청「새벽」 | Korean typography: no space before 「. (Note: "새벽" for Dawn is exactly right.) |
| ITEM_LOCKPICK | 따기 도구 | 자물쇠 따개 | "따기 도구" is vague (따다 has many senses); lockpick = 자물쇠 따개. |
| ITEM_MEDKIT | 구급 키트 | 구급상자 | Rest of the game says 구급상자 — unify item name. |
| RADIO_TRANSCRIPT_SOS | 배터리와 구급 키트를 | 배터리와 구급상자를 | Same unification. |
| RADIO_TRANSCRIPT_E1 | 들리신다면-빛을 지켜주세요 | 들리신다면 — 빛을 지켜주세요 | Stray half-width hyphen inside a sentence. |
| DIST_INDUSTRIAL | 공업 지구 | 공업 지대 | DNAME says 공업 지대 — map/quest drift. |
| Q_RESTORE_DISTRICT2_DESC | 공업 구역에 빛을 | 공업 지대에 빛을 | Third variant in the same quest's own title (공업 지대에 전력을) — unify. |
| SCR_PROMYSHLENNAYA_ZONA | 공업 지역 | 공업 지대 | Same unification (legacy label). |
| DIST_RESIDENTIAL | 주거 지역 | 주택가 | DNAME says 주택가. |
| Q_REPAIR_DISTRICT1_TITLE | 주택 구역 변전소 | 주택가 변전소 | Same unification. |
| Q_FIND_ENGINEERS_DESC | 주택 구역을 통과하는 | 주택가를 지나는 | Same unification. |
| SCR_ZHILYE_KVARTALY | 주거 지역 | 주택가 | Same unification. |
| DIST_WAREHOUSES | 창고 지역 | 창고 단지 | DNAME says 창고 단지. |
| LORE_SUBURBS_03_TEXT | 교외 지구 주민 여러분 | 교외 주민 여러분 | Same 지구 trap; the district is just 교외. |

**MEDIUM (7, documented only):** ENEMY_SPITTER 침 뱉는 자 (wordy; 스피터 would match the katakana monster list); PROMPT_HIDE 숨기 (reads as "conceal object"; 숨어들기/은신 clearer); STROBE_READY 스트로브 vs WSTROBE_COMBO 점멸광 (two words for strobe); Q_KILL_TANK_TITLE 탱크 (vehicle vs 장갑 괴물 in its own description); WORKBENCH_CRAFTABLE 가능 (terse); ONBOARD captions (해라체) vs TUT_* (합니다체) register mix on adjacent screens; msg_caught "발각되었다!" / msg_lose "실패했다…" plain vs formal toasts (read as deliberate arcade flavor — acceptable). LOW (6): SCR_MONETY_2 / SCR_SLOT / SCR_VES trailing spaces; SCR_ZAGRUZKA "로딩 중.. " missing third dot + trailing space; SCR_EST_SOHRANENIE trailing "\|"; RADIO_EMERGENCY2 "비상 2" bare numeral.

## Chinese, Simplified (zh)

**Verdict:** Genuinely good localization with confident transcreation (守灯人 for the Keeper, 被喂食者 for the Fed, 「黎明」血清 for Dawn serum, 暗影无处可逃 for "no escape for the shadows"). Two systematic defects: (1) the entire WORLD_* codex block shipped with half-width , ; : punctuation between Chinese characters — a classic machine-translation tell, 22 keys; (2) the currency is called both 硬币 and 金币 across different screens. Add the ENEMY_ARSONIST/MONSTER_BURNER name collision (both 纵火者), a verb where a slot label belongs (收枪 for Holster — and there is no gun in this game), and "Bring a strong back" translated literally. Counts: CRITICAL 0, HIGH 41, MEDIUM 6, LOW 6.

**HIGH (41, fixed):**
| Key | Was | Fix | Why |
|---|---|---|---|
| Q_KILL_TANK_DESC | 装甲怪物挡住了通往市中心的路，放倒三具尸体。 | …留下三具尸体。 | "放倒尸体" = knock down corpses (corpses don't stand); EN "Three bodies." means leave three bodies behind. |
| MONSTER_BURNER | 纵火者 | 焚烧者 | Collides with ENEMY_ARSONIST 纵火者 — two different creatures, one name. |
| CHAR_HOLSTER | 收枪 | 枪套 | Verb "holster the gun" as an equipment-slot label; the weapon is a flashlight. |
| DISTRICT_RESTORED_TOAST | 区域已拯救：%s | 区域已恢复：%s | 拯救 = rescue (a person); a district is restored (恢复), as every other key says. |
| VICTORY_DISTRICTS | 恢复的地区 | 恢复的区域 | 地区 vs the game's own 区域 (hud_district, MAP_PROGRESS). |
| COINS_AMOUNT / ITEM_COIN / NOT_ENOUGH_COINS / REWARD_* (×3) / TOAST_COINS_GAINED / UPG_HINT | 金币 | 硬币 | Currency split 金币/硬币 across screens; HUD, shop and achievements say 硬币 (8 keys). |
| BLUEPRINT_APPLIED | 已应用蓝图 | 已应用图纸 | Item names all say 图纸 (×4) — unify. |
| SKILL_RELOAD_SPEED_DESC / _NAME | 装填速度 / 快速装填 | 换弹速度 / 快速换弹 | tip2 and weapon compare say 换弹 — unify the gameplay term. |
| ACH_06_NAME | 静如鼠 | 悄无声息 | "静如鼠" is not a Chinese idiom; "quiet as a mouse" → 悄无声息. |
| RADIO_TRANSCRIPT_E1 | 如果听到我们-请守护光明。 | 如果你能听到我们——请守护光明。 | Dropped subject + stray half-width hyphen; zh dash is ——. |
| JOURNAL_RELATED | 相关:%s | 相关：%s | Half-width colon; rest of the file uses ：. |
| WORLD_RADIO_03_TEXT | 带上一副强壮的脊背来。 | 带副好身板来。 | Literal "bring a strong back"; 带副好身板来 is the natural thing to say before heavy work. |
| WORLD_NEWS_METERS_TEXT | 城市电力公司 | 市电力公司 | Faction name elsewhere is 市电力公司 (WORLD_FACTION_CITYPOWER_TITLE). |
| WORLD_NEWS_ARCHITECT_TEXT | 『建筑师计划』 | 「建筑师计划」 | Project names elsewhere use 「」; 『』 is for quotes nested inside 「」. |
| WORLD_CHAR_* (6), WORLD_FACTION_* (3), WORLD_RADIO_01/02/03 (3+title), WORLD_DIARY_* (4), WORLD_NEWS_* (4) | half-width , ; : between Chinese characters | ，；： | 22 keys total (incl. the three above): full-width punctuation is mandatory in zh prose; half-width commas between hanzi are the classic MT tell. Times (22:00) untouched. |

**MEDIUM (6, documented only):** ENEMY_ROTTER / MONSTER_ROTTER both 腐烂者 (inherited: both are "Rotter" in EN too); WORKBENCH_CRAFTABLE 可 (terse; 可制作 clearer); diff_normal 普通 vs legacy SCR labels 正常; WORLD_NEWS_METERS_TEXT 分接头 (transformer tap — technically fine, 私接 clearer for lay readers); D2_TOAST "城市重新呼吸" (poetic, slightly stiff; 城市再次呼吸); ¢IGRAT 开始游戏 duplicates menu_play. LOW (6): SCR_MONETY_2 / SCR_SLOT / SCR_VES trailing spaces; SCR_EST_SOHRANENIE trailing "\|"; SCR_ZAGRUZKA "加载中.. " missing third dot + trailing space; tutorial keys "F - 手电筒" half-width hyphens (consistent within the set).

## Chinese, Traditional (zh_TW)

**Verdict:** A real adaptation, not a conversion: 存檔/儲存, 主選單, 連線, 滑鼠, 空白鍵, 電晶體, 電動機, 破關, 專案, 計畫 — all correct TW vocabulary where zh_CN used mainland terms. It inherits every zh defect (half-width punctuation across the 22-key WORLD codex block, 硬幣/金幣 split, ENEMY_ARSONIST/MONSTER_BURNER collision, 收槍 for Holster, "strong back" calque, 放倒屍體 logic slip), and adds its own terminology drift: 發電站 (16 keys, mainland-preferred) against the map label 發電廠; three spellings of "workbench" (工作檯/工作臺/工作台, 14 keys); 信號 vs the TW-standard 訊號; 祕密 vs 秘密. Counts: CRITICAL 0, HIGH 77, MEDIUM 5, LOW 7.

**HIGH (77, fixed):**
| Key | Was | Fix | Why |
|---|---|---|---|
| Q_KILL_TANK_DESC | 放倒三具屍體 | 留下三具屍體 | Corpses don't get knocked down; EN "Three bodies." = leave bodies behind. |
| MONSTER_BURNER | 縱火者 | 焚燒者 | Collides with ENEMY_ARSONIST 縱火者. |
| CHAR_HOLSTER | 收槍 | 槍套 | Verb as slot label; the weapon is a flashlight. |
| DISTRICT_RESTORED_TOAST | 區域已拯救：%s | 區域已恢復：%s | 拯救 is for people; districts are restored. |
| VICTORY_DISTRICTS | 恢復的地區 | 恢復的區域 | 地區 vs the game's own 區域. |
| COINS_AMOUNT / ITEM_COIN / NOT_ENOUGH_COINS / REWARD_* (×3) / TOAST_COINS_GAINED / UPG_HINT | 金幣 | 硬幣 | Currency split (9 keys); HUD and quest toasts say 硬幣. |
| BLUEPRINT_APPLIED | 已套用藍圖 | 已套用圖紙 | Items say 圖紙. |
| SKILL_RELOAD_SPEED_DESC / _NAME | 裝填速度 / 快速裝填 | 換彈速度 / 快速換彈 | tip2 and weapon compare say 換彈. |
| ACH_06_NAME | 靜如鼠 | 悄無聲息 | Not a Chinese idiom. |
| RADIO_TRANSCRIPT_E1 | 如果聽到我們-請守護光明 | 如果你能聽到我們——請守護光明 | Dropped subject + stray hyphen. |
| JOURNAL_RELATED | 相關:%s | 相關：%s | Half-width colon. |
| confirm_quit / tutorial_done | 確定離開? / 祝你好運! | ？/！ | Half-width ? and ! in Chinese sentences. |
| tip1 | 保持手電筒開啟 - 敵人畏懼光芒 | …——… | Half-width hyphen; zh prose elsewhere uses ——. |
| menu_quit / SCR_VYHOD | 退出 | 離開 | TW usage (quit 離開 already); 退出 is mainland register. |
| 發電站 → 發電廠 (16 keys) | 發電站 | 發電廠 | DISTRICT_NAME_POWER_STATION says 發電廠; 發電廠 is the standard TW term. Includes endings, FINAL_NIGHT_GOTO_STATION, radio voice, and 7 LORE keys. |
| 工作檯 / 工作台 → 工作臺 (13 keys) | three spellings | 工作臺 | WORKBENCH_TITLE says 工作臺; unify quests + 11 LORE/codex keys. |
| 信號 → 訊號 (3 keys) | 求救信號 | 求救訊號 | 訊號 is the TW standard (EVENT_DISTRESS/RADIO_DISTRESS already correct). |
| 祕密 → 秘密 (2 keys) | 祕密 | 秘密 | Mixed with 秘密 everywhere else. |
| WORLD_CHAR_ANYA_TEXT | 在轉角窗口 | 在轉角窗邊 | 窗口 in TW reads as "service counter", not a window. |
| WORLD_* codex block (22 keys) | half-width , ; : | ，；： | Same MT-tell as zh; full-width punctuation in hanzi prose. Times untouched. |
| WORLD_RADIO_03_TEXT | 帶上一副強壯的脊背來 | 帶副好身板來 | Literal "bring a strong back". |
| WORLD_NEWS_METERS_TEXT | 城市電力公司 | 市電力公司 | Faction name unification. |
| WORLD_NEWS_ARCHITECT_TEXT | 『建築師計畫』 | 「建築師計畫」 | 『』 is for nested quotes only. |

**MEDIUM (5, documented only):** ENEMY_ROTTER / MONSTER_ROTTER both 腐爛者 (inherited EN collision); WORKBENCH_CRAFTABLE 可 (terse); IAUDIO_LOG 錄音日誌 (錄音檔 more natural for a tape item); diff_normal 普通 vs legacy SCR 正常; SCR keys trailing spaces (see LOW). LOW (7): SCR_MONET double leading space; SCR_MONETY_2 / SCR_SLOT / SCR_VES trailing spaces; SCR_EST_SOHRANENIE trailing "\|"; SCR_ZAGRUZKA "載入中.. " missing third dot + trailing space; tutorial keys "F - 手電筒" half-width hyphens (consistent within the set).

## Arabic (ar)

**Verdict:** Strong, fluent literary Arabic (يوميات الحارس — المناوبة الأولى, «الفجر» serum, سيد الضوء) with correct RTL-aware handling (RLM marks before +%d rewards). The problems are single-word misfires that a native hits immediately: "the drinker" rendered as الشارب — which first reads as "the mustache"; blunt damage rendered as "sharp damage" (ضرر حاد); the electrical fuse rendered as "molten" (منصهر) and elsewhere as "electrical valve" (صمام); the canned food "on the step" rendered as "from the grade" (من الدرجة); tip2's reloading rendered as "reconstruction"; and the radio voice slips into plural address in the codex while speaking singular on the radio. Counts: CRITICAL 1, HIGH 24, MEDIUM 8, LOW 6.

**CRITICAL (1, fixed):**
| Key | Was | Fix | Why |
|---|---|---|---|
| WORLD_DIARY_K3_TEXT | الشارب يجد الشبكة عبر المصابيح القادرة على الاحتراق | الذي يشرب يجد الشبكة عبر المصابيح القادرة على الاحتراق | الشارب = "the mustache" on first read; EN "The drinker" is the Keeper's name for the thing in the center — canon term garbled in the key diary. |

**HIGH (24, fixed):**
| Key | Was | Fix | Why |
|---|---|---|---|
| enc_locked | قابل المخلوق لفتح الإدخال. | قابل المخلوق لفتح بطاقته. | الإدخال = data input; a codex entry is بطاقة. |
| tip2 | إعادة التعمير تستغرق 1.5 ثانية. | إعادة التلقيم تستغرق 1.5 ثانية. | التعمير = construction/rebuilding; reloading = إعادة التلقيم (matches weapon compare + skill). |
| confirm_quit | الخروج بالتأكيد؟ | هل تريد الخروج؟ | "Exiting with certainty?" — not a question a native speaker asks. |
| ACH_07_NAME | سيد التتابع | سيد الكومبو | "Master of sequence/relay" for Combo Master; كومبو is the universal gaming loanword. |
| ENEMY_SLASHER | السلاخ | الممزّق | السلاخ = slaughterer/flayer (abattoir register); a claw monster shreds — الممزّق. |
| ENEMY_SPITTER | البصّاق | الباصق | بصّاق = saliva (noun); the creature is the doer — الباصق. |
| ITEM_FUSE | منصهر | فيوز | منصهر = molten; an electrical fuse is فيوز. |
| SCR_PREDOHRANITEL | صمام كهربائي | فيوز | صمام = valve; unify with ITEM_FUSE. |
| DISTRICT_RESTORED_TOAST | تم إنقاذ المنطقة: %s | تمت استعادة المنطقة: %s | إنقاذ = rescue (people); district restore = استعادة (as DSTAGE_*/DALREADY_FULL say). |
| VICTORY_DISTRICTS | المناطق المرممة | المناطق المستعادة | مرممة = patched-up buildings; unify with WIN_SUMMARY/STATS (مستعادة). |
| ENDING_LIGHT_DESC / END_LIGHT_DESC | تقول الراديو: "شكرًا لك" | يقول الراديو… | الراديو is masculine — gender agreement (2 keys). |
| Hardcore Mode | الوضع الصعب | وضع Hardcore | ACH_18_DESC says وضع Hardcore; settings must match (Latin "Hardcore" is normal in AR gaming). |
| craft | صناعة | صنع | Craft menu label vs WORKBENCH_CRAFT صنع and CRAFT_CREATED تم الصنع — صناعة also means "industry". |
| WORKBENCH_CREATE_BTN | إنشاء | صنع | Third verb for the same action (صناعة/صنع/إنشاء) — unify. |
| WEAKSPOT_BLUNT | ضرر حاد | ضرر الصدم | حاد = sharp — the exact opposite of blunt; impact damage = ضرر الصدم. |
| Q_FIND_ENGINEERS_DESC | القطاع السكني | الحي السكني | District = حي everywhere else (Q_REPAIR_DISTRICT1_TITLE: الحي السكني); قطاع is the outlier. |
| WORLD_FACTION_WATCH_TEXT | خذوا الطعام المعلّب من الدرجة | …من على العتبة | الدرجة = grade/rank; "the food on the step [of the door]" = العتبة. |
| WORLD_CHAR_RADIOVOICE_TEXT | اذهبوا… سيقابلكم… | اذهب… سيقابلك… | The radio voice addresses the player singular in WORLD_RADIO_01; plural here breaks the speaker's identity. |
| WORLD_RADIO_03_TEXT | أحضر ظهرًا قويًا. | ستحتاج ظهرًا قويًا. | Literal "bring a strong back"; "you'll need a strong back" is the natural phrasing. |
| WORLD_NEWS_ARCHITECT_TEXT | '…' quotes; التغذية الفرعية للمستشفى | «…» quotes; خط التغذية الفرعي للمستشفى | WNEWS_OUTAGES uses «» — unify quote style; "hospital sub-feed" needs خط (line) to read electrically. |
| WORLD_NEWS_ARCHITECT_TITLE | 'ذاكرة الشبكة' | «ذاكرة الشبكة» | Quote style. |
| WORLD_NEWS_TREES_TEXT | 'تميل نحو المصابيح لتستمع' / 'الأشجار' | «…» ×2 | Quote style unification. |
| WORLD_DIARY_M1_TEXT | إنه خجل | إنه يشعر بالخجل | "He is shyness" — needs a proper predicate. |

**MEDIUM (8, documented only):** ENEMY_ROTTER / MONSTER_ROTTER both المتعفن (inherited EN collision); hud_lives الأرواح ("souls" — acceptable AR gaming, المحاولات more standard); WORLD_NEWS_METERS_TEXT نقطة سحب ("draw point" — توصيل غير قانوني is the precise term for an illegal tap, but نقطة سحب is comprehensible); msg_win "جميع الأحياء" (أحياء = neighborhoods vs "the living" — context disambiguates); SBATTERY_CAPACITY_DESC / SMAX_HEALTH_DESC / SSTAMINA_BOOST_DESC "+25 البطارية القصوى" number-first pattern (RTL-rendering artifact, readable); WEAPON_STROBE_COMBO مزيج vs كومبو; GAME_OVER_STATS القتلى (casualty noun as kill counter — عددها clearer); VICTORY_STATS القتلى same. LOW (6): SCR_MONET leading double space; SCR_MONETY_2 / SCR_SLOT / SCR_VES trailing spaces; SCR_EST_SOHRANENIE trailing "\|"; SCR_ZAGRUZKA "جارٍ التحميل.. " missing third dot + trailing space.


## Final tally (all 11 locales, pass complete)

| Locale | CRITICAL found/fixed | HIGH found/fixed | MEDIUM | LOW | Fix rows in PROSE_CHANGES |
|---|---|---|---|---|---|
| fr | 4 / 4 | 49 / 49 | 11 | 7 | 53 |
| de | 0 / 0 | 36 / 36 | 8 | 5 | 36 |
| es | 0 / 0 | 48 / 48 | 10 | 7 | 48 |
| it | 1 / 1 | 27 / 27 | 10 | 7 | 28 |
| pt_BR | 1 / 1 | 46 / 46 | 9 | 7 | 47 |
| tr | 2 / 2 | 54 / 54 | 9 | 7 | 56 |
| ja | 0 / 0 | 28 / 28 | 8 | 7 | 28 |
| ko | 1 / 1 | 29 / 29 | 7 | 6 | 30 |
| zh | 0 / 0 | 41 / 41 | 6 | 6 | 41 |
| zh_TW | 0 / 0 | 77 / 77 | 5 | 7 | 77 |
| ar | 1 / 1 | 24 / 24 | 8 | 6 | 25 |
| **Total** | **10 / 10** | **459 / 459** | **91** | **72** | **469** |

**0 CRITICAL remaining after fixes.** All 469 rows are text-only replacements: no key/id/stage/gameplay changes, no deletions, placeholder parity verified per row (`%s`/`%d` counts preserved). Cross-cutting patterns fixed in every affected locale: the "sub-feed" malnutrition false friend, "City Power" left untranslated, "Bring a strong back" calque, verb-as-Holster-label, recorder/narrator word confusion, radio-voice person consistency, news-headline casing, district-name drift, coin/medkit/workbench terminology unification, enemy-name collisions (Arsonist/Burner), and locale-specific diacritic/punctuation regressions (tr stripped diacritics; ja/zh/zh_TW half-width punctuation; fr/es/it/pt accents).

Cross-locale notes for the owner (documented, not fixed): ENEMY_ROTTER/MONSTER_ROTTER share the name "Rotter" in EN itself, so the collision in es/it/pt/tr/ko/zh/zh_TW/ar is source-inherited; ENEMY_ARSONIST vs MONSTER_BURNER collisions were fixed where they occurred (fr/es/it/pt documented as MEDIUM, tr/ko? n/a, zh/zh_TW fixed to 焚烧者/焚燒者; ar already distinct). SCR_MONETY_2 / SCR_SLOT / SCR_VES trailing spaces and SCR_ZAGRUZKA ".. " exist in most locales and mirror the RU source — a pipeline-level cleanup, not per-locale.
