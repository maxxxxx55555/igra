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

- **tz_verify:** `scenes/tools/tz_verify_scene.tscn`, run windowed. 19 checks at rc12 (incl. C06 fog at load and D03 per stage; the user:// restore moved to the QaLaunchGuard autoload), `fails=0`.
- **Suite:** GOLD MASTER, `fails=0` on 3 consecutive runs.
- **footstep:** `footstep_check_scene`, `fails=0`; exits 1 when any surface lacks 3 distinct steps (mutation-tested in C8).

## Rows

| ID | Requirement | Verdict | Evidence |
|---|---|---|---|
| A02 | Music crossfade 2.0 s | MET | tz_verify `FADE_TIME=2.0` (audio: no frame applies) |
| A03 | Footsteps: 6 surfaces × 3 speeds, downward ray | DECIDED (DR-5: per-speed recordings for asphalt/puddle/glass are an asset residual) | footstep probe: every GDD surface gives 3 distinct steps. Concrete/wood/metal: walk/jog/sprint files for stealth/walk/run. Asphalt/puddle/glass: one recorded sample, speed carried by volume + pitch 0.9/1.0/1.12. |
| A04 | Audio size caps | MET-STATIC | Exported: non-music ≈ 23.5 MB (sfx 6.3 + one_shots 1.1 + ambience 16.1) < 50; music ≈ 38 MB < 100. `ambience/wav_src` (29.9 MB) is in `export_presets.cfg` `exclude_filter` |
| A01 | Bus graph SFX(Footsteps, Combat, UI, Environment) | DEFERRED-STRUCTURAL | Re-routing plus an ear re-mix (current buses: Master, Music, SFX, Voice, Ambient, UI, Hum) |
| V02 | No neon / #fff | MET | `V02_energy_ball.png`; monster hit flash is brass and restores the original material (suite P2b, C8 rc4) |
| V05 | Moon shadow 2048² | MET | tz_verify: `directional_shadow/size` 2048 and no smaller `.mobile` override (removed in C8 rc11); frames clean at 2048. On-device mobile cost not measured (P02). |
| V01 | "No day" | MET-STATIC | Dead daytime painter removed from DayNight |
| D03 | Stage ambient/moon (GDD.md:108-111) | MET | tz_verify asserts DARK 0.03/0.12, STREETS 0.11/0.25, FULL 0.16/0.40; `D03_stage_*.png` read by eye and PASS the visual gate at half res (C8 rc12) |
| V03 | Bebas Neue Bold | GAP-OWNER | No Bold font file exists |
| G01 | FPS canon / TPS option | DECIDED (DR-2) | `baseline.png` is first-person |
| G02 | Sprint headbob 0.1 | MET | tz_verify span 0.049; `G03_sprint_fov.png` |
| G03 | Sprint FOV +5° | MET | tz_verify 80 → 85 |
| G04 | 3 m interaction ray | DECIDED (DR-1) | Reach is 3.2 m. Tightening pickup/interaction reach is on the REJECTED list. |
| G06 | Sprint ×1.6 | MET | tz_verify run 272 = 170 × 1.6; bot 3/3 |
| G07 | Crouch speed/noise/visibility/capsule | MET-STATIC (speed ×0.4, noise ×0.3) / DEFERRED-STRUCTURAL (visibility, 1.2 m capsule) | — |
| G08 | Flashlight `#c9a24a`, 45° | MET (colour, cone) / NEEDS-EYES (8 m range, energy 2.0) | `G08_flashlight.png` |
| G09 | Drain 1% per 2 s | DECIDED (DR-3) | Recorded boss-fight failure at a milder value |
| G10 | Battery item +25% | DECIDED (DR-3) | `balance_sim` FAILs at +25 |
| G12b | Flicker below 20%, cleared by Stability L5 | MET | tz_verify: spread 16.2 at 10% battery, 0.000 with Stability L5; suite P2r: L5 + Brightness survive a real respawn, L5 cuts drain 50% (GDD §3.3), New Game clears them (C8 rc4); `G12b_low_battery.png` |
| G13 | Combo 8/12/20 | DECIDED (DR-3) | Recorded winnability tuning |
| G15 | Capsule 1.6 m, attack box | MET-STATIC (capsule 1.6) / DECIDED (DR-3, attack box) | Bot 1/3 with the capsule; all 3 seeds reached the boss; stalls = known boss-phase type |
| G16 | Respawn: district entry, 50% HP, battery kept | MET | Suite P2r (exact button path) |
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
| S03 | Ember vignette noise pulse | MET | tz_verify: vignette r 0.55 while running, frame edge warmth −0.015 → 0.066; `S03_noise_vignette.png` |
| S04 | Search 10 s within 5 m | MET-STATIC | Constants asserted in suite P2q; in the IRON RULE batch (2/3) |
| S04-hide | Hiding spots: lockers, bushes, car trunks, dark corners | DEFERRED-STRUCTURAL | `hiding_spot.gd` (locker/dumpster/car/crate) is not placed in any district; see TZ_DECISIONS |
| D02 | Unlock graph | DECIDED (DR-2) | — |
| E03 / T02 | 1 ad per hour, skip −100 | MET-STATIC (cooldowns asserted in suite, skip mechanism) / BY-DESIGN-ABSENT (modal trigger) | — |
| E05 | Coin curve 0–200 (D1) → 8000+ (D11) | MET (C8 rc12, DR-4) | District reward now follows the curve: D1 200 ... D11 1200 (7700 in all). Suite P2q asserts the D1/D11 payouts. A winning bot run earned 3439 coins by D11 on the old flat 200 and 8718-8975 on the new curve (achievements already unlocked on this profile, so a first run earns more). |
| C03 | Auto-aim | DEFERRED-STRUCTURAL (dormant until G25) | Cone logic in `WeaponBase` passes tz_verify on a probe weapon, but no gameplay path creates a weapon (G25). Live melee already hits anything within its 2.7 m sphere regardless of facing. |
| C04 | Arachnophobia rename | MET | "Слепые псы"; `C04_arachnophobia_label.png` |
| C06 | Tier fog + particles 50–150% | MET | tz_verify fog at load = tier preset (C8 rc4: `fog_setup.gd` no longer overrides it; since rc13 the probe loads on the High tier, 0.014, so an Ultra profile cannot mask it), 0.012 / 0.015 on change, 6/6 emitters; `C06_tier_*.png` |
| P01 | Draw calls < 200 (D1) / < 350 (D11) | DEFERRED-STRUCTURAL | Windowed `perf_check_scene`: D1 = 246 (C7) and 253 (rc11), over 200; under the D11 350 cap. Needs material/mesh batching, not a value swap. |
| P02 | Particles < 500, RAM/VRAM | NEEDS-MEASUREMENT | Windowed or device profiling only; see TZ_DECISIONS P02 |
| N01, I02, T01 | Owner rows | GAP-OWNER | See TZ_DECISIONS |

**Open GAP-DEV rows: 0.** Every audit row the audit scored GAP-DEV or GAP-OWNER has a verdict above. Rows the audit already scored MET, EXTRA or BY-DESIGN are not repeated here; their audit verdicts stand (see `docs/TZ_COMPLIANCE_AUDIT.md`).
