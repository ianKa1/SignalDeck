# rn-ask-input-disabled — 04 implementing (2026-09-30)

Worker in worktree `/Users/kaimao/Projects/astrology-wt/rn-ask-input-disabled` (branch `feature/rn-ask-input-disabled`, off `dev` @ 04ae600).

## Step 0 — baseline
`cd app-native && npx jest src/ask src/text-variant-rulings.test.tsx`
```
Test Suites: 15 passed, 15 total
Tests:       223 passed, 223 total
```
Per-suite (`npx jest <file>`):
```
src/ask/ask.test.tsx               Tests: 48 passed, 48 total
src/ask/ask-flow.test.tsx          Tests: 6 passed, 6 total
src/text-variant-rulings.test.tsx  Tests: 28 passed, 28 total
```

## Skills invoked
- `frontend-design` (before UI code). Direction: restraint — the spec forbids new figures, so the disabled look is the field's existing inert figures (0.5 wrapper opacity, `PAINT.actionOutlined.waiting`, `actionLabel` waiting tone) and the note is the existing `note` variant.
- `git-commit` (autonomous override: no approval wait, specific files staged).

## Step 1 — flag + string
- NEW `app-native/src/ask/ask-gate.ts`: `export const ASK_INPUT_ENABLED: boolean = false` (no imports). The `: boolean` annotation keeps TS from narrowing the const to the literal `false`, so flag-dependent branches typecheck the same either way; re-enable is still the one `false` → `true` edit.
- `i18n/en.ts` `ask.comingSoon: 'Asking is coming soon.'`, `i18n/zh.ts` `ask.comingSoon: '提问即将开放。'` (beside `checking`).
- `npx jest src/i18n` → `Test Suites: 2 passed; Tests: 17 passed, 17 total`. `npm run typecheck` → clean.

## Steps 2–3 — QuestionField `disabled`, AskScreen reads the flag
- QuestionField: required `disabled: boolean`; `canSubmit = normalized.length > 0 && !disabled` (so the Pressable's `disabled`, the press short-circuit, `submitInert` paint and the `waiting` tone all follow from the one existing expression); wrapper `(checking || disabled) && styles.checking`; input `editable={!checking && !disabled}` + `accessibilityState={{ disabled }}`. Label unchanged (`ask.submit` unless checking). Imports unchanged.
- AskScreen: `import { ASK_INPUT_ENABLED } from './ask-gate'`; `submit` begins `if (!ASK_INPUT_ENABLED) return` before abort/state/`checkFitness`; passes `disabled={!ASK_INPUT_ENABLED}`; renders `<Txt variant="note" testID="ask-coming-soon" style={styles.comingSoon}>{dict.ask.comingSoon}</Txt>` under the field inside `styles.field`, flag-off only; `comingSoon: { marginTop: space.sm, textAlign: 'center' }` (layout keys only).
- `npm run typecheck` → clean.

## Step 4 — existing suites on the flag-ON path
- `jest.mock('./ask-gate', () => ({ ASK_INPUT_ENABLED: true }))` in `ask/ask.test.tsx`, `ask/ask-flow.test.tsx`; `jest.mock('./ask/ask-gate', …)` in `text-variant-rulings.test.tsx`. Allowlist gains `'./ask-gate'` (commented) in the AskScreen import pin. New case `rn-ask-input-disabled — with the gate open there is no note` (ask-coming-soon absent, input editable).
- Counts after:
```
src/ask/ask.test.tsx               Tests: 49 passed, 49 total   (baseline 48, +1 new case)
src/ask/ask-flow.test.tsx          Tests: 6 passed, 6 total     (baseline 6)
src/text-variant-rulings.test.tsx  Tests: 28 passed, 28 total   (baseline 28)
```
- Mock is load-bearing (sanity, reverted): with the ask-flow mock line removed → `Tests: 4 failed, 2 passed, 6 total`.
- Removed lines per suite vs `04ae600` (`git diff | grep -c '^-[^-]'`): ask.test.tsx 0, ask-flow.test.tsx 0, text-variant-rulings.test.tsx 0 — no case deleted or edited.

## Step 5 — census floor
- `theme/text-variants.test.tsx`: `note: 12` → `13` with provenance `12 → 13: the coming-soon line under the gated field, ask/AskScreen.tsx (rn-ask-input-disabled, 2026-09-30)`.
- `npx jest src/theme/text-variants.test.tsx` → `Tests: 23 passed, 23 total`.

Commit `b88cebf` (steps 1–5).

## Step 6 — disabled-state suite `app-native/src/ask/ask-gate.test.tsx`
Real gate, real `@astrace/core/ask` (not mocked), `fetchSpy = jest.spyOn(g as Required<typeof g>, 'fetch')` (fitness-seam idiom; the call token never appears). One describe per AC-1…AC-6; AC-5 ends with `screen.UNSAFE_getByType(QuestionField).props.onSubmit('why do I keep doing this')` inside `act` + a flushed macrotask, then asserts `toHaveBeenCalledTimes(0)`, no `ask-final`/`ask-decline`, no `ask.checking` label.
- First run: `Tests: 1 failed, 9 passed, 10 total` — AC-1 found a SECOND file naming `./ask-gate`: QuestionField's own new header comment. Fixed by rewording the comment (the spec's AC-1 is a text scan, and the spec forbids the specifier in QuestionField). Rerun → `Tests: 10 passed, 10 total`.
- Sanity (reverted, `git diff --stat src/ask/ask-gate.ts` empty after): constant flipped to `true` → `Tests: 6 failed, 4 passed, 10 total` (incl. AC-5 — the spy does see the real core request).
- Sanity (reverted, `git diff --stat src/ask/AskScreen.tsx` empty after): only the `submit` early return removed → `✕ focus, type, ASK, every starter, then the seam called directly…`, `Tests: 1 failed, 9 passed` — AC-5 grades gate 2 on its own.

## Step 7 — guards and whole suites
`npx jest src/architecture.test.ts src/color-guard.test.ts src/text-variant-guard.test.ts src/theme/text-variants.test.tsx src/surface-paint-rulings.test.tsx src/i18n src/ask src/text-variant-rulings.test.tsx`
```
Test Suites: 23 passed, 23 total
Tests:       346 passed, 346 total
```
Residue constants unchanged: `MARKER_TOTAL = 61`, `RAW_TAG_TOTAL = 53` (text-variant-guard.test.ts:221-222, not edited).

Repo root `npm test`:
```
Test Suites: 92 passed, 92 total
Tests:       1091 passed, 1091 total
 Test Files  47 passed (47)
      Tests  445 passed (445)
```
Repo root `npm run typecheck`: `app-native tsc --noEmit` clean; `web-divination tsc --noEmit` clean.

`git diff --stat 04ae600 -- app-native`: 10 files changed, 275 insertions(+), 4 deletions(-) (the 4 deletions: 3 replaced lines in QuestionField.tsx + the note floor line).

Commit `ffc40d2` (step 6 suite + QuestionField comment fix).

Transition: implementing → validating
