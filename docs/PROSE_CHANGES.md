# PROSE_CHANGES — finishing-pass English prose edits (canon source → locale handoff)

Owner: CONTENT agent. Machine-readable handoff for CLAUDE / the locale agent.
Scope of the finishing pass: all **88 district lore notes** (`content/districts/*/lore_notes.json`)
plus the **world bible prose** (`content/world/*.json`, `content/lore/*.json` — characters,
factions, history, radio, diary, news). Goals per task: fix typos, canon inconsistencies and
tone drift; keep every id / i18n key / stage / gate **unchanged**; Play-Store-grade writing
(short, atmospheric, zero filler). `content/**` JSON remains the canon source.

## How to consume

One row per changed **i18n text** below, as `KEY<TAB>final_en_text` (tab-separated). Keys are
the `i18n_keys` values already present in the content JSON — the text after the tab is the
**authoritative final English string** and must replace the current English source for that key
in `data/i18n/*.json` (en) and, for translators, be marked changed in all 13 locales. Do **not**
rename keys; do **not** re-derive text from anywhere but the row below.

## Review conclusion (2026-09-09)

Re-read in full (11 district packs + world bible). No typos, no canon contradictions, no tone
drift found that required edits beyond the two lines below. Every gate-visible structural
property (ids, i18n keys, `min_stage`, stages, world-refs reachability, repair-chain proofs)
was re-verified unchanged in the §10 re-run (`docs/CONTENT_PIPELINE_AUDIT.md`).

The single real defect: the canonical concept "the center (of the city / the grid)" was spelled
`centre` in two in-world requisition forms (gas station, police) written by the same recurring
character — the Keeper — while all **24** other in-world uses across the 88 notes and the world
bible spell it `center` (American throughout). Standardized the two requisition REASON lines to
`center` for orthographic/canon consistency. (The `gas_station` pack's `location_hint` metadata
string keeps `centre`; hints are not player-facing prose and are outside this handoff contract.)

## Changed rows

LORE_GAS_STATION_06_TEXT	A station requisition pad, one page filled in by a hand that does not belong to a petrol station. "ITEM: canopy floodlight transformer, one. REASON: it will be needed at the center. AUTHORISED BY: —" and there the signature is just a small drawing of a streetlight inside a circle. Underneath, the manager's own biro: "Old man came at dusk, took the transformer, left this. Knew which bolt to loosen first. Said the ones he takes down are the ones they cannot drink. I didn't argue. Nobody's buying petrol anyway."

LORE_POLICE_06_TEXT	A release form that is not in the station's typeface. "ITEM: yard flood transformer, one. REASON: it will be needed at the center. AUTHORISED BY: —" and there the signature is the small streetlight-in-a-circle again. Underneath, the duty sergeant's own biro: "He knew which cage. He knew which bolt. He said the ones he takes down are the ones they cannot drink. I signed because the floods had already come on once with the switch off, and I would rather they were gone."

## Mega final pass (2026-09-10)

Full re-read of all 88 district notes + world bible (characters, factions, history,
radio, diary, news). No typos (scanned), no canon contradictions, no tone drift beyond
the three surgical lines below. Structural properties untouched (ids, i18n keys,
`min_stage`, stages, world-refs) — re-verified in the §11 mega-final re-run
(`docs/CONTENT_PIPELINE_AUDIT.md`).

- `LORE_PARK_02_TEXT`: flat photo-caption ending → quotable kicker ("Nobody in the
  queue knew the order would never be given again.").
- `LORE_PARK_07_TEXT`: tone fix — "The voice is the same one as the manifesto's
  seal" equated a voice with a wax seal; now "The voice belongs to whoever pressed
  the seal." (Keeper's streetlight-in-circle seal, cf. `LORE_PARK_01_TITLE`
  "The Keeper's Manifesto, Posted Copy" — the manifesto reference itself was canon).
- `LORE_POLICE_05_TEXT`: flat clerk-log ending → in-voice quotable kicker ("The
  property book has never cleared six items faster.").

## Changed rows (mega final pass)

LORE_PARK_02_TEXT	The same carousel that rots at the north lawn, but painted and spinning, horses mid-gallop, a queue of children two rows deep. Every lamp post around it is lit for the evening ride. On the back: "Last summer. The lights stayed on till midnight by order of the park office." Nobody in the queue knew the order would never be given again.

LORE_PARK_07_TEXT	A captured broadcast, looped on the shed's shortwave: a calm voice under static, neither young nor old: "...the grid can still be brought back. District by district, lamp by lamp. Go to the power station. The one who kept the light will meet you at the light." The loop ends with three soft clicks, like a streetlight relay. The voice belongs to whoever pressed the seal.

LORE_POLICE_05_TEXT	Evidence flash on a steel locker: six streetlight heads tagged and stacked, glass intact, brass rings still warm-looking in the photograph. Daylight — this is from before. On the back, a property clerk's hand: "Seized from the park road. Owner would not give a name. Said they were not stolen, they were taken down so they could not be drunk. Released to the same old man two nights later. He signed with a streetlight in a circle. The property book has never cleared six items faster."


## Locale native-QA fixes (2026-09-10, GOLD MASTER v2)

Owner: NATIVE QA agent. Machine-readable locale re-sync handoff, same contract as the EN rows above:
one row per changed localized string, `KEY | LOCALE | old_en_source_if_relevant | new_localized_text`.
Text-only replacements — keys, ids, stages, placeholders (`%s`/`%d`/`%.1f`/`%.2f`) and gameplay are
unchanged (verified: key parity 1061/1061, placeholder parity 0 mismatches). `-` = EN source not
relevant (typography/accents/terminology fix). Priority tags: [C]=CRITICAL, [H]=HIGH.

[H] AD_CLAIM | fr | - | Récupérer la récompense
[H] AD_READY | fr | - | Récompense prête
[H] AD_TITLE | fr | - | Publicité récompensée
[H] AD_WATCHING | fr | - | Publicité... %d s
[H] BLUEPRINT_APPLIED | fr | - | Plan appliqué : amélioration débloquée
[H] DISTRICT_ALREADY_FULL | fr | - | Le district est déjà entièrement restauré
[H] DISTRICT_STAGE_1 | fr | - | %s : alimentation partiellement rétablie
[H] DISTRICT_STAGE_2 | fr | - | %s : les réverbères sont allumés
[H] DISTRICT_STAGE_3 | fr | - | %s : district entièrement restauré
[H] INSPECT_NOTHING | fr | - | Rien d'intéressant.
[H] JOURNAL_FOUND | fr | - | Documents trouvés : %d sur %d
[H] WIN_SUMMARY | fr | - | Districts restaurés : %d/%d   Documents trouvés : %d/%d
[H] controls | fr | - | Contrôles
[H] difficulty | fr | - | Difficulté
[H] fullscreen | fr | - | Plein écran
[H] quests | fr | - | Quêtes
[H] retry | fr | - | Réessayer
[H] sens | fr | - | Sensibilité souris
[H] tutorial_done | fr | - | Tutoriel terminé. Bonne chance !
[H] tutorial_move | fr | - | WASD - se déplacer
[H] CHECKPOINT_SET | fr | - | POINT DE CONTRÔLE ACTIVÉ
[H] HUD_STEALTH | fr | - | FURTIVITÉ
[H] HUD_VISIBILITY | fr | - | VISIBILITÉ
[H] DOC_FOUND | fr | - | DOCUMENT TROUVÉ
[H] you_died | fr | - | VOUS ÊTES MORT
[H] FINAL_NIGHT_BEGINS | fr | - | La ville est à nouveau éclairée. Mais quelque chose approche.
[H] FINAL_NIGHT_GOTO_STATION | fr | - | Retournez à la centrale électrique
[H] VICTORY_STATS | fr | - | Temps : %ds ¦ Éliminés : %d
[H] tip1 | fr | - | Gardez la lampe allumée — les ennemis craignent la lumière.
[H] tip3 | fr | - | Mettez-vous à couvert quand vos PV sont bas.
[H] tip4 | fr | - | Appuyez sur M pour ouvrir la carte.
[H] menu_subtitle | fr | - | Un survivant dans une nuit éternelle. Rendez sa lumière à la ville.
[H] msg_caught | fr | You were caught! | Vous vous êtes fait prendre !
[H] confirm_quit | fr | Quit for sure? | Voulez-vous vraiment quitter ?
[H] CHAR_HOLSTER | fr | Holster | Étui
[H] enc_locked | fr | Encounter the creature to unlock the entry. | Rencontrez la créature pour débloquer sa fiche.
[H] DIST_SUBSTATION | fr | - | Poste électrique
[H] Q_REPAIR_DISTRICT1_TITLE | fr | Restart the residential substation | Rétablissez le poste électrique résidentiel
[H] RADIO_TRANSCRIPT_E2 | fr | - | ...nous avons tenté de restaurer le poste électrique. Ils viennent avec l'obscurité. Méfiez-vous.
[H] SCR_AKTIVNYE_PODSTANCII_3_8 | fr | - | Postes actifs : 3/8
[H] SCR_AVARIYA_NA_PODSTANCII | fr | - | Panne au poste électrique
[H] SCR_PODSTANCIYA | fr | - | Poste électrique
[H] SCR_PODSTANCIY | fr | - | POSTES ÉLECTRIQUES
[H] UPG_HINT | fr | Coins come from districts, secrets and achievements. | Les pièces se gagnent dans les districts, les secrets et les succès.
[H] WORLD_DIARY_K3_TEXT | fr | Decided. The drinker finds the grid through the lamps that can burn; a dismantled lamp is a door walled shut. Order 14,208: dismantle 219, suburbs, transformer to the center. I kept the light for forty years. Now I keep it backwards. Forgive me, streets. | Décidé. Celui qui boit trouve le réseau à travers les lampadaires qui peuvent brûler ; un lampadaire démonté est une porte murée. Ordre 14 208 : démonter les 219, banlieue, transformateur au centre. J'ai gardé la lumière quarante ans. Maintenant je la garde à l'envers. Pardonnez-moi, rues.
[H] WORLD_RADIO_02_TEXT | fr | Third shift to anyone: feeder four is not faulty, repeat, not faulty. The draw is deliberate. Marat traced it to a test tap that is not on any map. We are walking the line to the substation. If we do not call again — the bench proof stands. One streetlight. Remember that. | Troisième équipe à tous ceux qui écoutent : l'alimentation quatre n'est pas défectueuse, je répète, pas défectueuse. La consommation est délibérée. Marat l'a retracée jusqu'à une prise de test qui ne figure sur aucune carte. On suit la ligne jusqu'au poste. Si on ne rappelle pas — la preuve du banc d'essai tient. Un seul lampadaire. Souvenez-vous-en.
[H] WORLD_RADIO_03_TEXT | fr | You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back. | Tu restaures ce que je démonte, et nous avons tous les deux raison. Chaque lampadaire que tu allumes nourrit la ville. Chaque lampadaire que j'emporte affame la chose au centre. Éclaire les districts. Je te retrouverai au dernier avec tout ce que j'ai gardé. Quarante ans de lumière, ingénieur. Il te faudra de bons bras.
[H] LORE_HOSPITAL_08_TEXT | fr | Columns for name, ward, time, drawer. The last page keeps the names and abandons the rest. "Night three: eleven admitted below, nine accounted for at dawn. Drawers were closed from the inside. I am not writing 'deceased' any more, I am writing 'left', and the difference is the whole of my report. Whoever reads this: they are not something that came instead of them. They are them. Turn your lamp off before you open the last row." | Colonnes pour le nom, le service, l'heure, le tiroir. La dernière page garde les noms et abandonne le reste. « Troisième nuit : onze admis en bas, neuf comptés à l'aube. Les tiroirs étaient fermés de l'intérieur. Je n'écris plus 'décédé', j'écris 'parti', et la différence, c'est tout mon rapport. Quiconque lit ceci : ce n'est pas quelque chose venu les remplacer. Ce sont eux. Éteins ta lampe avant d'ouvrir la dernière rangée. »
[C] LORE_HOSPITAL_06_TITLE | fr | Archive Box 14 — Sub-Feed Four | Boîte d'archives 14 — alimentation secondaire quatre
[C] LORE_HOSPITAL_06_TEXT | fr | A works requisition, nine years old, carbon copy, stamped twice. Sub-feed four: dedicated night circuit, hospital to park line, "to be metered separately and not entered on the building plan". Purpose field, typed: to store what the lamps have seen. Programme name, typed: PROJECT ARCHITECT. Authorising signature, hand-written, and beneath it a pencil note from whoever filed the box: "Council says this program does not exist. Council also says do not shred this." | Une réquisition de travaux, vieille de neuf ans, papier carbone, tamponnée deux fois. Alimentation secondaire quatre : circuit de nuit dédié, hôpital vers la ligne du parc, « à mesurer séparément et à ne pas inscrire sur le plan du bâtiment ». Champ objet, tapé à la machine : stocker ce que les lampadaires ont vu. Nom du programme, tapé à la machine : PROJET ARCHITECTE. Signature autorisante, manuscrite, et dessous une note au crayon de celui qui a classé la boîte : « Le conseil dit que ce programme n'existe pas. Le conseil dit aussi de ne pas détruire ceci. »
[C] LORE_HOSPITAL_07_TEXT | fr | Nine engineers under a single test lamp on a gantry, arms folded, pleased with themselves. Eight are looking at the camera. The ninth, half a step back, is looking up at the lamp, and his face is the only one in focus. On the back, a caption in fountain pen with one name inked out so hard the paper split: "Sub-feed four, first light. It held for nine hours and it remembered every one of them." | Neuf ingénieurs sous une seule lampe d'essai sur un portique, bras croisés, contents d'eux-mêmes. Huit regardent l'appareil photo. Le neuvième, un demi-pas en arrière, lève les yeux vers la lampe, et son visage est le seul net. Au dos, une légende au stylo plume avec un nom raturé si fort que le papier s'est déchiré : « Alimentation secondaire quatre, première lumière. Elle a tenu neuf heures et s'est souvenue de chacune d'elles. »
[C] WORLD_NEWS_METERS_TEXT | fr | Apartment meters on three residential streets record negative draw at night. City Power blames 'faulty drums'. A retired meterman: a backwards meter is not a faulty drum, it is a tap. Something downstream is paying current into the wires, not taking it. | Les compteurs d'appartements dans trois rues résidentielles enregistrent une consommation négative la nuit. La compagnie invoque des « tambours défectueux ». Un releveur de compteurs à la retraite : un compteur qui tourne à l'envers n'est pas un tambour défectueux, c'est un branchement clandestin. Quelque chose en aval injecte du courant dans les fils, au lieu de le prélever.
[H] WORLD_DIARY_K1_TEXT | fr | First shift today. Two hundred and nineteen lamps in the suburbs alone. The foreman says a lamp out is a street forgot. I intend to be remembered as the man who never let the street be forgot. Order 1 logged. | Première garde aujourd'hui. Deux cent dix-neuf lampadaires rien que dans la banlieue. Le contremaître dit qu'un lampadaire éteint est une rue oubliée. Je veux qu'on se souvienne de moi comme de l'homme qui n'a jamais laissé une rue sombrer dans l'oubli. Ordre 1 consigné.
[H] back_menu | de | - | Hauptmenü
[H] music_vol | de | - | Musik-Lautstärke
[H] sfx_vol | de | - | Effekt-Lautstärke
[H] next_level | de | - | Nächstes Level
[H] select_slot | de | - | Slot wählen
[H] tip1 | de | - | Lass die Taschenlampe an - Feinde fürchten Licht.
[H] tip4 | de | - | Drücke M für die Karte.
[H] tutorial_done | de | - | Tutorial beendet. Viel Glück!
[H] tutorial_shoot | de | - | LINKSKLICK - schießen
[H] AD_SKIP | de | - | Überspringen
[H] AD_TITLE | de | - | Werbung für Belohnung
[H] DEATH_TITLE | de | YOU DIED | DU BIST TOT
[H] SCR_VY_POGIBLI | de | - | DU BIST TOT
[H] quests | de | - | Quests
[H] CODEX_TAB_QUESTS | de | - | Quests
[H] JOURNAL_RELATED | de | Related: %s | Siehe auch: %s
[H] CHAR_HOLSTER | de | Holster | Holster
[H] ENEMY_ROTTER | de | Rotter | Verrotteter
[H] PROMPT_REPAIR | de | Repair panel (needs: %s) | Verteilerkasten reparieren (benötigt: %s)
[H] Q_FIND_FUSES_DESC | de | - | Durchsuche das Gebiet nach Sicherungen für den Verteilerkasten
[H] Q_REPAIR_DISTRICT1_DESC | de | - | Finde den Verteilerkasten und versorge den Bezirk mit Strom
[H] WORLD_NEWS_METERS_TEXT | de | - | Wohnungszähler in drei Wohnstraßen zeichnen nachts negativen Verbrauch auf. Die Stadtwerke geben 'defekten Trommeln' die Schuld. Ein pensionierter Zählerableser: Ein rückwärtslaufender Zähler ist keine defekte Trommel, es ist ein Abgriff. Etwas stromabwärts speist Strom in die Leitungen, statt ihn zu entnehmen.
[H] WORLD_NEWS_ARCHITECT_TITLE | de | - | Rat bestreitet „Netzgedächtnis“-Programm
[H] WORLD_NEWS_METERS_TITLE | de | - | Zähler laufen auf drei Straßen rückwärts
[H] WORLD_NEWS_OUTAGES_TITLE | de | - | Rollierende Abschaltungen beginnen heute Nacht
[H] WORLD_NEWS_TREES_TITLE | de | - | Park nach „Baum“-Beschwerden geschlossen
[H] WORLD_NEWS_ARENA_TITLE | de | - | Sammelpunkt in der zentralen Arena
[H] WORLD_DIARY_K2_TITLE | de | Keeper's Diary — The Night It Went Out | Tagebuch des Wächters — Die Nacht, in der das Licht erlosch
[H] WORLD_CHAR_RADIOVOICE_TEXT | de | Go to the power station. The one who kept the light will meet you at the light. | Geht zum Kraftwerk. Wer das Licht gehütet hat, wird dir im Licht begegnen.
[H] DIST_POLICE | de | - | Polizeiwache
[H] SCR_POLICEYSKIY_UCHASTOK | de | - | Polizeiwache
[H] DIST_SUBURBS | de | - | Vororte
[H] SCR_PRIGOROD | de | - | Vororte
[H] DIST_WAREHOUSES | de | - | Lagerkomplex
[H] SCR_SKLADSKOY_KOMPLEKS | de | - | Lagerkomplex
[H] LORE_INDUSTRIAL_05_TEXT | de | A machining order from the stores cage, twelve years before the blackout. Client line: blank. Quantity: four hundred metering drums, special wind. Special instruction, typed: WIND THE SECOND COIL TO PAY CURRENT BACK DOWN THE LINE. The day foreman's stamp across it: REFUSED — A METER MEASURES. Below, in a different ink, the disposition that actually happened: "Reassigned to night shift. The night shift does not read instructions." The shipping stubs stapled behind it name two destinations only — a line through the park, and the hospital sub-feed — and the retired meterman who came asking after his drums three years later was shown the door. His parting line is pencilled on the stub by whoever filed this: "He said, a backwards meter is not a fault, it is a tap, and the substation has never lied to him once." | Ein Bearbeitungsauftrag aus dem Lagerkäfig, zwölf Jahre vor dem Stromausfall. Kundenzeile: leer. Menge: vierhundert Zählertrommeln, Sonderwicklung. Sonderanweisung, getippt: DIE ZWEITE SPULE SO WICKELN, DASS STROM IN DIE LEITUNG ZURÜCKGESPEIST WIRD. Der Stempel des Tagvorarbeiters darüber: ABGELEHNT — EIN ZÄHLER MISST. Darunter, in anderer Tinte, die tatsächliche Verfügung: „An die Nachtschicht übertragen. Die Nachtschicht liest keine Anweisungen.“ Die dahinter gehefteten Versandbelege nennen nur zwei Ziele — eine Leitung durch den Park und die Krankenhaus-Unterspeisung — und der pensionierte Zählertechniker, der drei Jahre später nach seinen Trommeln fragen kam, wurde vor die Tür gesetzt. Sein Abschiedssatz ist mit Bleistift auf dem Beleg von wem auch immer dies abgelegt hat, notiert: „Er sagte, ein rückwärts laufender Zähler ist kein Fehler, es ist ein Abzweig, und das Umspannwerk hat ihn nicht ein einziges Mal belogen.“
[H] diff_easy | es | - | Fácil
[H] diff_hard | es | - | Difícil
[H] empty_slot | es | - | Vacío
[H] graphics | es | - | Gráficos
[H] menu_title | es | - | LA ÚLTIMA FAROLA
[H] music_vol | es | - | Volumen de música
[H] tip1 | es | - | Mantén la linterna - los enemigos temen la luz.
[H] yes | es | - | Sí
[H] HUD_AMMO | es | - | MUNICIÓN
[H] DISTRICT_ALREADY_FULL | es | - | El distrito ya está completamente restaurado
[H] DISTRICT_STAGE_1 | es | - | %s: energía parcialmente restaurada
[H] DISTRICT_STAGE_2 | es | - | %s: las farolas están encendidas
[H] DIST_POLICE | es | - | Comisaría
[H] DIST_POWER | es | - | Central Eléctrica
[H] DIST_SUBSTATION | es | - | Subestación
[H] INSPECT_NOTHING | es | - | Nada de interés.
[H] FINAL_NIGHT_GOTO_STATION | es | - | Regresa a la central eléctrica
[H] confirm_quit | es | - | ¿Seguro que quieres salir?
[H] tutorial_done | es | - | Tutorial completado. ¡Suerte!
[H] CHAR_HOLSTER | es | Holster | Funda
[H] enc_locked | es | Encounter the creature to unlock the entry. | Encuentra la criatura para desbloquear su ficha.
[H] DISTRICT_NAME_SUBURBS | es | - | Suburbios
[H] SKILL_COST_SP | es | - | Coste: %d PH
[H] NG_PLUS_STAT_ENEMY_HP | es | - | PS enemigos: x%.2f
[H] Q_KILL_RUNNER_DESC | es | Runners are the boldest things out tonight. Take five. | Los corredores son los más atrevidos de esta noche. Elimina cinco.
[H] UPG_HINT | es | - | Las monedas se consiguen en los distritos, los secretos y los logros.
[H] WORLD_NEWS_METERS_TEXT | es | Apartment meters on three residential streets record negative draw at night. City Power blames 'faulty drums'. A retired meterman: a backwards meter is not a faulty drum, it is a tap. Something downstream is paying current into the wires, not taking it. | Los contadores de apartamentos en tres calles residenciales registran consumo negativo por la noche. La compañía culpa a 'tambores defectuosos'. Un técnico de contadores jubilado: un contador que gira hacia atrás no es un tambor defectuoso, es una toma. Algo, más abajo en la línea, está inyectando corriente en los cables en lugar de consumirla.
[H] WORLD_NEWS_ARCHITECT_TITLE | es | - | El consejo niega el programa «Memoria de la Red»
[H] WORLD_NEWS_ARENA_TITLE | es | - | Punto de reunión en la arena central
[H] WORLD_NEWS_METERS_TITLE | es | - | Los contadores giran hacia atrás en tres calles
[H] WORLD_NEWS_OUTAGES_TITLE | es | - | Los cortes por rotación comienzan esta noche
[H] WORLD_NEWS_TREES_TITLE | es | - | Parque cerrado tras quejas sobre los «árboles»
[H] WORLD_CHAR_RADIOVOICE_TEXT | es | Go to the power station. The one who kept the light will meet you at the light. | Ve a la central eléctrica. Quien guardó la luz te recibirá en la luz.
[H] WORLD_RADIO_03_TEXT | es | You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back. | Estás restaurando lo que yo desmonto, y ambos tenemos razón. Cada farola que enciendes alimenta a la ciudad. Cada farola que me llevo mata de hambre a lo que está en el centro. Ilumina los distritos. Te encontraré en el último con todo lo que he guardado. Cuarenta años de luz, ingeniero. Vas a necesitar una espalda fuerte.
[H] WORLD_DIARY_K3_TEXT | es | Decided. The drinker finds the grid through the lamps that can burn; a dismantled lamp is a door walled shut. Order 14,208: dismantle 219, suburbs, transformer to the center. I kept the light for forty years. Now I keep it backwards. Forgive me, streets. | Decidido. El que bebe encuentra la red a través de las farolas que pueden arder; una farola desmontada es una puerta tapiada. Orden 14.208: desmontar las 219, suburbios, transformador al centro. Guardé la luz durante cuarenta años. Ahora la guardo al revés. Perdónenme, calles.
[H] LORE_POWER_STATION_03_TEXT | es | A tape from the signal loft's big receiver, labelled in the night operator's hand: ANSWER — SAME VOICE, NEW WORDS. The calm voice that spent a year looping the call is looping it no longer. It answers: "You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back." The operator's note under the tape: "It knows the districts are lit. It is counting with us." | Una cinta del gran receptor del desván de señales, etiquetada con la letra del operador nocturno: RESPUESTA — MISMA VOZ, PALABRAS NUEVAS. La voz calmada que pasó un año repitiendo la llamada en bucle ya no la repite. Responde: «Estás restaurando lo que yo estoy desmontando, y ambos tenemos razón. Cada lámpara que enciendes alimenta la ciudad. Cada lámpara que me llevo mata de hambre a lo que está en el centro. Ilumina los distritos. Te encontraré en el último con todo lo que he guardado. Cuarenta años de luz, ingeniero. Vas a necesitar una espalda fuerte». La nota del operador bajo la cinta: «Sabe que los distritos están iluminados. Está contando con nosotros».
[H] LORE_POLICE_01_TEXT | es | The station's own carbon of list two, stamped RECEIVED 03:12. Same forty-seven names as the school-yard sheet, plus a duty sergeant's addendum in the margin: "Assembly at 04:00. Doors of this building stay locked after they leave. Anyone still in the cells at 04:10 is not on the list and is not our problem." The last line is in a different pen: "We processed the list. We did not walk anyone to the yard. That was the point of a list." | La copia en papel carbón de la comisaría de la lista dos, sellado RECIBIDO 03:12. Los mismos cuarenta y siete nombres que en la hoja del patio escolar, más una nota al margen del sargento de guardia: «Reunión a las 04:00. Las puertas de este edificio permanecen cerradas después de que se vayan. Quien siga en las celdas a las 04:10 no está en la lista y no es problema nuestro». La última línea está escrita con otra pluma: «Procesamos la lista. No acompañamos a nadie al patio. Ese era el sentido de una lista».
[H] LORE_POLICE_02_TEXT | es | Shot through the observation slit: four bunk frames, one blanket on the floor, the bench rail gouged in parallel lines that do not match a tool. No people. On the back, a felt pen: "Cell 4 held three overnight. Morning count was zero. The lock was still locked from our side. Do not put a lamp in the corridor — it doesn't care about lamps, and the light just shows you the empty bunk." | Tomada a través de la mirilla: cuatro armazones de litera, una manta en el suelo, el riel del banco marcado con surcos paralelos que no coinciden con ninguna herramienta. Sin gente. Al reverso, con rotulador: «La celda 4 tuvo a tres durante la noche. El recuento matutino fue cero. El cerrojo seguía echado por nuestro lado. No pongas una lámpara en el pasillo: no le importan las lámparas, la luz solo te muestra la litera vacía».
[H] LORE_POLICE_07_TEXT | es | Recorded off the dispatch set with the squelch rolled all the way open. Same loop the park shed carries, but it comes in on the station's own channel now, between bursts of the dead siren tail: "...district by district... lamp by lamp... go to the power station..." then three soft clicks like a relay, then a sergeant, very tired: "It's been on our frequency since the diesel died. We stopped answering. It does not need us to answer." | Grabado del equipo de despacho con el silenciador completamente abierto. El mismo bucle que porta la caseta del parque, pero ahora llega por el canal propio de la comisaría, entre ráfagas de la cola muerta de la sirena: «...distrito por distrito... farola por farola... ve a la central eléctrica...» luego tres clics suaves como un relé, luego un sargento, muy cansado: «Ha estado en nuestra frecuencia desde que murió el diésel. Dejamos de responder. No necesita que respondamos».
[H] LORE_GAS_STATION_07_TEXT | es | Recorded off a car radio with the door open, battery nearly flat. The same loop the park shed carries, but thinner out here, breaking up between words: "...district by district... lamp by lamp... go to the power station..." then a wash of static, then the three soft clicks like a relay closing. Whoever taped it added their own voice at the end, very tired: "It's been saying that for a month. Somebody should go." | Grabado de una radio de coche con la puerta abierta, batería casi agotada. El mismo bucle que lleva la caseta del parque, pero más débil aquí fuera, cortándose entre palabras: «...distrito a distrito... farol a farol... ve a la central eléctrica...» luego una ráfaga de estática, luego los tres clics suaves como un relé cerrándose. Quien lo grabó añadió su propia voz al final, muy cansada: «Lleva diciendo eso un mes. Alguien debería ir.»
[H] LORE_POWER_STATION_02_TEXT | es | A long-exposure photograph of the turbine hall, taken from the gallery on a night the station was fully dark. The three generators stand in a row like sleeping animals, and above them the dark is not empty — the exposure caught it moving, a slow churn in the black over the middle machine, the way heat moves over a road that is not hot. No flash was used. Nothing in the hall was lit. On the back, in a hand that does not appear anywhere else in the station: "They are not running. Do not let them being still fool you." | Una fotografía de larga exposición de la nave de turbinas, tomada desde la galería en una noche en que la central estaba completamente a oscuras. Los tres generadores están en fila como animales dormidos, y sobre ellos la oscuridad no está vacía — la exposición captó movimiento, un lento agitarse en el negro sobre la máquina del medio, como se mueve el calor sobre una carretera que no está caliente. No se usó flash. Nada en la nave estaba encendido. Al reverso, en una letra que no aparece en ningún otro lugar de la central: «No están funcionando. No dejes que su quietud te engañe».
[H] LORE_WAREHOUSES_08_TEXT | es | - | Pegada con cinta dentro de la puerta de la sala de alimentadores: la puerta este de noche, dos figuras con una carretilla, tambores apilados, una figura vuelta hacia la cámara — el rostro perdido en la niebla, pero la postura es la de un hombre contando un almacén que está dejando. Al reverso, la letra del grabador: «Volví la tercera noche. Me llevé los tambores del doce al dieciocho y todos los fusibles del estante etiquetado. Dejé la jaula tranquila — la llave nunca apareció, y no somos de los que cortan candados. Si estás leyendo esto después de que las luces se enciendan: el clasificador funcionó todo el tiempo que trabajamos. Revisa la cinta. Ahora cuenta todo lo que sale de este patio, y nos contó a nosotros al salir».
[H] LORE_INDUSTRIAL_08_TEXT | es | - | Pegada con cinta a la propia puerta sur, tomada desde la pasarela la primera noche en que los propios reflectores de la planta aguantaron: la puerta abierta de par en par, el camino corriendo al sur pasando la valla de la fábrica hacia las luces de la subestación en el horizonte lejano — el centro de la telaraña, por fin lo bastante cerca para verse desde aquí. La letra del grabador al reverso: «Registro de la cuadrilla, última anotación de esta planta. Caminamos la línea hacia adentro, la caminaremos hacia afuera. La voz de la radio no deja de decirlo y nunca ha dicho por qué — vayan a la central eléctrica, quien cuidó la luz les encontrará en la luz. Marat dice que la voz es una cuadrilla que nunca conocimos. Yo digo que la voz conoce los números de pedido del farolero y oí al propio hombre contar 219 de ellos en este muelle. Quienquiera que encuentre a quienquiera en esa luz — el camino empieza aquí, y más allá de la puerta de la subestación nadie vuelve caminando para contarlo. Dejen la puerta abierta detrás de ustedes. Es la última que se abre en ambos sentidos».
[H] LORE_SUBSTATION_07_TEXT | es | - | Una cinta encontrada encajada en el bastidor de relés, etiquetada con la letra del grabador: RELÉ — ENVIAR SI NO VOLVEMOS. La última llamada de la cuadrilla, reproducida por el propio altavoz del bastidor: «Tercer turno a quien sea: el alimentador cuatro no está defectuoso, repito, no está defectuoso. El consumo es deliberado. Marat lo rastreó hasta una derivación de prueba que no está en ningún mapa. Estamos caminando la línea hacia la subestación. Si no volvemos a llamar — la prueba del banco se mantiene. Una farola. Recuerden eso». No volvieron a llamar. La cinta es la llamada. Quienquiera que la enhebre en el transmisor del bastidor reproduce la voz de la cuadrilla de vuelta al aire que nunca volvieron a escuchar.
[H] LORE_SUBSTATION_08_TEXT | es | - | Pegada con cinta a la puerta este sellada, tomada desde la valla del cementerio la primera noche en que los reflectores del patio aguantaron: la puerta encadenada y con candado desde dentro, el camino corriendo al este pasando la valla hacia las torres de la central eléctrica en el horizonte — el último camino de la ciudad. En la escarcha en la esquina de la valla, más allá de la puerta, las marcas de ruedas de una carretilla y huellas de botas cortan a través de la malla desde dentro, dirigiéndose al este. La letra del grabador al reverso: «Marat dice que la derivación se alimenta desde el este. Descansamos una noche y la recorremos. La voz de la radio no deja de decirlo y nunca ha dicho por qué — vayan a la central eléctrica. Vamos. Si la puerta está sellada cuando leas esto, la sellamos detrás de nosotros».
[H] LORE_POWER_STATION_01_TEXT | es | - | La carretilla de la cuadrilla está de pie dentro de la puerta de la central, descargada y marcada con tiza. Los tambores han desaparecido — llevados adentro. La tiza en su plataforma es la letra del grabador, y es un manifiesto, no un mensaje: fusibles, alambre de bastidor, la lámpara de banco de los suburbios envuelta en una cortina. Debajo del manifiesto, una línea para quien camine la línea después: «Marat contó el consumo todo el camino hasta aquí. Termina en esta puerta. Sea lo que sea que la derivación estaba alimentando, ahora se alimenta desde dentro de estas paredes, y vamos a entrar a medirlo. La carretilla se queda — el camino de vuelta es cuesta abajo y no la necesitaremos».
[H] LORE_POWER_STATION_07_TEXT | es | - | Un casete en el reproductor del campamento de la cuadrilla, llevado dos distritos al este en la propia mochila del grabador. Es el estanque de Manya, semanas atrás — hielo, viento, y la voz de la anciana diciendo nombres en voz alta hacia la oscuridad, uno por uno, como los dice para los alimentados: el cartero, los gemelos, el padre de Katya. Y luego la voz de un miembro de la cuadrilla, más suave, añadiendo el único nombre que nunca fue suyo decir: «Petrov». Un largo silencio. Luego el grabador, apenas audible: «Se quedan quietos. Tiene razón. Se quedan quietos. Nos llevamos esto al este. Si algo en el centro todavía recuerda haber sido un hombre, se quedará quieto por su nombre».
[H] LORE_POWER_STATION_08_TEXT | es | - | Tomada desde la pasarela de la torre de refrigeración la primera noche en que la central aguantó: las torres iluminadas desde abajo, y en la puerta debajo de ellas la lámpara de la puerta ardiendo — una farola, la carretilla de la cuadrilla junto a ella, y un cuenco de comida puesto a su pie. La nota del guardabosques está sujeta a la copia: los álamos de la central se han inclinado hacia la lámpara de la puerta todo el invierno, como se inclinaban los árboles del parque antes del apagón. La lista de guardia está sujeta debajo, última línea: el nombre de la ventana esquinera, no tachado — relevado, lámpara mantenida. Y la letra del grabador al reverso, por último: «Una farola. La prueba del banco se mantiene en el centro».
[H] difficulty | it | - | Difficoltà
[H] sens | it | - | Sensibilità del mouse
[H] AD_WATCHING | it | - | Pubblicità... %d s
[H] DISTRICT_ALREADY_FULL | it | - | Il distretto è già completamente ripristinato
[H] FINAL_NIGHT_BEGINS | it | - | La città è di nuovo illuminata. Ma qualcosa sta arrivando.
[H] HUD_STEALTH | it | - | FURTIVITÀ
[H] HUD_VISIBILITY | it | - | VISIBILITÀ
[H] yes | it | - | Sì
[H] achievements | it | - | Obiettivi
[H] msg_caught | it | You were caught! | Ti hanno preso!
[H] ENEMY_ROTTER | it | Rotter | Putrefatto
[H] CHAR_HOLSTER | it | Holster | Fondina
[H] SKILL_INVENTORY_SPACE_NAME | it | Pack Rat | Accaparratore
[C] WORLD_NEWS_ARCHITECT_TEXT | it | - | Il consiglio nega di finanziare qualsiasi 'Progetto Architetto' per 'conservare ciò che i lampioni hanno visto'. La smentita nomina il progetto con un titolo che nessun giornalista aveva usato. Le linee di prova del programma, secondo i registri, erano collegate tramite la alimentazione secondaria dell'ospedale e la linea del parco.
[H] WORLD_CHAR_RADIOVOICE_TEXT | it | Go to the power station. The one who kept the light will meet you at the light. | Va' alla centrale elettrica. Chi ha custodito la luce ti incontrerà nella luce.
[H] WORLD_DIARY_K3_TEXT | it | Decided. The drinker finds the grid through the lamps that can burn; a dismantled lamp is a door walled shut. Order 14,208: dismantle 219, suburbs, transformer to the center. I kept the light for forty years. Now I keep it backwards. Forgive me, streets. | Deciso. Chi beve trova la rete attraverso i lampioni che possono ardere; un lampione smontato è una porta murata. Ordine 14.208: smontare i 219, sobborgo, trasformatore al centro. Ho custodito la luce per quarant'anni. Ora la custodisco al contrario. Perdonatemi, strade.
[H] WORLD_DIARY_K1_TEXT | it | First shift today. Two hundred and nineteen lamps in the suburbs alone. The foreman says a lamp out is a street forgot. I intend to be remembered as the man who never let the street be forgot. Order 1 logged. | Primo turno oggi. Duecentodiciannove lampioni nel solo sobborgo. Il caposquadra dice che un lampione spento è una strada dimenticata. Intendo essere ricordato come l'uomo che non ha mai permesso che una strada fosse dimenticata. Ordine 1 registrato.
[H] WORLD_DIARY_K2_TITLE | it | - | Diario del Custode — La notte in cui la luce si è spente
[H] WORLD_NEWS_METERS_TEXT | it | Apartment meters on three residential streets record negative draw at night. City Power blames 'faulty drums'. A retired meterman: a backwards meter is not a faulty drum, it is a tap. Something downstream is paying current into the wires, not taking it. | I contatori degli appartamenti in tre strade residenziali registrano un consumo negativo di notte. L'azienda incolpa 'tamburi difettosi'. Un ex tecnico dei contatori: un contatore che gira all'indietro non è un tamburo difettoso, è una derivazione. Qualcosa a valle sta immettendo corrente nei fili, non prelevandola.
[H] WORLD_NEWS_ARCHITECT_TITLE | it | - | Il consiglio nega il programma «Memoria della Rete»
[H] WORLD_NEWS_ARENA_TITLE | it | - | Punto di raccolta all'arena centrale
[H] WORLD_NEWS_METERS_TITLE | it | - | I contatori girano all'indietro in tre strade
[H] WORLD_NEWS_OUTAGES_TITLE | it | - | Le interruzioni a rotazione iniziano stanotte
[H] WORLD_NEWS_TREES_TITLE | it | - | Parco chiuso dopo lamentele sugli «alberi»
[H] WORLD_RADIO_03_TEXT | it | You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back. | Stai ripristinando ciò che io smonto, e abbiamo entrambi ragione. Ogni lampione che accendi nutre la città. Ogni lampione che porto via affama la cosa al centro. Illumina i distretti. Ti incontrerò nell'ultimo con tutto ciò che ho custodito. Quarant'anni di luce, ingegnere. Ti servirà una schiena forte.
[H] UPG_HINT | it | - | Le monete si ottengono nei distretti, dai segreti e dagli obiettivi.
[H] WORLD_CHAR_SUPERINTENDENT_TITLE | it | The Superintendent | L'Amministratore
[H] ACHIEVEMENTS_TITLE | it | Achievements | Obiettivi
