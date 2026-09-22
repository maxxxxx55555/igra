# DESIGN_DECISIONS — exact values for lead-dev (no improvisation)

**Owner:** designer-decision. **Zone:** this file only. Do not edit json/code from this pass.
**TZ:** `docs/GDD.md` (канон v4). GDD line 3–6: «Этот документ — единственный источник истины».
**Audit files named in the brief** (`docs/TZ_COMPLIANCE_AUDIT.md`, `docs/DESIGN_CRITIQUE.md`, `docs/BREAK_REPORT.md`) **are absent** on this checkout (`arena/01a0c87e-igra` @ `6f4c841`). Stand-ins read: `docs/INTERIM_TZ_COMPLIANCE.md`, `docs/INTERIM_BREAK.md`, `docs/DESIGN_AUDIT_ARENA.md`. Live numbers grepped 2026-09-22.

Implement the **RECOMMENDED** column verbatim. Do not keep live “winnability” inflations as silent canon.

---

## D1 — Night ambient + moon

**GDD verbatim**
- §4.2 `docs/GDD.md:108-111`: «DARK | 0 | Фонари выключены, ambient 0.03, луна 0.12 — только силуэты»; «STREETS | 2 | Улицы горят, ambient 0.11, луна 0.25»; «FULL | 3 | Район спасён: ambient 0.16, луна 0.40».
- §11.1 `docs/GDD.md:263-266`: «DARK: почти pitch-black (ambient 0.03, луна 0.12) — только силуэты вне конуса.» «LIT/FULL: фонари горят, ambient 0.11/0.16, луна 0.25/0.40.» ««Тьма → зажглись фонари» — главная визуальная награда.»

**Live**
- `scripts/world_env_setup.gd:17-25` — **this is the live owner**: `AMBIENT_DARK/LIT/FULL = 0.12/0.20/0.30`, `MOON_DARK/LIT/FULL = 0.09/0.14/0.20`. Stages 0 and 1 share DARK (`:114-117`).
- `scripts/world/district_grading.gd:16-19` — GDD ambient `[0.03, 0.06, 0.11, 0.16]`, but `world_env_setup.gd:223-226` documents that branch as dead (`world_environment_path` never set).

**GDD gap (not inconsistency):** PARTIAL (`docs/GDD.md:109` «Частичное питание, часть фонарей») has no ambient/moon numbers. §4.2 and §11.1 agree on DARK/STREETS/FULL.

**RECOMMENDED** (stage → ambient, moon)

| Stage | enum | ambient | moon |
|---|---|---|---|
| DARK | 0 | **0.03** | **0.12** |
| PARTIAL | 1 | **0.06** | **0.12** |
| STREETS | 2 | **0.11** | **0.25** |
| FULL | 3 | **0.16** | **0.40** |

PARTIAL ambient = midpoint of 0.03 and 0.11 (same fill `district_grading.gd:17-19` already chose). PARTIAL moon stays DARK: «часть фонарей» is local lamps, not sky. Split `world_env_setup.gd` `match 0, 1` so PARTIAL is not aliased to DARK. Keep `_STAGE_AMBIENT` in `district_grading.gd` identical: `[0.03, 0.06, 0.11, 0.16]`. Do **not** keep 0.12/0.20/0.30; the comment at `world_env_setup.gd:5-8` describes a rejected 0.01/0.03 floor **below** GDD, not a license to exceed it.

**Target:** `scripts/world_env_setup.gd:10,17-25,114-127` (live); `scripts/world/district_grading.gd:19` (keep in lockstep if that branch is rewired).

**Riskiest assumption:** 0.03 is readable on mobile Compatibility with flashlight 45°/8 m/energy 2.0 — not engine-measured this pass; if unreadable, raise toward 0.03 not back to 0.12.

---

## D2 — Flashlight cone / range / energy / color

**GDD verbatim** `docs/GDD.md:76-77`: «Параметры базы: конус 45°, дальность 8 м, цвет `#c9a24a`, energy 2.0, shadow 1024² (опц. на mobile — без теней).»

**Live (three sources, disagree)**
- `scenes/player/player_3d.tscn:179-184` — `light_color = Color(1.0, 0.82, 0.48)`, `light_energy = 24.0`, `spot_angle = 35.0`, `spot_range = 16.0` (first-frame / no-upgrade path).
- `scripts/player/player_3d.gd:1111,1138` — runtime: `spot_angle = 45.0 + a_bonus`, `spot_range = 8.0 * (1.0 + 0.2 * skill_lvl) + _upgrade_range_bonus`; energy `1.0 * (1.0 + b_bonus)` (`:1110`) — **half of GDD 2.0**.
- `data/balance/flashlight_stats.tres:5-7` — `cone_angle_deg = 52.0`, `cone_length_px = 260.0`, `energy_on = 1.1` (2D leftover; not the 3D consumer).

**RECOMMENDED base (L0, no skills)**
- `spot_angle` = **45.0**
- `spot_range` = **8.0**
- `light_energy` = **2.0**
- `light_color` = **`#c9a24a`** = `Color(0.788235, 0.635294, 0.290196)` (already used on PlayerGlow at `player_3d.tscn:209`)
- Scene defaults **must equal** these so frame 0 is not 35°/16 m/energy 24.
- Runtime: `flashlight.light_energy = 2.0 * (1.0 + b_bonus)` (not 1.0). Angle/range formulas stay; L1 angle is 45+10=55 per `docs/GDD.md:90`.
- Do not drive 3D from `flashlight_stats.tres` 52°/1.1. Ignore `cone_length_px`.

**Target:** `scenes/player/player_3d.tscn:179-184`; `scripts/player/player_3d.gd:1110-1111,1138`; `scripts/world_env_setup.gd:83` (comment already states 8.0/45 — make code match).

**Riskiest assumption:** energy 2.0 + ambient 0.03 will not bloom-blow Compatibility; if it does, cut glow not the cone.

---

## D3 — Combo damage

**GDD verbatim** `docs/GDD.md:127-133`: table «1 Jab | 0.25 s | 0.15 s | **8** | 5»; «2 Cross | 0.30 s | 0.15 s | **12** | 5»; «3 Slam | 0.45 s | 0.20 s | **20** | 8 | knockback 1.5 м». «Окно комбо 1.2 s.»

**Live** `scripts/player/player_3d.gd:75-81` — comment «урон мили-комбо поднят (~×1.75)» for the autoplay bot; `dmg` **14 / 21 / 35**. Windup/active/stam/knockback already match GDD. Recovery 0.15/0.15/0.20 is unspecified in GDD.

**RECOMMENDED** `COMBO_DATA` damage **8 / 12 / 20**. Keep windup/active/stam/knockback/window. Keep recovery 0.15/0.15/0.20 (GDD-silent fill; do not invent a deletion). Do not keep ×1.75.

Shadow HP 30 (`docs/GDD.md:172`) was authored against 8/12/20 (full combo 40). Live 70 overkills Act I.

**Target:** `scripts/player/player_3d.gd:79-81` (`"dmg"` keys only).

**Riskiest assumption:** Architect (HP 800, `docs/GDD.md:181`) remains completable at 8/12/20 once D9 hitbox is restored — bot timeout was a pathing/hitbox issue, not a DPS-spec issue.

---

## D4 — District lock-graph

**GDD verbatim**
- §4.1 `docs/GDD.md:101-103`: «Районы (11, **фиксированный порядок восстановления**)» then ``suburbs → residential → park → school → hospital → gas_station → police → warehouses → industrial → substation → power_station``.
- §4.3 `docs/GDD.md:114`: «Район открыт, если все его пререквизиты (`powered_by`) в FULL».
- §12.3 `docs/GDD.md:338`: «Акт I (D1–3): выживание, дом, первый фонарь».

**Live** `data/districts/district_*.tres` `powered_by`:

| id | live | GDD-chain parent |
|---|---|---|
| suburbs | `[]` | `[]` |
| residential | `[suburbs]` | `[suburbs]` |
| **park** | **`[suburbs]`** | **`[residential]`** |
| school | `[residential]` | `[park]` |
| hospital | `[residential]` | `[school]` |
| gas_station | `[park]` | `[hospital]` |
| police | `[park]` | `[gas_station]` |
| warehouses | `[hospital]` | `[police]` |
| industrial | `[warehouses, police]` | `[warehouses]` |
| substation | `[industrial]` | `[industrial]` |
| power_station | `[substation]` | `[substation]` |

**Inconsistency (not silent):** §4.1 is a lock order; §4.3 is the mechanism (array can be multi-parent). Content bible (`content/world/characters.json:119`) was authored against the live DAG («school's guaranteed closure is {residential, suburbs}»). **Reading chosen: §4.1 topology + §4.3 mechanism.** Heading is «порядок восстановления», not «нумерация». Act I «дом» is residential (D2); park-from-suburbs skips it. Plural `powered_by` stays valid; this chain simply has one parent each. Industrial AND `[warehouses, police]` is redundant once police is ancestor of warehouses.

**RECOMMENDED** `powered_by` (exactly):

```
suburbs:        []
residential:    [&"suburbs"]
park:           [&"residential"]
school:         [&"park"]
hospital:       [&"school"]
gas_station:    [&"hospital"]
police:         [&"gas_station"]
warehouses:     [&"police"]
industrial:     [&"warehouses"]
substation:     [&"industrial"]
power_station:  [&"substation"]
```

Travel/map must respect `PowerGrid.is_unlocked` (`scripts/world/power_grid.gd:32-36`). Related live break (not a design number): park Travel → `(inf,inf,inf)` — `docs/INTERIM_BREAK.md` BRK-01.

**Target:** `data/districts/district_{park,school,hospital,gas_station,police,warehouses,industrial}.tres` field `powered_by`. Content-bible reachability notes are CONTENT-zone follow-up (Architect reveal stays hospital STREETS; after this chain school is on the path to hospital, gas_station is after it).

**Riskiest assumption:** no required pickup/quest is currently only reachable by entering park before residential FULL.

---

## D5 — NG+ rules (GDD gap)

**GDD verbatim:** no rules. Only existence claims `docs/GDD.md:652` and `:703` «New Game+» on the implemented checklist. Endings `docs/GDD.md:344-350`. Hardcore `docs/GDD.md:161` «Hardcore (настройка): 1 жизнь, смерть = удаление сейва.» Hunger OUT `docs/GDD.md:196-197`.

**Live (disagree with each other)**
- `scripts/systems/new_game_plus.gd:22-27` — cap 3; per-level XP +0.25, enemy dmg +0.15, enemy HP +0.20, player dmg +0.10, loot +0.10. **No runtime loader** for `data/ng_plus_config.json` (`ng_plus_enemy_mult` 1.5 / `ng_plus_xp_mult` 1.2) — `docs/DESIGN_AUDIT_ARENA.md` P3 already traced this.
- `new_game_plus.gd:204-209` `reset_for_new_game()` **zeros** NG+. `docs/DESIGN_AUDIT_ARENA.md` P3: save reset must **retain** NG+.

**Inconsistency:** GDD silent vs two live number sets. **Reading chosen:** GDD-tone + the **loaded** constants in `new_game_plus.gd`, not the dead JSON. Do not invent a fourth multiplier table.

**RECOMMENDED minimal rules (implement verbatim)**

1. **Cap** = **3**. `MAX_NG_PLUS = 3`.
2. **Unlock** = any `GameManager.trigger_win()` (GDD §4.3 `:119` / §12.4). Death/«Тьма» does not unlock.
3. **Activate ≠ start.** Victory → NG+ setup → Activate increments level by 1 (clamped) and does not reset the world. Starting the run is main-menu New Game. (Copy: `docs/I18N_VOICE_FIXES.md` `NG_PLUS_ACTIVATED`.)
4. **Persist** in `user://ng_plus_data.json`: level, active flag, modifier ids. Independent of save slot. Continue loads the save; it does not change NG+ level.
5. **New Game with NG+ active:** suburbs DARK, empty inventory, coins 0, skills 0, districts 0. **Keep** NG+ level + selected modifiers. Do **not** call `reset_for_new_game()` from New Game. `reset_for_new_game()` is only for a true base-game wipe (no NG+).
6. **Per-level multipliers** (applied once, stacked with modifiers via existing multiply):

| knob | per NG+ level |
|---|---|
| enemy HP | **+0.20** |
| enemy damage | **+0.15** |
| XP | **+0.25** |
| player damage | **+0.10** |
| loot chance | **+0.10** |

   NG+1 = 1.20 HP / 1.15 dmg / 1.25 XP / 1.10 player dmg / 1.10 loot.

7. **Modifiers:** keep `content/ngp_modifiers.json` (one pick per NG+ level, exclusive_with honored). No new knobs this pass.
8. **Same 11-district chain (D4), same flashlight (D2), same combo 8/12/20 (D3).** Do not retune base combat to “make NG+ work”.
9. **Hardcore** remains `settings_manager` toggle, orthogonal to NG+.
10. **No hunger/thirst.** GDD §8 OUT. Temperature stays `[M4]`, not an NG+ hook.
11. **Ignore** `data/ng_plus_config.json` (1.5 / 1.2). Do not load it. Prefer delete in a later CODE pass.

**Target:** `scripts/systems/new_game_plus.gd:22-27,88-98,204-209`; callers of `reset_for_new_game` / `activate_ng_plus`; `scripts/ui/new_game_plus_ui.gd`, `scripts/ui/win_screen.gd`, `scripts/ui/main_menu.gd` (P3 routing). Dead file: `data/ng_plus_config.json`.

**Riskiest assumption:** `trigger_win()` is the only victory path; if a credits skip exists, it must not grant NG+.

---

## Further GAP-DEV numeric rows (GDD vs live)

Named audit `TZ_COMPLIANCE_AUDIT.md` absent; rows below are GDD-numeric vs live, verified by read/grep. INTERIM TZ-02 (hit-stop ≤80 ms) is **GAP-DEV needing in-engine measurement**, not a design number — no value invented here.

| ID | GDD verbatim | Live | RECOMMENDED | Target |
|---|---|---|---|---|
| D6 | `docs/GDD.md:83` «Расход: 1%/2 с (конус включён), 0 в выключенном.» | `player_3d.gd:96` `BATTERY_DRAIN_PER_SEC = 100.0/450.0` (7.5 min; comment admits 5 min “не дотягивали”) | **0.5** units/s at max 100 (= 1%/2 s, 200 s full). Pickup **+25** stays. Drain 0 when off. | `scripts/player/player_3d.gd:96` |
| D7 | `docs/GDD.md:141` «Атака: Box 0.6×0.4×1.2 м перед камерой» | `player_3d.gd:323-347` box `1.4×0.8×3.4` offset z=1.4 **plus** sphere r=2.7 (bot winnability) | Box **0.6×0.4×1.2**, offset in front of camera, **delete the sphere**. Active-frames only. | `scripts/player/player_3d.gd:323-347` |
| D8 | `docs/GDD.md:511` regen exists only as skill `health_regen`. No base regen in §5. | `player_3d.gd:101,491-494` `_BASE_HP_REGEN_PER_SEC = 18.0` always on | Base regen **0**. Skill path `2.0 * regen_lvl * delta` stays. | `scripts/player/player_3d.gd:101,491-494` |
| D9 | `docs/GDD.md:181` Architect «Урон 40». Dodge i-frames `docs/GDD.md:148` «I-frames 0.35 s» | `player_3d.gd:799-801` `amount = minf(amount, 12.0)`; `:110,790-794` mercy i-frames 0.8 s | **No incoming damage cap** (Architect 40 lands). **Delete** `_DAMAGE_GRACE_SEC` / `_damage_grace_timer`. Keep **only** dodge i-frames **0.35** s. | `scripts/player/player_3d.gd:110,790-801` |
| D10 | `docs/GDD.md:79` «Мерцание при заряде <20%» | `flashlight_stats.tres:11` `flicker_battery_threshold = 30.0` | Flicker below **20**. | consumer of that threshold (player flashlight update) + `data/balance/flashlight_stats.tres:11` if still read |
| D11 | `docs/GDD.md:81` strobe «STUN врагов в конусе 1.5 s, кд 10 s» — cone = flashlight cone (D2: 8 m / 45°) | `player_3d.gd:825-827` `STROBE_RANGE = 12.0`, `STROBE_HALF_ANGLE = 0.45` (comment «конус 52°»; the `* PI` at `:846` is a separate CODE bug) | `STROBE_RANGE = **8.0**`. Strobe cone **is** the flashlight cone (`spot_angle` 45, range 8) — same test, no second magic number. Stun **1.5** / cd **10**. Cost 5 is GDD-silent — **keep 5**. | `scripts/player/player_3d.gd:825-827,846` |

Do not compensate D3/D7/D8/D9 by raising combo or HP. Bot/arena issues are CODE, not a second damage spec.

**Walk/run 170/300** (`data/balance/player_stats.tres:5-6`): GDD gives no walk m/s, only sprint ×1.6 (`docs/GDD.md:70`). **No number invented.** Flag only: 170 m/s is why dodge was cut to ×0.9 (`player_3d.gd:1013-1017`). Separate scale pass; not this table.

---

## Implementation order

D4 (lock) → D2+D1 (see by flashlight, not ambient) → D3+D7 (combat canon) → D6/D8/D9/D10/D11 → D5 (NG+ on top of canon numbers).

Voice strings: `docs/I18N_VOICE_FIXES.md` (locale owner applies; this pass does not edit json).
