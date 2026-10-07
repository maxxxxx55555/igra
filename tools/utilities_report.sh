#!/usr/bin/env bash
# rc16 O4: every utility the release directive names (gdlint, shellcheck, mypy, pngquant, oggenc, ruff and friends, CI), run or listed
# as absent, with the raw output. tools/qa_sim/proof_run keeps this output as the evidence of docs/UTILITIES_REPORT.md:
#   tools/qa_sim/proof_run utilities -- bash tools/utilities_report.sh
cd "$(dirname "$0")/.." || exit 2
PY="${PY:-python}"
BASE="${BASE:-e4bb4df}"

have() { command -v "$1" >/dev/null 2>&1 || "$PY" -m "$1" --version >/dev/null 2>&1; }
version() { { command -v "$1" >/dev/null 2>&1 && "$1" --version 2>&1 || "$PY" -m "$1" --version 2>&1; } | head -1; }

echo "== availability (the downloads a missing tool needs are not approved in this environment)"
for t in gdlint gdformat shellcheck mypy pngquant oggenc ruff flake8 pyflakes black ffmpeg; do
	if have "$t"; then echo "$t: $(version "$t")"; else echo "$t: ABSENT"; fi
done

echo; echo "== ruff E9,F (syntax errors and pyflakes correctness) on tools/ and scripts/"
"$PY" -m ruff check tools scripts --select E9,F --output-format concise; echo "exit=$?"

echo; echo "== ruff default rule set, findings per rule (style and modernisation: reported, not a gate)"
"$PY" -m ruff check tools scripts --statistics 2>&1 | tail -25; echo "exit=$?"

echo; echo "== flake8 correctness subset (E9, F63, F7, F82)"
"$PY" -m flake8 tools scripts --count --select=E9,F63,F7,F82 --statistics; echo "exit=$?"

echo; echo "== python compile of every .py (py_compile)"
n=0; bad=0
while IFS= read -r f; do n=$((n+1)); "$PY" -m py_compile "$f" 2>/dev/null || { echo "FAIL $f"; bad=$((bad+1)); }; done < <(git ls-files '*.py')
echo "compiled=$n failed=$bad"

echo; echo "== bash -n (shellcheck is absent: syntax only) on every shell script, hook and extensionless wrapper"
n=0; bad=0
while IFS= read -r f; do
	[[ -f "$f" ]] || continue
	case "$f" in *.sh|tools/hooks/*|tools/qa_sim/*) ;; *) continue ;; esac
	[[ "$f" == *.* && "$f" != *.sh ]] && continue
	n=$((n+1)); bash -n "$f" 2>/dev/null || { echo "FAIL $f"; bad=$((bad+1)); }
done < <(git ls-files)
echo "checked=$n failed=$bad"

echo; echo "== GDScript: gdlint is absent; the engine compile gate (COMPILE_GATE bad=0 in tools/check.sh) is the parse proof; static gates:"
bash tools/check.sh --static 2>&1 | tail -3

echo; echo "== assets changed since $BASE (pngquant and oggenc only matter for shipped assets; docs/ frames are evidence, not assets)"
git diff --name-only "$BASE" HEAD -- '*.png' '*.ogg' '*.wav' '*.jpg' ':!docs' | sed 's/^/changed: /'
echo "changed assets: $(git diff --name-only "$BASE" HEAD -- '*.png' '*.ogg' '*.wav' '*.jpg' ':!docs' | wc -l | tr -d ' ')"

echo; echo "== CI"
if [[ -d .github/workflows ]]; then ls .github/workflows; else echo "no .github/workflows: none created (a workflow is a standing remote configuration nobody asked for); tools/check.sh --all is the one command, tools/hooks/pre-commit the opt-in hook"; fi
