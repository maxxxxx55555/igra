#!/usr/bin/env bash
# MEGA_PROMPT v7 phase 3: a track that the script audit marks RE-EDIT or REPLACE (docs/AUDIO_COVERAGE.md) is brought to the mood matrix without new material.
# A tempo more than 8 % off its row is stretched first (atempo keeps the pitch); the loop grows to 60 s or more by playing the track three times in a row at the tempo
# and 5 % either side of it, 1 s crossfades between the passes (the events fall in new places), then music_post.py cuts the steadiest stretch, closes the seam
# and levels it (-18 LUFS, true peak -1.5 dBFS). The original is kept in .qa_logs/music_orig/ and is always the source, so a rerun does not stretch a stretch.
# usage: tools/qa_sim/music_extend.sh <name> <tempo factor> <loop seconds>   e.g. music_combat 0.814 75 (reads and writes assets/audio/music/<name>.ogg)
set -euo pipefail
cd "$(dirname "$0")/../.."
name="$1"
factor="$2"
loop="$3"
dst="assets/audio/music/${name}.ogg"
orig=".qa_logs/music_orig/${name}.ogg"
take=".qa_logs/music_take/${name}.wav"
mkdir -p .qa_logs/music_orig .qa_logs/music_take
[[ -f "$orig" ]] || cp "$dst" "$orig"
slow=$(python -c "print($factor * 0.95)")
fast=$(python -c "print($factor * 1.05)")
ffmpeg -v error -y -i "$orig" -filter_complex "[0:a]asplit=3[x][y][z];[x]atempo=${factor}[p];[y]atempo=${slow}[q];[z]atempo=${fast}[r];[p][q]acrossfade=d=1[pq];[pq][r]acrossfade=d=1[o]" -map "[o]" -ac 1 -ar 44100 "$take"
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$take")
loop=$(python -c "print(min($loop, int($dur) - 13))")  # music_post wants the loop, a 2 s crossfade and 4 s of margin either side inside the take
python tools/qa_sim/music_post.py "$take" "$dst" --loop "$loop"
