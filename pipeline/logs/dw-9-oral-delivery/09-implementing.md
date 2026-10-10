# 09 implementing — dw-9-oral-delivery, acceptance cycle 1 fix

Trigger: 08-accepting.md, A2 FAIL (25/26). In run 1, Q3 ("Is this
friendship worth saving?") asked two questions: a rhetorical one in slip 3
plus the closing one, which breaks (c). One of its sentences was a maxim
anchored to neither the chart nor the question (borderline (d)). Cycle 1 of 3.

## Fix (prompt only, as the coordinator decided: no server question-mark check, no prose parsing)
In `server/app/divination/render.py`:
- `shape.chat` and `shape.deeper` gain: "Every message except the last is
  made only of statements: no question mark before your closing question,
  not even a rhetorical one."
- `depth.chart` gains: "Every message carries a placement or aspect from
  their chart or a concrete detail of what they asked; a sentence that
  holds neither — a general truth, a maxim, a consolation — does not
  belong."
- `depth.none` gains the same rule in its own terms: "…a concrete detail of
  what they told you or asked…".
- In both `depth.*` fragments, the question clause now reads: "End on one
  question: the only question in your whole reply is one sharp question
  back to them, at the end of your last message; ask nothing anywhere
  else, not even rhetorically." It used to read "exactly one sharp
  question back to them, in your last message, and no other question."
- Shape only, still no sample phrases.

## Tests
- `test_divination_render.py` gains
  `test_acceptance_cycle1_only_one_question_and_every_slip_anchored`. It
  pins the new clauses in both shapes and both depth rules. The existing
  T6 phrase checks still hold unchanged.
- I re-recorded the chart-less goldens from the merged render. The
  fixture diff is 2 lines per file, the `shape.chat` and `depth.none`
  paragraphs. A word diff shows only the wording above
  (`scratchpad/dw9/fixture-cycle1.diff`). The new FINGERPRINT is
  `d73444557626a9d7`.

## Suites
- Server `pytest -q`: `1203 passed, 50 skipped, 1 warning in 105.38s`.
- `npm run typecheck`: 0 `error TS`.
- `npm test`: app-native 90/1069 passed; web-divination 22 files / 212 tests passed.
