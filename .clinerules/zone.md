# Cline zone contract

Branch: `cl/a11y-i18n` (create from `main` if missing; never push an empty branch).

## Zone (touch nothing outside this list)
`data/i18n/*.json`, `scripts/ui/*` accessibility-relevant code, `scripts/tools/_a11y_probe.gd`,
`docs/ACCESSIBILITY.md`.

**Do not touch** `docs/STORE_KIT.md` or `store/screens_spec/shotlist.json` — both arena-delivered,
already merged into `main` (`ff863c3`), out of scope here.

## Real known conflict — read before adding a11y keys/effects
`main`'s `docs/GAMEFEEL_SPEC.md` (this session, `6d356f6`) names 3 accessibility toggles
(`reduce_flash`, `reduce_time_fx`, `reduce_ui_motion`) and they're already wired into
`scripts/systems/wow_director.gd`, `scripts/ui/toast_manager.gd`, `scripts/systems/uisfx.gd`,
`scripts/ui/settings_screen.gd`, and all 13 `data/i18n/*.json` files (commit `f372a5c`). A
**more detailed, conflicting** version of the same spec exists on unmerged branch
`arena/01a0ab24-igra` (specific numeric budgets, a companion `docs/QA_MATRIX.md` with rows keyed
to it, `git merge-tree` confirms a real content conflict against `main`'s version — not a
clean merge). If your a11y-gate audit needs a numeric budget (shake px, hit-stop ms, flash
duration) that `main`'s `GAMEFEEL_SPEC.md` doesn't specify precisely enough, check the other
branch's version before inventing a number — it may already have one, worked out in more detail.

## Scope order
Delta `LocalizationManager.t()`/`tf()` keys added since `v7.0.0-rc1` (`git diff v7.0.0-rc1 HEAD --
data/i18n/en.json` for the added set) → translate to all 13 locales, Keeper voice, ≤1.6× the EN
key's character length (mirrors the short-description discipline already used for
`docs/STORE_KIT.md`) → audit every juice/effect site from `f372a5c` for a working accessibility
gate (`reduce_flash`/`reduce_time_fx`/`reduce_ui_motion`, resolved by the conflict-check above) →
build `scripts/tools/_a11y_probe.gd`, a headless probe proving each toggle actually suppresses its
effect (mirror `scripts/tools/_save_integrity_check.gd`'s pattern: real assertions, `quit(0/1)`) →
wire it into `tools/check.sh` as a gate → backlog (glossary sweep across all 13 locales, caption
completeness for deaf/blind-combination players per `main`'s `GAMEFEEL_SPEC.md` QA note, settings
persistence edge tests for the 3 toggles across save/reload).

## Rules
- Push after every commit; prove it: `git ls-remote origin <ref>` must equal `git rev-parse <ref>`.
  One retry with an explicit refspec; two failures in a row is a hard stop.
- Rewrite `docs/RUN_STATE_CL.md` after each phase, ≤40 lines: what's done, hashes, what's next.
- Never touch `main` directly, never touch OpenCode's zone (`scripts/world_env_setup.gd`,
  `shaders/**`, `assets/shaders/**`, visual `.tres`, VFX scenes, `docs/stills/**`,
  `docs/store_screens/**`, `_orphaned`/`_pre_norm`/`_QUARANTINE` deletion) — a zone violation is a
  stop-and-report, not a push-through.
- Economy rules apply (see `CLAUDE.md`): targeted reads, output caps, one-line phase reports.
- Hard stop: same gate failing twice on the identical error; push failing twice.

See `docs/AGENT_ZONES.md` for the full agent/branch/zone table.
