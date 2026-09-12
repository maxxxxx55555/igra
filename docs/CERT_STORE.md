# STORE RELEASE CERTIFICATE — THE LAST STREETLIGHT (2026-09-11)

Owner: CONTENT+ASSETS+STORE agent. Scope: the six store deliverables —
`store/listing.md`, `store/press-kit.md`, `store/review-responses.md`,
`store/privacy-policy-template.md`, `store/changelog.md`, this certificate.
Method: static + script verification only (repo verification policy — no
engine GUI runs; no window opened). Every number below was produced by a
command run on the day stated, not quoted from memory.

**Verdict: PASS — 13/13 locales console-paste-ready, 0 defects.**

## 1. Character limits (Play Store hard limits)

Short description limit 80, title limit 30. Verified by
`python3 tools/gen_store_listing_locales.py --check` (GREEN) plus a
second independent parse of `store/listing.md`:

| Locale | Title | Short (real = labeled) |
|---|---|---|
| en | 20/30 | 70/80 |
| ru | 16/30 | 66/80 |
| es | 16/30 | 73/80 |
| de | 18/30 | 67/80 |
| fr | 20/30 | 71/80 |
| it | 17/30 | 71/80 |
| pt_BR | 21/30 | 63/80 |
| tr | 17/30 | 71/80 |
| ja | 5/30 | 30/80 |
| ko | 7/30 | 36/80 |
| zh | 6/30 | 30/80 |
| zh_TW | 6/30 | 30/80 |
| ar | 14/30 | 60/80 |

All 13 labeled counts equal the real `len()` of the string; 0 over limit.
All 13 shorts are hook-first (imperative hook first: "Restore the light."
/ «Верни свет.» / "Devuelve la luz." / … / "أعد النور.").

## 2. Locale parity — 13/13

For each of `en ru es de fr it pt_BR tr ja ko zh zh_TW ar` the generated
block in `store/listing.md` carries Title, Tagline, Short, Full
description (or the byte-untouched master pointer for en/ru), exactly 8
feature bullets, and an ASO-tags line. Script-verified: 13 sections
found, 0 structural failures. Titles and taglines are **byte-identical**
to the shipped in-game `data/i18n/<loc>.json` `menu_title` /
`menu_subtitle` (13/13). Three stale parity defects vs the shipped i18n
were found and fixed in this pass: es title accent (`LA ÚLTIMA FAROLA`),
fr tagline verb (`Rendez sa lumière à la ville.`), pt_BR title
(`O ÚLTIMO POSTE DE LUZ`).

## 3. EN/RU masters byte-untouched

Everything in `store/listing.md` above the `BEGIN GENERATED 13-LOCALE
BLOCK` marker (title, tagline, short, EN+RU full descriptions, EN+RU
bullets, tags, category, data-safety notes) is byte-identical to the
pre-polish state: prefix sha256
`430458f8e5ea87e529390b4b5f9805fe9607185a11115681687e6fdb756601fa`
(8 413 bytes), md5 `db68680c4ceedc2fe8fb91127001f7db` identical before
and after this pass. Master EN bullets: 8; master RU bullets: 8.

## 4. Bullets — benefit-led, 8 per locale

The 11 non-master locales' bullets were re-led benefit-first (player
outcome first, spec second): walk-anywhere-city, light-as-reward,
flashlight-trinity, survive-by-learning-the-hunters,
choose-your-ending, scavenge-craft-upgrade, music-hears-danger,
play-in-your-language. Vetted shipped vocabulary kept; all numbers
preserved (11 / 12 / 5 / 5-layer / 13). One grammar defect fixed (de:
`deine Trophäe`).

## 5. No placeholder leaks

Scanned every paste-ready field line of the generated block +
`store/changelog.md` (376 lines: Title/Tagline/Short/Full/bullets/tags):
**0** occurrences of `[…]`, `<…>`, TODO, FIXME, or "placeholder".
Deliberate fill-in fields live ONLY in non-paste-ready template regions
and are by design: `store/privacy-policy-template.md`
(`[contact email / support URL]` ×2 EN + ×2 RU — owner fills email/URL;
dates and app name pre-filled), `store/review-responses.md`
(`<support@…>`, `<name>` etc.), `store/press-kit.md` contact template
(`<APK/AAB link + expiry>` etc.). None of these is console copy.

## 6. Facts shipped in copy — all traced

| Claim in copy | Source | Status |
|---|---|---|
| 11 connected districts | `data/districts/*.tres` (11) | ✔ |
| 88 lore notes | `content/districts/*/lore_notes.json` (11×8) | ✔ |
| 13 languages | `data/i18n/*.json` (13 files) | ✔ |
| 20 achievements | `scripts/systems/achievements_manager.gd` ach_01–ach_20; GDD §21 / SUPPLEMENT §S17 | ✔ (see §8.1) |
| 30 daily challenges | `data/daily_challenges.json` (30 templates) | ✔ |
| 12 enemy types | `data/monsters/*.tres` (12) | ✔ |
| 5 endings all reachable | GDD §12.4; `docs/KNOWN_ISSUES.md` RESOLVED entry | ✔ |
| Checksum saves + backup | `scripts/core/save_system.gd` (SHA-256 envelope, `.bak` fallback, quarantine) | ✔ |

## 7. Review-support honesty

`store/review-responses.md` classes are wired to recorded truth: perf
complaints cite the ACCEPTED `KNOWN_ISSUES.md` draw-call state (D11<350
met at 234 and hard-gated; D1<200 WON'T-FIX for RC; distance-fade cull
58→18 lights); save-loss complaints cite the real
main→`.bak`→quarantine recovery chain and the fact that no open
save-loss defect is recorded (credible repro = new P0). No reply
promises a date or a guaranteed recovery.

## 8. Recorded disclosures (not defects)

1. **Achievement count:** the orchestrator brief said 31; canon says 20
   (GDD §21/S17 list exactly ach_01–ach_20, the autoloaded manager
   implements exactly those 20). Repo rule "on conflict — GDD wins":
   the press kit ships **20**. If 31 exists anywhere, it is not in this
   repository.
2. **Generator divergence:** `tools/gen_store_listing_locales.py`
   regenerates the block from its own dicts; its title/tagline sources
   are live (`data/i18n`), but its SHORT/FULL/BULLETS dicts predate the
   2026-09-11 benefit-led polish and the intro paragraph. Re-running it
   without `--check` would revert the polished bullets. Do not
   regenerate; if regeneration is ever needed, port the polished bullets
   into the generator first. (`tools/` is outside this agent's
   ownership, hence recorded here instead of fixed.)
3. **Owner TODOs before submission** (tracked in
   `docs/store/HUMAN_CHECKLIST.md`): host the privacy policy at a live
   HTTPS URL (template finalized); AppLovin disclosure must be added to
   the policy only if a live ad key ships; optional native spot-check of
   the 11 transcreated locales.

## 9. Defect ledger

0 open defects. 4 fixed this pass: es/fr/pt_BR title-tagline parity vs
shipped i18n; de `dein→deine Trophäe`.

**Certificate:** the STORE deliverables are COMPLETE and
CONSOLE-PASTE-READY at 13/13 locales: char limits hold (shorts ≤80,
titles ≤30), locale parity 13/13 with shipped in-game strings, EN/RU
masters byte-untouched, 0 placeholder leaks in paste-ready fields, 0
open defects. Known owner steps are human-checklist items (§8.3), not
copy defects.

## Reproduce

```bash
python3 tools/gen_store_listing_locales.py --check   # short<=80 + 13 sections
# master-prefix hash (must equal §3):
python3 - <<'EOF'
import hashlib, pathlib
t = pathlib.Path('store/listing.md').read_text(encoding='utf-8')
p = t[:t.index('<!-- BEGIN GENERATED 13-LOCALE BLOCK -->')]
print(hashlib.sha256(p.encode()).hexdigest(), len(p.encode()))
EOF
```
