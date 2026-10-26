# Last Streetlight 1.0.1 release candidate

The self-contained Igra-MegaRelease.ps1 carries the actual source fixes as a
verified Git bundle. Public baseline: a4b1943 (release/v10.1.0); validated source:
10627bb3316785e934010bb963db76bf39ae2642. Delivery commits after this revision add evidence
and this note only; the game and build driver remain the validated versions.

Run identity (time, kills, Hardcore) survives main/slot saves and legacy loads.
Focus loss, suspension, menu return and close checkpoint the run with the saved
autosave preference. New runs reset counters; invalid achievement IDs grant
nothing; corrupt signed side files and QA snapshots fail quietly and safely.
The quest HUD refreshes on return to play. UI feedback waits for first input,
ending music stops on menu, and world postprocessing draws below interface
canvases. Ending/death screens use the five existing illustrations, wrap and
scroll at small sizes, keep keyboard focus, refresh translations and retain
Hardcore death statistics after save deletion. Programmatic drag-data queries
free their unused preview instead of producing a viewport error.

## Completed validation

- All 41 pipeline stages passed in one run on official Godot 4.7.2 Linux.
- Static battery: 69 checks; lifecycle/ending regression: 39 checks.
- Closeout: 611 checks, zero failures; GOLDMASTER and touch checks passed.
- Three input-driven bot seeds won; death-counter checks passed. Nudge rescues
  remain visible in their logs, so these wins do not certify perfect navigation.
- 30/60/120 FPS comparison: 15 keys, zero failures.
- Windows Desktop and Web release exports passed; archives contain BUILD_INFO
  and exclude intermediate Windows templates.
- 15 release-tool tests passed, including actual PowerShell with disposable Git
  remotes, browser-auth routing, missing public prerequisite, inherited Git
  paths, corrupted bundle, read-only account, protected/existing/racing refs,
  remote verification failure and preservation of a long output tail.
- A 12.8 MB real source payload parsed and uploaded through the actual generated
  PowerShell to a disposable local remote; its main stayed at the public base.
  This was a transport fixture, not a push to the owner's GitHub account.
- Eight fresh canonical frames and eleven ending/locale frames were captured
  with Mesa llvmpipe. The native embedded Linux release booted for 600 frames
  with no script/resource errors. Windows executables were cross-exported here.

The final full run's original JSON report and logs are in
[full-run](artifacts/release-1.0.1/full-run/). Logs have an additional .out suffix
for repository storage; evidence-map.json maps their original names and hashes.
Known Godot shutdown resource-retention/dummy-renderer messages are retained
and counted; script/resource errors and missing completion markers fail. The
proof wrapper now writes header, command output and trailer through one open
descriptor: reopening an append handle on this synchronized filesystem had
overwritten late output, including valid completion markers.

## Generated artifacts of the validated run

| Artifact | Bytes | SHA256 |
|---|---:|---|
| LastStreetlight-1.0.1-windows.zip | 79889826 | `20d4e05c90802bacee87e51eb85bb93f32dc5d05211c1e8cf235cb6399a6397d` |
| LastStreetlight-1.0.1-web.zip | 52308553 | `276e815ce4e970e705b3b707afe8b5f3d04e8922e22cebdbc5044cc1f9461d93` |

The binaries are build outputs, not source commits. The mega script rebuilds
and uploads them with full logs, checksums and report as GitHub draft-release
assets tied to its exact source commit. It asks for a repository and uses
GitHub CLI's browser login, creates only a new branch, atomically refuses an
existing or racing branch, and verifies its remote hash before SOURCE_SAVED.
Main is preserved. Source is saved before lengthy tool installation and builds.

## Remaining owner checks

State: BUILDS_CREATED_MANUAL_REVIEW_PENDING. Native Windows controls, real
phone/touch/performance/audio, art/music rights and store acceptance remain
pending. Optional Android needs JDK 17, Android SDK licenses and the owner's
existing keystore/alias/password; its signed AAB was not built on this host.
The script creates a draft rather than certifying an untested store release.
See [the launch instructions](../tools/release/README.md).
