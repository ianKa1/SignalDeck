# 06 spec-review (round 3) — fresh-context reviewer

## Verdict: PASS

### Prior defects
- **D1 fixed.** S1 binds `r = natal_report(person)` (a dict) and compares against `_restate(r["chart"], r["structure"])` and `relevant_meanings(r["chart"], r["structure"])`. That matches report.py:12-27 (the function takes a kwargs dict and returns `{"chart","structure"}`), prompt.py:46 `_restate(chart, structure)`, and the `app.dictionary` export.
- **D2 fixed.** The module map lists `transcript.ts (sanitize keeps chartRefs)`, and the core contract states the non-empty-after-`isChartRef` rule. Today's `sanitize` whitelist (transcript.ts:24-35) confirms the edit is needed.
- **D3 fixed.** The Amendments and S10 now RETIRE `test_divination_imports_only_llm_prompts_chart_dictionary` (test_boundaries.py:322) into `test_divination_borrows_only_the_restate_helper`. The new test keeps all six self-checks, strips only the one exact borrow line in render.py, requires that line to occur exactly once, and leaves `DIVINATION_FORBIDDEN_RE` byte-identical. The rule is not weakened. The fence still bites anywhere else, and the planted-offender self-checks prove it.

### Checklist
1. **Serves the notes, right-sized: yes.** Every note item maps to a default and a criterion:
   - birthData rides the turn;
   - the context is built from natal_report + relevant_meanings + the restate helper;
   - chartRefs come from the existing side read, with no prose parsing, and ride `done`;
   - the reply says "why";
   - chips sit under the finished reply;
   - the loop closes in A2/A3.

   The catalogue enum, the cap of 6 and the time-unknown rules all serve "facts correct". None of it is invented scope.
2. **Criteria checkable: yes.** S1–S11, C1–C3 and W1–W4 run with fakes and a real ephemeris chart. A1–A7 run in the real app. A2, A5 and A7 depend on live model output and are checked by inspection, which is acceptable for the loop criterion. I verified the references:
   - tokens `line`/`venus`/`textDim`/`textFaint`/`aspect` exist;
   - the web `bodies` namespace, including `Ascendant`, exists;
   - the Placements panel exists;
   - the wheel exposes `data-planet` and `data-aspect-key`, and draws aspects only between planets and the Ascendant (ChartWheel.tsx:72-75, 170-171);
   - `BirthData` has the date and timezone validators S7 relies on (models.py).
3. **Contract / epic: consistent.** The `_restate` borrow is the epic's pre-authorised exception, pinned in test_boundaries.py. `interpretation/__init__.py` is empty and prompt.py imports only `..chart.natal`, so the borrow is shallow. The rule-10 amendment targets the real divination paragraph (CLAUDE.md:309-316). Rules 6, 9 and 12 are untouched: no state, and the chart is recomputed per turn. Rule 14 is also untouched: the chart compute is not generative, main.py keeps one `turn_events(` call, and the docstring keeps its slug and test name. The web keeps the barrel, network and arithmetic guards. The `done {mood, chartRefs[]}` shape matches the epic grammar. The reuse file:lines I checked are accurate: main.py:143/420, models.py:43, render.py:46/54/63/90, turn.py:157/177, and the core `BODIES`/`AspectPoint`/glyph barrel exports.
4. **Non-goals and defaults: yes.** Non-goals are explicit and nothing is left open.

### Non-blocking notes (for the plan)
- Existing dw-2 tests will need their expectations updated, because the wire deliberately changes:
  - test_divination_turn.py asserts `("done", {"mood": "tender"})` exactly (lines 101, 136, 166, 282);
  - it calls `turn.turn_events(request)` with one argument (line 268);
  - test_divination_render.py:72 calls the 3-argument `side_prompt`.

  The plan should list these edits. This follows from the spec's intended change and does not weaken a guard.
- The module map registers `chart.marker`, but S11 names only three fragments. This is harmless, but the plan could make the two agree.
- "The ten `chart["planets"]` bodies": the server's `planets` may carry more than the ten `BODIES`. The catalogue must filter to `BODIES`, and S5 already pins "no Chiron/NorthNode". Say this explicitly in the plan.
- Shape and budget hold. The Goal is three lines. Goal, non-goals and defaults come to about 1,200 words. Architecture is about 1,300 words, cites the epic and writes only the delta.
