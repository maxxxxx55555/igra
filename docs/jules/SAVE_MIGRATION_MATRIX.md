# SAVE-VERSION MIGRATION MATRIX & INTEGRITY REPORT

This document details the save version migration, HMAC signing architecture, 3-generation backup rotation, and integrity findings analyzed from `scripts/core/save_system.gd`.

---

## 1. Save Schema Evolution & Migration Matrix

| Save Version | Era / Phase | Fields Supported | Migration Handling in `_migrate()` |
|---|---|---|---|
| **v1** | Early Prototype / Gold Master v1-v3 | `wallet`, `power`, `progress`, `inventory`, `player_pos` | Migrates to `version: 3`. Legacy keys parsed with `.get(key, default)` fallbacks in system deserializers. |
| **v2** | Final Consolidation / Gold Master v4-v5 | Added `quests`, `xp`, `skill_tree`, `flashlight`, `photos`, `daily_streak` | Migrates to `version: 3`. |
| **v3** (Current) | RC / Release Candidate Final v5 | Added `run_id`, `onboard_done`, `progress_hmac`, `last_daily_time` | Native version. No transformation required. |
| **>3** | Future / Unrecognized | Any version > 3 | Rejected in `_read_envelope()`. Returns empty dictionary and prevents corrupting state. |

---

## 2. Integrity & HMAC Anti-Tamper Security Layers

### Layer 1: Outer Envelope HMAC-SHA256 (`_sign` / `write_signed` / `_read_envelope`)
- **Key**: Static hardcoded key `TLS-savegame-v1-4f1c9e6b2a8d5f03` (`scripts/core/save_system.gd:21`).
- **Mechanism**: `Crypto.hmac_digest(HASH_SHA256, key, body)`.
- **Envelope Format**: `{"hmac": "<hex>", "data_json": "<raw_json_str>"}`.
- **Behavior on Tampering**: Any text edit to `data_json` invalidates `hmac`. `_read_envelope` rejects the save immediately and attempts backup recovery.

### Layer 2: District & Progress Dual Signature (`_sign_progress` / `_verify_progress`)
- **Target Fields**: `power` (district restoration stages) and `progress` (documents, secrets, ending stats).
- **Motivation**: Closes the downgrade attack where an attacker strips the outer HMAC to emulate pre-HMAC legacy saves.
- **Behavior on Tampering**: If `progress_hmac` is missing or invalid, `_verify_progress()` resets `power` and `progress` to `{}` while preserving benign data like wallet/settings, preventing forged win states.

---

## 3. Backup Rotation Architecture (3 Generations)

`SaveSystem._rotate_backups()` (`scripts/core/save_system.gd:217`) keeps 3 historical generations prior to an atomic write:
1. `.save.bak` (Newest backup - immediately preceding current `.save`)
2. `.save.bak2` (Intermediate backup)
3. `.save.bak3` (Oldest backup)

### Fallback Order on Load Failure (`_read_validated`):
1. Reads `tls_savegame.save`.
2. On failure, logs warning and tries `tls_savegame.save.bak`.
3. On failure, tries `tls_savegame.save.bak2`.
4. On failure, tries `tls_savegame.save.bak3`.
5. If all fail, quarantine file to `tls_savegame.save.corrupt-<timestamp>` and initialize fresh profile.

---

## 4. Findings & Findings Classification

| Finding ID | Description | File:Line Citation | Classification |
|---|---|---|---|
| `FIND_SAVE_01` | HMAC key embedded in client binary (offline single-player limitation) | `scripts/core/save_system.gd:21` | FIXED-BY-SPEC (Documented speedbump) |
| `FIND_SAVE_02` | Downgrade attack on unkeyed legacy checksums removed; legacy saves without HMAC rejected | `scripts/core/save_system.gd:187` | FIXED-BY-SPEC (P-01 security patch) |
| `FIND_SAVE_03` | Slot save files lacked slot ID verification | `scripts/core/save_system.gd:426` | FIXED-BY-SPEC (P-06 slot_id check) |
| `FIND_SAVE_04` | Exported save in Downloads folder could be overwritten or unverified on import | `scripts/core/save_system.gd:64` | OWNER-ONLY (Requires device file system test) |
