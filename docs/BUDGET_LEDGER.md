# BUDGET_LEDGER — Qwen weekly cap (owner directive v2.0 §6)

`QWEN_WEEKLY_CAP = {{N}}` — the directive left `N` as a placeholder. The numeric cap is
**unknown**. Per §6 and §11 the lead does not invent a number. Until the owner supplies `N`
(question Q0 in the §11 package), the ledger operates in **static-only / Hy-models-only mode**:
zero Qwen calls, so no cap can be crossed. No phase is blocked by that, because Qwen is
reserved for (a) an independent final phase review, (b) lead-vs-nitpicker arbitration,
(c) targeted en/ru wording QA — all optional accelerators, not gates.

Ledger columns: `date | model | requests | phase | remaining`. Updated after EVERY call.

| Date | Model | Requests | Phase | Remaining |
|---|---|---|---|---|
| 2026-11-11 | Hy4 (lead) | 0 Qwen | P0 audit & registry | cap unknown (N unset) |
| 2026-11-11 | Hy3 (workers) | 0 Qwen | P0 (no workers spawned, audit-only) | cap unknown (N unset) |
| 2026-11-11 | Qwen | **0** | P0 | cap unknown (N unset) |

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

## Missing input (goes into the §11 package, asked once)

- **Q0 (budget):** what is `N` for `QWEN_WEEKLY_CAP`? Default if the owner is silent: `N = 0`,
  i.e. no Qwen calls this release, all three optional review roles handled by Hy4. Reversible
  ("approved by delegation", revert path: one line in this ledger + one `TZ_DECISIONS` row).
