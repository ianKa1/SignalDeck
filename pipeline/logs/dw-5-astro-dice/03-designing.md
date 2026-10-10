# dw-5-astro-dice — 03 designing (revision round 1)

Input: logs/dw-5-astro-dice/02-spec-review.md (FAIL on B1; five non-blocking notes).
Coordinator's instruction: take fix (a).

## Changes to specs/dw-5-astro-dice.md
- B1 (blocking), fix (a):
  - Non-goal reworded to "no side-read change for chat turns; the dice never
    light the wheel; a cast's side read is told so".
  - New Decided default "Dice are not refs". On a cast, `side_prompt` appends a
    registered `side.dice` fragment. It says dice faces are not the person's
    placements, so a planet is cited only where the reply speaks of the
    person's own placement. The fragment joins the fingerprint.
  - Architecture:
    - render registers four fragments;
    - new contract `side_prompt(…, cast=False)`, byte-identical to dw-3's
      when false;
    - turn.py passes `cast is not None` to the side read.
  - New criterion D11: a cast's side system text holds `side.refs` then
    `side.dice`. A chat turn's side prompt is byte-identical to dw-3's
    `side_prompt(message, reply, lang, catalogue)`. A no-birth cast gets the
    mood-only prompt, with no `side.dice`.
  - D10 now lists `side.dice`.
- D2 is concrete: the absent-`action` body and the `"chat"` body are
  byte-equal, and dw-3's existing test_divination_turn.py expectations pass
  unedited.
- D10 and C3 diffs now use `git diff feature/divination_web...HEAD` (the merge
  base), not 2f45dfb.
- `chat.houses` values are the ordinal captions: "1st house"…"12th house" and
  第一宫…第十二宫.
- Shared footprint: dw-6 may touch `useChat.ts`. `packages/core/src/chart/index.ts`
  is listed as no expected conflict.
- `dice.recall` is stated as an English, model-only note, including in zh
  conversations; it is never shown.

## Word counts (wc -w)
- Goal + Non-goals + Decided defaults: 1,491
- Architecture: 1,495
- Acceptance Criteria: 1,172 (budget-exempt)

## Transition
designing (revision 1) → spec-review (round 2), run by the coordinator.
