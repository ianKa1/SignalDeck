# 07 planning — dw-3-chart-grounded-reply

**Transition:** `spec-approved` → `implementing`.

## Reads
- CLAUDE.md, read from disk (rule 10's divination paragraph, and rules 13 and 14).
- PIPELINE.md: "Skills per stage" and "Pipeline-mode overrides for the design and plan skills".
- The spec `specs/dw-3-chart-grounded-reply.md` (the structure was taken as decided; architecture-designer was not re-run).
- The review `logs/dw-3-chart-grounded-reply/06-spec-review.md` (PASS). Its non-blocking notes are all settled in the plan.
- The epic `epics/divination-web.md` and the precedent plan `plans/dw-2-venus-chat.md`.
- Targeted code reads:
  - server: `server/app/divination/{render.py,turn.py}`, `main.py` (`_person` and the turn route), `models.py` (`BirthData` and `DivinationTurnRequest`), `interpretation/prompt.py` `_restate`, `chart/natal/compute.py` (the aspect inputs include the Midheaven and points), `chart/points.py` `PLANET_NAMES`;
  - server tests: the divination entries in `server/tests/test_boundaries.py`, and the dw-2 test lines in `test_divination_turn.py` and `test_divination_render.py`;
  - core: `packages/core/src/divination/{types.ts,turn.ts,transcript.ts}` and `chart/types.ts` `BODIES`;
  - web: `web-divination/src/chat/*`, `theme/{tokens,apply}.ts`, `i18n/en.ts`, and `birth-input`;
  - the root `package.json` scripts.

## Skill
`/imple-plan`, under the pipeline-mode override. The plan has Steps, an
Acceptance map and Risks. It has no Code Structure, Calling Sequence, Data
Flow or Test Plan section.

## Output
- `pipeline/plans/dw-3-chart-grounded-reply.md`: 6 steps (4 implementing, 1 validating, 1 docs-sync) and 1,534 words (`wc -w`).
- The acceptance map covers S1–S11, C1–C3, W1–W4 and A1–A7.
- The review notes are settled:
  - **dw-2 test edits:** `test_divination_turn.py` lines 101/136/166/282 (the `done` shape) and 268 (the two-argument `turn_events`), `test_divination_render.py:72` (the four-argument `side_prompt`), and, found in addition, `core-divination.test.ts` lines 67/81/112 plus its `REQ` fixture;
  - **`chart.marker` vs S11:** the marker is registered, and the S11 test asserts all four fragments;
  - **ten-body filter:** the catalogue filters to the ten bodies explicitly.

## Deviations (for DECISIONS.md)
- **D1:** `chart.marker` is a fourth registered fragment, and S11 asserts all four.
- **D2:** the ten-body source is `app.chart.points.PLANET_NAMES`; no local tuple is added.
- **D3:** the catalogue order is planets in chart order, then aspects in `chart["aspects"]` order.
- **D4:** the aspect `aria-label` is joined per language (spaces in en, none in zh), with no new i18n key.
