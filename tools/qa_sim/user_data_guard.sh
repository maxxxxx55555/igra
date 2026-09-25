#!/usr/bin/env bash
# User-data guard for QA runs. Engine gates, the GOLD MASTER suite and the
# autoplay bot all run the real game against the owner's user:// profile
# (New Game -> reset_all, save_all/autosave, forged upgrade cfgs), so each
# run could overwrite real progress. Snapshot the game's own files (top-level
# files + saves/) before, restore them byte-identical after. Engine caches
# (logs/, shader_cache/, vulkan/, objectdb_snapshots/) are left alone.
#
#   source tools/qa_sim/user_data_guard.sh
#   udg_snapshot; trap udg_restore EXIT; ...godot runs...; udg_restore
#   bash tools/qa_sim/user_data_guard.sh --demo    # self-check on a temp dir
#
# udg_restore removes only files that did not exist at snapshot time (made by
# the QA run); it never deletes a file the owner had. On a failed restore the
# snapshot is kept and its path printed.

udg_dir() {
	local name
	name=$(sed -n 's/^config\/name="\(.*\)".*/\1/p' project.godot | tr -d '\r' | head -1)
	if [[ -n "${APPDATA:-}" ]]; then echo "$APPDATA/Godot/app_userdata/$name"
	elif [[ "$(uname)" == Darwin ]]; then echo "$HOME/Library/Application Support/Godot/app_userdata/$name"
	else echo "${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/$name"; fi
}

_udg_list() { # dir -> sorted relative paths of the game's own files
	( cd "$1" 2>/dev/null || exit 0; find . -maxdepth 1 -type f; find ./saves -type f 2>/dev/null ) | sed 's#^\./##' | sort
}

udg_snapshot() { # [dir]
	UDG_DIR="${1:-$(udg_dir)}"
	UDG_ACTIVE=0
	UDG_SNAP=$(mktemp -d "${TMPDIR:-/tmp}/tls_udg.XXXXXX" 2>/dev/null) && [[ -n "$UDG_SNAP" ]] || {
		echo "  user-data guard: FAIL cannot create a snapshot dir - do not run the game against this profile"
		return 1
	}
	mkdir -p "$UDG_SNAP/files"
	_udg_list "$UDG_DIR" > "$UDG_SNAP/list"
	local f
	while IFS= read -r f; do
		mkdir -p "$UDG_SNAP/files/$(dirname "$f")"
		cp -p "$UDG_DIR/$f" "$UDG_SNAP/files/$f" && cmp -s "$UDG_DIR/$f" "$UDG_SNAP/files/$f" || {
			echo "  user-data guard: FAIL cannot snapshot $f - do not run the game against this profile"
			return 1
		}
	done < "$UDG_SNAP/list"
	UDG_ACTIVE=1
	echo "  user-data guard: $(wc -l < "$UDG_SNAP/list") file(s) snapshotted from $UDG_DIR"
}

udg_restore() {
	[[ "${UDG_ACTIVE:-0}" == 1 ]] || return 0
	UDG_ACTIVE=0
	local f bad=0
	# A lost/unreadable snapshot must never turn into "delete everything the
	# snapshot doesn't list" - refuse and leave the profile as it is.
	if [[ ! -r "$UDG_SNAP/list" || ! -d "$UDG_SNAP/files" ]] \
		|| [[ $(wc -l < "$UDG_SNAP/list") -ne $(find "$UDG_SNAP/files" -type f | wc -l) ]]; then
		echo "  user-data guard: FAIL snapshot $UDG_SNAP missing or incomplete - nothing restored or removed"
		return 1
	fi
	while IFS= read -r f; do
		grep -qxF -- "$f" "$UDG_SNAP/list" || rm -f -- "$UDG_DIR/$f"
	done < <(_udg_list "$UDG_DIR")
	while IFS= read -r f; do
		mkdir -p "$UDG_DIR/$(dirname "$f")"
		cp -p "$UDG_SNAP/files/$f" "$UDG_DIR/$f"
		cmp -s "$UDG_SNAP/files/$f" "$UDG_DIR/$f" || { echo "  user-data guard: FAIL $f differs after restore"; bad=1; }
	done < "$UDG_SNAP/list"
	[[ "$(_udg_list "$UDG_DIR")" == "$(cat "$UDG_SNAP/list")" ]] || { echo "  user-data guard: FAIL file set differs after restore"; bad=1; }
	if [[ $bad -eq 0 ]]; then
		echo "  user-data guard: $(wc -l < "$UDG_SNAP/list") file(s) restored byte-identical"
		rm -rf -- "$UDG_SNAP"
	else
		echo "  user-data guard: snapshot kept at $UDG_SNAP"
	fi
	return $bad
}

_udg_demo() {
	local d; d=$(mktemp -d "${TMPDIR:-/tmp}/tls_udg_demo.XXXXXX")
	mkdir -p "$d/saves" "$d/logs"
	printf 'owner-progress' > "$d/tls_savegame.save"
	printf 'slot' > "$d/saves/slot1.save"
	printf 'untouched' > "$d/settings.cfg"
	udg_snapshot "$d" > /dev/null
	printf 'qa-overwrote' > "$d/tls_savegame.save"
	rm "$d/saves/slot1.save"
	printf 'qa-new' > "$d/tls_savegame.save.bak2"
	printf 'engine log' > "$d/logs/godot.log"
	udg_restore > /dev/null || { echo "demo FAIL: restore reported a mismatch"; return 1; }
	[[ "$(cat "$d/tls_savegame.save")" == owner-progress ]] || { echo "demo FAIL: save not restored"; return 1; }
	[[ "$(cat "$d/saves/slot1.save")" == slot ]] || { echo "demo FAIL: deleted slot not restored"; return 1; }
	[[ ! -e "$d/tls_savegame.save.bak2" ]] || { echo "demo FAIL: QA-created file left behind"; return 1; }
	[[ -e "$d/logs/godot.log" ]] || { echo "demo FAIL: engine log dir touched"; return 1; }
	# Snapshot that cannot be taken: must report failure and arm nothing.
	if TMPDIR="$d/no/such/dir" udg_snapshot "$d" > /dev/null; then echo "demo FAIL: snapshot succeeded without a dir"; return 1; fi
	[[ "${UDG_ACTIVE:-0}" == 0 ]] || { echo "demo FAIL: failed snapshot left restore armed"; return 1; }
	# Lost snapshot: restore must fail and delete nothing.
	udg_snapshot "$d" > /dev/null
	rm -rf -- "$UDG_SNAP"
	if udg_restore > /dev/null; then echo "demo FAIL: restore succeeded without a snapshot"; return 1; fi
	[[ -e "$d/tls_savegame.save" && -e "$d/saves/slot1.save" ]] || { echo "demo FAIL: lost snapshot deleted owner files"; return 1; }
	rm -rf -- "$d"
	echo "demo OK"
}

if [[ "${BASH_SOURCE[0]}" == "$0" && "${1:-}" == "--demo" ]]; then
	_udg_demo
fi
