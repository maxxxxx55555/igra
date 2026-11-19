#!/usr/bin/env bash
# Run from the project root. --import waits for the editor's import queue.
set -eu
engine="${1:-godot}"
ready() {
  [[ -s data/i18n/translations.en.translation && -s data/i18n/translations.ru.translation &&
     -s .godot/global_script_class_cache.cfg && -d .godot/imported ]]
}
if [[ "${TLS_SKIP_REIMPORT:-0}" == 1 ]] && ready; then exit 0; fi
args=()
# Desktop validation keeps GPU texture compression. CI has no display.
if [[ "${CI:-}" == true || ( "$(uname)" == Linux && -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ) ]]; then args+=(--headless); fi
mkdir -p .qa_logs
if ! timeout 900 "$engine" "${args[@]}" --path . --import > .qa_logs/import.log 2>&1 || ! ready; then
  tail -40 .qa_logs/import.log >&2
  exit 1
fi
