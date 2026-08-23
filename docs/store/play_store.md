# Google Play Store listing — THE LAST STREETLIGHT

Source of truth for gameplay/scope claims: `docs/GDD.md` §1. Update this file
whenever the logline, feature list, or build config in that section changes.

## Descriptions

### Short description (EN, max 80 chars)
```
Survival horror FPS. Relight a dead city, one district at a time.
```
(67 chars)

### Short description (RU, max 80 chars)
```
Survival horror от первого лица. Верните свет в мёртвый город.
```

### Full description (EN, max 4000 chars)
```
THE LAST STREETLIGHT

The city has fallen into an endless night after the "Architect Project"
disaster. You're a survivor with one flashlight and a fading battery.
Restore the power grid district by district, and the streets light up
behind you — safer, but never safe.

Light is everything here:
• A RESOURCE — your flashlight runs on battery you have to manage and craft
  for.
• A WEAPON — some things that hunt you in the dark can't survive a beam of
  light.
• NAVIGATION — lit streets mark the path you've already made safe.
• A REWARD — every district you restore pushes the darkness back for good.

FEATURES
- Single continuous city map across 11 districts — no procedural filler,
  no loading-screen level select.
- Stealth-first survival: manage noise and visibility, or fight when you
  have to.
- A roster of enemies with distinct behavior, weaknesses, and status
  effects (bleed, burn, poison, stun) — learn them or avoid them.
- Crafting, upgrades, and an equipment system (head/body/legs/holster/
  backpack slots).
- Five endings determined by how much of the city — and how much of the
  truth — you actually recover.
- Fully offline. No always-on connection required for the single-player
  campaign; optional local-network co-op.
- 13 languages.
- 8-12 hours for one ending, 15+ hours to see them all.

Bring a working flashlight. You're going to need the muscle memory.
```

### Full description (RU, max 4000 chars)
```
THE LAST STREETLIGHT («Последний фонарь»)

Город погружён в вечную ночь после катастрофы «Проект Архитектор». Вы —
выживший с одним фонариком и батареей, которая никогда не заряжена
настолько, насколько хочется. Восстанавливайте электросеть район за
районом — и улицы позади вас зажигаются. Безопаснее. Но не безопасно.

Свет здесь — это всё:
• РЕСУРС — батарея фонарика требует бережного расхода и крафта запасных.
• ОРУЖИЕ — то, что охотится на вас в темноте, не переживёт луч света.
• НАВИГАЦИЯ — зажжённые улицы отмечают путь, который вы уже сделали
  безопасным.
• НАГРАДА — каждый восстановленный район отодвигает тьму навсегда.

ОСОБЕННОСТИ
- Единая непрерывная карта города из 11 районов — без процедурной генерации
  и экранов загрузки между уровнями.
- Стелс в приоритете: управляйте шумом и заметностью или вступайте в бой,
  когда иначе нельзя.
- Ростер врагов с разным поведением, слабостями и статусами (кровотечение,
  ожог, отравление, оглушение) — изучайте их или избегайте.
- Крафт, апгрейды и система экипировки (голова/тело/ноги/кобура/рюкзак).
- Пять концовок, зависящих от того, сколько города — и сколько правды —
  вы на самом деле вернули.
- Полностью офлайн: одиночная кампания не требует постоянного соединения;
  опциональный локальный мультиплеер по LAN.
- 13 языков.
- 8-12 часов на одну концовку, 15+ часов на все.

Возьмите с собой рабочий фонарик. Мышечная память пригодится.
```

## Tags / category
- Category: **Games → Action** (secondary: Adventure)
- Tags: survival horror, FPS, stealth, atmospheric, single-player, offline,
  crafting, exploration

## Rating notes (IARC questionnaire)
Expected outcome: **PEGI 12 / ESRB Teen** — see `docs/release_checklist.md`.
- Fantasy violence against non-human/undead-style enemies (no gore slider).
- Horror/dark themes: sustained tension, jump-scare-adjacent enemy reveals,
  a "the disaster was deliberate" narrative thread (Truth ending).
- No sexual content, no gambling, no real-money purchases at launch (see
  Data Safety below — `RewardsManager`/ad-based rewards exist behind an
  `AdService` interface but ship with a `SimulatedAdProvider` stub; flip
  this section once a real ad SDK is integrated, see `docs/ANDROID_BUILD.md`
  "Known limitations").
- No user-generated content, no location sharing, no chat with strangers
  (LAN co-op only, no matchmaking).

## Data Safety (placeholder — confirm before submission)
- **No personal data collected.** The game is offline-first; there is no
  account system and no analytics SDK in the current build.
- **No data shared with third parties.**
- Local-network multiplayer (`scripts/net/lan_network.gd`) only ever talks
  to devices on the same LAN the player explicitly connects to — no
  telemetry leaves the device.
- Privacy policy URL: **TODO — publish a policy page and paste the URL
  here before submitting.** Until then, use a placeholder policy that
  states "no data collected" (matches the actual current build) rather
  than a generic template that overclaims.

## Build steps
Full walkthrough: `docs/ANDROID_BUILD.md`. Summary for this listing:
1. `powershell -ExecutionPolicy Bypass -File tools/make_keystore.ps1` once,
   for local debug builds. **Generate a separate release keystore** before
   the first Play Store upload and store it outside the repo.
2. Export via Godot editor (Project → Export → **Android** preset) or
   headless: `godot --headless --export-release "Android" build/TLS.aab`.
   Play Store requires **AAB**, not APK (`docs/release_checklist.md`
   "Build Format").
3. Confirm `export_presets.cfg`: `min_sdk=29`, `target_sdk=34`,
   `package/unique_name="com.tls.game"`, launcher icons and
   `permissions/internet=true` (LAN co-op) are all present — these are
   already committed in this repo.
4. Run `bash tools/check.sh` clean before every submission build.
5. Work through `docs/release_checklist.md` top to bottom (Data Safety
   form, IARC questionnaire, ASO assets, versionCode bump) before
   uploading to a testing track.
