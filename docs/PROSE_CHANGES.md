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

[H] Q_KILL_TANK_DESC | zh | Armoured brutes block the way downtown. Three carcasses. | 装甲怪物挡住了通往市中心的路，留下三具尸体。
[H] MONSTER_BURNER | zh | Burner | 焚烧者
[H] CHAR_HOLSTER | zh | Holster | 枪套
[H] DISTRICT_RESTORED_TOAST | zh | District saved: %s | 区域已恢复：%s
[H] VICTORY_DISTRICTS | zh | Districts restored | 恢复的区域
[H] COINS_AMOUNT | zh | Coins: %d | 硬币：%d
[H] ITEM_COIN | zh | Coin | 硬币
[H] NOT_ENOUGH_COINS | zh | Not enough coins | 硬币不足
[H] REWARD_ACHIEVEMENT | zh | +%d coins for an achievement | 达成成就 +%d 硬币
[H] REWARD_DISTRICT | zh | +%d coins for a district | 恢复区域 +%d 硬币
[H] REWARD_SECRET | zh | +%d coins for a secret | 发现秘密 +%d 硬币
[H] TOAST_COINS_GAINED | zh | +%s coins | +%s 硬币
[H] UPG_HINT | zh | Coins come from districts, secrets and achievements. | 硬币来自区域、秘密与成就。
[H] BLUEPRINT_APPLIED | zh | Blueprint applied: upgrade unlocked | 已应用图纸：升级已解锁
[H] SKILL_RELOAD_SPEED_DESC | zh | +25% reload speed | 换弹速度+25%
[H] SKILL_RELOAD_SPEED_NAME | zh | Quick Reload | 快速换弹
[H] ACH_06_NAME | zh | Quiet as a Mouse | 悄无声息
[H] RADIO_TRANSCRIPT_E1 | zh | ...this is the last broadcast of the city. The lamps are going out one by one. If you hear us - guard the light. | ...这是这座城市最后的广播。路灯一盏盏熄灭。如果你能听到我们——请守护光明。
[H] JOURNAL_RELATED | zh | Related: %s | 相关：%s
[H] WORLD_RADIO_03_TEXT | zh | You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back. | 你在恢复我拆毁的东西，我们两个都没有错。你点亮的每一盏灯都在滋养这座城市。我搬走的每一盏灯都在饿死中心那个东西。照亮各个区吧。我会在最后一个区带着我所守护的一切与你相见。四十年的光明，工程师。带副好身板来。
[H] WORLD_NEWS_METERS_TEXT | zh | Apartment meters on three residential streets record negative draw at night. City Power blames 'faulty drums'. A retired meterman: a backwards meter is not a faulty drum, it is a tap. Something downstream is paying current into the wires, not taking it. | 三条住宅街道的公寓电表在夜间记录到负的用电量。市电力公司将其归咎于「有故障的鼓轮」。一位退休的抄表员说：倒转的电表不是鼓轮故障，那是一个分接头。下游有什么东西正在把电流注入电线，而不是从中取用。
[H] WORLD_NEWS_ARCHITECT_TEXT | zh | The council denies funding any 'Project Architect' to 'store what the lamps have seen'. The denial names the project by title, which no reporter had used. The program's test feeders, records show, were wired through the hospital sub-feed and the park line. | 议会否认为任何「储存路灯所见之物」的「建筑师计划」提供过资金。这份否认声明却用了一个从没有任何记者使用过的名称来指称该项目。据记录显示，该项目的测试馈线是通过医院的分支馈线和公园线路接入的。
[H] WORLD_CHAR_KEEPER_TEXT | zh | Forty years of work orders, every lamp logged by hand. Now he keeps the light backwards, and the grid waits for him at the center. | 四十年的工作单，每一盏灯都手写记录。现在他反过来守护光明，电网在中心等着他。
[H] WORLD_CHAR_MARAT_TEXT | zh | The engineer who proved one streetlight can burn. The draw doesn't add up, he said. Something is pulling from the grid at night. | 证明了一盏路灯能够持续燃烧的工程师。用电量对不上，他说。夜里有什么东西在从电网里抽取。
[H] WORLD_CHAR_RECORDER_TEXT | zh | Third shift, feed four. If anyone replays this — the lights can be brought back. We proved it on the bench. | 第三班，4号馈线。如果有人听到这段录音——灯光是可以恢复的。我们在工作台上证明过了。
[H] WORLD_CHAR_PETROV_TEXT | zh | The crew walked an hour in mud and it still found him at the pond edge. Took him toward the water without a sound. | 小队在泥地里走了一个小时，它还是在池塘边找到了他。悄无声息地把他拖向水边。
[H] WORLD_CHAR_SUPERINTENDENT_TEXT | zh | Meters 12, 24, 31 spin backwards at night. One of the two is lying, and the substation has never lied to me. | 12号、24号、31号电表夜里倒转。这两者之中有一个在撒谎，而变电站从没对我撒过谎。
[H] WORLD_CHAR_ARCHITECT_TEXT | zh | The project bears his name. The monsters were people; the grid was his instrument. | 这个项目以他的名字命名。那些怪物曾是人类；电网是他的工具。
[H] WORLD_FACTION_CITYPOWER_TEXT | zh | Planned rolling outage, Tuesday 22:00-23:00. It never came back on. | 计划轮流停电，周二22:00-23:00。再也没有恢复过。
[H] WORLD_FACTION_GRIDCREW_TEXT | zh | Grids don't drink, he said. The transformer was warm anyway. | 电网又不会喝水，他说。可变压器还是热的。
[H] WORLD_FACTION_KEEPERS_TEXT | zh | While one lantern burns, the city is alive. | 只要还有一盏灯笼燃烧，这座城市就还活着。
[H] WORLD_RADIO_01_TEXT | zh | ...if you can hear this, the grid can still be brought back. District by district, lamp by lamp. Do not go underground. Do not follow the arena signs. Go to the power station. The one who kept the light will meet you at the light. [three relay clicks] | ……如果你能听到这段广播，电网仍然可以恢复。一个区一个区地，一盏灯一盏灯地。不要去地下。不要跟着竞技场的路标走。去发电站。守护灯光的那个人会在灯光中与你相见。〔三声继电器咔哒声〕
[H] WORLD_RADIO_02_TITLE | zh | Broadcast 2 — Crew Relay, Recovered | 广播2 — 班组中继，已找回
[H] WORLD_RADIO_02_TEXT | zh | Third shift to anyone: feeder four is not faulty, repeat, not faulty. The draw is deliberate. Marat traced it to a test tap that is not on any map. We are walking the line to the substation. If we do not call again — the bench proof stands. One streetlight. Remember that. | 第三班向所有人通报：4号馈线没有故障，重复，没有故障。这是蓄意的抽取。马拉特把它追踪到一个不在任何地图上的测试分接头。我们正沿着线路走向变电站。如果我们不再联络——工作台上的证明依然成立。一盏路灯。记住这一点。
[H] WORLD_DIARY_K1_TEXT | zh | First shift today. Two hundred and nineteen lamps in the suburbs alone. The foreman says a lamp out is a street forgot. I intend to be remembered as the man who never let the street be forgot. Order 1 logged. | 今天是第一班。仅郊区就有两百一十九盏灯。工头说，熄灭的灯就是被遗忘的街道。我打算被人们记住，记住我是那个从不让街道被遗忘的人。第1号指令已记录。
[H] WORLD_DIARY_K2_TEXT | zh | The outage was scheduled for one hour. At 23:00 the feeders held. At 23:40 they were drinking. I have kept lamps forty years; I know the sound a transformer makes when it is full, and the grid sounds full tonight, and every lamp in the city is dark. Something else is lit. | 停电原定持续一小时。23:00时馈线还撑得住。23:40时它们就在被吸取了。我守护路灯四十年了；我知道变压器满载时发出的声音，而今晚电网听起来是满载的，可城里的每一盏灯都是黑的。有别的东西亮着。
[H] WORLD_DIARY_K3_TEXT | zh | Decided. The drinker finds the grid through the lamps that can burn; a dismantled lamp is a door walled shut. Order 14,208: dismantle 219, suburbs, transformer to the center. I kept the light for forty years. Now I keep it backwards. Forgive me, streets. | 决定了。那饮取者透过还能燃烧的灯找到电网；拆掉的灯就是一扇被砌死的门。第14208号指令：拆除219号，郊区，变压器送往中心。我守护这灯光四十年了。现在我反过来守护它。原谅我吧，街道们。
[H] WORLD_DIARY_M1_TEXT | zh | Three of them came to the pond again. The tall one that was the postman stands apart; he is ashamed. I put the bowl on the ice and I said their names out loud, all of them. They stood still when I said them. They remember. The light remembers too — that is why I keep my lamp. | 他们当中的三个又来到了池塘边。那个曾是邮差的高个子站得远远的；他感到羞愧。我把碗放在冰面上，大声念出他们所有人的名字。我念出名字时，他们都静止不动。他们记得。灯光也记得——这就是我一直点着灯的原因。
[H] WORLD_NEWS_OUTAGES_TEXT | zh | CITY POWER COMPANY announces planned rolling outages, Tuesday 22:00-23:00, suburban feeders first. 'A maintenance formality,' says the director. Asked about the night-shift request for feeder four, the director ended the call. | 市电力公司宣布计划轮流停电，周二22:00-23:00，先从郊区馈线开始。「只是例行维护，」局长说。当被问及夜班关于4号馈线的申请时，局长挂断了电话。
[H] WORLD_NEWS_ARENA_TEXT | zh | Residents are to proceed orderly to the central arena. Documents and one bag per person. Do not remain outdoors after dark. The Herald notes the order carries no signature and no office, and that the arena's own lights were seen off at press time. | 居民应有序前往中央竞技场。每人携带证件和一个包。天黑后不要停留在户外。《先驱报》指出该命令既无签名也无发布机构，而且截稿时竞技场自身的灯光也已熄灭。
[H] WORLD_NEWS_TREES_TEXT | zh | The central park closes until further notice following repeated complaints that the trees 'lean toward the lamps to listen'. The parks office: trees do not listen. Night gardeners, unnamed, add that the leaning started the week the new feeder hummed. | 由于反复收到关于树木「向路灯倾斜以聆听」的投诉，中央公园将暂时关闭，恕不另行通知。公园管理处表示：树木不会聆听。几位未透露姓名的夜间园丁补充说，这种倾斜是从新馈线开始嗡嗡作响的那一周开始的。

[H] ACH_06_NAME | zh_TW | Quiet as a Mouse | 悄無聲息
[H] BLUEPRINT_APPLIED | zh_TW | Blueprint applied: upgrade unlocked | 已套用圖紙：升級已解鎖
[H] CHAR_HOLSTER | zh_TW | Holster | 槍套
[H] COINS_AMOUNT | zh_TW | Coins: %d | 硬幣：%d
[H] DISTRICT_RESTORED_TOAST | zh_TW | District saved: %s | 區域已恢復：%s
[H] DIST_POWER | zh_TW | Power Station | 發電廠
[H] ENDING_SURVIVOR_DESC | zh_TW | Only the power station runs. The rest of the city stays dark, and you walk into the unknown. | 只有發電廠在運轉，城市其餘部分仍陷於黑暗，你獨自走向未知。
[H] ENDING_TRUTH_DESC | zh_TW | Documents, recordings and the bunker beneath the power station tell one story: the disaster was deliberate. | 文件、錄音以及發電廠下方的地堡都指向同一個真相：這場災難是蓄意為之。
[H] END_SURVIVOR_DESC | zh_TW | The station runs, but the rest of the city stays dark. You walk into the unknown. | 發電廠在運轉，但城市其餘部分仍陷於黑暗，你走向未知。
[H] FINAL_NIGHT_GOTO_STATION | zh_TW | Return to the power station | 返回發電廠
[H] ITEM_COIN | zh_TW | Coin | 硬幣
[H] MONSTER_BURNER | zh_TW | Burner | 焚燒者
[H] NOT_ENOUGH_COINS | zh_TW | Not enough coins | 硬幣不足
[H] Q_COLLECT_COMPONENTS_DESC | zh_TW | Transistors and gears for the workbench. Ten of them. | 給工作臺用的電晶體和齒輪，需要十個。
[H] Q_CRAFT_ITEMS_DESC | zh_TW | Craft 5 items at the workbench. | 在工作臺製作5件物品。
[H] Q_KILL_TANK_DESC | zh_TW | Armoured brutes block the way downtown. Three carcasses. | 裝甲怪物擋住了通往市中心的路，留下三具屍體。
[H] RADIO_TRANSCRIPT_E1 | zh_TW | ...this is the last broadcast of the city. The lamps are going out one by one. If you hear us - guard the light. | ...這是這座城市最後的廣播。路燈一盞盞熄滅。如果你能聽到我們——請守護光明。
[H] REWARD_ACHIEVEMENT | zh_TW | +%d coins for an achievement | 達成成就 +%d 硬幣
[H] REWARD_DISTRICT | zh_TW | +%d coins for a district | 恢復區域 +%d 硬幣
[H] REWARD_SECRET | zh_TW | +%d coins for a secret | 發現秘密 +%d 硬幣
[H] SCR_ELEKTROSTANCIYA | zh_TW | Power Station | 發電廠
[H] SCR_FINALNYY_PROTIVNIK_VSTRECHAETSYA_V_CENTRE_EL | zh_TW | The final adversary. Waits at the heart of the power station on the last night. | 最終的敵人。在最後一夜守候在發電廠的核心。
[H] SCR_SIGNAL_BEDSTVIYA_S_KRYSHI | zh_TW | Distress signal from the rooftop | 來自屋頂的求救訊號
[H] SCR_VYHOD | zh_TW | QUIT | 離開
[H] UPG_HINT | zh_TW | Coins come from districts, secrets and achievements. | 硬幣來自區域、秘密與成就。
[H] VICTORY_DISTRICTS | zh_TW | Districts restored | 恢復的區域
[H] VICTORY_SECRETS | zh_TW | Secrets found | 找到的秘密
[H] confirm_quit | zh_TW | Quit for sure? | 確定離開？
[H] menu_quit | zh_TW | Quit | 離開
[H] tip1 | zh_TW | Keep the flashlight on - enemies fear light. | 保持手電筒開啟——敵人畏懼光芒。
[H] tutorial_done | zh_TW | Tutorial complete. Good luck! | 教學完成。祝你好運！
[H] SKILL_RELOAD_SPEED_NAME | zh_TW | Quick Reload | 快速換彈
[H] SKILL_RELOAD_SPEED_DESC | zh_TW | +25% reload speed | 換彈速度+25%
[H] LORE_SUBURBS_07_TEXT | zh_TW | "Last entry, I think. We found where the draw comes from and Marat won't say it out loud, so I will: the transformer is warm. Suburb feed has been dark for two weeks and the transformer is WARM. We're walking out to the substation. If anyone replays this — the lights can be brought back. We proved it on the bench. One streetlight. Remember that." | 「大概是最後一條記錄了。我們找到了耗電的來源,馬拉特不願意說出口,那就我來說:變壓器是熱的。郊區饋線已經黑了兩週,而變壓器是熱的。我們正步行前往變電站。如果有人聽到這段錄音——燈光是可以恢復的。我們在工作臺上證明過了。一盞路燈。記住這一點。」
[H] LORE_PARK_07_TITLE | zh_TW | Radio: 'Go to the Power Station' | 廣播:「去發電廠」
[H] LORE_PARK_07_TEXT | zh_TW | A captured broadcast, looped on the shed's shortwave: a calm voice under static, neither young nor old: "...the grid can still be brought back. District by district, lamp by lamp. Go to the power station. The one who kept the light will meet you at the light." The loop ends with three soft clicks, like a streetlight relay. The voice belongs to whoever pressed the seal. | 小屋短波電台裡循環播放的一段錄音廣播:靜電噪音下一個平靜的聲音,不年輕也不蒼老:「……電網仍然可以恢復。一個區一個區地,一盞燈一盞燈地。去發電廠。守護燈光的那個人會在燈光中與你相見。」循環結尾是三聲輕柔的咔噠聲,像路燈的繼電器。這聲音屬於按下封印的那個人。
[H] WORLD_CHAR_KEEPER_TEXT | zh_TW | Forty years of work orders, every lamp logged by hand. Now he keeps the light backwards, and the grid waits for him at the center. | 四十年的工作單，每一盞燈都手寫記錄。現在他反過來守護光明，電網在中心等著他。
[H] WORLD_CHAR_MARAT_TEXT | zh_TW | The engineer who proved one streetlight can burn. The draw doesn't add up, he said. Something is pulling from the grid at night. | 證明了一盞路燈能夠持續燃燒的工程師。用電量對不上，他說。夜裡有什麼東西在從電網裡抽取。
[H] WORLD_CHAR_RECORDER_TEXT | zh_TW | Third shift, feed four. If anyone replays this — the lights can be brought back. We proved it on the bench. | 第三班，4號饋線。如果有人聽到這段錄音——燈光是可以恢復的。我們在工作臺上證明過了。
[H] WORLD_CHAR_PETROV_TEXT | zh_TW | The crew walked an hour in mud and it still found him at the pond edge. Took him toward the water without a sound. | 小隊在泥地裡走了一個小時，它還是在池塘邊找到了他。悄無聲息地把他拖向水邊。
[H] WORLD_CHAR_ANYA_TEXT | zh_TW | At the corner window with the flashlight. The watch roster's last uncrossed name. | 在轉角窗邊拿著手電筒。守夜名單上最後一個沒被劃掉的名字。
[H] WORLD_CHAR_SUPERINTENDENT_TEXT | zh_TW | Meters 12, 24, 31 spin backwards at night. One of the two is lying, and the substation has never lied to me. | 12號、24號、31號電錶夜裡倒轉。這兩者之中有一個在撒謊，而變電站從沒對我撒過謊。
[H] WORLD_CHAR_RADIOVOICE_TEXT | zh_TW | Go to the power station. The one who kept the light will meet you at the light. | 去發電廠。守護燈光的那個人會在燈光中與你相見。
[H] WORLD_CHAR_ARCHITECT_TEXT | zh_TW | The project bears his name. The monsters were people; the grid was his instrument. | 這個專案以他的名字命名。那些怪物曾是人類；電網是他的工具。
[H] WORLD_FACTION_CITYPOWER_TEXT | zh_TW | Planned rolling outage, Tuesday 22:00-23:00. It never came back on. | 計畫輪流停電，週二22:00-23:00。再也沒有恢復過。
[H] WORLD_FACTION_GRIDCREW_TEXT | zh_TW | Grids don't drink, he said. The transformer was warm anyway. | 電網又不會喝水，他說。可變壓器還是熱的。
[H] WORLD_FACTION_KEEPERS_TEXT | zh_TW | While one lantern burns, the city is alive. | 只要還有一盞燈籠燃燒，這座城市就還活著。
[H] JOURNAL_RELATED | zh_TW | Related: %s | 相關：%s
[H] WORLD_RADIO_01_TEXT | zh_TW | ...if you can hear this, the grid can still be brought back. District by district, lamp by lamp. Do not go underground. Do not follow the arena signs. Go to the power station. The one who kept the light will meet you at the light. [three relay clicks] | ……如果你能聽到這段廣播，電網仍然可以恢復。一個區一個區地，一盞燈一盞燈地。不要去地下。不要跟著競技場的路標走。去發電廠。守護燈光的那個人會在燈光中與你相見。〔三聲繼電器喀噠聲〕
[H] WORLD_RADIO_02_TITLE | zh_TW | Broadcast 2 — Crew Relay, Recovered | 廣播2 — 班組中繼，已找回
[H] WORLD_RADIO_02_TEXT | zh_TW | Third shift to anyone: feeder four is not faulty, repeat, not faulty. The draw is deliberate. Marat traced it to a test tap that is not on any map. We are walking the line to the substation. If we do not call again — the bench proof stands. One streetlight. Remember that. | 第三班向所有人通報：4號饋線沒有故障，重複，沒有故障。這是蓄意的抽取。馬拉特把它追蹤到一個不在任何地圖上的測試分接頭。我們正沿著線路走向變電站。如果我們不再聯絡——工作臺上的證明依然成立。一盞路燈。記住這一點。
[H] WORLD_RADIO_03_TEXT | zh_TW | You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back. | 你在恢復我拆毀的東西，我們兩個都沒有錯。你點亮的每一盞燈都在滋養這座城市。我搬走的每一盞燈都在餓死中心那個東西。照亮各個區吧。我會在最後一個區帶著我所守護的一切與你相見。四十年的光明，工程師。帶副好身板來。
[H] WORLD_DIARY_K1_TEXT | zh_TW | First shift today. Two hundred and nineteen lamps in the suburbs alone. The foreman says a lamp out is a street forgot. I intend to be remembered as the man who never let the street be forgot. Order 1 logged. | 今天是第一班。僅郊區就有兩百一十九盞燈。工頭說，熄滅的燈就是被遺忘的街道。我打算被人們記住，記住我是那個從不讓街道被遺忘的人。第1號指令已記錄。
[H] WORLD_DIARY_K2_TEXT | zh_TW | The outage was scheduled for one hour. At 23:00 the feeders held. At 23:40 they were drinking. I have kept lamps forty years; I know the sound a transformer makes when it is full, and the grid sounds full tonight, and every lamp in the city is dark. Something else is lit. | 停電原定持續一小時。23:00時饋線還撐得住。23:40時它們就在被吸取了。我守護路燈四十年了；我知道變壓器滿載時發出的聲音，而今晚電網聽起來是滿載的，可城裡的每一盞燈都是黑的。有別的東西亮著。
[H] WORLD_DIARY_K3_TEXT | zh_TW | Decided. The drinker finds the grid through the lamps that can burn; a dismantled lamp is a door walled shut. Order 14,208: dismantle 219, suburbs, transformer to the center. I kept the light for forty years. Now I keep it backwards. Forgive me, streets. | 決定了。那飲取者透過還能燃燒的燈找到電網；拆掉的燈就是一扇被砌死的門。第14208號指令：拆除219號，郊區，變壓器送往中心。我守護這燈光四十年了。現在我反過來守護它。原諒我吧，街道們。
[H] WORLD_DIARY_M1_TEXT | zh_TW | Three of them came to the pond again. The tall one that was the postman stands apart; he is ashamed. I put the bowl on the ice and I said their names out loud, all of them. They stood still when I said them. They remember. The light remembers too — that is why I keep my lamp. | 他們當中的三個又來到了池塘邊。那個曾是郵差的高個子站得遠遠的；他感到羞愧。我把碗放在冰面上，大聲念出他們所有人的名字。我念出名字時，他們都靜止不動。他們記得。燈光也記得——這就是我一直點著燈的原因。
[H] WORLD_NEWS_OUTAGES_TEXT | zh_TW | CITY POWER COMPANY announces planned rolling outages, Tuesday 22:00-23:00, suburban feeders first. 'A maintenance formality,' says the director. Asked about the night-shift request for feeder four, the director ended the call. | 市電力公司宣布計畫輪流停電，週二22:00-23:00，先從郊區饋線開始。「只是例行維護，」局長說。當被問及夜班關於4號饋線的申請時，局長掛斷了電話。
[H] WORLD_NEWS_ARENA_TEXT | zh_TW | Residents are to proceed orderly to the central arena. Documents and one bag per person. Do not remain outdoors after dark. The Herald notes the order carries no signature and no office, and that the arena's own lights were seen off at press time. | 居民應有序前往中央競技場。每人攜帶證件和一個包。天黑後不要停留在戶外。《先驅報》指出該命令既無簽名也無發布機構，而且截稿時競技場自身的燈光也已熄滅。
[H] WORLD_NEWS_TREES_TEXT | zh_TW | The central park closes until further notice following repeated complaints that the trees 'lean toward the lamps to listen'. The parks office: trees do not listen. Night gardeners, unnamed, add that the leaning started the week the new feeder hummed. | 由於反覆收到關於樹木「向路燈傾斜以聆聽」的投訴，中央公園將暫時關閉，恕不另行通知。公園管理處表示：樹木不會聆聽。幾位未透露姓名的夜間園丁補充說，這種傾斜是從新饋線開始嗡嗡作響的那一週開始的。
[H] WORLD_NEWS_ARCHITECT_TEXT | zh_TW | The council denies funding any 'Project Architect' to 'store what the lamps have seen'. The denial names the project by title, which no reporter had used. The program's test feeders, records show, were wired through the hospital sub-feed and the park line. | 議會否認為任何「儲存路燈所見之物」的「建築師計畫」提供過資金。這份否認聲明卻用了一個從沒有任何記者使用過的名稱來指稱該專案。據記錄顯示，該專案的測試饋線是通過醫院的分支饋線和公園線路接入的。
[H] WORLD_NEWS_METERS_TEXT | zh_TW | Apartment meters on three residential streets record negative draw at night. City Power blames 'faulty drums'. A retired meterman: a backwards meter is not a faulty drum, it is a tap. Something downstream is paying current into the wires, not taking it. | 三條住宅街道的公寓電錶在夜間記錄到負的用電量。市電力公司將其歸咎於「有故障的鼓輪」。一位退休的抄錶員說：倒轉的電錶不是鼓輪故障，那是一個分接頭。下游有什麼東西正在把電流注入電線，而不是從中取用。
[H] LORE_GAS_STATION_07_TEXT | zh_TW | Recorded off a car radio with the door open, battery nearly flat. The same loop the park shed carries, but thinner out here, breaking up between words: "...district by district... lamp by lamp... go to the power station..." then a wash of static, then the three soft clicks like a relay closing. Whoever taped it added their own voice at the end, very tired: "It's been saying that for a month. Somebody should go." | 從車門敞開的收音機上錄下的,電池快沒電了。和公園小屋播放的是同一段循環,但在這裡更微弱,詞與詞之間斷斷續續:「……一個區一個區地……一盞燈一盞燈地……去發電廠……」然後是一陣靜電噪音,然後是像繼電器閉合般的三聲輕柔喀噠聲。錄下這段的人在最後加上了自己的聲音,非常疲憊:「它這麼說了一個月了。該有人去了。」
[H] LORE_POLICE_07_TEXT | zh_TW | Recorded off the dispatch set with the squelch rolled all the way open. Same loop the park shed carries, but it comes in on the station's own channel now, between bursts of the dead siren tail: "...district by district... lamp by lamp... go to the power station..." then three soft clicks like a relay, then a sergeant, very tired: "It's been on our frequency since the diesel died. We stopped answering. It does not need us to answer." | 從調度台錄下的,靜噪完全開著。和公園棚屋裡那段一樣的循環,只是現在出現在警局自己的頻道上,夾在死掉的警笛尾音的爆音之間:「……一個區一個區……一盞燈一盞燈……去發電廠……」接著是三聲像繼電器一樣的輕響,然後是一個非常疲憊的警長:「自從柴油機死掉以後它就一直在我們的頻率上。我們不再應答了。它不需要我們應答。」
[H] LORE_WAREHOUSES_03_TEXT | zh_TW | "Stores check, second night, and Marat's count holds: drums twelve through eighteen are feeder-grade, same lot the suburbs bench ran on. Fuses are racked by the yard flood box, tagged. Solid state is another story — nothing in the open stores; everything with a transistor in it is behind the quarantine mesh, and the cage key is not on the board. Recorder's note: we do not cut that lock. Whatever they quarantined in here, it was quarantined on purpose, and I would like the person who kept ordering it to explain the label first. Second thing: the sorter ran at two this morning. Nobody is on the sorter. Logging it and leaving." | 「庫存清點,第二晚,馬拉特的數目對得上:十二號到十八號的捲筒是饋線級的,和郊區那個工作臺用的是同一批貨。保險絲掛在院子探照燈配電箱旁的架子上,貼了標籤。固態元件是另一碼事——開放倉庫裡什麼都沒有;凡是帶電晶體的都在隔離網後面,籠子的鑰匙不在掛板上。錄音者附言:我們不剪那把鎖。不管他們在這兒隔離的是什麼,那都是故意的,我希望一直下訂單的那個人先解釋一下標籤。第二件事:分揀機今早兩點自己運轉了。分揀機上沒人。記錄完就走。」
[H] LORE_INDUSTRIAL_02_TEXT | zh_TW | A plant-safety photograph, timestamped 23:15 — the exact minute the shift log stopped being a log and started being testimony. Workshop B lit by a single overhead that should not have been lit: every feeder in the city was dark by then, and this one lamp is burning at full warm throw over a bench where nothing is plugged in. In the foreground, the peening press mid-stroke. No operator's hands. The print is blurry the way photographs are when the photographer's hands are shaking, and on the back, one line: "This is the third frame like this. I did not take the first two. The camera was in the locker." | 工廠安全照片,時間戳23:15——班次日誌不再是日誌、開始變成證詞的那一分鐘。B車間被一盞本不該亮著的頂燈照亮:那時全城的每條饋線都已經斷電,而這盞燈卻在一張什麼都沒插的工作臺上方全力散發著暖光。前景是噴丸壓機停在衝程中途。沒有操作員的手。照片模糊得像攝影師的手在發抖時拍的那樣,背面一行字:「這是第三張這樣的照片了。前兩張不是我拍的。相機當時在儲物櫃裡。」
[H] LORE_INDUSTRIAL_03_TEXT | zh_TW | "Stores check, the factory this time. Marat's count again: fuses by the crate in the yard bins, transistor stock behind the switchgear door — that one's locked and the key will be in the foreman's office, same as the depot, same as everywhere, they all lock the solid state and lose the key at a desk. Gears and billet stock enough to roof a house. But listen — the line in Workshop B is running. Slow, no load on it, and it is sorting lamp fittings. Brass shells, the kind we found on the suburbs bench. It sorts them onto a pallet with no order number and no destination street, and when I put my hand on the conveyor bed it is warm like the transformer was warm. We are taking what we came for and we are not standing between that line and its pallet. Recorder's note: the pallet was fuller on our way out than our way in." | 「庫存清點,這次是工廠。又是馬拉特的數目:保險絲一箱箱堆在院子的箱櫃裡,電晶體庫存在開關設備門後面——那扇門鎖著,鑰匙會在工頭辦公室,和倉庫一樣,到處都一樣,他們都把固態元件鎖起來,然後把鑰匙丟在某張辦公桌上。齒輪和坯料的庫存夠蓋一棟房子的屋頂了。但聽著——B車間的那條生產線在運轉。慢速,沒有負載,而且它在分揀燈具配件。黃銅外殼,就是我們在郊區工作臺上找到的那種。它把它們分揀到一個沒有訂單編號、沒有目的地街道的托盤上,當我把手放在傳送帶上時,它像變壓器曾經那樣溫熱。我們拿走該拿的東西,不會站在那條生產線和它的托盤之間。錄音者附言:出去的時候托盤比進來時更滿了。」
[H] LORE_INDUSTRIAL_07_TEXT | zh_TW | A cassette in the locker-room player, labelled ROLL CALL in grease pencil. The shift boss runs the 22:00 roll the way he has run it for thirty years — Roma. The Zimin twins. Katya's father, who fixed the paint line. He reads each name and pauses for the answer, and the answers come, but they come from the floor, through the wall, spaced like machine cycles — a press-stroke for a yes. He keeps going. He has to reach the end of the list before he can clock anyone out, and no one has ever reached the end. Then, quieter: "The old woman at the pond says you should say their names out loud, and they stand still. She is right. They stand still. Roma stands still. I say his name every night at this bench and for as long as I say it, the press he worked does not cycle. The line took Petrov the same way it took them, and someone is saying his name by the water right now. That is all any of us are now — a name being said by somebody who will not stop." | 更衣室播放器裡的一盤磁帶,用蠟筆標著「點名」。班長按他三十年來一直用的方式點22:00的名——羅馬。齊明家那對雙胞胎。修油漆線的卡佳的父親。他念出每個名字然後停頓等回答,回答確實來了,但那是從地板下面來的,穿過牆壁,間隔得像機器的循環週期——一次壓機衝程代表一聲「到」。他繼續念下去。他必須念到名單的末尾才能給任何人打退勤卡,而從來沒有人念到過末尾。接著,聲音更輕了:「池塘邊那個老太太說你應該大聲說出他們的名字,他們就會站定不動。她是對的。他們站定不動。羅馬站定不動。我每天晚上在這張工作臺前念他的名字,只要我在念,他操作過的那台壓機就不會循環運轉。那條生產線帶走彼得羅夫的方式和帶走他們一模一樣,此刻正有人在水邊念著他的名字。這就是我們現在所剩下的一切了——一個被某個不會停下來的人念著的名字。」
[H] LORE_INDUSTRIAL_08_TEXT | zh_TW | Taped to the south gate itself, shot from the catwalk on the first night the plant's own floods held: the gate standing open, the road running south past the works fence toward the substation lights on the far horizon — the center of the web, finally close enough to see from here. The recorder's hand on the back: "Crew log, last entry from this plant. We walked the line in, we will walk it out. The radio voice keeps saying it and it has never once said why — go to the power station, the one who kept the light will meet you at the light. Marat says the voice is a crew we never met. I say the voice knows the lamplighter's order numbers and I heard the man himself count 219 of them at this dock. Whoever meets whoever at that light — the road starts here, and past the substation gate nobody walks back out to tell it. Leave the gate open behind you. It is the last one that swings both ways." | 貼在南門本身上,是工廠自己的探照燈第一次撐住的那個夜晚從天橋上拍的:大門敞開著,道路沿著廠區圍欄向南延伸,通向遠方地平線上變電站的燈光——蛛網的中心,終於近得能從這裡看見了。背面是敘述者的字跡:「班組日誌,這座工廠的最後一條記錄。我們是走著這條線進來的,也會走著出去。無線電裡的聲音一直在說這句話,卻從沒說過為什麼——去發電廠,守燈人會在燈光那兒等你們。馬拉特說那聲音是我們從沒見過的一個班組。我說那聲音知道點燈人的訂單號碼,而且我親耳聽那個人自己在這個碼頭數過219個。不管是誰在那盞燈那兒見到誰——路從這裡開始,而過了變電站的大門,沒有人能走回來講述。把門開著留在你們身後。這是最後一扇兩面都能開的門。」
[H] LORE_SUBSTATION_03_TEXT | zh_TW | "Crew log twenty-one, and this is the fence we walked two districts to reach. Marat's trace ends here — feeder four's draw walks out of the park line, crosses the whole west grid, and goes into this yard through a breaker that is not on any map we were ever issued. The transformer is warm. Say it plain, Marat. [Marat, faint: grids don't drink.] Grids don't drink, and the transformer is warm anyway, and that is the whole of it. We cache what we carried at the bunk and we go in at first dark. If anyone replays this after us — we walked the line in, we will walk it out. The bench proof stands. One streetlight." | 「班組日誌二十一,這就是我們走了兩個區才到達的圍欄。馬拉特追蹤的痕跡到這裡就斷了——四號饋線的用電量從公園那條線出來,穿過整個西部電網,通過一個斷路器進入這個院子,而這個斷路器不在我們領到過的任何地圖上。變壓器是熱的。說明白點,馬拉特。〔馬拉特,聲音很輕:電網不會喝東西。〕電網不會喝東西,可變壓器還是熱的,事情就是這樣。我們把隨身帶的東西藏在鋪位那兒,天一黑就進去。如果有人在我們之後重放這段——我們是走著這條線進來的,也會走著出去。工作臺上的證據仍然成立。一盞路燈。」
[H] LORE_SUBSTATION_07_TEXT | zh_TW | A tape found slotted in the relay rack, labelled in the recorder's hand: RELAY — SEND IF WE DON'T COME BACK. The crew's last call, played back off the rack's own speaker: "Third shift to anyone: feeder four is not faulty, repeat, not faulty. The draw is deliberate. Marat traced it to a test tap that is not on any map. We are walking the line to the substation. If we do not call again — the bench proof stands. One streetlight. Remember that." They did not call again. The tape is the call. Whoever threads it into the rack's sender plays the crew's voice back onto the air they never came back to hear. | 在繼電器架上發現的一盤插好的磁帶,用敘述者的字跡標著:繼電——若我們沒回來就發送。班組的最後一次通話,從機架自己的擴音器裡播放出來:「三班向任何聽到的人:四號饋線沒有故障,重複,沒有故障。這個用電量是有意為之的。馬拉特把它一路追到了一個不在任何地圖上的測試分接頭。我們正沿著這條線走向變電站。如果我們不再聯絡——工作臺上的證據仍然成立。一盞路燈。記住這句話。」他們再也沒有聯絡。這盤磁帶就是那次通話。不管是誰把它穿進機架的發射機,都是在把班組的聲音重新播放到他們再也沒能回來聽的電波裡。
[H] LORE_SUBSTATION_08_TEXT | zh_TW | Taped to the sealed east gate, shot from the boneyard fence on the first night the yard floods held: the gate chained and padlocked from the inside, the road running east past the fence toward the power station stacks on the horizon — the last road in the city. In the frost at the fence corner, past the gate, a hand truck's wheel tracks and boot prints cut through the mesh from inside, heading east. The recorder's hand on the back: "Marat says the tap is fed from the east. We rest one night and walk it. The radio voice keeps saying it and it has never once said why — go to the power station. We are going. If the gate is sealed when you read this, we sealed it behind us." | 貼在封鎖的東門上,是院子探照燈第一次撐住的那個夜晚從廢料場圍欄那兒拍的:大門從裡面上了鏈條和掛鎖,道路沿著圍欄向東延伸,通向地平線上發電廠的煙囪群——這座城市裡最後一條路。圍欄角落的霜裡,過了大門,有手推車的輪印和靴印從裡面穿破網眼,朝東而去。背面是敘述者的字跡:「馬拉特說那個分接頭是從東邊供電的。我們歇一晚,然後走過去。無線電裡的聲音一直在說這句話,卻從沒說過為什麼——去發電廠。我們去了。如果你讀到這個的時候大門是封著的,那是我們從身後把它封上的。」
[H] LORE_POWER_STATION_01_TEXT | zh_TW | The crew's hand truck stands inside the station gate, unloaded and chalked. The drums are gone — carried in. The chalk on its bed is the recorder's hand, and it is a manifest, not a message: fuses, rack wire, the bench lamp from the suburbs wrapped in a curtain. Below the manifest, one line for whoever walks the line next: "Marat counted the draw all the way here. It ends at this gate. Whatever the tap was feeding, it is fed from inside these walls now, and we are going in to meter it. The truck stays — the way back is downhill and we will not need it." | 班組的手推車停在電站大門內側,貨已卸空,上面用粉筆寫了字。捲筒不見了——都搬進去了。車板上的粉筆字是敘述者的筆跡,那是一份清單,不是留言:保險絲、機架線材,還有用窗簾裹著的郊區那盞工作臺燈。清單下面,給下一個走這條線的人留了一行字:「馬拉特把這用電量一路數到了這裡。它就在這道門結束。不管那個分接頭當初在供給什麼,現在它是從這些牆裡面供給的,我們要進去把它測量清楚。手推車留下——回去的路是下坡,用不上它了。」
[H] LORE_POWER_STATION_02_TEXT | zh_TW | A long-exposure photograph of the turbine hall, taken from the gallery on a night the station was fully dark. The three generators stand in a row like sleeping animals, and above them the dark is not empty — the exposure caught it moving, a slow churn in the black over the middle machine, the way heat moves over a road that is not hot. No flash was used. Nothing in the hall was lit. On the back, in a hand that does not appear anywhere else in the station: "They are not running. Do not let them being still fool you." | 一張渦輪機大廳的長曝光照片,是發電廠徹底陷入黑暗的一個夜晚從走廊拍的。三台發電機像睡著的動物一樣排成一排,而它們上方的黑暗並不是空的——曝光捕捉到了它在移動,中間那台機器上方的黑色裡有一種緩慢的攪動,就像熱氣在一條並不炙熱的路面上浮動的樣子。沒有用閃光燈。大廳裡沒有任何東西是亮著的。背面是一手在電站任何地方都沒再出現過的字跡:「它們沒在運轉。別被它們的靜止騙了。」
[H] LORE_POWER_STATION_03_TITLE | zh_TW | Signal Loft — The Keeper Answers | 訊號閣樓——守燈人回應了
[H] LORE_POWER_STATION_03_TEXT | zh_TW | A tape from the signal loft's big receiver, labelled in the night operator's hand: ANSWER — SAME VOICE, NEW WORDS. The calm voice that spent a year looping the call is looping it no longer. It answers: "You are restoring what I am taking apart, and we are both right. Every lamp you light feeds the city. Every lamp I carry out starves the thing in the center. Light the districts. I will meet you at the last one with everything I have kept. Forty years of light, engineer. Bring a strong back." The operator's note under the tape: "It knows the districts are lit. It is counting with us." | 一盤來自訊號閣樓大型接收機的磁帶,用值夜操作員的字跡標著:回應——同一個聲音,新的話語。那個循環播放呼叫已經一年的平靜聲音,不再循環了。它回應道:「你在修復我正在拆解的東西,我們兩個都對。你點亮的每一盞燈都在餵養這座城市。我搬走的每一盞燈都在餓死中心那個東西。點亮這些區。我會帶著我保存的一切,在最後一區與你相見。四十年的光,工程師。帶上一副強壯的脊背來。」磁帶下面操作員的字條:「它知道各區都已點亮。它在和我們一起數著。」
[H] LORE_POWER_STATION_08_TEXT | zh_TW | Shot from the cooling-tower gantry on the first night the station held: the towers lit from below, and at the gate below them the gate lamp burning — one streetlight, the crew's hand truck beside it, and a bowl of food set at its foot. The groundskeeper's note is pinned to the print: the station poplars have leaned toward the gate lamp all winter, the way the park trees leaned before the blackout. The watch roster is pinned under it, final line: the corner-window name, uncrossed — relieved, lamp kept. And the recorder's hand on the back, last: "One streetlight. The bench proof stands at the center." | 在電站第一次撐住的那個夜晚,從冷卻塔的棧橋上拍的:塔身從下方被照亮,塔下的大門那兒,門燈正燃燒著——一盞路燈,班組的手推車立在旁邊,腳下放著一碗食物。護場人的字條別在照片上:整個冬天,電站的白楊樹都朝那盞門燈傾斜,就像停電前公園裡的樹傾斜的樣子。下面別著值守名單,最後一行:角窗那個名字,沒有劃掉——已換班,燈留著。背面是敘述者的字跡,是最後一句:「一盞路燈。工作臺上的證據在中心依然成立。」
[H] TOAST_COINS_GAINED | zh_TW | +%s coins | +%s 硬幣
