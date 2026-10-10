# dw-5-astro-dice — 05 designing (revision round 2)

Input: logs/dw-5-astro-dice/04-spec-review.md (FAIL on B2, plus non-blocking notes).

## Changes to specs/dw-5-astro-dice.md

**B2 (blocking).** `side.dice` is now appended whenever dice are in view:
`dice_in_view = cast is not None or any(e.dice for e in request.transcript)`.
- The non-goal now reads: no side-read change for a chat turn whose
  transcript carries no dice.
- The "Dice are not refs" default covers casts AND any turn that has a persona
  entry with dice.
- The `side_prompt` contract takes `dice_in_view=False`. With it false, the
  output is byte-identical to dw-3's.
- D11 now covers three cases:
  - (a) a cast;
  - (b) a chat turn whose transcript carries dice (D7's transcript) gets
    `side.refs` then `side.dice`;
  - (c) a dice-free chat turn's system text equals
    `side.role + " " + side.refs` exactly, and its user JSON equals the
    default `side_prompt` output.

**Same-class re-check across the whole spec.** Refs are shaped only from the
side read, and the side read is the one place a die face could turn into a
ref. Dice reach the model on three paths:
- the cast prompt;
- the recall note;
- stopped cast entries that are re-sent with their dice.

All three set `dice_in_view`. The client derives no refs, and dw-4 lights
only `chartRefs`. So no other leak path remains.

Real-app A3 and A5 now also require that chips name only placements the
reply speaks of as the user's own. A planet named only as a die gets no chip.

**Non-blocking notes, all taken:**
- `DivinationDice.house` is a StrictInt. D8 adds `{house:"8"}` → 422, which
  matches the client's `isDice`.
- D10 drops the "differs from dw-3" hash clause. It relies on the
  `fragments()` assertions (four fragments, and `dice.venus` equals the
  asset). Decided because the fingerprint hashes every fragment, so a recorded
  hash would add nothing.
- A cast stopped before its first delta stores nothing, so its card
  disappears. This is stated in one line.

**Trims to stay in budget:**
- the fixture line was shortened;
- the cast-button disabled line was merged;
- the "mechanical merge" sentence was dropped.

## Word counts (wc -w)
- Goal + Non-goals + Decided defaults: 1,496
- Architecture: 1,498
- Acceptance Criteria: 1,271 (budget-exempt)

## Transition
designing (revision 2) → spec-review (round 3, final), run by the coordinator.
