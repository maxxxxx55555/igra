# Retention & fun review — MEGA FINAL PASS (2026-09-13)

Independent review agent, paper playtest read against the actual code. Every behavioural
claim below was cited to file:line by the reviewer.

## RETURN LOOP SCORE: 5/10

The daily challenge card sits second in the main-menu VBox
(`scripts/ui/main_menu.gd:33`, `:148-191`), so every player sees today's target and their
streak the moment the app opens — a real hook. Rewards (10–400 coins, streak bonuses
150/750/3000 at 7/30/100 days) comfortably outweigh shop prices of 15–150
(`data/economy/shop_catalog.json`). What caps the score is that **nothing pulls the player
back from outside the app**: there is no OS/local notification anywhere in `scripts/`, only
in-game toasts, so the loop only fires if the player independently remembers to relaunch.

## Will a new player actually meet each feature?

| Feature | Session 1 | Session 2 | Session 3 | Evidence |
|---|---|---|---|---|
| Secrets | Partial | Likely | Partial | `content/secrets.json` min_stage histogram; `district_park.tres:8`; `power_grid.gd:32-39` |
| Daily challenges | Yes | Yes | Yes | `main_menu.gd:33`, `:172-191` |
| NG+ modifiers | No | No | No | `victory_screen.gd:45` — only on a win, many repair cycles away |
| Captions | Partial | Yes | Yes (accumulating) | `content/captions.json:6-11`; `captions_manager.gd:27` |
| UI stingers | Yes | Yes | Yes | `uisfx.gd:18-30` |

**Sharpest finding.** Suburbs starts at `Stage.DARK` (`district_suburbs.tres:7`). Before
this pass only **2 of 26** secrets had `min_stage 0`, and one of those two sits in park,
which itself needs suburbs at `Stage.FULL` to enter (`power_grid.gd:36-39`) — so exactly
**one** secret was reachable at game start, and 17 of 26 (65%) sat behind stage 2 or 3.
A 26-secret feature was shipping essentially invisible to the audience meant to be hooked
by it.

NG+ modifiers being unreachable in the first three sessions is **by design** and is not
treated as a defect: NG+ is post-completion content.

## Top 3 friction points — all fixed in commit `a406075`

1. **Secrets gated deeper than a new player reaches.**
   Fixed as a pure data edit: `secret_suburbs_02` and `secret_residential_02` lowered from
   `min_stage` 2 to 1, so the starting district yields a second secret as soon as the
   player makes their first repair. New histogram: 2 at stage 0, 9 at 1, 10 at 2, 5 at 3.

2. **Nothing ever told the player the journal exists.** Quest `q_secrets_1` ("find 1
   secret", 30 coins) is live from `quest_manager.gd:50` on the first frame, but
   `tutorial_system.gd`'s `STEPS` never mentioned quests or the journal, so the player had
   no in-fiction reason to open the screen that would teach them secrets are a thing.
   Fixed with one data-only tutorial step, `TUT_JOURNAL`, synced to all 13 locales.

3. **The secret prop was invisible at the distance it spawns.** Its `GlowOmniLight3D` had
   `light_energy 0.3`, `omni_range 1.6`, fade `7.0/3.0` — fully faded by ~10 m — while
   `district_loot.gd` seeds secrets 13.2–22 m from district centre. Even a diligent,
   correctly-staged player walked past them. Fixed by tuning to energy 0.9, range 4.5,
   fade 22.0/8.0.

## Not addressed, and why

The missing out-of-app notification is the single largest remaining lever on the return
loop. It is not a data or UI change — it needs a platform notification integration — and
this pass was explicitly scoped to data and UI only, so it is recorded here rather than
half-built.
