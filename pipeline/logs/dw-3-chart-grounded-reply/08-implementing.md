# 08 — implementing (dw-3-chart-grounded-reply)

Worker run, primary checkout, branch `feature/dw-3-chart-grounded-reply`.
Fresh start: no plan box was ticked.

## Step 1 — render: chart context, catalogue, side schema, borrow fence

- dw-2 FINGERPRINT captured before any edit: `5c9f50cbc874475f`
  (`conda run -n astrology python -c "from app.divination import render; print(render.FINGERPRINT)"`),
  pinned as `DW2_FINGERPRINT` in `test_divination_render.py`.
- `server/app/divination/render.py`: registered `chart.none`, `chart.read`,
  `chart.marker`, `side.refs`; added `NatalContext`, `ref_catalogue`,
  `natal_context`, `side_schema`, `to_wire_refs` (REFS_MAX 6); threaded `ctx`
  through `system_prompt`/`turn_messages` (optional, default None) and the
  catalogue through `side_prompt` (now 4 args). Imports `natal_report`,
  `PLANET_NAMES` (D2), `relevant_meanings`, and the one borrow line.
- `personas/venus.txt`: "You have not read their birth chart yet…" bullet
  removed (it now lives in `chart.none`).
- `turn.py`: minimal compile fix only — `side_prompt(..., {})` so the suite
  stays green until step 2.
- `test_boundaries.py`: `test_divination_imports_only_llm_prompts_chart_dictionary`
  retired into `test_divination_borrows_only_the_restate_helper`;
  `DIVINATION_FORBIDDEN_RE` untouched (not in the diff).
- CLAUDE.md rule 10: the one pinned borrow.

Checks:
- `conda run -n astrology pytest tests/test_divination_render.py tests/test_boundaries.py tests/test_prompts.py -q`
  → `61 passed in 0.69s`
- Hand plant `from app.interpretation.prompt import _LANG_INSTRUCTIONS` appended
  to render.py → `1 failed, 20 deselected` (-k restate); reverted.
- Hand plant `from app.interpretation.prompt import _restate` appended to
  turn.py → `1 failed, 20 deselected`; reverted.
- Full server: `1020 passed, 50 skipped, 1 warning in 101.08s`.
- Root `npm test`: jest green, vitest `Test Files 13 passed (13) / Tests 57 passed (57)`.

Commit: `7a2aa51` (feat): … render builds the natal context, ref catalogue and side schema; the _restate borrow is pinned

## Step 2 — turn, request model, route

- `models.py`: `DivinationTurnRequest.birthData: BirthData | None = None`.
- `main.py`: `person = _person(request.birthData) if request.birthData else None`;
  still exactly one `turn_events(` call; docstring "birth-data-free" →
  "birth data rides each turn … and the chart is recomputed per turn;
  nothing kept"; `done {mood, chartRefs}` in the docstring.
- `turn.py`: `turn_events(request, person)`; `render.natal_context` built at
  the top of the generator (failure → `error{unavailable}`, logged, before
  any worker is submitted); `_side_read` takes the catalogue, uses
  `render.side_schema`, returns `(mood, refs)` via `render.to_wire_refs`;
  any failure/timeout/non-dict → `(None, [])`; `done` always carries both keys.
- dw-2 tests edited per plan (every exact `done` gains `"chartRefs": []`;
  `turn_events(request, None)`). New tests: dw3 S1, S2 (absent + null), S3,
  S4 end-to-end, S5, S6 (unavailable, non-list, timeout at 1.5 s), S7 (three
  422s, fakes never called), S8, S9 (TestClient `POST /api/chart`), plus a
  context-failure → SSE error test.
- CLAUDE.md rule 10: "Birth data rides each turn (dw-3) and the chart is
  recomputed per turn, never stored."

Checks:
- `pytest tests/test_divination_turn.py tests/test_boundaries.py tests/test_divination_render.py -q` → `78 passed, 1 warning in 3.46s`
- `npm run server:test` → `1035 passed, 50 skipped, 1 warning in 102.17s`
- `npm test` → jest `Tests: 1069 passed, 1069 total` (with the usual
  "worker process has failed to exit gracefully" notice); vitest `Tests 57 passed (57)`.

Commit: `382bd2f` (feat): … turns take optional birthData, ground Venus in the chart and send validated chartRefs on done

## Step 3 — core `divination`: ChartRef, birthData, refs that persist

- `types.ts`: `ChartRef` (type-only `AspectPoint/AspectType/Body` from
  `../chart`; `BODIES` as a value import from the `../chart` barrel),
  `TurnRequest.birthData: BirthData | null` (type-only from `../birth-data`),
  `done.chartRefs`, `TranscriptEntry.chartRefs?`, `isChartRef`, and a
  module-internal `chartRefsOf` (non-array → []). The aspect-type check is a
  `Record<AspectType, true>` so a new AspectType fails to compile (no
  runtime list of aspect types existed in core to reuse).
- `turn.ts`: `done` carries `chartRefsOf(data.chartRefs)`.
- `transcript.ts` `sanitize`: keeps `chartRefs` only when non-empty after
  filtering. `toWire` unchanged (`{role, text}`).
- `index.ts`: exports `ChartRef`, `isChartRef`.
- STEP-ORDER NOTE: making `birthData` required on `TurnRequest` turned the
  root typecheck red at `useChat.ts`, and step 3's done-when requires it
  green, so `useChat`'s two data edits (send `getBirthData()` at `run` start;
  keep non-empty `chartRefs` on the finished persona entry) landed here
  instead of step 4. Step 4 keeps the chips, i18n and W tests.
- Test edits for the wire change: `core-divination.test.ts` `REQ` gains
  `birthData: null` and three `done` expectations gain `chartRefs: []`
  (per plan); `ChatPanel.test.tsx` dw-2 W1 request-body equality gains
  `birthData: null` (same wire change, not listed in the plan's notes).
  New: C1 (pass-through, missing/non-array → [], malformed items dropped,
  request body birthData object/null) and C2 (fresh-KV round trip,
  malformed/empty dropped, toWire has no chartRefs).

Checks:
- `npx vitest run src/chat/core-divination.test.ts` → `19 passed (19)`
- `npm run typecheck` (root) → 0 `error TS`
- `npm test` → jest `1069 passed, 1069 total`; vitest `Tests 64 passed (64)`

Commit: `42a77b6` (feat): … core ChartRef on done and in the transcript; turns send the saved birth data

## Step 4 — web: the chips (frontend-design loaded first)

- `chat/ChatPanel.tsx`: `ChartRefChips` (in the same file, per the module
  map) renders `div.chat__refs` → an eyebrow (aria-hidden) + `ul.chat__refs-list`
  (`aria-label` = `chat.refsLabel`) after the prose and before the mood tag,
  only for a stored, non-stopped persona entry with non-empty `chartRefs`.
  Planet chip: glyph (venus) + translated name (textDim). Aspect chip: glyph
  A, aspect glyph in `--aspect-<type>` (modifier classes, class selectors
  only), glyph B, "A–B" names; `aria-label` = bodies + `chat.aspects` joined
  by a space in en and nothing in zh (plan D4). Glyphs from
  `@astrace/core/chart-view` (`PLANET_GLYPHS`, `ASPECT_GLYPHS`,
  `ASCENDANT_GLYPH`); `AspectPoint` is a type-only import from
  `@astrace/core/chart` (G5 stays: useChart is the only value importer).
  `Entry` now takes the whole `dict` (it needs `bodies`).
- `chat/chat.css`: engraved-seal chips — 1px `var(--line)` border, 2px
  radius, tight padding, `--font-body` 0.82rem, small-caps eyebrow in
  `--text-faint`; `chat-seal` keyframe fades up 4px, staggered 60ms by
  inline `animationDelay`; `.chat__ref` joins the reduced-motion `animation:
  none` block (the global reduced-motion rule also zeroes delays). No new
  colour token. `font-variant-emoji: text` keeps the glyphs from rendering as
  emoji where supported.
- `i18n/{en,zh}.ts`: `chat.refsLabel` ("read in your chart" / "星盘所见"),
  `chat.aspects` (en the five names; zh 合/六合/刑/拱/冲).
- Tests: `ChatPanel.test.tsx` W1 (saved birth data deep-equals the body;
  after `clearBirthData()` → null), W2 en + zh (order, glyphs, aria-labels
  "Venus opposition Pluto" / "金星冲冥王星", position between prose and mood,
  KV stores the refs), W3 (empty → no list and no stored key; stopped → no
  list; remount from KV → same chips, dw-2-shaped entry → none; chips absent
  while streaming), W4 (no button, no tabindex, no focusable). `i18n.test.ts`
  binds `chat.aspects` to `Record<AspectType, string>` in both languages.

Checks:
- `npx vitest run` (web) → `Tests 72 passed (72)`
- `npm run typecheck` → 0 `error TS`
- `npm test` → jest `1069 passed, 1069 total` (architecture, colour, i18n
  guards included); vitest `72 passed (72)`
- `npm run server:test` → `1035 passed, 50 skipped, 1 warning in 102.66s`

Status: implementing complete (steps 1–4) → validating.
