# BUDGET_LEDGER — Qwen weekly cap (owner directive v2.0 §6)

`QWEN_WEEKLY_CAP = 0` — **resolved 2026-11-11**: the directive left `{{N}}` as a placeholder,
the owner answered Q0 with `N = 0` in the one §11 package. Recorded as "approved by delegation"
in `docs/TZ_DECISIONS.md` (§11 package table). **Zero Qwen calls for this release.** The three
optional review roles (independent final phase review, lead-vs-nitpicker arbitration, targeted
en/ru wording QA) are handled by Hy4. No phase is blocked, and no cap can be crossed.
Revert path: one line here + the Q0 row in `TZ_DECISIONS.md`.

Ledger columns: `date | model | requests | phase | remaining`. Updated after EVERY call.

| Date | Model | Requests | Phase | Remaining |
|---|---|---|---|---|
| 2026-11-11 | Hy4 (lead) | 0 Qwen | P0 audit & registry | 0 of 0 |
| 2026-11-11 | Hy3 (workers) | 0 Qwen | P0 (no workers spawned, audit-only) | 0 of 0 |
| 2026-11-11 | Qwen | **0** | P0 | 0 of 0 (cap = 0, frozen) |
| 2026-11-11 | Qwen | **0** | §11 owner package answered (N=0) | 0 of 0 (cap = 0, frozen) |

## Routing contract (recording it here so future sessions do not re-litigate it)

- Hy3: all mass work — wiring, content, translations, tools.
- Hy4: architecture, integration, review, conflict resolution, every merge and every Godot run.
- Qwen: ONLY (a) independent final review of a phase, (b) arbitration lead vs nitpicker,
  (c) targeted en/ru wording QA. Norm <= 2 calls per phase.
- Send Qwen diffs and summaries only, never whole files. De-duplicate against this ledger within
  the same weekly window; do not re-ask something already decided.
- 80% of cap -> Qwen frozen until end of week, static-only Hy models.
- 100% of cap -> HARD STOP, report to owner with the remaining registry.
- Gate cadence: static after each commit; full battery once at end of phase; x2 identical before
  release; headless suite at end of phase and after any behaviour change.
- Context between sessions travels ONLY through `docs/RUN_STATE.md` (+ per-lane
  `docs/RUN_STATE_OC.md` for visual) and `docs/HANDOFF.md`, <= 40 lines: done | hashes | next |
  budget. Never through chat history.

## Resolved input (§11 package, asked once, answered 2026-11-11)

- **Q0 (budget):** `N = 0` — no Qwen calls this release; the three optional review roles are
  handled by Hy4. Reversible ("approved by delegation"; revert path: one line in this ledger +
  the Q0 row in `docs/TZ_DECISIONS.md`). Not re-asked.
