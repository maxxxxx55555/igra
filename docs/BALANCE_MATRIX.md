# BALANCE_MATRIX — repo-data snapshot: NG+ knobs, district stages, boss phases

Date: 2026-09-16 · Owner: game-feel & QA pass · Skill: `ponytail` (full)
Mode: **READ-ONLY.** Nothing here edits data, code, or GDD. This table records
what the repo says *today*, traces who consumes it, and raises **exactly 3**
outliers (§ Outliers) with proposed values for the owner / content agent to
decide. Proposed ≠ applied. On any conflict, `docs/GDD.md` wins (AGENTS.md).

Source files read (all paths relative to repo root, 2026-09-16 state):
`scripts/systems/new_game_plus.gd`, `scripts/systems/difficulty_manager.gd`,
`data/ng_plus_config.json`, `content/ngp_modifiers.json`,
`data/districts/*.tres` (11) + `data/districts/districts.json`,
`scripts/world/district_data.gd` (Stage enum) + `power_grid.gd`,
`content/secrets.json` (26), `scripts/enemies/enemy_roster_data.gd` (roster +
AI_TO_ROSTER, `/100` armor semantics via `base_monster.gd:180`),
`scripts/enemies/boss_3d.gd`, `scripts/enemies/tvar_3d.gd`,
`scripts/enemies/base_monster.gd` (`_apply_ng_scaling`, kill payout 5–15),
`data/monsters/*.tres` (12), `data/bestiary/bestiary.json`,
`content/daily_challenges.json` (60 templates) / `data/daily_challenges.json`
(30, legacy), `scripts/systems/daily_challenge_manager.gd`,
`scripts/systems/integrity_guard.gd` (MAX_COINS),
`docs/GDD.md` §6.2 enemy table, `docs/PRODUCTION_BIBLE.md` §1/§3/§4,
`docs/VISUAL_PASS.md` (stage-adjacent light/ambient values only).

## Master table (one table, all read data)

Legend — **Status**: `LIVE` = read by shipped gameplay code · `UI` = display
only · `LEGACY-FB` = loaded only as fallback · `DEAD` = zero code readers
found (grep of `scripts/` + `tools/`) · `DISPLAY` = codex/encyclopedia.

| # | Area | Object | Knob / value (as shipped) | Source | Consumer | Status |
|---|---|---|---|---|---|---|
| N1 | NG+ | level cap | `MAX_NG_PLUS = 3`; activate returns false at cap | new_game_plus.gd:15 | NewGamePlus (36 call sites) | LIVE |
| N2 | NG+ | enemy HP | `+0.20 × ng` additive → ×1.20 / 1.40 / 1.60 | new_game_plus.gd:18 → `get_enemy_hp_multiplier` | base_monster `_apply_ng_scaling` (max_hp) | LIVE |
| N3 | NG+ | enemy damage | `+0.15 × ng` → ×1.15 / 1.30 / 1.45 | new_game_plus.gd:17 | base_monster (attack_damage) | LIVE |
| N4 | NG+ | XP | `+0.25 × ng` → ×1.25 / 1.50 / 1.75; ×2 again when Keeper's Pact held (`get_xp_multiplier` folds `lore`) | new_game_plus.gd:16 (`get_xp_multiplier`) | XpManager | LIVE |
| N5 | NG+ | player damage | `+0.10 × ng` → ×1.10 / 1.20 / 1.30 | new_game_plus.gd:19 | player weapons | LIVE |
| N6 | NG+ | loot chance | `+0.10 × ng`, × `whisper.loot 0.90` | new_game_plus.gd:20 (`get_loot_chance_multiplier`) | loot tables | LIVE |
| N7 | NG+ | flat multipliers | `ng_plus_enemy_mult: 1.5`, `ng_plus_xp_mult: 1.2`, 5 `unique_achievements` | data/ng_plus_config.json | **nobody** — zero refs in scripts/tools | **DEAD** (outlier O1) |
| N8 | NG+ | difficulty + NG flag | hp `[0.7, 1.0, 1.5]`, dmg `[0.7, 1.0, 1.4]`, detection `[0.8, 1.0, 1.2]`; `ngplus` = existence of `user://ngplus.cfg` → extra ×1.5 | difficulty_manager.gd | **not autoloaded, zero refs** | **DEAD** (outlier O1) |
| N9 | NG+ mod | `long_night` | battery ×0.80 | content/ngp_modifiers.json | flashlight drain budget | LIVE |
| N10 | NG+ mod | `whisper` | hunter_hearing ×0.70, loot ×0.90; exclusive `sprint` | " | detection + loot | LIVE |
| N11 | NG+ mod | `blackout_plus` | `extra_dark_districts` 1.0 read as **additive count** → blackout *events* strike 1+N districts; exclusive `long_night` | " + random_events.gd:28–37 | random_events | LIVE, **text ≠ behavior** (O2) |
| N12 | NG+ mod | `keepers_pact` | lore ×2.0, hints=false | " | XpManager + hint systems | LIVE |
| N13 | NG+ mod | `sprint` | cycle ×0.85, rewards ×1.5, time_pressure HUD | " | day_night length, coin/XP payout, countdown HUD | LIVE |
| N14 | NG+ mod | `ghost` | crawlers_ignore, achievements=false (logged, never granted) | " | aggro filter + AchievementManager.unlock | LIVE |
| N15 | NG+ mod | stacking | same-knob **multiply**; exclusivity symmetric-checked both directions; ≤ ng-level count of picks | ngp_modifiers.json `_contract` + `new_game_plus.gd::can_select` | selection UI | LIVE |
| D1 | Districts | count / start | 11 districts, every `stage = 0` (DARK) at new game | data/districts/district_*.tres | PowerGrid.reset() | LIVE |
| D2 | Districts | stage model | `enum Stage {DARK 0, PARTIAL 1, STREETS 2, FULL 3}` | district_data.gd:3 | env grade, secrets gate, loot | LIVE |
| D3 | Districts | ambient canon | 0.03 / 0.06 / 0.11 / 0.16 per stage | PRODUCTION_BIBLE §2 (verified-live note) | world_env_setup / district_grading | LIVE |
| D4 | Districts | power DAG | longest chain suburbs→residential→hospital→warehouses→industrial→substation→power_station (7 nodes); parallel branch suburbs→park→{gas_station, police}, police re-joins industrial (dual-parent); school is a leaf | 11 × `powered_by` | PowerGrid restore order | LIVE |
| D5 | Districts | blackout events | random event strikes 1 district (`_random_non_full_district`) per interval; +1 per N11 | random_events.gd | district state | LIVE |
| D6 | Districts | secrets/district | 26 total: 3 each (park, hospital, industrial, power_station), 2 elsewhere; min_stage mix {0:2, 1:9, 2:10, 3:5} → 5 secrets need FULL | content/secrets.json | secret.gd gate, dailies, q_secrets, Truth ending (≥3) | LIVE |
| D7 | Districts | legacy graph | 5 districts ("Okraina/Promzona/…"), `power/max_power 0–4` point model, enemies watcher/shadow/runner/tank/sniper/phantom/crawler/swarm | data/districts/districts.json | **nobody** (no `districts.json` ref in scripts/tools) | **DEAD** (same class as O1; kept in inventory, not flagged — it changes no live number) |
| B1 | Boss | Architect hp/dmg | 800 / 40; GDD §6.2 row pins both; armor 25 % and resist B 0.5 / S 0.6 / BL 0.7 / F 0.8 / E 0.9 / P 0.4 are **code-only** (no GDD column) | roster `beast` + monster_boss.tres + GDD:181 | combat | LIVE |
| B2 | Boss | phases | P1 r>0.66 (ranged balls 20, teleport 6 s, stun-weak since WAVE 6); P2 0.66≥r>0.33 (invisible outside flashlight cone, ≤3 shadow adds); P3 r≤0.33 (melee enrage + beams 25 @ 4 s); `boss_phase_changed` event | boss_3d.gd:46–59 | fight logic, audio | LIVE |
| B3 | Boss | encounter audio | intro sting at first contact (−2 dB), `enter_boss` music; win = ending preset (see GAMEFEEL_SPEC 3.24) | boss_3d.gd:36–45 | audio | LIVE |
| B4 | Boss | reachability guard | player–boss >10 m for 1.5 s → boss teleports back (P2/P3 never self-approach) | base_monster `_boss_keep_near_player` | anti-stall | LIVE |
| M1 | Enemies | Hunter | 120 / 35 / armor 2 / B 1.1; GDD-pinned via WAVE 6 note; tres agrees | roster `runner`, monster_hunter.tres | combat | LIVE |
| M2 | Enemies | Crawler | 50 / 20 (roster `dog`), light-flee, `crawlers_ignore` under ghost | roster + tres 50/20 | combat, N14 | LIVE |
| M3 | Enemies | Watcher | 80 / 12 / attack_range 18 m — driven by roster `sniper` per AI_TO_ROSTER (WAVE 6 note: stationary sentinel, light-stun→rage per GDD §6.2, *not* a real sniper) | roster `sniper`, tres 80/12 | combat | LIVE |
| M4 | Enemies | Sharpshooter | 60 / **50** / armor 10, ranged 18 m, backstab-weak | roster + tres | combat — 50 dmg vs player 100 hp = half an encounter in 2 shots; pacing-verified by bot (KNOWN_ISSUES), not flagged | LIVE |
| M5 | Enemies | Destroyer / Brute / Burner / Rotter / Hound / Shadow | 200/25 · 350/30 · 90/15 · 140/10 · 40/18 · **30/15** — Shadow absent from roster: `get_entry_for_ai("shadow") → {}` → .tres values live; all tres↔roster pairs consistent | roster + data/monsters | combat | LIVE |
| M6 | Enemies | Tvar (mini-boss) | 1200 / 40 / armor 20 / B 0.6, S 0.7, BL 0.8, F 0.9, E 1.5, P 0.6; speed 50 chase 50 (tres) vs roster 3.0 m/s; weakness `strobe_combo` (3 hits in a combo window, tvar_3d header) | roster `tvar`, monster_tvar.tres, GDD:180 | combat | LIVE (EHP vs B1 = O3) |
| M7 | Enemies | codex table | 8 entries, transliterated, hp/dmg **disagree** with live (watcher 60/10 vs 80/12; sniper 40/25 vs 60/50; "tank 200/40" ≈ destroyer hp + boss dmg) | data/bestiary/bestiary.json | encyclopedia_manager preloads 12 monster `.tres`, not this JSON | **DEAD/DISPLAY-drift** (inventory only) |
| E1 | Economy | kill payout | randi 5–15 coins ×`rewards` knob (sprint ×1.5) | base_monster `_die` | wallet | LIVE |
| E2 | Economy | daily template pay | 10/kill, 15/secret, 40/streetlight, 60/restore, 6.6/min, 25/photo, 30/dark-seg — 60 templates (five event types × 11, photo ×3, dark-segment ×2), reward range 10–780 | content/daily_challenges.json | daily manager `_tick`/`_complete` | LIVE |
| E3 | Economy | streak | 7→150, 30→750, 100→3000 coins | same | `_streak_bonus` | LIVE |
| E4 | Economy | coin ceiling | MAX_COINS 9 999 999 (integrity watchdog) | integrity_guard.gd | anti-cheat clamp | LIVE |
| E5 | Economy | event payouts | secret +50, district restored +200, achievement +100 coins, each ×`rewards` knob (sprint 1.5) | rewards_manager.gd | CoinWallet + inventory_notice | LIVE |
| E6 | Economy | daily legacy | 30 templates, identical id/type/reward grid, no flavor/i18n keys | data/daily_challenges.json | loaded **only** if content file missing (`DATA_PATH_LEGACY`) | LEGACY-FB |
| P1 | Player | baseline | max_hp 100, pistol 25 (weapon_base default), rifle 12 hitscan, shotgun pellets 8; skill `damage_boost_1/2` +10 % each; flashlight cone +25 % damage, crit multiplier (GDD §"Итоговый урон") | player_3d.gd:233, weapons/*.gd, GDD:134 | combat | LIVE |

### Derived figures (arithmetic on the table above — no new data)

Bullet EHP = hp ÷ (bullet-resistance × (1 − armor)):
Architect **800 ÷ (0.50 × 0.75) = 2 133** · Tvar **1200 ÷ (0.60 × 0.80) = 2 500**.
Pistol DPS math used in O3: 25 dmg → per-shot after res+armor: Architect
9.375 (85.3 shots), Tvar 12.0 (100 shots) — at GDD cone-bonus +25 % both scale
identically, so the ordering stands with or without it.

## Outliers — exactly 3, proposed values only, NO edits

### O1 — Three NG+ scalars exist; two are dead and *disagree* with the live one
**Evidence.** N1–N6 (live): per-level additive — NG+3 ⇒ enemy HP ×1.60, enemy
dmg ×1.45, XP ×1.75. N7 (dead JSON): flat enemy ×1.5 / XP ×1.2 regardless of
level. N8 (dead system): a 4th ×1.5 NG+ flag switched on by the *existence of
a marker file* (`user://ngplus.cfg`), not by save state. `data/ng_plus_config.json`
also promises 5 NG+ "unique_achievements" (`ng_plus_start`, `ng_plus_complete`,
`all_secrets`, `all_docs`, `pacifist`) with **no definition anywhere in the
achievements source** — only `secrets_10` exists in achievements_manager.gd.
**Why it's an outlier.** Every one of these is player-facing-adjacent: a
tuning pass that reads the JSON gets wrong numbers; a player who finds the
achievement promise sees a dead promise. This is the exact failure class the
TRUTH WAVE lesson targets (CLAUDE.md: "an 'already done' claim should point at
a real test/gate").
**Proposed values (owner decides):**
- Canonical: keep N1–N6 as-is.
- `data/ng_plus_config.json` → either delete, or rewrite to
  `{"per_ng": {"enemy_hp": 0.20, "enemy_damage": 0.15, "xp": 0.25,
  "player_damage": 0.10, "loot_chance": 0.10}, "max_ng_plus": 3}` as a
  *generated mirror* with a header naming new_game_plus.gd as source, so the
  two can be diffed by a gate.
- `difficulty_manager.gd` → delete the `ngplus ×1.5` lines if kept, or
  archive the file; keep difficulty [0.7/1.0/1.5] only if a consumer wires it.
- The 5 achievements → content adds them (5 rows) **or** the promise retires.

### O2 — Blackout+ advertises a starting state it cannot subtract from
**Evidence.** N11 card text (both `en.desc` and i18n `NGP_BLACKOUT_PLUS_DESC`
family): "One extra district starts DARK. No head start, no mercy." But D1:
**all 11 districts already start stage 0 = DARK** — and the consuming code
says so out loud (random_events.gd:28–33: "has nothing to subtract from at
game start — so the knob widens its blast radius instead"). The shipped
behavior is D5: each random blackout event hits 1+N districts, i.e. an
*in-run hazard*, not a *start state*.
**Why it's an outlier.** Modifier choice is made from the card text
(`new_game_plus_ui.gd` renders exactly these strings). The promise and the
product differ in kind, not degree — a player trading `long_night` for
"no head start" gets… the same head start, plus harsher outages.
**Proposed value:** text-only fix (CONTENT lane — `en.desc` here;
`LocalizationManager` keys re-flowed by the i18n pass, 13 locales), e.g.
"One extra district goes dark with every blackout. The city starts as it
ended: dark." Data knob `1.0` and the behavior **stay untouched** — the
implementation is the correct read of the modifier's name (its own comment
argues this), and it is the only NG+ knob with zero effect if nerfed to the
text. No numeric outlier exists in the knob itself.

### O3 — Bullet EHP inversion: the mandatory mini-boss out-tanks the final boss
**Evidence.** Derived figures: Tvar 2 500 vs Architect 2 133 bullet EHP
(+17 %), despite Tvar being the Act III *mini*-boss (M6) and Architect being
the finale (B1) with a three-phase machine, adds, and a strobe window.
Nominal HP reads backwards in the codex UI (B1 800 < M6 1200) — and the
EHP math shows it isn't even compensated "on paper". Boss armor (25) and
resistances are code-only (B1) — GDD pins hp/dmg/speed/vision/hearing only
(GDD:180–181), so an armor edit does not touch GDD canon.
**Why it's an outlier.** The finale should be the session's peak grind.
Today, a player who skips exploring can be softened up by a *longer* bullet
exchange at Tvar (100 pistol shots) than at the finale (85), and every
"mini-boss is a taste of the boss" heuristic inverts.
**Proposed values (one of the two; (a) recommended):**
- (a) Architect `armor: 25 → 40` (roster `beast` + whatever mirrors it):
  EHP 2 133 → **2 667**, +6.7 % above Tvar; GDD-pinned hp/dmg untouched;
  electric weakness (0.9 ×) and strobe window preserved, so skill still pays.
  Player-facing diff: pistol shots-to-kill 85 → 96.
- (b) Tvar `hp: 1200 → 1000` (EHP 2 500 → 2 083 < 2 133) — cheaper to
  reason about but **contradicts GDD:180's pinned 1200**, so it needs a GDD
  amendment first; not the lazy path.
Either way, re-run `tools/qa_sim/autoplay_bot` seeds 1–10 and
`tools/qa_sim/balance_sim.py` after the change (both exist; no new tooling),
and update `docs/QA_MATRIX.md` NG/SE rows if pacing text quotes the fight.

**Deliberately NOT flagged** (kept to exactly 3 outliers): M4 sharpshooter
damage (50 vs 100 hp) — bot-verified survivable, telegraphed by range; D7/M7
dead-but-harmless legacy files — inventoried above, no live number moves;
E3 streak bonuses — monotone and dwarfed only by the 100-day goal's own
grind, which is the point.

## Cross-references & consistency

- `docs/GAMEFEEL_SPEC.md`: owns feel budgets (hit-stop/shake/flash caps,
  per-event table). Its 3.20 death-timer 🟨 audit and §1 px audit are the
  *feel* side; this file confirms the underlying numbers it reads (roster,
  stage enum, payout ranges) are the ones QA checks. The only data-adjacent
  rows shared: 3.24 (ending preset trauma/flash budgets = shipped
  WowDirector values, unchallenged here).
- `docs/QA_MATRIX.md`: QA-NG-01..04 (this file's §N rows), QA-SE-02 (D6),
  QA-DA-0x (E2/E3), QA-AU-05 & AC rows (feel side). Each outlier has an
  executor row already: O1 → QA-NG-04; O2 → QA-NG-02 (selection UI shows
  the card text being fixed); O3 → QA-NG-01 + §"re-run" note above.
- `docs/VISUAL_PASS.md`: D3 ambient band, E12 LUT, V3 strobe cited by
  GAMEFEEL are that doc's canon; this file cites its stage→ambient table as
  LIVE (matches `world_env_setup`/`district_grading` as of that pass). No
  renderer-value claims added here.
- `docs/KNOWN_ISSUES.md`: boss-velocity drift (WAVE 6) and the flashlight
  P2-cone requirement (lines ~441–470) are why B2/B4 are recorded as *fixed
  and load-bearing* — do not re-flag them as outliers. The 2026-09-10 a11y
  audit is the pattern O1's "point at a gate" rationale borrows.
- `docs/ACCESSIBILITY.md` **does not exist** in this repo (same honest note
  VISUAL_PASS made about its missing named doc); the accessibility canon is
  GDD_SUPPLEMENT §S12.2 + Settings screen + KNOWN_ISSUES record, all cited
  by GAMEFEEL_SPEC §4. Auto-aim and dyslexia font stay removed; this file
  proposes nothing that would silently re-add them.
- Gate status at write time: `bash tools/check.sh --static` → **12/12 green**
  (run 2026-09-16 in this sandbox). Engine gates not runnable here (no Godot
  binary) — recorded as local-agent scope per QA_MATRIX executor rule.

## Reading notes (how not to be fooled by this table)

- "LIVE" was earned by a consumer found in `scripts/`, not by file existence.
- `data/balance/enemy_stats.tres` is an **empty** `EnemyRosterData` instance —
  it inherits the script's default dict, so the encyclopedia and combat share
  one roster today (no drift to flag). If a CODE pass ever populates it, the
  two sources fork and this table goes stale by design — re-run this read.
- MonsterData `.tres` files (12) are display + `shadow` fallback (M5);
  combat numbers come from the roster for every mapped AI id. Both agreed in
  every pair checked (hunter, crawler, watcher, destroyer, brute, burner,
  boss).
