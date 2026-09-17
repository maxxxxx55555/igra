# Export hardening

## Current state (verified against `export_presets.cfg`)

No `script_export_mode` or `encryption_key` key exists anywhere in
[export_presets.cfg](export_presets.cfg) for any of the three presets (Android, Web, Windows
Desktop). That means every export currently relies on Godot's own default rather than an explicit
project choice — worth pinning explicitly rather than leaving implicit.

## Bytecode-only scripts

Set on every export preset, under `[preset.N.options]`:

```
script_export_mode=1
```

(`0` = raw text source, `1` = compiled tokenized binary — no `.gd` source text ships in the PCK.
Godot 4 does not offer reversible-proof bytecode; this raises the bar from "open in a text editor"
to "decompile," matching the same honest scope already written for save signing in
`docs/SECURITY_THREAT_MODEL.md`.)

## Debug-guarded prints

45 files under `scripts/`/`autoloads/` currently call bare `print(...)` with no guard — verified
via `grep -rlE "^\s*print\(" --include=*.gd`. None currently check `OS.is_debug_build()` first
(zero hits for that check anywhere in the codebase). `CLAUDE.md`'s hard rule is "zero shipped
debug prints" — the 45 files are the concrete punch list for whoever closes that gap: wrap release
logging behind `if OS.is_debug_build(): print(...)`, or route through a single logger function
that checks the flag once. **Not fixed in this doc-only pass** — this phase specs the plan, P4/dev
backlog does the mechanical wrap.

## PCK encryption key workflow

Godot supports `--export-pack`/`--export-release` with a PCK encryption key
(`encryption_key` under `[preset.N.options]`, 64 hex chars = 32-byte AES key). Workflow:

1. Generate the key once: `openssl rand -hex 32` (or Godot editor's own key generator in Export
   settings). Never reuse a key across projects.
2. **The key is NEVER committed.** It does not belong in `export_presets.cfg` in plaintext if that
   file is tracked in git (it is — `git ls-files export_presets.cfg` confirms). Store it instead in
   an environment variable (`GODOT_PCK_KEY`) or a local untracked file, and pass it at export time
   via the editor's "Export With Debug" key field or `godot --export-release "<preset>" --encrypt-key "$GODOT_PCK_KEY" ...` from CI/a local script, not by editing the tracked `.cfg`.
3. Add `export_presets.cfg`'s `encryption_key=` line to `.gitignore` handling if it's ever
   auto-populated by the editor (check before every commit that touches this file — a leaked key
   defeats the entire point).
4. Encryption raises the bar on asset/script extraction the same way bytecode export does on
   scripts; it is still a client-side secret and inherits the same "NOT protectable client-side"
   ceiling documented in `docs/SECURITY_THREAT_MODEL.md` — it deters casual extraction, not a
   determined reverse-engineer with the binary in hand.

## Owner action required

Steps 1-2 (generating and holding the real key) need to happen on the owner's machine/CI, not in
this repo — same category as the AppLovin MAX SDK key already flagged in
`docs/store/HUMAN_CHECKLIST.md`. This doc specs the workflow; it does not and should not contain
an actual key.
