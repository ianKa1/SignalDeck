# 04 spec-review (round 2) — fresh-context reviewer

## Verdict: FAIL (one concrete defect; D1 and D2 are fixed; everything else holds)

### Round-1 defects
- **D1 fixed.** S1 now binds `r = natal_report(person)` (a dict) and checks `_restate(r["chart"], r["structure"])` and `relevant_meanings(r["chart"], r["structure"])`. Both signatures match the code (report.py:12, prompt.py `_restate(chart, structure)`, natal.py:146).
- **D2 fixed.** The module map lists `transcript.ts (sanitize keeps chartRefs)`, and the core contract says `sanitize` keeps `chartRefs` only when it is a non-empty array after `isChartRef` filtering. That matches today's whitelist in transcript.ts:24-35.

### Checklist
1. **Serves the notes, right-sized: yes.** birthData rides the turn. The context is natal_report + relevant_meanings + the restate helper. chartRefs come from the existing side read (no second call, no prose parsing) and ride `done`. The reply says why. Chips sit under the finished reply. The added pieces (catalogue enum, cap 6, time-unknown rules) exist to make "facts correct" hold. I re-ran the fixture chart: the ten planets, Cancer rising, and aspects that include Chiron, NorthNode and Midheaven, so the catalogue filter is load-bearing. With time unknown there is no ascendant and no Ascendant aspect (S8 holds). The claim "exactly the points the wheel draws" is true: ChartWheel.tsx only draws aspects whose ends are in `pointLongitude`, which holds the planets plus Ascendant.
2. **Criteria checkable: yes.** Tokens `line`/`venus`/`textDim`/`textFaint`/`aspect` exist, as does zh `bodies.Venus` = 金星. A2, A5 and A7 depend on live model output and are checked by inspection, which is acceptable for the real-app loop.
3. **Contract / epic: one defect (D3).** Otherwise consistent. The borrow is the epic's pre-authorised exception, pinned in test_boundaries.py. Rules 6, 9, 12 and 14 are untouched. `done {mood, chartRefs[]}` matches the epic's grammar. The file:lines I checked are accurate: render.py:46/54/63/90, turn.py:157/177, main.py:143, the CLAUDE.md rule-10 divination paragraph (:309).
4. **Non-goals and defaults: yes.** Nothing is left open.

### Defect (must fix)
- **D3: the borrow turns an existing guard red, and the spec does not say what happens to it.**
  - `test_boundaries.py:322` `test_divination_imports_only_llm_prompts_chart_dictionary` asserts `_offenders("divination", DIVINATION_FORBIDDEN_RE) == []`.
  - `_forbidden_imports_re` (:193-207) matches `from app.interpretation.prompt import _restate`. So once render.py gains the borrow, that test fails.
  - The spec keeps the regex unchanged. S10 lists the tests that "still pass" but leaves this one out, and the Amendments say only "add the borrow pin". An implementer then faces a red guard with no ruling, and CLAUDE.md forbids weakening a guard just to make code compile.
  - **Fix:** in Amendments and S10, state that `test_divination_imports_only_llm_prompts_chart_dictionary` is REPLACED by (folded into) `test_divination_borrows_only_the_restate_helper`. The new test runs the same fence over every divination file with the one exact borrow line stripped from render.py, and keeps all six existing self-checks (interpretation / `.. import jobs` / cards bite; llm, prompts, chart pass). S10 should then name the old test as retired, not silently dropped.

### Non-blocking notes
- `isChartRef` needs a VALUE import of `BODIES` from `../chart` (chart/types.ts:1). "Type-only imports from ../chart" applies to the `ChartRef` type only. The plan should say where `isChartRef` lives and that its `BODIES` import goes through the `../chart` barrel.
- The shape and budgets hold. The Goal is three lines and cites the queue. The Architecture section cites the epic and writes only the delta. The "Chips (look)" block is close to component design, but it is visual acceptance material.
- The CLAUDE.md copy in the reviewer's injected context was stale (no dw-1/dw-2 text), so I verified against the file on disk.
