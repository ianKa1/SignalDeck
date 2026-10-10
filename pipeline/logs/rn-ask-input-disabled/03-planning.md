# rn-ask-input-disabled — 03 planning (2026-09-30)

## Inputs read
- CLAUDE.md (rules 5, 8, 13, 15), pipeline/PIPELINE.md ("Skills per stage", `/imple-plan` pipeline-mode override).
- `pipeline/specs/rn-ask-input-disabled.md` (Decided defaults, Architecture, AC-1…AC-10).
- `pipeline/logs/rn-ask-input-disabled/02-spec-review.md` (PASS; two non-blocking notes).
- Targeted confirmations: `app-native/src/theme/text-variants.test.tsx:239-275` (floors count `<Txt variant>` sites in non-test files; `note: 12`), `app-native/src/ask/fitness-seam.test.ts:61-71` (spy idiom), `docs/text-variant-census.md` §D `note` row, `.claude/skills/verify/SKILL.md` present, `pipeline/plans/dw-18-divination-auth.md` (house plan format).

## Skills invoked
- `imple-plan` (Skill tool) under the pipeline-mode override: ordered `- [ ]` steps with files, intent and a done-when command; Acceptance map; short Risks. Code Structure / Calling Sequence / Data Flow / Test Plan sections dropped. `/architecture-designer` not re-run.

## Output
- `pipeline/plans/rn-ask-input-disabled.md` — 10 steps (0 baseline → 9 docs-sync), acceptance map covering AC-1…AC-10, 5 risks.
- Review notes folded in: mock specifier per suite location (step 4); census §D member count for provenance parity (step 9).
- Validating (step 8) needs the iOS simulator: the implementer reports `validating — needs device` to the coordinator for AC-10.

## Spec gaps
None. Every step maps to a decided default or an Architecture contract; no structural decision was made in the plan. (Observation only, outside scope: CLAUDE.md rule 15's "50 raw tags, 57 markers" is stale vs the pinned 48/55, as the review already noted.)

Transition: spec-approved → implementing

## Coordinator correction (2026-09-30, after planning)
The spec (lines 140, 187) and plan step 7 quoted the residue as "48 raw tags, 55 markers" — that is the stale TITLE of the test. The pinned constants are `MARKER_TOTAL = 61`, `RAW_TAG_TOTAL = 53` (app-native/src/text-variant-guard.test.ts:221-222; the rn-appearance-dark-light reviewer caught the same drift). Both files now cite the constants. Fact correction only; no behaviour or scope change, so no re-review.
