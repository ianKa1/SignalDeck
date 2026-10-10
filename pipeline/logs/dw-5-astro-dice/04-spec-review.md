# 04 spec-review (round 2) — fresh-context reviewer

VERDICT: FAIL. One blocking defect: B1's fix covers the cast turn but not the follow-up turn the spec itself demos.

Checked against code on feature/divination_web at 2f45dfb:
- symbols.py:14/27/42: the ten PLANETS, twelve SIGNS and int HOUSES 1–12. The module has no imports.
- core chart/types.ts:17: `SIGNS` is not on the barrel today, as the spec says. divination/types.ts already value-imports `BODIES`.
- glyphs.ts:11/17.
- render.py:144/159/189, turn.py:185 (natal_context runs first today, so moving the roll ahead of it is what D6 needs).
- natal compute: planets carry `body`, `sign` and `house`, and `house` is None when the time is unknown.
- test_boundaries: the no-state regex, the fence, and `turn_events(` counted once in main.py.
- The web G4 guard (a static pentagon polygon does not trip it).
- The web i18n `bodies` and `signs` in zh (冥王星, 天蝎座).

## B1 (round 1): fixed for the cast turn

The `side.dice` fragment, D11 and the amended non-goal ("no side-read change for chat turns") close the leak on the cast itself.

## Blocking

**B2. The dice still reach chartRefs on the follow-up turn, and A5 is exactly that turn.** The recall fold (Decided defaults, "Dice on later turns") exists so that a chat turn can discuss an earlier roll. A5's demo is "What did the planet die mean for me?", and the reply names "the Pluto die". That turn is a chat, so `side_prompt` gets no `side.dice`, and the unchanged `side.refs` asks for every placement the reply names. `planet:Pluto` is in the catalogue, so the chip claims "read in your chart: Pluto", and dw-4 lights natal Pluto. That contradicts the non-goal "The dice … never light the wheel". This is B1's defect, moved one turn later.

Fix: append `side.dice` when `cast is not None or any(e.dice for e in request.transcript)`. Reword the non-goal to "no side-read change for a chat turn whose transcript carries no dice". Extend D11 with two checks:
- a chat turn whose transcript has a persona entry with dice gets `side.refs` then `side.dice`;
- a chat turn with a dice-free transcript stays byte-identical to dw-3's `side_prompt`.

The contract line `side_prompt(..., cast=False)` should then read "dice in view". An alternative is to record follow-up leakage as an accepted limitation and drop "never" from the non-goal. The first fix is preferred.

## Non-blocking

- D8: pydantic's lax `int` coerces `"8"` to 8 on the server, while C1 drops `house:"8"` on the client. Either make `DivinationDice.house` a `StrictInt` and add `{house:"8"}` to D8, or state that coercion is accepted.
- D10's "FINGERPRINT differs from dw-3's value" can only be tested if dw-3's hash is recorded in the test. Say so, or rely on the four `fragments()` assertions alone.
- Stop during a cast before any delta stores nothing, so the rolled card disappears. This follows from dw-2's rule, but state it in one line next to "A stopped cast reply that has text keeps its dice".
- Size: the non-AC prose is within the overrides' roughly 1,500 plus 1,500 words. Shape (Goal, Non-goals, Decided defaults, Architecture, AC) conforms.

## Checklist

1. **Serves the notes, right-sized.** Every element of the queue note is present. The re-sent dice and the recall fold are a small, justified addition. PASS.
2. **Checkable.** D1–D11, C1–C3 and W1–W6 are concrete. A3 and A5 carry a checker procedure. Randomness is tested properly: a stubbed `_RNG`, an isinstance pin, a coverage run, and a source scan with a self-check. PASS.
3. **Contract and epic.**
   - Rules 5, 9, 10, 12, 13 and 14 hold: main.py and test_boundaries are untouched, and the new edge models.py → the import-free Tier B is stated and harmless.
   - It matches the epic's `dice` grammar row and the `dice.py` target.
   - B2 is internal: the spec contradicts its own non-goal, and through that dw-4's activation contract.
   - FAIL on B2 only.
4. **Non-goals and defaults.** Non-goals are stated and every default is decided. PASS.
