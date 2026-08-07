#!/usr/bin/env python3
"""Generate all locale JSON files from en.json using comprehensive dictionary."""
import json
import os

with open("data/i18n/en.json", "r", encoding="utf-8") as f:
    en = json.load(f)

# Read translations from a separate JSON file
with open("scripts/tools/translations.json", "r", encoding="utf-8") as f:
    T = json.load(f)

locales = ["de", "es", "fr", "it", "ja", "ko", "pt_BR", "tr", "zh", "zh_TW", "ar"]

def tr(key, loc):
    if key in T and loc in T[key]:
        return T[key][loc]
    return en.get(key, key)

for loc in locales:
    result = {}
    for key in en:
        result[key] = tr(key, loc)
    out_path = f"data/i18n/{loc}.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(f"Generated {out_path} with {len(result)} keys")

print("Done")
