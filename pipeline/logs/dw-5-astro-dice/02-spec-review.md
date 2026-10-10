# 02 spec-review (round 1) — fresh-context reviewer

VERDICT: FAIL (one blocking defect; the rest of the spec is sound)

Checked against code on feature/divination_web at 2f45dfb. Verified:
symbols.py:14/27/42, render.py:36/95/144/159/189, turn.py:112/185,
models.py:332/339, core turn.ts:30/57-75, transcript.ts:24/94,
types.ts:53, chart/types.ts:17, glyphs.ts:11/17, useChat.ts:56/100/112,
all named tokens and their CSS vars, the divination fence and
no-state tests (dice.py importing random + app.dictionary passes both),
G5 (web never value-imports chart). Randomness testing is sound: a
stubbed `_RNG` for determinism, an unseeded SystemRandom pinned by
isinstance, a 3,600-roll coverage run (the chance of a miss is
negligible), and a source scan with a self-check.

## Blocking

**B1. The dice faces leak into chartRefs, which contradicts the stated
non-goal.** The non-goal says "The dice are not chart refs and never light
the wheel" and "No change to … the side read". But the brief makes Venus
"name all three faces once, plainly", and the unchanged `side.refs`
(render.py:87) asks the side read for "every placement or aspect the
reply names or plainly relies on". Suppose the dice give Mars and the reply
says "the Mars die…". The side read will very likely return `planet:Mars`.
It is in the catalogue, so `to_wire_refs` keeps it. The chip then reads
"read in your chart: Mars" for a planet the reply never read in the chart,
and dw-4 (built in parallel) lights natal Mars. The chip makes a false
grounding claim in the feature's own demo (A3). Nothing in the spec
prevents this, and no criterion checks it.

Fix (pick one and add a criterion):
(a) Preferred: when `cast` is set, `side_prompt` appends a registered
fragment `side.dice` saying the reply names dice faces, which are not the
person's placements, so it cites a planet only where the reply speaks of
the person's OWN placement. Amend the non-goal to "no change to the side
read for chat turns". Add D11: a cast's side system prompt contains
`side.dice`, and a chat turn's side prompt is byte-identical to dw-3's.
(b) Alternatively, keep the side read unchanged and reword the non-goal
honestly: a die's planet may appear as a chart ref when the side read
judges the reply relied on it. Record this as an accepted limitation.

## Non-blocking

- D2 says "byte-identical to the same dw-3 request". Make that concrete:
  assert the frame sequence and bytes equal dw-3's existing expectation
  in test_divination_turn.py, and that `action` absent equals `"chat"`.
- D10 and C3 diff against `2f45dfb`. If the worker has to merge dw-4 in
  after a squash conflict (serial landing, PIPELINE §Parallel waves 6),
  that diff includes dw-4's files. It still passes today, because dw-4
  leaves App.tsx, tokens and packages alone. Diffing against
  `git merge-base HEAD <working-branch>` would be more robust.
- `chat.houses ("1"…"12")`: state that the values are the ordinal captions
  ("8th house" / "第八宫"). As written, they read like bare numerals.
- The shared-footprint list omits `packages/core/src/chart/index.ts`. It
  is not a wave conflict, but list it for completeness. dw-6 may also
  touch `useChat.ts`, and the dw-6 column does not list it.
- The `dice.recall` template is English inside zh conversations. That is
  acceptable, because it is model-facing only. Say so.

## Checklist

1. Serves the notes and is right-sized. Every queue-note element is present
   (SystemRandom over the dictionary tables, action:"cast" with no new
   route or store, `dice` first, the brief as an asset, button, animation,
   inline card). Re-sending dice for follow-ups is a small justified
   addition. PASS.
2. The criteria are checkable, and randomness is tested properly. The
   LLM-dependent A3 and A5 have a concrete checker procedure. PASS.
3. Contract. Rule 10 fences hold. Rule 14 needs no new exception, and main.py
   is untouched. Rule 5 holds (the server does equality lookups only, the
   client does none). Rule 13 holds (var() only, no new token). Core barrels
   hold, and so does statelessness (no stored or logged faces). The design
   matches the epic (the dice grammar row, dice.py, the brief as an asset).
   The B1 inconsistency is internal to the spec, against its own non-goal
   and dw-4's activation contract. FAIL on B1 only.
4. Non-goals are stated, and every default is decided. PASS.
