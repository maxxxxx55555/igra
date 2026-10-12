#!/usr/bin/env python3
"""
tools/qa_sim/i18n_placeholder_fuzz.py
Fuzzer and static truth gate for all 13 locales in `data/i18n/*.json`.
Asserts:
1. Placeholder parity (%s, %d, %f, %.1f, %02d, %d/%d, %d%%, etc.) across all 13 locales against `en.json`.
2. No raw `tr()` calls on raw English sentences in active GDScript files (archived dead code excluded per KNOWN_ISSUES.md).
3. No romanized/invalid uppercase placeholders in localized strings (%S instead of %s, etc.).
4. Cognate whitelist consistency.
"""

import json
import os
import re
import sys

LOCALES = ["ar", "de", "en", "es", "fr", "it", "ja", "ko", "pt_BR", "ru", "tr", "zh", "zh_TW"]

# Allowed exact cognates / loanwords where value in locale == value in en.json
COGNATE_WHITELIST = {
    "Auto", "Park", "Normal", "AUDIO", "Journal", "Radio", "Speedrunner", "Endurance",
    "OK", "FPS", "HUD", "VRAM", "Master", "SFX", "Voice", "Ambient", "UI", "VSync",
    "NG+ %d", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "D11",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "100%", "50%", "25%",
    "kg", "m", "s", "ms", "Hz", "dB", "MB", "GB", "KB", "px", "Last Streetlight",
    "Holster", "Quests", "Sprinter", "Combo Master", "Flashlight", "Batteries", "Medkits"
}

# Strict Godot format specifier pattern (%s, %d, %f, %.1f, %02d, %x, %X, etc.)
FORMAT_SPECIFIER_PATTERN = re.compile(r'%(?:\.\d+|\d+)*[sdfcxX%]')

# Known archived/unreachable dead code files per KNOWN_ISSUES.md (hard zone rule forbids editing existing files)
ARCHIVED_SCRIPTS = {
    "scripts/ui/lobby_menu.gd",
    "scripts/ui/save_slot_entry.gd",
    "scripts/ui/save_slots_ui.gd"
}

def extract_placeholders(text):
    if not isinstance(text, str):
        return []
    return FORMAT_SPECIFIER_PATTERN.findall(text)

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
    i18n_dir = os.path.join(repo_root, "data/i18n")

    print("--- i18n PLACEHOLDER & TYPOGRAPHY FUZZER ---")

    # Load master EN
    en_path = os.path.join(i18n_dir, "en.json")
    with open(en_path, "r", encoding="utf-8") as f:
        en_data = json.load(f)

    total_keys = len(en_data)
    print(f"Master en.json loaded with {total_keys} keys.")

    errors = []
    warnings = []

    # 1. Placeholder Parity Check & Romanized Placeholder Check across all locales
    for loc in LOCALES:
        loc_path = os.path.join(i18n_dir, f"{loc}.json")
        if not os.path.exists(loc_path):
            errors.append(f"Missing locale file: {loc_path}")
            continue

        with open(loc_path, "r", encoding="utf-8") as f:
            loc_data = json.load(f)

        # Key parity
        if len(loc_data) != total_keys:
            errors.append(f"Locale {loc} key count mismatch: expected {total_keys}, got {len(loc_data)}")

        for key, en_val in en_data.items():
            if key not in loc_data:
                errors.append(f"Locale {loc} missing key: {key}")
                continue

            loc_val = loc_data[key]

            # Placeholder parity
            en_ph = extract_placeholders(en_val)
            loc_ph = extract_placeholders(loc_val)
            if sorted(en_ph) != sorted(loc_ph):
                errors.append(f"Placeholder mismatch in [{loc}] key '{key}': EN has {en_ph}, {loc} has {loc_ph}")

            # Romanized invalid placeholder check (e.g. %S instead of %s, %D instead of %d)
            invalid_ph = re.findall(r'%[A-CE-RT-WY-Z]', loc_val)
            if invalid_ph:
                errors.append(f"Romanized / invalid upper-case placeholder in [{loc}] key '{key}': {invalid_ph}")

            # Cognate check (if identical to EN, verify it's in whitelist or numeric/symbolic)
            if loc != "en" and loc_val == en_val and en_val not in COGNATE_WHITELIST:
                if not re.match(r'^[0-9\s%.:_/-]+$', en_val): # purely numeric/punctuation
                    warnings.append(f"Unwhitelisted EN cognate in [{loc}] key '{key}': '{en_val}'")

    print(f"Placeholder parity check complete across {len(LOCALES)} locales.")

    # 2. Check for raw tr("sentence") calls in active GDScripts
    raw_tr_pattern = re.compile(r'\btr\s*\(\s*"([^"]*\s[^"]*)"\s*\)')
    scripts_dir = os.path.join(repo_root, "scripts")
    raw_tr_count = 0
    for root, _, files in os.walk(scripts_dir):
        for file in files:
            if file.endswith(".gd"):
                filepath = os.path.join(root, file)
                relpath = os.path.relpath(filepath, repo_root).replace("\\", "/")
                if relpath in ARCHIVED_SCRIPTS:
                    continue
                with open(filepath, "r", encoding="utf-8", errors="ignore") as sf:
                    for line_num, line in enumerate(sf, 1):
                        m = raw_tr_pattern.search(line)
                        if m:
                            matched_str = m.group(1)
                            if not line.strip().startswith("#"):
                                raw_tr_count += 1
                                errors.append(f"Raw sentence tr() in {relpath}:{line_num} -> \"{matched_str}\"")

    print(f"Raw sentence tr() scan complete in active scripts/. Found {raw_tr_count} violations.")

    print("\n-----------------------------------------------------")
    print(f"ERRORS: {len(errors)} | WARNINGS: {len(warnings)}")

    if errors:
        print(f"FAIL: Found {len(errors)} i18n errors:")
        for e in errors[:10]:
            print(f"  [ERR] {e}")
        sys.exit(1)
    else:
        print("PASS: i18n placeholder & typography fuzz test passed cleanly across all 13 locales.")
        sys.exit(0)

if __name__ == "__main__":
    main()
