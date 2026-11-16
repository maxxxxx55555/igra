<!-- LOCALE TRUTH (2026-11-10): the shipped build supports exactly 2 locales (`en`, `ru`); the owner cut the other 11 on 2026-11-05. Every mention of 13/11/6 locales in this repository is a historical pre-cut record, not the current build. -->

# Project State — The Last Streetlight (ПОСЛЕДНИЙ ФОНАРЬ)

**Single authoritative status document.** Every other status doc reconciles to this one.
Machine-readable header block first, then prose.

```yaml
version: 1.0.1
version_code: 17
main_sha: 965ec095c945f976edab4a58ec6c66243a8d89e0
locales: [en, ru]
districts: 11
status: BLOCKED
status_detail: UNFROZEN-IN-PROGRESS (owner directive 2026-11-11; terminal state RELEASE-READY / BLOCKED(owner-only))
owner_only_items: 6
last_verified: 2026-11-11
```

<!-- UNFREEZE (2026-11-11, owner directive "TLS -> RELEASE" v2.0 §0): the 2026-11-10
"frozen for agent work" status below is a dated historical record, SUPERSEDED as a status
statement. The owner reopened the agent-closable remainder for the sole purpose of taking
1.0.1 to release. The single work queue is docs/RELEASE_GAP_FINAL.md; the decision log is
docs/TZ_DECISIONS.md. `CLOSED` / `SHIPPED` remain forbidden without owner proof. -->

<!-- W TRUTH (2026-11-11, §1.2 resolved by code, PR-dated): the claim in AGENTS.md:25-29 that
only W1 of VISUAL_PASS.md's W1-W11 is connected and W2-W10 have "zero consumers" is STALE.
git grep on current main shows live consumers for W2 (world_env_setup.gd:46,108),
W3 (district_dressing.gd:31), W4 (lamp_head.gd:6, street_props.gd:217),
W5 (street_wetness.gd:6, street_props.gd:316), W6 (contact_shadows.gd:34, visual_quality.tres:9-12),
W7 (weather_particles.gd:6-7, player_3d.gd:1503), W8 (menu_parallax.gd, main_menu.gd),
W9 (theme_setup.gd:18, theme_provider.gd:18-24), W10 (streetlight_3d.gd:27,50,68-69).
Ground rendering is script-driven (district_grading.gd tints ground; world_env_setup.gd is the
single WorldEnvironment writer); district_scene_factory.gd has no WorldEnvironment on main.
Full file:line table: docs/RELEASE_GAP_FINAL.md §2. Code wins over docs. -->

## P1 — agent-closable residue closed (2026-11-12, branch `arena/8966ccea-igra`)

Worked from `24b970a` with a clean tree. The registry is still the single queue; §10 of
`docs/RELEASE_GAP_FINAL.md` holds the evidence of this session.

**Closed with evidence (static proofs in §10):** T3 (key hints read the live binding, dead hint
strings removed, phone gets a quick-slot reset gesture, new `hint_binding_check.py` proved to bite),
T8 agent part (`min_touch()` is density-aware), T9 (one notice queue, the two checks that read the
removed field now read the queue), T10 (`narrow_layout` deleted as dead, `skyline.gd` live), T13
(the hum row is a recorded owner decision, the stale W4 instruction is marked dropped), T14 (status
docs dated), G-MSAA (the null dereference is guarded and locked by `viewport_write_guard.py`),
G-AUDIT, G-DEMO-VIS / G-DEMO-AF2 / G-DEMO-LINT, G-CLEAN-TREE.

**Still open, and correctly so:** T12 (needs one engine chain: the coverage misses match logs only
the owner's machine writes), G-WINDOWED and the two windowed gates (no display, no GPU, no Godot
4.7 binary in the P1 sandbox), and every owner-only row of §7 — none of them was touched.

**Not claimed:** no engine gate (compile, signal arity, autoload API, i18n, asset, save integrity,
boot), no export and no device run was performed in P1. The P1 battery is static: 73 passed, 2
environment-only failures (`actionlint` binary download blocked, ffmpeg now installed), §10.9.

## Status: UNFROZEN — agent work reopened (2026-11-11), owner-only residue unchanged

**Historical (2026-11-10):** the repository was declared frozen and the Phase A–H agent work
declared complete. The 2026-11-11 owner directive reopened the agent-closable remainder; that
freeze statement is retained above only as a dated witness, not as the current status.

**Current (2026-11-11, P0):** the single registry `docs/RELEASE_GAP_FINAL.md` lists all open
agent rows (T1-T14, P0 battery defects, KNOWN_ISSUES verify-first rows) and all owner/decision
rows. P0 battery truth: 6 failed / 97 passed on a dirty tree
(`.qa_logs/proofs/p0_static_20261111.out`, `docs/ENVIRONMENT.md`). Terminal state after P1-P3
must be `RELEASE-READY` or `BLOCKED(owner-only)`; `CLOSED` / `SHIPPED` require owner proof.
The following 6 items remain **owner-only** (secrets, store accounts, or business decisions)
and are listed in `docs/artifacts/known_owner_only_items.md`:

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
