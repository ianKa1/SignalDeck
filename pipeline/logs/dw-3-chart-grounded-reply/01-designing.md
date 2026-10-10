# 01 designing: dw-3-chart-grounded-reply

Stage worker for the coordinator, on branch `feature/dw-3-chart-grounded-reply`.
Nothing was committed, because `pipeline/` is gitignored.

## Reads
- CLAUDE.md. Rule 10's divination paragraph is at :309-316, and rules 1, 3
  and 14 as dw-2 amended them.
- PIPELINE.md: status table, Skills per stage, pipeline-mode overrides, Epic
  files, Spec requirements, Auto spec review.
- QUEUE.md: the epic comment and the dw-3 entry.
- epics/divination-web.md, cited rather than re-surveyed.
- specs/dw-2-venus-chat.md and logs/dw-2-venus-chat/10-final-review.md.
- DECISIONS.md from "2026-09-28 · divination-web epic" (:3105) to the end.
- Targeted server reads:
  - `divination/{render,turn,__init__}.py` and `personas/venus.txt`;
  - `models.py` (`BirthData` :43, `DivinationTurnRequest` :339);
  - `main.py` (`_person` :143, `/api/chart` :154, turn route :420);
  - `chart/natal/report.py` and `dictionary/natal.py` `relevant_meanings`
    :146;
  - `interpretation/prompt.py` `_restate` :46 (imports only `..chart.natal`;
    `interpretation/__init__.py` is empty);
  - `llm.generate_sections` :857;
  - `test_boundaries.py` divination fences :306-367.
- Targeted client reads:
  - core `divination/{types,turn,index}.ts`, `chart/types.ts`,
    `chart-view/aspect-set.ts` and the glyph exports, `birth-data` barrel;
  - web `session.ts`, `chart/ChartWheel.tsx` (the `data-planet` and
    `data-aspect-key` attributes, and `pointLongitude`, which holds the
    planets plus Ascendant only), `chat/useChat.ts`, `ChatPanel.tsx`,
    `chat.css`, `i18n/en.ts`, `theme/tokens.ts`.
- Probe run: `natal_report` of the fixture birth, 1990-06-15 08:30
  Beijing.
  - The restatement is 18.3k characters and the meanings 6.9k characters.
  - Venus is in Taurus in house 10, Venus opposes Pluto, and the rising
    sign is Cancer.
  - The server's aspects include Chiron, NorthNode and Midheaven ends. The
    wheel does not draw these, and core's `AspectPoint` type does not have
    them.

## Skills invoked (in order)
1. `frontend-design`. It set the chips' look: engraved-seal chips on a
   hairline gold border, glyph in `venus`, aspect glyph in its aspect
   token, staggered fade-up, no new tokens, static in dw-3.
2. `feature-spec`, in pipeline mode: Goal, Non-goals, Decided defaults,
   Acceptance Criteria.
3. `architecture-designer`, in pipeline mode: the Architecture section only,
   delta only, no Migration Steps.

## Key choices
- **Restate helper: borrowed, not moved or duplicated.** It is one pinned
  import line in `divination/render.py`. It is carved out by a new test,
  `test_divination_borrows_only_the_restate_helper`, not by widening the
  regex. That test also pins interpretation/prompt.py's shallow imports.
  Moving it would edit interpretation's byte-frozen, deliberately placed
  helper. Duplicating it would drift from the natal reading's view.
- **chartRefs come from the existing mood side read.** One call now returns
  `{mood, chartRefs}`, using a per-chart enum catalogue. The server then
  filters them against the catalogue, dedupes them and caps them at 6. They
  are never parsed from the prose, and no second model call is added.
- **The catalogue is only what the wheel can address.** That is the ten
  planets, plus aspects whose ends are planets or the Ascendant.
- **Wire shape:** `done {mood, chartRefs:[{kind:"planet",body} |
  {kind:"aspect",bodyA,type,bodyB}]}`. `chartRefs` is always present. The
  aspect uses the chart's own a/b order, so dw-4 does
  `aspectKey(matching aspect)` and gets `data-aspect-key` with no parsing.
  No key string is sent, to avoid a second definition of aspect identity.
- **Birth data on the turn:** `birthData: BirthData | None = None` reuses
  the `/api/chart` model. main.py passes `_person(...)` into
  `turn_events(request, person)`, so the pin's single `turn_events(` call
  still holds. The chart is recomputed each turn, and nothing is stored.
- **Persona:** the "not read your chart" paragraph moves into a
  `chart.none` fragment, and a new `chart.read` fragment grounds the answer
  and handles an unknown birth time.
- **Client:** refs are stored on the persona entry in KV and are never sent
  back on the wire. `isChartRef` filters them in core. The chips are
  static; dw-4 makes them interactive.
- **Fact checks:**
  - Tests compare the prompt JSON with `_restate(natal_report(fixture))`
    and every ref with `/api/chart`, all with fake providers.
  - In the real app (claude-cli, :8001), each claim in the reply is checked
    against the Placements panel and the wheel, and each chip is checked
    against the DOM `data-*` attributes.

## Word counts (`wc -w`)
- Spec without criteria (Goal, Non-goals, Decided defaults, excluding
  Architecture): 1,201.
- Architecture: 1,313.
- Criteria: about 985.

## Transition
designing → spec-review. The spec is at
`pipeline/specs/dw-3-chart-grounded-reply.md`.
