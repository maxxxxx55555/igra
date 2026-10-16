# Final polish plan (Session 26, `v9.0.0-universe`)

**Rule of this pass.** A frame is read before a change is made, and a change is made only for a defect that is measured, breaks a rule of `docs/STYLE_GUIDE.md` or of plain legibility, and
can be fixed without touching what the player does. A change that moves what a monster sees, what the bot wins or what the perf gate counts needs the bot, the stealth balance and the
windowed gate, and a polish pass does not own those; it is written down as an owner row. The pass's budget was at most 8 defects, 3 items to a batch, 4 batches and one windowed launch
a batch: it used **one batch of one item**, kept.

**What was read.** The eight release frames of `docs/stills/ultimate` (the code of `0752c9b`: menu, district at FULL, district at DARK, combat, boss, victory, skill tree, shop), the density
and store frames around them, and the eight frames of `docs/stills/universe` (the code of `ccc7669`) after the batch. The numbers come from one script that prints itself first
(`docs/artifacts/rc16/proofs/s26_p1_frames.out`).

## P1. The audit

| # | Where | Seen | Measured | Rule | Cause | Decision |
|---|---|---|---|---|---|---|
| D1 | `02_district_day_full` (and every frame with a toast over a lit road) | the level-up toast ("Level up! Now level 2") is bone text with no outline; on the lit road it is gone | contrast of the box 1.53:1 (text `214,207,195` on `254,255,252`) | legibility: WCAG 2 asks 4.5:1 for text of this size, 3:1 for large text | `UIManager.show_notification` sets a colour and a size and nothing else | **applied** (batch 1) |
| D2 | `04_combat` | the lit road is a cream slab: 6.17 % of the frame has all three channels at 240 or more, and the monster's hit flash is a white capsule | 6.17 % near white at `0752c9b`, 4.09 % at `ccc7669` (the staging is random) | `docs/STYLE_GUIDE.md` section 2: pure white is banned | the flashlight's `light_energy = 24.0` (`scenes/player/player_3d.tscn:180`) saturates a Compatibility-renderer pixel; the tonemap pairs of `docs/BEAUTY_RC16.md` (V3) did not move it | **declined, owner row**: the number also feeds `LightGrid` (`_intensity_of` returns `light_energy` for a spot light), so a lower value changes how bright the grid says a monster's cell is, that is the stealth balance, and needs the bot and the perf gate |
| D3 | `04_combat` | a flat brass patch fills a third of the sky and ends in a hard vertical edge at x = 350 | brass `134,112,68` flat to x = 348, `77,55,31` at 350, `15,14,13` at 352 | none broken: the landmark is "a silhouette against a halo at FULL" (`docs/DISTRICT_SIGNATURES.md:33`) | the halo quad of `scripts/world/district_landmark.gd` (110 x 100 m, 16 m behind a tower) and the tower's own left edge | **declined**: the design, not a fault; the dim option for the owner is `HALO_BY_STAGE` (0.28 at FULL) or `HALO_SIZE` |
| D4 | `07_skill_tree` | five cards in the upper left quarter and an empty screen | luma 27.2, 0.00 % near white | none | the tree's layout | **declined**: layout work with 13-locale overflow risk (`docs/BEAUTY_RC16.md`, "Left as it is") |
| D5 | `05_boss` | a red vignette over the whole frame | the damage vignette of a hurt player | none | `scripts/ui/damage_vignette.gd` | **declined**: the state shows the hit, by design |
| D6 | `02_district_day_full` | the battery and visibility bars are 110 px wide with 6 px labels | measured on the half-resolution frame | none | the HUD pass of Session 22 (`docs/HUD_PLAN.md`) | **declined**: the frame is half resolution; the HUD plan holds the sizes |
| D7 | `07_skill_tree`, `08_shop` | the narrative log line of the HUD stays on the screen over a menu | the toast layer sits above screens by design | none | `scripts/ui/toast_manager.gd` | **declined**: a notice is meant to reach a player in a menu |

## P2. Batch 1 (D1)

`scripts/ui/ui_manager.gd`: two theme overrides on the toast label, `font_outline_color` of bg-deep `#0c1016` (the canon colour of `docs/STYLE_GUIDE.md` section 2) and `outline_size`
4. No layout changes (an outline does not move a glyph), no string changed. The label's colour, size and timing are as before; the prompt and notice labels of the HUD
(`PromptLabel`, `NoticeLabel` of `scenes/ui/hud_3d.tscn`) are the same class of label and were not measured in a lit frame, so they are not touched.

One windowed launch shot the eight frames at `ccc7669` (`docs/artifacts/rc16/proofs/s26_windowed_ccc7669.out`, ledger row 128, one command of three steps with the perf and the audio gate).

## P3. The pair, read

`docs/stills/ultimate/02_district_day_full_after_0752c9b_20261015T015008Z.png` against `docs/stills/universe/02_district_day_full_after_ccc7669_20261016T035459Z.png`, the box of the
toast: before, the text is a pale smear on the road; after, a dark outline carries every glyph and the line reads at a glance. Measured the same way on both: **1.53:1 to 5.53:1**
(`docs/artifacts/rc16/proofs/s26_p1_frames.out`). The other seven pairs differ by grain and by the random staging of the combat and boss frames (a different monster and facing:
mean luma 86.2 to 76.0 and 52.8 to 48.2), nothing a change of this batch touches; no frame lost a canon colour. **Kept.**

## P4. Budgets

| View | Draw calls | Budget | p95 frame | Budget | Source |
|---|---|---|---|---|---|
| D1 (suburbs, the spawn district) | 152 | 200 | 17.48 ms | 30 ms | `[perf] budget D1<200: 152; D11<350: 142; p95<=33 ms: 17.48 and 19.05` |
| D11 (power station, the busiest) | 142 | 350 | 19.05 ms | 35 ms | the same line; `[perf] DONE fails=0` |

Video memory 125.0 MiB (budget 512), texture memory 97.5 MiB, 154 particles (budget 500): `docs/artifacts/rc16/proofs/s26_windowed_ccc7669.attach.perf_check_scene.log`. The windowed
gate read RED at Session 23 (D1 p95 35.00 ms, D11 38.63 ms, `docs/PERF_PASS.md` 0b) on a machine whose process list showed other programs at a core and more; this pass reads it green
on the same render path (nothing of it changed but a toast's outline and the dead functions). One reading does not erase two, so the row stays an owner row for the device that matters:
`docs/RELEASE_CHECKLIST.md`.

## Owner rows from this plan

- **D2 (the cream slab).** Decide whether the flashlight may be dimmer, and if it may, how `LightGrid` should read it; the bot and the stealth balance have to be run with it.
- **D3 (the halo).** Keep the silhouette-against-halo look or dim the halo.
- **The prompt and notice labels** of the HUD: measure them in a lit frame; the same two overrides fix them if they read below 4.5:1.
