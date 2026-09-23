# Security patch specification

**Audit date:** 2026-09-21 (static-only; no engine run and no source-code changes)

**Scope:** client-only Godot game, including the offline save/economy/achievement/NG+ paths, the
optional LAN peer path, exported presets, and persisted files under `user://`.

**Owned file:** this document only. The implementation snippets below are normative instructions
for the lead developer; they are not changes made by this audit.

## Executive verdict

The main save has a real HMAC envelope, atomic writes, three backups, and a 50-mutant probe in
`docs/SECURITY_THREAT_MODEL.md:8-25` and `scripts/core/save_system.gd:115-146`. That is useful
against casual file edits and corruption. It is not an anti-cheat root of trust because the HMAC
key is in the client at `scripts/core/save_system.gd:8-24`.

The material gaps found in the current checkout are:

1. **P1:** the main-save legacy `checksum` path accepts an attacker-created unsigned save, and
   `_migrate()` does not itself rewrite it (`scripts/core/save_system.gd:170-225`). The same
   compatibility ambiguity exists for legacy achievements (`scripts/systems/achievements_manager.gd:206-211`).
2. **P1:** `ng_plus_data.json` is entirely unsigned; `active` and `modifiers` are not validated,
   although they control difficulty, rewards, battery, time pressure, and achievement eligibility
   (`scripts/systems/new_game_plus.gd:186-218`).
3. **P1:** `flashlight_upgrades.cfg` is entirely unsigned gameplay authority; all five levels are
   trusted without a range check (`scripts/systems/flashlight_upgrade_manager.gd:130-146`).
4. **P1:** the daily state file is unsigned and its anti-replay decision trusts the system clock
   (`scripts/systems/daily_challenge_manager.gd:89-105,153-171`). Signing closes hand edits only;
   it cannot close clock rollback in an offline client.
5. **P1/P2:** slot HMACs are not bound to a slot. A valid save from B is accepted as A by design
   (`scripts/security/attack_sim.gd:145-159`), so slot identity is not an integrity boundary.
6. **P1:** the documented runtime watchdog is not instantiated: `IntegrityGuard` is absent from
   the `[autoload]` list (`project.godot:56-114`) even though its file exists
   (`scripts/systems/integrity_guard.gd:24-107`). No live speed/teleport watchdog is therefore
   present.
7. **P1:** release distribution has no PCK encryption or runtime package verification; Web assets
   are necessarily client-visible. `script_export_mode=1` is already set, which raises the bar but
   does not change the client-side ceiling (`export_presets.cfg:11-87`).
8. **P2:** the tracked export preset contains debug keystore credentials and points at a debug
   keystore (`export_presets.cfg:23-27`). The keystore file itself is ignored/not present in this
   checkout, but the preset still leaks credentials and has empty release-signing fields.

Nothing here treats local achievements, local leaderboards, or local daily rewards as an online
trust failure: there is no server-side award or leaderboard to poison. The impact is local state,
progress, display, or optional LAN peers only.

## Verification basis and stale claims

- Read first: `docs/SECURITY_THREAT_MODEL.md:1-65`.
- Read save and persistence code: `scripts/core/save_system.gd`, `save_data.gd`, achievement,
  economy, XP/skill, NG+, daily, caption, flashlight-upgrade, leaderboard, settings, and tutorial
  managers.
- Read exports: `export_presets.cfg:1-87` and `docs/EXPORT_HARDENING.md:1-57`.
- The current `attack_sim` actually has six check calls, not the 14 cases claimed by the release
  docs: `scripts/security/attack_sim.gd:26-41`. The existing shell gate is wired at
  `tools/check.sh:216-240`; its timeout protects the process, but a prior direct run hung in
  autoload/import work before `_ready()` as recorded in `docs/RUN_STATE.md:176-194`.
- No file or row literally named `TZ` exists in this checkout. The security-relevant matrix rows
  used for cross-checking are `docs/QA_MATRIX.md:165-168` (`QA-SEC-01` and `QA-SEC-04`) plus the
  cheater findings at `docs/QA_SWARM_FINDINGS.md:8-18`.

## 1. Persistence, tamper, and authority inventory

### 1.1 What the current HMAC actually covers

| Persisted path / fields | Current protection | Assessment |
|---|---|---|
| `tls_savegame.save` and `tls_savegame_slot1..4.save`, including `wallet`, `shop`, `upgrades`, `inventory`, `power`, `progress`, `settings`, `player_pos`, `district`, `quests`, `xp`, `skill_tree`, `photos`, `daily_streak`, `last_daily_time`, `onboard_done`, and slot `timestamp` | `_write_atomic()` serializes the body and HMACs the exact `data_json` bytes (`scripts/core/save_system.gd:115-133`); payloads are assembled at `scripts/core/save_system.gd:261-282` and `439-460` | **Signed on new writes.** A byte flip, truncation, append, wrong type, or stale outer HMAC is rejected before load; backups are tried at `scripts/core/save_system.gd:233-252`. This is corruption/casual-edit protection, not a secret against a reverse-engineered client. |
| `power` and `progress` | `progress_hmac` is put inside the already-signed body at `scripts/core/save_system.gd:115-123`; verification is at `202-210` | **Not an independent trust root.** It helps only on the old unkeyed compatibility path, and that path is itself the gap below. |
| `achievements.cfg`: `unlocked`, `progress` | HMAC on new format at `scripts/systems/achievements_manager.gd:191-205,213-217` | **Signed for new format, but legacy plain JSON is trusted and immediately re-signed at `206-211`. Unknown IDs and unbounded progress are also accepted.** |
| `ng_plus_data.json`: `ng_plus`, `active`, `modifiers` | Plain JSON read/write at `scripts/systems/new_game_plus.gd:186-218` | **Unsigned gameplay authority.** `ng_plus` is clamped, but `active` and every modifier entry are trusted. |
| `flashlight_upgrades.cfg`: `brightness`, `range`, `stability`, `angle`, `battery` | Plain JSON read/write at `scripts/systems/flashlight_upgrade_manager.gd:130-146`; values affect the player at `scripts/player/player_3d.gd:1099-1117` | **Unsigned gameplay authority.** A file edit grants all upgrade levels. |
| `tls_daily.json`: `today_id`, `progress`, `last_completed_day` | Plain JSON read/write at `scripts/systems/daily_challenge_manager.gd:153-171` | **Unsigned reward-claim state.** It is also coupled to a mutable wall clock. |
| `tls_leaderboard.json`: local run `time`, `kills`, `districts`, `ending`, `unix` | Plain JSON at `scripts/systems/local_leaderboard.gd:9-10,29-58` | **Unsigned claimed performance, not gameplay authority.** Local-only by design. |
| `leaderboard.json`: `name`, `score`, `level`, `time`, `date` | Plain JSON at `scripts/systems/leaderboard.gd:3-34` | **Unsigned and currently dormant** (no `Leaderboard` autoload in `project.godot:73-114`). If reactivated, it must not be presented as trusted. |
| `settings.cfg`: audio/language/settings dictionary | Plain `ConfigFile` at `scripts/systems/settings_manager.gd:233-250`; `from_dict()` clamps volumes but merges every setting key/value at `564-580` | **Unsigned preference state.** Mostly presentation/accessibility; do not use it as a difficulty, reward, or achievement authority. |
| `lang.cfg`, `tutorial.cfg`, `onboarding.cfg`, `tls_captions.json` | Plain local preferences at `scripts/i18n/localization_manager.gd:175-185`, `scripts/systems/captions_manager.gd:78-92`, `scripts/ui/tutorial_system.gd:170-182`, and `scripts/ui/onboarding.gd:59-68` | **Not gameplay authority.** Editing them changes UI/tutorial visibility only. |
| `diff.cfg`, `ngplus.cfg`, `user://saves/*.json` from `DifficultyManager` / `SaveSlotManager` | Plain local files at `scripts/systems/difficulty_manager.gd:27-34` and `scripts/systems/save_slot_manager.gd:10-43` | **Dormant legacy paths**: neither manager is an autoload in `project.godot:73-114`. If any caller is restored, they become unsigned persistence holes. |

**Unsigned-field answer:** the live gameplay-authority fields that are unsigned are exactly
`ng_plus_data.json.ng_plus/active/modifiers`, all five `flashlight_upgrades.cfg` branch levels,
and the daily claim tuple `today_id/progress/last_completed_day`. The local leaderboard records
and the dormant legacy files are unsigned but are not current game authority. Achievements are
not unsigned on the new format; their legacy acceptance remains a compatibility bypass.

### 1.2 Closed corruption cases (not authority findings)

- **Byte flip:** change one byte in the outer envelope or `data_json`; `_read_envelope()` rejects
  malformed JSON, a changed body, or a stale HMAC at `scripts/core/save_system.gd:155-186`.
- **Truncation/partial write:** truncate the main file or a backup; the same parser rejects it and
  `_read_validated()` tries `.bak`, `.bak2`, and `.bak3`, then quarantines an unreadable main file
  at `scripts/core/save_system.gd:233-252`.
- **Impact:** the current control loses the newest write or starts from clean state; it does not
  silently load a modified authority body. This does not cover the legacy checksum bypass in P-01,
  unsigned sidecar files, or a player who extracts the client key.
- **Closable?** **Yes for corruption detection** (already present for the new main-save format);
  **no** as proof of authenticity against a modified client.
- **Riskiest assumption:** all critical authority is routed through the new main envelope and its
  backups; the sidecar gaps listed below disprove that assumption today.

### 1.3 Findings

#### P-01 — Main-save legacy checksum bypass (P1)

- **Evidence:** `scripts/core/save_system.gd:170-180` accepts `checksum = body.sha256_text()`
  whenever `hmac` is absent. `_migrate()` only changes the in-memory version and returns at
  `218-225`; it does not call `_write_atomic()`.
- **Attack steps:** (1) Copy a real save. (2) Remove `hmac`, keep or replace `data_json` with
  arbitrary JSON authority, and set `checksum` to the new body's plain SHA-256. (3) Place it at
  `user://tls_savegame.save` or a slot. (4) Start/continue before an autosave or checkpoint.
- **Impact:** An editor can inject wallet, power, progress, quests, XP, skills, inventory, or
  position without the HMAC key. The accepted state can remain unsigned until a later write.
- **Closable?** **Yes, only by rejecting unsigned legacy envelopes.** There is no cryptographic way
  to distinguish an authentic old plain-checksum file from an attacker-created one. If automatic
  compatibility must remain, this is an inherent residual and must not be called closed; at least
  re-sign immediately after a successful legacy read to shorten the window.
- **Riskiest assumption:** Existing legacy players are more important than refusing an
  unauthenticated authority file.

#### P-02 — Achievements legacy migration and weak schema (P2, local-only)

- **Evidence:** `scripts/systems/achievements_manager.gd:191-211` trusts any plain dictionary as
  legacy, then writes a new HMAC envelope. `203-204` also accepts any dictionary for `unlocked`
  and `progress`; `219-223` reads values without roster/type/range checks.
- **Attack steps:** (1) Replace `user://achievements.cfg` with
  `{"unlocked":{"ach_01":true},"progress":{"ach_05":999999}}`. (2) Launch once. (3) The
  file is trusted and re-signed.
- **Impact:** Local trophies and their local reward signal can be fabricated; no online leaderboard
  or server payout is affected. Unknown IDs can pollute local state.
- **Closable?** **Yes** for strict mode: reject the plain legacy shape, require a versioned HMAC
  envelope, allow only IDs in `ACHIEVEMENTS`, and clamp progress to each known target. Automatic
  migration of old unsigned trophies remains cryptographically unclosable for the same reason as
  P-01.
- **Riskiest assumption:** Achievements are device-level history and should survive Reset Progress
  (`docs/SESSION_REPORT_TRUTH.md:66-69`), so rejecting old files may be a UX decision.

#### P-03 — NG+ file is unsigned and modifier selection is not reconstructed safely (P1)

- **Evidence:** `_load_save()` reads plain JSON at `scripts/systems/new_game_plus.gd:186-207`.
  Only `_current_ng_plus` is clamped at `203`; `active` is assigned at `204`, and all raw
  `modifiers` entries are appended at `205-207`. Multipliers/toggles consume them at `84-98`.
- **Attack steps:** (1) Edit `user://ng_plus_data.json`. (2) Set `{"ng_plus":3,"active":true,
  "modifiers":["sprint","sprint","keepers_pact","ghost"]}` or an unknown/invalid mixture.
  (3) Relaunch and use the reward, cycle, battery, hint, or achievement paths.
- **Impact:** Free valid modifiers, duplicate multiplier stacking, inconsistent active state, or
  an invalid achievement-disabled run. The current attack sim covers only `ng_plus=99`, not
  `active` or modifier validation (`scripts/security/attack_sim.gd:100-121`).
- **Closable?** **Yes against file tampering:** authenticate the file and reconstruct only a
  unique allowlisted modifier set with `size <= ng_plus`, `ng_plus >= 1` for modifiers, and the
  same exclusivity rules as `can_select()` (`57-72`). A determined player who extracts the key
  remains covered by the client-only limit, not by this control.
- **Riskiest assumption:** NG+ state is intentionally separate from the run save so it survives a
  New Game (`scripts/core/save_system.gd:359-366`).

#### P-04 — Flashlight upgrade file grants gameplay upgrades (P1)

- **Evidence:** `FlashlightUpgradeManager` is live at `project.godot:101-106`. It writes five
  branch levels without an envelope at `scripts/systems/flashlight_upgrade_manager.gd:130-136`
  and loads each raw value at `138-146`. Bonuses directly change light energy, cone, battery,
  and range at `scripts/player/player_3d.gd:1099-1117`.
- **Attack steps:** Write `{"brightness":5,"range":5,"stability":5,"angle":5,"battery":5}`
  to `user://flashlight_upgrades.cfg`, relaunch, and enter play.
- **Impact:** Free maximum flashlight advantages without coins or purchases; this is a real local
  gameplay/economy bypass, not only a cosmetic leaderboard claim.
- **Closable?** **Yes:** fold these five levels into the signed main authority body, or give the
  file a domain-separated HMAC and validate every branch in `[0,5]`; reject unknown keys.
- **Riskiest assumption:** The separate file is still the source of truth; no later main-save load
  overwrites it.

#### P-05 — Daily state tamper and system-clock replay (P1, partially inherent)

- **Evidence:** `_today_index()` is wall-clock-only at `scripts/systems/daily_challenge_manager.gd:89-90`;
  the anti-replay decision uses that same value at `92-105`. The claim tuple is plain JSON at
  `153-171`. The reward is applied at `121-143`.
- **Attack steps:** (1) Complete a daily. (2) Set the OS clock backward/forward or edit
  `tls_daily.json`'s `last_completed_day`/`progress`. (3) Relaunch and claim another reward.
- **Impact:** Repeated local daily rewards and streak manipulation. No server economy is affected.
- **Closable?** **File-edit part: yes** with an authenticated envelope and schema. **Clock part:
  no in this client-only design**; a local player controls the OS clock and process. A monotonic
  clock can reduce same-session abuse, but cannot prove elapsed time across restarts without a
  trusted service.
- **Riskiest assumption:** A daily reward is allowed to be local and offline rather than server
  issued; this is also the existing QA disposition (`docs/QA_SWARM_FINDINGS.md:13-14`).

#### P-06 — Cross-save swap is accepted because the HMAC is not slot-bound (P1/P2)

- **Evidence:** All slots use the same `_HMAC_KEY` and `_write_atomic()` at
  `scripts/core/save_system.gd:21-24,438-460`; there is no slot ID in the signed payload. The
  existing sim copies B over A and expects A to load B's 222 coins at
  `scripts/security/attack_sim.gd:145-159`.
- **Attack steps:** Save distinct authority into slots A and B. Copy
  `tls_savegame_slotB.save` over `tls_savegame_slotA.save`. Load A.
- **Impact:** Slot A silently becomes slot B, including position, progress, inventory, XP, and
  economy. That is a profile-isolation failure if slots are meant to be independent, though it is
  not corruption and may be an intentional “swap saves” feature.
- **Closable?** **Yes if slot isolation is required:** put `slot_id` in the signed body and pass
  the expected slot to validation. **No if arbitrary signed save import/swap is a promised feature**;
  document it instead of pretending slot identity exists.
- **Riskiest assumption:** The GDD advertises separate manual/autosave slots, so users may expect
  a dropped file not to change the target slot's identity.

#### P-07 — Signed body has incomplete semantic validation (P1/P2 conditional)

- **Evidence:** `PowerGrid.from_dict()` assigns any integer stage at
  `scripts/world/power_grid.gd:140-148`; `ProgressTracker.from_dict()` accepts raw counters,
  IDs, and time at `scripts/systems/progress_tracker.gd:121-144`; inventory counts are raw at
  `scripts/inventory/inventory_manager.gd:198-219`; `QuestManager.from_dict()` accepts raw progress
  and done state at `scripts/core/quest_manager.gd:142-149`. `CoinWallet.from_dict()` does already
  clamp coins to `[0, MAX_COINS]` at `scripts/economy/coin_wallet.gd:28-37`, so the currency hole
  is free bounded-max currency through the legacy path, not an unbounded integer.
- **Attack steps:** Edit and correctly re-sign a body after extracting the client HMAC key, or use
  the legacy path from P-01. Set district stages above FULL, negative/huge item counts, completed
  quests, or counters above the actual content totals. Load and trigger the dependent reward/ending.
- **Impact:** Sequence skips, free inventory, free bounded-max currency, malformed UI math, or
  fabricated ending and achievement prerequisites. Casual byte edits are still caught by the outer
  HMAC.
- **Closable?** **Yes for invariants:** schema/type checks, allowlists, finite checks, and clamps
  must run before every `from_dict()`; this does not defeat a patched client or extracted key.
- **Riskiest assumption:** “HMAC-valid” is currently being treated as equivalent to “game-valid,”
  but authenticity and semantic validity are separate properties.

#### P-08 — Local leaderboards are forgeable but have no external trust boundary (P2, not a server hole)

- **Evidence:** Both leaderboard formats write and load raw arrays at
  `scripts/systems/local_leaderboard.gd:29-58` and `scripts/systems/leaderboard.gd:9-34`.
- **Attack steps:** Replace `user://tls_leaderboard.json` with a zero-time, 11-district run and
  open Stats.
- **Impact:** False local display only. There is no server submission or payout in the current
  project (`docs/SECURITY_THREAT_MODEL.md:57-58`).
- **Closable?** **Yes** if the product promises tamper-evident local records: sign and validate
  records. **No** as an anti-cheat guarantee for a client-only personal board; a determined owner
  can still patch the writer or reader.
- **Riskiest assumption:** A local “leaderboard” is UX history, not a competitive service.

## 2. Runtime cheat surface

#### R-01 — The documented integrity watchdog is dormant (P1)

- **Evidence:** `scripts/systems/integrity_guard.gd:24-39` implements timers, but
  `project.godot:56-114` has no `IntegrityGuard="*res://scripts/systems/integrity_guard.gd"` line
  and grep found no production instantiation. The threat model nevertheless calls it a runtime
  watchdog at `docs/SECURITY_THREAT_MODEL.md:26-27`.
- **Attack steps:** Attach a debugger/memory editor, set wallet or player stats/position while
  playing, and wait longer than the claimed 1/5-second watchdog intervals.
- **Impact:** No correction or detection occurs from this script. This invalidates the current
  claim that runtime economy/position values are periodically revalidated.
- **Closable?** **Yes for detection/correction:** add the autoload and test it. It cannot prevent a
  debugger from changing the process; see the inherent-limits section.
- **Riskiest assumption:** File presence was mistaken for runtime wiring.

#### R-02 — Speed, teleport, and memory-edit advantage vectors are not bounded (P1)

- **Evidence:** Movement uses mutable resource stats in `scripts/player/player_3d.gd:504-544,664-677`
  and the shipped baseline is a resource (`data/balance/player_stats.tres:1-17`). The only existing
  guard logic checks missing player, non-finite position, or `y <= -50` at
  `scripts/systems/integrity_guard.gd:62-91`; it neither checks displacement speed nor runs today.
  The exported `weight_speed_mult` at `data/balance/player_stats.tres:17` is not consumed by
  `_speed_for()` (`scripts/player/player_3d.gd:664-677`); `compute_velocity()` independently
  computes `1.0 - weight_ratio * 0.5` at `scripts/player/player_3d.gd:537-539`. This is a
  balance/authority mismatch, not a standalone current exploit, and must be resolved before a
  watchdog compares speed against a supposedly authoritative value.
- **Attack steps:** (1) Edit `stats.run_speed`, `velocity`, `global_position`, or `Engine.time_scale`
  in memory. (2) Move through locked/unsafe space or finish time-gated content. (3) Restore values
  before a save if desired. For the balance mismatch, edit the exported `weight_speed_mult` or
  carry an overweight inventory and compare the observed speed with the intended stat contract.
- **Impact:** Movement advantage, sequence breaks, speedrun falsification, and potential bypass of
  physical encounter gates. Today changing `weight_speed_mult` alone has no effect through
  `_speed_for()`; the actual local weight formula still affects `compute_velocity()`. A client-side
  clamp can detect/correct common edits, not stop an owner who controls the process.
- **Closable?** **Partly:** centralize one speed calculation that explicitly consumes the intended
  weight multiplier, then a live watchdog can bound finite speed and validate navigation/collision
  domain; **prevention is no** without a trusted authority. `Engine.time_scale` is not a player
  setting in the shipped code, but a memory editor can change it.
- **Riskiest assumption:** Legitimate movement is always below a fixed cap, including dodge,
  knockback, scene transitions, and laggy LAN updates, and the exported weight field is meant to
  be authoritative rather than dead balance metadata.

#### R-03 — Saved position and district are syntactically trusted but not world-consistent (P2)

- **Evidence:** `SaveSystem.load_all()` restores `district` and accepts any three-element
  `player_pos` at `scripts/core/save_system.gd:284-313`; `WorldRuntime` applies the saved vector
  directly at `scripts/world/world_runtime.gd:70-88`. `DistrictSceneFactory` does correctly
  allowlist scene IDs at `scripts/world/district_scene_factory.gd:4-23`, but
  `WorldRuntime.load_district()` later writes the original unvalidated ID back to
  `DistrictManager.current_district` at `scripts/world/world_runtime.gd:54-68`.
- **Attack steps:** Supply a forged/legacy save with `[INF,INF,INF]`, a far-away finite vector, or
  a valid-looking district ID/path; continue and allow the world rebuild.
- **Impact:** Position softlock/teleport, inconsistent current-district state, or a future caller
  using the tainted ID. Current factory fallback limits direct scene-path traversal, so this is not
  an arbitrary filesystem read today.
- **Closable?** **Yes:** require finite coordinates, a per-district playable-volume/collision check,
  and an allowlisted district before applying either field; otherwise use the district spawn.
- **Riskiest assumption:** A signed coordinate is assumed to be physically reachable.

#### R-04 — Unsigned settings/config values can be absurd, though most are presentation-only (P2)

- **Evidence:** `SettingsManager.from_dict()` merges arbitrary `_settings` keys and values at
  `scripts/systems/settings_manager.gd:564-580`; only volume values are clamped there. The
  setting getters are consumed throughout UI/quality code, for example
  `scripts/ui/virtual_joystick.gd:83` and `scripts/world/district_grading.gd:48-61`.
- **Attack steps:** Edit `user://settings.cfg` to put huge/negative values in `graphics_tier`,
  `draw_distance`, `render_scale`, `deadzone`, `touch_sensitivity`, or add unknown keys; relaunch.
- **Impact:** Rendering/UI denial, odd input, or a future gameplay flag becoming an unbounded cheat.
  Current callers often clamp again, and `lang.cfg` is allowlisted by
  `scripts/i18n/localization_manager.gd:134-136`.
- **Closable?** **Yes:** use a closed typed schema and setter/clamp for every loaded key; do not
  let arbitrary config values influence authority. This is not a reason to sign cosmetic settings.
- **Riskiest assumption:** A currently harmless preference will not become a reward/difficulty
  switch in a future patch.

#### R-05 — Scene/path input has mixed protections (P2)

- **Evidence:** `DistrictSceneFactory.build()` uses a fixed `DISTRICTS` allowlist before composing
  `res://scenes/districts/%s.tscn` (`scripts/world/district_scene_factory.gd:4-23`). The existing
  attack sim checks traversal strings but only asserts “doesn't crash” at
  `scripts/security/attack_sim.gd:134-143`. In contrast, `Routes.goto()` accepts any existing
  path from its caller at `scripts/core/routes.gd:20-34`.
- **Attack steps:** Pass `../../../../etc/passwd`, `res://project.godot`, or a future
  user-controlled `res://` path to the relevant caller; use a save/memory edit to taint the
  district state.
- **Impact:** Factory currently falls back safely; a new caller of `Routes.goto()` or another
  dynamic `load()` could expose arbitrary project scenes/resources, crash, or create a debug path.
- **Closable?** **Yes:** route through a fixed enum/path table and reject all caller-provided paths;
  preserve the factory allowlist and validate state before `WorldRuntime` assignment.
- **Riskiest assumption:** All future route callers remain internal and trusted.

#### R-06 — i18n/format-string injection is not a current player-input path (no live finding)

- **Evidence:** `LocalizationManager.tf()` treats the shipped translation value as the format
  string (`scripts/i18n/localization_manager.gd:141-151`), while locale selection is allowlisted
  (`134-136`) and the shipped data is under `data/i18n/*.json`. Persisted values are arguments,
  not format strings; e.g. rewards use `LocalizationManager.tf()` at
  `scripts/economy/rewards_manager.gd:11-22`.
- **Attack steps:** A local player can edit a PCK/translation resource or patch the binary; they
  cannot inject a new translation through the current save/settings inputs.
- **Impact:** A tampered resource can cause bad formatting or altered UI, but that is already full
  client/package tampering, not a separate user-data injection primitive.
- **Closable?** **No as a client-package trust problem; yes as robustness** by validating format
  placeholders in a build gate and falling back on formatting failure. Do not call this an
  anti-cheat fix.
- **Riskiest assumption:** Translation files remain shipped immutable resources, not user-editable
  content.

#### R-07 — Optional LAN peer messages are self-authenticated only (P2, scope-limited)

- **Evidence:** `LANNetwork` accepts `@rpc("any_peer")` state/power messages and emits their
  supplied `peer_id`, position, and district without checking the sender at
  `scripts/net/lan_network.gd:74-94`. Player transform sync also accepts any peer payload at
  `scripts/player/player_3d.gd:1030-1047`; the threat model explicitly has no server arbitration
  (`docs/SECURITY_THREAT_MODEL.md:3-4`).
- **Attack steps:** A connected peer sends a state for another `peer_id`, an infinite/remote
  position, or a district it did not enter; send forged power events.
- **Impact:** Other LAN clients can see false remote state or experience local co-op desync/griefing.
  The host's own local authority remains inherently client-controlled.
- **Closable?** **Yes for network hygiene:** bind payloads to `multiplayer.get_remote_sender_id()`,
  validate finite positions, allowlisted district IDs, and displacement against the last accepted
  state; reject invalid RPCs. **No** for proving an honest host without a server.
- **Riskiest assumption:** LAN peers are cooperative, not adversarial.

#### R-08 — Wall-clock trust affects streaks, timestamps, and claimed run times (P1/P2)

- **Evidence:** daily selection uses `Time.get_unix_time_from_system()` at
  `scripts/systems/daily_challenge_manager.gd:89-90`; SaveSystem uses it for streak and save
  timestamps at `scripts/core/save_system.gd:395-401,458`; local leaderboard records it at
  `scripts/systems/local_leaderboard.gd:29-33`.
- **Attack steps:** Set the device clock or suspend/accelerate the process around a daily boundary,
  then claim a daily or record a run.
- **Impact:** Daily repeat/streak abuse and false local timestamps. It cannot affect an online
  authority because none exists.
- **Closable?** **No** for cross-launch time truth without a server or platform trusted-time
  service. **Partly yes** for same-session elapsed time: use a monotonic tick clock, cap per-frame
  delta, and flag rollback/forward jumps rather than awarding immediately.
- **Riskiest assumption:** Offline calendar-day semantics are acceptable for the feature.

## 3. Distribution and exported-build surface

#### D-01 — PCK replacement/overlay and package tamper are not self-verifiable (P1)

- **Evidence:** All three presets export all resources with only path exclusions at
  `export_presets.cfg:1-9,41-49,65-73`; Windows embeds the PCK at `78`. There is no manifest,
  external signature, or runtime package verification. The Play Integrity integration explicitly
  returns `STUB_NO_SERVER` and `false` at `scripts/systems/play_integrity_service.gd:21-39`.
- **Attack steps:** Replace/overlay a PCK or repack the Web/desktop/Android payload; patch a script,
  resource, scene, or translation; run the modified client.
- **Impact:** Arbitrary local gameplay changes, bypassed checks, altered rewards, or extraction of
  the HMAC key. A modified client can also patch any proposed self-check.
- **Closable?** **No in a determined client-only attacker model.** Platform APK/EXE signing,
  distribution hashes, CI artifact signing, and a server/platform attestation can detect or deter
  replacement; PCK encryption and a public-key manifest only raise effort. A verifier shipped in
  the same client cannot authenticate itself against a patched client.
- **Riskiest assumption:** The platform's package-signing and distribution channel, not the game,
  is the trusted boundary.

#### D-02 — HMAC key material is intentionally extractable from the client (inherent) (P1)

- **Evidence:** `_HMAC_KEY` is a literal at `scripts/core/save_system.gd:21`; `_sign()` uses it at
  `23-24`. The own comments correctly state the limitation at `8-20`.
- **Attack steps:** Decompile/dump the exported bytecode or instrument the process; recover the key;
  generate a valid HMAC for any save/achievement envelope; load it.
- **Impact:** Full local save forgery, including all fields that have an outer HMAC. This is the
  decisive reason the system is a casual-tamper speed bump, not anti-cheat.
- **Closable?** **No without moving signing to a backend or trusted platform service.** Bytecode and
  PCK encryption do not make a client-held secret unextractable.
- **Riskiest assumption:** There is no server-held secret by design (`docs/SECURITY_THREAT_MODEL.md:46-60`).

#### D-03 — Bytecode export is on; encryption is absent; Web assets are exposed (P1/P2)

- **Evidence:** `script_export_mode=1` is already present in all three presets at
  `export_presets.cfg:11-14,51-54,75-78`; `docs/EXPORT_HARDENING.md:10-21` correctly describes it
  as tokenized, reversible-barrier bytecode. There is no `encryption_key` in the presets, confirmed
  by `docs/EXPORT_HARDENING.md:3-8`. Web export is `all_resources` at `45-49`.
- **Attack steps:** Download the Web PCK/assets through browser/network tooling, or unpack a desktop
  PCK; decompile tokenized scripts and inspect data/config/assets.
- **Impact:** Source/logic/content/key extraction and easier patching. No new remote code execution
  path is implied; the attacker owns the client already.
- **Closable?** **No** as confidentiality against the owner of a Web/client build. **Yes as a
  casual-extraction speed bump** by keeping bytecode mode, optionally encrypting release PCKs with
  a CI-held key, stripping unused assets, and never treating encryption as anti-cheat.
- **Riskiest assumption:** Web delivery necessarily gives the browser the resources it renders.

#### D-04 — Debug signing material is present in tracked export configuration (P2)

- **Evidence:** Android preset contains `keystore/debug="res://tls_debug.keystore"`, user
  `tlsdebug`, and password `tlsdebug` at `export_presets.cfg:23-27`; release fields are empty at
  `26-28`. The keystore is ignored and not present in this checkout (`.gitignore:43-45`), so this
  is credential/config leakage, not proof that the binary is currently repackable with that file.
- **Attack steps:** Obtain the debug keystore from a build machine or old artifact; use the leaked
  preset credentials to sign a debug/repacked APK and distribute it outside the trusted release
  channel.
- **Impact:** Debug identity confusion and a preventable repackaging route; a real release build
  cannot be trusted until release signing is configured.
- **Closable?** **Yes:** remove passwords and debug keystore paths from the tracked release
  configuration, make a separate local debug preset, inject release keystore credentials only in
  CI/owner environment, and fail release export if `keystore/release*` is empty or debug-signed.
- **Riskiest assumption:** The ignored debug keystore has never escaped a developer/build machine.

#### D-05 — Import/UID metadata leaks project structure but is not an integrity control (P2)

- **Evidence:** 539 tracked `.import` files are present; a representative file reveals importer,
  UID, source path, and generated cache path at `assets/art/coin_icon.png.import:1-15`. A script UID
  is also tracked at `scripts/enemies/status_effects.gd.uid:1`.
- **Attack steps:** Inspect a checkout or any export that carries editor metadata; enumerate source
  names, resource paths, and generated artifact identifiers before reverse engineering.
- **Impact:** Reverse-engineering convenience and path disclosure. UIDs do not grant filesystem
  access or a signing key; they are not a tamper defense.
- **Closable?** **Yes for disclosure hygiene:** verify release exports exclude editor-only `.import`,
  `.uid`, and unused source metadata, and keep only runtime-imported resources. **No** as a
  confidentiality boundary once the resource is delivered to a Web/client build.
- **Riskiest assumption:** Godot's exporter, rather than the repository checkout, is the release
  artifact boundary.

## 4. Implementation-ready controls (no code landed here)

The following is the exact patch contract. Each control has an `attack_sim` case name and a gate
assertion. Keep `tools/check.sh:240` as the process-level gate and do not rely only on an in-scene
watchdog; boot/autoload hangs can happen before `attack_sim.gd:_ready()`.

### C-01 — Strict, domain-separated authority envelopes

Implement one envelope format for every gameplay-authority file:

```gdscript
const ENVELOPE_VERSION: int = 1

static func _sign_domain(domain: String, body: String) -> String:
    var material := (domain + "\n" + body).to_utf8_buffer()
    return Crypto.new().hmac_digest(
        HashingContext.HASH_SHA256,
        _HMAC_KEY.to_utf8_buffer(),
        material
    ).hex_encode()

static func _make_envelope(domain: String, body: String) -> Dictionary:
    return {
        "format": ENVELOPE_VERSION,
        "domain": domain,
        "data_json": body,
        "hmac": _sign_domain(domain, body),
    }
```

For main saves use domain `"tls-save-v1"`; slots must include `slot_id` in the body. For
achievements, NG+, flashlight upgrades, and daily state use distinct domains. In every reader:

```gdscript
if not (envelope is Dictionary):
    return {}
if int(envelope.get("format", 0)) != ENVELOPE_VERSION:
    return {}
if String(envelope.get("domain", "")) != expected_domain:
    return {}
var body: String = String(envelope.get("data_json", ""))
if body.is_empty() or String(envelope.get("hmac", "")) != _sign_domain(expected_domain, body):
    return {}
```

**Legacy rule:** do not automatically trust plain `checksum` or plain JSON. If compatibility is
kept, migrate only after an explicit user-facing “unverified legacy data” decision and immediately
write the new envelope; record that this does not cryptographically close P-01/P-02. Strict release
mode is the only closed security posture.

**Gate:** add `_check_legacy_envelopes_rejected()` to `scripts/security/attack_sim.gd`: write a
plain-checksum main save, plain achievement file, and plain NG+/upgrade/daily file; call each
loader; assert no authority is loaded and no plain file is left accepted. Also write one valid
new-format file per domain and assert round-trip succeeds. The existing wrong-HMAC achievement
case at `scripts/security/attack_sim.gd:58-77` remains.

### C-02 — Bind saves to their slot and schema

Normative slot binding:

```gdscript
payload["slot_id"] = slot

func _read_slot(slot: int) -> Dictionary:
    var data := _read_envelope(_get_slot_path(slot), "tls-save-v1")
    if data.is_empty() or int(data.get("slot_id", -1)) != slot:
        return {}
    return data
```

Use the same explicit `slot_id=0` for the live export/import path, or define export as an explicit
“replace target slot” operation. Do not silently accept a valid body from another slot.

**Gate:** replace `_check_cross_save_swap_no_corruption()` with
`_check_cross_save_swap_rejected()`: save 111 to A and 222 to B, copy B over A, call
`load_slot(A)`, assert it returns `false` and the pre-load wallet/state remains unchanged; then
assert each file still loads in its own slot.

### C-03 — Authenticate and reconstruct NG+, flashlight upgrades, and daily state

Required NG+ reconstruction (after envelope verification):

```gdscript
_current_ng_plus = clampi(int(data.get("ng_plus", 0)), 0, MAX_NG_PLUS)
_is_ng_plus_active = bool(data.get("active", false))
_active_modifiers.clear()
var seen := {}
for raw_id in data.get("modifiers", []):
    var id := String(raw_id)
    if seen.has(id):
        continue
    var modifier: Dictionary = get_modifier(id)
    if modifier.is_empty():
        continue
    if _active_modifiers.size() >= _current_ng_plus:
        break
    seen[id] = true
    _active_modifiers.append(id)
```

Then apply `exclusive_with` symmetrically and force `active=false` when level is zero. For
flashlight upgrades:

```gdscript
for branch in BRANCH_NAMES:
    _levels[branch] = clampi(int(data.get(branch, 0)), 0, get_max_level())
```

For daily state, authenticate and require `today_id == _id_for_day(_today_index())` before loading
progress; clamp progress to the current template target and reject a completed-day record whose
`last_completed_day` is in the future. This closes file tamper only, not the clock.

**Gate:** add these exact cases to `attack_sim.gd` and keep them in the `tools/check.sh:240` gate:

- `_check_ng_plus_modifier_forgery_rejected`: wrong HMAC, duplicate `sprint`, unknown ID, >level
  entries, and `active=true` at level 0; assert defaults/allowlist only.
- `_check_flashlight_upgrade_forgery_rejected`: wrong HMAC and all levels 999; assert all loaded
  levels are 0..5 and no bonus exceeds the level-5 table.
- `_check_daily_file_tamper_rejected`: flip `progress` and `last_completed_day`; assert state is
  rejected or reset, not completed.
- `_check_daily_clock_policy`: use an injected clock seam in the test; assert same-session elapsed
  time uses monotonic/capped delta, and explicitly record that cross-restart rollback is not a
  passable client-only security assertion.

### C-04 — Validate all signed main-save authority before applying it

Every `from_dict()` must reject wrong types, non-finite values, unknown IDs, and impossible values.
At minimum implement these exact bounds before assignment:

```gdscript
# PowerGrid.from_dict
var st := clampi(int(stages.get(String(d2.id), DistrictData.Stage.DARK)), 0, DistrictData.Stage.FULL)

# InventoryManager.from_dict
var item_data: ItemData = ItemDatabase.get_item(item_id)
if item_data == null:
    continue
var count := clampi(int(s.get("count", 0)), 0, item_data.max_stack if item_data.stackable else 1)

# ProgressTracker.from_dict; MAX_* are fixed constants derived from shipped content,
# never from the incoming dictionary.
secrets = clampi(int(d.get("secrets", 0)), 0, MAX_SECRETS)
kills = clampi(int(d.get("kills", 0)), 0, MAX_KILLS)
shadow_kills = clampi(int(d.get("shadow_kills", 0)), 0, kills)
puzzles = clampi(int(d.get("puzzles", 0)), 0, MAX_PUZZLES)
time_played = maxf(0.0, float(d.get("time_played", 0.0)))

# QuestManager.from_dict
q.progress = clampi(int(row.get("progress", 0)), 0, q.target_count)
q.done = bool(row.get("done", false)) and q.progress >= q.target_count
```

Also allowlist `district` against `DistrictManager.DISTRICTS`, require finite `player_pos`, and
apply a per-district playable-volume check before using it. Keep the existing XP clamps at
`scripts/systems/xp_manager.gd:121-125` and add allowlisting/range checking for skill IDs and
upgrade IDs (`scripts/systems/skill_tree_manager.gd:322-328`, `scripts/economy/upgrade_system.gd:72-76`).

**Gate:** add `_check_main_authority_schema()` to `attack_sim.gd`: feed each loader dictionaries
containing strings, arrays, negative/huge counts, stages 99, `INF`/`NAN` vectors where the engine
API allows them, unknown IDs, and completed quests with zero progress; assert no crash, finite
state, legal bounds, and no reward/ending trigger. This is a semantic gate, not a claim that a
player with the HMAC key is stopped.

### C-05 — Wire and strengthen the runtime watchdog

Add the missing autoload entry to the production project configuration:

```ini
IntegrityGuard="*res://scripts/systems/integrity_guard.gd"
```

Keep economy clamps, and replace the current position-only check with a monotonic, state-aware
movement check. Normative logic:

```gdscript
const MAX_TRAVEL_SPEED: float = 360.0
var _last_watchdog_pos := Vector3.ZERO
var _last_watchdog_ticks: int = 0

func _watchdog() -> void:
    if not GameManager.is_playing():
        return
    var player := get_tree().get_first_node_in_group("player")
    if not is_instance_valid(player):
        return
    var now := Time.get_ticks_msec()
    var dt := clampf((now - _last_watchdog_ticks) / 1000.0, 0.001, 0.25)
    var pos: Vector3 = player.global_position
    var displacement := pos.distance_to(_last_watchdog_pos)
    if not pos.is_finite() or displacement > MAX_TRAVEL_SPEED * dt + 8.0:
        player.global_position = _last_watchdog_pos
        player.velocity = Vector3.ZERO
        push_warning("IntegrityGuard: movement rejected")
        return
    _last_watchdog_pos = pos
    _last_watchdog_ticks = now
```

The actual implementation must exempt a known scene transition/teleport token and reset the
baseline after a legitimate spawn; otherwise the control will punish normal travel. Keep the
existing HP/battery/stamina finite/range validation (`integrity_guard.gd:88-107`).

**Gate:** add `_check_integrity_guard_runtime()` to `attack_sim.gd` or a child probe scene used by
that gate: instantiate the real player, baseline it, move it by a legal distance, then inject a
non-finite position, a 10,000-unit one-tick displacement, and an out-of-range wallet; assert the
position is restored, velocity is zeroed, and wallet is clamped. Add a transition-token case that
asserts a legitimate district spawn is not reverted. The shell timeout remains mandatory.

### C-06 — Close route and district allowlists

Use a fixed route map instead of accepting a caller path:

```gdscript
const ROUTES := {
    "menu": MENU,
    "loading": LOADING,
    "game": GAME,
    "settings": SETTINGS,
    "difficulty": DIFFICULTY,
    "credits": CREDITS,
}

func goto_id(id: StringName) -> void:
    var path: String = ROUTES.get(String(id), "")
    if path.is_empty() or not ResourceLoader.exists(path):
        return
    goto(path)
```

Validate `DistrictManager.current_district` before assigning it in `WorldRuntime`, not only inside
the factory. Invalid save/memory IDs must select `suburbs` or the safe spawn and must never become
persistent current state.

**Gate:** extend `_check_district_id_injection_defended()` (`attack_sim.gd:134-143`) to assert the
factory result's resolved name is one of `DistrictSceneFactory.DISTRICTS`, the manager current ID
never becomes the malicious string, and every route ID outside `ROUTES` is rejected. Test
`res://project.godot`, traversal, empty, and a valid district.

### C-07 — LAN sender binding and payload invariants

For every `@rpc("any_peer")` state/power method, require the network sender to own the claimed
player and validate fields before emitting:

```gdscript
var sender := multiplayer.get_remote_sender_id()
if sender != peer_id:
    return
if not pos.is_finite() or not DISTRICTS.has(district):
    return
```

Track the last accepted position per peer and reject impossible displacement; never trust a peer's
`powered` boolean as a local `PowerGrid` mutation. Only the host-authoritative gameplay event may
change host state.

**Gate:** add `_check_lan_payload_validation()` to the attack sim's network-enabled probe; send a
valid sender/peer pair, wrong sender, non-finite position, unknown district, and forged power
message. Assert only the valid remote-view event is emitted and no local `PowerGrid` stage changes.

### C-08 — Export/release gates

- Keep `script_export_mode=1` in all presets (`export_presets.cfg:13,53,77`).
- Add a release-export static gate that fails if `encryption_key=` is committed, any release
  preset has debug keystore fields, `keystore/release`, `keystore/release_user`, or
  `keystore/release_password` is empty, or an exported artifact contains tool/test scenes.
- Store any PCK encryption key and release keystore outside Git/CI logs; use it only as extraction
  friction, never as a save-signing root.
- Add a release artifact inspection gate asserting no `.import`, `.uid`, test scenes, or test scripts
  are present in the final package unless Godot requires that runtime resource.

**Gate:** this is a static release gate, not an `attack_sim` runtime assertion. The existing
`tools/check.sh` engine gate remains process-timeout wrapped; a separate artifact check must inspect
the actual exported APK/PCK/Web files, not only `export_presets.cfg`.

## 5. What client-only integrity can and cannot enforce

### Enforceable without a server

- Detect accidental corruption and casual hand edits with atomic writes, backups, strict parsing,
  schema validation, and an HMAC speed bump. This is the current main-save strength, not full
  authenticity.
- Clamp numeric ranges, finite-check vectors, validate item/skill/district IDs, enforce stage,
  quest, inventory, modifier, and reward invariants on every load and every runtime mutation.
- Reject cross-file/domain/slot substitution with domain-separated envelopes and a slot ID.
- Use an in-process watchdog to **detect/correct** common out-of-range memory edits, impossible
  travel, missing players, and non-finite values. It cannot prevent the edit.
- Use platform package signing, CI artifact hashes, and a release keystore to protect distribution
  provenance for users who trust the platform/channel.
- For LAN, validate sender ownership and payload bounds; this protects peers from accidental or
  malformed messages, not from a malicious host controlling its own client.

### Inherent client-side limits — not fixes

These are explicitly **not** patch items and must never be described as closed by the controls above:

1. The HMAC key, code, invariant checks, and any public-key verifier ship to the attacker. A
   determined owner can extract the key, patch the verifier, or call the reward path directly.
2. A memory editor can change speed, position, wallet, HP, timers, `Engine.time_scale`, or branch
   around the watchdog. A watchdog is detection/correction only.
3. An offline client cannot prove real elapsed/calendar time across restarts. Wall-clock daily
   rollback, suspend/resume, and process instrumentation remain possible without a server or
   platform trusted-time service.
4. Web exports expose the code/assets needed by the browser. Bytecode/PCK encryption only increases
   effort; it cannot hide a resource from the user who must receive it.
5. Local achievement, leaderboard, daily, and NG+ state has no server-side truth. If cheated local
   trophies are unacceptable, the product needs a platform/server account authority; signing the
   local file only deters casual edits.
6. Optional peer-to-peer LAN has no independent arbiter. Sender validation limits spoofed messages,
   but a malicious host can fabricate its own local state.
7. A modified client can suppress logs, fake a clean watchdog result, and produce a valid-looking
   local report. The `PlayIntegrityService` stub is honest at
   `scripts/systems/play_integrity_service.gd:4-19`; it is not attestation until a backend verifies
   a token.

## Acceptance checklist

- [ ] Only `docs/SECURITY_PATCH_SPEC.md` is changed by this audit; no engine or code edits landed.
- [ ] Lead developer resolves P-01 through P-07 according to the stated strict/compatibility
      decisions and adds the named `attack_sim` cases.
- [ ] `attack_sim` is described as the six-case current baseline plus the new cases, not as a
      pre-existing 14-case proof; `tools/check.sh` keeps an outer timeout.
- [ ] Release artifact inspection, not only static preset inspection, is run on Android/Web/
      Windows outputs.
- [ ] Re-read `docs/SECURITY_THREAT_MODEL.md` after implementation and preserve its honest
      “NOT protectable client-side” section.
- [ ] Final review checks `git diff --stat`, confirms no code/assets/generated artifacts changed,
      and confirms the commit subject is exactly `docs(security): patch spec`.
