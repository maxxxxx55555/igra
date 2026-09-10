# Review-response playbook — THE LAST STREETLIGHT

Ready-to-paste replies for Google Play / App Store reviews. Two languages
(EN + RU — the store-listing languages). Keep replies short, name the
concrete next step, never argue. Fill `<…>` before sending. The
**Escalation** line is for the owner, not the reviewer — it says what to
check internally and which `docs/KNOWN_ISSUES.md` entry it maps to.

House rules:
- Reply within 72 h to anything 1–3★ or mentioning a crash / lost save.
- One reply per review; don't re-reply unless they update it.
- Never promise a date. "A fix is in progress" only if it actually is.
- Bug reports → always ask for device model + Android/iOS version + a
  step to reproduce. Route to the owner with the tag below.

---

## Class 1 — Crash / won't launch / lost save

**EN**
```
Thanks for flagging this, and sorry it hit you. This isn't the intended
behaviour. Could you tell us your device model and Android/iOS version,
and what you were doing right before it happened (booting, saving,
changing districts)? Saves are checksum-verified with an automatic
backup, so a lost slot can often be recovered — email <support@…> with
that info and we'll walk you through it.
```
**RU**
```
Спасибо, что сообщили, — так быть не должно. Напишите, пожалуйста,
модель устройства и версию Android/iOS и что происходило прямо перед
сбоем (запуск, сохранение, переход между районами). Сохранения
проверяются контрольной суммой и имеют резервную копию, поэтому
потерянный слот часто удаётся восстановить — напишите на <support@…>,
и мы поможем.
```
**Escalation (owner):** reproduce on a matching device; check the save
envelope path in `scripts/core/save_system.gd` (`_read_envelope` /
`_read_validated`) and the boot flow (`boot_check_scene.tscn`). Not a
known open issue — `KNOWN_ISSUES.md` records the save round-trip and
boot-flow as passing gates. If it reproduces, it's a new P0.

## Class 2 — Performance: lag, stutter, battery drain, heat

**EN**
```
Thanks — that's useful. Which device and roughly how many districts had
you restored when it started? Try Settings → Graphics → lower the
preset and cap the frame rate; the lit districts add real-time lights,
and that screen trades them back for smoothness. Let us know if that
helps or not — device details make it much easier to chase.
```
**RU**
```
Спасибо, это полезно. Какое устройство и сколько примерно районов было
восстановлено, когда началось? Попробуйте Настройки → Графика →
снизить пресет и ограничить частоту кадров: освещённые районы добавляют
динамический свет, и этот экран разменивает его на плавность. Напишите,
помогло или нет, — детали устройства сильно ускорят разбор.
```
**Escalation (owner):** `KNOWN_ISSUES.md` "Draw calls: 234 measured vs
GDD's <200 (D1) / <350 (D11)" — D11 target is met, D1 is not, and the
distance-fade guard on streetlight + pickup lights already caps active
lights (~18/frame D1 per `tools/qa_sim/drawcall_estimate.py`). Still
pending: one owner `perf_check_scene.tscn --windowed` run for the real
`RENDER_TOTAL_DRAW_CALLS_IN_FRAME` on the reported device tier. If a
low-end tier is consistently bad, that's a P1 (concurrent
monster/pickup budget or a material merge).

## Class 3 — Stuck / can't progress / too hard / "I'm lost"

**EN**
```
No spoilers, but: every district can be finished with parts found inside
it — look for the distribution board / cable box and the three repair
parts (cable, fuse, transistor). The map screen shows which district is
next. Stealth is about noise and line of sight, not a meter: stay out of
the light you don't control, and keep your own flashlight off when you
can. If a specific spot has you stuck, tell us which district and we'll
give a nudge.
```
**RU**
```
Без спойлеров: каждый район проходится деталями, которые есть внутри
него, — ищите распределительный щит / кабельный шкаф и три детали
(кабель, предохранитель, транзистор). Экран карты показывает следующий
район. Стелс — это шум и линия взгляда, а не индикатор: держитесь вне
чужого света и по возможности выключайте свой фонарь. Если застряли в
конкретном месте — напишите район, подскажем.
```
**Escalation (owner):** confirm the district in question still spawns its
repair parts — `scripts/world/district_loot.gd` `REPAIR_PARTS` (two of
each per district) via `DistrictLoot.populate()`. This path regressed
once (fixed `f3bd1e3`: `LOOT_SCRIPT.populate` didn't dispatch → zero
loot); `tools/qa_sim/headless_suite` P2 now guards it. If a player
genuinely has no parts, treat as P0 and re-run the suite.

## Class 4 — Ads / monetization complaint ("too many ads", "pay to win")

**EN**
```
To be clear on how it works: there's no paywalled content and no season
pass — every district, ending and upgrade is reachable for free. Ads are
opt-in rewarded (revive / extra battery) plus one interstitial on
district travel with a cooldown, never during combat. If you're seeing
ads at other times, that's a bug — tell us your device and when it
happened and we'll fix it.
```
**RU**
```
Как это устроено: платного контента и сезонного пропуска нет — все
районы, концовки и улучшения доступны бесплатно. Реклама — это
добровольные вознаграждаемые ролики (возрождение / доп. батарея) и один
межстраничный ролик при переходе между районами с задержкой, никогда во
время боя. Если реклама показывается в другое время — это ошибка,
напишите устройство и момент, поправим.
```
**Escalation (owner):** ad timing is enforced in `AdService` (interstitial
180 s cooldown, gated off combat) and regression-checked by
`boot_check_scene.tscn` phase 2b ("no ad before first input"). If a
review credibly reports mid-combat or pre-input ads, that's a P0
regression in `AdService`. Note the build currently ships the no-key
debug stub (no real ads) until the owner sets a live AppLovin key.

## Class 5 — Praise + feature request

**EN**
```
Thank you — genuinely glad the light-vs-dark thing landed for you.
Noting the request for <feature>. Updates are free as the city gets
built out, so it may well show up. If you have a minute, a rating helps
a small project a lot.
```
**RU**
```
Спасибо — правда рад, что контраст света и тьмы сработал для вас.
Записал пожелание про <фичу>. Обновления бесплатные по мере расширения
города, так что вполне может появиться. Если будет минута — оценка
очень помогает маленькому проекту.
```
**Escalation (owner):** log the request in `docs/PLAN.md` or
`docs/GAP_TO_IDEAL.md` (P1/P2 as appropriate). No action needed on the
review itself beyond the reply.

---

## Quick router

| Review says… | Class | Owner tag |
|---|---|---|
| "crashes", "black screen", "lost my save", "won't open" | 1 | `crash` — new P0 until reproduced |
| "lag", "stutter", "hot", "drains battery", "fps" | 2 | `perf` — `KNOWN_ISSUES` draw-calls entry |
| "stuck", "can't finish", "no parts", "too hard", "lost" | 3 | `progression` — verify `DistrictLoot.populate()` |
| "too many ads", "pay to win", "cash grab" | 4 | `ads` — `AdService` timing, usually a misunderstanding |
| 4–5★ + "please add…" | 5 | `request` — log in `GAP_TO_IDEAL.md` |
