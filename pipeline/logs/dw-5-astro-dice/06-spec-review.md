# 06 spec-review (round 3) — fresh-context reviewer

VERDICT: PASS. There are no blocking defects. B1 and B2 are fixed, and the whole spec holds up on a fresh read.

Checked against code on feature/divination_web:
- render.py: `side_prompt` builds `side.role + " " + side.refs` when the catalogue is non-empty (:220–230). That is exactly D11(c)'s expectation. `system_prompt` (:159) and `turn_messages` (:189) have the shapes the contracts extend.
- turn.py `turn_events` (:185): `natal_context` runs before any frame today. Moving the roll ahead of it is what gives D6 its `dice, error` for a natal failure.
- models.py:332/339: there is no existing import guard on models.py. `app.dictionary` is import-free.
- core chart/types.ts: `BODIES` holds exactly the ten planets, so `isDice` rejects Chiron as C1 requires. `SIGNS` (:17) is not on the barrel, as the spec says.
- main.py:437: `StreamingResponse(turn_events(...))` adds no prefix, so D1's "first frame" holds.
- useChat.ts: `run`, `send` and `retry` match the spec's description. A failed turn leaves the user entry, so "Retry re-casts" is well defined.
- `web-divination/src/app/App.tsx` exists at the path C3 names.

## B1 / B2 (prior rounds): fixed

- The `side.dice` fragment is appended whenever dice are in view: on the cast itself, and on any turn whose transcript carries persona dice (`dice_in_view` in turn.py).
- The non-goal now reads "no side-read change for a chat turn whose transcript carries no dice".
- D11(a) covers the cast, D11(b) the follow-up chat with dice in the transcript, and D11(c) keeps a dice-free chat byte-identical to dw-3.
- The round-2 non-blocking items are also addressed:
  - `StrictInt` for the house, with `{house:"8"}` added to D8.
  - D10 drops the hash comparison.
  - The stop-before-first-delta case is stated.

## Non-blocking

- turn.py contract: "the FIRST statement pair is `cast = dice.roll()`…" reads awkwardly beside the existing `deadline = …` line. The intent is clear: roll and yield before `natal_context`. The implementer may leave the deadline line first.
- `streamTurn` yields a `dice` frame even on a chat request. That is harmless, because the server never sends one there, but the spec could say "regardless of action".
- `side.dice` is advisory to an LLM, so D11 only proves that the instruction is present. That dice never become chips is checked only by A3/A5 on the real app. This is an honest limit, and the criteria place it correctly.
- Size: non-AC prose is about 1,496 words, Architecture about 1,498 and AC about 1,271. All are within the pipeline-mode budgets. The shape (Goal, Non-goals, Decided defaults, Architecture, AC) conforms.

## Checklist

1. **Serves the notes, right-sized.** Every element of the queue note is present:
   - SystemRandom over the dictionary tables;
   - `action:"cast"` with no new route or store;
   - `dice` sent first;
   - the brief as a persona asset;
   - the button, the animation and the inline card;
   - interpretation against the question and the chart.

   The recall fold and the re-sent dice are small and justified. PASS.
2. **Checkable.**
   - D1–D11, C1–C3 and W1–W6 are concrete tests with fakes.
   - Randomness is covered by a stubbed `_RNG`, an isinstance pin, a coverage run and a source scan with a self-check.
   - A1–A8 have concrete checker procedures.

   PASS.
3. **Contract and epic.**
   - Rules 3, 5, 6, 9, 10, 12, 13 and 14 hold. main.py and test_boundaries.py are untouched. The only new edge is models.py → the import-free Tier B, which is stated.
   - The design is consistent with the epic's `dice` grammar row, the `dice.py` target and the dice brief in `personas/`.

   PASS.
4. **Non-goals and defaults.** Non-goals are explicit and every open point is decided. PASS.
