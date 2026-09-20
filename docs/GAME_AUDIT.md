# Full-game design + code audit (2026-09-20)

Lead-dev pass: read core systems, ran the static/scene-node/economy-sim gates and the
full headless engine battery, and fixed the fixable P1s in the same session (ponytail:
shortest diff, reuse before writing). Every finding below cites `file:line` or a run
output; anything without hard evidence is marked HYPOTHESIS.

> **CORRECTION (2026-09-20, same day, later session):** Finding #2 below ("player was
> up to 15x faster than the fastest monster") was WRONG and has been reverted. It was
> based on a static-analysis assumption never checked against actual behavior. The
> `autoplay_bot` QA tool proved it: with the "fixed" values (1.7/3.0/0.9 m/s) the bot
> softlocked 0/3 seeds, stuck within a few meters of spawn, every time — the district
> layout genuinely needs the original traversal speed. With the original values
> (170/300/90) restored, the same bot cleared 5 districts in under 90 seconds. See the
> correction entry in `docs/RUN_STATE.md` for the full trace. Lesson: a code-level root
> cause (no separate scale factor between player and monster velocity) does not by
> itself prove which side of the comparison is "wrong" — verify against the actual
> world scale (here, inter-district distances), not just internal numeric consistency.

## Score table

| System | Score /10 | Status |
|---|---|---|
| Core game loop (`game_manager.gd`) | 7 | as-is |
| Save / NG+ | 6 → 8 | **fixed** (NG+ unreachable, district pointer stale) |
| Districts / save-slot parity | 7 | as-is (prior-session fix already verified) |
| Economy | 5 → 6 | **fixed** (stale comment); sim coverage gap open |
| Monster AI / stealth detection | 5 → 7 | **fixed** (hidden player could still be tracked/hit) |
| Boss fight | 6 → 7 | **fixed** (P1 ranged attack had zero telegraph) |
| Player controller | 6 | as-is (speed "fix" below was reverted, see CORRECTION) |
| Input service | 8 | as-is, no action needed |
| Balance data | 3 | as-is (player speed "fix" reverted, see CORRECTION) |
| i18n | 7 | one gap open, **Cline zone** — not touched |
| Audio | 6 | debug prints fixed; one behavioral HYPOTHESIS left open |
| UI/HUD | 4 → 7 | **fixed** (quickslot badges never refreshed) |
| Zero-shipped-debris | 5 → 9 | **fixed** (13 BOMs, 7 debug prints/commented code) |

## TOP issues found and fixed this session

1. **NG+ was unreachable in practice** — `victory_screen.gd:44-46`'s NG+ button calls
   `NewGamePlus.activate_ng_plus()` then routes to the menu; the only way to actually
   *start* that run is the menu's "Play" button (`start_new_game()` →
   `SaveSystem.reset_all()`), which called `NewGamePlus.reset_for_new_game()`
   (`save_system.gd:351`, now removed) and wiped the level the player just set.
   Fix: `reset_all()` no longer touches NG+ state — a genuinely fresh save (level
   already 0) is unaffected either way. `scripts/core/save_system.gd`.
2. ~~**Player was up to 15x faster than the fastest monster**~~ — **RETRACTED, see
   CORRECTION at the top of this file.** `data/balance/player_stats.tres` had
   `walk_speed=170.0, run_speed=300.0, stealth_speed=90.0`, used directly as
   `CharacterBody3D.velocity` magnitude (`player_3d.gd:538,656-666`, no scale factor
   anywhere) vs. monster speeds (`enemy_roster_data.gd`) of 1.2-6.0. The code-level
   observation was correct; the conclusion that this was a bug was not. Divided the
   player values by 100 last session (1.7/3.0/0.9) without checking behavior first —
   `autoplay_bot` proved that change softlocks the game 0/3 seeds at spawn. Reverted
   to the original 170/300/90 this session; `autoplay_bot` cleared 5 districts in
   under 90s with the revert. The apparent scale mismatch against monster speeds is
   real but unexplained — worth a design look, not a unilateral numeric "fix" again
   without bot verification first.
3. **A hidden player could still be tracked and hit** — `hiding_spot.gd`'s physical
   occlusion blocks the *first* spotting raycast, but once a monster is in CHASE/ATTACK
   it never re-checked hiding: `_state_chase` (`base_monster.gd:389-405`, pre-fix)
   pathed to the player's exact position every frame regardless, and `_deal_damage`
   (`base_monster.gd:459-464`) was a pure distance check with no LOS — a monster could
   hit a hidden player point-blank, including through the telegraph-warn delay window.
   `EventBus.player_hiding_changed` (`player_3d.gd:1056,1065`) was emitted but had zero
   listeners repo-wide. Fixed: `base_monster.gd` now subscribes, `_deal_damage` gates
   on it (single point, covers the telegraph-delay race too), and `_state_chase` breaks
   off into INVESTIGATE at the last-seen position instead of tracking blind (reused the
   existing cold-trail-scaled investigate logic from `_detect_ambient` via a new shared
   `_enter_investigate_at()` helper instead of duplicating it).
4. **HUD quickslot badge counts froze after the first pickup** — contradicts the
   "already done: HUD badge refresh" claim. `hud_3d.gd:856-866` set `Badge.text` from
   inventory count only once, inside `_setup_slot_placeholders()` (`_ready()`-time).
   `EventBus.inventory_changed` fires 9x from `inventory_manager.gd` on every
   pickup/use/craft but nothing in `hud_3d.gd` was connected to it. Fixed: promoted the
   slot-item list to a shared `_SLOT_ITEMS` const and added a `_refresh_slot_badges()`
   connected to `inventory_changed`.
5. **Boss P1's ranged attack had zero telegraph** — `_throw_energy_ball()`
   (`boss_3d.gd:126-135`) spawned a damaging projectile the same frame it was called,
   often the same tick as a teleport-in (`boss_3d.gd:82-92`), with no visual/audio
   wind-up — the only boss attack in the file not routed through the shared
   `MonsterTelegraph.warn()` the base class already provides. Fixed: routed through
   `_telegraph.warn(_throw_energy_ball)`, same pattern `base_monster.gd:_perform_attack`
   already uses.
6. **District pointer survived "New Game"** — `DistrictManager.current_district`
   (default `"suburbs"`) is set from the save on load (`save_system.gd:304-307`) but
   was never reset on `reset_all()` — dying and restarting, or starting fresh after a
   completed run, left the pointer stale at whatever district the player was last in.
   Fixed: `reset_all()` now resets it to `"suburbs"`.
7. **13 files shipped with a UTF-8 BOM** — hard "zero shipped" rule violation:
   `scenes/environment/world_env.tscn`, `scenes/ui/difficulty_screen.tscn`,
   `scenes/ui/district_banner.tscn`, all 6 `data/dialogs/dialog_*.json`,
   `data/economy/economy_config.json`, `data/economy/shop_catalog.json`,
   `data/loot/loot_table.json`, `data/ng_plus_config.json`. Fixed: BOM stripped, JSON
   files re-validated as parseable.
8. **Diagnostic `print()` in shipped runtime code, one genuinely commented-out
   statement** — `save_system.gd` (4x, save-corruption/HMAC-failure diagnostics),
   `net/lan_network.gd` (5x, connection lifecycle), `monetization/stub_crazy_games.gd`
   (1x, web ad-SDK-unavailable notice) all used raw `print()` instead of the
   `push_warning()` convention already established elsewhere in the codebase (9 other
   files). Separately, `scripts/multiplayer/lan_discovery.gd:37` had an actually
   commented-out `push_warning()` call silently swallowing a port-bind failure with zero
   diagnostic — restored it. Fixed all of the above.
9. **Stale economy comment** — `coin_wallet.gd:31-32` claimed shop prices are "30-100"
   as the rationale for a 999999 anti-tamper cap; real catalog prices are 1500-4000
   (`data/shop/*.tres`). Comment corrected; the cap itself was already fine either way.

## Findings documented, NOT fixed this session (with reason)

- **`scripts/net/lan_menu.gd` is entirely unlocalized** (`"LAN"`, `"Host"`, `"Join"`,
  raw English placeholder text at lines 28,33,37,41,45) and is wired live in
  `scenes/main_3d.tscn` — player-reachable, contradicts the "every user-facing string"
  i18n claim. Not fixed: adding keys touches `data/i18n/*.json` across all 13 locales,
  which is `cl/a11y-i18n`'s zone per `docs/AGENT_ZONES.md`, not mine. Flagging for that
  session.
- **`proc_audio.gd` lacks `PROCESS_MODE_ALWAYS`**, unlike its three sibling audio
  autoloads (`audio_manager.gd`, `music_manager.gd`, `streetlight_hum_pool.gd`). Not
  fixed: the file mixes ambient hum (arguably should keep playing through pause, like
  its siblings) with player-driven footstep/flashlight-click SFX (should NOT fire
  during pause) in one node — blanket `PROCESS_MODE_ALWAYS` risks a footstep firing off
  a stale timer during the pause menu. Needs a real design call, not a mechanical
  fix — left as an open finding with acceptance criteria below.
- **Orphaned "Hum" audio bus** — `default_bus_layout.tres:54-59` defines a `Hum` bus
  nothing routes to (`streetlight_hum_pool.gd` actually routes to `SFX`). Dead config,
  low priority, not touched.
- **`scripts/hiding/hiding_spot.gd` — confirmed a second, unused hiding
  implementation** (Area3D-based, `is_player_hiding()`, zero references repo-wide).
  This is very likely *the* file CLAUDE.md's own hard-rule lesson names
  ("never delete unless proven dead *and* not a planned feature — lesson:
  `hiding_spot.gd`"). **Not deleted, per that explicit rule.** Documenting its
  live/dead status here so it doesn't get mis-flagged as new debt by a future pass.
- **Boss P1 melee-during-teleport-windup cheese risk** — HYPOTHESIS, needs a manual
  playtest to confirm; no static-analysis path to verify player-feel timing.
- **`DistrictManager.current_district` mid-session "New Game" via death screen** —
  same root cause as issue #6 above; the death-screen path (`death_screen.gd:53`)
  calls `start_new_game()` directly, so the fix in #6 covers it too. Verified, no
  separate fix needed.

## 5 concrete design improvements (feel/pacing/clarity), with acceptance criteria

1. **Stealth skill branch is thin for a stealth-pillar game.** `skill_tree_manager.gd`:
   `stealth` has 2 skills / 7 SP-to-max (`silent_steps`, `cold_trail`) vs `combat`'s 5
   skills / 21 SP (lines 7-50 vs 139-159). The branch's own comment says it was built
   "on the two real, already-live stealth mechanics" deliberately, reuse-before-write —
   correct call at the time, but it leaves the pillar mechanic the shallowest tree.
   *Acceptance:* stealth reaches parity with survival/utility (≥4 skills, ≥13 SP-to-max)
   by exposing skill-gated tuning on mechanics that already exist in code (e.g. detect
   radius reduction, investigate-timer decay rate already read by `_enter_investigate_at`)
   rather than inventing new mechanics.
2. **NG+ menu-entry clarity.** Now that NG+ actually works end-to-end (fix #1 above),
   the main menu shows both "Continue" (resumes the just-finished save near the ending)
   and "Play" (the button that actually starts the fresh NG+ run) with no indication
   which one the player wants after activating NG+. *Acceptance:* main menu displays
   the active NG+ level when `NewGamePlus.get_current_ng_plus() > 0`, and/or the "Play"
   button's label reflects it (e.g. "New Game (NG+2)").
3. **`tools/qa_sim/balance_sim.py` doesn't model the coin economy at all** — it covers
   parts/hunter-pressure/battery/skills/time-to-win but has no faucet-vs-sink check for
   `CoinWallet`/`ShopService`, which is exactly the class of bug that let the stale
   "30-100" comment (fix #9) go unnoticed. *Acceptance:* sim asserts total reachable
   one-time coin income (secrets+districts+achievements, `rewards_manager.gd`) plus a
   stated repeatable-income estimate covers at least 2 catalog items
   (`data/shop/*.tres`) without repeatable grinding beyond a stated multiplier.
4. **PARTIAL-style time-to-win runs past the stated 3-6h target** — `balance_sim.py`'s
   own output: typical-first-playthrough PARTIAL estimate is ~6.9h vs the design
   target. DARK (the tension-forward default style) lands cleanly in range. *Acceptance:*
   either trim PARTIAL district pacing ~15%, or explicitly document in
   `docs/PRODUCTION_BIBLE.md` that PARTIAL is the longer, more thorough style and the
   3-6h target is DARK-specific.
5. **`proc_audio.gd`'s pause behavior is undocumented and inconsistent with its
   siblings** (see "not fixed" above) — needs an explicit design decision: does ambient
   hum duck-not-stop on pause like `audio_manager`/`music_manager`, or is silence during
   pause intentional? *Acceptance:* either `PROCESS_MODE_ALWAYS` is added with the
   footstep/flashlight-click logic explicitly gated on `not get_tree().paused`, or a
   one-line comment states the current behavior is intentional.

## Evidence run log (this session)

- `bash tools/check.sh --static` — 12/12 green, before and after fixes.
- `python tools/scene_node_check.py` — clean, before and after fixes.
- `python tools/qa_sim/balance_sim.py` — PASS (parts economy, hunter pressure, battery
  economy, skill branches, time-to-win); surfaced findings #3/#4 above.
- Full engine gate battery (`bash tools/check.sh`, non-static) — see
  `docs/RUN_STATE.md` for the result recorded after this pass.
