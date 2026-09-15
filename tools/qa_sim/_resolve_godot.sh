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
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

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
for _ver in 4.3 4.2.2 4.2.1; do
  for _url in \
    "https://github.com/godotengine/godot/releases/download/${_ver}-stable/Godot_v${_ver}-stable_linux_headless.64.zip" \
    "https://downloads.tuxfamily.org/godotengine/${_ver}/Godot_v${_ver}-stable_linux_headless.64.zip"; do
    _probe "$_url" || continue
    _zip="$CACHE_DIR/godot-headless-${_ver}.zip"
    if _download "$_url" "$_zip"; then
      if command -v unzip >/dev/null 2>&1; then
        unzip -o "$_zip" -d "$CACHE_DIR" >/dev/null 2>&1
        # Expected: Godot_vX.Y-stable_linux_headless.64 inside zip
        for _bin in "$CACHE_DIR"/Godot_v*_linux_headless.64 "$CACHE_DIR"/Godot_v*_linux.x86_64; do
          if [[ -x "$_bin" ]] || [[ -f "$_bin" ]]; then
            chmod +x "$_bin" 2>/dev/null || true
            ln -sf "$(basename "$_bin")" "$CACHE_DIR/godot4" 2>/dev/null || cp "$_bin" "$CACHE_DIR/godot4"
            chmod +x "$CACHE_DIR/godot4"
            rm -f "$_zip"
            echo "$CACHE_DIR/godot4"
            exit 0
          fi
        done
      fi
    fi
  done
done

# Give up.
cat >&2 <<EOF
ERROR: Godot 4 engine binary not found, and auto-download failed.

Install Godot 4 (any 4.2+) and do one of:
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
