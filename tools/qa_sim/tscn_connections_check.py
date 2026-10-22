#!/usr/bin/env python3
"""Static [connection] check for .tscn files (Session 30, verifier round finding).

Godot resolves a scene's [connection] rows when the scene is instantiated: a `from`
node path that does not exist, or a `method` that the target node's script does not
define, is an engine ERROR on every open of that scene and a dead, focusable control.
The verifier found six such rows in scenes/ui/settings_screen.tscn (handlers that were
removed when the screen went procedural); this gate holds the whole tree.

Run:  python tools/qa_sim/tscn_connections_check.py
Exit: 0 - clean, otherwise the number of findings.
"""
from __future__ import annotations

import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

NODE_RE = re.compile(r'^\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]*)")?(?:\s+instance=ExtResource\("([^"]+)"\))?', re.M)
SCRIPT_PROP_RE = re.compile(r'^script = ExtResource\("([^"]+)"\)', re.M)
EXT_SCRIPT_RE = re.compile(r'^\[ext_resource type="Script" (?:path|uid)="([^"]+)" id="([^"]+)"', re.M)
CONN_RE = re.compile(r'^\[connection signal="([^"]+)" from="([^"]+)" to="([^"]+)" method="([^"]+)"', re.M)
FUNC_RE = re.compile(r'^(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', re.M)


def script_functions(rel_path: str):
    path = os.path.join(ROOT, rel_path.replace("res://", ""))
    try:
        text = open(path, encoding="utf-8", errors="ignore").read()
    except OSError:
        return None
    funcs = set(FUNC_RE.findall(text))
    # inherited scripts: follow `extends "res://..."` one level down
    m = re.search(r'^extends\s+"(res://[^"]+)"', text, re.M)
    if m:
        parent = script_functions(m.group(1))
        if parent:
            funcs |= parent
    return funcs


def check_scene(rel_scene: str):
    path = os.path.join(ROOT, rel_scene)
    text = open(path, encoding="utf-8", errors="ignore").read()
    ext_script = {eid: p for p, eid in EXT_SCRIPT_RE.findall(text)}
    nodes = {}  # full node path from the scene root -> {"script": str|None, "instance": str|None}
    for m in NODE_RE.finditer(text):
        name, _type, parent, instance = m.group(1), m.group(2), m.group(3), m.group(4)
        if parent is None:
            node_path = "."  # the scene root; [connection] to="." names it
        elif parent in ("", "."):
            node_path = name
        else:
            node_path = parent + "/" + name
        # script property belongs to this node if it appears before the next [node]
        seg_start = m.end()
        nxt = text.find("\n[node ", seg_start)
        seg = text[seg_start:nxt if nxt != -1 else len(text)]
        sm = SCRIPT_PROP_RE.search(seg)
        nodes[node_path] = {
            "script": ext_script.get(sm.group(1)) if sm else None,
            "instance": instance,
            "type": _type,
        }
    findings = []
    for m in CONN_RE.finditer(text):
        signal, frm, to, method = m.group(1), m.group(2), m.group(3), m.group(4)
        if frm not in ("", ".") and frm not in nodes:
            findings.append((rel_scene, "from node '%s' does not exist (signal %s -> %s)" % (frm, signal, method)))
            continue
        target = nodes.get(to if to not in ("", ".") else ".")
        if target is None:
            findings.append((rel_scene, "to node '%s' does not exist (signal %s -> %s)" % (to, signal, method)))
            continue
        if target["script"] is None:
            if target["instance"] is not None:
                continue  # instanced scene: the script lives in another file; out of scope here
            findings.append((rel_scene, "to node '%s' has no script, method '%s' cannot exist" % (to, method)))
            continue
        funcs = script_functions(target["script"])
        if funcs is None:
            findings.append((rel_scene, "script %s of node '%s' is missing" % (target["script"], to)))
            continue
        if method not in funcs:
            findings.append((rel_scene, "method '%s' is not defined in %s (node '%s')" % (method, target["script"], to)))
    return findings


def main() -> int:
    scenes = sorted(glob.glob(os.path.join(ROOT, "scenes", "**", "*.tscn"), recursive=True))
    all_findings = []
    for scene in scenes:
        rel = os.path.relpath(scene, ROOT).replace(os.sep, "/")
        all_findings.extend(check_scene(rel))
    for rel, msg in all_findings:
        print("FAIL %s: %s" % (rel, msg))
    print("tscn_connections_check: %d scene(s), %d finding(s)" % (len(scenes), len(all_findings)))
    return len(all_findings)


if __name__ == "__main__":
    sys.exit(min(main(), 120))
