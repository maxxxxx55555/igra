# Authentication and local integrity

Verified against source on 2026-11-10. This is an implementation explanation, not a live network or device test. Release status remains governed by `docs/PROJECT_STATE.md`.

## Accounts and connections

The game has no account-login backend, password database, OAuth exchange, JWT session, or refresh-token flow in the inspected game services. Local save profiles are gameplay slots, not authenticated identities. `scripts/systems/play_integrity_service.gd:7` explicitly documents the absence of a server.

Two networking autoloads exist in `project.godot`: `NetworkManager` and `LANNetwork`. Both create an `ENetMultiplayerPeer` and assign it to the scene multiplayer API. The default port is 7777. Hosting creates a server; joining takes an IP address and creates a client. Neither path asks for credentials or exchanges an application login token (`scripts/multiplayer/network_manager.gd:36`, `scripts/multiplayer/network_manager.gd:50`, `scripts/net/lan_network.gd:12`, `scripts/net/lan_network.gd:26`). UPnP is disabled by default in NetworkManager.

LAN state messages carry a peer ID, position, yaw, and district. The receiver rejects a remote sender whose connection ID differs from the claimed peer ID, non-finite movement values, and unknown districts (`scripts/net/lan_network.gd:73`). This is connection-level validation, not proof of a person's identity. The power-change RPC accepts any connected peer after validating the district (`scripts/net/lan_network.gd:87`). No password handshake or application encryption layer is implemented in these services; they must not be described as an authenticated public multiplayer service.

## Save integrity

`SaveSystem` serializes a JSON body and computes HMAC-SHA256 with a key reconstructed inside the client (`scripts/core/save_system.gd:26`, `scripts/core/save_system.gd:33`). Signed sidecars use `write_signed()` and `read_signed()`; the latter checks envelope types and the HMAC before parsing the body (`scripts/core/save_system.gd:39`, `scripts/core/save_system.gd:50`). Main saves use atomic writes and backup rotation (`scripts/core/save_system.gd:218`, `scripts/core/save_system.gd:248`).

Loading verifies the HMAC, rejects unsigned legacy checksum-only saves, validates the JSON body and version, and checks signed progress before migration (`scripts/core/save_system.gd:259`). Slot loads additionally require the signed `slot_id` to match the requested slot (`scripts/core/save_system.gd:677`).

These controls detect corruption and casual file edits. They do not encrypt saves or authenticate an account. A key shipped in a client can be extracted; a modified client can forge its own state. This is not server-authoritative anti-cheat. Key material must not be copied into documentation or logs.

## SDK configuration and attestation

`AdService` reads `monetization/applovin_sdk_key` from ProjectSettings and passes it to AppLovinProvider on mobile (`scripts/monetization/ad_service.gd:60`). The provider reads ad-unit IDs, installs SDK listeners, and calls `AppLovinMAX.initialize()` (`scripts/monetization/applovin_provider.gd:25`). An SDK reward callback then notifies AdService. These are advertising configuration and SDK events, not player login credentials or server-verified account rewards.

Without the key, non-Web release builds select no provider; debug builds use a stub. Web takes a separate CrazyGames provider branch before the mobile key check. Do not infer live monetization from the existence of this wiring.

`PlayIntegrityService.request_integrity_token()` emits `STUB_NO_SERVER`, `has_real_attestation=false`, the platform, and the supplied nonce; `is_available()` returns false (`scripts/systems/play_integrity_service.gd:27`, `scripts/systems/play_integrity_service.gd:38`). It neither requests nor verifies a real Google token. Real attestation would require the SDK and a backend that verifies the response.

Platform signing keys authenticate distribution packages, not players. Provisioning signing identities and publishing through store accounts remain owner operations recorded in `docs/PROJECT_STATE.md`; no credential values belong in this document.
