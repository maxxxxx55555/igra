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
