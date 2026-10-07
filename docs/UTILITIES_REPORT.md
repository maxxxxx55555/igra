# Utilities report (rc16, U0)

Evidence: `tools/utilities_report.sh` run through `tools/qa_sim/proof_run utilities_u0` on `2e0ada0` plus the uncommitted U0 files; raw output in
`docs/artifacts/rc16/proofs/utilities_u0.out` (exit 0, 115 lines). The run of Session 16 at `401ca41` (every candidate absent) is
`docs/artifacts/rc16/proofs/utilities.out`. Measurements only; the decision column states the measurement it rests on.

## Decisions

| Candidate | Decision | Measurement |
|---|---|---|
| Everything Claude Code, `affaan-m/everything-claude-code` @ `ef648e01899ba3e8dc6371642deaaf64b4477775` | rejected, nothing copied | 293 skills, 68 agents, 94 commands; 0 files mention godot or gdscript; `hooks/hooks.json` holds 24 hook commands, all run `node`, on PreToolUse 9, Stop 7, SessionStart 2, PostToolUse 2, PostToolUseFailure 2, PreCompact 1, SessionEnd 1; the `verification-loop` skill names npm, pnpm, pytest, cargo, go, mvn or gradle on 4 lines and godot on 0; `token-budget-advisor` asks the user a question before answering |
| gdtoolkit 4.5.0, `gdparse` | adopted for changed files | parses 375 of 379 tracked `.gd` files in 7.5 s without the engine; the 4 it cannot read are listed below |
| gdtoolkit 4.5.0, `gdlint` | adopted with the 6 defect-class rules of `gdlintrc` | default rules on the 40 `.gd` files changed since `e4bb4df`: 377 max-line-length, 261 class-definitions-order, 6 unused-argument, 6 max-returns, 3 max-public-methods, 2 class-variable-name, 1 max-file-lines, 1 function-variable-name (style, none a defect); the 6 rules kept (`comparison-with-itself`, `duplicated-load`, `expression-not-assigned`, `mixed-tabs-and-spaces`, `trailing-whitespace`, `unnecessary-pass`) found 2 trailing-whitespace lines, fixed |
| gdtoolkit 4.5.0, `gdformat` | rejected | rewrites layout of whole files; the directive forbids a mass reformat |
| ruff 0.16.9 | adopted for changed files (E9,F), already a gate on `tools/` and `scripts/` since Session 16 | E9,F: 0 findings; default rule set: 227 findings (style and modernisation), not a gate |
| mypy 2.4.0 | rejected | 16 errors in 6 of 39 Python files (index 8, operator 2, misc 2, assignment 2, union-attr 1, func-returns-value 1); the code behind each location was read: a PIL call typed as a union, a name reused for a `str` and an `int`, a dict of mixed values, a guarded `Match`; no defect found |
| shellcheck 0.11.0 (`shellcheck-py` 0.11.0.1) | adopted for changed files at `-S warning` | 18 shell scripts: 16 findings at the start (15 SC2164 `cd` without `|| exit`, 1 SC2034); 5 fixed in the scripts changed in this pass, 9 remain in unchanged wrappers (exception list below) |
| actionlint 1.7.12 (`actionlint-py` 1.7.12.25) | adopted for workflows | clean on `.github/workflows/static.yml` |
| pre-commit 4.6.2 | adopted | `pre-commit validate-config .pre-commit-config.yaml` exit 0; hook `lint-changed` added next to the card-art hook |
| CI workflow | adopted | `.github/workflows/static.yml`, tool versions pinned |
| pngquant, oggenc | rejected for now | not installed; `git diff --name-only e4bb4df HEAD -- '*.png' '*.ogg' '*.wav' '*.jpg' ':!docs'` lists 0 files |
| godot-git-plugin | rejected | an editor extension that shows git status inside Godot; it is not a merge driver, and `.tscn` files are text |

## Integration

- `tools/lint_changed.py`: the files changed since `e4bb4df` (`BASE` at `tools/lint_changed.py:27`), skipping vendor, evidence and generated trees (`SKIP_TREES` at `tools/lint_changed.py:28`); gdparse in process and gdlint once (`check_gd` at `tools/lint_changed.py:95`), shellcheck on the file with the carriage returns stripped (`check_sh` at `tools/lint_changed.py:127`); `--demo` (`demo` at `tools/lint_changed.py:154`) proves 6 fixtures: the clean file passes, a syntax error, a trailing space, a comparison with itself, an unused import and a `cd` without exit are each reported.
- `gdlintrc` (`disable:` at `gdlintrc:1`) keeps 6 rules; `gdparse` limits: `GDPARSE_KNOWN` at `tools/lint_changed.py:29` names the 4 files and the text of the line each fails on, so a new syntax error in the same file still fails.
- `tools/check.sh`: the block at `tools/check.sh:343` runs the demo and the lint inside `--static` and therefore inside `--all`.
- `.pre-commit-config.yaml`: hook `lint-changed` (`lint-changed` at `.pre-commit-config.yaml:32`) runs `python tools/lint_changed.py --staged`; installing the hook into `.git/hooks` is the owner's `pre-commit install` (CLAUDE.md: never touch `.git/hooks`).
- `.github/workflows/static.yml`: installs the pinned tools (`pip install` at `.github/workflows/static.yml:23`), runs the lint of the push or pull-request diff (`lint_changed` at `.github/workflows/static.yml:25`), `flow_check`, `scene_node_check`, `af5_check`. The engine gates and `check.sh --all` stay on the dev machine.
- Fixed by the lint: `cd ... || exit 2` in `tools/qa_sim/proof_run:9`, `tools/qa_sim/rc16_probe:8`, `tools/qa_sim/timing_equiv:7`, `tools/qa_sim/guarded_headless:7`, `tools/check.sh:12`; two trailing-whitespace lines in `scripts/player/player_3d.gd` (329 and 338).

## Zero-warning evidence and exceptions

`python tools/lint_changed.py` at the commit that adds it: 41 gd, 15 py, 7 sh, 1 workflow, 0 findings (raw: `docs/artifacts/rc16/proofs/utilities_u0.out`).
Exceptions, all listed in the raw output:
1. gdparse cannot read 4 files (`scripts/tools/_closeout_check_runner.gd:1183`, `scripts/ui/character_screen.gd:281`, `scripts/ui/hud_3d.gd:1520`, `scripts/ui/puzzle_cables.gd:204`): a one-line `if` inside a lambda body, and a string literal with raw newlines. The engine compile gate is the parse proof for them.
2. shellcheck, 9 findings in wrappers not changed in this pass: SC2164 in `tools/qa_sim/_resolve_godot.sh:21`, `autoplay_bot:11`, `closeout_check:8`, `guarded_windowed:11`, `headless_suite:15`, `playthrough:13`, `static_syntax_check.sh:10`, `tz_verify:8`, and SC2034 in `tools/qa_sim/autoplay_bot:37`. The lint gates a file only when it changes.
3. The CI run on `599cd89` (run 37669887172, `https://github.com/maxxxxx55555/igra/actions/runs/37669887172`) completed with conclusion success: 8 steps (checkout, python, pip install, lint demo, lint of the diff, flow_check, scene_node_check, af5_check) all success, 3 min 55 s; the job JSON read from the public API is `docs/artifacts/rc16/proofs/ci_static_599cd89.json`. The workflow runs on pushes to main and pull requests only.

## Installed on the dev machine

`python -m pip install --user gdtoolkit mypy pre-commit shellcheck-py actionlint-py` (ruff 0.16.9 was present). The install replaced `filelock` 3.20.3 with 4.0.12 (a dependency of the pre-commit chain); `aider-chat 0.86.2` in the same user site pins `filelock==3.20.3`, and `python -m pip check` lists 7 more of its pins that were already unmet (aiohttp, click, fastapi, hf-xet, huggingface-hub, numpy, openai).
