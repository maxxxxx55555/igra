# Security threat model

Offline single-player game, no backend, no multiplayer trust boundary except optional LAN
co-op (`remote_player_state` etc. in EventBus — peer-to-peer, no server to arbitrate; currently
dead code with zero consumers, see the LAN row below).

**Updated (studio-lead C2 SEC-CLOSE pass) after `docs/SECURITY_PATCH_SPEC.md`'s audit.** That
audit found real gaps beyond what this document originally described (legacy-checksum bypass,
several entirely-unsigned sidecar files, no slot binding, no semantic validation on signed bodies,
a dormant watchdog, unvalidated LAN payloads, leaked debug keystore credentials). Every closable
finding is now fixed with a real code change + an `attack_sim.gd` regression case, A/B-verified
against the reverted code — not just re-described as already fine. See `docs/RUN_STATE.md`'s
"C2 SEC-CLOSE" section for the full trace, commit hashes, and the items deliberately left open.

## What already exists — verified, not rebuilt

A signed-save + tamper-probe system already ships, now extended to every gameplay-authority file,
not just the main save:

- **Signing**: [scripts/core/save_system.gd:21-24](scripts/core/save_system.gd:21) — HMAC-SHA256
  over the save body via Godot's `Crypto.hmac_digest`, with an inline comment already stating the
  honest scope (speed bump, not real anti-cheat — see "NOT protectable client-side" below). The
  same key now also signs `ng_plus_data.json`, `flashlight_upgrades.cfg`, `tls_daily.json`, and
  `achievements.cfg` (new format) — every gameplay-authority sidecar file that used to be plain,
  unsigned JSON.
- **Backup rotation, corruption/tamper rejection**: `_write_atomic`, `_rotate_backups`,
  `_read_envelope` in the same file. The legacy plain-`checksum` compatibility path is now a hard
  rejection, not a trust-once-then-migrate: a save without a real `hmac` never loads (closes
  SECURITY_PATCH_SPEC P-01 — there is no cryptographic way to tell an authentic pre-patch legacy
  file from a forged one, so this is a real, accepted cost, not a free fix).
- **Slot identity**: `slot_id` is part of the signed payload for `save_slot()`/`load_slot()`; a
  validly-signed save from one slot no longer silently loads as another slot (P-06).
- **Semantic validation on every `from_dict()`**: district stage, inventory stack size, secrets
  (against the real 26-secret content total), quest progress/done consistency, and saved
  district-id/player-position are all bounds-checked before being applied, not just
  signature-checked (P-07, R-03). `kills`/`puzzles` are floored at zero but NOT capped — this
  project has no fixed total for either, and guessing a wrong cap risks breaking a legitimate
  long/replayed save more than it stops anything.
- **Test probe**: [scripts/tools/_save_integrity_check.gd](scripts/tools/_save_integrity_check.gd)
  (main-save format, 24 checks) plus [scripts/security/attack_sim.gd](scripts/security/attack_sim.gd)
  (forgery/schema attack surface across every sidecar file, NG+, flashlight upgrades, slots, LAN
  payloads, district/position validation, and the live watchdog). Both wired into `tools/check.sh`.
- **Runtime watchdog is now actually live**: [scripts/systems/integrity_guard.gd](scripts/systems/integrity_guard.gd)
  was fully implemented (economy clamp, missing-player grace-tick detection, fell-through-floor/
  non-finite position restore, HP/battery/stamina range checks) but was missing from
  `project.godot`'s `[autoload]` list — this document previously described it as running when
  nothing was. Now registered (R-01), verified with `autoplay_bot` still winning cleanly with the
  watchdog live. Still detection/correction only, not prevention — see below. A speed/displacement
  check (R-02) was deliberately NOT added: a correct teleport/scene-transition exemption is real
  design risk, left open rather than guessed at.
- **LAN payload validation**: `rpc_player_state`/`rpc_power_changed` now reject a non-finite
  position, an unknown district, and (for player state) a sender claiming a peer_id that isn't its
  own (R-07). No consumer of these signals exists yet (`EventBus.remote_player_state`/
  `remote_power_changed` have zero listeners in the whole codebase) — closed as the boundary a
  future consumer would otherwise trust blindly, not because of a live exploit today.
- **Release config hygiene**: `export_presets.cfg` no longer carries debug keystore credentials
  (D-04); `tools/qa_sim/release_export_check.py` gates against that regressing and against a
  committed PCK `encryption_key=` (C-08, static-only — does not inspect an actual exported
  artifact, which needs a real `--export-release` run not available in this environment).

## Threats considered

| Threat | Mitigation | Residual risk |
|---|---|---|
| Hand-edited save JSON (text editor) | HMAC signature over the whole envelope (main save) or the domain envelope (NG+/flashlight/daily/achievements-new-format), rejected on mismatch | none for this specific vector |
| Corrupted/truncated save (crash mid-write) | atomic write via temp file + rename, 3-generation `.bak` rotation | none |
| Forged save built from scratch | needs the HMAC key, which ships in the client binary | see below — not solvable client-side |
| Pre-signing legacy main save | rejected outright, not migrated (P-01 — a deliberate, accepted cost) | orphans a genuinely pre-HMAC save; no cryptographic alternative exists |
| Legacy unsigned achievements.cfg | still trusted once and re-signed forward (deliberate policy: achievements are device-level history meant to survive Reset Progress) | unknown IDs/unbounded progress from that one legacy read are inert dead weight in every current consumer, not exploitable |
| Cross-slot save swap | `slot_id` bound into the signed body; mismatch is rejected | none for this vector; there is no player-facing "import into a different slot" feature today, so this isn't a lost capability |
| Exported save file tampered before re-import | same HMAC check on `import_save_from_file`, plus live-state refresh so the next autosave can't clobber a fresh import with stale pre-import state | none |
| Signed-but-semantically-invalid body (stage 99, absurd item count, fabricated quest completion, out-of-roster district, non-finite position) | bounds/allowlist checks on every `from_dict()` before the value is applied | none for a body signed with the shipped key; a player who extracts the key can still forge a body that passes both checks |
| Runtime memory/save editor (Cheat Engine style) while the game is running | `integrity_guard.gd` watchdog (now live) re-validates economy/position/vitals periodically | detection/correction only, not prevention — see below; no speed/displacement bound yet (R-02) |
| Malicious LAN peer sending forged state | sender-id binding + finite/allowlist checks on both RPCs | none for the covered payload fields; no consumer exists yet for the events these RPCs feed, so there is no live gameplay effect either way today |

## NOT protectable client-side (honest scope)

This is a single-player offline game shipping as a client binary with no server to hold a real
secret. The following are true regardless of how much code is added:

- **The HMAC key ships inside the binary.** Anyone willing to decompile/dump the exported PCK can
  recover `_HMAC_KEY` and forge a validly-signed save — this now applies equally to the main save,
  NG+, flashlight upgrades, daily state, and new-format achievements, since C2 SEC-CLOSE extended
  the same signing to all of them. Signing stops "open the file in a text editor," not
  "reverse-engineer the client." No client-side scheme changes this — it would take a server
  holding the key, which this game does not have and is not planned to have
  ([docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md)).
- **Semantic validation is bounded by the same limit.** A player who has the key can forge a body
  that is both correctly signed AND passes every schema/range check added in C2 SEC-CLOSE — those
  checks stop a signed-but-buggy or signed-but-lazily-forged body, not an attacker who read this
  document and the source.
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
