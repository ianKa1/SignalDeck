# dw-11-sky-now · 01 designing

Date: 2026-09-28. Coordinator-dispatched stage worker, primary checkout (feature/divination_web @ d2aaf12). Nothing was committed, and neither QUEUE.md nor DECISIONS.md was edited.

## Reads
- CLAUDE.md (rules 5, 10, 14); PIPELINE.md (Skills per stage, the pipeline-mode overrides, Epic files, Spec requirements, Auto spec review, Parallel waves).
- The QUEUE.md round-2 comment and the dw-11 entry; `epics/divination-web.md`; DECISIONS.md from "2026-09-28 · divination-web round 2" to the end.
- The dw-8 spec in full (the "Composition with dw-11" contract) and the dw-8 plan's hand-off risks; the dw-9 spec's `system_prompt` signature.
- Code:
  - `chart/transit/{__init__,instant,policy,timeline}.py` (compute_transits, the memo, the bundle shape, contact_timeline, events);
  - `selection/{__init__,standing,cadence,strip}.py`;
  - `transit_day.py`; `interpretation/service.py` `transit_instant`;
  - `divination/{render,turn}.py`;
  - `main.py` (the turn route, `_person`, `/api/transits`); `models.py` (the turn request, the currentTimezone validators);
  - `tests/test_boundaries.py` (the divination fence, GENERATE_ON_REQUEST_RE);
  - core `divination/{types,turn}.ts`, `transit-day/service.ts` deviceTimezone.
- Probes (scratchpad `dw11_probe*.py`, real engine) on chart A at NOW=2026-09-28T03:00Z:
  - cold walk 0.46 s, memo hit 1 ms;
  - the Saturn, Jupiter and Moon packets computed; the New York zone shift confirmed;
  - the K4 ephemeris check (pass dates ≤0.06°, window edges straddle the max orb) ALL OK.

## Skills
1. `frontend-design`: SKIPPED. dw-11 changes no UI: no chips, no web files, and core only adds a body field.
2. `feature-spec` (pipeline mode): Goal, Non-goals, Decided defaults and Acceptance Criteria.
3. `architecture-designer` (pipeline mode): the Architecture section, a delta over the epic file and dw-8; no Migration Steps.

## Choices
- Sky personas are moon/saturn/jupiter (`sky.SKY_PERSONAS`). Venus, Mars and Mercury keep `roster.timing`.
- The sky is included structurally: on every turn with birth data for a sky persona, on any action. There is no question parsing. A sky failure degrades to `roster.timing` and the reply still streams.
- Exactly one of `roster.timing` and the sky section in every prompt (the never-both test). The sky section goes in dw-8's slot, after chart and before dice.
- The packet contains:
  - rows where P is the transiter, plus contacts to natal P (transiting-Moon rows only for the Moon), ordered by Tier A score, cap 8;
  - P's own stations, sign ingresses and house ingresses, and dated returns.
  - Dates are local `YYYY-MM-DD`. There are no orbs or degrees.
- The route resolves the clock and the instant: main.py's `_utcnow()` seam + `transit_instant`, which is local noon, sharing the memo with the transit page. Divination reads no clock (new guard). No selection import, and the fence is not widened.
- The request gains an optional `currentTimezone`, which core fills from the device zone. The web is untouched.
- No new ref kind, chip or `done` change. `side.sky` keeps transiting planets out of chartRefs.
- Dates are proven against the ephemeris (K4) independently of the timeline walk. On the real app, the reply's dates must equal packet dates.

## Word counts (wc -w)
- Goal 56 + Non-goals 154 + Decided defaults 718 = **928** (feature-spec, ≤1,500).
- Architecture **1,319** (≤1,500).
- Acceptance Criteria 873 (exempt).

## Shared files touched
Only `pipeline/specs/dw-11-sky-now.md` and this log. No code, no QUEUE or DECISIONS edits, and no scratch files outside the scratchpad.

## Transition
designing → spec-review.
