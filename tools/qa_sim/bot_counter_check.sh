#!/usr/bin/env bash
# The autoplay bot logs "revived after death" for every death it recovers from, so its own death counter must not be lower than that.
# (Until rc16 the counter listened to a signal nothing emits and read 0 while every seed died and was revived in the final fight.)
# usage: tools/qa_sim/bot_counter_check.sh <seed log>       exit 0 consistent, 1 counter below the revive lines, 2 no counter line
log="${1:?usage: tools/qa_sim/bot_counter_check.sh <seed log>}"
revives=$(grep -a -c "revived after death" "$log")
deaths=$(sed -nE 's/^\[bot s[0-9]+\]   deaths +: +([0-9]+).*/\1/p' "$log" | tail -1)
[[ -n "$deaths" ]] || { echo "no death counter line in $log"; exit 2; }
echo "deaths counted ${deaths}, revive lines ${revives}"
[[ $deaths -ge $revives ]]
