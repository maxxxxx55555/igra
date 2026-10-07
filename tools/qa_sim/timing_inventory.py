# -*- coding: utf-8 -*-
"""Frame-independence inventory (rc16 O2): every _process / _physics_process / Tween / Timer / frame-count site of the shipped
scripts, and the lines that could depend on the frame rate.

usage: python tools/qa_sim/timing_inventory.py            summary + every open suspect (file:line kind code)
       python tools/qa_sim/timing_inventory.py --gate     exit 1 while a suspect is neither fixed nor listed in timing_whitelist.json
       python tools/qa_sim/timing_inventory.py --table    write docs/artifacts/rc16/timing_inventory.md (one row per script)
       python tools/qa_sim/timing_inventory.py --demo     self-check of the detectors on synthetic code

A suspect is a line in a function that runs every frame (_process, _physics_process, or a function they call, up to three calls
deep inside the same file) that moves a value by a constant instead of by delta:
  LERP_NO_DELTA    lerp / lerpf / lerp_angle / move_toward / slerp / .lerp whose weight does not come from delta
  STEP_NO_DELTA    `x += <constant>` or `x -= <constant>` without delta (a per-frame counter or a per-frame step)
  TRANSFORM_STEP   rotate / translate / position += without delta
  FRAME_COUNTER    Engine.get_frames_drawn / get_physics_frames, a `% N == 0` frame modulo, an awaited process_frame inside a loop
A whitelist row is {"file", "text" (the stripped source line), "why"}; a row that matches no line any more is itself an error.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
WHITELIST = ROOT / "tools" / "qa_sim" / "timing_whitelist.json"
SKIP_DIRS = ("scripts/tools/", "addons/applovin_max/")
EVERY_FRAME = ("_process", "_physics_process")
LERPS = re.compile(r"(?<![\w.])(lerp|lerpf|lerp_angle|move_toward|move_toward_angle|slerp)\(|\.(lerp|slerp|move_toward|interpolate_with)\(")
STEP = re.compile(r"^\s*[\w.\[\]\"']+\s*([+\-])=\s*(-?[0-9][0-9._]*|[A-Z][A-Z0-9_]{2,})\s*(#.*)?$")
TRANSFORM = re.compile(r"\b(rotate|rotate_x|rotate_y|rotate_z|translate|translate_object_local)\(|\b(global_position|position|rotation|global_rotation)(\.[xyz])?\s*[+\-]=")
FRAME_API = re.compile(r"Engine\.get_(frames_drawn|physics_frames|process_frames)\(\)")
MODULO = re.compile(r"(frame|frames|tick|ticks|_count|counter)\w*\s*%\s*\d+")
FUNC = re.compile(r"^(\s*)(static\s+)?func\s+(\w+)\s*\(")


def shipped_scripts():
    out = []
    for p in sorted(ROOT.glob("scripts/**/*.gd")) + sorted(ROOT.glob("addons/**/*.gd")):
        rel = p.relative_to(ROOT).as_posix()
        if not rel.startswith(SKIP_DIRS):
            out.append(rel)
    return out


def functions(lines):
    """name -> (first_line_index, [(index, text)]) for every function; the body ends at the next line with an indent <= the func's."""
    found = {}
    i = 0
    while i < len(lines):
        m = FUNC.match(lines[i])
        if m:
            indent = len(m.group(1).replace("\t", "    "))
            body = []
            j = i + 1
            while j < len(lines):
                t = lines[j]
                if t.strip() and not t.strip().startswith("#"):
                    cur = len(t) - len(t.lstrip("\t "))
                    if cur <= indent and not t.lstrip().startswith(("#", ")", "]", "}")):
                        break
                body.append((j, t))
                j += 1
            found[m.group(3)] = (i, body)
            i = j
            continue
        i += 1
    return found


def reachable(funcs):
    """_process and _physics_process plus the functions they call by name, up to three calls deep."""
    seen = {n for n in EVERY_FRAME if n in funcs}
    frontier = set(seen)
    for _ in range(3):
        nxt = set()
        for n in frontier:
            text = "\n".join(t for _, t in funcs[n][1])
            for other in funcs:
                if other not in seen and re.search(r"\b" + re.escape(other) + r"\(", text):
                    nxt.add(other)
        seen |= nxt
        frontier = nxt
    return seen


def split_args(call_text):
    """Top-level comma split of the text inside the first balanced parentheses of call_text."""
    start = call_text.index("(")
    depth, cur, args = 0, "", []
    for ch in call_text[start:]:
        if ch in "([{":
            depth += 1
            if depth == 1:
                continue
        elif ch in ")]}":
            depth -= 1
            if depth == 0:
                args.append(cur.strip())
                return args
        if ch == "," and depth == 1:
            args.append(cur.strip())
            cur = ""
        else:
            cur += ch
    args.append(cur.strip())
    return args


def delta_weighted(weight, body_text):
    if "delta" in weight:
        return True
    if re.fullmatch(r"[A-Za-z_]\w*", weight):
        return re.search(r"\b" + re.escape(weight) + r"\b\s*(?::\s*[\w\[\]]+\s*)?(?::=|=)[^\n]*delta", body_text) is not None
    return False


def lerp_weight(line):
    m = LERPS.search(line)
    if m is None:
        return None
    args = split_args(line[m.start():])
    return args[-1] if args else ""


def suspects_of(rel, lines):
    funcs = functions(lines)
    hot = reachable(funcs)
    out = []
    for name in sorted(hot):
        body = funcs[name][1]
        body_text = "\n".join(t for _, t in body)
        for idx, text in body:
            s = text.strip()
            if not s or s.startswith("#") or "delta" in s and not LERPS.search(s):
                continue
            kind = None
            if LERPS.search(s):
                w = lerp_weight(s)
                if w is not None and not delta_weighted(w, body_text):
                    kind = "LERP_NO_DELTA"
            elif STEP.match(s) and "delta" not in s:
                kind = "STEP_NO_DELTA"
            elif TRANSFORM.search(s) and "delta" not in s:
                kind = "TRANSFORM_STEP"
            if kind:
                out.append((idx + 1, kind, s, name))
    for idx, text in enumerate(lines):
        s = text.strip()
        if s.startswith("#"):
            continue
        if FRAME_API.search(s) or MODULO.search(s):
            out.append((idx + 1, "FRAME_COUNTER", s, "-"))
    loop_indent = []
    for idx, text in enumerate(lines):
        stripped = text.strip()
        ind = len(text) - len(text.lstrip("\t "))
        loop_indent = [x for x in loop_indent if ind > x]
        if re.match(r"(for|while)\b", stripped):
            loop_indent.append(ind)
        elif loop_indent and re.search(r"await\s+get_tree\(\)\.process_frame", stripped):
            out.append((idx + 1, "FRAME_COUNTER", stripped, "-"))
    return out


def counts(lines):
    text = "\n".join(lines)
    return {
        "process": len(re.findall(r"^func _process\(", text, re.M)),
        "physics": len(re.findall(r"^func _physics_process\(", text, re.M)),
        "tween": len(re.findall(r"create_tween\(", text)),
        "timer": len(re.findall(r"create_timer\(", text)) + len(re.findall(r"Timer\.new\(\)", text)),
    }


def load_whitelist():
    if not WHITELIST.exists():
        return []
    return json.loads(WHITELIST.read_text(encoding="utf-8"))


def run():
    rows, open_suspects, all_suspects = [], [], []
    white = load_whitelist()
    used = set()
    for rel in shipped_scripts():
        lines = (ROOT / rel).read_text(encoding="utf-8", errors="replace").splitlines()
        c = counts(lines)
        sus = suspects_of(rel, lines)
        n_open = 0
        for line_no, kind, text, fn in sus:
            all_suspects.append((rel, line_no, kind, text))
            hit = next((i for i, w in enumerate(white) if w["file"] == rel and w["text"] == text), None)
            if hit is None:
                open_suspects.append((rel, line_no, kind, text))
                n_open += 1
            else:
                used.add(hit)
        if any(c.values()) or sus:
            rows.append((rel, c, len(sus), n_open))
    stale = [w for i, w in enumerate(white) if i not in used]
    return rows, open_suspects, all_suspects, stale


def demo():
    src = [
        "extends Node3D",
        "func _process(delta: float) -> void:",
        "\tvar k := 1.0 - exp(-6.0 * delta)",
        "\tx = lerpf(x, 1.0, k)",
        "\tvar k2: float = clamp(delta * 4.0, 0.0, 1.0)",
        "\tx = lerpf(x, 1.0, k2)",
        "\ty = lerpf(y, 1.0, 0.1)",
        "\t_t += 1",
        "\trotate_y(0.02)",
        "\t_helper()",
        "func _helper() -> void:",
        "\tfade = move_toward(fade, 1.0, 0.05)",
        "\tif Engine.get_frames_drawn() % 3 == 0:",
        "\t\tpass",
        "func _ready() -> void:",
        "\tz = lerpf(z, 1.0, 0.5)",
    ]
    kinds = sorted((k, text) for _, k, text, _ in suspects_of("demo.gd", src))
    want = sorted([
        ("LERP_NO_DELTA", "y = lerpf(y, 1.0, 0.1)"),
        ("STEP_NO_DELTA", "_t += 1"),
        ("TRANSFORM_STEP", "rotate_y(0.02)"),
        ("LERP_NO_DELTA", "fade = move_toward(fade, 1.0, 0.05)"),
        ("FRAME_COUNTER", "if Engine.get_frames_drawn() % 3 == 0:"),
    ])
    assert kinds == want, (kinds, want)
    print("timing_inventory demo OK (5 detectors, delta-weighted lerp and _ready lerp stay quiet)")


def main():
    if "--demo" in sys.argv:
        demo()
        return 0
    rows, open_suspects, all_suspects, stale = run()
    tot = {k: sum(r[1][k] for r in rows) for k in ("process", "physics", "tween", "timer")}
    print("scripts with timing sites: %d | _process %d | _physics_process %d | Tween %d | Timer %d | suspects %d | open %d | stale whitelist rows %d" % (
        len(rows), tot["process"], tot["physics"], tot["tween"], tot["timer"], len(all_suspects), len(open_suspects), len(stale)))
    if "--table" in sys.argv:
        out = ROOT / "docs" / "artifacts" / "rc16" / "timing_inventory.md"
        out.parent.mkdir(parents=True, exist_ok=True)
        text = "| script | _process | _physics_process | Tween | Timer | suspects | open |\n|---|---|---|---|---|---|---|\n"
        text += "".join("| %s | %d | %d | %d | %d | %d | %d |\n" % (r[0], r[1]["process"], r[1]["physics"], r[1]["tween"], r[1]["timer"], r[2], r[3]) for r in rows)
        out.write_text(text, encoding="utf-8", newline="\n")
        print("wrote", out.relative_to(ROOT).as_posix())
    for rel, line_no, kind, text in open_suspects:
        print("%s:%d %s %s" % (rel, line_no, kind, text[:140]))
    for w in stale:
        print("STALE whitelist row: %s | %s" % (w["file"], w["text"][:100]))
    if "--gate" in sys.argv:
        bad = len(open_suspects) + len(stale)
        print("timing_inventory gate:", "PASS" if bad == 0 else "FAIL (%d open or stale)" % bad)
        return 1 if bad else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
