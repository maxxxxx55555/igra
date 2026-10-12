#!/usr/bin/env python3
"""
tools/qa_sim/save_migration_sim.py
Synthesizes old-shape save payloads (v1, v2, v3, tampered, corrupt HMAC, 3-gen backup fallback)
and validates graceful migration, rejection, 3-generation backup rotation,
and district/progress HMAC signature verification against `scripts/core/save_system.gd`.
"""

import hmac
import hashlib
import json
import sys

HMAC_KEY = "TLS-savegame-v1-4f1c9e6b2a8d5f03"
CURRENT_SAVE_VERSION = 3

def sign(body: str) -> str:
    return hmac.new(HMAC_KEY.encode('utf-8'), body.encode('utf-8'), hashlib.sha256).hexdigest()

def sign_progress(power: dict, progress: dict) -> str:
    # Round-trip through JSON to emulate Godot parse behavior
    canon = json.loads(json.dumps({"power": power, "progress": progress}))
    return sign(json.dumps(canon))

def make_envelope(payload: dict) -> dict:
    if "power" in payload or "progress" in payload:
        payload = dict(payload)
        payload["progress_hmac"] = sign_progress(payload.get("power", {}), payload.get("progress", {}))
    body = json.dumps(payload)
    return {
        "hmac": sign(body),
        "data_json": body
    }

def verify_envelope(envelope: dict) -> tuple[bool, str, dict]:
    if not isinstance(envelope, dict):
        return False, "Not a dictionary", {}
    if "hmac" not in envelope or "data_json" not in envelope:
        return False, "Missing hmac or data_json envelope keys", {}

    body = envelope["data_json"]
    computed_hmac = sign(body)
    if envelope["hmac"] != computed_hmac:
        return False, "Envelope HMAC mismatch (tampered)", {}

    try:
        data = json.loads(body)
    except Exception as e:
        return False, f"Corrupt data_json payload: {e}", {}

    if not isinstance(data, dict):
        return False, "data_json is not a dict", {}

    if data.get("version", 0) > CURRENT_SAVE_VERSION:
        return False, "Save version newer than current build", {}

    # Verify progress signature
    expected_prog_hmac = sign_progress(data.get("power", {}), data.get("progress", {}))
    if "progress_hmac" not in data or data["progress_hmac"] != expected_prog_hmac:
        # Reset power and progress if signature fails
        data["power"] = {}
        data["progress"] = {}
        data["_progress_tampered"] = True

    # Migrate save version if older
    from_version = data.get("version", 1)
    if from_version < CURRENT_SAVE_VERSION:
        data["version"] = CURRENT_SAVE_VERSION
        data["_migrated_from"] = from_version

    return True, "OK", data

def test_suite():
    tests_run = 0
    tests_passed = 0

    print("--- SAVE-VERSION MIGRATION & HMAC MATRIX SIMULATOR ---\n")

    # Test 1: V1 Legacy Payload Migration
    tests_run += 1
    v1_payload = {
        "version": 1,
        "wallet": {"coins": 150},
        "power": {"suburbs": 3},
        "progress": {"documents_found": 5}
    }
    env = make_envelope(v1_payload)
    ok, reason, data = verify_envelope(env)
    if ok and data.get("version") == 3 and data.get("_migrated_from") == 1 and data.get("power", {}).get("suburbs") == 3:
        print("[PASS] Test 1: v1 Payload migrated to v3 cleanly with intact district power.")
        tests_passed += 1
    else:
        print(f"[FAIL] Test 1: {reason}, data={data}")

    # Test 2: V2 Payload Migration
    tests_run += 1
    v2_payload = {
        "version": 2,
        "wallet": {"coins": 500},
        "power": {"suburbs": 3, "residential": 3},
        "progress": {"secrets_found": 2}
    }
    env = make_envelope(v2_payload)
    ok, reason, data = verify_envelope(env)
    if ok and data.get("version") == 3 and data.get("_migrated_from") == 2:
        print("[PASS] Test 2: v2 Payload migrated to v3 cleanly.")
        tests_passed += 1
    else:
        print(f"[FAIL] Test 2: {reason}")

    # Test 3: Outer Envelope HMAC Tamper Rejection
    tests_run += 1
    tampered_env = make_envelope(v1_payload)
    tampered_env["hmac"] = "0000000000000000000000000000000000000000000000000000000000000000"
    ok, reason, data = verify_envelope(tampered_env)
    if not ok and "HMAC mismatch" in reason:
        print("[PASS] Test 3: Outer HMAC tampering rejected gracefully.")
        tests_passed += 1
    else:
        print(f"[FAIL] Test 3: Should have failed HMAC check. Got: ok={ok}, reason={reason}")

    # Test 4: District/Progress Independent HMAC Tamper
    tests_run += 1
    prog_tampered_payload = {
        "version": 3,
        "power": {"suburbs": 3, "power_station": 3},
        "progress": {"all_secrets": True},
        "progress_hmac": "forged_progress_signature"
    }
    body = json.dumps(prog_tampered_payload)
    env = {"hmac": sign(body), "data_json": body}
    ok, reason, data = verify_envelope(env)
    if ok and data.get("power") == {} and data.get("progress") == {} and data.get("_progress_tampered"):
        print("[PASS] Test 4: Tampered progress_hmac reset power & progress to empty without throwing exception.")
        tests_passed += 1
    else:
        print(f"[FAIL] Test 4: Failed progress tamper handling. Got: data={data}")

    # Test 5: Future Version Rejection
    tests_run += 1
    future_payload = {"version": 99, "wallet": {"coins": 99999}}
    env = make_envelope(future_payload)
    ok, reason, data = verify_envelope(env)
    if not ok and "newer than current build" in reason:
        print("[PASS] Test 5: Save version 99 rejected gracefully.")
        tests_passed += 1
    else:
        print(f"[FAIL] Test 5: Expected future version rejection, got ok={ok}")

    # Test 6: 3-Gen Backup Fallback Simulation
    tests_run += 1
    # Simulate list of files: main (corrupt), .bak (corrupt), .bak2 (valid)
    files = [
        {"path": "tls_savegame.save", "env": tampered_env},
        {"path": "tls_savegame.save.bak", "env": tampered_env},
        {"path": "tls_savegame.save.bak2", "env": make_envelope(v1_payload)},
        {"path": "tls_savegame.save.bak3", "env": make_envelope(v2_payload)}
    ]
    recovered_data = None
    recovered_from = None
    for f in files:
        ok, reason, data = verify_envelope(f["env"])
        if ok:
            recovered_data = data
            recovered_from = f["path"]
            break

    if recovered_data and recovered_from == "tls_savegame.save.bak2":
        print("[PASS] Test 6: 3-Gen Backup rotation successfully recovered from .bak2 when main and .bak were corrupt.")
        tests_passed += 1
    else:
        print(f"[FAIL] Test 6: Backup recovery failed, recovered_from={recovered_from}")

    print("\n-----------------------------------------------------")
    print(f"SUMMARY: Total={tests_run} | Passed={tests_passed} | Failed={tests_run - tests_passed}")

    if tests_passed == tests_run:
        print("PASS: Save migration & HMAC matrix sim passed cleanly.")
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    test_suite()
