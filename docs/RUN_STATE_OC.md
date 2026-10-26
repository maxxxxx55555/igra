# Release work checkpoint

Branch: release/mega-finish, based on public release/v10.1.0 (a4b1943).
User authorized complete game fixes and delivery through a self-contained script.
The script must create a NEW remote branch; main must remain unchanged.

Completed: run identity/save migration, focus/quit checkpointing, startup audio,
unknown achievement guard, quest refresh, ending audio teardown, responsive
localized terminal screens with ending art, UI above world postprocessing.
New regression scene: 39 checks passed on Godot 4.7.2 headless.

In progress: pinned toolchain, real QA/build pipeline, browser GitHub login,
verified source upload, Windows/Web artifacts and a GitHub draft release.
PowerShell bootstrap tests use only disposable local remotes; no owner push here.
Next: complete engine matrix, refresh canonical frames, export, package and verify.
Device/store acceptance and asset rights require owner review.
