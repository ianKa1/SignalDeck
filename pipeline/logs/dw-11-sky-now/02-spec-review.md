# 02 spec-review (round 1) — fresh-context reviewer

**Verdict: PASS**

Inputs: QUEUE `dw-11-sky-now` + ROUND 2 comment, `specs/dw-11-sky-now.md`, `epics/divination-web.md`, CLAUDE.md, PIPELINE.md (Spec requirements, Auto spec review, pipeline-mode overrides), dw-8's "Composition with dw-11". Working branch at d2aaf12.

## Checklist

1. **Serves the notes, right-sized.** Yes. Default A (sky for timing), Moon/Saturn/Jupiter first, reuse of the memoized `compute_transits`, no new sky math, the "pattern, not timing" fallback (dw-8's `roster.timing`) and the loop-closer (Saturn names a real transit with correct dates) are all carried. "Relevant slow-planet windows" is read as contacts touching P, which is a reasonable decided reading. No invented scope; pills/chips deferred to dw-10.
2. **Checkable criteria.** Yes. I recomputed chart A at `transit_instant(None, "Asia/Shanghai", 2026-09-28T03:00Z)` = 04:00Z in the conda env: K3's Saturn episode order (MC 8.36, Mars 6.72, IC 5.02, Neptune 2.73, quincunx house-3-cusp 1.62, Mercury□Saturn 0.18; Moon□Saturn dropped), Saturn sign Aries / house 9 / retrograde, the Saturn☌Mars window 04-18→03-06, passes 05-15/10-12/02-05, stations 07-27/12-11 (UTC 07-26T19:56Z → Shanghai 07-27), house ingress 9 on 09-13 (retrograde), `saturn-quarter` 2027-06-01 and the undated approaching `saturn-return` all match. K5 (Jupiter□Venus 09-08→10-10, pass 09-23; Uranus□Moon `exitUtc` null; Moon□Saturn a transiting-Moon row in Moon's top 8) and K6 (NY: today 09-27, window end 03-05, first pass 05-14) also match. K4's ±1-day/0.25° tolerances are sound for Saturn/Jupiter speeds against `TRANSIT_MAX_ORB`. The R criteria use a mechanical date rule against a logged packet.
3. **Architecture Contract.** Holds. `sky.py → app.chart.transit` is inside the existing `DIVINATION_FORBIDDEN_RE` fence (selection stays forbidden, `test_boundaries.py:321`). `transit_instant` is called from main.py, so there is no second interpretation borrow. Pure compute, no job, no generator token, so rule 14 is unchanged (main.py's `/api/transit` is precedent). Rule 5: core only reports the device zone (the `deviceTimezone` one-liner, `transit-day/service.ts:86`). Identity-free: the memo is content-keyed. The question text is never inspected. dw-8's contract is honoured: exactly one of `roster.timing`/sky (K2), slot chart < sky < dice, goldens re-recorded with an empty diff (K9). The citations I checked are accurate (`instant.py:450/457/479/597`, `service.py:219`, `models.py:217`, `main.py:148/425`, `render.py:247/351`, `turn.py:167/200/211`).
4. **Non-goals and defaults.** Non-goals are explicit, and every point is decided. There is no open-question section.

## Non-blocking refinements

- Default 4 lists `planet` as `{sign, natalHouse, retrograde}`, but K3 also asserts `body:"Saturn"`. Add `body` to Default 4 or the `sky_view` contract so the two agree.
- `transit_day.py:81` is really `server/app/transit_day.py` (not under interpretation/). The spec gives no directory, so this is harmless, but the plan should use the full path.
- An unknown birth time is only covered by `sky.read`'s "names no house" text. Consider a cheap server check: a `time: null` chart-A Saturn turn builds a packet with `planet.natalHouse: null` and no cusp/angle episodes or house ingresses, and does not raise.
- The ~0.5 s cold walk runs inside the turn deadline and emits no keepalive while it runs. That is acceptable, but the plan's risks should note that a slow cold walk delays the first frame rather than failing it.
- Episodes by the transiting Moon (Moon persona) carry hour-long windows whose from/to fall on the same date. `sky.read` could say that a same-day window reads as "today", so the model does not present hours as a span of dates.
