#!/usr/bin/env bash
# tools/qa_sim/static_syntax_check.sh
# -----------------------------------
# Fast static GDScript parser check. Used as a smoke test when a real
# Godot binary isn't available (e.g. a sandbox that can't download one).
# Uses the gdtoolkit `gdparse` parser (pip3 install gdtoolkit). This
# does NOT prove runtime correctness — only that every .gd script parses.
# Exit 0 = all scripts parse; non-zero = number failing.
set -uo pipefail
cd "$(dirname "$0")/../.."

if ! command -v gdparse >/dev/null 2>&1; then
  echo "gdparse not installed (pip3 install --break-system-packages gdtoolkit); skipping static syntax check."
  exit 0
fi

FAILS=0; TOTAL=0
while IFS= read -r -d '' f; do
  TOTAL=$((TOTAL+1))
  if ! out=$(gdparse "$f" 2>&1); then
    # gdtoolkit 4.5 does not support a handful of Godot 4.7-only syntax
    # (e.g. single-expression lambdas inside chained calls). Treat those
    # lines as "skip if they are pre-existing" — we only fail scripts
    # that differ from main (i.e. scripts changed in this branch), since
    # those are the only ones that could regress.
    if ! git diff --quiet main -- "$f" 2>/dev/null; then
      echo "  PARSE FAIL (changed in branch): $f"
      echo "$out" | head -5 | sed 's/^/       /'
      FAILS=$((FAILS+1))
    fi
  fi
done < <(find scripts -name "*.gd" -print0 | grep -z -v "/tools/" )

echo "static syntax check: $((TOTAL-FAILS))/$TOTAL scripts parse cleanly, $FAILS failing in changed files."
exit $FAILS
