"""Merges tools/i18n_new_keys.json into every data/i18n/<locale>.json and
replaces the transliterated ru.json values with proper Cyrillic.

Idempotent: re-running changes nothing. Key order in en.json is the canonical
order; every other locale is rewritten in that same order so diffs stay small.
"""
import io
import json
import os

LOC_DIR = 'data/i18n'
NEW = 'tools/i18n_new_keys.json'
RU_CYR = 'tools/i18n_ru_cyrillic.json'


def load(path):
    return json.load(io.open(path, encoding='utf-8'))


def save(path, data):
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


new_keys = load(NEW)
ru_cyr = load(RU_CYR)

locales = sorted(f[:-5] for f in os.listdir(LOC_DIR) if f.endswith('.json'))
en = load(os.path.join(LOC_DIR, 'en.json'))

# Canonical key order: existing en.json order, then the new keys.
order = list(en.keys()) + [k for k in new_keys if k not in en]

for loc in locales:
    path = os.path.join(LOC_DIR, '%s.json' % loc)
    data = load(path)
    if loc == 'ru':
        data.update(ru_cyr)
    for k, per_lang in new_keys.items():
        if loc not in per_lang:
            raise SystemExit('missing translation: %s / %s' % (k, loc))
        data[k] = per_lang[loc]
    out = {}
    for k in order:
        if k in data:
            out[k] = data[k]
    for k in data:  # keys unique to this locale, if any
        if k not in out:
            out[k] = data[k]
    save(path, out)
    print('%-6s %d keys' % (loc, len(out)))
