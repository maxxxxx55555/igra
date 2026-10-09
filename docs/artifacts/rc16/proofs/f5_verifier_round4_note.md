# Note for the F5 verifier, round 4

Read this together with `docs/artifacts/rc16/proofs/f5_verifier_brief.md`; where the two differ, this note wins. It replaces the notes of rounds 2 and 3, which you may skip.

Round 1 (HEAD `32b8199`) returned `PASS=27 FAIL=17 UNVERIFIED=10`, round 2 (`650ec59`) `PASS=29 FAIL=5 UNVERIFIED=12` and round 3 (`556f8dc`) `PASS=30 FAIL=2 UNVERIFIED=11`; the three reports are kept verbatim next to this note (`f5_verifier_round1.md`, `f5_verifier_round2.md`, `f5_verifier_round3.md`). The orchestrator fixed each finding once (CORRECTION_LOG 129 to 133 and 135); CORRECTION_LOG 134 and 135 record why this fourth round is run. Do not trust those descriptions or the earlier verdicts: run the whole brief again at the HEAD you start at, and re-check the 2 findings of round 3 at their original places with the original commands.

Changes since round 3 (documents and proof logs only; `git diff --stat 556f8dc HEAD -- scripts scenes assets data addons android localization project.godot export_presets.cfg default_bus_layout.tres tools scripts/tools scenes/tools` must print nothing):
- CORRECTION_LOG now runs 101 to 135 (use 135 where the brief says 128 or 117); the documents that said 101 to 116, 128, 132 or 134 say 101 to 135.
- New proofs: `f5_af5_drift.out` (each citation of the AF5 scope, the cited lines at the commit of its sentence against HEAD, script included), `f5_gdparse_errors.out` (where the parser stops in the four files of UTILITIES_REPORT, script included) and the round 3 report.
- The rc16 section of PROOFS.md, closures.json and the rc16 section of ORDER_PASS_REPORT were regenerated again; the claims of FINAL-AF5 and S0-ARENA changed. The static proofs (final_static_f4, i18n_final, af5_final, lint_final, af3_final, af3_fresh_final, accept_count) were re-run at `31750a6`, after the last fix of the documents.
- The skill log has the same 19 rows, 13 of them ok, as in the earlier rounds.
- Citations: rounds 2 and 3 found stale citations that `tools/af5_check.py` cannot see (rule C3 tests a citation only when a backticked claim stands right before it). Read the citations without such a claim in the documents changed since `e4bb4df` against the code or the document they cite, and compare the cited lines at the commit of each sentence with HEAD; say how many you read.
- The rules of the brief hold: read-only, no Godot, no `tools/check.sh`, nothing written into the repository (scratch only in the directory you are given), the verdict is your final message in the brief's format, at most 160 tool calls.
- The 11 UNVERIFIED items of round 3 need the engine, a phone, the network or the session transcript; list one again only if you still cannot decide it, in one line.
