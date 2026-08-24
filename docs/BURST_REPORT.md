# Burst report — MAX-THROUGHPUT parallel audit + fix wave

5 read-only subagents (A1 code, A2 UI, A3 assets, A4 i18n, A5
architecture) full-read the codebase in parallel; I fixed findings
P0→P2 as each list streamed in. 7 commits, all pushed to `origin/main`.
Investigation notes and DEFAULT_CHOICE reasoning for every fix:
`docs/PLANS.md` (burst-wave entries, in order).

## Agent findings → fixed → commit

| Agent | Findings | Fixed this wave | Commit |
|---|---|---|---|
| A1 code | 7 (5 BUG, 1 logic, 1 MINOR) | Achievement threshold logic (3 achievements unlocked on 1st occurrence instead of at target; ach_01 could never unlock); 4 of 5 KILL quests + both REPAIR quests permanently uncompletable; q_craft_items never wired to the live crafting path; flashlight upgrade cost mismatch vs GDD | `66f556f` |
| A2 UI | 20 (13 VISUAL, 6 I18N, 1 mixed) | Off-canon backgrounds on every pre-gameplay screen (menu/splash/boot/credits/settings/difficulty/pre_loading); skill_button.gd raw-sentence-as-key i18n bug; hardcoded HUD strings (noise/visibility/ammo/radar/sprint/stealth); skill tree off-palette colors | `fb05718`, `4277959`, `78f1a70`, `6b8956b` |
| A3 assets | 12 UNWIRED + 1 OVERSIZE | 6 silent enemy types (brute/burner/rotter/hound/tvar/sharpshooter) had zero combat audio — `_set_cues()` was never called | `617ec7d` |
| A4 i18n | 196-key systemic gap + per-locale extras, 0 missing/unused keys, 0 file issues | Not mass-fixed this wave (see "Not done" below) — but every NEW key added this wave (12 total: 6 SKILL_*, 6 HUD_*) was translated into all 13 locales properly, not left English | (rolled into A2 commits above) |
| A5 architecture | 1 INIT_ORDER (investigated, not reproduced), 1 DUPLICATE (dead, no action), 6 DEAD_SIGNAL, 1 dead-reference-in-dead-code | monster_spotted (5 dead subscribers) repointed to the live player_detected signal | `7f3b699` |

## Gates (final verification pass, all individually clean)

`compile bad=0` · `signal-arity fails=0` · `autoload-api fails=0`
(this run itself surfaced and I fixed a false-positive: a comment
containing the literal substring `EventBus.gd` was mis-parsed by the
regex-based checker as a call to a nonexistent `EventBus.gd()` method —
reworded the comment, not the checker) · `i18n fails=0` ·
`asset-check fails=0` · `save-integrity fails=0` · `boot-flow fails=0`
(real menu → New Game → sustained gameplay → save → load, unchanged
from the prior RESCUE WAVE session) · `footstep-check fails=0`.

## What was fixed, in plain terms

- **6 enemy types were completely silent in combat.** brute, burner,
  rotter, hound, tvar, and sharpshooter never called `_set_cues()` —
  24 delivered audio files sat unused. Wired all 6.
- **Achievements were broken in both directions.** "Kill 50 Shadows"
  unlocked on the *first* kill (dead threshold-check code); the very
  first achievement in the list, "First Light," could *never* unlock at
  all (wrong argument type passed in).
- **6 of the game's 20 quests were permanently stuck at 0/N** — 4 KILL
  quests targeted enemy names that don't exist in the actual game
  (`"runner"`/`"tank"`/`"sniper"`/`"squad"` vs the real `hunter`/
  `destroyer`/`sharpshooter`/`hound`), both REPAIR quests fired
  simultaneously on the very first district restored regardless of
  which one, and the crafting quest was wired to a dead, never-
  instantiated manager instead of the real crafting screen.
- **Every screen before and around gameplay had the wrong background
  color** — a warm brown-black instead of the canon cool blue-black —
  since before the palette was formally canonized. Fixed on the main
  menu, splash screen, boot loader, credits, settings, and difficulty
  screens.
- **The core gameplay HUD showed mixed Russian/English text** (`ШУМ`,
  `ЗАМЕТ.`, `РАДАР`, `БЕГ`, `СТЕЛС`) to every player regardless of
  their selected language, because nothing had ever localized those
  five labels. Same root-cause class hit the skill tree screen's
  cost/level/requirement text, permanently English in all 13 locales.
- **A dead signal name silently broke 5 unrelated feedback systems** —
  encyclopedia auto-unlock on sighting, the HUD's spotted indicator, a
  tutorial hint, and a growl SFX all listened for `monster_spotted`,
  which nothing has emitted since the codebase migrated to
  `player_detected` under the exact same signature.

## DEFAULT_CHOICE (flagged for human sanity-check)

The KILL-quest target remapping (`runner→hunter`, `tank→destroyer`,
`sniper→sharpshooter`, `squad→hound`) and `ach_01` sharing its unlock
trigger with `ach_02` are content/design judgment calls, not pure code
fixes — reasonably grounded in the game's own existing roster-naming
scheme, not arbitrary, but someone should sanity-check that quest
flavor text still reads correctly against the enemy it now actually
targets. Full reasoning for each: `docs/PLANS.md`.

## Investigated and NOT fixed (with reasons)

- **A5's `GameManager`→`AdService` init-order theory** (autoload #19
  connecting to autoload #52's signal in `_ready()`) — grepped every
  runtime log captured across this and the prior session (multiple full
  real-window boots) for related errors: zero hits. A fresh direct
  headless boot also produced no error. GDScript raises hard on
  `null.method()` calls, so a silent no-op isn't possible here — this
  did not reproduce as a real bug and wasn't "fixed."
- **Enemy stats badly diverge from GDD's own table** (Watcher/Hunter/
  Destroyer/Crawler use a roster-key mapping that gives them 2-4x the
  documented HP/damage, changing core combat difficulty) — a real,
  confirmed data-mapping bug, but fixing it changes balance across
  every encounter with 4 of the game's enemy types. Deliberately
  deferred as too large/risky to fold into a mixed fix-everything pass;
  needs its own focused session with real playtesting.
- **7 of 8 workbench recipes are uncraftable** — the required materials
  (`fabric`, `alcohol`, `gunpowder`, etc.) don't exist as items anywhere
  in the game. Fixing this means creating new item resources, which is
  content creation, not wiring — out of this session's edits-only,
  no-new-systems scope.
- **2 EXPLORE quests and 1 INTERACT quest** (`q_find_engineers`,
  `q_explore_school`, `q_connect_cables`) have no code anywhere that
  could ever satisfy them — no zone-detection or cable-interaction
  system exists to hook into. Same reasoning as above: would require
  building new detection logic, not wiring existing pieces together.
- **`scripts/tools/_game_test_3d.gd`'s "generator uses registered fuel
  item" check fails for real**: `street_builder.gd` has no
  `GENERATOR_FUEL` constant, and the only `Generator` class in the
  codebase (`scripts/generator.gd`) is never instantiated anywhere —
  the fuel-consuming generator mechanic the test expects simply doesn't
  exist as a working feature. Same for "pickups spawned: 0" in the same
  test — the synthetic test scene doesn't populate the `pickups` group.
  Both pre-existing, not caused by anything this wave touched; a real
  gap, not a regression.
- **zh.json (Simplified Chinese) has ~107 keys with romanized pinyin
  placeholders** (e.g. `"yes": "Shi"`) beyond A4's already-large 196-key
  English-identical gap — discovered while adding new keys to that
  file, not chased further this wave (needs its own dedicated pass).
- **The full 196-key × 11-locale translation gap A4 found** was not
  mass-fixed. Every *new* key this wave added (12 total) was properly
  translated into all 13 languages, but the pre-existing backlog is
  untouched — realistically ~2,000+ individual strings, sized for its
  own dedicated session, not a fold-in.
- Several of A5's fully-dead signals (`coin_changed`/`lives_changed`,
  `player_caught`, `game_loaded`, `shop_purchased`, `purchase_failed`,
  `enemy_hp_updated`) and the dead `ScreenFlowManager` duplicate system
  were left alone — zero current subscribers+emitters means zero
  player-facing effect, and "fixing" a signal nothing listens to isn't
  a real improvement.
- Crosshair texture wiring (delivered `crosshair_64.png`/
  `crosshair_dot.png` UI-crisp assets) — the live crosshair reacts to
  the same dead `crosshair_state_changed` signal A5 flagged; a real
  texture swap would need that emit-site built too, which is more than
  a mechanical fix. Not attempted.

## Self-audit — 3 loudest claims, checked just now

1. **"All 6 previously-silent enemy types now have combat audio."**
   True at the wiring level — `_set_cues()` is called with the correct
   file names for all 6, verified via `compile bad=0` and `asset-check
   fails=0` (which checks every referenced audio path resolves on
   disk). Not verified by actually hearing it in a live encounter this
   session — no audio-capture tooling exists yet, only visual
   screenshot tools. Downgraded from "confirmed working" to "confirmed
   wired and reachable."
2. **"All gates are green."** Re-ran fresh, individually, immediately
   before writing this file (quoted above): compile, signal-arity,
   autoload-api, i18n, asset-check, save-integrity, boot-flow,
   footstep-check — all `fails=0`/`bad=0`. True as stated. (The combined
   `tools/check.sh` run launched at the start of this wave did complete
   this time, but two of its lines needed separate scrutiny: the
   autoload-api false-positive, fixed and re-verified above, and
   `game_test_3d_scene`'s 2 genuine pre-existing failures, investigated
   and explained above, not silently claimed as passing.)
3. **"7 of 20 quests were fixed."** Precise count, not rounded up:
   4 KILL quests + 2 REPAIR quests + 1 CRAFT quest = 7 quest-level fixes
   across `quest_manager.gd`/`workbench.gd`. 3 quests (`q_find_
   engineers`, `q_explore_school`, `q_connect_cables`) remain genuinely
   uncompletable and are explicitly listed as not fixed above, not
   glossed over.
