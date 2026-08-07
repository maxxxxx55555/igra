import re, json, io, os, collections, sys

LOC_DIR = 'data/i18n'
EN = os.path.join(LOC_DIR, 'en.json')

keys = set(json.load(io.open(EN, encoding='utf-8')).keys())

PAT = re.compile(r'(?:\btr|LocalizationManager\.t|Localization\.t)\(\s*"((?:[^"\\\n]|\\.)*)"')

ESCAPES = [('\\n', '\n'), ('\\t', '\t'), ('\\"', '"')]


def unescape(s):
    for a, b in ESCAPES:
        s = s.replace(a, b)
    return s


def scan():
    used = collections.defaultdict(list)
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in ('.godot', '.git', '_BACKUPS', '.import')]
        for fn in files:
            if not fn.endswith(('.gd', '.tscn')):
                continue
            p = os.path.join(root, fn)
            try:
                s = io.open(p, encoding='utf-8', errors='ignore').read()
            except Exception:
                continue
            for m in PAT.finditer(s):
                used[unescape(m.group(1))].append(p.replace(os.sep, '/'))
    return used


used = scan()
missing = sorted(k for k in used if k not in keys)
print('tr() keys used: %d | en.json: %d | MISSING: %d' % (len(used), len(keys), len(missing)))
json.dump({k: used[k][0] for k in missing},
          io.open('missing_keys.json', 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)
for k in missing:
    print('  %-40s %s' % (repr(k), used[k][0]))
sys.exit(1 if missing else 0)
