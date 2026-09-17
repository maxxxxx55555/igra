# Store kit

## Listing copy — reuse, don't duplicate

English listing copy already exists and is GDD-sourced:
[docs/store/play_store.md](docs/store/play_store.md) (Google Play) and
[docs/store/steam.md](docs/store/steam.md) (Steam). Hook line (from
`docs/PRODUCTION_BIBLE.md` §6): *"Blackout city. You are the grid engineer."* This file does not
re-write that copy — it adds what's missing: locale coverage, a privacy skeleton, and the
screenshot list.

## Locale coverage — EN + 12

Matches `SettingsManager.LANGUAGES` (the 13 locales the game itself ships in — store listing
languages should track playable languages, not diverge from them). Two tiers, not conflated:

- **Full long-form listing** (description, bullets, keywords — `docs/store/play_store.md` shape):
  EN only, done. Translating the full listing into 12 more locales is real professional
  translation work this doc doesn't fabricate — machine-drafted-then-native-checked, tracked as
  dev-remaining.
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

Full long-form listing translation for es/de/fr/it/pt_BR/tr/ja/ko/zh/zh_TW/ar (11 locales) remains
dev-remaining — this pass deliberately didn't rush a full-page translation at low review depth.

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
doc's — this is the shot list P5 executes against.
