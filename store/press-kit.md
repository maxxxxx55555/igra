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
  same game, same save file — export/import it between devices, no account, no server.
  Fully offline; no paywalled content.

### Content numbers (all verified against shipped data, 2026-09-13 / RC FINAL v2)

| # | What | Source of truth |
|---|---|---|
| 11 | Connected districts, one continuous city, zero loading screens | `data/districts/*.tres` (11 files), `docs/CONTENT_PIPELINE_AUDIT.md` §9 |
| 88 | Lore notes (8 per district × 11) | `content/districts/*/lore_notes.json` (recounted 2026-09-13: 8 × 11 = 88) |
| 13 | Fully localized languages at launch | `data/i18n/*.json` (ar, de, en, es, fr, it, ja, ko, pt_BR, ru, tr, zh, zh_TW); `tools/i18n_audit.py` → MISSING: 0 (`docs/artifacts/final_gate_report.md`) |
| 31 | Achievements (20 core, incl. secret ones, + 11 district-full) | `scripts/systems/achievements_manager.gd` ach_01–ach_20 + `ach_district_*` (Batch 13, `docs/PLAYER_VISIBLE_CHANGES.md`) |
| 30 | Daily challenges (rotating templates, same for all players per UTC day; 7/30/100-day streak bonuses) | `data/daily_challenges.json` (30 templates, streak rewards verified in shipped data) |
| 12 | Enemy types, each with own senses/weaknesses (incl. the final boss) | `scripts/enemies/*_3d.gd` (12 files) + `data/monsters/*.tres` (12 files), PLAN.md §GDD-conformance table |
| 5 | Endings, decided by how much city + truth you recover | `scripts/systems/endings_manager.gd` (`Ending` enum) + `tools/qa_sim/endings_sim.py` PASS — all 5 reachable (`docs/artifacts/final_gate_report.md`) |
| 4 | Skill-tree branches | `tools/qa_sim/balance_sim.py` PASS (`docs/artifacts/final_gate_report.md`) |

### Release state, quotable (from `docs/artifacts/final_gate_report.md`, 2026-09-13)

- Static gates: **10/10 green** (`tools/check.sh --static`, incl. 53/53 flow-wiring checks).
- Engine gates headless: **22/23 green** — the one fail is a pre-existing, documented
  headless combat-smoke timeout (`docs/KNOWN_ISSUES.md`), not a regression.
- Save system: **50-mutant corruption fuzz, export/import, backup-rotation, forgery
  checks all PASS**; saves are HMAC-signed (was plain checksum) — `docs/artifacts/security_report.md`.
- Autoplay bot completes the **11/11 district spine in the clear majority of runs**
  (real combat, real revives, boss engagement).
- Time-to-win window per balance sim: **3–6 hours** per run; 5 endings + New Game+ for replay.

- **Kit contents (paths verified on disk 2026-09-13):**
  `store/trailer/presskit_1600x900.png` (header),
  `store/trailer/still_first_light_1920x1080.png`,
  `store/trailer/still_first_ending_1920x1080.png`,
  `store/trailer/still_grid_cascade_1920x1080.png` (3 wow-moment stills, 1920×1080),
  `store/trailer/shorts_silhouette_1080x1920.png` (vertical),
  `store/trailer/hero_first_restore_1920x1080.png`,
  `store/trailer/hero_grid_cascade_1920x1080.png`,
  `store/trailer/hero_reactor_room_1920x1080.png`,
  `store/trailer/hero_shorts_cut_1080x1920.png` (full-post-fx masters, 2026-09-12 pass —
  these carry the exact shipped cinematic stack: district LUT + bloom + vignette + chroma + grain),
  `store/feature-graphic.png` (1024×500), `store/icon-512.png`, `store/icon-adaptive/`,
  `store/screenshots/` (8 upload-ready 1920×1080 EN shots),
  `store/listing.md` (store copy, 13 locales), `store/changelog.md` (v1.0 notes).

## Review-copy instructions (for the owner)

1. Build a release APK/AAB from a clean export; smoke-test install → new game →
   first streetlight restore before sending anything.
2. Reviewers play **EN, High graphics**; suggest headphones (adaptive audio).
3. Review guide ask (not embargo, just guidance): please keep coverage to Act I
   districts for the first 2 weeks; no ending footage; the Keeper/Architect
   identity is the game's one ungoogleable — keep it that way.
4. Known-launch-facts reviewers may cite (numbers from the fact sheet above):
   11 districts, 88 lore notes, 12 enemy types, 5 endings, 31 achievements,
   30 daily challenges, 13 languages, workbench crafting, HMAC-signed
   checksum-verified saves with automatic backup recovery, offline-first with
   no account. See also the release-state block above for gate numbers.

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
Play time: 3–6 h to win (balance-sim verified) · 5 endings + New Game+ ·
31 achievements · 30 daily challenges · 13 languages · Android + PC (same save file)

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
