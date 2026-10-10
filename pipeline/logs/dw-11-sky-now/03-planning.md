# dw-11-sky-now · 03 planning

Date: 2026-09-28. Coordinator-dispatched stage worker, primary checkout (feature/divination_web @ d2aaf12). Nothing committed; QUEUE.md and DECISIONS.md not edited; no code edited.

## Reads
- CLAUDE.md; PIPELINE.md (Skills per stage, pipeline-mode overrides for the design and plan skills, Parallel waves).
- `specs/dw-11-sky-now.md`; `logs/dw-11-sky-now/02-spec-review.md` (five non-blocking notes).
- `specs/dw-8-planet-cast.md` "Composition with dw-11"; `plans/dw-8-planet-cast.md` (names, fixtures, tests dw-11 inherits).
- `logs/dw-12-google-sign-in/05-validating.md` (throwaway Postgres + `mint.py` recipe).
- `epics/divination-web.md` (section index).
- Targeted code: `divination/turn.py` (`turn_events`, `natal_context`, `_side_read`), `divination/render.py` (signatures, FINGERPRINT), `main.py` (imports, `_person`, turn route), `interpretation/service.py:219` `transit_instant`, `chart/transit/instant.py` (memo, uncached seam), `models.py` validators, core `divination/turn.ts`, `transit-day/service.ts` `deviceTimezone`, `test_boundaries.py` divination fence, `test_divination_render.py`, test fixtures, root `package.json` scripts, `web-divination/src/chat/core-divination.test.ts` (C1's home). dw-8 code does not exist yet; its names are cited from the dw-8 spec/plan.

## Probe
- Unknown birth time (review note 3): `compute_transits` for chart A with `time: None` at 2026-09-28T04:00Z in the conda env → Saturn `natalHouse: None`, contact target kinds `{planet}`, `houseIngresses: []`, no exception. Became check K3u.

## Skill
`/imple-plan` under the pipeline-mode override (Steps / Acceptance map / Risks; no Code Structure, Calling Sequence, Data Flow or Test Plan; no architecture re-run).

## Output
- `plans/dw-11-sky-now.md`: 7 steps (0–6: 0–4 implementing, 5 validating, 6 docs-sync); `wc -w` = 1622.
- All five review notes settled (R-a body, R-b full path, R-c K3u, R-d risk note, R-e same-day "today").

## Deviations
- Packet `planet` carries `body` (spec Default 4 omitted it; K3 asserts it).
- K3u added as a server test beyond the spec's criteria.
- `sky.read` also rules same-day windows as "today".
- dw-8's `fixtures/divination_pre_dw8/` kept (dw-8's S5 test still reads them).

## Transition
spec-approved → implementing (worktree to be cut after dw-8 lands).
