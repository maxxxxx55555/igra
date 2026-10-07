#!/usr/bin/env bash
# rc16 S9: the two-grep proof for the four GAP-OWNER rows of docs/TZ_COMPLIANCE.md (V03, G22, G28/D04, N01/I02/T01): the first grep reads what the
# spec says, the second what the repository holds. A row stays owner-only while the second grep shows no code that could close it.
#   tools/qa_sim/proof_run gapowner_twogrep -- bash tools/gapowner_check.sh
cd "$(dirname "$0")/.." || exit 2
show() { sed 's/\r$//' | cut -c1-210; }

echo "== V03 Bebas Neue Bold (asset only)"
echo "-- spec: the heading font"; grep -n "Bebas" docs/GDD.md | head -2 | show
echo "-- state: the font files the repository holds"; for f in assets/fonts/*ebas*; do basename "$f"; done

echo; echo "== G22 save-slot picker (owner decision)"
echo "-- spec: the slots"; grep -n "3 ручных" docs/GDD.md | show
echo "-- state: the slot API exists, MAX_SLOTS"; grep -n "const MAX_SLOTS" scripts/core/save_system.gd | show
echo "-- state: the two slot screens and what opens them (an opener would be a line below that is not in the screen files themselves)"
grep -rn "SaveSlotsUI\|save_slot_entry\|_open_card(\"Saves\")" scripts scenes --include=*.gd --include=*.tscn | grep -v "^scripts/tools/" | show | head -8

echo; echo "== G28/D04 all FULL, then the boss (GDD text)"
echo "-- spec: the amended line"; grep -n "Все 11 районов FULL" docs/GDD.md | show
echo "-- state: the win goes through the finale director"; grep -n "trigger_win" scripts/world/finale_director.gd scripts/world/power_grid.gd | head -4 | show

echo; echo "== N01 / I02 / T01 (owner text and keys)"
echo "-- N01 the New Game+ carryover rule"; grep -n "N01" docs/TZ_DECISIONS.md | head -2 | show
echo "-- I02 the key census: keys per locale in en.json, the GDD line"
python -c "import json;print(len(json.load(open('data/i18n/en.json',encoding='utf-8'))))"
grep -n "ключа на локаль" docs/GDD.md | show
echo "-- T01 the keystore and the bundle (the device test is not a file)"; ls -la build/tls.aab .signing/tls-release.keystore 2>&1 | sed 's/^\(.\{0,10\}\).*  \([0-9]\{3,\} .*\)$/\1 \2/' | head -3
