# Security threat model

Offline single-player game, no backend, no multiplayer trust boundary except optional LAN
co-op (`remote_player_state` etc. in EventBus — peer-to-peer, no server to arbitrate).

## What already exists — verified, not rebuilt

A signed-save + tamper-probe system already ships. Before writing anything new here it was
checked against a real run, not trusted from a commit message (the exact TRUTH WAVE lesson this
repo's `CLAUDE.md` names):

- **Signing**: [scripts/core/save_system.gd:21-24](scripts/core/save_system.gd:21) — HMAC-SHA256
  over the save body via Godot's `Crypto.hmac_digest`, with an inline comment already stating the
  honest scope (speed bump, not real anti-cheat — see "NOT protectable client-side" below).
- **Backup rotation, corruption/tamper rejection, legacy migration**: `_write_atomic`,
  `_rotate_backups`, `_read_envelope`, `_migrate`, `_verify_progress` in the same file.
- **Test probe**: [scripts/tools/_save_integrity_check.gd](scripts/tools/_save_integrity_check.gd)
  — round-trip, `.bak` recovery, corrupt-file rejection, 3-generation backup rotation, a forged
  progress-signature check, a 50-mutant byte-fuzz pass, and export/import round-trip. Wired into
  `tools/check.sh` as gate `"целостность сейва"` (`run_gate`, [tools/check.sh:214](tools/check.sh:214)).
- **Verified this session**: `godot --headless --path . scenes/tools/save_integrity_check_scene.tscn`
  → `[save-integrity] DONE fails=0`, exit 0. (First run showed 13 fails from missing texture
  imports — the same stale `.godot` import-cache artifact `docs/RELEASE_READINESS_REPORT.md` v6
  already documented for the headless suite; `godot --headless --path . --import` cleared it. Not
  a code bug, not re-litigated further here.)
- **Runtime economy watchdog**: [scripts/systems/integrity_guard.gd](scripts/systems/integrity_guard.gd)
  — snapshots and re-validates wallet/stat ranges on a timer, independent of the save file.

This already covers what a "build save_signer.gd + integrity.gd + tamper probe" task would have
asked for. Writing a second, parallel signing module here would violate reuse-before-write for no
gain — this file documents the real one instead.

## Threats considered

| Threat | Mitigation | Residual risk |
|---|---|---|
| Hand-edited save JSON (text editor) | HMAC signature over `power`/`progress`, rejected on mismatch | none for this specific vector |
| Corrupted/truncated save (crash mid-write) | atomic write via temp file + rename, 3-generation `.bak` rotation | none |
| Forged save built from scratch | needs the HMAC key, which ships in the client binary | see below — not solvable client-side |
| Legacy unsigned saves from before this system | `_migrate()` path re-signs on load instead of rejecting | none — intentional compat path |
| Exported save file tampered before re-import | same HMAC check on `import_save_from_file` | none |
| Runtime memory/save editor (Cheat Engine style) while the game is running | `integrity_guard.gd` watchdog re-validates economy values periodically | detection only, not prevention — see below |

## NOT protectable client-side (honest scope)

This is a single-player offline game shipping as a client binary with no server to hold a real
secret. The following are true regardless of how much code is added:

- **The HMAC key ships inside the binary.** Anyone willing to decompile/dump the exported PCK can
  recover `_HMAC_KEY` and forge a validly-signed save. Signing stops "open the file in a text
  editor," not "reverse-engineer the client." No client-side scheme changes this — it would take
  a server holding the key, which this game does not have and is not planned to have
  ([docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md)).
- **Runtime memory editing** (Cheat Engine, GameGuardian on Android) can change any value while
  the process is live. `integrity_guard.gd` can catch and correct out-of-range values on its next
  tick; it cannot prevent the edit itself.
- **Achievement/leaderboard trust**: there is no server-side leaderboard, so "cheated" local
  achievement state has no blast radius beyond the local player's own save.
- **Export hardening** (bytecode export, see `docs/EXPORT_HARDENING.md`) raises the effort to dump
  the key; it does not make it infeasible.

Bottom line: this system defends against casual tampering (a curious player editing a JSON file)
and against accidental corruption, and is honest that it does not defend against a player
determined to reverse-engineer their own local binary — which is true of every offline
single-player game's local save file, not a gap specific to this one.
