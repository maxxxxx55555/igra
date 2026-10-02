# TZ compliance — live ledger (C4 TZ-CLOSE)

Source: `docs/TZ_COMPLIANCE_AUDIT.md` (static read, 2026-09-21); TZ = `docs/GDD.md`. The reasoning
for every non-MET row is in `docs/TZ_DECISIONS.md`.

## Verdicts

| Verdict | Meaning |
|---|---|
| **MET** | Checked in a real engine run. Visual rows also have a frame in `docs/stills/tzverify/` that was read by eye. |
| **MET-STATIC** | Code or data matches the GDD. No run evidence. |
| **DECIDED** | A DR rule kept the current behavior. |
| **DEFERRED-STRUCTURAL** | A real gap, but out of scope for a mechanical fix. |
| **NEEDS-EYES** | Subjective look or feel only. |
| **BY-DESIGN-ABSENT** | The GDD names no trigger for it, so nothing was built (see TZ_DECISIONS). |
| **NEEDS-MEASUREMENT** | Needs a device or windowed measurement that has not been run. |
| **GAP-OWNER** | Needs an owner action. |

## Evidence sources

- **tz_verify:** `scenes/tools/tz_verify_scene.tscn`, run windowed. 19 checks at rc12 and rc13 (incl. C06 fog at load and D03 per stage; the user:// restore moved to the QaLaunchGuard autoload), `fails=0` (local logs; RECONFIRM-AT-SIGNOFF).
- **Suite:** GOLD MASTER, `fails=0` on 3 consecutive runs.
- **footstep:** `footstep_check_scene`, `fails=0`; exits 1 when any surface lacks 3 distinct steps (mutation-tested in C8).

## Rows

| ID | Requirement | Verdict | Evidence |
|---|---|---|---|
| A02 | Music crossfade 2.0 s | MET | tz_verify `FADE_TIME=2.0` (audio: no frame applies) |
| A03 | Footsteps: 6 surfaces × 3 speeds, downward ray | DECIDED (DR-5: per-speed recordings for asphalt/puddle/glass are an asset residual) | footstep probe: every GDD surface gives 3 distinct steps. Concrete/wood/metal: walk/jog/sprint files for stealth/walk/run. Asphalt/puddle/glass: one recorded sample, speed carried by volume + pitch 0.9/1.0/1.12. |
| A04 | Audio size caps | MET-STATIC | Exported: non-music ≈ 23.5 MB (sfx 6.3 + one_shots 1.1 + ambience 16.1) < 50; music ≈ 38 MB < 100. `ambience/wav_src` (29.9 MB) is in `export_presets.cfg` `exclude_filter` |
| A01 | Bus graph SFX(Footsteps, Combat, UI, Environment) | MET-STATIC (rc14, `audio_bus_check_scene`: 9 buses, every player routed) / owner ear re-mix pending | Buses: Master, Music, SFX, Voice, Ambient, then UI, Footsteps, Combat, Environment under SFX; the Hum bus is gone |
| V02 | No neon / #fff | MET | `V02_energy_ball.png`; monster hit flash is brass and restores the original material (suite P2b, C8 rc4) |
| V05 | Moon shadow 2048² | MET | tz_verify: `directional_shadow/size` 2048 and no smaller `.mobile` override (removed in C8 rc11); frames clean at 2048. On-device mobile cost not measured (P02). |
| V01 | "No day" | MET-STATIC | Dead daytime painter removed from DayNight |
| D03 | Stage ambient/moon (GDD.md:108-111) | MET | tz_verify asserts DARK 0.03/0.12, STREETS 0.11/0.25, FULL 0.16/0.40; `D03_stage_*.png` read by eye and PASS the visual gate at half res (C8 rc12) |
| V03 | Bebas Neue Bold | GAP-OWNER (asset only; headings use the emboldened Regular, `closeout_check` V03) | No Bold font file exists; proof R4-1 below |
| G01 | FPS canon / TPS option | DECIDED (DR-2) | `baseline.png` is first-person |
| G02 | Sprint headbob 0.1 | MET | tz_verify span 0.049; `G03_sprint_fov.png` |
| G03 | Sprint FOV +5° | MET | tz_verify 80 → 85 |
| G04 | 3 m interaction ray | DECIDED (DR-1) | Reach is 3.2 m. Tightening pickup/interaction reach is on the REJECTED list. |
| G06 | Sprint ×1.6 | MET | tz_verify run 272 = 170 × 1.6; bot 3/3 |
| G07 | Crouch speed/noise/visibility/capsule | MET-STATIC (speed ×0.4, noise ×0.3) / DEFERRED-STRUCTURAL (visibility, 1.2 m capsule) | — |
| G08 | Flashlight `#c9a24a`, 45° | MET (colour, cone) / BY-DESIGN DR-3 (16 m / 24 kept: the GDD's 8 m / 2.0 leaves no readable pool, measured at rc14, see TZ_DECISIONS G08) | `G08_flashlight.png`; `docs/stills/evidence/g08_*.png` |
| G09 | Drain 1% per 2 s | DECIDED (DR-3) | Recorded boss-fight failure at a milder value |
| G10 | Battery item +25% | DECIDED (DR-3) | `balance_sim` FAILs at +25 |
| G12b | Flicker below 20%, cleared by Stability L5 | MET | tz_verify: spread 16.2 at 10% battery, 0.000 with Stability L5; suite P2r: L5 + Brightness survive a real respawn, L5 cuts drain 50% (GDD §3.3), New Game clears them (C8 rc4); `G12b_low_battery.png` |
| G13 | Combo 8/12/20 | MET (rc15) | `COMBO_DATA` is the GDD 5.1 table again; the x1.75 of DR-3 was a reserve for the bot's Architect fight while only the Architect could be hit (`closeout_check` G13; bot 3/3 with the canon values, 106 to 126 s) |
| G15 | Capsule 1.6 m, attack box | MET-STATIC (capsule 1.6) / DECIDED (DR-3, attack box) | Bot 1/3 with the capsule; all 3 seeds reached the boss; stalls = known boss-phase type |
| G16 | Respawn: district entry, 50% HP, battery kept | MET (re-proved rc15; the suite P2r evidence read the scene being left, CORRECTION_LOG 72) | `closeout_check` RESP1 (the dead player does not take it, the new one does: hp 50, battery 37); play-through A05c samples health and battery every 0.25 s after the reload |
| G17 | Hardcore death deletes save | MET | tz_verify: main + .bak/.bak2/.bak3 seeded, 0 files left after death; the wipe's `reset_all()` also clears flashlight upgrades (suite P2r, C8 rc4); `G17_hardcore_death.png` |
| G18 / G19 | Roster stats, Shadow | MET-STATIC | All 11 + boss HP/damage equal the GDD table |
| G20 | Boss phases 70/30%, beams 40 | MET-STATIC | Constants; the bot boss phase exercises them |
| G21 | §9 blueprints | DEFERRED-STRUCTURAL | New mechanics plus 5 blueprint locations |
| G22 | 3 + 1 save slots UI | GAP-OWNER (DR-6) | Owner's archive decision on record (PLAN.md §В, Этап 1); owner re-enables the slot picker or amends G22 |
| G24 | Point of no return at D10 | DECIDED (DR-2) | Gate closes once D1–D9 are FULL, not on first D10 entry; suite P2q asserts both sides |
| G25 | HUD slots incl. weapons ×2 | DEFERRED-STRUCTURAL | No weapon system in any scene |
| G26 | 200 photos, 50/100/200 achievements | DEFERRED-STRUCTURAL (DR-5) | No photo can be collected in play |
| G27 | Touch: left half = camera | DECIDED (DR-2) | The GDD table has no movement input |
| G28 / D04 | All FULL → win vs boss | GAP-OWNER (DR-2 default kept) | — |
| G31 / G32 / G33 | Ending edge cases | DECIDED (DR-2) | — |
| G34 | Truth: docs + audio + photos + bunker | MET (bunker = real secret) / MET-STATIC (the 22 audio-log and 24 photo lore notes are inside the all-documents total) | Suite P2q bunker assert; `endings_sim` all 5 reachable |
| S01 | Hit 5 m/1.0, dodge 3 m/0.4 noise | DECIDED (DR-3, measured) | Bot bisect: with 0/3, without 2/3 |
| S02 | Visibility modifiers | DEFERRED-STRUCTURAL | Detection-model rework |
| S03 | Ember vignette noise pulse | MET | tz_verify: vignette r 0.55 while running, frame edge warmth −0.015 → 0.168 on the committed rc12 frames (`baseline.png` → `S03_noise_vignette.png`, `_edge_warmth` of `_tz_verify_runner.gd:30-40` recomputed by the cloud audit; the rc2 run read 0.066); `S03_noise_vignette.png` |
| S04 | Search 10 s within 5 m | MET-STATIC | Constants asserted in suite P2q; in the IRON RULE batch (2/3) |
| S04-hide | Hiding spots: lockers, bushes, car trunks, dark corners | DEFERRED-STRUCTURAL | `hiding_spot.gd` (locker/dumpster/car/crate) is not placed in any district; see TZ_DECISIONS |
| D02 | Unlock graph | DECIDED (DR-2) | — |
| E03 / T02 | 1 ad per hour, skip −100 | MET-STATIC (cooldowns asserted in suite, skip mechanism) / BY-DESIGN-ABSENT (modal trigger) | — |
| E05 | Coin curve 0–200 (D1) → 8000+ (D11) | MET (C8 rc12, DR-4) | District reward now follows the curve: D1 200 ... D11 1200 (7700 in all). Suite P2q asserts the D1/D11 payouts. A winning bot run earned 3439 coins by D11 on the old flat 200 and 8718-8975 on the new curve (achievements already unlocked on this profile, so a first run earns more). |
| C03 | Auto-aim | DEFERRED-STRUCTURAL (dormant until G25) | Cone logic in `WeaponBase` passes tz_verify on a probe weapon, but no gameplay path creates a weapon (G25). Live melee already hits anything within its 2.7 m sphere regardless of facing. |
| C04 | Arachnophobia rename | MET | "Слепые псы"; `C04_arachnophobia_label.png` |
| C06 | Tier fog + particles 50–150% | MET | tz_verify fog at load = tier preset (C8 rc4: `fog_setup.gd` no longer overrides it; since rc13 the probe loads on the High tier, 0.014, so an Ultra profile cannot mask it), 0.012 / 0.015 on change, 6/6 emitters; `C06_tier_*.png` |
| P01 | Draw calls < 200 (D1) / < 350 (D11) | MET (rc15 sign-off, running game: D1 134 / 132, D11 136 / 133) | Windowed `perf_check_scene`, camera at the player: D1 175, D11 165 after the skyline, re-run at sign-off (`docs/PERF_PASS.md` §0; 168-170 and 175-186 before it). The earlier 246/253 came from the camera ScreenShake pinned at (0, 1.7, 0) (CORRECTION_LOG 46). Primitives stay over budget (PERF_PASS #18). rc15: the same scene measured 279 / 272 at the start of the pass (the moon's four shadow cascades re-drew the street for 110 calls, CORRECTION_LOG 88); a single 40 m cascade and no moon shadow in the dark stages give D1 169 / D11 168 on the paused-tree instrument of that pass (primitives 76 551 / 77 637, `docs/artifacts/rc15/perf_rc15.txt`) and D1 134 / 132, D11 136 / 133 on the running game at sign-off (two runs, `docs/artifacts/rc15/perf_rc15_final.txt`, CORRECTION_LOG 93). |
| P02 | Particles < 500, RAM/VRAM | MET (desktop, rc14) | 140 emitting particles, texture 144.7 MiB, video 168.3 MiB (windowed `perf_check_scene`, sign-off run); on-device profile stays an owner step, see TZ_DECISIONS P02 |
| N01, I02, T01 | Owner rows | GAP-OWNER | See TZ_DECISIONS |

**Open GAP-DEV rows: 0.** Every audit row the audit scored GAP-DEV or GAP-OWNER has a verdict above. Rows the audit already scored MET, EXTRA or BY-DESIGN are not repeated here; their audit verdicts stand (see `docs/TZ_COMPLIANCE_AUDIT.md`).

## Totals (recounted from the table by script, 2026-09-30)

48 table rows (several rows group IDs, e.g. G18/G19, G31/G32/G33, N01, I02, T01): **MET 18 + MET-STATIC 9 = 27 met**,
DECIDED 11, **GAP-OWNER 4** (V03 Bebas Neue Bold file, G22 save-slot picker, G28/D04 and N01/I02/T01 GDD text
amendments), **DEFERRED-STRUCTURAL 6** (G21 blueprints, G25 weapons, G26 photos, S02 visibility model, S04-hide
hiding-spot placement, C03 auto-aim). GAP-DEV 0, NEEDS-MEASUREMENT 0.


## R4: the four owner rows are asset or decision only (two greps each, 2026-10-02)

Each row below was checked twice, once for the missing input and once for the code that would consume it. In all four the
code is in place and the open item is a file or a decision that only the owner can supply.

| Row | grep 1: the input is missing or decided | grep 2: the code path exists | Owner action |
|---|---|---|---|
| V03 Bebas Neue Bold | `ls assets/fonts | grep -i bebas` prints `BebasNeue-Regular.ttf` and its `.import` only | `scripts/ui/theme_provider.gd:35-38`: `_bold()` builds a `FontVariation` with `variation_embolden`; `closeout_check` V03 asserts headings and the project theme's Button font are that variation | drop `BebasNeue-Bold.ttf` into `assets/fonts/` and point `build_theme()` at it (one line) |
| G22 3 + 1 save slots UI | `PLAN.md:1313`: "Судьба lobby/save-slots экранов ... **DECIDED: archive**" (the owner's own decision) | `scripts/core/save_system.gd`: `MAX_SLOTS = 4`, `save_slot()`, `load_slot()` (slot id inside the signed payload) are live; `screens.gd` lists the "Saves" card but no route opens it | re-enable the slot picker, or amend GDD G22 to the archive decision |
| G28 / D04 all FULL -> win | `docs/GDD.md:122`: all eleven FULL -> final night -> the Architect on the power station -> his death is the win (GDD amended rc15; it had said the win was immediate) | `scripts/world/finale_director.gd:135-136` calls `trigger_win()` on `boss_defeated`; `scripts/world/power_grid.gd:92` calls it only when no FinaleDirector exists; `closeout_check` FIN1 | none (decided); the owner may delete the GAP-OWNER tag |
| N01 / I02 / T01 | N01 NG+ rule text and I02 the key census (GDD:22, "198 keys / ~2574 total") are GDD lines, not code: `grep -c '"' data/i18n/en.json` counts the real keys | T01: `ls .signing` prints `release.env` and `tls-release.keystore`, `git check-ignore -v .signing/release.env` prints `.gitignore:87:.signing/`; `export_presets.cfg:23-28` keystore fields are empty strings (the release build reads the environment) | write the NG+ rule or accept the modifier set, amend the census line, and put the signed AAB on a phone (the one step no machine here can do) |
