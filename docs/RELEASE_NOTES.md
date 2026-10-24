# Release notes: Last Streetlight 1.0

Player-facing notes for the first release (store version `1.0`, version code 5, built from the head the Session 29 block of `docs/RUN_STATE.md` names). The feature list repeats the claim-checked copy of `store/listing.md`; the store's per-language "What's new" text is `store/changelog.md`.

## English

**Last Streetlight 1.0: the first release.**

The "Architect Project" disaster plunged the city into permanent night. You are a survivor with one flashlight and a fading battery, and you bring the power grid back, district by district.

- 11 districts, relit one at a time and reached from the city map; every district you restore stays lit
- 11 enemy types, each with its own senses, weaknesses and behaviour
- 5 endings, decided by how much of the city, and of the truth, you recover
- stealth built on noise and visibility, crafting, a skill tree and a workbench for the flashlight
- 6 languages: English, Russian, German, Spanish, French and Brazilian Portuguese
- no ads and no in-app purchases in this version; the game plays offline


## Русский

**Последний фонарь 1.0: первый выпуск.**

Катастрофа «Проекта Архитектор» погрузила город в вечную ночь. Вы выживший с одним фонарём и садящейся батареей, и вы возвращаете городу электричество, район за районом.

- 11 районов, которые зажигаются по одному и открываются с карты города; каждый восстановленный район остаётся освещённым
- 11 типов врагов, у каждого свои органы чувств, слабости и поведение
- 5 концовок: они зависят от того, сколько города и правды вы вернёте
- стелс на шуме и видимости, крафт, дерево навыков и верстак для фонаря
- 6 языков: английский, русский, немецкий, испанский, французский и бразильский португальский
- в этой версии нет рекламы и покупок внутри игры; игра работает без интернета


## v10.0.0 (2026-10-22)

The last light got brighter. This release is the v10.0.0-ship pass, verified and landed by the
land pass: 611 closeout checks green, a fresh signed bundle at 66.7 MiB (down from 127 MB), and the
stealth loop as it was signed off.

- Stores, cards and endings: the eleven district cards, the five ending plates and the three weapon
  renders are in the build, with the locked card variants derived from their lit twins.
- Audio: one generation of the eleven lit beds, the long one-shots on OGG, the hunted-layer music
  mix and the Master hard limiter (no clip at the sum of music, ambience and a shot).
- Readability: the window interiors and the late-evening grade of every district, the contact
  shadows under props and pickups, the weather driven by the signal payload.
- Stability: save integrity and the launch guard hold through a crash; the new vectors SECV2/6/7/8/9
  hold in the closeout.

- The damage-over-time ticks (bleed, burn, poison) no longer count as monster hits: they take their health quietly - no hurt sound, no camera shake, no 0.8 s invulnerability after every tick, and a tick inside a hit's grace window is no longer swallowed.

- The three weapon icons (pistol, rifle, shotgun) now share one hand-drawn flat style in the quick bar.
