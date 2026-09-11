# Press kit — THE LAST STREETLIGHT

Owner: CONTENT+ASSETS+STORE agent. Send this file (or its sections) with every
review code. Spoiler ceiling: **Act I only** (districts 1–3 topic guidance);
the half-lit-city ending still is cleared, ending text/Architect identity never is.

## Fact sheet

- **Title:** The Last Streetlight / Последний фонарь
- **Tagline:** "Restore the light. Every streetlight is life." / «Верни свет. Каждый фонарь — жизнь.»
- **Genre:** Stealth-horror FPS, single-player, offline-first
- **Hook:** 11 connected districts, one continuous blackout city — every street
  you restore stays lit. The flashlight is your gun, your eyes, and your giveaway.
- **Platforms/controls:** Android (touch + double-tap dodge) and PC (WASD+mouse),
  same game, same save file. No paywalled content.

### Content numbers (all verified against shipped data, 2026-09-11)

| # | What | Source of truth |
|---|---|---|
| 11 | Connected districts, one continuous city, zero loading screens | `data/districts/*.tres` (11 files) |
| 88 | Lore notes (8 per district × 11) | `content/districts/*/lore_notes.json` |
| 13 | Fully localized languages at launch | `data/i18n/*.json` (ar, de, en, es, fr, it, ja, ko, pt_BR, ru, tr, zh, zh_TW) |
| 20 | Achievements (13 open + 7 secret) | `scripts/systems/achievements_manager.gd` ach_01–ach_20, GDD §21 / SUPPLEMENT §S17 |
| 30 | Daily challenges (rotating templates + streak rewards) | `data/daily_challenges.json` (30 templates) |
| 12 | Enemy types, each with own senses/weaknesses | `data/monsters/*.tres` (12 files) |
| 5 | Endings, decided by how much city + truth you recover | GDD §12.4 (`docs/KNOWN_ISSUES.md`: all 5 reachable — RESOLVED) |

- **Kit contents:** `store/trailer/presskit_1600x900.png` (header),
  `store/trailer/still_*.png` (3 wow-moments, 1920×1080),
  `store/trailer/shorts_silhouette_1080x1920.png` (vertical),
  `store/listing.md` (store copy, 13 locales), `store/changelog.md` (v1.0 notes).

## Review-copy instructions (for the owner)

1. Build a release APK/AAB from a clean export; smoke-test install → new game →
   first streetlight restore before sending anything.
2. Reviewers play **EN, High graphics**; suggest headphones (adaptive audio).
3. Review guide ask (not embargo, just guidance): please keep coverage to Act I
   districts for the first 2 weeks; no ending footage; the Keeper/Architect
   identity is the game's one ungoogleable — keep it that way.
4. Known-launch-facts reviewers may cite (numbers from the fact sheet above):
   11 districts, 88 lore notes, 12 enemy types, 5 endings, 20 achievements,
   30 daily challenges, 13 languages, workbench crafting, checksum-verified saves.

## Embargo note

There is **no hard embargo** — coverage may go live as soon as the review
copy arrives. The ask above is spoiler guidance, not a date gate: Act I only
for the first 2 weeks, ending footage and the Architect's identity stay
unspoiled indefinitely. State this explicitly in the outreach mail so
reviewers don't self-impose a delay that doesn't exist.

## Contact template (fill before sending)

```
Subject: Review copy — THE LAST STREETLIGHT (stealth-horror FPS)

Hi <name>,

<One line on why them: e.g. "loved your <outlet> piece on <game>.">

THE LAST STREETLIGHT is a stealth-horror FPS about bringing the light back
to a dead city: 11 connected districts, zero loading screens, and every
street you save stays lit. Tagline: "Restore the light. Every streetlight
is life."

Review build: <APK/AAB link + expiry>
Press kit (art, fact sheet, trailer stills): <this repo's store/ link or zip>
Play time: <X>h campaign · 5 endings · 13 languages · Android + PC

Only ask: please keep coverage to the first districts for 2 weeks and keep
the endings unspoiled. Happy to do a <written/video> interview any time.

Thanks,
<your name> — <role>
<email> · <socials/Discord>
```

## Outreach checklist

- [ ] Contact template filled (build link, kit link, play time).
- [ ] Kit zip contains the 5 `store/trailer/` masters + this file.
- [ ] Spoiler ceiling stated in the mail (Act I / no endings).
- [ ] Follow-up date set (+7 days, one nudge max before launch).
