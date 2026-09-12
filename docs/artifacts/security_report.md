# Security / anti-tamper report (STEP 5, RELEASE CONVERGENCE, 2026-09-12)

Scope stated up front, honestly: **this is an offline single-player game
with no server.** Nothing below is real anti-cheat — a determined player
with a decompiler can always win against a client-embedded secret. What
follows is a genuine speed-bump raise (a hand-edited save now needs the
binary reverse-engineered, not just re-hashed) plus real crash-safety and
scope hygiene, which are worth doing regardless of the anti-cheat ceiling.

## 1. Save signing — HMAC-SHA256 (was: plain SHA-256)

`scripts/core/save_system.gd`. The pre-existing "checksum" was
`body.sha256_text()` — proves the bytes weren't corrupted, proves nothing
about who wrote them (no secret involved, so a save-editor just re-hashes
after editing). Now `Crypto.hmac_digest(HASH_SHA256, embedded_key, body)`.
Backward-compatible: a save written before this pass still verifies once
against the old plain hash (so no player gets quarantined by the update
itself); the next autosave re-signs it with the real HMAC.

**Honest ceiling, in the code's own comment:** the key ships inside the
client. No backend exists to hold an un-extractable secret. This stops
"open the save in a text editor and change a number" — it does not stop
"decompile the APK, find the key, forge a valid signature."

## 2. Graceful corrupt/tampered recovery — verified, not just claimed

Pre-existing chain (`_write_atomic`/`_read_validated`): main file → `.bak`
→ quarantine (`.corrupt-<unix>` rename) → clean state. Never throws, never
crashes. Verified this pass with a genuinely adversarial test, not just
the 3 hand-picked cases that already existed:

**50-mutant fuzzer** (`scripts/tools/_save_integrity_check.gd`,
`_check_fuzz_50_mutants`): a real signed save → 50 deterministic
corruptions (byte flips, truncation, garbage append, zeroed chunks, empty
file) → `SaveSystem.load_slot()` on each. Proof of "never crash" is
structural — a real engine crash on any mutant would kill the whole gate
process mid-loop, so completing all 50 and reaching the final assertion
**is** the proof. Also asserts `CoinWallet` stays within its own clamp
(§3) after every mutant, whichever path SaveSystem took.
**Result: 50/50 processed, 0 crashes, 0 out-of-bounds state.**

## 3. Stats sanity clamps (previously unclamped straight from save JSON)

| Field | File | Bound |
|---|---|---|
| `coins` | `scripts/economy/coin_wallet.gd` | `[0, 999999]` |
| `level` | `scripts/systems/xp_manager.gd` | `[1, 9999]` |
| `current_xp` / `xp_to_next` | `scripts/systems/xp_manager.gd` | `[0, 999999999]` |
| `total_skill_points` | `scripts/systems/xp_manager.gd` | `[0, 9999]` |
| `skill_points` | `scripts/systems/skill_tree_manager.gd` | `[0, 9999]` |
| `unlocked_skills` | `scripts/systems/skill_tree_manager.gd` | type-checked (Dictionary or reset to `{}`) |

These are generous ceilings well above anything legitimate play reaches
(shop prices are 30-100 coins; nothing elsewhere enforces a level cap) —
they stop a hand-edited save from putting the game in a negative,
overflow, or wrong-type state, nothing more. Not a claimed design balance.

## 4. Dev tools / probe scenes excluded from export

`export_presets.cfg` — all 3 presets (Android/Web/Windows) now carry
`exclude_filter="scenes/tools/*,scenes/tools/**,scripts/tools/*,
scripts/tools/**"`. Verified no production script references anything
under those paths (one hit was a code *comment*, one was `tools/
scene_smoke.gd` — itself dev tooling — referencing a `scenes/tools/`
scene; neither is a real runtime dependency), so excluding them cannot
break a shipped build. This is every headless gate driver, the autoplay
bot, the touch/save-integrity probes, the QA scenario runner — none of it
ships in the player-facing binary.

**Cheat keys:** searched for any hardcoded debug key combo / god-mode
toggle in production scripts — found none. `OS.has_feature("dev")` is not
used anywhere in this codebase (no dev-gated code paths exist to verify),
which is a non-issue rather than a gap: there is nothing to gate.

## 5. Debug prints — audited, 0 shipped-scratch prints found

Searched every production script (`scripts/**`, excluding `scripts/tools/`
— dev-only test drivers, now also export-excluded per §4) for `print(`/
`print_debug(`/`printerr(`. Four files matched; each is a *named,
prefixed, operational* log line (`[SaveSystem]` corruption/recovery
events, `[LAN]` connection state changes, the AdService stub's one-line
"SDK not connected" notice), not leftover scratch debugging from
iteration — the kind of thing a real support session would want visible
in `adb logcat`, not scaffolding someone forgot to delete. The one
`print()`-heavy function found (`footstep_system.gd`'s `demo()`, a
ponytail-style self-check) is never called from any production code path
(`_ready()` doesn't call it) — it only runs if a dev tool explicitly
invokes it, so it never prints during real play either. **Verdict: 0
genuine debug-print violations; nothing removed, because there was
nothing to remove.**

## 6. Anti "lost phone" (STEP 6, cross-referenced here since it touches SaveSystem)

`export_save_to_file()`/`import_save_from_file()` — see
`RELEASE_CHECKLIST.md` §8 for the player-facing flow and
`docs/RELEASE_ARTIFACTS.md` for the commit. Import validates the file is a
genuine HMAC-signed envelope before touching anything, and backs up the
current save to `.bak` first — same recoverability guarantee as §2.
