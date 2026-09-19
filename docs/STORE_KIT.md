# Store kit

## Listing copy — reuse, don't duplicate

English listing copy already exists and is GDD-sourced:
[docs/store/play_store.md](docs/store/play_store.md) (Google Play) and
[docs/store/steam.md](docs/store/steam.md) (Steam). Hook line (from
`docs/PRODUCTION_BIBLE.md` §6): *"Blackout city. You are the grid engineer."* This file does not
re-write that copy — it adds what's missing: the 11 non-master full listings (§Full listings),
locale coverage, a privacy skeleton, and the screenshot list.

## Locale coverage — EN + 12

Matches `SettingsManager.LANGUAGES` (the 13 locales the game itself ships in — store listing
languages should track playable languages, not diverge from them). Two tiers, not conflated:

- **Full long-form listing** (description, bullets, keywords — `docs/store/play_store.md` shape):
  EN/RU masters live in `store/listing.md` and remain the source of truth (not rewritten here).
  The 11 remaining locales — es, de, fr, it, pt_BR, tr, ja, ko, zh, zh_TW, ar — are authored in
  §Full listings below: same claims and numbers as the master, Keeper voice, ≤1200 characters
  each, glossary-locked to `data/i18n/<locale>.json`. ASO tags for those locales stay in
  `store/listing.md`'s generated block and are not duplicated here.
- **Short description** (≤80 chars, the line shown in search results before a user opens the
  listing page): all 13 done below — small enough to translate carefully at this pass without
  guessing at nuance a longer passage would risk.

| Locale | Short description (≤80 chars) |
|---|---|
| en | Restore the light. Stealth horror FPS where every streetlight is life. |
| ru | Верни свет. Стелс-хоррор от первого лица, где каждый фонарь — жизнь. |
| es | Restaura la luz. Terror sigiloso en primera persona donde cada farola es vida. |
| de | Bring das Licht zurück. Stealth-Horror, in dem jede Laterne Leben bedeutet. |
| fr | Rallume la lumière. Horreur furtive où chaque réverbère est une vie. |
| it | Riaccendi la luce. Horror stealth dove ogni lampione è vita. |
| pt_BR | Restaure a luz. Terror furtivo onde cada poste é vida. |
| tr | Işığı geri getir. Her sokak lambası bir can taşıyan gizlilik korkusu. |
| ja | 灯りを取り戻せ。一つ一つの街灯が命になるステルスホラー。 |
| ko | 빛을 되찾아라. 모든 가로등이 생명인 스텔스 호러. |
| zh | 重燃光明。每一盏路灯都是生命的潜行恐怖游戏。 |
| zh_TW | 重燃光明。每一盞路燈都是生命的潛行恐怖遊戲。 |
| ar | أعد النور. رعب تسللي حيث كل عمود إنارة هو حياة. |

Long-form listings for es/de/fr/it/pt_BR/tr/ja/ko/zh/zh_TW/ar (11 locales) are authored in
§Full listings below — that dev-remaining note is closed. Still open, and not claimed done here:
a native spot-check of the 11 authored listings before submission (the same review gate the short
descriptions carry).

## Privacy policy skeleton

No `docs/store/PRIVACY.md` or published policy page exists yet — `play_store.md`'s own Data Safety
section already flags this as a submission blocker ("Privacy policy URL: TODO — publish a policy
page"). Skeleton, grounded in the game's actual data footprint (verified this session — no
analytics SDK, no account system found in `scripts/`):

```
# Privacy Policy — THE LAST STREETLIGHT

Effective date: <fill in at publish>

This game does not collect, store, or transmit personal data to us or any third party in its
current build.

- Save data stays on your device (local file, never uploaded).
- Local-network co-op only connects to devices on the same LAN you explicitly join — no data
  leaves your network.
- [IF AppLovin MAX ad SDK key is live at ship time: this build shows ads via AppLovin MAX, which
  may collect an advertising identifier and usage data per their own policy — link AppLovin's
  privacy policy here and disclose this in the Play Data Safety section too.]
- Contact: <owner email/support address>
```

This is a skeleton, not a filed policy — the owner fills in the effective date, contact, and the
AppLovin bracket (delete it if shipping without ads; keep and link if the real SDK key is in by
launch — see `docs/store/HUMAN_CHECKLIST.md`).

## 8-shot screenshot list

Grounded in the actual pillars (`docs/PRODUCTION_BIBLE.md` §1: light-vs-dark, noise/visibility
stealth, power-restoration-as-reward) and the real district roster (11 districts, verified in
`scripts/world/district_layouts.gd`: suburbs, residential, park, school, industrial, substation,
power_station, + 4 more):

1. **Dark district, pre-restoration** — cold ambient, no streetlights, player's flashlight cone as
   the only warm light source (pillar 1, primary hook image).
2. **Same district, post-restoration** — streetlights lit, warm ambient shift (the "reward" beat,
   pillar 3) — pairs with #1 as a before/after.
3. **Stealth moment** — player in a flashlight cone's edge, an enemy mid-patrol, noise-radius
   readable from the HUD (pillar 2 — sells "simulation, not a meter").
4. **Substation/industrial district** — mechanical/electrical visual variety, distinct from the
   suburban shots.
5. **City map / district-power overview screen** (`city_map.gd`'s hex district-stage art) — shows
   scope (multiple districts, progress state) in one UI shot.
6. **Combat/encounter beat** — one of the 7 monster types, framed to read as tense not gory (PEGI
   16 per `docs/PRODUCTION_BIBLE.md` §6 — avoid a shot that reads as the rating's ceiling).
7. **A puzzle/interior/quest beat** — school or park district interior, shows non-combat variety.
8. **HUD/inventory or photo-mode shot** — sells the systems (health/stamina/battery bars, inventory,
   or the existing photo-mode feature from `docs/PRODUCTION_BIBLE.md`'s "already done" list).

Capture mechanics (windowed, owner-approved per this run's constraints) are P5's job, not this
doc's — this is the shot list P5 executes against. Machine-readable shot ids, framing and English
gallery captions for the capture plan: `store/screens_spec/shotlist.json` (keyed to
`store/screenshot-plan-detailed.md` §3 gallery + §7 phone shots).

## Full listings — 11 authored locales

Authored for the 11 locales that had only a short description: **es, de, fr, it, pt_BR, tr, ja,
ko, zh, zh_TW, ar**. EN and RU keep the master full description in
[store/listing.md](../store/listing.md) — byte-untouched, still the source of truth. Aims:

- **Same claims, same numbers as the master** — 11 districts, 12 enemy types, 5 endings,
  13 languages, 5 adaptive music layers, 30 daily challenges, 31 achievements, New Game+,
  crafting/workbench, noise-and-visibility stealth, offline, no paid content, touch + PC share
  one save file. Nothing invented; nothing unbacked added.
- **Keeper voice** — terse, second person, archaic lean, ellipses, no exclamation marks.
  The hook line is deliberately the same hook as the master (`docs/PRODUCTION_BIBLE.md` §6).
- **≤1200 characters each** — this doc's own budget (the Play description field allows 4000).
  Store-friendly line breaks: hook line, three short paragraphs, one bullet block, closer.
- **Glossary-locked** — every cited term is the shipped `data/i18n/<locale>.json` string
  (3 terms per locale, listed below). No new vocabulary was coined for store text.

| locale | full listing | chars (this doc's budget: 1200) |
|---|---|---|
| en | master — `store/listing.md` §Full description, byte-untouched | 1732 (master, pre-budget) |
| ru | master — `store/listing.md` §Full description, byte-untouched | 1697 (master, pre-budget) |
| es | §es below — authored this pass | 1133 |
| de | §de below — authored this pass | 1125 |
| fr | §fr below — authored this pass | 1199 |
| it | §it below — authored this pass | 1147 |
| pt_BR | §pt_BR below — authored this pass | 1089 |
| tr | §tr below — authored this pass | 1005 |
| ja | §ja below — authored this pass | 508 |
| ko | §ko below — authored this pass | 586 |
| zh | §zh below — authored this pass | 415 |
| zh_TW | §zh_TW below — authored this pass | 416 |
| ar | §ar below — authored this pass | 864 |

The two masters sit above the 1200-char budget this doc uses for new copy; they are the shipped
store text and are deliberately left as they are. EN stays the source of truth for every locale.

### Glossary lock — 3 shipped terms per locale

Each term is quoted verbatim from `data/i18n/<locale>.json` and appears (case-insensitively;
inflected only where the locale's grammar demands it) in that locale's listing below.

- **es** — `TIP_1` «Tu linterna es tu única aliada.» · `WORKBENCH_TITLE` «Banco de trabajo» · `ONBOARD_04_CAPTION` «Cada farola encendida ilumina la calle y aleja el peligro.»
- **de** — `TIP_1` «Deine Taschenlampe ist dein einziger Verbündeter.» · `WORKBENCH_TITLE` «Werkbank» · `TIP_3` «Jeder Bezirk hat seinen eigenen Rhythmus.»
- **fr** — `TIP_1` «Votre lampe torche est votre seule alliée.» · `WORKBENCH_TITLE` «Établi» · `TIP_3` «Chaque district a son propre rythme.»
- **it** — `TIP_1` «La tua torcia è la tua unica alleata.» · `WORKBENCH_TITLE` «Banco da lavoro» · `TIP_3` «Ogni distretto ha il suo ritmo.»
- **pt_BR** — `TIP_1` «Sua lanterna é sua única aliada.» · `WORKBENCH_TITLE` «Bancada» · `TIP_3` «Cada distrito tem seu próprio ritmo.»
- **tr** — `HINT_FLASHLIGHT` «F — el feneri. Işık pili tüketir ama gölgeleri korkutur» · `WORKBENCH_TITLE` «Tezgâh» · `TIP_3` «Her bölgenin kendi ritmi vardır.»
- **ja** — `TIP_1` «懐中電灯だけがあなたの味方だ。» · `WORKBENCH_TITLE` «作業台» · `TIP_3` «それぞれの地区には固有のリズムがある。»
- **ko** — `TIP_1` «손전등만이 당신의 유일한 동맹이다.» · `WORKBENCH_TITLE` «작업대» · `TIP_3` «각 구역마다 고유한 리듬이 있다.»
- **zh** — `TIP_1` «手电筒是你唯一的盟友。» · `WORKBENCH_TITLE` «工作台» · `TIP_3` «每个区域都有自己的节奏。»
- **zh_TW** — `TIP_1` «手電筒是你唯一的盟友。» · `WORKBENCH_TITLE` «工作臺» · `TIP_3` «每個區域都有自己的節奏。»
- **ar** — `menu_subtitle` «ناجٍ في ليلٍ أبدي. أعد النور إلى المدينة.» · `TIP_1` «مصباحك هو حليفك الوحيد.» · `WORKBENCH_TITLE` «طاولة العمل»

### Re-runnable static check

Paste from the repo root — green means 11/11 authored, within budget, no exclamation marks,
every listing non-English, every cited term present in both `data/i18n` and the listing.

```python
import json, pathlib, re

doc = pathlib.Path('docs/STORE_KIT.md').read_text(encoding='utf-8')
# Parse the budget-tagged per-locale headings only (robust against this snippet
# itself containing the section title).
blocks = dict(re.findall(r'^### (\w+) — [^\n]*\(\d+/1200\)\n\n```\n(.*?)\n```',
                        doc, re.S | re.M))
CITED = {  # locale -> (i18n key, shipped term); all three cited in the locale's block above
    'es': [('TIP_1', 'linterna'), ('WORKBENCH_TITLE', 'Banco de trabajo'),
           ('ONBOARD_04_CAPTION', 'farola')],
    'de': [('TIP_1', 'Taschenlampe'), ('WORKBENCH_TITLE', 'Werkbank'), ('TIP_3', 'Bezirk')],
    'fr': [('TIP_1', 'lampe torche'), ('WORKBENCH_TITLE', 'Établi'), ('TIP_3', 'district')],
    'it': [('TIP_1', 'torcia'), ('WORKBENCH_TITLE', 'Banco da lavoro'), ('TIP_3', 'distretto')],
    'pt_BR': [('TIP_1', 'lanterna'), ('WORKBENCH_TITLE', 'Bancada'), ('TIP_3', 'distrito')],
    'tr': [('HINT_FLASHLIGHT', 'el feneri'), ('WORKBENCH_TITLE', 'Tezgâh'), ('TIP_3', 'bölge')],
    'ja': [('TIP_1', '懐中電灯'), ('WORKBENCH_TITLE', '作業台'), ('TIP_3', '地区')],
    'ko': [('TIP_1', '손전등'), ('WORKBENCH_TITLE', '작업대'), ('TIP_3', '구역')],
    'zh': [('TIP_1', '手电筒'), ('WORKBENCH_TITLE', '工作台'), ('TIP_3', '区域')],
    'zh_TW': [('TIP_1', '手電筒'), ('WORKBENCH_TITLE', '工作臺'), ('TIP_3', '區域')],
    'ar': [('menu_subtitle', 'النور'), ('TIP_1', 'مصباح'), ('WORKBENCH_TITLE', 'طاولة العمل')],
}

assert sorted(blocks) == sorted(CITED), sorted(blocks)          # 11/11 authored
assert len(re.findall(r'^\| (?:en|ru) \| master — .*\(master, pre-budget\) \|$',
                        doc, re.M)) == 2, 'ledger must carry the en+ru masters'  # 13/13
for loc, text in blocks.items():
    i18n = json.load(open(f'data/i18n/{loc}.json', encoding='utf-8'))
    assert len(text) <= 1200, (loc, len(text))
    assert not re.search(r'[!！]', text), loc
    assert any(ord(c) > 127 for c in text), loc                 # not left in English
    for key, term in CITED[loc]:
        assert term in i18n[key], (loc, key)
        assert term.casefold() in text.casefold(), (loc, term)
print('full-listings gate: OK — 13/13 (2 masters + 11 authored), <=1200 chars, glossary-locked')
```

### es — Español (1133/1200)

```
LA CIUDAD A OSCURAS. TÚ ERES EL INGENIERO DE LA RED.

Nadie escribió el final. La luz se fue una vez y no volvió; el «Proyecto
Arquitecto» guarda el porqué. Te queda una linterna... y una batería que
se apaga. Caminarás distrito a distrito, calle a calle, hasta devolverle
a la ciudad lo que le falta.

Once distritos. Una sola ciudad. Ninguna pantalla de carga. Lo que salvas
se queda encendido: las calles frías delante, las farolas cálidas
detrás... esa es la forma entera del juego.

Linterna: tu arma, tus ojos, tu sentencia. Cada haz te delata.

LO QUE HAY DENTRO
- 11 distritos encadenados — un mapa continuo
- 12 clases de enemigos, con sus sentidos y sus debilidades
- 5 finales, según cuánta ciudad y cuánta verdad devuelvas
- Sigilo de ruido y visibilidad, no de medidor
- Banco de trabajo y fabricación para mejorar la linterna
- Música adaptativa de 5 capas
- 30 desafíos diarios, 31 logros y New Game+ después de los créditos
- 13 idiomas

TÁCTIL: joystick virtual y botones. PC: WASD y ratón — la misma partida.
Sin conexión, sin cuenta, sin contenido de pago. La ciudad entera desde el
primer día... y la noche, tuya.
```

### de — Deutsch (1125/1200)

```
DIE STADT IM BLACKOUT. DU BIST DER NETZINGENIEUR.

Keiner schrieb das Ende auf. Das Licht ging aus und kam nicht wieder; das
„Architekt-Projekt“ behält das Warum. Dir bleibt eine Taschenlampe... und
eine Batterie, die endet. Du gehst Bezirk für Bezirk, Straße für Straße,
bis die Stadt zurückbekommt, was ihr fehlt.

Elf Bezirke. Eine Stadt. Kein Ladebildschirm. Was du rettest, bleibt
erleuchtet: kalte Straßen vor dir, warme Laternen hinter dir... das ist
die ganze Gestalt des Spiels.

Taschenlampe: Waffe, Augen, Urteil. Jeder Strahl verrät dich.

WAS DRIN IST
- 11 verbundene Bezirke — eine durchgehende Karte
- 12 Gegnerarten, jede mit eigenen Sinnen und Schwächen
- 5 Enden, je nachdem wie viel Stadt und Wahrheit du birgst
- Stealth über Lärm und Sicht, nicht über einen Balken
- Werkbank und Basteln für deine Taschenlampe
- Adaptive Musik in 5 Schichten
- 30 Tagesaufgaben, 31 Erfolge und New Game+ nach dem Abspann
- 13 Sprachen

TOUCH: virtueller Stick und Tasten. PC: WASD und Maus — dieselbe Partie.
Ohne Netz, ohne Konto, ohne Bezahlinhalte. Die Stadt ist vom ersten Tag an
ganz da... und die Nacht gehört dir.
```

### fr — Français (1199/1200)

```
LA VILLE DANS LE NOIR. VOUS ÊTES L'INGÉNIEUR DU RÉSEAU.

Personne n'a écrit la fin. La lumière est partie et n'est pas revenue ;
le « Projet Architecte » garde le pourquoi. Il vous reste une lampe
torche... et une batterie qui s'épuise. Vous irez de district en district,
de rue en rue, jusqu'à rendre à la ville ce qui lui manque.

Onze districts. Une seule ville. Aucun écran de chargement. Ce que vous
sauvez reste éclairé : rues froides devant, lampadaires chauds
derrière... c'est toute la forme du jeu.

Lampe torche : votre arme, vos yeux, votre sentence. Chaque faisceau
vous trahit.

CE QU'IL Y A DEDANS
- 11 districts reliés — une carte continue
- 12 sortes d'ennemis, avec leurs sens et leurs faiblesses
- 5 fins, selon la ville et la vérité que vous rapportez
- Furtivité par le bruit et la visibilité, non par une jauge
- Établi et artisanat pour améliorer votre lampe torche
- Musique adaptative en 5 couches
- 30 défis quotidiens, 31 succès et un New Game+ après le générique
- 13 langues

TACTILE : joystick virtuel et boutons. PC : WASD et souris — la même
partie. Hors ligne, sans compte, sans contenu payant. La ville est entière
dès le premier jour... et la nuit vous appartient.
```

### it — Italiano (1147/1200)

```
LA CITTÀ AL BUIO. TU SEI L'INGEGNERE DELLA RETE.

Nessuno ha scritto la fine. La luce se n'è andata e non è tornata; il
«Progetto Architetto» custodisce il perché. Ti resta una torcia... e una
batteria che finisce. Andrai distretto per distretto, via per via, finché
la città non riavrà ciò che le manca.

Undici distretti. Una città sola. Nessuna schermata di caricamento.
Quello che salvi resta illuminato: strade fredde davanti, lampioni caldi
dietro... è tutta la forma del gioco.

Torcia: la tua arma, i tuoi occhi, la tua condanna. Ogni fascio ti
tradisce.

COSA C'È DENTRO
- 11 distretti collegati — una mappa continua
- 12 specie di nemici, con i loro sensi e le loro debolezze
- 5 finali, secondo quanta città e quanta verità riporti
- Furtività fatta di rumore e visibilità, non di una barra
- Banco da lavoro e creazione per migliorare la torcia
- Musica adattiva su 5 livelli
- 30 sfide giornaliere, 31 obiettivi e New Game+ dopo i titoli
- 13 lingue

TOUCH: joystick virtuale e pulsanti. PC: WASD e mouse — la stessa partita.
Offline, senza account, senza contenuti a pagamento. La città è intera dal
primo giorno... e la notte è tua.
```

### pt_BR — Português (BR) (1089/1200)

```
A CIDADE NO ESCURO. VOCÊ É O ENGENHEIRO DA REDE.

Ninguém escreveu o fim. A luz se foi e não voltou; o «Projeto Arquiteto»
guarda o porquê. Resta uma lanterna... e uma bateria que termina. Você vai
distrito por distrito, rua por rua, até a cidade receber de volta o que
lhe falta.

Onze distritos. Uma só cidade. Nenhuma tela de carregamento. O que você
salva fica aceso: ruas frias à frente, postes quentes atrás... essa é toda
a forma do jogo.

Lanterna: sua arma, seus olhos, sua sentença. Cada feixe te denuncia.

O QUE VEM DENTRO
- 11 distritos encadeados — um mapa contínuo
- 12 espécies de inimigos, com seus sentidos e fraquezas
- 5 finais, conforme quanta cidade e quanta verdade você recupera
- Furtividade por ruído e visibilidade, não por medidor
- Bancada e fabricação para melhorar sua lanterna
- Música adaptativa em 5 camadas
- 30 desafios diários, 31 conquistas e New Game+ após os créditos
- 13 idiomas

TOQUE: joystick virtual e botões. PC: WASD e mouse — o mesmo save. Sem
conexão, sem conta, sem conteúdo pago. A cidade inteira desde o primeiro
dia... e a noite é sua.
```

### tr — Türkçe (1005/1200)

```
ŞEHİR KARANLIKTA. SEN ŞEBEKE MÜHENDİSİSİN.

Sonu kimse yazmadı. Işık bir kez gitti ve dönmedi; «Mimar Projesi» nedenini
saklıyor. Elinde bir el feneri kalır... ve tükenen bir pil. Bölge bölge,
sokak sokak yürürsün; şehir eksiğini geri alana kadar.

On bir bölge. Tek şehir. Yükleme ekranı yok. Kurtardığın şey yanık kalır:
önde soğuk sokaklar, arkanda sıcak sokak lambaları... oyunun bütün biçimi
bu.

El feneri: silahın, gözün, hükmün. Her huzme seni ele verir.

İÇİNDE NE VAR
- 11 bağlı bölge — kesintisiz tek harita
- 12 düşman çeşidi; her birinin kendi duyuları ve zayıflıkları
- Şehirden ve gerçekten ne kadarını kurtardığına göre 5 son
- Gizlilik ses ve görünürlükle işler, bir ölçekle değil
- El fenerini geliştirmek için Tezgâh ve üretim
- 5 katmanlı uyarlanabilir müzik
- 30 günlük görev, 31 başarım ve jenerikten sonra New Game+
- 13 dil

DOKUNMATİK: sanal joystick ve düğmeler. PC: WASD ve fare — aynı kayıt.
Çevrimdışı, hesapsız, ücretli içerik yok. Şehir ilk günden tamam... ve gece
senindir.
```

### ja — 日本語 (508/1200)

```
街は闇に沈んだ。あなたは電力網の技師だ。

終わりを書いた者はいない。光は一度消えて、戻らなかった。「建築家計画」は
理由を抱えたままだ。残るのは懐中電灯一つ…そして尽きかけの電池。
地区から地区へ、通りから通りへ。足りないものを街に返すまで、歩き続ける。

十一の地区。ひとつの街。読み込み画面はない。救った場所は灯ったままだ。
手前の冷たい道、背後に残る暖かい街灯…それがこのゲームの全体だ。

懐中電灯は武器であり、目であり、判決でもある。光を当てるたび、居場所を知られる。

中身
- 11のつながった地区――途切れない一枚の地図
- 12種の敵。それぞれに感覚と弱点がある
- 街と真実、どこまで取り戻すかで決まる5つの結末
- 隠密は物音と視認性で決まる。検知メーターではない
- 作業台と製作で懐中電灯を強化
- 5層の適応型音楽
- 30のデイリーチャレンジ、31の実績、エンディング後のNew Game+
- 13言語

タッチ：バーチャルスティックとボタン。PC：WASDとマウス、同じセーブで。
オフライン、アカウント不要、課金要素なし。街は初日から全部そこにある…
そして夜はあなたのものだ。
```

### ko — 한국어 (586/1200)

```
도시는 어둠에 잠겼다. 당신은 전력망 기술자다.

끝을 쓴 사람은 없다. 빛은 한 번 꺼져 돌아오지 않았고, 「건축가 계획」은
이유를 품은 채 침묵한다. 남은 것은 손전등 하나… 그리고 닳아가는 배터리.
구역에서 구역으로, 거리에서 거리로. 도시가 잃은 것을 돌려줄 때까지 걷는다.

열한 개의 구역. 하나의 도시. 로딩 화면은 없다. 구한 곳은 계속 켜져 있다.
앞의 차가운 거리, 뒤에 남은 따뜻한 가로등… 그것이 이 게임의 전부다.

손전등은 무기이자 눈이며 판결이다. 빛을 비출 때마다 위치가 드러난다.

안에 있는 것
- 11개 연결된 구역 — 끊김 없는 하나의 지도
- 12종의 적, 저마다의 감각과 약점
- 도시와 진실을 얼마나 되찾았는지에 따라 갈리는 5가지 결말
- 은신은 소음과 노출로 결정된다. 탐지 게이지가 아니다
- 작업대와 제작으로 손전등 강화
- 5겹 적응형 음악
- 30개의 일일 도전, 31개의 업적, 엔딩 후 New Game+
- 13개 언어

터치: 가상 조이스틱과 버튼. PC: WASD와 마우스, 같은 세이브.
오프라인, 계정 없음, 유료 콘텐츠 없음. 도시는 첫날부터 전부 있다…
그리고 밤은 당신의 것이다.
```

### zh — 简体中文 (415/1200)

```
城市沉入黑暗。你是电网工程师。

没有人写下结局。光闪过一次，再没回来；「建筑师计划」守着缘由不放。
剩下的只有一支手电筒……和一块将尽的电池。一个区域接一个区域，一条街接
一条街——直到把城市缺的那一部分还回去。

十一个区域。一座城市。没有加载画面。你救下的地方会一直亮着。
前方的冷街，背后的暖灯……这就是这款游戏的全部形状。

手电筒：武器、眼睛、判词。每一道光束都在暴露你。

内容
- 11 个相连区域——一张连续的地图
- 12 种敌人，各有各的感官与弱点
- 5 种结局，取决于你带回多少城市……以及多少真相
- 潜行靠声响与可见度，不靠侦测条
- 工作台与制作，强化你的手电筒
- 5 层自适应音乐
- 30 个每日挑战、31 项成就，以及通关后的 New Game+
- 13 种语言

触屏：虚拟摇杆与按键。PC：WASD 与鼠标，同一份存档。
离线，无账号，无付费内容。城市第一天就是完整的……夜归你所有。
```

### zh_TW — 繁體中文 (416/1200)

```
城市沉入黑暗。你是電網工程師。

沒有人寫下結局。光閃過一次，再也沒回來；「建築師計畫」守著緣由不放。
剩下的只有一支手電筒……和一塊將盡的電池。一個區域接一個區域，一條街接
一條街——直到把城市缺的那一部分還回去。

十一個區域。一座城市。沒有載入畫面。你救下的地方會一直亮著。
前方的冷街，背後的暖燈……這就是這款遊戲的全部形狀。

手電筒：武器、眼睛、判詞。每一道光束都在暴露你。

內容
- 11 個相連區域——一張連續的地圖
- 12 種敵人，各有各的感官與弱點
- 5 種結局，取決於你帶回多少城市……以及多少真相
- 潛行靠聲響與可見度，不靠偵測條
- 工作臺與製作，強化你的手電筒
- 5 層自適應音樂
- 30 個每日挑戰、31 項成就，以及通關後的 New Game+
- 13 種語言

觸控：虛擬搖桿與按鍵。PC：WASD 與滑鼠，同一份存檔。
離線，無帳號，無付費內容。城市第一天就是完整的……夜歸你所有。
```

### ar — العربية (864/1200)

```
المدينة في العتمة. أنت مهندس الشبكة.

لم يكتب أحد النهاية. ذهب الضوء مرة ولم يعد؛ و«مشروع المهندس» يحفظ السبب.
لم يبقَ معك إلا مصباح واحد… وبطارية تنفد. ستمشي حيًّا حيًّا وشارعًا
شارعًا، حتى تعيد النور إلى المدينة.

أحد عشر حيًّا. مدينة واحدة. بلا شاشات تحميل. ما تنجيه يبقى مضاءً:
شوارع باردة أمامك، وأعمدة إنارة دافئة خلفك… هذا هو شكل اللعبة كله.

المصباح: سلاحك، عينك، وحكمك. كل شعاع يكشف مكانك.

ما في الداخل
- 11 حيًّا متصلًا — خريطة واحدة متواصلة
- 12 صنفًا من الأعداء، لكلٍّ حواسه ونقاط ضعفه
- 5 نهايات بحسب ما تعيده من المدينة… ومن الحقيقة
- التخفي بالصوت والظهور، لا بمقياس
- طاولة العمل والتصنيع لتطوير مصباحك
- موسيقى تكيّفية من 5 طبقات
- 30 تحديًا يوميًا و31 إنجازًا وNew Game+ بعد النهاية
- 13 لغة

باللمس: عصا افتراضية وأزرار. على الحاسب: WASD والفأرة، والحفظة نفسها.
دون اتصال، بلا حساب، بلا محتوى مدفوع. المدينة كاملة من اليوم الأول…
والليل لك.
```

