#!/usr/bin/env python3
"""Which asset files can the game reach (WORKQUEUE E, the safety rail of the size pass). The game builds many resource paths from strings at run time ("res://assets/audio/sfx/%s.wav" % name, DIR + id + ".png"), so a
search for the literal path misses them and deleting what the search misses silences monsters and empties the encyclopedia while the game still boots clean. This tool counts a file as RESOLVED when any of these holds:
  1. LITERAL   its path ("res://assets/..." or the relative form in a data file) is written out in the code, a scene, a resource, a data file or the project settings;
  2. TEMPLATE  it matches a path with a format hole ("res://assets/textures/items/%s.png" -> items/<anything>.png) and the word in the hole is written somewhere in the code or the data (the fill of the template);
  3. DIRECTORY it stands in a directory that the code names as a prefix ("res://assets/audio/sfx/" + name + ".wav") and its name, less the trailing number, is written somewhere in the code or the data.
A file that none of these reaches is a DELETION CANDIDATE, never a proof: read the list before a file goes. Files of assets/store, the sources of the imports (.import, .uid) and the documents are left out of the count.

usage: python tools/qa_sim/dynpath_resolve.py [--list [dir-prefix]] [--min-kb N] [--json out.json] [--dups] [--fixture]
  --list  prints the candidates (of a directory) largest first; --dups groups the files of one content (sha256) that are two or more.
  --fixture  exits 1 when a file of a directory the game fills from data (FIXTURE below: the 40 detail beds of the districts, the icons, the portraits) is a candidate: the files a naive deletion pass would take.
"""
import argparse
import collections
import fnmatch
import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCAN = ["assets", "content", "data"]
SKIP_SUFFIX = {".import", ".uid", ".md"}
TEXT_SUFFIX = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".json", ".gdshader", ".shader", ".res"}
CORPUS_DIRS = ["scripts", "scenes", "assets", "data", "content", "addons"]
CORPUS_SKIP = ("data/i18n", "content/cards", "assets/store", "scripts/tools", "scenes/tools")
LITERAL = re.compile(r"res://[^\s\"'`)\]},;]+")
RELATIVE = re.compile(r"[\"']([\w\-./ ]+\.(?:png|jpg|jpeg|webp|svg|ogg|wav|mp3|tres|tscn|json|ttf|otf|res|glb|gdshader|cfg))[\"']")
HOLE = re.compile(r"%(?:\d*)[sd]")
FIXTURE = ["assets/audio/ambience/district_details/*.ogg", "assets/textures/portraits_v2/*_full_512x768.png", "assets/textures/icons_v2/monster_*_64.png", "assets/textures/icons_v2/stat_*_64.png",
           "assets/textures/icons_v2/ach_medal_v2_*_96.png", "assets/textures/icons_v2/branches/*_header_256x64.png", "assets/textures/cards/card_*_512.png", "assets/textures/crests/crest_*_96.png",
           "assets/textures/luts/lut_*.png", "assets/photos/*.png", "assets/textures/renders_v2/weapons/*_render_256.png", "assets/textures/badges/badge_*_128.png",
           "assets/textures/icons/skills/*_96.png", "assets/textures/touch/help_*_96.png", "assets/textures/tiles/*_floor.png"]
PREFIX = re.compile(r"\"(res://[^\"%]*/)\"")


def text_files():
    for d in CORPUS_DIRS:
        for p in (ROOT / d).rglob("*"):
            rel = p.relative_to(ROOT).as_posix()
            if p.is_file() and p.suffix in TEXT_SUFFIX and not rel.startswith(CORPUS_SKIP):
                yield rel, p
    for name in ("project.godot", "export_presets.cfg"):
        if (ROOT / name).exists():
            yield name, ROOT / name


def asset_files():
    for d in SCAN:
        for p in (ROOT / d).rglob("*"):
            rel = p.relative_to(ROOT).as_posix()
            if p.is_file() and p.suffix not in SKIP_SUFFIX and not rel.startswith("assets/store/"):
                yield rel, p.stat().st_size


def resolve():
    literals, relatives, templates, prefixes = set(), set(), [], set()
    corpus = []
    for rel, p in text_files():
        t = p.read_text(encoding="utf-8", errors="ignore")
        corpus.append(t)
        for m in LITERAL.findall(t):
            path = m[len("res://"):].rstrip(".")
            if HOLE.search(path):
                if rel.endswith(".gd"):
                    templates.append(path)
            else:
                literals.add(path)
        for m in RELATIVE.findall(t):
            relatives.add(m)
        if rel.endswith(".gd"):
            for m in PREFIX.findall(t):
                prefixes.add(m[len("res://"):])
    text = "\n".join(corpus)
    words = set(re.findall(r"[A-Za-z0-9_]+", text))
    regexes = []
    for tpl in sorted(set(templates)):
        parts = HOLE.split(tpl)
        regexes.append((tpl, re.compile("^" + "(.+?)".join(re.escape(x) for x in parts) + "$")))
    result = {}
    for rel, size in asset_files():
        stem = pathlib.PurePosixPath(rel).stem
        base = re.sub(r"_(albedo|normal|rough)$", "", re.sub(r"_?\d+$", "", stem))  # a PBR map is named by its set: pbr_sets.gd builds DIR + set + "_albedo.png"
        reason = ""
        if rel in literals or any(r == rel or r.endswith("/" + rel) or rel.endswith("/" + r) for r in relatives):
            reason = "literal"
        if not reason:
            for tpl, rx in regexes:
                m = rx.match(rel)
                if m:
                    inner = "".join(m.groups())  # the fill: one hole, or the holes side by side ("card_%s%s_512" -> suburbs_locked)
                    if inner in words or all(part in words or re.sub(r"\d+$", "", part) in words for part in inner.split("_") if part):
                        reason = "template " + tpl
                        break
        if not reason:
            for pre in prefixes:
                if rel.startswith(pre) and "/" not in rel[len(pre):] and (stem in words or base in words):
                    reason = "directory " + pre
                    break
        result[rel] = (size, reason)
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", nargs="?", const="", default=None)
    ap.add_argument("--min-kb", type=float, default=0.0)
    ap.add_argument("--json", default="")
    ap.add_argument("--dups", action="store_true")
    ap.add_argument("--fixture", action="store_true")
    args = ap.parse_args()
    if args.dups:
        by_hash = collections.defaultdict(list)
        for rel, size in asset_files():
            by_hash[hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()].append((rel, size))
        groups = [g for g in by_hash.values() if len(g) > 1]
        groups.sort(key=lambda g: -sum(s for _, s in g[1:]))
        print("%d groups of identical files, %.1f MB in the extra copies" % (len(groups), sum(s for g in groups for _, s in g[1:]) / 1e6))
        for g in groups[:60]:
            print("%8.0f KB x%d  %s" % (g[0][1] / 1e3, len(g), "  |  ".join(x for x, _ in g)))
        return 0
    found = resolve()
    dead = {k: v for k, v in found.items() if not v[1]}
    if args.fixture:
        items = ["assets/textures/items/%s.png" % p.stem for p in (ROOT / "data/items").glob("*.tres")]
        wanted = sorted({k for k in found if any(fnmatch.fnmatch(k, pat) for pat in FIXTURE)} | set(items))
        lost = [k for k in wanted if k in dead or k not in found]
        print("fixture: %d files the game fills from data (%d item icons, the detail beds, the portraits, the icons, cards, crests, luts, photos, renders, badges, skills, touch, floors)" % (len(wanted), len(items)))
        print("fixture: %d of them are missing or candidates for deletion%s" % (len(lost), (": " + ", ".join(lost[:12])) if lost else ""))
        return 1 if lost else 0
    by_dir = collections.defaultdict(lambda: [0, 0, 0, 0])
    for rel, (size, reason) in found.items():
        d = "/".join(rel.split("/")[:3])
        row = by_dir[d]
        row[0 if reason else 2] += 1
        row[1 if reason else 3] += size
    print("%d files, %.1f MB; resolved %d (%.1f MB); candidates %d (%.1f MB)" % (len(found), sum(v[0] for v in found.values()) / 1e6, len(found) - len(dead), sum(v[0] for k, v in found.items() if v[1]) / 1e6, len(dead), sum(v[0] for v in dead.values()) / 1e6))
    print("%-44s %6s %8s %6s %8s" % ("directory", "files", "MB", "dead", "dead MB"))
    for d, (n, s, dn, ds) in sorted(by_dir.items(), key=lambda kv: -kv[1][3]):
        if ds > 20000:
            print("%-44s %6d %8.2f %6d %8.2f" % (d, n + dn, (s + ds) / 1e6, dn, ds / 1e6))
    if args.list is not None:
        for rel, (size, _) in sorted(dead.items(), key=lambda kv: -kv[1][0]):
            if rel.startswith(args.list) and size >= args.min_kb * 1000:
                print("%8.1f KB  %s" % (size / 1000, rel))
    if args.json:
        pathlib.Path(args.json).write_text(json.dumps({k: {"bytes": v[0], "reason": v[1]} for k, v in sorted(found.items())}, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
