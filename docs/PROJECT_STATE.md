<!-- LOCALE TRUTH (2026-11-10): the shipped build supports exactly 2 locales (`en`, `ru`); the owner cut the other 11 on 2026-11-05. Every mention of 13/11/6 locales in this repository is a historical pre-cut record, not the current build. -->

# Project State — The Last Streetlight (ПОСЛЕДНИЙ ФОНАРЬ)

**Single authoritative status document.** Every other status doc reconciles to this one.
Machine-readable header block first, then prose.

```yaml
version: 1.0.1
version_code: 17
main_sha: 04d54aae806310cbf90f115c820e505172cc6e0a
locales: [en, ru]
districts: 11
status: BLOCKED
owner_only_items: 6
last_verified: 2026-11-10
```

## Status: BLOCKED (owner-only residue)

The repository is **frozen for agent work**. All agent-closable work across Phases A–H has been
completed or explicitly deferred to the owner. The remaining open items are **owner-only** (they
require secrets, store accounts, or business decisions the agent cannot perform) and are listed in
`docs/artifacts/known_owner_only_items.md` (6 items):

1. Windows Authenticode signing (owner code-signing certificate / keystore).
2. Android upload signing (owner upload key + Play Console account).
3. Real AppLovin MAX SDK key (currently wired against the stub).
4. Texture-compression banding pass on 74 specific files (owner art-direction call).
5. Draw-call budget re-measure on target hardware.
6. Store listing publish + Open Testing launch (owner Play/Store accounts).

These are **not** agent blockers — the builds, gates, and documentation are complete and reproducible.
Per the closure brief, a `BLOCKED` status is the correct, honest terminal state when owner-only
items remain; it must not be relabeled `CLOSED` by an agent.

## What is verified (agent-closed)

- **CI green** — `static`, `pr-sims`, `release-wrapper`, `weekly-full` all pass on `main`
  (`04d54aae`, Phase A). Required-status `static` check enforced on branch protection.
- **Locales** — exactly 2 shipped: `data/i18n/en.json`, `data/i18n/ru.json`.
- **Version** — `project.godot` `config/version="1.0.1"`, `export_presets.cfg`
  `product_version="1.0.1"`, `version/code=17`, consistent with `RELEASE_NOTES.md` and
  `store/listing.md`.
- **Lint false-green class killed** — `tools/lint_changed.py` no longer exits 0 with a partial
  toolchain; `tools/check.sh` requires the full pinned toolchain in CI.
- **Doc-truth reconciled** — `tools/closure_guard.py` (6 rules, `--demo` proven) enforces that no
  status doc drifts on locale count, `main` SHA, version, `CLOSED` status, backed READY/SHIPPED
  claims, or dead branch references.
- **Builds** — Windows and Web export artifacts produced and checksummed from current `main`.

## Drift guard

`tools/closure_guard.py` is the mechanical guarantee that the project cannot silently drift back
into "development". It is wired into `static.yml`, `pr-sims.yml` and `tools/check.sh`. Any future
edit that re-introduces a wrong locale count, a stale `main` SHA, a version disagreement, a
`CLOSED` status with lingering `in_progress`, an unbacked `READY`/`SHIPPED` claim, or a reference
to a branch that does not exist on `origin` will fail the static gate.

## Historical note

Earlier planning targeted up to 13 locales (en, ru, de, es, fr, pt_BR, zh, ja, ko, it, pl, tr, uk).
The owner cut the project to **en + ru only on 2026-11-05**. All prior "13/13 parity", "11 locales",
or "6 locales" statements in the documentation are pre-cut history and are explicitly marked as such.
