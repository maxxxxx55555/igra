#!/usr/bin/env bash
# rc16 launch 6: in launch 5 the windowed audio truth gate read the Music bus at -12.3 dB with default_bus_layout.tres at b69ed90 and at
# +0.7 and +0.9 dB with the layout at HEAD (reverb effects on the Footsteps, Combat and Environment buses). Does the layout, or one of its
# three reverbs, move the Music peak? Each variant edits the HEAD layout text and runs the gate once; the last variant is HEAD unchanged;
# the layout is put back to HEAD at the end.
#   tools/qa_sim/proof_run --launch s4_truth_bisect2 -- bash docs/artifacts/rc16/audio_truth_bisect2.sh
cd "$(dirname "$0")/../../.." || exit 2
LAYOUT=default_bus_layout.tres

variant() { # name, sed expression applied to the layout
	git restore --worktree -- $LAYOUT
	[[ -n "$2" ]] && sed -i -E "$2" $LAYOUT
	bash tools/qa_sim/guarded_windowed res://scenes/tools/audio_truth_gate_scene.tscn 300
	local rc=$?
	cp .qa_logs/audio_truth_gate_scene.log ".qa_logs/audio_truth_$1.log"
	echo "VARIANT $1 rc=$rc $(grep -a 'bus peak=' ".qa_logs/audio_truth_$1.log" | sed -E 's/\[audio-truth\] //; s/ \(ceiling[^)]*\)//' | tr '\n' ';')"
}
variant all_reverbs_disabled 's#^(bus/[678]/effect/0/enabled = )true#\1false#'
variant environment_only 's#^(bus/[67]/effect/0/enabled = )true#\1false#'
variant footsteps_and_combat_only 's#^(bus/8/effect/0/enabled = )true#\1false#'
variant head_layout_repeat ''
git restore --worktree -- $LAYOUT
git status --short -- $LAYOUT
