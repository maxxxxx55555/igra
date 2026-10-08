#!/usr/bin/env bash
# Runs a command in a fresh local clone of HEAD, the way the owner's tree looks after a pull: every file carries the checkout time as its
# modification time, so a gate that passes only in the tree that made the evidence (af3_frame_check F5 did) fails here.
# usage: tools/qa_sim/fresh_clone_check.sh <command> [args...]      e.g. python tools/qa_sim/af3_frame_check.py
# The clone holds the history and, by default, tools/ and docs/stills/; FRESH_PATHS="dir dir" widens or narrows that (cone sparse checkout).
set -euo pipefail
cd "$(dirname "$0")/../.." || exit 2
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git clone --quiet --local --no-checkout . "$tmp/clone"
# word splitting of FRESH_PATHS is the point: it is a list of directories
# shellcheck disable=SC2086
git -C "$tmp/clone" sparse-checkout set --cone ${FRESH_PATHS:-tools docs/stills}
git -C "$tmp/clone" checkout --quiet "$(git rev-parse HEAD)"
echo "fresh clone of $(git rev-parse --short HEAD): $(git -C "$tmp/clone" ls-files | wc -l) tracked files, checkout time $(date -u +%Y%m%dT%H%M%SZ)"
cd "$tmp/clone" && "$@"
