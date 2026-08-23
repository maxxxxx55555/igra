Read docs/HANDOFF.md and docs/SESSION_REPORT.md for full context on the
last session (19 tasks landed, all gates green, pushed to origin/main).

Run `bash tools/check.sh` first to confirm the baseline is still clean.

Then pick up one of the open threads from docs/HANDOFF.md's "Open threads"
section — none are blockers, they're deliberate scope cuts:
1. Oversized ambience loops (assets/audio/ambience/*.wav, uncommitted,
   need OGG transcode + a decision on replace-vs-keep-existing).
2. Parallel SFX naming scheme vs. the wired mon_*/step_* convention.
3. District tilesets / UI chrome PNGs — available but unused (polish, not
   a gap).
4. Orphaned touch_controls.gd duplicate — never instantiated, needs a
   deliberate look before it's touched again.
5. Dormant WeaponManager/WeaponBase ranged-weapon system — design
   decision needed on whether this game wants ranged weapons at all.

Or take a new task from the owner directly. Either way: gates after every
change, commit small, push every 2-3 commits, same as always.
