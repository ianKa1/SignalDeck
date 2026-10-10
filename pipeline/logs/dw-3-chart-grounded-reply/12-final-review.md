# 12 final review — dw-3-chart-grounded-reply (auto-finalized)

**Acceptance**: PASS, all 25 criteria (S1–S11, C1–C3, W1–W4, A1–A7) — logs/dw-3-chart-grounded-reply/11-accepting.md (fresh-context checker).
**Landed**: 2f45dfb on feature/divination_web (squash of 7a2aa51…8aa9252); branch deleted. Cycles used: 0. Spec needed 3 review rounds.

## What was built
- Turn request gains optional `birthData`; the server recomputes the natal chart per turn (never stored) and renders context from `natal_report` + `relevant_meanings` + the borrowed `interpretation.prompt._restate` (pinned by `test_divination_borrows_only_the_restate_helper`, which retired the old fence test with a byte-identical regex).
- The mood side read now returns `{mood, chartRefs}` with refs constrained to a catalogue built from the chart (ten planets + aspects between planets/Ascendant), validated, deduped, capped at 6; `done` = `{mood, chartRefs[]}`.
- Persona fragments `chart.none` / `chart.read` / `chart.marker`; unknown birth time → no house/rising claims.
- core `ChartRef` + `isChartRef`; refs persist on the persona transcript entry; web chips under the finished reply (inert until dw-4), en/zh.
- CLAUDE.md rule 10 amended (the one pinned borrow; birth data rides each turn).

## Deviations
Plan D1–D4 and the worker choices journaled 2026-09-28 (useChat change moved to step 3; exhaustive `Record<AspectType,true>`; one unlisted dw-2 test expectation).

## Known limitations
- Paid providers unexercised (claude-cli + fakes only).
- `server/app/ARCHITECTURE.md` still lacks a Tier C entry for `app/divination`.
- Chips are not interactive yet (dw-4).
