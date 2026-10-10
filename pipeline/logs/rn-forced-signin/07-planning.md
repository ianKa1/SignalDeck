# rn-forced-signin — 07 planning (2026-09-30)

## Inputs read
- CLAUDE.md, and pipeline/PIPELINE.md ("Skills per stage" and the `/imple-plan` pipeline-mode override).
- `pipeline/specs/rn-forced-signin.md`, and the reviews `02-`, `04-` and `06-spec-review.md` (round 3 PASS, planner notes N1–N8).
- Targeted confirmations on dev `d47d24a`:
  - migrations end at `013_planet_chat_rename.sql`, so 014 and 015 are free;
  - the throwaway-cluster recipe is in the docstring of `server/tests/test_auth_integration.py`;
  - `web-divination/src/auth/core-planet-chat-auth.test.ts` has the C1 block at :144, `{auth:true}` at :147/:180/:195, and the :165 non-report case;
  - the `main.py:308` docstring says "UNAUTHENTICATED", as do `docs/ARCHITECTURE.md` :3174 and :5279;
  - CLAUDE.md :117 reads "works with no keys";
  - `App.test.tsx:20` mocks deepLink, and `native-guards.test.ts:525` has a comment naming AccountSheet;
  - `test_boundaries.py:171` is the resend pin and `:1075` is B4;
  - the census constants are 61/53 on dev;
  - `rn-appearance-dark-light` is `validating` in its own worktree (not yet on dev);
  - DECISIONS.md :4014 already journals the gallery-all-cards Supersedes (N2's journal half is done).

## Skills invoked
- `imple-plan` (Skill tool), under the pipeline-mode override:
  - ordered `- [ ]` steps with files, intent and a done-when check;
  - an Acceptance map;
  - short Risks.
- `/architecture-designer` was not re-run.

## Output
- `pipeline/plans/rn-forced-signin.md`: 19 steps (0–18). They run server (1–7), core (8–9), app-native (10–14), config (15), device (16–17), then docs-sync (18). The Acceptance map covers every criterion: S1–S7, D1–D4, R1, R1b, R2–R7, A4′, C1–C9, U1–U4, G1, B1, B2, A1 and A2, plus L1–L5 marked LIVE and deferred to the user hand-back.
- Where each round-3 note landed:
  - N1: step 8, the sanctioned R7 exception (see the clarification below);
  - N2: step 5 (the docstring) and step 18 (ARCHITECTURE.md);
  - N3: step 13 (App.test.tsx) and step 14 (native-guards comment);
  - N4: step 6 (Commands);
  - N5: step 6 (A4′ matches identifiers);
  - N6: step 0 (merge dev and re-check), step 13 and Risks;
  - N7: step 6 (rule 14's header).
- Steps that need the simulator: 16 (dev-client rebuild) and 17's A1 half. A2 (curl) needs no device. The coordinator serializes both device steps.

## Clarification of R7 (for the journal)
The whole "C1 — postJson carries the bearer only when asked" block in `core-planet-chat-auth.test.ts` is the sanctioned exception to R7's "unchanged". That covers the `:154` no-header case (now always sent), the inverted `:165` non-report case, and the removed `{auth:true}` arguments at `:147/:180/:195`. The web behaviour is otherwise unchanged. This is N1, recorded as a plan clarification rather than a scope change.

## Spec gaps
- **G-a (test home, not structure).** The module map lists `packages/core/src/account/{service,sync}.test.ts` as CHG homes for the core criteria. But those files are run by NO runner and typechecked by no tsconfig: they are vitest files left over from the deleted `frontend/` runner. app-native jest has `roots: src`, and web-divination vitest includes only `src/**`. Criteria graded there would pass vacuously. The plan puts the graded C4–C6 tests in a new `app-native/src/account/core-account.test.ts` (barrel imports, the `core-planet-chat-auth.test.ts` precedent) and edits the orphaned files only to drop removed APIs. Journal this as a deviation. Whether to wire a core test runner or delete the orphaned core tests is out of scope, and is for the user.
- No structural decision was made in the plan.

Transition: spec-approved → implementing
