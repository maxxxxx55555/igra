# Release Defect Repair

## Scope

Repair six confirmed defects in the existing first-person, localization, and LAN features.
Do not replace working systems or add dependencies.

## Changes

- Throttle LAN discovery broadcasts to once per second.
- Make `NetworkManager` connections idempotent across host/join/shutdown cycles.
- Remove blocking UPnP discovery because the supported mode is nearby LAN play.
- Convert remote-player global spawn coordinates to manager-local coordinates.
- Apply the existing system fallback font as the project fallback for CJK and Arabic glyphs.
- Remove locale keys that differ only by case and have identical values.

## Error Handling

- Propagate ENet creation failures through the existing `connection_failed` signal.
- Reject invalid host addresses before creating a client.
- Keep discovery inactive when bind/setup fails.

## Verification

- Add one headless regression check covering LAN broadcast cadence and reconnect signal counts.
- Run compile, e2e, FPS smoke, crafting, and asset checks.
- APK export and two-device LAN testing remain external hardware/tooling gates.
