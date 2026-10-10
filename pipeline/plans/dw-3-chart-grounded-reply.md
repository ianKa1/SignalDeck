# Implementation Plan: dw-3-chart-grounded-reply

Spec: `pipeline/specs/dw-3-chart-grounded-reply.md` (WHAT + Architecture,
PASS in `logs/dw-3-chart-grounded-reply/06-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Branch `feature/dw-3-chart-grounded-reply`.
Steps 1–4 are `implementing`, 5 is `validating`, 6 is `docs-sync`. Tick a box
only after its done-when passed and its `/git-commit` landed
(`(<type>): dw-3-chart-grounded-reply — <summary>`). Load `/frontend-design`
before step 4. Automated tests fake `llm.stream_turn` and
`llm.generate_sections` only; the chart is real (Swiss Ephemeris, fixture
birth from the spec's Acceptance preamble). Server commands run from
`server/` as `conda run -n astrology pytest -q …`.

## Settled review notes

- **dw-2 tests that change with the wire** (edited in the step that changes
  the wire, not weakened):
  - `server/tests/test_divination_turn.py` lines 101, 136, 166, 282: every
    exact `("done", {"mood": …})` gains `"chartRefs": []` (step 2);
  - same file, line 268: `turn.turn_events(request)` becomes
    `turn.turn_events(request, None)` (step 2);
  - `server/tests/test_divination_render.py:72`: the three-argument
    `side_prompt(…, "en")` gains an empty catalogue as its fourth argument,
    and still asserts the dw-2 user JSON and `side.role` text (step 1);
  - `web-divination/src/chat/core-divination.test.ts` lines 67, 81, 112:
    `done` expectations gain `chartRefs: []`; its `REQ` fixture gains
    `birthData: null`, so line 70's body equality still holds (step 3).
- **`chart.marker` vs S11.** `chart.marker` IS registered on the
  `divination` topic, alongside `chart.read`, `chart.none` and `side.refs`.
  The S11 test asserts all four keys are registered (a superset of the three
  S11 names) and that `FINGERPRINT` differs from dw-2's value (see D1).
- **The catalogue's ten bodies.** `ref_catalogue` keeps only
  `chart["planets"]` entries whose `body` is in the ten classical bodies
  (`app.chart.points.PLANET_NAMES`), and only aspects whose two ends are in
  that set or are `Ascendant`. Today `planets` holds only the ten, but the
  filter is explicit, so a future point (nodes, Chiron) or the Midheaven
  never becomes chip-able. S5 pins this with its no-Chiron/NorthNode/Midheaven
  check.

## Steps

- [x] **1. Render: chart context, catalogue, side schema, and the borrow fence.**
  Files: `server/app/divination/{render.py,personas/venus.txt}`,
  `server/tests/test_divination_render.py`, `server/tests/test_boundaries.py`,
  `CLAUDE.md` (rule 10, divination paragraph: the one pinned borrow).
  Register the four fragments. Add `natal_context`, `ref_catalogue`,
  `side_schema` and `to_wire_refs`. Thread the context through
  `system_prompt`/`turn_messages`/`side_prompt` as the spec's contracts say.
  Retire `test_divination_imports_only_llm_prompts_chart_dictionary` into
  `test_divination_borrows_only_the_restate_helper`.
  Done when: `pytest tests/test_divination_render.py tests/test_boundaries.py tests/test_prompts.py -q`
  is green (the S4 cap, the S8 catalogue with no Ascendant, S10, S11). Planting
  `from app.interpretation.prompt import _LANG_INSTRUCTIONS` in render.py
  turns it red, and so does moving the `_restate` import into turn.py (check
  by hand, then revert).

- [x] **2. Turn, request model, and route.**
  Files: `server/app/models.py` (`birthData: BirthData | None = None`),
  `server/app/divination/turn.py`, `server/app/main.py` (pass
  `_person(request.birthData)` or `None`; the docstring says "birth data
  rides each turn; nothing kept" and keeps the test name),
  `server/tests/test_divination_turn.py` (the dw-2 edits above, plus the
  grounding tests), `CLAUDE.md` (rule 10: birth data rides each turn, and the
  chart is recomputed per turn and never stored).
  The context is built before the worker is submitted. The side read returns
  `(mood, refs)`, and `done` always has both keys.
  Done when: `pytest tests/test_divination_turn.py tests/test_boundaries.py -q`
  covers S1–S3 and S5–S9. S9 uses a TestClient `POST /api/chart` with the
  same birth. `npm run server:test` at the root is green.

- [x] **3. Core `divination`: ChartRef, birthData, and refs that persist.**
  Files: `packages/core/src/divination/{types.ts,turn.ts,transcript.ts,index.ts}`,
  `web-divination/src/chat/core-divination.test.ts` (the dw-2 edits above,
  plus C1 and C2; dw-2 Deviation D1 still applies, so core seams are tested
  in the web vitest tree).
  Add `ChartRef` and `isChartRef` (in types.ts, exported from the barrel).
  `streamTurn` filters `done.chartRefs`, defaulting to `[]`. `sanitize`
  keeps a non-empty filtered `chartRefs`. `toWire` stays `{role, text}`.
  Done when: in `web-divination`, `npx vitest run src/chat/core-divination.test.ts`
  is green for C1 and C2, and root `npm run typecheck` is green.

- [x] **4. Web: send birth data, and the chips.**
  Files: `web-divination/src/chat/{useChat.ts,ChatPanel.tsx,chat.css,ChatPanel.test.tsx}`,
  `web-divination/src/i18n/{en.ts,zh.ts}` (`chat.refsLabel`, and
  `chat.aspects` keyed by the five `AspectType`s).
  `useChat` reads `getBirthData()` when `run` starts, which covers Retry,
  and stores non-empty refs on the finished persona entry. `ChartRefChips`
  renders as a `ul` after the prose and before the mood tag, with no
  buttons and no tabindex. The CSS uses `var(--line)`, `var(--venus)`,
  `var(--text-dim)`, `var(--text-faint)` and `var(--aspect-<type>)`. The
  staggered fade-up is off under reduced motion.
  Done when: `ChatPanel.test.tsx` covers W1–W4. W1 seeds birth data through
  core's birth-data store. Root `npm test`, `npm run typecheck` and
  `npm run server:test` pass, and the C3 guards (barrels, network, arithmetic,
  colour, en/zh parity in `src/i18n.test.ts`) are green.

- [x] **5. Validating prep and the real-app run (A1–A7).**
  Leave :8000 alone; another checkout holds it. Backend, from the repo root:
  `CORS_ALLOW_ORIGINS=http://localhost:5173 ANALYSIS_LLM=claude-cli conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001`.
  Web: `VITE_API_BASE=http://localhost:8001 npm run web` on :5173 (the port
  is strict, so free it first). Enter the fixture birth. Drive the app with
  claude-in-chrome:
  - `read_network_requests` for A1 and A6;
  - `innerText` samples while streaming, then after `done`, for A2 and A3;
  - `document.querySelector` on `data-planet` and `data-aspect-key`, plus the
    chip border's computed colour, for A3;
  - reload for A4, the language toggle for A5, and the time-unknown checkbox
    for A7.
  Done when: A1–A7 are observed and recorded in the validating log, with A2's
  claims listed beside the chart values. Both processes are stopped
  afterwards.

- [x] **6. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (via `/update-architecture-doc`),
  `docs/features/dw-3-chart-grounded-reply.md`, and
  `pipeline/epics/divination-web.md` ("Built so far", "Target modules", the
  `done {mood, chartRefs}` shape and the `_restate` borrow).
  Done when: the docs name `natal_context`, the catalogue enum, `ChartRef`,
  and the pinned borrow, and `git diff --stat main -- docs` shows the edits.

## Acceptance map

| Criterion | Step |
|---|---|
| S1 grounded prompt order + chart JSON | 1 (builder), 2 (through the route) |
| S2 no chart → `chart.none`, MOOD_SCHEMA, `chartRefs: []` | 2 |
| S3 refs validated (dupes, unknown, off-chart) | 1 (`to_wire_refs`), 2 (end to end) |
| S4 cap of 6 | 1 |
| S5 side read gets the catalogue enum and user JSON | 1 (schema, catalogue), 2 (fake receives it) |
| S6 degradation (unavailable, timeout, non-list) | 2 |
| S7 birthData 422s, fakes uncalled | 2 |
| S8 time unknown | 1 (catalogue), 2 (prompt JSON) |
| S9 every ref is in `/api/chart` | 2 |
| S10 boundaries, borrow fence, regex byte-identical | 1 |
| S11 fingerprint moves, persona drops "have not read" | 1 |
| C1 `streamTurn` refs + request `birthData` | 3 |
| C2 transcript round-trip, sanitize, `toWire` | 3 |
| C3 existing guards + root suites | 4 |
| W1 birthData on the wire | 4 |
| W2 chips render, en + zh | 4 |
| W3 empty/stopped/reload | 4 |
| W4 not buttons, not focusable | 4 |
| A1–A7 real app | 5 |

## Deviations (for journaling)

- **D1: `chart.marker` is a fourth registered fragment.** S11 names three.
  The S11 test asserts all four, so the module map and the criterion agree.
- **D2: the ten-body source is `app.chart.points.PLANET_NAMES`.** It is the
  chart tier's own list, and divination may already import `app.chart`. No
  local tuple is added. The spec said "the ten `chart["planets"]` bodies"
  without naming a source.
- **D3: catalogue order.** The planets come first, in `chart["planets"]`
  order, then the aspects in `chart["aspects"]` order (not the restatement's
  orb order). The enum and `to_wire_refs` both follow it. The reply's own
  order comes from the model's list, not from the catalogue.
- **D4: aspect-phrase joining is per language, with no new i18n key.** In en
  the parts are joined with spaces ("Venus opposition Pluto"). In zh they
  are joined with no separator (金星冲冥王星). The join is chosen by the
  current `lang`, so `chat.aspects` holds only the five names, as the spec
  requires. The visible names use an en dash in both languages.

## Risks for the implementer

- **The schema enum is advisory.** `generate_sections` checks only that the
  required keys are present. The claude-cli path may not enforce enums at
  all. `to_wire_refs` is the real filter: it must tolerate a non-list,
  non-string items and unknown ids (S6, S3).
- **The aspect id must come from `chart["aspects"]`, not the restatement.**
  The restated `a`/`b` keep the same order but are sorted by orb. Building ids
  from the raw chart keeps `aspectKey` equal to the web wheel's
  `data-aspect-key`.
- **Errors after the stream opens are SSE errors.** A `natal_report` failure
  inside the generator comes after the 200 has gone out. It must yield
  `error{unavailable}`, not raise. Pydantic's 422s all happen before the
  generator runs.
- **Do not hand-compute the fixture.** Beijing observed DST in 1990, so
  08:30 is UTC+9. Assert against `natal_report` output and S3's pre-check
  (no Venus–Mars square), never against constants you derived yourself.
- **The system prompt uses `sort_keys`.** S1 compares the parsed JSON, not
  bytes, so key reordering is fine. Split the text at the marker to get the
  JSON, which must run up to the lang line.
- **Keep the rule-14 pin intact.** `test_main_names_the_synchronous_exceptions`
  reads main.py's docstrings. Edit only the "birth-data-free" phrase, and
  keep exactly one `turn_events(` call.
- **Chips appear on `done`, not during streaming.** The streaming bubble is
  React state in `useChat`. Chips attach only to the appended persona entry,
  so A3's "not while it streams" holds as long as streaming text never
  renders the chips component.
- **Barrel and value imports.** `BODIES` is a VALUE import from
  `../chart` inside core. The web chips take glyphs from
  `@astrace/core/chart-view` only. The G1 guard also walks test files.
