# Plan — rn-onboarding-after-signin

Spec: `pipeline/specs/rn-onboarding-after-signin.md` (Decided defaults D1–D14,
Architecture, AC1–AC24). Worktree: `../astrology-wt/rn-onboarding-after-signin`,
branch `feature/rn-onboarding-after-signin` from `dev`. All paths below are
relative to the worktree; `src/` = `app-native/src/`. Load `/frontend-design`
before any UI step (3, 5, 6). Commit via `/git-commit` after each step,
`(<type>): rn-onboarding-after-signin — <summary>`.

## Steps

- [x] **1. Core sync phase.** `packages/core/src/account/sync.ts`, `index.ts`;
  tests in `app-native/src/account/core-account.test.ts` (graded core-account
  tests live there since rn-forced-signin). Add the `AccountSync` channel per the
  Architecture contract (pulling / ready / failed / idle; superseded generation
  sets nothing). **Done-when**: new tests prove the four transitions incl. "adopt
  happens before `ready`" and "a stale pull after stopSync stays `idle`";
  `npx jest src/account` green; `npm run typecheck` green.

- [x] **2. App hooks + progress key.** NEW `src/account/useAccountSync.ts`,
  NEW `src/setup/setup-progress.ts` (+ test). Read/write/clear
  `astrology.setup.v1` (`language`|`birth`, anything else → null), best-effort
  over `getKV()`. **Done-when**: `setup-progress.test.ts` covers round-trip,
  junk value → null, throwing KV → null/no throw; and a test that
  `wipeDevice`'s kept-keys list does not contain the key while it keeps lang and
  ground (AC18, unit half).

- [x] **3. Lift BirthForm.** NEW `src/birth-input/BirthForm.tsx`; CHG
  `BirthSheet.tsx` to Modal + scrim + grip + `sheet-cancel` around the form;
  `submitLabel?` prop; sheet maps `onSaved` → `onClose`. Raw tags + census
  markers move with their code. **Done-when**: existing `birth-sheet.test.tsx`,
  `city-picker.test.tsx`, `settings.test.tsx` pass unchanged;
  `text-variant-guard.test.ts` totals unchanged; new BirthForm test: no
  dismiss control, empty submit shows date+place errors (AC15 unit half).

- [x] **4. Opening `still` + children.** CHG `src/opening/OpeningPrototype.tsx`.
  `still` → lines visible at once, no timing call, `onDone` next tick; `children`
  rendered in the lower region below the block. No figure, same import set.
  **Done-when**: `opening.test.tsx` gains still/children cases; its AC-6/AC-7
  pins (no digits, imports, App.tsx-only importer) still pass.

- [x] **5. Gate as controls.** CHG `src/account/SignInGate.tsx`: drop page +
  wordmark, `revealed` prop, `sign-in-gate` on the controls root, fade from
  `revealed && signed-out` (at once under Reduce Motion). Rewrite
  `sign-in-gate.test.tsx` wordmark assertions; keep every behaviour test.
  **Done-when**: suite green; grep shows no `brand.wordmark` use in the gate;
  AC4's state cases covered.

- [x] **6. Setup screens.** NEW `src/setup/{SetupFlow,AppearanceStep,
  LanguageStep,BirthStep,StepMarks}.tsx`; CHG `src/i18n/en.ts`, `zh.ts` (`setup`
  block, D11 copy). Txt variants, PAINT, GROUND_TOKENS only; testIDs
  `setup-appearance`, `setup-language`, `setup-birth`, `setup-ground-dark|light`,
  `setup-lang-en|zh`. Behaviour per Architecture "SetupFlow". **Done-when**:
  `src/setup/setup.test.tsx` proves AC11, AC12 (reload seam via
  `setReloadImpl`), AC14, AC15, AC16 (fetch mock records the PUT body) at
  component level; i18n parity green.

- [x] **7. Compose in App.** CHG `src/App.tsx` per the render rule; clear a
  stale progress key when sync is ready with birth data; pass
  `revealed={wordsDone || reduced}`. Rewrite `src/App.test.tsx`.
  **Done-when**: App tests prove AC1, AC2, AC3, AC5, AC7, AC8, AC9, AC10, AC13
  (light ground applied before App modules evaluate — `jest.isolateModules`),
  AC16 end-to-end to `tab-chart`, AC17, AC18 (session end → key gone).

- [x] **8. Guards + headers.** CHG `src/native-guards.test.ts`: add `setup` to
  the raw-JSX-literal walk and the paid/card-channel walk; update comments in
  App.tsx, OpeningPrototype, SignInGate, BirthSheet headers; census comment if
  any total moved. **Done-when**: plant-and-revert probe (a literal string in a
  setup JSX child; a paid-channel name in a setup file) turns each guard red,
  then reverted; full `npm test` + `npm run typecheck` green (AC20, AC21).

- [x] **9. Full suites.** `npm test`, `npm run typecheck`, `npm run
  server:test` (db-less) from the worktree root. **Done-when**: all green,
  counts logged in `logs/rn-onboarding-after-signin/NN-validating.md`.

- [x] **10. Device (coordinator-serialized).** Harness D14: throwaway Postgres
  (own port, e.g. 54318), scratch wrapper monkeypatching
  `app.accounts.google._verify_token`, backend on a free port with
  `DATABASE_URL`/`WEB_DATABASE_URL` set explicitly and no `--env-file`, dev
  build via `npx expo run:ios` with `EXPO_PUBLIC_API_BASE` and
  `GOOGLE_IOS_CLIENT_ID` set, temporary uncommitted `googleIdToken` stub.
  Back up the simulator app container first and restore it after. **Done-when**:
  AC6, AC22, AC23, AC24 evidenced (screenshots, idb dumps, backend log lines,
  db row) in the validating log; `git status` clean after reverting the stub.

## Acceptance map

| AC | Step | AC | Step |
|---|---|---|---|
| AC1 | 7 | AC13 | 4, 7 |
| AC2 | 7 | AC14 | 6 |
| AC3 | 4, 5, 7 | AC15 | 3, 6 |
| AC4 | 5, 7 | AC16 | 6, 7 |
| AC5 | 7 | AC17 | 7 |
| AC6 | 10 | AC18 | 2, 7 |
| AC7 | 1, 7 | AC19 | 3 |
| AC8 | 1, 7 | AC20 | 6, 8 |
| AC9 | 1, 7 | AC21 | 8, 9 |
| AC10 | 1, 7 | AC22 | 10 |
| AC11 | 6 | AC23 | 10 |
| AC12 | 6 | AC24 | 10 |

## Risks for the implementer

- `signedIn()` sets the status before `startSync()` runs (service.ts:56–58):
  App sees `signed-in` with sync `idle` for a tick — the render rule must treat
  `idle` as "threshold", never as "shell".
- The ground is applied at module evaluation; a light-ground App test must
  apply it before importing App (isolateModules), and must restore dark.
- `OpeningPrototype`'s reanimated mock: animated styles never reach
  `toJSON()`; assert visibility through the static `visible` twin as its suite
  does.
- `useBirthData` snapshot identity is memoised in core (useBirthData.ts:12) —
  the App render rule reads `=== null` only.
- `DateTimePicker` in the setup page is the same spinner as the sheet; on the
  simulator, set date/time by the spinner wheels (idb swipe) or accept the
  ANCHOR by unfurling the dial (it commits).
- The device build: `expo run:ios` replaces the user's Astrace Dev install and
  data container — back up and restore exactly as rn-forced-signin's
  11-validating did; leave the user's :8000, :5173, :8082 alone.
- Never commit the `googleIdToken` stub; never use the Neon URLs in `.env`.
