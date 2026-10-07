#!/usr/bin/env bash
# rc16 launch 5: which file of the audio changes (A1 to A4, commits e241004..7c49500) lifts the Music bus peak of the windowed audio
# truth gate from -12 dB (b69ed90) to +0.5 dB (HEAD)? One variant per run: the named files go back to their b69ed90 content, the rest stay at HEAD.
# First the rc16 closeout group at HEAD (the AUD3 fade fix). Every file is put back to HEAD at the end.
#   tools/qa_sim/proof_run --launch s4_truth_bisect_7c49500 -- bash docs/artifacts/rc16/audio_truth_bisect.sh
cd "$(dirname "$0")/../../.." || exit 2
ALL="scripts/systems/audio_manager.gd scripts/systems/music_manager.gd scripts/systems/footstep_system.gd default_bus_layout.tres"
BASE=b69ed90

CLOSEOUT_ONLY=rc16 bash tools/qa_sim/closeout_check 300
echo "closeout rc16 rc=$?"

variant() { # name, files put back to $BASE
	git restore --worktree -- $ALL
	[[ -n "$2" ]] && git restore --source=$BASE --worktree -- $2
	bash tools/qa_sim/guarded_windowed res://scenes/tools/audio_truth_gate_scene.tscn 300
	local rc=$?
	cp .qa_logs/audio_truth_gate_scene.log ".qa_logs/audio_truth_$1.log"
	echo "VARIANT $1 rc=$rc $(grep -a 'Music bus peak=' ".qa_logs/audio_truth_$1.log" | head -1)"
}
variant layout_at_b69ed90 default_bus_layout.tres
variant music_manager_at_b69ed90 scripts/systems/music_manager.gd
variant audio_manager_and_footsteps_at_b69ed90 "scripts/systems/audio_manager.gd scripts/systems/footstep_system.gd"
git restore --worktree -- $ALL
git status --short -- $ALL
