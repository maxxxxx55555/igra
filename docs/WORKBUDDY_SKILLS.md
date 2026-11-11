# WORKBUDDY_SKILLS — protocol cards (loaded at the start of EVERY session)

Owner directive "TLS -> RELEASE" v2.0 §4. This WorkBuddy session does not auto-load
`.claude/skills/**`, so this file IS the protocol surface. Load it first, then log one line
per skill invocation in `docs/RUN_STATE.md`. Repo canon: English.

## Source of truth

- Enabled: `.claude/skills/{backup-first,godot-style,memory-keeper,ponytail,token-saver}/SKILL.md`
- Disabled but present on disk (do NOT assume they are active):
  `.skills_disabled/claude/{ponytail-review,speckit-analyze,speckit-checklist,speckit-clarify,
  speckit-constitution,speckit-converge,speckit-implement,speckit-plan,speckit-specify,
  speckit-tasks}/SKILL.md`
- Reviewer agent (read-only, append-only to `docs/NITPICK_v1.0.md`): `.claude/agents/nitpicker.md`
- Other agents on disk: `bug-hunter`, `code-reviewer`, `godot-architect`, plus
  `.opencode/agents/*` (android-builder, qa-mobile, release-publisher, ...).

## Cards

### ponytail (apply to EVERY diff)
Ladder, stop at the first rung that holds: (1) does this need to exist at all (YAGNI);
(2) already in the codebase -> reuse; (3) stdlib; (4) native platform feature;
(5) already-installed dependency; (6) can it be one line; (7) only then the minimum code.
Bug fix = root cause, not symptom: grep EVERY caller of the function before editing; one guard
in the shared function beats a guard in every caller. No unrequested abstractions, no
boilerplate "for later", deletion over addition, boring over clever. Active every response,
default intensity `full`. Not used for prose/translation/summaries.

### ponytail-review (before committing a code fix)
Read the diff as a hostile reviewer: does it touch only the zone? Is it the shortest working
change? Does it reuse an existing helper? Any new abstraction with one implementation? Any
debug print / TODO / commented-out code / BOM? If any answer is bad, fix before commit.
(Source card is disabled on disk -> apply this card manually and log it.)

### godot-style (every `.gd` edit)
Static typing everywhere; `@export` for tunables; `snake_case`; no polling in `_process`
(signals/timers); `is_instance_valid()` for freed nodes; scripts >300 lines are split; comment
only the non-obvious "why", in English; autoloads via `/root`; `PROCESS_MODE_ALWAYS` on anything
that runs while paused; autoloads never name world classes.

### backup-first (before doc regeneration and ANY batch operation)
Before deleting/overwriting project files, copy them outside the repo to
`..\_BACKUPS\YYYY-MM-DD_HH-MM\` preserving relative paths (`Copy-Item`). Skip only if the file
is under VCS with a clean commit. Do not weaken the sandbox bulk-delete guard.

### memory-keeper (end of every wave)
Read `opencode-memory.md`; append a short dated entry (what changed + key decisions); update
`CLAUDE.md` if the project structure changed. Never delete old entries.

### token-saver (always)
Concise answers; files >500 lines never read whole (Grep narrow + Read offset/limit); do not
echo user code back; project-wide searches skip `refs/` and `myrepos/`; durable knowledge goes
to `opencode-memory.md` / `CLAUDE.md` / `docs/RUN_STATE.md`, not into context; suggest `/compact`
after each finished stage.

### nitpicker (one read-only reviewer round at the END of EVERY phase)
Hostile, no edit rights. May append only to `docs/NITPICK_v1.0.md` and write under `.qa_logs/`.
Every row: `| ID | SEVERITY | AREA | WHAT IS WRONG | WHERE (file:line or frame) | REPRO | EFFORT |`.
SEVERITY: BLOCKER / MAJOR / MINOR / COSMETIC. A row without REPRO/frame is deleted. Findings
split into GAME-AFFECTING (must be fixed before the phase closes) and META (dated record only).

### spec-kit (MANDATORY for the P2 feature-sized juice wave)
`/speckit-specify` -> `/speckit-plan` -> `/speckit-tasks` -> `/speckit-implement`. Small fixes
skip the full cycle. The cards are disabled on disk; P2 must either re-enable them or emulate
the four artefacts (spec, plan, tasks, implementation trace) as dated docs under
`docs/artifacts/2026-11-11-closure/` before touching code.

## Session load log

| Date | Phase | Cards loaded | Logged in RUN_STATE |
|---|---|---|---|
| 2026-11-11 | P0 audit | ponytail, ponytail-review, godot-style, backup-first, memory-keeper, token-saver, nitpicker, spec-kit | yes |
