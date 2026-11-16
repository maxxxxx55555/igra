# Codex release pass — 2026-11-16

Status: NOT READY. Scoped runtime fixes are verified; full release acceptance is not.

Changed: new-run combat music reset; streetlight stage-energy retention; immediate Reduce Flash updates to lights and existing shared/batched materials; weak material references; regression scenes and older lamp fixture setup.

Evidence: `docs/artifacts/rc16/proofs/codex_20261116_audio.out`, `docs/artifacts/rc16/proofs/codex_20261116_lamps.out`. Both terminate with fails=0, EXIT=0 and byte-identical profile restoration. GDScript lint passes. Flow and scene checks pass; authentication citations pass.

Preserved unrelated local changes. No signing identities, store accounts or credentials accessed. No tracked cleanup candidate was proven both unused and unplanned. Historical AUTO-DELETABLE labels conflict with retained-feature decisions and are not sufficient deletion evidence.

Unslop review adapted from Damir Sokolovsky, CC BY 4.0, https://github.com/heydamir/unslop. Existing menu visual direction retained; historical images do not certify this modified tree.

Full battery result is recorded separately after completion. No release tag or store publication.

Full-battery attempts were interrupted and are NOT acceptance evidence: an interrupted MSYS runner left a child running, causing overlap with the rerun. Both were terminated gracefully; each recorded restoration of 12 profile files, with the original runner restored last. No engine processes remained before the separate windowed performance run. The isolated targeted regression results remain valid.
Static findings requiring follow-up: eight store screenshots are stale against current runtime code; branch_absorb_sim reports missing dispositions for two locally known remote branches. No assertion or evidence freshness rule was weakened.

Independent windowed performance gate: EXIT=0, fails=0. D1=107 draw calls, D11=115; p95=27.78/28.53 ms; video memory=224.8 MiB. Raw measurements: `docs/artifacts/rc16/proofs/codex_20261116_perf_measurements.out`. This passes the implemented draw-call/frame-time/memory gate on this PC; D1 primitives=151982 still exceeds the separate documented 50000 target and is not enforced by that gate. No phone result claimed.

Independent windowed audio gate: `codex_20261116_audio_bus` EXIT=0, PASS overall. Music peak -12.3 dB in the sampled context; adaptive calm/tension/combat stem transitions pass. Output was measured through WASAPI; this is technical audio verification, not a subjective listening sign-off.

Current rendered capture run: `codex_20261116_frames` EXIT=0, 18 frames, protected profile restored. Reviewed Russian large-text menu and restored district frame from `.qa_logs/codex_20261116_frames/`. Menu text fits and authored charcoal/brass presentation remains coherent. The street still uses visibly repeated facades and coarse props; this review does not certify the requested final art quality. These are working-tree review frames, not committed-HEAD store acceptance frames.

Remaining release blockers: complete a serial full-battery run; refresh store evidence against the integrated committed tree; reconcile branch dispositions; meet/resolve primitive budget and device acceptance; finish art acceptance and subjective audio review; signing/store steps. No store release or READY claim made.
