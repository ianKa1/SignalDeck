# 03 · designing (revision after round-1 FAIL)

Defect D1 (logs/rn-appearance-dark-light/02-spec-review.md): AC-12 quoted stale residue totals (50/57 from CLAUDE.md rule 15 prose). Verified in code: `app-native/src/text-variant-guard.test.ts` pins `MARKER_TOTAL = 61`, `RAW_TAG_TOTAL = 53` (the test title still says 48/55 — stale).

Edit: AC-12 now reads "`RAW_TAG_TOTAL` (53), `MARKER_TOTAL` (61) and `RESIDUE_FLOORS` unedited, text-variant-guard.test.ts:220-222", and records the CLAUDE.md / test-title figures as pre-existing drift outside scope. No other change (non-blocking notes left to the implementer).

Transition: spec-review (revise) → spec-review (round 2)
