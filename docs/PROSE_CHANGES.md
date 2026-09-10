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
[H] diff_easy | pt_BR | - | Fácil
[H] diff_hard | pt_BR | - | Difícil
[H] graphics | pt_BR | - | Gráficos
[H] inventory | pt_BR | - | Inventário
[H] music_vol | pt_BR | - | Volume de música
[H] next_level | pt_BR | - | Próxima fase
[H] quests | pt_BR | - | Missões
[H] menu_title | pt_BR | THE LAST STREETLIGHT | O ÚLTIMO POSTE DE LUZ
[H] tutorial_done | pt_BR | - | Tutorial concluído. Boa sorte!
[H] tutorial_jump | pt_BR | - | ESPAÇO - pular
[H] victory | pt_BR | - | FASE CONCLUÍDA
[H] you_died | pt_BR | - | VOCÊ MORREU
[H] AD_REVIVE | pt_BR | - | Assistir anúncio para reviver
[H] AD_TITLE | pt_BR | - | Anúncio premiado
[H] AD_WATCHING | pt_BR | - | Anúncio... %d s
[H] DISTRICT_ALREADY_FULL | pt_BR | - | O distrito já está totalmente restaurado
[H] DISTRICT_STAGE_2 | pt_BR | - | %s: os postes estão acesos
[H] DIST_SUBSTATION | pt_BR | - | Subestação
[H] DIST_SUBURBS | pt_BR | - | Subúrbio
[H] DIST_WAREHOUSES | pt_BR | - | Armazéns
[H] HUD_AMMO | pt_BR | - | MUNIÇÃO
[H] HUD_NOISE | pt_BR | - | RUÍDO
[H] FINAL_NIGHT_BEGINS | pt_BR | - | A cidade está iluminada novamente. Mas algo está vindo.
[H] NEED_DISTRICT_FIRST | pt_BR | - | Você precisa restaurar este distrito primeiro: %s
[H] NEED_ITEM | pt_BR | - | Item necessário: %s
[H] CHAR_HOLSTER | pt_BR | Holster | Coldre
[H] enc_locked | pt_BR | Encounter the creature to unlock the entry. | Encontre a criatura para desbloquear o verbete.
[H] NG_PLUS_STAT_ENEMY_HP | pt_BR | - | PV dos inimigos: x%.2f
[H] Q_KILL_SNIPER_DESC | pt_BR | Snipers hold the rooftops. Clear four nests. | Franco-atiradores dominam os telhados. Limpe quatro ninhos.
[H] Q_KILL_SNIPER_TITLE | pt_BR | Sniper hunter | Caçador de franco-atiradores
[C] WORLD_NEWS_ARCHITECT_TEXT | pt_BR | - | O conselho nega financiar qualquer 'Projeto Arquiteto' para 'armazenar o que os postes viram'. A negação nomeia o projeto pelo título, que nenhum repórter havia usado. Os alimentadores de teste do programa, segundo registros, estavam conectados pela alimentação secundária do hospital e pela linha do parque.
[H] WORLD_NEWS_METERS_TEXT | pt_BR | Apartment meters on three residential streets record negative draw at night. City Power blames 'faulty drums'. A retired meterman: a backwards meter is not a faulty drum, it is a tap. Something downstream is paying current into the wires, not taking it. | Medidores de apartamentos em três ruas residenciais registram consumo negativo à noite. A companhia culpa 'tambores com defeito'. Um leiturista aposentado: um medidor que gira para trás não é um tambor com defeito, é uma derivação. Algo a jusante está injetando corrente nos fios, não retirando.
[H] WORLD_NEWS_ARCHITECT_TITLE | pt_BR | - | Conselho nega programa «Memória da Rede»
[H] WORLD_NEWS_ARENA_TITLE | pt_BR | - | Ponto de encontro na arena central
[H] WORLD_NEWS_METERS_TITLE | pt_BR | - | Medidores giram para trás em três ruas
[H] WORLD_NEWS_OUTAGES_TITLE | pt_BR | - | Cortes em rodízio começam esta noite
[H] WORLD_NEWS_TREES_TITLE | pt_BR | - | Parque fechado após queixas sobre «árvores»
[H] WORLD_CHAR_RADIOVOICE_TEXT | pt_BR | Go to the power station. The one who kept the light will meet you at the light. | Vá até a usina de energia. Quem guardou a luz vai encontrar você na luz.
[H] WORLD_RADIO_03_TEXT | pt_BR | You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back. | Você está restaurando o que eu estou desmontando, e ambos temos razão. Todo poste que você acende alimenta a cidade. Todo poste que eu levo embora mata de fome a coisa no centro. Ilumine os distritos. Vou encontrá-lo no último com tudo que guardei. Quarenta anos de luz, engenheiro. Você vai precisar de costas fortes.
[H] WORLD_DIARY_K3_TEXT | pt_BR | Decided. The drinker finds the grid through the lamps that can burn; a dismantled lamp is a door walled shut. Order 14,208: dismantle 219, suburbs, transformer to the center. I kept the light for forty years. Now I keep it backwards. Forgive me, streets. | Decidido. Quem bebe encontra a rede através dos postes que podem arder; um poste desmontado é uma porta emparedada. Ordem 14.208: desmontar os 219, subúrbio, transformador para o centro. Guardei a luz por quarenta anos. Agora a guardo ao contrário. Perdoem-me, ruas.
[H] WORLD_DIARY_K2_TITLE | pt_BR | Keeper's Diary — The Night It Went Out | Diário do Guardião — A noite em que a luz se apagou
[H] UPG_HINT | pt_BR | Coins come from districts, secrets and achievements. | As moedas vêm dos distritos, dos segredos e das conquistas.
[H] LORE_SUBSTATION_07_TEXT | pt_BR | - | Uma fita encontrada encaixada no rack de relés, rotulada com a letra do gravador: RELÉ — ENVIAR SE NÃO VOLTARMOS. A última chamada da equipe, reproduzida pelo próprio alto-falante do rack: "Terceiro turno para quem estiver ouvindo: o alimentador quatro não está com defeito, repito, não com defeito. O consumo é deliberado. Marat rastreou até um desvio de teste que não está em nenhum mapa. Estamos caminhando a linha até a subestação. Se não ligarmos de novo — a prova do banco permanece. Um poste. Lembrem-se disso." Eles não ligaram de novo. A fita é a chamada. Quem quer que a enfie no transmissor do rack toca a voz da equipe de volta ao ar que nunca voltaram para ouvir.
[H] LORE_SUBSTATION_08_TEXT | pt_BR | Taped to the sealed east gate, shot from the boneyard fence on the first night the yard floods held: the gate chained and padlocked from the inside, the road running east past the fence toward the power station stacks on the horizon — the last road in the city. In the frost at the fence corner, past the gate, a hand truck's wheel tracks and boot prints cut through the mesh from inside, heading east. The recorder's hand on the back: "Marat says the tap is fed from the east. We rest one night and walk it. The radio voice keeps saying it and it has never once said why — go to the power station. We are going. If the gate is sealed when you read this, we sealed it behind us." | Colada no portão leste selado, tirada da cerca do cemitério na primeira noite em que os refletores do pátio se sustentaram: o portão acorrentado e trancado a cadeado por dentro, a estrada seguindo ao leste além da cerca em direção às torres da usina no horizonte — a última estrada da cidade. Na geada no canto da cerca, além do portão, marcas de rodas de um carrinho de mão e pegadas de botas cortam a tela por dentro, indo para leste. A letra do narrador no verso: "Marat diz que o desvio é alimentado do leste. Descansamos uma noite e caminhamos até lá. A voz do rádio não para de dizer isso e nunca disse por quê — vá para a usina. Estamos indo. Se o portão está selado quando você ler isso, nós o selamos atrás de nós."
[H] LORE_SUBSTATION_01_TEXT | pt_BR | The gatehouse desk holds two logbooks, and only one of them was ever shown to anyone. The official one is the duty record the company filed: twelfth shift, door welded shut by the guard's own signed order, at 03:00 the door standing open by itself with nothing on the threshold, logged as a sensor trip because the pay mattered more than the truth. The duplicate, kept in the drawer under the weld receipt he paid for himself, says what he actually saw: "The dark on the threshold had learned the shape of a doorway. It stood in it the way a man stands in it. I did not log a man, because there was no man, and I did not log the dark, because the form has no line for the dark. The weld held. The door opened anyway. Whatever came through it, it came through the weld, not the door." | A mesa da guarita guarda dois livros de registro, e só um deles jamais foi mostrado a alguém. O oficial é o registro de plantão que a empresa arquivou: décimo segundo turno, porta soldada fechada por ordem assinada pelo próprio guarda, às 03h00 a porta aberta sozinha, sem nada na soleira, registrado como disparo de sensor porque o salário importava mais que a verdade. O duplicado, guardado na gaveta sob o recibo da solda que ele mesmo pagou, diz o que ele realmente viu: "A escuridão na soleira tinha aprendido a forma de um vão de porta. Ficava nele do jeito que um homem fica. Não registrei um homem, porque não havia homem, e não registrei a escuridão, porque o formulário não tem linha para a escuridão. A solda aguentou. A porta abriu assim mesmo. Seja lá o que passou por ela, passou pela solda, não pela porta."
[H] LORE_SUBSTATION_03_TEXT | pt_BR | "Crew log twenty-one, and this is the fence we walked two districts to reach. Marat's trace ends here — feeder four's draw walks out of the park line, crosses the whole west grid, and goes into this yard through a breaker that is not on any map we were ever issued. The transformer is warm. Say it plain, Marat. [Marat, faint: grids don't drink.] Grids don't drink, and the transformer is warm anyway, and that is the whole of it. We cache what we carried at the bunk and we go in at first dark. If anyone replays this after us — we walked the line in, we will walk it out. The bench proof stands. One streetlight." | "Registro da equipe vinte e um, e essa é a cerca pela qual caminhamos dois distritos até chegar. O rastro de Marat termina aqui — o consumo do alimentador quatro sai da linha do parque, atravessa toda a rede oeste, e entra neste pátio por um disjuntor que não está em nenhum mapa que já nos deram. O transformador está quente. Diga claramente, Marat. [Marat, fraco: redes não bebem.] Redes não bebem, e o transformador está quente mesmo assim, e é isso. Escondemos o que carregávamos no beliche e entramos ao anoitecer. Se alguém reproduzir isso depois de nós — caminhamos a linha para entrar, caminharemos para sair. A prova do banco permanece. Um poste."
[H] LORE_SUBSTATION_05_TEXT | pt_BR | Clipped to the vault breaker's own frame, where only the man with the key would ever read it: the wiring order that built what Marat traced. Twelve years before the blackout — breaker 9, wired off-plan, fed from the park line and the hospital sub-feed both, metering drums with the second coil wound to pay current back down the line. The day foreman's stamp across it: REFUSED. Below, the disposition that actually happened: "Night shift takes it." Below that, the clipping someone pasted here years later, the council denying the program by name in print — the denial that names what it denies. And last, the night foreman's hand: "It was never a fault. A fault does not need its own breaker." | Preso ao próprio quadro do disjuntor do cofre, onde só o homem com a chave jamais o leria: a ordem de fiação que construiu o que Marat rastreou. Doze anos antes do apagão — disjuntor 9, fiado fora do plano, alimentado tanto pela linha do parque quanto pelo alimentador secundário do hospital, tambores de medição com a segunda bobina enrolada para devolver corrente linha abaixo. O carimbo do capataz diurno atravessado nele: RECUSADO. Embaixo, a disposição que realmente aconteceu: "O turno da noite assume." Embaixo disso, o recorte que alguém colou ali anos depois, o conselho negando o programa pelo nome, impresso — a negação que nomeia o que nega. E por último, a letra do capataz noturno: "Nunca foi um defeito. Um defeito não precisa de seu próprio disjuntor."

[H] achievements | tr | Achievements | Başarımlar
[H] back_menu | tr | Main Menu | Ana Menü
[H] confirm_quit | tr | Quit for sure? | Çıkmak istediğine emin misin?
[H] empty_slot | tr | Empty | Boş
[H] loading | tr | Loading... | Yükleniyor...
[H] multiplayer | tr | Multiplayer | Çoklu Oyuncu
[H] music_vol | tr | Music Volume | Müzik Sesi
[H] next_level | tr | Next Level | Sonraki Bölüm
[H] paused | tr | Paused | Duraklatıldı
[H] quests | tr | Quests | Görevler
[H] quit | tr | Quit | Çıkış
[H] select_slot | tr | Select Slot | Yuva Seç
[H] shop | tr | Shop | Mağaza
[H] tip1 | tr | Keep the flashlight on - enemies fear light. | Feneri açık tut - düşmanlar ışıktan korkar.
[H] tip2 | tr | Reloading takes 1.5 seconds. | Şarj etmek 1,5 saniye sürer.
[H] tip3 | tr | Use cover when HP is low. | Canın azken sığınak kullan.
[H] tip4 | tr | Press M for the map. | Harita için M'ye bas.
[H] tutorial_done | tr | Tutorial complete. Good luck! | Eğitim tamamlandı. İyi şanslar!
[H] tutorial_interact | tr | E - interact | E - etkileşim
[H] tutorial_jump | tr | SPACE - jump | BOŞLUK - zıpla
[H] tutorial_shoot | tr | LEFT CLICK - shoot | SOL TIK - ateş
[H] victory | tr | LEVEL COMPLETE | BÖLÜM TAMAMLANDI
[H] weight | tr | Weight | Ağırlık
[H] AD_CLAIM | tr | Claim reward | Ödülü al
[H] AD_READY | tr | Reward ready | Ödül hazır
[H] AD_REVIVE | tr | Watch ad to revive | Yeniden dirilmek için reklam izle
[H] AD_TITLE | tr | Rewarded ad | Ödüllü reklam
[H] COINS_AMOUNT | tr | Coins: %d | Jeton: %d
[H] NOT_ENOUGH_COINS | tr | Not enough coins | Yeterli jeton yok
[H] UPG_HINT | tr | Coins come from districts, secrets and achievements. | Jetonlar bölgelerden, sırlardan ve başarımlardan gelir.
[H] REWARD_ACHIEVEMENT | tr | +%d coins for an achievement | Bir başarım için +%d jeton
[H] REWARD_DISTRICT | tr | +%d coins for a district | Bir bölge için +%d jeton
[H] REWARD_SECRET | tr | +%d coins for a secret | Bir sır için +%d jeton
[H] TOAST_COINS_GAINED | tr | +%s coins | +%s jeton
[H] ENEMY_ROTTER | tr | Rotter | Çürümüş
[H] MONSTER_BRUTE | tr | Brute | Zorba
[H] CHAR_HOLSTER | tr | Holster | Kılıf
[H] PHOTO_MODE | tr | Photo Mode | Fotoğraf modu
[H] DIST_RESIDENTIAL | tr | Residential | Konut Bölgesi
[H] SCR_ZHILYE_KVARTALY | tr | Residential | Konut Bölgesi
[H] WORLD_NEWS_METERS_TEXT | tr | Apartment meters on three residential streets record negative draw at night. City Power blames 'faulty drums'. A retired meterman: a backwards meter is not a faulty drum, it is a tap. Something downstream is paying current into the wires, not taking it. | Üç konut sokağındaki daire sayaçları geceleri negatif çekiş kaydediyor. Şirket 'arızalı tamburları' suçluyor. Emekli bir sayaç okuyucusu: geriye dönen bir sayaç arızalı bir tambur değil, bir kaçak bağlantıdır. Hattın aşağısında bir şey akımı kablolara veriyor, çekmiyor.
[H] WORLD_NEWS_ARCHITECT_TEXT | tr | The council denies funding any 'Project Architect' to 'store what the lamps have seen'. The denial names the project by title, which no reporter had used. The program's test feeders, records show, were wired through the hospital sub-feed and the park line. | Konsey, 'lambaların gördüklerini depolamak' için herhangi bir 'Proje Mimar'ı finanse ettiğini yalanlıyor. Yalanlama, hiçbir muhabirin kullanmadığı bir başlıkla projeyi adlandırıyor. Kayıtlara göre, programın test hatları hastanenin ikincil besleme hattı ve park hattı üzerinden bağlanmıştı.
[H] WORLD_NEWS_ARCHITECT_TITLE | tr | Council Denies 'Grid Memory' Program | Konsey «Şebeke Belleği» programını yalanlıyor
[H] WORLD_NEWS_ARENA_TITLE | tr | Collection Point at the Central Arena | Merkezi arenada toplanma noktası
[H] WORLD_NEWS_METERS_TITLE | tr | Meters Run Backwards on Three Streets | Üç sokakta sayaçlar geriye dönüyor
[H] WORLD_NEWS_OUTAGES_TITLE | tr | Rolling Outages Begin Tonight | Dönüşümlü kesintiler bu gece başlıyor
[H] WORLD_NEWS_TREES_TITLE | tr | Park Closed After 'Tree' Complaints | «Ağaç» şikayetleri sonrası park kapatıldı
[H] WORLD_CHAR_RADIOVOICE_TEXT | tr | Go to the power station. The one who kept the light will meet you at the light. | Elektrik santraline git. Işığı koruyan, seninle ışıkta buluşacak.
[H] WORLD_RADIO_03_TEXT | tr | You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back. | Sen benim söktüğümü onarıyorsun, ve ikimiz de haklıyız. Yaktığın her lamba şehri besliyor. Söküp götürdüğüm her lamba merkezdeki şeyi aç bırakıyor. Bölgeleri aydınlat. Sonuncusunda seninle, koruduğum her şeyle buluşacağım. Kırk yıllık ışık, mühendis. Sırtın sağlam olsun.
[H] WORLD_DIARY_M1_TEXT | tr | Three of them came to the pond again. The tall one that was the postman stands apart; he is ashamed. I put the bowl on the ice and I said their names out loud, all of them. They stood still when I said them. They remember. The light remembers too — that is why I keep my lamp. | Üçü yine gölete geldi. Postacı olan uzun boylu olan ayrı duruyor; utanıyor. Kaseyi buzun üzerine koydum ve isimlerini yüksek sesle söyledim, hepsini. Söylediğimde kıpırdamadan durdular. Hatırlıyorlar. Işık da hatırlıyor — bu yüzden lambamı yanık tutuyorum.
[C] WORLD_DIARY_K3_TEXT | tr | Decided. The drinker finds the grid through the lamps that can burn; a dismantled lamp is a door walled shut. Order 14,208: dismantle 219, suburbs, transformer to the center. I kept the light for forty years. Now I keep it backwards. Forgive me, streets. | Karar verildi. İçen, yanabilen lambalar aracılığıyla şebekeyi buluyor; sökülmüş bir lamba, duvarla örülmüş bir kapıdır. Emir 14.208: 219'u sök, banliyö, transformatörü merkeze götür. Işığı kırk yıl korudum. Şimdi onu tersinden koruyorum. Beni affedin, sokaklar.
[H] WORLD_CHAR_RECORDER_TITLE | tr | The Recorder | Kayıtçı
[H] LORE_WAREHOUSES_08_TEXT | tr | Taped inside the feeder-room door: the east gate at night, two figures with a hand truck, drums stacked, one figure turned back toward the camera — face lost in the fog, but the posture is a man counting a store he is leaving. On the back, the recorder's hand: "Came back the third night. Took drums twelve through eighteen and every fuse on the tagged rack. Left the cage alone — the key never did turn up, and we are not the ones who cut locks. If you are reading this after the lights come on: the sorter ran the whole time we worked. Check the belt. It counts everything that leaves this yard now, and it counted us out." | Besleme odası kapısının içine bantlanmış: geceleyin doğu kapısı, el arabalı iki figür, istiflenmiş tamburlar, bir figür kameraya dönmüş — yüzü siste kaybolmuş, ama duruşu ayrılmakta olduğu bir depoyu sayan bir adamınki. Arkasında, kaydedenin eliyle: "Üçüncü gece geri döndüm. On iki ile on sekiz arası tamburları ve etiketli raftaki her sigortayı aldım. Kafesi rahat bıraktım — anahtar hiç ortaya çıkmadı, ve biz kilit kesenlerden değiliz. Işıklar yandıktan sonra bunu okuyorsan: çalıştığımız sürece ayırıcı çalıştı. Bandı kontrol et. Artık bu avludan çıkan her şeyi sayıyor, ve bizi de sayarak dışarı çıkardı."
[C] LORE_WAREHOUSES_05_TEXT | tr | A laminated tag wired to the cage mesh, dated the year three streets' meters ran backwards. "REASON: negative draw at night. Drum tested twice — not faulty. Not a fault: a tap. Returns go to the cage, not to the grid." A supervisor's tick, nothing else. On the inside of the mesh, facing out, a pencil answer too small for the cage's owner to have read: "These were not defective. Defective meters stop. These ran backwards on purpose, like something downstream was being fed. The cage is where you put things that feed. That is all the cage was ever for." | Kafes teline bağlanmış laminasyonlu bir etiket, üç caddenin sayaçlarının geriye doğru işlediği yıla ait. "NEDEN: geceleri negatif çekiş. Tambur iki kez test edildi — arızalı değil. Arıza değil: kaçak bir bağlantı. İadeler kafese gider, şebekeye değil." Bir amirin onay işareti, başka bir şey yok. Telin iç tarafında, dışa dönük, kafesin sahibinin okuyamayacağı kadar küçük kurşun kalemle yazılmış bir cevap: "Bunlar arızalı değildi. Arızalı sayaçlar durur. Bunlar aşağı akışta bir şey besleniyormuş gibi kasıtlı olarak geri işledi. Kafes, besleyen şeylerin konulduğu yerdir. Kafesin var olma nedeni hep bu oldu."
[H] LORE_GAS_STATION_06_TEXT | tr | A station requisition pad, one page filled in by a hand that does not belong to a petrol station. "ITEM: canopy floodlight transformer, one. REASON: it will be needed at the center. AUTHORISED BY: —" and there the signature is just a small drawing of a streetlight inside a circle. Underneath, the manager's own biro: "Old man came at dusk, took the transformer, left this. Knew which bolt to loosen first. Said the ones he takes down are the ones they cannot drink. I didn't argue. Nobody's buying petrol anyway." | İstasyonun talep bloknotu, bir sayfa bir benzin istasyonuna ait olmayan bir elle doldurulmuş. "KALEM: kanopi projektör trafosu, bir adet. NEDEN: merkezde gerekecek. ONAYLAYAN: —" ve orada imza sadece daire içinde küçük bir sokak lambası çizimi. Altında, müdürün kendi tükenmez kalemiyle: "Yaşlı adam alacakaranlıkta geldi, trafoyu aldı, bunu bıraktı. Önce hangi cıvatayı gevşeteceğini biliyordu. Söktüklerinin, onların içemeyecekleri olduğunu söyledi. Tartışmadım. Zaten kimse benzin almıyor."
[H] LORE_GAS_STATION_03_TEXT | tr | "Fuel run. Two hundred litres for the park generator and whatever we can carry after. Marat won't let us start the pump motor — he says an engine and a man running sound the same to the one that hunts out here, and the engine can't stop when it wants to. So we siphon by hand, all night, and we walk the drums out. Slowly. If you're replaying this and you're in a hurry: don't be. Hurry is the noise it likes." | "Yakıt seferi. Park jeneratörü için iki yüz litre ve sonrasında taşıyabildiğimiz her şey. Marat pompa motorunu çalıştırmamıza izin vermiyor — bir motor ile koşan bir adamın sesinin, dışarıda avlanan şeye aynı geldiğini söylüyor, ve motor istediğinde duramıyor. O yüzden elle çekiyoruz, bütün gece, ve varilleri yürüyerek taşıyoruz. Yavaşça. Bunu dinliyorsan ve acelen varsa: olma. Acele, onun sevdiği ses."

[H] WORLD_NEWS_METERS_TEXT | ja | Apartment meters on three residential streets record negative draw at night. City Power blames 'faulty drums'. A retired meterman: a backwards meter is not a faulty drum, it is a tap. Something downstream is paying current into the wires, not taking it. | 三つの住宅街のアパートのメーターが夜間に負の消費を記録している。市電力公社は「故障したドラム」のせいだとしている。引退したメーター検針員は言う——逆回転するメーターは故障したドラムではない、盗電だ。下流の何かが電流を電線に流し込んでいるのであり、吸い取っているのではない。
[H] WORLD_NEWS_ARCHITECT_TEXT | ja | The council denies funding any 'Project Architect' to 'store what the lamps have seen'. The denial names the project by title, which no reporter had used. The program's test feeders, records show, were wired through the hospital sub-feed and the park line. | 議会は「街灯が見てきたものを保存する」ための「プロジェクト・アーキテクト」への資金提供を否定した。この否定声明はどの記者も使ったことのないタイトルでプロジェクトの名を挙げている。記録によれば、プログラムの試験系統は病院の二次フィーダーと公園の線を通して配線されていた。
[H] WORLD_RADIO_03_TEXT | ja | You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back. | お前は私が解体するものを修復している、そして我々は両方とも正しい。お前が灯すすべての灯りが街を養う。私が持ち出すすべての灯りが中心のあれを飢えさせる。地区を照らせ。私は最後の地区で、私が守ってきたすべてを持ってお前と会うだろう。四十年分の光だ、技師よ。万全の体で来い。
[H] WORLD_CHAR_RADIOVOICE_TEXT | ja | Go to the power station. The one who kept the light will meet you at the light. | 発電所へ行け。光を守ってきた者が、光の中でお前と会うだろう。
[H] WORLD_CHAR_SUPERINTENDENT_TITLE | ja | The Superintendent | 大家
[H] WORLD_DIARY_K3_TEXT | ja | Decided. The drinker finds the grid through the lamps that can burn; a dismantled lamp is a door walled shut. Order 14,208: dismantle 219, suburbs, transformer to the center. I kept the light for forty years. Now I keep it backwards. Forgive me, streets. | 決めた。飲む者は燃え続けられる街灯を通して送電網を見つける。解体された街灯は壁で塞がれた扉だ。命令14,208番：219番を撤去せよ、郊外、変圧器は中心部へ。私は四十年間光を守った。今は逆に守る。許してくれ、通りたちよ。
[H] WORLD_RADIO_02_TEXT | ja | Third shift to anyone: feeder four is not faulty, repeat, not faulty. The draw is deliberate. Marat traced it to a test tap that is not on any map. We are walking the line to the substation. If we do not call again — the bench proof stands. One streetlight. Remember that. | 三交代目から全員へ：四系統は故障していない、繰り返す、故障していない。消費は意図的なものだ。マラトはそれを、どの地図にもない試験用タップまで追跡した。俺たちは変電所まで線をたどっている。もう連絡がなければ——作業台の証明は有効だ。街灯一本。それを覚えておけ。
[H] RADIO_TRANSCRIPT_E1 | ja | ...this is the last broadcast of the city. The lamps are going out one by one. If you hear us - guard the light. | ...これは街からの最後の放送。街灯がひとつずつ消えていく。これが聞こえているなら――光を守って。
[H] DISTRICT_RESTORED_TOAST | ja | District saved: %s | 地区を復旧：%s
[H] CHAR_HOLSTER | ja | Holster | ホルスター
[H] ACH_03_NAME | ja | Beacon | 希望の灯
[H] ACH_11_NAME | ja | Economist | エコノミスト
[H] SKILL_INVENTORY_SPACE_NAME | ja | Pack Rat | ため込み屋
[H] ITEM_SERUM | ja | Dawn serum | 「夜明け」の血清
[H] SKILL_LOOT_LUCK_NAME | ja | Scavenger | スカベンジャー
[H] Q_KILL_SNIPER_DESC | ja | Snipers hold the rooftops. Clear four nests. | 狙撃手が屋上を占拠している。巣を4つ潰せ。
[H] Q_KILL_SNIPER_TITLE | ja | Sniper hunter | 狙撃手ハンター
[H] DIST_INDUSTRIAL | ja | Industrial | 工業地帯
[H] Q_RESTORE_DISTRICT2_DESC | ja | Bring light back to the industrial district - there is no way downtown without it | 工業地帯に光を取り戻せ。それなしでは中心部へ行けない。
[H] Q_REPAIR_DISTRICT1_DESC | ja | Find the distribution board and power up the district | 配電盤を見つけ、地区に電力を供給しろ
[H] shop_medkit | ja | Medkit | 救急キット
[H] Q_COLLECT_MEDKIT_DESC | ja | Gather 3 medkits. | 救急キットを3個集めろ。
[H] Q_COLLECT_MEDKIT_TITLE | ja | Medkits | 救急キット
[H] SCR_APTECHKA | ja | medkit | 救急キット
[H] WEAKSPOT_FIRE_IMMUNE | ja | Immune to fire | 炎耐性
[H] JOURNAL_RELATED | ja | Related: %s | 関連：%s
[H] confirm_quit | ja | Quit for sure? | 終了しますか？
[H] tutorial_done | ja | Tutorial complete. Good luck! | チュートリアル完了。頑張れ！

[C] DISTRICT_2_TOAST | ko | District 2 restored! The city breathes again. | 2구역 복구! 도시가 다시 숨쉽니다.
[H] WORLD_NEWS_METERS_TEXT | ko | Apartment meters on three residential streets record negative draw at night. City Power blames 'faulty drums'. A retired meterman: a backwards meter is not a faulty drum, it is a tap. Something downstream is paying current into the wires, not taking it. | 세 개의 주거 거리에 있는 아파트 계량기들이 밤마다 음의 소비량을 기록한다. 시 전력공사는 '고장 난 드럼' 탓이라고 한다. 은퇴한 계량기 검침원은 말한다: 거꾸로 도는 계량기는 고장 난 드럼이 아니라 무단 탭이다. 하류의 무언가가 전류를 전선에 공급하고 있는 것이지, 가져가는 것이 아니다.
[H] WORLD_NEWS_ARCHITECT_TEXT | ko | The council denies funding any 'Project Architect' to 'store what the lamps have seen'. The denial names the project by title, which no reporter had used. The program's test feeders, records show, were wired through the hospital sub-feed and the park line. | 의회는 '가로등이 본 것을 저장'하기 위한 어떤 '프로젝트 아키텍트'에도 자금을 지원한 적이 없다고 부인한다. 이 부인 성명은 어떤 기자도 사용한 적 없는 명칭으로 프로젝트를 언급하고 있다. 기록에 따르면 프로그램의 시험 배전선은 병원 보조 배전선과 공원 선로를 통해 배선되어 있었다.
[H] WORLD_RADIO_03_TEXT | ko | You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back. | 너는 내가 해체하는 것을 복구하고 있고, 우리 둘 다 옳다. 네가 켜는 모든 등불이 도시를 먹여 살린다. 내가 가지고 나가는 모든 등불은 중심부에 있는 그것을 굶주리게 한다. 구역들을 밝혀라. 내가 지켜온 모든 것을 가지고 마지막 구역에서 너를 만나겠다. 사십 년의 빛이다, 기술자여. 허리 튼튼히 하고 와라.
[H] WORLD_CHAR_SUPERINTENDENT_TITLE | ko | The Superintendent | 관리소장
[H] WORLD_FACTION_GRIDCREW_TITLE | ko | The Grid Crew | 전력망 작업조
[H] WORLD_CHAR_MARAT_TEXT | ko | The engineer who proved one streetlight can burn. The draw doesn't add up, he said. Something is pulling from the grid at night. | 가로등 하나가 계속 탈 수 있음을 증명한 기술자. 소비량이 안 맞는다고 그는 말했다. 밤마다 뭔가가 전력망에서 전기를 끌어내고 있다.
[H] VICTORY_DISTRICTS | ko | Districts restored | 복구된 구역
[H] msg_win | ko | All districts powered! | 모든 구역에 전력이 공급되었습니다!
[H] cb_deut | ko | Deuteranopia | 녹색맹
[H] cb_prot | ko | Protanopia | 적색맹
[H] cb_trit | ko | Tritanopia | 청색맹
[H] enc_title | ko | Creature Encyclopedia | 몬스터 도감
[H] CHAR_HOLSTER | ko | Holster | 홀스터
[H] ACH_03_NAME | ko | Beacon | 봉화
[H] SKILL_INVENTORY_SPACE_NAME | ko | Pack Rat | 수집꾼
[H] ITEM_SERUM | ko | Dawn serum | 혈청「새벽」
[H] ITEM_LOCKPICK | ko | Lockpick | 자물쇠 따개
[H] ITEM_MEDKIT | ko | Medkit | 구급상자
[H] RADIO_TRANSCRIPT_SOS | ko | ...SOS... we are trapped in the metro. They don't like light. Send batteries and medkits. SOS... | ...SOS... 우리는 지하철에 갇혔습니다. 그들은 빛을 싫어합니다. 배터리와 구급상자를 보내주세요. SOS...
[H] RADIO_TRANSCRIPT_E1 | ko | ...this is the last broadcast of the city. The lamps are going out one by one. If you hear us - guard the light. | ...이것은 도시의 마지막 방송입니다. 가로등이 하나씩 꺼지고 있습니다. 들리신다면 — 빛을 지켜주세요.
[H] DIST_INDUSTRIAL | ko | Industrial | 공업 지대
[H] Q_RESTORE_DISTRICT2_DESC | ko | Bring light back to the industrial district - there is no way downtown without it | 공업 지대에 빛을 되찾아라. 빛 없이는 시내로 갈 수 없다.
[H] SCR_PROMYSHLENNAYA_ZONA | ko | Industrial Zone | 공업 지대
[H] DIST_RESIDENTIAL | ko | Residential | 주택가
[H] Q_REPAIR_DISTRICT1_TITLE | ko | Restart the residential substation | 주택가 변전소를 재가동하라
[H] Q_FIND_ENGINEERS_DESC | ko | Track the engineering crew through the residential sector | 주택가를 지나는 기술진을 추적하라
[H] SCR_ZHILYE_KVARTALY | ko | Residential | 주택가
[H] DIST_WAREHOUSES | ko | Warehouses | 창고 단지
[H] LORE_SUBURBS_03_TEXT | ko | "RESIDENTS OF THE SUBURBAN DISTRICT: proceed in an orderly fashion to the collection point at the central arena. Bring documents and one bag per person. Do not remain outdoors after dark." The bottom edge is torn off — the date and the issuing office are missing. | "교외 주민 여러분: 중앙 아레나의 집결지로 질서 있게 이동하십시오. 서류와 1인당 가방 하나를 지참하십시오. 어두워진 뒤에는 실외에 머물지 마십시오." 하단이 찢겨 나가 날짜와 발행 기관이 없다.
