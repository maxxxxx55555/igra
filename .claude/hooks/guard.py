#!/usr/bin/env python3
"""Mechanical guardrails. stdin = Claude Code hook JSON. Exit 2 = BLOCK the call."""
import json, os, re, sys
try: d = json.load(sys.stdin)
except Exception: sys.exit(0)
tool = d.get("tool_name", "")
ti   = d.get("tool_input", {}) or {}
def block(msg):
    print(msg, file=sys.stderr); sys.exit(2)
# --- R1: no new markdown outside the allow-list ---
if tool in ("Write", "Edit", "MultiEdit"):
    p = (ti.get("file_path") or "").replace("\\", "/")
    if p.endswith(".md"):
        allowed = ("docs/NITPICK_v1.0.md", "docs/KNOWN_ISSUES.md", "docs/RESUME_NOTE.md",
                   "docs/RUN_STATE.md", "RELEASE_CHECKLIST.md", "RELEASE_NOTES.md",
                   "docs/VISUAL_REMAINING.md")
        if not any(p.endswith(a) for a in allowed) and not os.path.exists(p):
            block("R1 VIOLATION: refusing to create a new markdown file (%s). Change the game "
                  "instead. If genuinely required, the owner must edit the allow-list in "
                  ".claude/hooks/guard.py." % p)
    # --- R15: no new agent scaffolding ---
    if re.search(r"\.claude/(agents|commands|skills)/", p) or p.endswith(".mcp.json"):
        block("R15 VIOLATION: no new subagent, slash command, skill or MCP server beyond "
              "what §0.12 installs. The constraint on this project is attention, not tooling.")
    # --- R11/AF4: gate tuning is watched ---
    if p.endswith(("tools/check.sh", "tools/qa_sim/af3_frame_check.py",
                   "tools/qa_sim/audio_loudness.py", "tools/qa_sim/af3_f4_scope.tsv",
                   "tools/qa_sim/drawcall_estimate.py")):
        body = json.dumps(ti)
        if re.search(r"(PASS|FAIL|threshold|ceiling|budget|tolerance)", body):
            print("AF4 WATCH: you are editing a gate. Legal only to ADD a check or declare an "
                  "AF3 scope row. Tuning a number so a failing test passes violates R11 and must "
                  "be confessed in the queue EVIDENCE column.", file=sys.stderr)
# --- Git and filesystem safety (the Bash tool and this harness's PowerShell tool) ---
if tool in ("Bash", "PowerShell"):
    c = ti.get("command") or ""
    for pat, why in (
        (r"git\s+push\s+.*(--force|-f)\b",          "never force-push"),
        (r"git\s+push\s+.*--tags\b",                "push the explicit tag ref, never --tags"),
        (r"git\s+(reset\s+--hard|clean\s+-[a-z]*f)", "never destroy uncommitted work"),
        (r"git\s+filter-(repo|branch)",             "history rewrite is an owner decision (K-1)"),
        (r"rm\s+-rf\s+/(?!home|tmp)",               "refusing an absolute destructive rm"),
        (r"\b(pip|npm|winget|apt|brew)\s+install\b(?!.*(gdtoolkit|ruff|pillow|numpy|scipy|trimesh|ffmpeg))",
                                                    "R15: nothing installs beyond Phase 0"),
        (r"\b(strix|playwright|puppeteer|docker)\b", "R15/H-STRIX: explicitly not used on this project"),
    ):
        if re.search(pat, c): block("BLOCKED by guard.py: %s" % why)
sys.exit(0)
