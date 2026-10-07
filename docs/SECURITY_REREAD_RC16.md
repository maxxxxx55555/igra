# Security re-read of the risky APIs (rc16, S3)

Evidence: `tools/sec_reread.sh` through `tools/qa_sim/proof_run sec_reread` on `a459b9c`; raw output `docs/artifacts/rc16/proofs/sec_reread.out` (exit 0). Scope: the shipped GDScript
(`scripts/`, not `scripts/tools/`, not `addons/`). The adversarial gate is `scripts/security/attack_sim.gd` (`[attack-sim] DONE fails=0` on `8bb881b` in
`docs/artifacts/rc16/proofs/s3s4_gates_8bb881b.attach.attack_sim_scene.log`; it runs again inside `tools/check.sh --all`).

| class | command (section of the output) | result | reading |
|---|---|---|---|
| process, shell, code execution (`OS.execute`, `create_process`, `shell_open`, `kill`, `Expression`, `GDScript.new`, `source_code`, `str_to_var`, `bytes_to_var`, `JavaClassWrapper`, `JavaScriptBridge`, `HTTPRequest`) | 1 | 0 hits | none in shipped code |
| environment and command line | 2 | 3 lines, all in the profile guard autoload (`OS.get_environment` at `scripts/core/qa_launch_guard.gd:39`, the two argument loops at `:91` and `:97`) | they switch the QA snapshot and restore of the profile; no gameplay flag is read |
| network peers and sockets | 3 | `ENetMultiplayerPeer` in `scripts/net/lan_network.gd:14` and `scripts/multiplayer/network_manager.gd:38`, `PacketPeerUDP` in `scripts/multiplayer/lan_discovery.gd:27` | each opens a socket inside a function that only the lobby calls |
| reachability of that network code | 4 | the only callers of `create_server` (`scripts/ui/lobby_menu.gd:41`) and `join_server` (`scripts/ui/lobby_menu.gd:58`) are in the lobby; no shipped script or scene opens the lobby (`rg -i lobby` outside the lobby files and the tools lists 0 lines) | no socket is opened in a shipped run; the RPC handlers below are dormant |
| `@rpc("any_peer")` handlers | 3 | 13 handlers in 5 files | `take_damage(clampf(amount, 0.0, 200.0)` in `_request_damage` clamps the amount (`scripts/enemies/base_monster.gd:740`); `_request_player_damage` (`scripts/player/player_3d.gd:951`) accepts the host only: `get_remote_sender_id` (`scripts/player/player_3d.gd:954`); `LANNetwork` state and power messages are validated (attack_sim rejects a NaN position and an unknown district id: `rpc_player_state` at `scripts/security/attack_sim.gd:448` and `rpc_power_changed` at `scripts/security/attack_sim.gd:461`); the six inventory requests (`scripts/inventory/inventory_manager.gd:358` to `:396`) check authority only |
| paths built from values | 5 | `DirAccess.remove_absolute` on backup suffixes, slot files and the profile guard; `load` and `ResourceLoader.load` on constant or table paths | slot paths take an integer (`scripts/systems/save_slot_manager.gd:21`); the language file is checked against `SUPPORTED` before it names a path (`scripts/i18n/localization_manager.gd:49`) |
| files the player can edit | 6 and 7 | the save, the New Game+ file, achievements, the daily state, the flashlight upgrades and the leaderboard go through `write_signed` (`scripts/core/save_system.gd:29`) and `read_signed` (`scripts/core/save_system.gd:40`) | an edited signed file resets that state; the unsigned files are the language code, the captions "seen" list (`scripts/systems/captions_manager.gd:79`) and the settings, which change presentation only |
| the New Game+ run ledger (rc16, E1) | closeout `E1A` to `E1D`, attack_sim | a forged ledger of 500 entries loads as at most 64 well-formed names | `docs/TZ_DECISIONS.md` row E1 |

## Finding

F1 (dormant, no player can reach it): the six inventory requests check `is_multiplayer_authority()` only; they do not check the sender id or clamp `amount`. They run only if a peer exists, and a peer exists only after `create_server` (`scripts/ui/lobby_menu.gd:41`) or `join_server` (`scripts/ui/lobby_menu.gd:58`), which no shipped screen opens. Owner action if the lobby is ever opened: compare `multiplayer.get_remote_sender_id()` with the peer that owns the inventory and clamp the amount to the pack size, then add a case to attack_sim.
