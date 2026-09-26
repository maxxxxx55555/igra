# I18N table v2: native-quality defects at `ce782f8`

Rows for Local to apply verbatim: one `key` in one locale, OLD → NEW. The cloud pass applied none of
them. **Validation:** all rows applied to a copy of `data/i18n/` → `python3
tools/qa_sim/i18n_truth_gate.py <copy>` → **12/12 locales PASS, rc 0**. Placeholders are unchanged in
every row.

## What was swept (all 12 translated locales, 1301 keys each)

| Check | Method | Result |
|---|---|---|
| Placeholders | GDScript `%` specifiers (`tf()` uses `String % args`), en vs locale per key | 0 mismatches (literal "5% …" is not a specifier) |
| BBCode, newlines, stray whitespace | per key vs en | 0 |
| Mixed script, bloat > 1.6× | `i18n_truth_gate.py` | 0 (gate PASS at HEAD) |
| zh_TW contains Simplified | OpenCC `s2tw` round trip | 0 real leaks. The 38 hits are OpenCC over-conversions (背包→揹包, 證明了→證明瞭, 不准→不準) and must not be applied |
| English left in non-Latin locales | Latin words also present in the en string | 8 real (rows A); brand or proper names kept: SOS, EON, OpenDyslexic |
| Identical to English in Latin locales | exact match | Cognates and accepted gaming terms only (Hospital, Park, Radio, Journal, Speedrunner) |
| Accents on capitals | fr/es/it/pt_BR all-caps words vs their accented lowercase forms, plus a read of all 88 fr all-caps strings | 2 real (rows D) |
| Glossary | each locale's own `NEW_GAME_PLUS` term across all New Game+ keys; ru flashlight vs streetlight | rows B |
| Voice (register) | pronouns and imperative endings in the tutorial / onboarding / tips / hints / touch-calibration family (lore excluded) | ru, fr, tr, ja, ko mixed in one flow (rows C); de, es, it, pt_BR, zh, zh_TW consistent |

## Register rule per locale (the minority side of each mixed flow is rewritten)

- **ru:** ты. 21 of 34 in the family, and it matches the radio voice fixed to ты in `21c6563`.
  System lines in the past tense stay вы (ВЫ ПОГИБЛИ, Вы проиграли), because a ты past tense is
  gendered.
- **fr:** vous. 23 of 34, and the system UI (death, map, achievements) is vous. Narrator flavour
  lines (daily flavour, NG+ descriptions) stay tu as the narrator voice.
- **tr:** sen (majority). **ja:** the terse command voice (〜しろ/〜せよ) of the whole family; only
  the touch-calibration screens used friendly 〜しよう/だよ.
- **ko:** 해라체 (24 of 43, and the narrator lines ONBOARD/TIP use it). If the owner prefers polite
  -세요/-습니다 for instructions, flip the other 24 instead. What matters is one register.


Rows: **79**. By class: latin 8, glossary 17, voice 51, grammar 1, accent 2. By locale: ar 3, de 3, fr 15, it 1, ja 5, ko 20, pt_BR 1, ru 27, tr 4.

| # | Locale | Key | OLD | NEW | Class |
|---|---|---|---|---|---|
| 1 | ru | `ACH_02_DESC` | Восстановить 1 район до FULL | Полностью восстановить 1 район | latin |
| 2 | ru | `ACH_03_DESC` | Восстановить все районы до FULL | Полностью восстановить все районы | latin |
| 3 | ru | `ACH_07_DESC` | Выполнить 10 combo-3 подряд | Провести 10 тройных комбо подряд | latin |
| 4 | ru | `ACH_12_DESC` | Пройти District 4 без урона | Пройти район 4 без урона | latin |
| 5 | ru | `ACH_19_DESC` | Поспать в кровати (District 1) | Поспать в кровати (район 1) | latin |
| 6 | ar | `Hardcore Mode` | وضع Hardcore | وضع هاردكور | latin |
| 7 | ar | `ACH_18_DESC` | أنهِ اللعبة في وضع Hardcore | أنهِ اللعبة في وضع هاردكور | latin |
| 8 | ar | `NGP_SETUP_ACTION` | إعداد New Game+ | إعداد اللعبة الجديدة+ | latin+glossary |
| 9 | de | `NGP_SETUP_ACTION` | New Game+ einrichten | Neues Spiel+ einrichten | glossary |
| 10 | de | `NG_PLUS_ACTIVATED` | New Game+ aktiviert! Schwierigkeit erhöht. | Neues Spiel+ aktiviert! Schwierigkeit erhöht. | glossary |
| 11 | de | `NG_PLUS_LEVEL` | New Game+ Stufe: %d / %d | Neues Spiel+: Stufe %d / %d | glossary |
| 12 | fr | `NGP_SETUP_ACTION` | Configurer New Game+ | Régler Nouvelle Partie+ | glossary |
| 13 | it | `NGP_SETUP_ACTION` | Configura New Game+ | Configura Nuova Partita+ | glossary |
| 14 | pt_BR | `NGP_SETUP_ACTION` | Configurar New Game+ | Configurar Novo Jogo+ | glossary |
| 15 | ko | `NG_PLUS_ACTIVATED` | 뉴 게임+ 활성화! 난이도가 상승합니다. | 새 게임+ 활성화! 난이도가 상승합니다. | glossary |
| 16 | ko | `NG_PLUS_LEVEL` | 뉴 게임+ 레벨: %d / %d | 새 게임+ 레벨: %d / %d | glossary |
| 17 | ru | `CRAFT_BATTERY` | Батарея фонаря | Батарея фонарика | glossary |
| 18 | ru | `Q_COLLECT_BATTERY_DESC` | Собери 4 батареи для фонаря. | Собери 4 батареи для фонарика. | glossary |
| 19 | ru | `SCR_FONAR` | ФОНАРЬ | ФОНАРИК | glossary |
| 20 | ru | `TIP_1` | Фонарь — твой единственный союзник. | Фонарик — твой единственный союзник. | glossary |
| 21 | ru | `SKILL_LIGHT_RADIUS_DESC` | +20% к дальности фонаря | +20% к дальности фонарика | glossary |
| 22 | ru | `SKILL_LOW_PROFILE_DESC` | -10% к радиусу зрения врагов при скрытности с выключенным фонарём | -10% к радиусу зрения врагов при скрытности с выключенным фонариком | glossary |
| 23 | ru | `ONBOARD_01_CAPTION` | Свет — твой единственный инструмент. Держи фонарь ближе, здесь темно. | Свет — твой единственный инструмент. Держи фонарик ближе, здесь темно. | glossary |
| 24 | ru | `ONBOARD_05_CAPTION` | Батарейки поддерживают фонарь горящим — ищи их, пока не остался без света. | Батарейки не дают фонарику погаснуть — ищи их, пока не наступила тьма. | glossary+grammar |
| 25 | ru | `TUT_FLASHLIGHT` | Включи фонарь. Темнота не пуста. | Включи фонарик. Темнота не пуста. | glossary |
| 26 | ru | `SCR_SVET_NE_TOLKO_ZASCHISCHAET_VAS_OT_MONSTROV_N` | Свет не только защищает вас от монстров, но и открывает новые пути. | Свет не только защищает тебя от монстров, но и открывает новые пути. | voice |
| 27 | ru | `TOUCH_CAL_STEP_DRAG` | Потяните джойстик, чтобы двигаться. | Потяни джойстик, чтобы двигаться. | voice |
| 28 | ru | `TOUCH_CAL_STEP_HAPTIC` | Почувствовали вибрацию? Это тактильная отдача — нажмите, чтобы продолжить. | Чувствуешь вибрацию? Это тактильная отдача — нажми, чтобы продолжить. | voice |
| 29 | ru | `TOUCH_CAL_STEP_INTERACT` | Теперь нажмите «Действие». | Теперь нажми «Действие». | voice |
| 30 | ru | `TOUCH_CAL_TITLE` | Освойте управление | Освой управление | voice |
| 31 | ru | `TUT_COMPLETE` | Обучение завершено. Берегите свет. | Обучение завершено. Береги свет. | voice |
| 32 | ru | `TUT_FIND_FLASHLIGHT` | Найдите фонарик. Нажмите F, чтобы включить его. | Найди фонарик. Нажми F, чтобы включить его. | voice |
| 33 | ru | `TUT_FIRST_SHADOW` | Тень рядом. Удерживайте её в луче. | Тень рядом. Удерживай её в луче. | voice |
| 34 | ru | `TUT_GENERATOR` | Запустите генератор, чтобы вернуть свет району. | Запусти генератор, чтобы вернуть свет району. | voice |
| 35 | ru | `TUT_GENERATOR_STEP1` | Соедините кабели в правильном порядке. | Соедини кабели в правильном порядке. | voice |
| 36 | ru | `TUT_LIGHT_SHIELD` | Свет — ваш щит. Монстры боятся луча. | Свет — твой щит. Монстры боятся луча. | voice |
| 37 | ru | `TUT_TO_GARAGE` | Идите к гаражу. Генератор находится там. | Иди к гаражу. Генератор находится там. | voice |
| 38 | ru | `TUT_WAKE_UP` | Вы приходите в себя. Город погрузился во тьму. | Ты приходишь в себя. Город погрузился во тьму. | voice |
| 39 | fr | `ONBOARD_05_CAPTION` | Les piles gardent la lampe torche allumée — trouve-les avant de te retrouver dans le noir. | Les piles gardent la lampe torche allumée — trouvez-les avant de vous retrouver dans le noir. | voice |
| 40 | fr | `ONBOARD_06_CAPTION` | Certains panneaux ont besoin de plus que du courant — relie les câbles pour les débloquer. | Certains panneaux ont besoin de plus que du courant — reliez les câbles pour les débloquer. | voice |
| 41 | fr | `ONBOARD_07_CAPTION` | Accroupis-toi pour te déplacer sans bruit et rester hors du champ de vision d'un chasseur. | Accroupissez-vous pour vous déplacer sans bruit et rester hors du champ de vision d'un chasseur. | voice |
| 42 | fr | `TUT_ATTACK` | Riposte s'il t'atteint. | Ripostez s'il vous atteint. | voice |
| 43 | fr | `TUT_CROUCH` | Avance sans bruit. Des pas lents s'entendent moins. | Avancez sans bruit. Des pas lents s'entendent moins. | voice |
| 44 | fr | `TUT_DODGE` | Esquive quand quelque chose bondit. | Esquivez quand quelque chose bondit. | voice |
| 45 | fr | `TUT_FLASHLIGHT` | Allume ta lampe. L'obscurité n'est pas vide. | Allumez votre lampe. L'obscurité n'est pas vide. | voice |
| 46 | fr | `TUT_INVENTORY` | Ouvre ton sac pour voir ce que tu portes. | Ouvrez votre sac pour voir ce que vous portez. | voice |
| 47 | fr | `TUT_JOURNAL` | Ton journal suit les quêtes et les secrets que tu trouves. Ouvre-le quand tu veux. | Votre journal suit les quêtes et les secrets que vous trouvez. Ouvrez-le quand vous voulez. | voice |
| 48 | fr | `TUT_MOVE` | Avance. Reste là où tombe la lumière. | Avancez. Restez là où tombe la lumière. | voice |
| 49 | fr | `TUT_PICKUP` | Ramasse ce que tu trouves. Les pièces rallument les lampadaires. | Ramassez ce que vous trouvez. Les pièces rallument les lampadaires. | voice |
| 50 | fr | `NGP_MENU_STATUS` | NG+%d actif. « Nouvelle partie » recommence à zéro à cette difficulté ; « Continuer » charge ta progression. | NG+%d actif. « Nouvelle partie » recommence à zéro à cette difficulté ; « Continuer » charge votre progression. | voice |
| 51 | tr | `SCR_SVET_NE_TOLKO_ZASCHISCHAET_VAS_OT_MONSTROV_N` | Işık sizi sadece canavarlardan korumaz - yeni yollar da açar. | Işık seni sadece canavarlardan korumaz - yeni yollar da açar. | voice |
| 52 | tr | `SCR_TISHINA_TVOY_SOYUZNIK_V_TEMNOTE` | Sessizlik karanlıkta müttefikinizdir. | Sessizlik karanlıkta müttefikindir. | voice |
| 53 | tr | `TOUCH_CAL_STEP_DRAG` | Hareket etmek için joystick'i sürükleyin. | Hareket etmek için joystick'i sürükle. | voice |
| 54 | tr | `TOUCH_CAL_STEP_INTERACT` | Şimdi Etkileşim'e dokunun. | Şimdi Etkileşim'e dokun. | voice |
| 55 | ja | `TOUCH_CAL_STEP_DRAG` | スティックをドラッグして移動しよう。 | スティックをドラッグして移動しろ。 | voice |
| 56 | ja | `TOUCH_CAL_STEP_HAPTIC` | 今の振動を感じた?これがハプティックフィードバックだよ。タップして続けよう。 | 今の振動を感じたか？これがハプティックフィードバックだ。タップして続けろ。 | voice |
| 57 | ja | `TOUCH_CAL_STEP_INTERACT` | 次にインタラクトをタップしよう。 | 次にインタラクトをタップしろ。 | voice |
| 58 | ja | `TOUCH_CAL_TITLE` | 操作に慣れよう | 操作に慣れろ | voice |
| 59 | ja | `TUT_ATTACK` | 届かれたら反撃しろ。 | 襲われたら反撃しろ。 | grammar |
| 60 | ko | `HINT_FLASHLIGHT` | F — 손전등. 빛은 배터리를 소모하지만 그림자를 쫓아냅니다 | F — 손전등. 빛은 배터리를 소모하지만 그림자를 쫓아낸다 | voice |
| 61 | ko | `HINT_INVENTORY` | Tab — 인벤토리. 무게에 주의하세요 | Tab — 인벤토리. 무게에 주의하라 | voice |
| 62 | ko | `ONBOARD_05_CAPTION` | 배터리가 손전등을 계속 밝혀줍니다 — 어둠 속에 남겨지기 전에 찾으세요. | 배터리가 손전등을 계속 밝혀준다 — 어둠 속에 남겨지기 전에 찾아라. | voice |
| 63 | ko | `ONBOARD_06_CAPTION` | 전력만으로는 부족한 배전반도 있습니다 — 케이블을 맞춰 잠금을 해제하세요. | 전력만으로는 부족한 배전반도 있다 — 케이블을 맞춰 잠금을 해제하라. | voice |
| 64 | ko | `ONBOARD_07_CAPTION` | 웅크리면 조용히 움직이고 사냥꾼의 시야 밖에 머물 수 있습니다. | 웅크리면 조용히 움직이고 사냥꾼의 시야 밖에 머물 수 있다. | voice |
| 65 | ko | `TOUCH_CAL_STEP_DRAG` | 조이스틱을 드래그해서 이동하세요. | 조이스틱을 드래그해서 이동하라. | voice |
| 66 | ko | `TOUCH_CAL_STEP_HAPTIC` | 방금 진동 느꼈나요? 그게 햅틱 피드백이에요 — 계속하려면 탭하세요. | 방금 진동을 느꼈나? 그것이 햅틱 피드백이다 — 계속하려면 탭하라. | voice |
| 67 | ko | `TOUCH_CAL_STEP_INTERACT` | 이번엔 상호작용을 눌러보세요. | 이번엔 상호작용을 눌러라. | voice |
| 68 | ko | `TOUCH_CAL_TITLE` | 조작감을 익혀보세요 | 조작을 익혀라 | voice |
| 69 | ko | `TUT_BATTERY_FOUND` | 배터리다! 손전등을 충전할 수 있습니다. | 배터리다! 손전등을 충전할 수 있다. | voice |
| 70 | ko | `TUT_COMPLETE` | 튜토리얼 완료. 빛을 지키세요. | 튜토리얼 완료. 빛을 지켜라. | voice |
| 71 | ko | `TUT_FIND_FLASHLIGHT` | 손전등을 찾으세요. F 키를 눌러 켭니다. | 손전등을 찾아라. F 키를 눌러 켠다. | voice |
| 72 | ko | `TUT_FIRST_SHADOW` | 그림자가 가까이 있습니다. 빛줄기 안에 붙잡으세요. | 그림자가 가까이 있다. 빛줄기 안에 붙잡아라. | voice |
| 73 | ko | `TUT_GENERATOR` | 발전기를 가동해 구역을 되살리세요. | 발전기를 가동해 구역을 되살려라. | voice |
| 74 | ko | `TUT_GENERATOR_STEP1` | 케이블을 올바른 순서로 연결하세요. | 케이블을 올바른 순서로 연결하라. | voice |
| 75 | ko | `TUT_LIGHT_SHIELD` | 빛은 당신의 방패입니다. 괴물은 빛줄기를 두려워합니다. | 빛은 당신의 방패다. 괴물은 빛줄기를 두려워한다. | voice |
| 76 | ko | `TUT_TO_GARAGE` | 차고로 가세요. 발전기가 그곳에 있습니다. | 차고로 가라. 발전기가 그곳에 있다. | voice |
| 77 | ko | `TUT_WAKE_UP` | 잠에서 깼습니다. 도시는 어둠에 잠겼습니다. | 잠에서 깼다. 도시는 어둠에 잠겼다. | voice |
| 78 | fr | `menu_title` | LE DERNIER REVERBERE | LE DERNIER RÉVERBÈRE | accent |
| 79 | fr | `victory` | NIVEAU TERMINE | NIVEAU TERMINÉ | accent |

Class meanings:
- **latin:** an English word left inside a non-Latin locale.
- **glossary:** a term that differs from the locale's own established term. New Game+ follows each
  locale's `NEW_GAME_PLUS`. For ru, the flashlight is фонарик, because фонарь is the streetlight
  (title: ПОСЛЕДНИЙ ФОНАРЬ).
- **voice:** a register break inside one flow.
- **accent:** fr capitals keep their accents (every other fr all-caps string already does).
- **grammar:**
  - ja `TUT_ATTACK` 届かれたら is not idiomatic.
  - ru `ONBOARD_05` "поддерживают фонарь горящим" is a calque, and "остался" is gendered.

## Machine-readable rows

Apply with: `for r in rows: d=load(f"data/i18n/{r[0]}.json"); assert d[r[1]]==r[2]; d[r[1]]=r[3]; save(...)`.
Keep each file's existing formatting, then run the i18n gate.

```json
[
["ru", "ACH_02_DESC", "Восстановить 1 район до FULL", "Полностью восстановить 1 район"],
["ru", "ACH_03_DESC", "Восстановить все районы до FULL", "Полностью восстановить все районы"],
["ru", "ACH_07_DESC", "Выполнить 10 combo-3 подряд", "Провести 10 тройных комбо подряд"],
["ru", "ACH_12_DESC", "Пройти District 4 без урона", "Пройти район 4 без урона"],
["ru", "ACH_19_DESC", "Поспать в кровати (District 1)", "Поспать в кровати (район 1)"],
["ar", "Hardcore Mode", "وضع Hardcore", "وضع هاردكور"],
["ar", "ACH_18_DESC", "أنهِ اللعبة في وضع Hardcore", "أنهِ اللعبة في وضع هاردكور"],
["ar", "NGP_SETUP_ACTION", "إعداد New Game+", "إعداد اللعبة الجديدة+"],
["de", "NGP_SETUP_ACTION", "New Game+ einrichten", "Neues Spiel+ einrichten"],
["de", "NG_PLUS_ACTIVATED", "New Game+ aktiviert! Schwierigkeit erhöht.", "Neues Spiel+ aktiviert! Schwierigkeit erhöht."],
["de", "NG_PLUS_LEVEL", "New Game+ Stufe: %d / %d", "Neues Spiel+: Stufe %d / %d"],
["fr", "NGP_SETUP_ACTION", "Configurer New Game+", "Régler Nouvelle Partie+"],
["it", "NGP_SETUP_ACTION", "Configura New Game+", "Configura Nuova Partita+"],
["pt_BR", "NGP_SETUP_ACTION", "Configurar New Game+", "Configurar Novo Jogo+"],
["ko", "NG_PLUS_ACTIVATED", "뉴 게임+ 활성화! 난이도가 상승합니다.", "새 게임+ 활성화! 난이도가 상승합니다."],
["ko", "NG_PLUS_LEVEL", "뉴 게임+ 레벨: %d / %d", "새 게임+ 레벨: %d / %d"],
["ru", "CRAFT_BATTERY", "Батарея фонаря", "Батарея фонарика"],
["ru", "Q_COLLECT_BATTERY_DESC", "Собери 4 батареи для фонаря.", "Собери 4 батареи для фонарика."],
["ru", "SCR_FONAR", "ФОНАРЬ", "ФОНАРИК"],
["ru", "TIP_1", "Фонарь — твой единственный союзник.", "Фонарик — твой единственный союзник."],
["ru", "SKILL_LIGHT_RADIUS_DESC", "+20% к дальности фонаря", "+20% к дальности фонарика"],
["ru", "SKILL_LOW_PROFILE_DESC", "-10% к радиусу зрения врагов при скрытности с выключенным фонарём", "-10% к радиусу зрения врагов при скрытности с выключенным фонариком"],
["ru", "ONBOARD_01_CAPTION", "Свет — твой единственный инструмент. Держи фонарь ближе, здесь темно.", "Свет — твой единственный инструмент. Держи фонарик ближе, здесь темно."],
["ru", "ONBOARD_05_CAPTION", "Батарейки поддерживают фонарь горящим — ищи их, пока не остался без света.", "Батарейки не дают фонарику погаснуть — ищи их, пока не наступила тьма."],
["ru", "TUT_FLASHLIGHT", "Включи фонарь. Темнота не пуста.", "Включи фонарик. Темнота не пуста."],
["ru", "SCR_SVET_NE_TOLKO_ZASCHISCHAET_VAS_OT_MONSTROV_N", "Свет не только защищает вас от монстров, но и открывает новые пути.", "Свет не только защищает тебя от монстров, но и открывает новые пути."],
["ru", "TOUCH_CAL_STEP_DRAG", "Потяните джойстик, чтобы двигаться.", "Потяни джойстик, чтобы двигаться."],
["ru", "TOUCH_CAL_STEP_HAPTIC", "Почувствовали вибрацию? Это тактильная отдача — нажмите, чтобы продолжить.", "Чувствуешь вибрацию? Это тактильная отдача — нажми, чтобы продолжить."],
["ru", "TOUCH_CAL_STEP_INTERACT", "Теперь нажмите «Действие».", "Теперь нажми «Действие»."],
["ru", "TOUCH_CAL_TITLE", "Освойте управление", "Освой управление"],
["ru", "TUT_COMPLETE", "Обучение завершено. Берегите свет.", "Обучение завершено. Береги свет."],
["ru", "TUT_FIND_FLASHLIGHT", "Найдите фонарик. Нажмите F, чтобы включить его.", "Найди фонарик. Нажми F, чтобы включить его."],
["ru", "TUT_FIRST_SHADOW", "Тень рядом. Удерживайте её в луче.", "Тень рядом. Удерживай её в луче."],
["ru", "TUT_GENERATOR", "Запустите генератор, чтобы вернуть свет району.", "Запусти генератор, чтобы вернуть свет району."],
["ru", "TUT_GENERATOR_STEP1", "Соедините кабели в правильном порядке.", "Соедини кабели в правильном порядке."],
["ru", "TUT_LIGHT_SHIELD", "Свет — ваш щит. Монстры боятся луча.", "Свет — твой щит. Монстры боятся луча."],
["ru", "TUT_TO_GARAGE", "Идите к гаражу. Генератор находится там.", "Иди к гаражу. Генератор находится там."],
["ru", "TUT_WAKE_UP", "Вы приходите в себя. Город погрузился во тьму.", "Ты приходишь в себя. Город погрузился во тьму."],
["fr", "ONBOARD_05_CAPTION", "Les piles gardent la lampe torche allumée — trouve-les avant de te retrouver dans le noir.", "Les piles gardent la lampe torche allumée — trouvez-les avant de vous retrouver dans le noir."],
["fr", "ONBOARD_06_CAPTION", "Certains panneaux ont besoin de plus que du courant — relie les câbles pour les débloquer.", "Certains panneaux ont besoin de plus que du courant — reliez les câbles pour les débloquer."],
["fr", "ONBOARD_07_CAPTION", "Accroupis-toi pour te déplacer sans bruit et rester hors du champ de vision d'un chasseur.", "Accroupissez-vous pour vous déplacer sans bruit et rester hors du champ de vision d'un chasseur."],
["fr", "TUT_ATTACK", "Riposte s'il t'atteint.", "Ripostez s'il vous atteint."],
["fr", "TUT_CROUCH", "Avance sans bruit. Des pas lents s'entendent moins.", "Avancez sans bruit. Des pas lents s'entendent moins."],
["fr", "TUT_DODGE", "Esquive quand quelque chose bondit.", "Esquivez quand quelque chose bondit."],
["fr", "TUT_FLASHLIGHT", "Allume ta lampe. L'obscurité n'est pas vide.", "Allumez votre lampe. L'obscurité n'est pas vide."],
["fr", "TUT_INVENTORY", "Ouvre ton sac pour voir ce que tu portes.", "Ouvrez votre sac pour voir ce que vous portez."],
["fr", "TUT_JOURNAL", "Ton journal suit les quêtes et les secrets que tu trouves. Ouvre-le quand tu veux.", "Votre journal suit les quêtes et les secrets que vous trouvez. Ouvrez-le quand vous voulez."],
["fr", "TUT_MOVE", "Avance. Reste là où tombe la lumière.", "Avancez. Restez là où tombe la lumière."],
["fr", "TUT_PICKUP", "Ramasse ce que tu trouves. Les pièces rallument les lampadaires.", "Ramassez ce que vous trouvez. Les pièces rallument les lampadaires."],
["fr", "NGP_MENU_STATUS", "NG+%d actif. « Nouvelle partie » recommence à zéro à cette difficulté ; « Continuer » charge ta progression.", "NG+%d actif. « Nouvelle partie » recommence à zéro à cette difficulté ; « Continuer » charge votre progression."],
["tr", "SCR_SVET_NE_TOLKO_ZASCHISCHAET_VAS_OT_MONSTROV_N", "Işık sizi sadece canavarlardan korumaz - yeni yollar da açar.", "Işık seni sadece canavarlardan korumaz - yeni yollar da açar."],
["tr", "SCR_TISHINA_TVOY_SOYUZNIK_V_TEMNOTE", "Sessizlik karanlıkta müttefikinizdir.", "Sessizlik karanlıkta müttefikindir."],
["tr", "TOUCH_CAL_STEP_DRAG", "Hareket etmek için joystick'i sürükleyin.", "Hareket etmek için joystick'i sürükle."],
["tr", "TOUCH_CAL_STEP_INTERACT", "Şimdi Etkileşim'e dokunun.", "Şimdi Etkileşim'e dokun."],
["ja", "TOUCH_CAL_STEP_DRAG", "スティックをドラッグして移動しよう。", "スティックをドラッグして移動しろ。"],
["ja", "TOUCH_CAL_STEP_HAPTIC", "今の振動を感じた?これがハプティックフィードバックだよ。タップして続けよう。", "今の振動を感じたか？これがハプティックフィードバックだ。タップして続けろ。"],
["ja", "TOUCH_CAL_STEP_INTERACT", "次にインタラクトをタップしよう。", "次にインタラクトをタップしろ。"],
["ja", "TOUCH_CAL_TITLE", "操作に慣れよう", "操作に慣れろ"],
["ja", "TUT_ATTACK", "届かれたら反撃しろ。", "襲われたら反撃しろ。"],
["ko", "HINT_FLASHLIGHT", "F — 손전등. 빛은 배터리를 소모하지만 그림자를 쫓아냅니다", "F — 손전등. 빛은 배터리를 소모하지만 그림자를 쫓아낸다"],
["ko", "HINT_INVENTORY", "Tab — 인벤토리. 무게에 주의하세요", "Tab — 인벤토리. 무게에 주의하라"],
["ko", "ONBOARD_05_CAPTION", "배터리가 손전등을 계속 밝혀줍니다 — 어둠 속에 남겨지기 전에 찾으세요.", "배터리가 손전등을 계속 밝혀준다 — 어둠 속에 남겨지기 전에 찾아라."],
["ko", "ONBOARD_06_CAPTION", "전력만으로는 부족한 배전반도 있습니다 — 케이블을 맞춰 잠금을 해제하세요.", "전력만으로는 부족한 배전반도 있다 — 케이블을 맞춰 잠금을 해제하라."],
["ko", "ONBOARD_07_CAPTION", "웅크리면 조용히 움직이고 사냥꾼의 시야 밖에 머물 수 있습니다.", "웅크리면 조용히 움직이고 사냥꾼의 시야 밖에 머물 수 있다."],
["ko", "TOUCH_CAL_STEP_DRAG", "조이스틱을 드래그해서 이동하세요.", "조이스틱을 드래그해서 이동하라."],
["ko", "TOUCH_CAL_STEP_HAPTIC", "방금 진동 느꼈나요? 그게 햅틱 피드백이에요 — 계속하려면 탭하세요.", "방금 진동을 느꼈나? 그것이 햅틱 피드백이다 — 계속하려면 탭하라."],
["ko", "TOUCH_CAL_STEP_INTERACT", "이번엔 상호작용을 눌러보세요.", "이번엔 상호작용을 눌러라."],
["ko", "TOUCH_CAL_TITLE", "조작감을 익혀보세요", "조작을 익혀라"],
["ko", "TUT_BATTERY_FOUND", "배터리다! 손전등을 충전할 수 있습니다.", "배터리다! 손전등을 충전할 수 있다."],
["ko", "TUT_COMPLETE", "튜토리얼 완료. 빛을 지키세요.", "튜토리얼 완료. 빛을 지켜라."],
["ko", "TUT_FIND_FLASHLIGHT", "손전등을 찾으세요. F 키를 눌러 켭니다.", "손전등을 찾아라. F 키를 눌러 켠다."],
["ko", "TUT_FIRST_SHADOW", "그림자가 가까이 있습니다. 빛줄기 안에 붙잡으세요.", "그림자가 가까이 있다. 빛줄기 안에 붙잡아라."],
["ko", "TUT_GENERATOR", "발전기를 가동해 구역을 되살리세요.", "발전기를 가동해 구역을 되살려라."],
["ko", "TUT_GENERATOR_STEP1", "케이블을 올바른 순서로 연결하세요.", "케이블을 올바른 순서로 연결하라."],
["ko", "TUT_LIGHT_SHIELD", "빛은 당신의 방패입니다. 괴물은 빛줄기를 두려워합니다.", "빛은 당신의 방패다. 괴물은 빛줄기를 두려워한다."],
["ko", "TUT_TO_GARAGE", "차고로 가세요. 발전기가 그곳에 있습니다.", "차고로 가라. 발전기가 그곳에 있다."],
["ko", "TUT_WAKE_UP", "잠에서 깼습니다. 도시는 어둠에 잠겼습니다.", "잠에서 깼다. 도시는 어둠에 잠겼다."],
["fr", "menu_title", "LE DERNIER REVERBERE", "LE DERNIER RÉVERBÈRE"],
["fr", "victory", "NIVEAU TERMINE", "NIVEAU TERMINÉ"]
]
```
