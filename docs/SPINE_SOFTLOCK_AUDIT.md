# Spine Softlock — Residential Audit (2026-09-21)

> **Scope**: `docs/SPINE_SOFTLOCK_AUDIT.md` only, static + log analysis, no code edits.
> **Branch**: `arena/01a0c324-igra`
> **Rejected hypothesis (DO NOT RETRY)**: pickup touch distance 1.4 vs true overlap 1.0. Per `docs/KNOWN_ISSUES.md` 2026-09-21 entry: tightening `PICKUP_TOUCH` to 0.8 made result **0/3 wins** across gas_station/suburbs/school (worse than 2/3 baseline). Reverted, never committed. This audit proposes only other hypotheses.

## 1. Timeline reconstruction — last ~60s before softlock

### Primary incident: seed2, residential, spine_i=1 (from KNOWN_ISSUES + IDEAL_GAP_REPORT)

Source: `docs/KNOWN_ISSUES.md:19-35` + `docs/IDEAL_GAP_REPORT.md:78-82` + bot runner `scripts/tools/_qa_autoplay_runner.gd:27-28,32,46-48,247-260,490-496`

| t (rel) | Evidence | Interpretation |
|---------|----------|----------------|
| t-60s to t-45s | `phase=spine district=residential spine_i=1` — suburbs already FULL per SPINE order `suburbs→residential` (`_qa_autoplay_runner.gd:22`). `PowerGrid` residential stage = DARK (0), needs `cable` → PARTIAL (`power_switch.gd:REPAIR_COST`). Bot `_nearest_pickup(cable)` selects nearest cable. Heartbeat `hb` every 5s (`_qa_autoplay_runner.gd:108-130`) logs `ppos`, `tdist`, `npu` (pickups count). | Bot entered residential via `DistrictTrigger` (box 80,20,80 at `residential.tscn:10`), `WorldRuntime.load_district` built district root, `DistrictLoot.populate` scattered `REPAIR_PARTS` 2×cable/fuse/transistor + `COMMON` + themed. Battery maintained by `_maintain_flashlight()` → `battery` >20, `fl_on=true` expected (same logic that kept boss fight battery >20 in KNOWN_ISSUES boss diagnostic). |
| t-45s to t-15s | Heartbeats show `tdist=1.4-1.5` oscillating for ~30s, never closing. `ppos` stable near pickup. `have_target=true`, `pos=%s` round. No `part_log` entry for cable. | Bot loop: `if distance > PICKUP_TOUCH (1.4) move else stop` (`_qa_autoplay_runner.gd:247-250`). At `walk_speed=170.0` (`data/balance/player_stats.tres:5` — verified correct per `docs/RUN_STATE.md` Session 3, bot 3/3 wins with this speed, 0/3 with 1.7), one physics frame (1/60) moves 2.84m. Pickup `SphereShape3D radius=0.7` (`item_pickup_3d.tscn:6`) + player capsule radius 0.3 (`player_3d.tscn:capsule_shape`) = 1.0 true overlap. Bot stops at 1.4 but Area3D `body_entered` never fires if tunneling. Inventory `try_add` could also silently fail (weight 40kg, slots 12, scrap weight 6.0). |
| t-15s to t-10s | `_stuck_sec` accumulates: `moved <0.03*delta*60` (`_qa_autoplay_runner.gd:488-489`). After `STUCK_NUDGE_SEC=2.0`, `nudge_dir = perp + base*0.3`, `nudge_until = now+1.2` (`491-495`). | Bot considers itself stuck while oscillating at threshold. Nudge at 170 m/s for 1.2s = 204m displacement. Matches observed jump. |
| t-10s to t-5s | Heartbeat shows `ppos` jump 150-250 units between two consecutive 5s heartbeats (KNOWN_ISSUES description). `npu` still >0. | Player launched far outside `NavigationRegion3D` S=40 (80×80 plane at y=0, `main_3d.gd:77-84`) and outside `DistrictTrigger` box. `StreetBuilder` roads centered at 0 with half-size 24, so 200m is void. |
| t-5s to t=0 | No score bump for 45s → `_compute_score()` unchanged (district stages *10 + spine_i*5). Watchdog `SOFTLOCK_SEC=45.0` fires: `SOFTLOCK: no progress for 45s — phase=spine district=residential spine_i=1` (`_qa_autoplay_runner.gd:314-316`). `have_target=true` but stale, `score` frozen. | `WorldRuntime` does not re-trigger district load when player leaves nav region; `_nearest_pickup` now finds far pickup but player cannot path back via direct vector without hitting world edge. Run ends with `FAIL`. |

**Other incidents (same class, different districts)** — from `docs/KNOWN_ISSUES.md:247-249,265` 10-seed table:

- seed8: `residential spine_i=1 1/11` — earliest, severe, same as primary.
- seed9: `school spine_i=3 3/11` — school layout `####..####` with interior walls (if any) but scene same structure; suggests not residential-specific collision.
- seed10: `industrial spine_i=8 8/11` — late spine, still cable/fuse/transistor loop.
- seed2 (different run): `gas_station spine_i=5 5/11` — gas_station.

Pattern: softlock occurs at any district when targeting repair part, not just residential; residential is earliest because it's spine_i=1 and first to need cable after suburbs.

**Player position**: near district center ±22m scatter radius (`district_loot.gd:RADIUS_MIN 6.0 RADIUS_MAX 22.0`), then after nudge 150-250m away.

**AI state**: residential roster `[SHADOW, CRAWLER, CRAWLER]` (`enemy_pool.gd:24`). Shadow `peripheral_range=15` 180° (`shadow_3d.gd`), crawler `vision_range=6` (`crawler_3d.gd:12`). Could be in CHASE/INVESTIGATE, but bot heartbeat does not log AI. No evidence of `State.STUN` loop; `base_monster.gd:_state_chase` breaks to INVESTIGATE if `_player_hiding`, not loop. Need diagnostic to confirm AI not blocking.

**Nearest interactables**: cable pickup (target, `item_pickup_3d.tscn` group `pickups`), PowerSwitch at (8,0,8) (`residential.tscn:14`), DistrictTrigger box 80×20×80.

**Battery**: expected >20, `fl_on=true` per `_maintain_flashlight()` (`_qa_autoplay_runner.gd:233-236`) — same logic that disproved battery/light-gate for boss softlock (KNOWN_ISSUES boss entry). Not root cause.

**District progress**: 1/11 FULL (suburbs), residential 0/3, overall score = suburbs 3*10 + spine_i 1*5 = 35. No progress for 45s.

## 2. Candidate root causes (other than pickup-touch-distance)

### C1: High-speed tunneling / overshoot — player velocity 170 m/s skips Area3D

**Description**: Player `walk_speed=170.0, run_speed=300.0` (`player_stats.tres:5-6`) is canonical, bot-verified correct per `RUN_STATE.md` Session 3 (revert proved 1.7 m/s softlocks 0/3 at spawn). At 60Hz, 170 m/s = 2.83m/frame. Pickup sphere radius 0.7 + player capsule 0.3 = 1.0 overlap diameter 2.0. Bot stops moving when `distance <= PICKUP_TOUCH 1.4` (`_qa_autoplay_runner.gd:248`), but if approaching at 2.8m/frame it jumps from 2.0 away to 0.8 past target in one frame, never overlapping Area3D long enough for `body_entered` to fire. It then stops (distance 0.8 <=1.4) expecting collision pickup, but pickup remains, so next frame distance still 0.8, still stopped, oscillating between move/stop as physics jitter pushes it slightly out to 1.5 then back.

**Evidence**:
- `data/balance/player_stats.tres:5` walk_speed 170.0, `RUN_STATE.md` says 170/300/90 is correct, 1.7 fails.
- `scenes/pickups/item_pickup_3d.tscn:6` radius 0.7, `player_3d.tscn` capsule radius 0.3 → true 1.0.
- `scripts/tools/_qa_autoplay_runner.gd:28` PICKUP_TOUCH 1.4, heartbeat tdist 1.4-1.5 for 30s (KNOWN_ISSUES).
- Tightening to 0.8 made worse 0/3 wins across 3 different districts (KNOWN_ISSUES rejected hypothesis) — consistent with needing even closer approach at high speed, increasing overshoot probability.
- Jump 150-250m matches nudge math: 1.2s *170=204m (`_qa_autoplay_runner.gd:495` nudge_until now+1.2).

**Riskiest assumption**: Godot Area3D `body_entered` does not use CCD at 170 m/s, so tunneling is possible — need to verify via engine docs or by logging overlap vs distance.

**Diagnostic to confirm/reject**:
```bash
# grep existing constants
grep -n "walk_speed\|PICKUP_TOUCH\|radius" /home/user/igra/data/balance/player_stats.tres /home/user/igra/scripts/tools/_qa_autoplay_runner.gd /home/user/igra/scenes/pickups/item_pickup_3d.tscn
```
Log addition (lead dev, no commit needed for this audit, just for next run):
- In `scripts/pickups/item_pickup_3d.gd:_process` add: `if player and player.global_position.distance_to(global_position) < 2.0: print("[pickup_diag] dist=%.2f vel=%.1f bob_y=%.2f entered=%s" % [player.global_position.distance_to(global_position), player.velocity.length(), global_position.y, _picked_up])`
- In `_qa_autoplay_runner.gd:_tick_spine` before move: `print("[bot_vel] tdist=%.2f player_vel=%.1f move_dir=%s" % [player.global_position.distance_to(_target_pos), player.velocity.length(), _dir_to(_target_pos)])`
If `player_vel` ~170 and `tdist` jumps from >1.4 to <0.8 without `body_entered`, confirms tunneling.

### C2: Inventory weight/slot exhaustion blocking try_add

**Description**: `InventoryManager.try_add` returns false if `current_weight + data.weight*amount > capacity_kg` (40.0) or no empty slot (`_first_empty_slot() == -1`) (`inventory_manager.gd:53-78`). It emits `INV_OVERWEIGHT`/`INV_NO_SLOTS` but bot does not listen. Scrap weight 6.0 (`scrap.tres:9`), cable 1.5, fuse 0.4, transistor 0.05, medkit 1.0, battery 0.3. Base slots 12 (`inventory_stats.tres:5`). Bot picks all `COMMON` + `REPAIR_PARTS` (6) + themed + blueprint per district, never discards except repair parts at switch (`power_switch.gd:inv.remove`). After suburbs (first district), it may have 6 scraps (36kg) + other items >40kg or 12 slots filled, so cable pickup in residential fails `try_add`, remains, bot loops at 1.4-1.5 expecting collision.

**Evidence**:
- `scripts/inventory/inventory_manager.gd:53-78` try_add weight/slot checks, returns false.
- `data/items/scrap.tres:9` weight 6.0, heaviest common.
- `data/balance/inventory_stats.tres:5-6` base_slots 12 capacity 40.0.
- `scripts/world/district_loot.gd:14-18` COMMON includes battery,battery,scrap,medkit + REPAIR_PARTS 6 items per district.
- Bot `_nearest_pickup` does not check inventory capacity (`_qa_autoplay_runner.gd:227-237`).
- No `INV_OVERWEIGHT` log in known softlock description, but also no heartbeat for inventory.

**Riskiest assumption**: Bot actually fills inventory before residential cable — need to check weight ratio at time of softlock, which current heartbeat does not log.

**Diagnostic**:
```bash
grep -n "capacity_kg\|base_slots\|weight" /home/user/igra/data/balance/inventory_stats.tres /home/user/igra/data/items/*.tres | head -n 30
```
Log addition:
- In `inventory_manager.gd:try_add` failure path: `print("[inv_diag] FAIL add %s weight %.1f/%.1f slots_used %d/%d" % [item_id, current_weight, stats.capacity_kg, slots.filter(func(s): return s!=null).size(), slots.size()])`
- In `_qa_autoplay_runner.gd` heartbeat: include `inv_weight=%.1f/%s slots=%d` via `InventoryManager.current_weight` and `stats.capacity_kg`.
If softlock heartbeat shows weight ~40 or slots 12/12 with cable still needed, confirms.

### C3: Unreachable scatter placement / collision blocking (navmesh gap / blocked raycast)

**Description**: `DistrictLoot._scatter` uses `ang=randf_range(0,TAU) rad=randf_range(6,22)` from district root (`district_loot.gd:193-196`). District root at 0,0,0. No check against `StreetBuilder` static bodies (ground tiles 4×0.1×4 at y=0.01) or `PowerSwitch` box 0.8×1.6×0.2 at (8,0,8) (`residential.tscn:14`, `power_switch.gd:32-35`). Pickup at y=0.6 bob 0.4-0.8 could spawn inside PowerSwitch collision or outside `NavigationRegion3D` (80×80 plane S=40 `main_3d.gd:77`). Bot's direct vector `_dir_to` uses camera basis, not NavigationAgent, so if pickup behind collision box, `move_and_slide` will block, distance stays 1.4-1.5, stuck detection triggers. Residential fixed spawns mention boiler_room locked by key (`residential_fix_key_01` in `item_spawns.json:73`), but `residential.tscn` has no door mesh/collision — narrative lock without physical lock, yet could be interpreted as needing key.

**Evidence**:
- `district_loot.gd:193-196` scatter no collision check.
- `street_builder.gd:172-188` `_create_collision` per tile creates many StaticBody3D.
- `power_switch.gd:28-35` builds StaticBody3D at (0,0.8,0) local → world (8,0.8,8).
- `residential.tscn` only has StreetBuilder, PowerSwitch, DistrictTrigger, EmissiveWindows, Props — no building walls, so no obvious blocker, but PowerSwitch box is blocker.
- Other districts same scene structure, so if this were sole cause, all districts would softlock equally, but observed residential earliest severe (seed8 1/11) suggests residential-specific fixed spawn (boiler_room) may be targeted.

**Riskiest assumption**: There is actual collision at pickup location — but `residential.tscn` shows no building collision, only ground and PowerSwitch, so scatter could still be reachable; need raycast check.

**Diagnostic**:
```bash
grep -rn "_scatter\|RADIUS_MIN\|RADIUS_MAX" /home/user/igra/scripts/world/district_loot.gd -n
grep -rn "PowerSwitch\|CollisionShape3D" /home/user/igra/scenes/districts/residential.tscn /home/user/igra/scripts/world/power_switch.gd -n
```
Log addition:
- In `district_loot.gd:_spawn_item` after `root.add_child(node)`: `print("[loot_diag] %s at %s dist_root %.1f" % [item_id, str(node.global_position), node.global_position.distance_to(root.global_position)])`
- In `_qa_autoplay_runner.gd:_nearest_pickup`: after finding best, do raycast: `var space=get_world_3d().direct_space_state; var q=PhysicsRayQueryParameters3D.create(player.global_position, best.global_position); var res=space.intersect_ray(q); print("[ray_diag] to pickup %s hit %s dist %.1f" % [best.get("item_id"), res, player.global_position.distance_to(best.global_position)])`
If ray hits StaticBody and distance ~1.4-1.5, confirms blocked.

### C4: Stuck-nudge at high speed launching player out of district / stale target race

**Description**: When `_stuck_sec > STUCK_NUDGE_SEC 2.0`, bot sets `nudge_dir = perp + base*0.3` and `nudge_until = now+1.2` (`_qa_autoplay_runner.gd:491-495`). `_move` then uses nudge_dir instead of target dir (`347-348`). At 170 m/s, 1.2s = 204m, which matches observed jump 150-250 between heartbeats. After jump, player outside `NavigationRegion3D` (S=40, 80×80) and outside `DistrictTrigger` (80,20,80). `WorldRuntime` only loads district on `district_entered` (deferred via `call_deferred("load_district")` `world_runtime.gd:31`), so leaving trigger does not unload, but `_nearest_pickup` may still target old pickup now 200m away. Score never increases, watchdog fires. This is consequence of C1/C3 but could be independent if nudge logic itself is flawed (perpendicular nudge at high speed is too large).

**Evidence**:
- `_qa_autoplay_runner.gd:32` STUCK_NUDGE_SEC 2.0, 46-48 nudge vars, 490-496 stuck logic.
- `main_3d.gd:77` S=40.0 nav mesh 80×80.
- `residential.tscn:10` DistrictTrigger box 80,20,80.
- Jump 150-250m matches 170*1.2=204m.

**Riskiest assumption**: Nudge is cause, not effect — but nudge only triggers after being stuck, so root cause is still why stuck; however nudge magnitude alone makes recovery impossible, turning temporary stuck into permanent softlock.

**Diagnostic**:
```bash
grep -n "STUCK_NUDGE\|_nudge_until\|_stuck_sec\|S :=" /home/user/igra/scripts/tools/_qa_autoplay_runner.gd /home/user/igra/scripts/main_3d.gd
```
Log addition:
- In `_qa_autoplay_runner.gd` nudge trigger: `print("[nudge_diag] STUCK %.1fs at pos %s target %s dist %.1f nudge_dir %s vel %.1f nav_outside=%s" % [_stuck_sec, str(_player.global_position), str(_target_pos), _player.global_position.distance_to(_target_pos), str(_nudge_dir), _player.velocity.length(), _player.global_position.length() > 40.0])`
- In heartbeat, log `outside_nav=%s` via `global_position.length() > 40`.
If after nudge player outside nav and never returns, confirms.

### C5 (bonus): AI blocking / animation lock (weaker, for completeness)

**Description**: Residential roster includes 2 crawlers that leap (`crawler_3d.gd:LEAP_SPEED 8.0`) and could knock player or block path. Shadow teleports behind player (`shadow_3d.gd:_teleport_behind_player`). If monster constantly in CHASE, player could be staggered. Player has `_stun_timer`, `_iframes`, `_damage_grace_timer` (`player_3d.gd`). No evidence of stun loop in logs.

**Evidence**: `base_monster.gd:_state_chase` etc., but no heartbeat logs AI state. Previous boss softlock was Y-dip, not AI loop.

**Riskiest assumption**: AI actually blocks pickup approach — need to log monster positions vs player.

**Diagnostic**: Add to heartbeat: `var monsters=get_tree().get_nodes_in_group("enemies"); for m in monsters: print("[ai_diag] %s state %s pos %s dist %.1f" % [m.monster_id, m.ai_state, str(m.global_position.round()), player.global_position.distance_to(m.global_position)])`

## 3. Ranking by evidence strength

| Rank | Candidate | Evidence strength | Why |
|------|-----------|-------------------|-----|
| 1 | C1 High-speed tunneling / overshoot | **Strongest** — directly explains 1.4-1.5 oscillation, explains why tightening to 0.8 made 0/3 wins worse (harder to hit at high speed), matches verified speed 170 (RUN_STATE), matches pickup radius 0.7, matches jump via nudge math 204m. | |
| 2 | C4 Nudge launching out of nav region | **Strong** — explains 150-250m jump, consequence of C1, but magnitude alone makes softlock irrecoverable. Independent fix (reduce nudge speed or clamp) would mitigate even if C1 remains. | |
| 3 | C2 Inventory full | **Medium** — plausible due to scrap weight 6kg, capacity 40, slots 12, bot never empties; but no log of INV_OVERWEIGHT, and tightening touch distance wouldn't affect inventory, yet tightening made worse, so not sole cause. Still worth checking as secondary. | |
| 4 | C3 Unreachable scatter / collision blocking | **Medium-Weak** — scatter has no collision check, PowerSwitch box at (8,0,8) could block, boiler_room narrative locked; but residential.tscn has no building walls, and other districts same structure yet also softlock (gas_station, school, industrial), so not residential-specific. Needs raycast diagnostic. | |
| 5 | C5 AI blocking | **Weak** — no evidence, but crawler leap could push. | |

## 4. Recommended TOP-1 to try first

**C1 + C4 combined: fix high-speed pickup approach and nudge magnitude.**

- **Why**: Strongest evidence, explains both oscillation and jump, and is actionable without changing game balance (player speed 170 is verified correct, cannot change). The fix is in bot **and** in game: either increase pickup Area3D radius / add CCD, or reduce bot's effective approach speed when near target, or clamp nudge to walk speed.

- **Exact next step for lead dev** (no code edit in this audit, only diagnostic, but recommendation for next session):
  1. Run diagnostic from C1: log player vel and dist to confirm tunneling (see C1 diagnostic).
  2. If confirmed, fix options (choose one, verify with bot):
     - Option A (game): increase `item_pickup_3d.tscn` Sphere radius from 0.7 to 2.0 or add second larger Area3D for high-speed catch, or enable `monitorable` + add `body_entered` with larger shape.
     - Option B (bot): in `_qa_autoplay_runner.gd:_tick_spine`, when distance <5.0, set joy dir length scaled by distance/5.0 (slow down approach) instead of full 1.0, to avoid overshoot at 170 m/s.
     - Option C (bot): clamp nudge velocity: in `_move`, if `now < _nudge_until`, limit `dir` length to 0.3 or set player state to STEALTH (90 m/s) during nudge, reducing jump from 204m to ~108m or less, keeping player inside nav region (40m half-size).
  3. Re-run `QA_SEEDS="1 2 3" bash tools/qa_sim/autoplay_bot` (or 10-seed) and check if residential spine_i=1 still softlocks at same tdist pattern. Expect 2/3 or 3/3 wins if fixed, vs 0/3 with 0.8 touch fix.

- **Acceptance**: 3-seed bot shows no 30s oscillation at 1.4-1.5, pickup collected, no 150-250m jump, residential progresses to PARTIAL. Log shows `[pickup_diag] dist <1.0 vel <50` at pickup.

## 5. What was NOT retried

- Did NOT propose changing `PICKUP_TOUCH` to 0.8 or similar distance-only fix. Per `KNOWN_ISSUES.md`, that was tried, made 0/3 wins across gas_station/suburbs/school, reverted. This audit proposes speed/tunneling and nudge magnitude, not distance threshold.

## 6. Files checked (static analysis)

- `docs/KNOWN_ISSUES.md` (rejected hypothesis)
- `docs/GAME_AUDIT.md`, `docs/RUN_STATE.md`, `docs/IDEAL_GAP_REPORT.md`
- `scripts/tools/_qa_autoplay_runner.gd`, `scripts/tools/_qa_autoplay_bot.gd`
- `scenes/districts/residential.tscn`, `data/districts/district_residential.tres`
- `scripts/world/district_loot.gd`, `street_builder.gd`, `power_switch.gd`, `world_runtime.gd`, `street_props.gd`, `district_layouts.gd`, `enemy_pool.gd`, `main_3d.gd`
- `scenes/pickups/item_pickup_3d.tscn`, `scripts/pickups/item_pickup_3d.gd`
- `scripts/player/player_3d.gd`, `scenes/player/player_3d.tscn`, `data/balance/player_stats.tres`
- `scripts/inventory/inventory_manager.gd`, `data/balance/inventory_stats.tres`, `data/items/*.tres`
- `scripts/enemies/base_monster.gd`, `crawler_3d.gd`, `shadow_3d.gd`

## 7. Self-review

- Scope: only `docs/SPINE_SOFTLOCK_AUDIT.md` created, no code edits.
- Rejected hypothesis not reused.
- 4 candidates + bonus, each with evidence, riskiest assumption, exact grep/log diagnostic.
- Timeline reconstructed from available bot logs/evidence per task.

---
*Audit by fresh-eyes debug engineer, 2026-09-21, branch arena/01a0c324-igra*
