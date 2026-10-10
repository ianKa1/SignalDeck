# 02 spec-review (round 1) — fresh-context reviewer

## Verdict: FAIL (two small, concrete defects; everything else holds)

### Checklist

1. **Serves the notes, right-sized: yes.** Every note item is covered: birthData rides the turn; context comes from natal_report + relevant_meanings + interpretation's restate helper; chartRefs come from a structured side read (never parsed from prose) and ride `done`; the reply explains why; chips sit under the finished reply; the loop closes (A2/A3). The choices it adds (catalogue enum, cap 6, Ascendant as an aspect end, the time-unknown handling) are needed to make "facts correct" hold, not invented scope. I verified the fixture facts by computing the chart: Venus Taurus H10, Moon Pisces H8, Mars Aries H9, Venus opposition Pluto, Cancer rising. I also confirmed that chart aspects really do include Chiron, NorthNode and Midheaven, so the catalogue filter is load-bearing.
2. **Criteria checkable: one defect (D1).** Everything else can be checked with fakes, a real chart or the real app.
3. **Contract / epic consistency: consistent, with one gap in the Architecture section (D2).** The `_restate` borrow is exactly the exception the epic pre-authorised ("the spec must pin it in test_boundaries.py"). It is pinned without widening `DIVINATION_FORBIDDEN_RE`, and the rule-10 amendment targets the real divination paragraph (CLAUDE.md:309-316). I checked the claim that `interpretation/prompt.py` imports only `..chart.natal`, and that `interpretation/__init__.py` has no imports. Both hold. Rules 6, 9, 12 and 14 are untouched: no state, identity-free, and the side read stays inside the existing bounded stream. The `done {mood, chartRefs[]}` shape matches the epic's event grammar. The reuse file:lines I checked are accurate: report.py:12, models.py:43, main.py:143/420, render.py:46/54/63/90, turn.py:157/177, llm.py:857, aspect-set.ts:17, `ASCENDANT_GLYPH`, `BODIES` = ten planets, five `AspectType`s, `AspectPoint = Body | 'Ascendant'`.
4. **Non-goals and decided defaults: yes.** Non-goals are explicit. There is no open question left undecided.

### Defects (must fix)

- **D1: S1 is wrong as written.** `_restate(*natal_report(person))` unpacks a dict. `natal_report` (chart/natal/report.py:26) returns `{"chart": …, "structure": …}`, so the star-unpack passes the two key STRINGS, and `_restate` raises. The criterion cannot pass literally. **Fix:** "its `chart` equals `_restate(r["chart"], r["structure"])` where `r = natal_report(person)`, and its `meanings` equals `relevant_meanings(r["chart"], r["structure"])`." The Module contracts line "`natal_context` … `restated`, which is `_restate(chart, structure)`" is fine.
- **D2: the module map omits `packages/core/src/divination/transcript.ts`.** Its `sanitize()` (transcript.ts:24-35) whitelists fields: it copies `role`/`text`, then only `mood` and `stopped`. Without an edit there, stored `chartRefs` are dropped on read, and C2, W3 and A4 fail. **Fix:** add `transcript.ts` to the core line of the module map, with the contract "sanitize keeps `chartRefs` when it is a non-empty array, filtered through `isChartRef`; otherwise omits it."

### Non-blocking notes

- Shape and budgets hold. The Goal is three lines, citing the queue. Goal, non-goals and defaults come to about 1,200 words and Architecture to about 1,300, excluding the criteria. The Architecture section cites the epic rather than restating it. The Chips (look) block is close to internal component design, but it is visual acceptance material, so it is acceptable.
- A2 and A7 depend on live model behaviour (claude-cli). They are checkable by inspection, which is appropriate for a real-app loop criterion.
- In S3, `aspect:Venus|square|Mars` is correctly absent from the fixture chart, and the test relies on that. A comment in the test saying so would stop a future fixture change from silently weakening it.
