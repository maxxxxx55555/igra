#!/usr/bin/env bash
# resolve_godot.sh — locate a Godot 4 binary across platforms.
#
# Shared helper sourced by autoplay_bot and headless_suite so they both
# resolve the engine the same way. Priority order:
#   1. $GODOT env var, if set and executable.
#   2. `godot4` / `godot` on PATH.
#   3. Project-local cache: tools/.bin/godot4 (headless) / tools/.bin/godot.
#   4. Common install locations on Linux (~/.local/bin, /usr/local/bin, /usr/bin).
#   5. The author's Windows dev-machine path (C:/.../Godot_v4.7-stable_win64_console.exe),
#      retained for Windows dev boxes; harmless on Linux (won't exist).
#   6. Auto-download a Linux Godot 4 headless binary into tools/.bin/
#      if none of the above worked AND network access to GitHub releases
#      is available (gated by a curl probe).
#
# Prints the resolved path on stdout and exits 0; exits 99 with a
# diagnostic message if nothing resolves AND the auto-download fails
# (typically because the sandbox has no outbound HTTPS — in that case
# the caller prints the error and aborts).
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 2

REPO_ROOT="$(pwd)"
CACHE_DIR="$REPO_ROOT/tools/.bin"
mkdir -p "$CACHE_DIR"

# Candidate list; first one that exists and is executable wins.
_candidates=()
if [[ -n "${GODOT:-}" ]]; then
  _candidates+=("$GODOT")
fi
for _cmd in godot4 godot godot-server godot4-headless godot-headless; do
  if command -v "$_cmd" >/dev/null 2>&1; then
    _candidates+=("$(command -v "$_cmd")")
  fi
done
_candidates+=(
  "$CACHE_DIR/godot4"
  "$CACHE_DIR/godot"
  "$HOME/.local/bin/godot4"
  "$HOME/.local/bin/godot"
  "/usr/local/bin/godot4"
  "/usr/local/bin/godot"
  "/usr/bin/godot4"
  "/usr/bin/godot"
  # Author's Windows dev box path — harmless on Linux (doesn't exist).
  "C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe"
)

for _c in "${_candidates[@]}"; do
  if [[ -n "$_c" ]] && [[ -x "$_c" ]] && [[ -f "$_c" ]]; then
    echo "$_c"
    exit 0
  fi
done

# Nothing found locally. Try to download a Linux Godot 4 headless binary.
# Headless is ~30-60 MiB, much smaller than the full editor, and is all
# these runners need (--headless mode).
#
# We probe GitHub first (preferred: canonical releases); fall back to
# TuxFamily. If neither works (sandbox-restricted egress, airplane, etc.)
# we give up with a clear message — we never silently hang.
_download() {
  local url="$1" out="$2"
  curl -fL --connect-timeout 10 --max-time 300 --retry 3 --retry-delay 2 \
    -o "$out" "$url" 2>/dev/null
}

_probe() {
  curl -fsSI --connect-timeout 5 --max-time 10 "$1" >/dev/null 2>&1
}

echo "# no Godot found locally; attempting download..." >&2
mkdir -p "$CACHE_DIR"
# Godot 4's standard binary supports --headless; no separate headless archive exists.
_ver=4.7.2
_url="https://github.com/godotengine/godot-builds/releases/download/${_ver}-stable/Godot_v${_ver}-stable_linux.x86_64.zip"
_zip="$CACHE_DIR/godot-${_ver}.zip"
_bin="$CACHE_DIR/Godot_v${_ver}-stable_linux.x86_64"
if _probe "$_url" && _download "$_url" "$_zip" && command -v unzip >/dev/null 2>&1 \
  && unzip -o "$_zip" -d "$CACHE_DIR" >/dev/null 2>&1 && [[ -f "$_bin" ]]; then
  chmod +x "$_bin"
  ln -sf "$(basename "$_bin")" "$CACHE_DIR/godot4" 2>/dev/null || cp "$_bin" "$CACHE_DIR/godot4"
  chmod +x "$CACHE_DIR/godot4"
  rm -f "$_zip"
  echo "$CACHE_DIR/godot4"
  exit 0
fi

# Give up.
cat >&2 <<EOF
ERROR: Godot 4 engine binary not found, and auto-download failed.

Install Godot 4.7.2 and do one of:
  - export GODOT=/absolute/path/to/godot
  - put \`godot4\` or \`godot\` on your PATH
  - drop a Linux Godot binary at tools/.bin/godot4 (chmod +x)

The runner searched (in order): \$GODOT, PATH (godot4/godot/godot-server),
tools/.bin/, ~/.local/bin/, /usr/local/bin/, /usr/bin/, the author's
Windows path, and an auto-download from GitHub releases.

In restricted sandbox environments where outbound HTTPS to github.com /
downloads.tuxfamily.org is blocked you will need to pre-seed
tools/.bin/godot4 manually.
EOF
exit 99
