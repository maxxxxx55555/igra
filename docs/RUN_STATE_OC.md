# Release work complete

Branch: release/mega-finish; public baseline a4b1943.
Validated source: 10627bb3316785e934010bb963db76bf39ae2642.
Remote owner main is unchanged; writes here used only disposable local remotes.

Done: run identity/save migration, lifecycle checkpointing, startup audio gate,
unknown-achievement rejection, quest refresh, ending audio cleanup, responsive
localized ending/death screens with art and retained Hardcore statistics,
UI above world effects, quiet malformed signed/QA file rejection, drag cleanup.

One full pipeline: 41/41 stages; static 69; closeout 611; new regression 39;
GOLDMASTER/touch pass; bots 3/3 WIN with correct counters; timing 15/15 keys.
Windows/Web release archives, SHA256 report and complete logs generated.
15 release-tool tests pass; full 12.8 MB PowerShell payload replayed to a local
remote with main preserved. Native embedded Linux boot smoke: 600 frames.
8 canonical and 11 ending/locale native Mesa frames captured.

Delivery: one self-contained Igra-MegaRelease.ps1 with verified source bundle,
GitHub browser login, repository permission checks, atomic NEW-branch creation,
remote SHA verification, pinned toolchain, isolated QA, builds and draft assets.
Android optional with the owner's existing key. Source saved before long builds.
Manual device/audio/performance, rights, Android signing and stores are pending.
Details and hashes: docs/RELEASE_1_0_1.md and docs/artifacts/release-1.0.1/full-run/.
