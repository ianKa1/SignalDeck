# 10 — docs-sync (dw-3-chart-grounded-reply)

Skill `update-architecture-doc`. Baseline: `docs/ARCHITECTURE.md` and
`server/app/ARCHITECTURE.md` were last touched in `53af7d8` (dw-2), so the
diff `53af7d8..HEAD` (21 files, all dw-3) is exactly what they had not seen.
No escalation to wider reading was needed.

## docs/ARCHITECTURE.md (surgical)
- Executive summary, web-divination bullet: turns carry the saved birth
  data; finished replies show chips.
- Repo tree: the core `divination/` note (ChartRef); the web `chat/`
  (ChartRefChips, sending birth data); the server `divination/` tree entry
  (new fragments, natal_context/catalogue/to_wire_refs, the one pinned
  `_restate` borrow).
- Boundary-tests paragraph: the divination fence's one exception and how
  `test_divination_borrows_only_the_restate_helper` pins it (strip,
  exactly once, shallow-import asserts).
- `core/divination` section: `ChartRef`, `isChartRef`,
  `TurnRequest.birthData`, `done {mood, chartRefs}`, the transcript's
  `chartRefs` persistence rule, and `toWire` still `{role, text}`.
- Tier C `interpretation/prompt.py` line: `_restate` is also borrowed by
  divination.
- Tier C `divination/` entry: the four fragments, `natal_context`,
  `ref_catalogue`, the new `system_prompt`/`turn_messages`/`side_prompt`
  signatures, `side_schema`, `to_wire_refs`, `turn_events(request,
  person)`, `done {mood, chartRefs}` degradation, the request's
  `birthData`, and the tests.
- web `chat/` section: useChat sends `getBirthData()` and stores refs;
  the ChartRefChips look and a11y; i18n binding of `chat.aspects`.
- Runtime flow paragraph: `natal_context` then `done {mood, chartRefs}`
  then the chip row.
- Confirmed still accurate (untouched): layout/columns, the colour-guard
  and G1–G6 guard descriptions, the dw-2 SSE transport, and rule 14's two
  exceptions.

## server/app/ARCHITECTURE.md
- Delivery bullet: the turn now maps optional `birthData` through
  `_person`, recomputes the chart per turn, and returns `done {mood,
  chartRefs}`.
- Pre-existing omission noticed, not fixed: this doc has no Tier C entry
  for `app/divination` (dw-2 only added the delivery/llm mentions).
  docs/ARCHITECTURE.md carries the full description.

## Spot checks
`natal_context`, `ref_catalogue`, `side_schema`, `to_wire_refs`,
`ChartRefChips`, `isChartRef`, `test_divination_borrows_only_the_restate_helper`
and `PLANET_NAMES` were all grepped present in the code. docs/ARCHITECTURE.md
mentions natal_context, enum, ChartRef and _restate (counts in the command
output below).

## docs/features/dw-3-chart-grounded-reply.md
Written to describe what was actually built. The path is gitignored
(`.gitignore:17 docs/features/`) and was not force-added.

## pipeline/epics/divination-web.md (not committed)
- "Built so far" gains a dw-3 block.
- The dw-2 hooks that dw-3 consumed are rewritten.
- New "Hooks dw-3 leaves" block: dw-4's ref → `data-planet` /
  `data-aspect-key` mapping, and natal_context reuse.
- Reuse map: the natal context row.
- Target modules: dw-3 ✔ on render.py, turn.py, models.py, core
  divination and web chat.
- Event grammar: the exact `done {mood, chartRefs}` shape, and the request's
  `birthData`.
- Dependency rules: the borrow is now a fact, not an "if".

Transition: docs-sync → accepting (coordinator).
