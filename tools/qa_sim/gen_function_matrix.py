#!/usr/bin/env python3
"""P1: generates the FUNCTION_MATRIX.md spine (one row per autoload, one row
per input-map action) straight from project.godot, so the matrix's row count
can be cross-checked against the project's own config instead of trusting a
hand-typed list. Extra rows (UI screens, non-autoload gameplay systems like
stealth/boss, standing bugs) are appended by hand in FUNCTION_MATRIX.md after
generation - this script only proves the autoload+input spine is complete,
matching the order-pass spec's own "cross-count vs autoload+input list" step.

Usage: python tools/qa_sim/gen_function_matrix.py > /tmp/spine.md
Prints the row count to stderr for the cross-count proof.
"""
import re
import sys
from pathlib import Path


def parse_autoloads(cfg: str) -> list[tuple[str, str]]:
    section = cfg.split("[autoload]")[1].split("\n[")[0]
    return re.findall(r'^(\w+)="\*?(res://[^"]+)"', section, re.M)


def parse_inputs(cfg: str) -> list[str]:
    section = cfg.split("[input]")[1].split("\n[")[0] if "[input]" in cfg else ""
    return re.findall(r"^(\w+)=", section, re.M)


def main() -> int:
    cfg = Path("project.godot").read_text(encoding="utf-8")
    autoloads = parse_autoloads(cfg)
    inputs = parse_inputs(cfg)

    rows = 0
    print("| ID | Function | Entry | Test method | Status |")
    print("|---|---|---|---|---|")
    for name, path in autoloads:
        rows += 1
        print("| AL%02d | %s (autoload) | `%s` | UNTESTED | UNTESTED |" % (rows, name, path[6:]))
    for action in inputs:
        rows += 1
        print("| IN%02d | input action `%s` | `project.godot [input]` | UNTESTED | UNTESTED |" % (rows, action))

    print("\nTotal spine rows: %d (%d autoloads + %d input actions)" % (
        rows, len(autoloads), len(inputs)), file=sys.stderr)
    return 0


def _demo() -> None:
    """ponytail self-check: parse a tiny synthetic project.godot."""
    cfg = '[autoload]\nFoo="*res://a.gd"\nBar="*res://b.gd"\n\n[input]\njump={\n"deadzone": 0.5\n}\nrun={\n}\n\n[rendering]\n'
    autoloads = parse_autoloads(cfg)
    inputs = parse_inputs(cfg)
    assert autoloads == [("Foo", "res://a.gd"), ("Bar", "res://b.gd")], autoloads
    assert inputs == ["jump", "run"], inputs
    print("demo OK")


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--demo":
        _demo()
        sys.exit(0)
    sys.exit(main())
