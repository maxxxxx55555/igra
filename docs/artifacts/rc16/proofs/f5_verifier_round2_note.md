# Note for the F5 verifier, round 2

Read this together with `docs/artifacts/rc16/proofs/f5_verifier_brief.md`; where the two differ, this note wins.

Round 1 ran at HEAD `32b8199` and returned `PASS=27 FAIL=17 UNVERIFIED=10` (`docs/artifacts/rc16/proofs/f5_verifier_round1.md`, verbatim). The orchestrator fixed each of the 17 once; CORRECTION_LOG 129 to 132 describe the fixes. Do not trust those descriptions or the earlier verdict: run the whole brief again at the HEAD you start at, and re-check each of the 17 at its original place with the original command.

Changes since round 1 (documents and proof logs only; `git diff --stat 32b8199 HEAD -- scripts scenes assets data addons android localization project.godot export_presets.cfg default_bus_layout.tres tools scripts/tools scenes/tools` must print nothing):
- CORRECTION_LOG now runs 101 to 132 (use 132 where the brief says 128 or 117); the documents that said 101 to 116 or 101 to 128 say 101 to 132.
- New proofs: `f5_arena_strategies.out`, `f5_rpc_addons.out`, `f5_af5_all.out` (it exits 1 on purpose: it is `tools/af5_check.py --all` over the older documents, 109 findings) and the round 1 report.
- The rc16 section of PROOFS.md, closures.json and the rc16 section of ORDER_PASS_REPORT were regenerated again; the claims and quotes of S0-SKILL-SCAN, S4-MN4, S4-U8 and S8-AUDIO changed. The static proofs (final_static_f4, i18n_final, af5_final, lint_final, af3_final, af3_fresh_final, accept_count) were re-run at `e8b5ac2`, after the last fix of the documents.
- The skill log has the same 19 rows, 13 of them ok, as in round 1.
- The rules of the brief hold: read-only, no Godot, no `tools/check.sh`, nothing written into the repository (scratch only in the directory you are given), the verdict is your final message in the brief's format, at most 160 tool calls.
- The 10 UNVERIFIED items of round 1 (D2, D4, E1 twice, A2, A3, T6, K1, K2, H1) need the engine, a phone, the network or the session transcript; list one again only if you still cannot decide it, in one line.
