# Release candidate audit — 2026-11-02

This pass continues the version-16 work from `pass/swarm-final` and integrates it with the current-main release workflow. Runtime revision `756a4f2` is the source of the new eight store captures. This is a tested candidate, not a claim of completed photographic reference fidelity or store acceptance.

## Delivered

- `tools/release/Finish-IgraRelease.ps1`: standalone PowerShell entrypoint fetching current main, pinned restart, clean-checkout guards, verified toolchain downloads, complete checks, Windows/Web exports, artifact checksums, optional signed Android and optional GitHub draft. Repeating a failed run preserves its logs and retries verification; a completed result is reused only after checksum verification.
- Preserved the prior version-16 export, six-language story, phone preset, safe-area and recessed-facade changes. Removed a duplicate proposed lamp-cone layer during integration.
- Added district-specific entrances, shutters, canopies, roof details and open balcony guards across all eleven districts. Shared mesh batches preserve Low-tier controls. Calmer pavement fissures replace the prominent closed-polygon effect.
- Fixed victory music continuing over the menu/new run, deferred layout on detached menus, and notch margins disappearing when touch buttons resize or change handedness.
- Consumed and released district/music threaded preloads. Removed unused sky dependencies from parameter-only environment presets; the real scene panorama remains unchanged. Both defects had independent failing reproductions before their fixes.
- Audio audit now rejects decoder failures and covers previously omitted folders. Reduced excessive peaks in two thunder effects without changing their duration.
- Save export/import regressions use an explicit disposable destination. The ordinary UI export still resolves to Downloads; the real exported save is not overwritten by tests.

## Evidence

The native Godot 4.7.2 suite passed all 28 gates, including 629 closeout checks. The save-transfer and full-game gates passed after moving scratch transfers into the disposable profile. The audio/menu/notch/threaded-loader regressions failed before their respective fixes and passed afterward.

All 215 audio assets decode and meet the peak gate; 36 declared loop seams pass. The real windowed audio gate passes its Music/SFX/Ambient routing and adaptive-layer checks. This measures playback and levels; it is not a listening opinion or a new rights certification.

Fresh real-GPU captures complete without script errors or the two former texture leaks. Screenshot provenance passes AF3. An initial desktop performance run exceeded the final-district budget (38.89 ms p95); a controlled quiet rerun measured 19.88/26.35 ms p95, 120 draw calls in each sampled district and 219.9 MiB video memory. Both runs are retained: desktop load sensitivity and phone performance remain acceptance concerns.

Changed-file lint, 809 documentation citations, three export-reference presets, integrity manifests and branch reconciliation pass. GitHub Windows jobs validate real clone/update/resume/artifact behavior in Windows PowerShell 5.1 and PowerShell 7. The complete shell release pipeline is not claimed as locally executed: this sandbox blocks Git Bash startup, so native engine checks and GitHub shell checks supply separate evidence.

All three automated playthrough seeds reached WIN and their death/revive counters agree. All 15 timing comparisons pass across 30, 60 and 120 FPS. The standalone native runner initially mis-escaped its completion-marker boundary; the unchanged engine logs were then validated against the production marker and compared by the repository's timing tool.

Windows and Web release exports were created with Godot 4.7.2 from revision `f03dd94` (same runtime as `756a4f2`). The packaged Windows executable also passes a cold-boot smoke check outside the editor. The export copy required the normal clean second import after its initial cold font/resource scan. Browser play and a newly signed Android bundle are not claimed by this pass.

## Running the release workflow

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Finish-IgraRelease.ps1
```

Use `-Update` to select newer main on a later run. Use `-CheckGame` for verification only. The release-tool README documents existing signing credentials and SDK/JDK requirements for `-Android`; this pass does not create a new signing identity or publish to a store.

## Remaining acceptance

The world still uses stylized procedural architecture and does not fully reproduce the reference artwork. Physical-phone touch/safe-area/performance, subjective music review, asset-rights confirmation and store submission remain pending. Existing broader visual and product issues remain recorded in `docs/KNOWN_ISSUES.md`; passing automation does not close them.
