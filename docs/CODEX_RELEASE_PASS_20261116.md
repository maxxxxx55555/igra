# Codex release pass — 2026-11-16

Status: NOT READY. Scoped runtime fixes are verified; full release acceptance is not.

Latest result (runtime 110af564): the serial integrated full battery completed with 103 passes and two failures, restoring all 12 player-profile files byte-identically. One failure was the static checker missing inherited Node methods; its exact static block passes after recognizing `find_children` and `set_process`. The other was a real detached-HUD notification error during return-to-menu. The lifecycle guard and deterministic detached-signal regression fix it; codex_boot_fixed repeats the complete boot/play/save/menu/load flow with fails=0 and no script errors. This is a completed battery followed by focused corrections, not a claim that the original full log was green. Headless HUD teardown still reports audio playback/resource warnings; no production memory-leak fix is claimed.

Final evidence: codex_final_frames captured 18 frames from 110af564; eight current evidence frames replace the obsolete set, AF3 passes 8/8. Capture staging now follows the real pause-to-shop route, dismisses the tutorial and lets notices expire. Reviewed shop and boss frames no longer carry the earlier overlay clutter. The separate 50k primitive target and physical-device/art/listening acceptance remain unresolved.

Windows candidate: `build/windows/codex-110af564/LastStreetlight.exe`, 223257880 bytes, SHA-256 `af4ca1cb0e80ef749a951857a09e6185ec73925bb10e7627cf4b72ed6d72b095`. Release export and a windowed exported-binary smoke test both exit 0; smoke test restores the profile byte-identically. This candidate is unsigned, not published, and does not supersede prior signing records as an approved release.

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

Continuation: integrated origin/main at 6667fd92 into this existing checkout (merge 765831f4), retaining newer controls, localization and viewport guards. Reproduced and fixed three additional defects: control-owned touches leaking into look/swipe gestures, same-species enemies confusing the aimed HUD target, and disabling High Contrast retaining its boosted colors. Regression evidence: codex_touch_red/green, codex_target_red/final, codex_contrast_red/final. Windowed codex_touch_dispatch3 passes the actual viewport delivery path with local coordinates; it is not physical-device certification. Earlier dispatch attempts used window coordinates incorrectly and are not product acceptance evidence. Target fixture reports two ObjectDB warnings at teardown; no gameplay leak conclusion is inferred from that count. The new regressions run in tools/check.sh. Scoped lint passes.
