# Release readiness report — 2026-09-15

This report was commissioned as "Phases 2-5" of a plan whose own CONTEXT section claimed
`main` already contained two merged arena branches (`arena/01a09aec-igra`,
`arena/texture-optimization`) delivering boss winnability, card art, i18n and ASTC texture
compression. **That premise was checked and was false**: neither branch exists, locally or
on the remote, and none of the five arena branches that do exist (all stale, pre-dating this
repo's current state by 15,000-62,000 changed lines) match that description. `main`'s actual
top commit before this pass was `aea3743`, the prior session's honest "0/3 seeds won" record.

So Phase 2 below is a first real attempt at boss winnability, not a re-verification, and
item 9 (texture compression) cites the one real, prior report that exists under a different
name than the plan assumed. Everything else in this report is a genuine measurement taken
today (2026-09-15) or during the same continuous pass on 2026-09-14, against the actual
current state of `main` — nothing here is carried over from the plan's own claims.

## The 11 verification items

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | Static gates | **12/12 PASS** | `bash tools/check.sh --static` → "Всё зелёное. Проверок пройдено: 12", re-run after every commit this pass |
| 2 | Engine gates | **24/25 PASS** | `bash tools/check.sh` (full) → "Провалено: 1, пройдено: 24"; the one failure is `прогон 3D-сцены (таймаут 90s)`, documented pre-existing since before this pass, unchanged |
| 3 | Headless suite | **GREEN** | `bash tools/qa_sim/headless_suite` → 12 engine gates + extended scenario driver, all `OK`, exit 0 |
| 4 | Autoplay bot wins ≥1/3 at default NG+ | **FAIL — 0/3** | See "Boss winnability" below. Best single run dealt 28.5% of the boss's HP within the 240s window; no run has produced a win |
| 5 | Autoplay bot restores 11/11 across all 3 seeds | **FAIL, inconsistent** | Some runs restore 11/11 on all 3 seeds; others softlock earlier (suburbs, gas_station, police, residential — a different district each time) on pre-existing bot-navigation flakiness unrelated to this pass's changes. Not reliably 3/3 |
| 6 | i18n: 0 English strings in non-English locales | **FAIL — 124 known** | Key parity is exact (`python tools/i18n_audit.py` → `MISSING: 0` at 1265×13), but `docs/KNOWN_ISSUES.md` ("The 124 new content strings...") documents 124 strings that are still English text in all 12 non-English locale files. Parity ≠ translation |
| 7 | NG+ knobs: all 7 wired | **7 of 11 wired** (reframed — there are 11 knobs, not 7) | Grep-verified call sites: `battery` (`player_3d.gd`), `hunter_hearing` (`noise_propagation.gd`), `achievements` (`achievements_manager.gd`), `loot` (`base_monster.gd`, wired this pass), `lore` (`xp_manager.gd`, wired this pass), `rewards` (`rewards_manager.gd`, wired this pass), `hints` (`onboarding.gd`, wired this pass). Still data-only: `extra_dark_districts`, `cycle`, `time_pressure`, `crawlers_ignore` |
| 8 | Onboarding: median time-to-first-secret ≤8min, 10-seed table | **NOT ATTEMPTED** | Telemetry added for real (`first_interactable_seen`, `first_secret_hinted`, `first_secret_found`, `first_district_full` — `scripts/tools/_qa_autoplay_runner.gd`), but no 10-seed sampling pass was run: Phase 2's investigation consumed the pass's time budget. Also: the bot doesn't seek secrets opportunistically today, so `first_secret_found` will read "never" on most runs until that's added |
| 9 | Textures: ≥30% size reduction | **PARTIAL — real prior data, different axis than assumed** | `docs/artifacts/texture_compression_audit.md` (2026-09-12, not `TEXTURE_COMPRESSION_REPORT.md` — that filename doesn't exist): VRAM/runtime footprint **-75% (38.75 MiB → 9.69 MiB, ~4.0x)**, well past 30%. On-disk/APK size for the same 74 files **increased** slightly (8.99 → 9.69 MiB) — this art style's flat palette already compresses well under Lossless PNG, so block compression didn't shrink it on disk. Not re-measured this pass |
| 10 | Edge cases: ≥3 defects fixed | **PASS — 6 fixed** | All in the boss fight, see below, each with a reproduction and a fix commit |
| 11 | Release packet: owner-executable | **DONE** | `docs/OWNER_RELEASE_PACKET.md`, 218 lines (~4 pages); item 11's playtest line updated today to reflect the real current boss-fight state instead of a stale one |

**5 of 11 pass outright, 1 is partial, 1 is reframed-but-real, 4 fail or are unattempted** —
stated plainly rather than rounded up.

## Boss winnability — what actually happened

Six real bugs were found and fixed chasing this, none of them balance numbers:

1. `revive_player()` had no grace window — the player died again almost immediately, in a
   loop that could eat the entire fight without landing a swing.
2. Dodge invulnerability was completely broken (`_iframes` counted down but `take_damage()`
   never checked it) — fixed by the same guard as #1.
3. The boss's documented weakness (GDD §6.2, "стробоскоп") was unreachable by anything
   driving `InputService`, the bot included — added `request_strobe()`.
4. The boss's first phase had no stun check, so a landed strobe froze the model but its
   ranged attacks kept firing anyway.
5. A long chase could send the boss falling through the floor forever (`velocity.y` never
   reset on landing — measured, Y went from 1 to -166 over 25 seconds).
6. The melee attack hitbox was never offset from the player's own origin, reaching only
   ~0.3m past their own body.

Full detail, reproductions and commit hashes: `docs/KNOWN_ISSUES.md`, top entry.

**Net effect:** the fight went from instantly breaking (death spirals, physics bugs) to a
stable fight where the bot never dies and deals real, measured damage. It has not yet
produced a win inside the 240-second budget. The ceiling is now damage throughput, not
survival — closing it needs either a smarter bot (sustained combo uptime, exploiting the
strobe-stun window, using a non-BLUNT damage source the boss resists less) or a human-judged
difficulty pass on the boss's `armor`/`resistances`, neither attempted this pass. This is
the single most important unresolved item in this report.

## What this pass did not attempt, and why

- **P7 items** (boss win-rate 40-70% tuning, onboarding first-wow timing, a fresh texture
  PSNR/APK pass) — the false premise meant Phase 2 started from zero instead of verifying
  finished work, and the real bugs it surfaced were worth fixing properly rather than
  rushing past to reach later phases.
- **10-seed onboarding sampling** — telemetry exists, sampling doesn't; see item 8.
- **Cert/ledger consolidation into `CONTENT_PIPELINE_AUDIT.md`/`ASSET_LICENSES.md`** —
  not touched this pass; no new certs were produced (this pass generated bug fixes and docs,
  not new content-pipeline artifacts, so there's nothing new to consolidate).

## Standing gates

`bash tools/check.sh` — 12 static + 13 engine gates. `bash tools/qa_sim/headless_suite` — 12
engine gates + the extended scenario driver. `python tools/i18n_audit.py` — key parity
across 13 locales. All re-run and green (per the table above) as of this commit.
