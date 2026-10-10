# Plan — rn-ask-input-disabled

Spec: `pipeline/specs/rn-ask-input-disabled.md` (Decided defaults + Architecture are the source of truth; this plan only orders them). Review: `pipeline/logs/rn-ask-input-disabled/02-spec-review.md` (non-blocking notes folded into steps 4 and 9). All commands run from `app-native/` unless stated. Frontend-facing: load `/frontend-design` before step 2.

## Steps

- [x] **0. Baseline.** Record per-suite case counts for `src/ask/ask.test.tsx`, `src/ask/ask-flow.test.tsx`, `src/text-variant-rulings.test.tsx` (for AC-7's before/after evidence) and confirm the tree is green. Done-when: `npx jest src/ask src/text-variant-rulings.test.tsx --verbose` green; counts written into the implementing log.

- [x] **1. The flag and the string.** Create `src/ask/ask-gate.ts` (one exported boolean constant, false, header comment, no imports — Contracts). Add the `ask.comingSoon` leaf to `src/i18n/en.ts` and `src/i18n/zh.ts` beside `checking`, strings per Decided default 6. Done-when: `npx jest src/i18n` and `npm run typecheck` green.

- [x] **2. QuestionField takes `disabled`.** `src/ask/QuestionField.tsx`: required `disabled` prop; OR it into the existing inert wrapper, `editable`, ASK's disabled/paint/tone, and short-circuit its press; add `accessibilityState` to the input; label stays `ask.submit`; no new import (Contracts). Done-when: `npm run typecheck` fails only at AskScreen's missing prop (fixed in step 3; commit steps 2–3 together).

- [x] **3. AskScreen reads the flag.** `src/ask/AskScreen.tsx`: import from `./ask-gate`; early return at the top of `submit` before abort/state/`checkFitness`; pass `disabled`; render the `note` Txt (`ask-coming-soon`) under the field inside the `field` wrapper, flag-off only, layout-only style entry. Nothing else branches on the flag. Done-when: `npm run typecheck` green.

- [x] **4. Keep the existing suites on the flag-ON path.** Add a top-level `jest.mock` of the gate to `{ ASK_INPUT_ENABLED: true }` in `src/ask/ask.test.tsx` and `src/ask/ask-flow.test.tsx` (specifier `./ask-gate`) and `src/text-variant-rulings.test.tsx` (`./ask/ask-gate`). In `ask.test.tsx` add `'./ask-gate'` to the AskScreen import allowlist with a feature comment, and one case asserting `ask-coming-soon` is absent with the flag on. No other case edits. Done-when: `npx jest src/ask src/text-variant-rulings.test.tsx` green; case counts = baseline (+1 new case only); `git diff --stat` shows no deleted cases.

- [x] **5. Census floor.** `src/theme/text-variants.test.tsx`: `note` floor 12 → 13 with a provenance comment in the row's existing style (slug + date). Done-when: `npx jest src/theme/text-variants.test.tsx` green.

- [x] **6. The disabled-state suite.** New `src/ask/ask-gate.test.tsx`: real gate constant, real `@astrace/core/ask` barrel, `jest.spyOn(globalThis, 'fetch')` per the `fitness-seam.test.ts:61-71` idiom (never the literal `fetch` + `(` token). One `describe` per AC-1…AC-6 exactly as the criteria read (AC-1 walks non-test files under `src` for the specifier; AC-5 is one test ending with a direct `onSubmit` call via the rendered `QuestionField` element inside `act`, then flushed promises). Done-when: `npx jest src/ask/ask-gate.test.tsx` green, and it fails if the constant is flipped to true locally (sanity check, reverted).

- [x] **7. Guards and whole suites.** Done-when: `npx jest src/architecture.test.ts src/color-guard.test.ts src/text-variant-guard.test.ts src/theme/text-variants.test.tsx src/surface-paint-rulings.test.tsx src/i18n` green (residue constants still `RAW_TAG_TOTAL` 53 / `MARKER_TOTAL` 61), then from the REPO ROOT `npm test` and `npm run typecheck` green. Commit via `/git-commit`, then set `validating`.

- [ ] **8. Validate on the simulator** (validating stage). Per `.claude/skills/verify/SKILL.md`: backend in the foreground/log-visible, Metro + dev client on the iOS simulator. Drive AC-10 (tap field, tap ASK, chips and ring still present, 中文 note), screenshots + backend access-log excerpt showing no `/api/ask`. The implementer reports `validating — needs device` to the coordinator for this part. Done-when: evidence recorded in the validating log.

- [x] **9. Docs-sync.** `docs/ARCHITECTURE.md` via `/update-architecture-doc` (Ask section: the gate module and its one reader); write `docs/features/rn-ask-input-disabled.md` from what was built; add the coming-soon `note` member to `docs/text-variant-census.md` §D (member count 12 → 13, matching the floor comment). Done-when: `git diff --stat docs/` lists all three files; `npx jest src/theme` still green.

## Acceptance map

| Criterion | Made to pass by | Graded in |
|---|---|---|
| AC-1 one flag | 1, 3 | step 6 suite |
| AC-2 visibly disabled (en) | 2, 3 | step 6 suite |
| AC-3 zh | 1, 3 | step 6 suite + `i18n/i18n.test.ts` |
| AC-4 cannot focus or type | 2 | step 6 suite |
| AC-5 no request leaves | 2, 3 | step 6 suite |
| AC-6 rest of the screen stays | 3 | step 6 suite |
| AC-7 one-line re-enable | 4 (baseline 0) | existing suites + flag-on absence case |
| AC-8 guards hold | 4, 5 | step 7 |
| AC-9 whole suites | all | step 7 |
| AC-10 simulator | 8 | validating log |

## Risks for the implementer

- `jest.mock` factories are hoisted; the gate module has no imports, so a plain object factory is safe — but the specifier must match the resolved path per file (`./ask-gate` vs `./ask/ask-gate`) or the mock silently misses and flag-on cases fail on the disabled field.
- The `fetch(`-token scan in `ask.test.tsx:841-847` reads the new suite too: name the spy and call it only as a property (`toHaveBeenCalledTimes`), never with the call token, in comments included.
- AC-5's direct `onSubmit` bypasses the widget; it only proves gate 2 if `AskScreen.submit`'s early return precedes the AbortController and `checkFitness`. If `checkFitness` hits a warm fitness cache it would also send nothing — keep the spy assertion at 0 AND assert no plate/decline so a cache hit could not pass vacuously.
- `accessibilityState.disabled` on ASK must stay derived from both `!canSubmit` and `disabled`; flag-on paint rulings (`text-variant-rulings.test.tsx`, `surface-paint-rulings.test.tsx`) pin the accent/waiting split.
- The title's expanded face depends on focus never arriving; do not add an `onFocus` fallback that flips it.
