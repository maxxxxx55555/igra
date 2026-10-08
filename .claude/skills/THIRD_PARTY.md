# Third-party skills in this folder

Copied unmodified, project-local only. Provenance, licence, and what was checked before each copy:

| skill directories | source | pinned commit | licence |
|---|---|---|---|
| `arena` | https://github.com/Jakeschincariol/arena-skill (`skills/arena`) | `df07b8e518e1` (main at `git ls-remote` time) | MIT (`arena/LICENSE`) |
| `cli-*`, `omni-*`, `config-codex-cli` (45 OmniRoute entries) | https://github.com/diegosouzapw/OmniRoute (`skills/`) | `26d48292ce16` | MIT |
| `graphify` | https://github.com/safishamsi/graphify (`graphify/skill.md` as `SKILL.md`, `graphify/skills/claude/references/`) | `6478eb71237c` | Apache-2.0 (`graphify/LICENSE`) |

Owner skills copied from `..\.claude\skills\` so the registry can invoke them by name: `godot-style`, `backup-first`, `memory-keeper`.
OmniRoute's own `ponytail` entry was not copied (name collision with this project's `ponytail`).

Checks (raw output under `docs/artifacts/rc16/proofs/`): `s0_skill_scan` (every `.md` line-scanned for credential reads, deletes, uploads, shell pipes, invisible characters, injection phrases; hosts found: `localhost:20128`, `github.com`, `raw.githubusercontent.com`, one doc example each for `api.elevenlabs.io` and `anthropic.com`), `s0_install_verify` (46 directories byte-identical to the scanned source, frontmatter name equals the directory), `s0_arena_plan_agents4`.

Usage rules for the rc16 pass (`docs/RUN_STATE.md`, skill log):
- `arena`: always `--agents 4` (19 sub-agent calls); the default is 100.
- `graphify`: only `--help`. Its Step 1 runs `uv tool install` or `pip install graphifyy` (third-party code outside the project), which nobody approved; the pipeline is not run.
- OmniRoute entries describe a gateway on `localhost:20128` that is not installed here. Quarantined, never invoked: `cli-skill-collector` (installs skills into `~/.claude/skills`), `omni-github-skills` (imports community skills), `omni-cli-tools` (rewrites CLI tool settings).
