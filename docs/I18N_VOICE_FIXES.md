# I18N_VOICE_FIXES — exact NEW strings (locale owner applies; do not edit json this pass)

**Voice:** Keeper. Terse. 2nd person. Ellipses. No exclamation.
**Length:** every NEW locale string ≤1.6× its NEW EN (characters).
**TZ quote for radio register:** `docs/GDD.md:338` «радио-голос «Идите на электростанцию»».
**This pass does not edit** `data/i18n/*.json`.

---

## Glossary (unify to these; do not mix)

| Concept | en | ru | ja |
|---|---|---|---|
| The Keeper (NPC) | The Keeper | Хранитель | **管理人** (never 守護者, never キーパー) |
| Player, when addressed | engineer | инженер | 技師 |
| Act I radio (city call) | you | **вы** | お前 / imperative |
| Act III radio (Keeper to engineer) | you | **ты** | お前 |

Diaries stay 1st person (Keeper writing). Resident recorders stay 1st person. Do not call the player «Keeper» / «Хранитель» / «管理人».

---

## 1. ja Keeper name: 管理人 vs 守護者 / キーパー

Dominant title is already `WORLD_CHAR_KEEPER_TITLE` = 管理人. Two strays:

| key | loc | OLD | NEW |
|---|---|---|---|
| FINAL_NIGHT_DESC | ja | 守護者が待つ。街の最後の街灯を復旧せよ。 | 管理人が待つ。街の最後の街灯を復旧せよ。 |
| LORE_POWER_STATION_03_TITLE | ja | 信号室——キーパーが応答する | 信号室——管理人が応答する |

en/ru already say The Keeper / Хранитель — no change.

`FINAL_NIGHT_DESC` en (unchanged, 52): `The Keeper waits. Restore the last lamp of the city.`
ja NEW 20 ≤ 1.6×52.

`LORE_POWER_STATION_03_TITLE` en (unchanged, 32): `Signal Loft — The Keeper Answers`
ja NEW 14 ≤ 1.6×32.

---

## 2. ru radio вы/ты

**Reading:** GDD §12.3 quotes **«Идите»** (вы) for the Act I call. Broadcast 3 is Keeper to one engineer — **ты** (already). Unify the *call* to вы; do not flatten Broadcast 3.

| key | loc | OLD | NEW |
|---|---|---|---|
| WORLD_RADIO_01_TEXT | ru | ...если ты это слышишь, сеть ещё можно вернуть. Район за районом, фонарь за фонарём. Не ходи под землю. Не иди по указателям на арену. Иди на электростанцию. Тот, кто хранил свет, встретит тебя у света. [три щелчка реле] | ...если вы это слышите, сеть ещё можно вернуть. Район за районом, фонарь за фонарём. Не ходите под землю. Не идите по указателям на арену. Идите на электростанцию. Тот, кто хранил свет, встретит вас у света. [три щелчка реле] |

Keep as-is (already correct register):

| key | loc | status |
|---|---|---|
| WORLD_CHAR_RADIOVOICE_TEXT | ru | KEEP `Идите на электростанцию. Тот, кто хранил свет, встретит вас у света.` (вы, GDD quote) |
| WORLD_RADIO_03_TEXT | ru | KEEP ты (`Ты восстанавливаешь… инженер.`) |
| RADIO_TRANSCRIPT_E1 | ru | KEEP вы (`Если вы нас слышите`) |
| WORLD_RADIO_01_TEXT | en | KEEP (you covers both) |
| WORLD_RADIO_01_TEXT | ja | KEEP (行け / 行くな) |

NEW ru `WORLD_RADIO_01_TEXT` 225 / en 251 = 0.90.

---

## 3. LORE_RESIDENTIAL_03 stray "why"

en narrator «I don't know why I said yes» is the stray (explains the lie). ja leaked English `why` next to なぜ.

| key | loc | OLD | NEW |
|---|---|---|---|
| LORE_RESIDENTIAL_03_TEXT | en | "...the intercom has been dead for a month, but last night it clicked on by itself. A child's voice asked: 'Is the light on yet?' I said yes. I don't know why I said yes, ours is the only window that never had a lamp. The voice said: 'Then why is it dark in your stairwell?' Then static. I am not going down there again." | "...the intercom has been dead for a month, but last night it clicked on by itself. A child's voice asked: 'Is the light on yet?' I said yes. Ours is the only window that never had a lamp. The voice said: 'Then why is it dark in your stairwell?' Then static. I am not going down there again." |
| LORE_RESIDENTIAL_03_TEXT | ru | «...домофон не работал месяц, но прошлой ночью включился сам. Детский голос спросил: „Свет уже включили?“ Я сказал да. Не знаю, почему сказал да, у нас единственное окно, где никогда не было лампы. Голос сказал: „Тогда почему у вас на лестнице темно?“ Потом помехи. Я больше туда не спущусь». | «...домофон не работал месяц, но прошлой ночью включился сам. Детский голос спросил: „Свет уже включили?“ Я сказал да. У нас единственное окно, где никогда не было лампы. Голос сказал: „Тогда почему у вас на лестнице темно?“ Потом помехи. Я больше туда не спущусь». |
| LORE_RESIDENTIAL_03_TEXT | ja | 「……インターホンは一ヶ月壊れていたのに、昨夜勝手に鳴った。子供の声が聞いた:『もう明かりはついた?』はいと答えた。なぜそう言ったのか分からない、うちの窓だけはランプを持ったことがないのに。声は言った:『じゃあwhy階段はなぜ暗いの?』それから雑音。もう二度とあそこには降りない」 | 「……インターホンは一ヶ月壊れていたのに、昨夜勝手に鳴った。子供の声が聞いた:『もう明かりはついた?』はいと答えた。うちの窓だけはランプを持ったことがない。声は言った:『じゃあ階段はなぜ暗いの?』それから雑音。もう二度とあそこには降りない」 |

Keep the child's «why / почему / なぜ» — that is the scare. Strip the narrator's why and the latin `why` in ja.

NEW lens: en 292, ru 268 (0.92), ja 122 (0.42).

---

## 4. WORLD_DIARY_K2 tone

Stacked «and…and…and» plus «was scheduled for» — not Keeper-terse. Diary stays 1st person. Timestamps + ellipses.

| key | loc | OLD | NEW |
|---|---|---|---|
| WORLD_DIARY_K2_TEXT | en | The outage was scheduled for one hour. At 23:00 the feeders held. At 23:40 they were drinking. I have kept lamps forty years; I know the sound a transformer makes when it is full, and the grid sounds full tonight, and every lamp in the city is dark. Something else is lit. | Outage: one hour. 23:00... the feeders held. 23:40... they were drinking. Forty years of lamps. I know the sound a full transformer makes... the grid sounds full tonight. Every lamp in the city is dark. Something else is lit. |
| WORLD_DIARY_K2_TEXT | ru | Отключение было рассчитано на час. В 23:00 фидеры держались. В 23:40 они уже пили. Я храню фонари сорок лет; я знаю звук, который издаёт полный трансформатор, и сегодня сеть звучит полной, а каждый фонарь в городе тёмен. Горит что-то другое. | Отключение: на час. 23:00... фидеры держались. 23:40... они уже пили. Сорок лет фонарей. Я знаю звук полного трансформатора... сегодня сеть звучит полной. Каждый фонарь в городе тёмен. Горит что-то другое. |
| WORLD_DIARY_K2_TEXT | ja | 停電は一時間の予定だった。23時にはフィーダーは持ちこたえていた。23時40分には飲んでいた。私は四十年間街灯を守ってきた。満杯の変圧器が立てる音を知っている、そして今夜、送電網は満杯の音を立てている、なのに街のすべての街灯は暗い。何か別のものが灯っている。 | 停電は一時間の予定。23時...フィーダーは持ちこたえた。23時40分...飲んでいた。街灯四十年。満杯の変圧器の音は知っている...今夜、送電網は満杯に響く。街の街灯はすべて暗い。何か別のものが灯っている。 |

Titles unchanged (`Keeper's Diary — The Night It Went Out` / `Дневник Хранителя — Ночь, когда всё погасло` / `管理人の日記 — 消えた夜`).

NEW lens: en 225, ru 205 (0.91), ja 104 (0.46).

---

## 5. Further voice breaks found (en/ru/ja)

### 5.1 Player addressed as Keeper (glossary break)

`DAILY_PLAY_20_FLAVOR` calls the player Keeper. Player is the engineer (`WORLD_RADIO_03`).

| key | loc | OLD | NEW |
|---|---|---|---|
| DAILY_PLAY_20_FLAVOR | en | Twenty minutes. That is a shift, Keeper. | Twenty minutes. A shift, engineer. |
| DAILY_PLAY_20_FLAVOR | ru | Двадцать минут. Это уже смена, Хранитель. | Двадцать минут. Смена, инженер. |
| DAILY_PLAY_20_FLAVOR | ja | 二十分。それがひと勤務だ、管理人。 | 二十分。ひと勤務だ、技師よ。 |

NEW: en 33, ru 32 (0.97), ja 13 (0.39).

Keep `DAILY_DARK_10_FLAVOR` ja `管理人のように歩け` (simile, not address). Keep `DAILY_KILL_40_FLAVOR` (Keeper's forty years, 3rd person).

### 5.2 Bang + lecture (Keeper-facing HUD)

GDD §4.3 names `FIRST_RESTORE` as the lock hint (`docs/GDD.md:114`). Live consumer is `NEED_DISTRICT_FIRST` (`scripts/world/power_grid.gd:54`). Fix both. No `!`.

| key | loc | OLD | NEW |
|---|---|---|---|
| FIRST_RESTORE | en | First district restored! | First district restored. |
| FIRST_RESTORE | ru | Первый район восстановлен! | Первый район восстановлен. |
| FIRST_RESTORE | ja | 最初の地区を復旧した！ | 最初の地区を復旧した。 |
| NEED_DISTRICT_FIRST | en | You must restore this district first: %s | Restore %s first... |
| NEED_DISTRICT_FIRST | ru | Сначала нужно восстановить район: %s | Сначала восстанови %s... |
| NEED_DISTRICT_FIRST | ja | 先にこの地区を復旧させる必要がある：%s | 先に%sを復旧しろ... |
| NG_PLUS_ACTIVATED | en | New Game+ activated! Difficulty increased. | NG+ is active. The grid can be walked again. |
| NG_PLUS_ACTIVATED | ru | Новая игра+ активирована! Сложность повышена. | NG+ активен. Сеть можно пройти снова. |
| NG_PLUS_ACTIVATED | ja | ニューゲーム+が有効になりました。難易度が上昇します。 | NG+が有効。送電網はもう一度歩ける。 |
| STROBE_HIT | en | Creature blinded! | Blinded... |
| STROBE_HIT | ru | Тварь ослеплена! | Ослеплена... |
| STROBE_HIT | ja | 敵を目くらまし！ | 目くらまし... |

`NG_PLUS_ACTIVATED` NEW: en 45, ru 38 (0.84), ja 22 (0.49).
`NEED_DISTRICT_FIRST` NEW: en 21+id, ru 22+id, ja 12+id — all under 1.6× EN.

### 5.3 Same Keeper quote, ja あなた vs お前

`WORLD_RADIO_03_TEXT` ja uses お前. The tape that quotes it (`LORE_POWER_STATION_03_TEXT`) uses あなた. Unify the quoted speech to お前; keep the operator frame.

| key | loc | OLD | NEW |
|---|---|---|---|
| LORE_POWER_STATION_03_TEXT | ja | 信号室の大型受信機からのテープ、夜間オペレーターの筆跡でラベル付けされている:応答——同じ声、新しい言葉。一年間ループしていたあの穏やかな声は、もうループしていない。それは答える——「あなたは私が解体しているものを修復している、そして我々は両方とも正しい。あなたが灯すすべての灯りが街を養う。私が運び出すすべての灯りが中心にあるものを飢えさせる。地区を照らせ。最後の場所で、私が保管してきたすべてを持ってあなたに会おう。四十年分の灯り、エンジニア。強い背中を持ってこい」。テープの下のオペレーターのメモ——「それは地区が灯っていることを知っている。我々と一緒に数えている」。 | 信号室の大型受信機からのテープ、夜間オペレーターの筆跡でラベル:応答——同じ声、新しい言葉。一年ループしていた穏やかな声は、もうループしていない。それは答える——「お前は私が解体するものを修復している、そして我々は両方とも正しい。お前が灯すすべての灯りが街を養う。私が持ち出すすべての灯りが中心のあれを飢えさせる。地区を照らせ。最後の地区で、守ってきたすべてを持ってお前と会う。四十年分の光だ、技師よ。万全の体で来い」。テープ下のメモ——「それは地区が灯っていることを知っている。我々と一緒に数えている」。 |

en/ru of this key already quote ты/you matching radio_03 — KEEP.

NEW ja ~280 / en 590 = 0.47.

---

## Apply order (locale owner)

1. Glossary pass: ja 管理人 only (table 1 + 5.3).
2. `WORLD_RADIO_01_TEXT` ru → вы (table 2).
3. `LORE_RESIDENTIAL_03_TEXT` en+ru+ja (table 3).
4. `WORLD_DIARY_K2_TEXT` en+ru+ja (table 4).
5. Tables 5.1–5.2.

Do not retouch other of 13 locales in this brief. After json edit: `i18n_check` must still see 1291 keys/locale; no key add/remove except if CODE later adds P3 keys from `docs/DESIGN_AUDIT_ARENA.md` (out of this table).

**Riskiest assumption:** `NEED_DISTRICT_FIRST` `%s` is a district display name that fits after «Restore … first...» on mobile HUD.
