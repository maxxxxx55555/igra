# Security sweep v2 at `ce782f8`

New exploit candidates beyond the closed set in `docs/SECURITY_PATCH_SPEC.md` and
`docs/ARENA_CLOSURE.md`. Static read only; nothing here was run in Godot. Each row carries a repro,
whether it can be closed, and the exact fix. Local applies the fixes, except row 1, which is already
closed on `cloud/audit-ce782f8`.

**Swept:**
- Guard bypass paths
- Every `user://` file shipped code reads or writes (18 paths)
- Every `@rpc` entry point (14)
- Ad and integrity providers
- Save import and export
- Hardcore flow
- Export filters, `.gdignore`, committed keys

| # | Candidate | Severity | Live? |
|---|---|---|---|
| 1 | `--shot` turns a release session into a revertible one | Low | rc13 desktop; **closed in `a6f4fdb`** |
| 2 | Debug ad stub ships in release and grants rewards with no ad | Medium (revenue, economy) | Yes: every desktop build; Android while the AppLovin key is unset |
| 3 | LAN RPCs without sender or payload checks | High if LAN ships | Dormant: no UI path opens a socket |
| 4 | Hardcore is honour-system (settings toggle + save export/import) | Low | Yes, but no reward depends on it |
| 5 | Local leaderboard unsigned, entries not validated | Low | Yes, local and cosmetic |

## 1. `--shot` makes a release session revertible (closed)

- **Where (rc13):** `scripts/core/qa_launch_guard.gd` `_is_qa_launch()` matched any argument starting
  with `--shot` in any build, snapshotted the profile at launch and restored it at exit.
- **Repro (rc13, desktop release):** start `TheLastStreetlight.exe --shot`, start a hardcore run, die
  (the wipe runs), then quit. The next launch has the pre-launch save back. With an unwritable profile
  the same argument reached `OS.crash` on every such launch.
- **Closable:** yes. **Closed in `a6f4fdb`:** `_enter_tree` returns at once unless
  `OS.is_debug_build()`. Release exports carry no `tools/` scenes, so no legitimate QA launch is lost.

## 2. The debug ad stub ships in release

- **Where:** `scripts/monetization/ad_service.gd:57-63` `_default_provider()`:
  - web → `CrazyGamesStub`;
  - mobile with `monetization/applovin_sdk_key` set → AppLovin;
  - **anything else → `StubAdProvider`**, whose popup calls `_on_provider_reward()` when "claim" is
    pressed (`:187-194`).
- `project.godot` has no `monetization/*` setting at all, so every release build today takes the stub
  path. Offers are live at `scripts/ui/hud_3d.gd:731-748` (extra battery) and
  `scripts/death_screen.gd:13-20` (revive).
- **Repro:** release build, die, press the revive offer, press "claim" on the stub popup. The revive
  is granted and no ad was shown. Limits: once per session each (`SESSION_LIMITED`) and a 1 h
  cooldown.
- **Closable:** yes.
- **Fix:** in `_default_provider()`, return `StubAdProvider.new(self)` only
  `if OS.is_debug_build()`, otherwise `null`. `can_show_reward()` already requires
  `_provider != null` (`:74`), so both offers hide themselves.
- **Before any web release:** check `stub_crazy_games.gd` against the same rule.
- **Check:** assert that `AdService._default_provider()` is null when the debug feature is off. The
  simplest hook is to pass the flag in as a parameter so a gate can drive both branches.

## 3. LAN RPCs without sender or payload checks (dormant)

**Where:**
- `scripts/inventory/inventory_manager.gd:344-384`: `_request_add`, `_request_remove`,
  `_request_use`, `_request_equip` and `_request_unequip` are `@rpc("any_peer")`. They run on the
  authority with any `item_id`, `amount` or slot from any peer.
- `_sync_inventory` (`:379`) is `any_peer`, so *any* peer, not only the host, can overwrite a
  client's whole inventory with `from_dict(payload)`.
- `scripts/enemies/base_monster.gd:692` `_request_damage` has no sender check. Any peer deals up to
  200 per call with no rate limit, which is 6 calls for the 1200-HP boss.
- `base_monster.gd:849` `_sync_monster_state` and `scripts/player/player_3d.gd:1065` `_sync_transform`
  are `any_peer` setters.
- R-07 (`cef6ae6`) only hardened `scripts/net/lan_network.gd`.

**Why it's dormant:** every host, join and discovery call starts from the archived
`scripts/ui/lobby_menu.gd:34-58` or the unreferenced `scripts/net/lan_menu.gd`. No socket opens in
normal play.

**Repro once LAN is enabled:** a client calls `InventoryManager._request_add.rpc_id(1, &"battery", 99)`,
or `monster._request_damage.rpc_id(1, 200.0)` in a loop.

**Closable:** yes. Pick one:
- **Lazy (recommended while LAN is archived):** remove the `LANNetwork`, `LANDiscovery` and
  `NetworkManager` autoloads (`project.godot:62`, `:98`, `:99`) and quarantine `scripts/net/`,
  `scripts/multiplayer/` and `lobby_menu.gd` with the SLOP_REPORT_V2 S-table. The surface is gone.
- **If LAN ships:**
  - Change `_sync_*` to `@rpc("authority", ...)`.
  - In every `_request_*`, read `multiplayer.get_remote_sender_id()`, reject unknown peers, reject an
    `item_id` not in `ItemDatabase`, require `1 <= amount <= max_stack`, and bounds-check slot
    indices.
  - In `_request_damage`, accept only a sender whose player is within weapon range of the monster,
    and rate-limit per sender (≤ 10/s).
  - Copy the sender check from `player_3d.gd:821-826`, which already does it right.
  - Extend `attack_sim` `_check_lan_payload_validation` to the inventory and monster RPCs.

## 4. Hardcore is honour-system

**Where:**
- The hardcore flag lives in unsigned `settings.cfg` and is a toggle in Settings
  (`scripts/ui/settings_screen.gd:95`), read at death (`scripts/core/game_manager.gd:172`).
- Save export/import is in Settings too (`settings_screen.gd:118-125`,
  `scripts/core/save_system.gd:45-68`). An export taken before a death restores the run after the
  wipe.

**Impact today:** none. The only reward tied to hardcore, `ach_18` / `hardcore_clear`
(`scripts/systems/achievements_manager.gd:125-131`), has no grant path; `iron_man` is mapped at
`:281` and never unlocked.

**Closable:** yes, once `ach_18` is wired. Store `hardcore` in the signed save at New Game (not in
settings), lock the toggle during a run, and mark an imported save non-hardcore.

**Adjacent content bug (not security):** 10 of the 20 base achievements have no grant path: ach_06,
ach_07, ach_08, ach_11, ach_12, ach_16, ach_17, ach_18, ach_19 and ach_20. FUNCTION_MATRIX AL33
calls AchievementManager WORKS on "get_all non-empty" only. Tracked in `docs/MERGE_PLAN.md`.

## 5. Local leaderboard: unsigned, entries unchecked

- **Where:** `scripts/systems/local_leaderboard.gd:45-58`. Plain JSON, and `_runs = parsed` takes any
  Array.
- **Impact:** a hand-edited file shows fake local records; a non-Dictionary entry raises script
  errors wherever runs are read.
- **Closable:** yes. Sign it with the `SaveSystem.write_signed`/`read_signed` helper from
  SLOP_REPORT_V2 A3, keep only Dictionary entries with numeric fields, and cap the list length.

## Checked and clean

- **Export leakage:**
  - `include_filter` is empty in all three presets.
  - `docs/` carries `.gdignore`.
  - `_QUARANTINE/**`, `scripts/tools/**`, `scripts/security/**`, `scenes/tools/**` and `tools/**` are
    excluded (`export_presets.cfg:3`).
  - The release keystore fields are empty in `export_presets.cfg`, and no API or SDK key value is
    committed in `scripts/` or `project.godot`.
  - The only export oddity is the ShotTool autoload boot error (SLOP_REPORT_V2 C1), which is not a
    leak.
- **Play Integrity:** `scripts/systems/play_integrity_service.gd` is an honest stub (verdict
  `STUB_NO_SERVER`) and claims nothing.
- **Signed files:** save and slots (B4/P-01), NG+ (P-03), flashlight upgrades (P-04), daily (B6) and
  achievements (legacy trust once, B7) all verify their HMAC before use. `lang.cfg`, `tutorial.cfg`
  and `tls_captions.json` hold no economy state.
- **Save import:** verifies the envelope before copying (`save_system.gd:56-58`). Replaying an older
  signed save is the inherent D-02 class.
- **Permissions:** `internet` (ads) and `vibrate` (`hud_3d.gd:799`, `virtual_joystick.gd:61`) are both
  used.
