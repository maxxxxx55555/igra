#!/usr/bin/env bash
# rc16 U0: every utility the release directive names (ECC, gdtoolkit, ruff, mypy, shellcheck, actionlint, pre-commit, pngquant, oggenc,
# godot-git-plugin), run or listed as absent, with the raw output. tools/qa_sim/proof_run keeps this output as the evidence of docs/UTILITIES_REPORT.md:
#   ECC_DIR=<a checkout of affaan-m/everything-claude-code> tools/qa_sim/proof_run utilities_u0 -- bash tools/utilities_report.sh
cd "$(dirname "$0")/.." || exit 2
PY="${PY:-python}"
BASE="${BASE:-e4bb4df}"
USER_SCRIPTS="$("$PY" -c "import os,sysconfig;print(sysconfig.get_path('scripts','nt_user' if os.name=='nt' else 'posix_user'))")"

exe() { command -v "$1" 2>/dev/null || { [[ -x "$USER_SCRIPTS/$1.exe" ]] && echo "$USER_SCRIPTS/$1.exe"; } || { [[ -x "$USER_SCRIPTS/$1" ]] && echo "$USER_SCRIPTS/$1"; }; }
have() { [[ -n "$(exe "$1")" ]] || "$PY" -m "$1" --version >/dev/null 2>&1; }
version() { local e; e="$(exe "$1")"; if [[ -n "$e" ]]; then "$e" --version 2>&1 | head -2 | tr '\n' ' '; else "$PY" -m "$1" --version 2>&1 | head -1; fi; }

echo "== availability (pip --user scripts directory: $USER_SCRIPTS)"
for t in gdparse gdlint gdformat shellcheck actionlint mypy ruff pre_commit pngquant oggenc ffmpeg flake8 black; do
	if [[ "$t" == gd* ]]; then m="gdtoolkit.${t/gdparse/parser}"; m="${m/gdlint/linter}"; m="${m/gdformat/formatter}"; if "$PY" -m "$m" --version >/dev/null 2>&1; then echo "$t: $("$PY" -m "$m" --version 2>&1 | head -1)"; else echo "$t: ABSENT"; fi
	elif have "$t"; then echo "$t: $(version "$t")"; else echo "$t: ABSENT"; fi
done

echo; echo "== ruff E9,F (syntax errors and pyflakes correctness) on tools/ and scripts/"
"$PY" -m ruff check tools scripts --select E9,F --output-format concise --no-cache; echo "exit=$?"

echo; echo "== ruff default rule set, findings per rule (style and modernisation: reported, not a gate)"
"$PY" -m ruff check tools scripts --statistics --no-cache 2>&1 | tail -4

echo; echo "== python compile of every .py (py_compile)"
n=0; bad=0
while IFS= read -r f; do n=$((n+1)); "$PY" -m py_compile "$f" 2>/dev/null || { echo "FAIL $f"; bad=$((bad+1)); }; done < <(git ls-files '*.py')
echo "compiled=$n failed=$bad"

echo; echo "== gdparse over every tracked .gd (378 files at the time of the report): which files does gdtoolkit not read?"
"$PY" - <<'PY'
import subprocess, time
from gdtoolkit.parser import parser
files = subprocess.run(["git", "ls-files", "*.gd"], capture_output=True, text=True).stdout.split()
bad = []
start = time.time()
for f in files:
    try:
        parser.parse(open(f, encoding="utf-8", errors="replace").read(), gather_metadata=False)
    except Exception as e:
        bad.append((f, " ".join(str(e).split())[:100]))
print("files=%d parse_failures=%d seconds=%.1f" % (len(files), len(bad), time.time() - start))
for f, e in bad:
    print("  " + f + " | " + e)
PY

echo; echo "== gdlint default rules on the .gd files changed since $BASE, findings per rule (style rules: rejected as a gate; the defect-class subset is gdlintrc)"
CH="$(git diff --name-only "$BASE" HEAD -- '*.gd' | grep -v '^addons/')"
echo "changed .gd files: $(echo "$CH" | wc -l | tr -d ' ')"
mkdir -p .qa_logs/gdlint_default && (cd .qa_logs/gdlint_default && "$PY" -m gdtoolkit.linter -d >/dev/null 2>&1; cd ../.. && for f in $CH; do echo "$f"; done | (cd .qa_logs/gdlint_default && xargs -I{} "$PY" -m gdtoolkit.linter ../../{} 2>&1) | grep -E "Error: " | sed -E 's/.*\((.*)\)$/\1/' | sort | uniq -c | sort -rn)
echo "-- gdlintrc (defect-class rules) through tools/lint_changed.py:"
"$PY" tools/lint_changed.py --demo; "$PY" tools/lint_changed.py; echo "exit=$?"

echo; echo "== shellcheck -S warning on every shell script, hook and extensionless wrapper (carriage returns stripped)"
SC="$(exe shellcheck)"; shellcheck_files=0; shellcheck_hits=0
if [[ -n "$SC" ]]; then
	while IFS= read -r f; do
		[[ -f "$f" ]] || continue
		case "$f" in *.sh|tools/hooks/*|tools/qa_sim/*) ;; *) continue ;; esac
		[[ "$f" == *.* && "$f" != *.sh ]] && continue
		shellcheck_files=$((shellcheck_files+1))
		out="$(tr -d '\r' < "$f" | "$SC" -s bash -f gcc -S warning - 2>&1 | sed "s#^-:#$f:#")"
		[[ -n "$out" ]] && { echo "$out"; shellcheck_hits=$((shellcheck_hits+$(echo "$out" | wc -l))); }
	done < <(git ls-files)
fi
echo "shellcheck files=$shellcheck_files findings=$shellcheck_hits"

echo; echo "== mypy over every tracked tools/ and scripts/ .py (--ignore-missing-imports)"
mapfile -t PYF < <(git ls-files 'tools/*.py' 'tools/**/*.py' 'scripts/**/*.py' | sort -u)
MYPY_OUT="$("$PY" -m mypy --ignore-missing-imports --follow-imports=silent --no-incremental --cache-dir=nul "${PYF[@]}" 2>&1)"
echo "$MYPY_OUT" | grep "error:" | sed -E 's/.*\[([a-z-]+)\]$//' | sort | uniq -c | sort -rn
echo "$MYPY_OUT" | grep "error:" | sed -E 's/^([^:]+:[0-9]+): error: (.{0,90}).*$/ /'
echo "$MYPY_OUT" | tail -1

echo; echo "== pre-commit: the config validates"
"$PY" -m pre_commit validate-config .pre-commit-config.yaml; echo "exit=$?"

echo; echo "== actionlint on the workflows"
AL="$(exe actionlint)"
if [[ -n "$AL" && -d .github/workflows ]]; then "$AL" -no-color .github/workflows/*.yml; echo "exit=$?"; else echo "no workflow or no actionlint"; fi

echo; echo "== assets changed since $BASE (pngquant and oggenc only matter for shipped assets; docs/ frames are evidence, not assets)"
git diff --name-only "$BASE" HEAD -- '*.png' '*.ogg' '*.wav' '*.jpg' ':!docs' | sed 's/^/changed: /'
echo "changed assets: $(git diff --name-only "$BASE" HEAD -- '*.png' '*.ogg' '*.wav' '*.jpg' ':!docs' | wc -l | tr -d ' ')"

echo; echo "== Everything Claude Code (ECC_DIR=${ECC_DIR:-unset})"
if [[ -n "${ECC_DIR:-}" && -d "$ECC_DIR/.git" ]]; then
	echo "commit: $(git -C "$ECC_DIR" rev-parse HEAD)"
	echo "skills: $(ls "$ECC_DIR/skills" | wc -l)  agents: $(ls "$ECC_DIR/agents" | wc -l)  commands: $(ls "$ECC_DIR/commands" | wc -l)"
	echo "files that mention godot or gdscript in skills, agents, rules, commands, hooks, scripts: $(grep -rli 'godot\|gdscript' "$ECC_DIR/skills" "$ECC_DIR/agents" "$ECC_DIR/rules" "$ECC_DIR/commands" "$ECC_DIR/hooks" "$ECC_DIR/scripts" 2>/dev/null | wc -l)"
	"$PY" - "$ECC_DIR/hooks/hooks.json" <<'PY2'
import json, sys, collections
data = json.load(open(sys.argv[1], encoding="utf-8"))
hooks = data.get("hooks", data)
events = collections.Counter()
runners = collections.Counter()
for event, entries in hooks.items():
    for entry in entries:
        for hook in entry.get("hooks", []):
            events[event] += 1
            runners[hook.get("command", "").split(" ")[0]] += 1
print("hooks.json: %d hook commands; per event %s; run by %s" % (sum(events.values()), dict(events), dict(runners)))
PY2
	for s in verification-loop continuous-learning continuous-learning-v2 config-gc strategic-compact token-budget-advisor; do
		printf "skill %s: " "$s"; sed -n '/^description:/p' "$ECC_DIR/skills/$s/SKILL.md" | head -1 | cut -c1-210
	done
	echo "verification-loop build/test commands: $(grep -cE 'npm|pnpm|pytest|cargo|go test|mvn|gradle' "$ECC_DIR/skills/verification-loop/SKILL.md") lines name npm, pnpm, pytest, cargo, go, mvn or gradle; godot: $(grep -ci godot "$ECC_DIR/skills/verification-loop/SKILL.md")"
else
	echo "ECC_DIR not set"
fi

echo; echo "== godot-git-plugin"
echo "an editor extension (a native library under addons/) that shows git status in the Godot editor; it is not a merge driver, and scene files (.tscn) are text that git merges as it merges any text"

echo; echo "== CI"
if [[ -d .github/workflows ]]; then ls .github/workflows; else echo "no .github/workflows"; fi
