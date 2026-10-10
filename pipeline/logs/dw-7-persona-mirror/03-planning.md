# 03 planning — dw-7-persona-mirror

Transition: `spec-approved` → `implementing` (coordinator writes QUEUE.md).

Skill: `/imple-plan`, under PIPELINE.md's pipeline-mode override (Steps with
done-when, Acceptance map, Risks; no Code Structure / Calling Sequence /
Data Flow / Test Plan; no architecture re-run).

Reads: CLAUDE.md; PIPELINE.md (Skills per stage, pipeline-mode overrides,
Parallel waves); spec `specs/dw-7-persona-mirror.md`; review
`logs/dw-7-persona-mirror/02-spec-review.md`; precedent
`plans/dw-6-session-log.md`. Targeted code: `divination/render.py`
(:120-260), `divination/turn.py` (`turn_events`), `main.py` (turn and
summary routes), `generation.py` (`ensure_divination_summary`),
`chart/natal/report.py` (not memoized), `db/migrations/` (last is 011),
`tests/test_boundaries.py` (`_create_table_columns`, turn-state regex),
`tests/test_divination_render.py` (fragment set, order tests,
`_chart_json`), `web-divination/src/chat/ChatPanel.tsx` header/greeting,
i18n `chat.houses`, root `package.json` scripts.

Output: `pipeline/plans/dw-7-persona-mirror.md` — 10 steps (0–9), 1,820
words (`wc -w`).

Review notes settled in the plan:
- N1: accepted the second `natal_report` per turn (tens of ms vs a streamed
  reply; passing facts would change `turn_events` and move chart work
  pre-stream); `cached_for` returns None on any exception so a bad chart
  still fails as the SSE `error`.
- N2: `_create_table_columns(sql, table)` looks the table up by name.
- N3: with-chart prompt tests may take order/fragment-set updates; the
  chart-less golden stays strict (fixture files recorded from unedited
  render.py first thing in step 5).
- N4: flagged for the journal.
- N5: zh 你的金星 / 她正在寻找自己的声音… / 入庙 入旺 落陷 入弱 / ℞ 逆行;
  en `in {sign}` vs zh `{sign}` template.
- N6: A3 log quotes both first answers side by side.

Deviations: none structural. For journaling: N1 acceptance, N4, N5 strings,
golden as fixture files. Wave note for the coordinator: dw-9 must re-record
the chart-less golden fixtures if it edits `venus.txt` or `lang.*`.
