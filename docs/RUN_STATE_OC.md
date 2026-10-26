# Release work checkpoint

Branch: release/mega-finish, public baseline release/v10.1.0 (a4b1943).
User authorized whole-game fixes and a self-contained authenticated uploader.
Remote main is unchanged; no owner GitHub writes were made from this environment.

Done: run identity/save migration, focus/quit checkpointing, startup audio,
unknown-achievement guard, quest refresh, ending audio teardown, responsive
localized terminal screens with art, UI above world effects, quiet rejection of
corrupt signed side files and QA snapshots, unused drag preview cleanup.
39 regression checks; 611 closeout checks; full engine matrix passed in development.
8 canonical frames and 11 ending/small-locale frames captured on Mesa llvmpipe.
Windows and Web export successfully; final end-to-end pipeline verification next.

Mega script: embedded SHA256-checked Git bundle, GitHub browser login, repository
permission check, atomic creation of a NEW branch, remote commit verification,
pinned private toolchain, isolated QA profiles, bot/timing gates, exports,
SHA256/report/logs and draft release assets. Android uses the owner's signing key.
PowerShell tested against disposable Git remotes; no main/existing-ref overwrite.
Manual native device/audio/performance, signing and store/rights review are pending.
