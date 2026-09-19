# Tooling decisions

External tools considered this pass. None installed — every one either failed verification or
was explicitly deferred/skipped by the task itself. Installing unverified software (supply-chain
risk, and in two cases something that would read this session's own activity) is exactly the kind
of judgment call this repo's `CLAUDE.md` asks to be conservative about, not default-yes.

| Tool | Decision | Reason |
|---|---|---|
| Zoetrope | **Not installed** | Real project found (`zoetrope.furkankly.dev`, agent-session observability/replay for Claude Code) — matches the description, but it's a single-maintainer, domain-hosted tool with no independent security signal found in one search pass. Installing something that watches this session's own activity is a real trust decision; one web search isn't enough verification for that. Deferred to the owner |
| Multi | **Not installed** | No specific tool literally named "Multi" matching "adds a merge-review gate without resident MCP servers" was found — search surfaced generic AI-code-review products (Qodo, CodeRabbit, Greptile, etc.), none matching the name. Ambiguous per the task's own fallback rule — skipped, not guessed at |
| Stagehand | Deferred | Owner's Play Console step (per task) |
| Crush | Skipped | Redundant shell (per task) |
| Morphic | Skipped | Research tool, not execution (per task) |
| Storm | Skipped | Research tool, not execution (per task) |
| ThreeUI | Skipped | React component lib; this project is Godot, not a web frontend (per task) |

**Standing rule, unchanged**: nothing here adds a resident MCP server. If the owner wants Zoetrope
or a specific "Multi"-named tool installed, that's a one-line ask once they've picked a source
they trust — not something to install on a single search result.
