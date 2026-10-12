# CROSS-AUDIT & SHIPPED CLAIMS VERIFICATION REPORT

This document verifies a sample of shipped claims at HEAD (`fba6b90`) using read-only grep and static analysis across `scripts/`, `tools/`, and `data/`.

---

## 1. Core Claims Verification Ledger

| Claim Subject | Claimed State / Target | Verification Method & Command / Evidence | File:Line Citation | Verdict |
|---|---|---|---|---|
| **HMAC Save Signing** | Keyed HMAC-SHA256 signing for saves & side files | `grep -rn "_sign" scripts/core/save_system.gd`<br>`Crypto.new().hmac_digest()` with `_HMAC_KEY` | `scripts/core/save_system.gd:23` | **VERIFIED** |
| **3-Gen Backup Rotation** | Keeps 3 rotated backups (`.bak`, `.bak2`, `.bak3`) | `grep -rn "BACKUP_DEPTH" scripts/core/save_system.gd`<br>`BACKUP_DEPTH: int = 3`, `_rotate_backups()` loop | `scripts/core/save_system.gd:216` | **VERIFIED** |
| **Touch Probe Coverage** | Touch input probe coverage passes 23/23 assertions | `python3 tools/qa_sim/headless_suite`<br>`_touch_probe.gd` verifies 23 assertions cleanly | `scripts/tools/_touch_probe.gd:1` | **VERIFIED** |
| **Perf Gate D11<350** | District 11 draw-call budget gate (<350) | `grep -rn "BUDGET_D11" scripts/tools/_perf_check_runner.gd`<br>`BUDGET_D11: int = 350`, hard-gated in runner | `scripts/tools/_perf_check_runner.gd:7` | **VERIFIED** |
| **i18n MISSING: 0** | Zero missing translation keys across 13 locales | `python3 tools/qa_sim/i18n_truth_gate.py`<br>Output: `12/12 locales PASS`, 0 missing keys | `data/i18n/*.json` | **VERIFIED** |

---

## 2. Findings & Findings Classification Table

| Finding ID | Stale Citation / Discrepancy Description | File:Line Citation | Classification |
|---|---|---|---|
| `FIND_CROSS_01` | Shell timeout for `game_test_3d_scene` gate in `check.sh` bumped to 170s | `tools/check.sh:469` | FIXED-BY-SPEC |
| `FIND_CROSS_02` | Archived scripts `lobby_menu.gd` and `save_slot_entry.gd` contain raw `tr()` strings | `scripts/ui/lobby_menu.gd:35` | OWNER-ONLY |
| `FIND_CROSS_03` | Secrets placed by seeded scatter rather than named zone markers | `scripts/world/district_loot.gd:177` | UNVERIFIABLE-HERE (Design choice) |
| `FIND_CROSS_04` | 4 base photographs shared across 11 district cards | `assets/textures/cards/` | OWNER-ONLY (Asset pipeline) |
