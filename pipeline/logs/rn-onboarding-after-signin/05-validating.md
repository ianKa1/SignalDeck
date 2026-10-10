# 05 — validating (worker; plan steps 8–9; step 10 device checks are the coordinator's)

Worktree `../astrology-wt/rn-onboarding-after-signin`, branch `feature/rn-onboarding-after-signin`,
HEAD bf355b6 (8 WIP commits over dev @ 5d72459). `git status --short` clean at the end.

## Step 9 — full suites (from the worktree root)

`npm test`:
```
Test Suites: 97 passed, 97 total
Tests:       1186 passed, 1186 total        (app-native jest; base 5d72459 had 1141)
 Test Files  48 passed (48)
      Tests  447 passed (447)                (web-divination vitest, untouched)
```
The jest run also prints "A worker process has failed to exit gracefully and has been force
exited…" — PRE-EXISTING: the same line appears running the base commit's sources
(`git checkout 5d72459 -- app-native/src packages/core/src`, new files removed → 1141 passed +
the same line; tree restored to HEAD after). `npx jest src/App src/setup
src/birth-input/birth-form.test.tsx src/account src/opening --detectOpenHandles` → 115 passed,
no open handle reported.

`npm run typecheck`: `tsc --noEmit` (app-native) and `tsc --noEmit` (web-divination), no errors.

`DATABASE_URL= WEB_DATABASE_URL= npm run server:test` (db-less, env emptied explicitly):
```
1504 passed, 124 skipped, 1 warning in 116.80s (0:01:56)
```
(the warning is starlette's httpx deprecation, pre-existing; no server file changed.)

## Step 8 — plant-and-revert probes (verbatim output)

Each probe planted one offending line in a setup/ source, ran the guard, then restored the file
from a scratch backup and re-ran it.

```
=== PROBE 1 (planted: 'Choose {label}' JSX literal in setup/LanguageStep.tsx) ===
  ✕ no raw literal reaches a JSX child in readings/, transit/, settings/, shell/, cards/, lore/, gallery/, account/, ask/ or setup/ (criterion 16b/20b, AC-17) (54 ms)
  ○ skipped no file under settings/ or setup/ names the paid or card channels (native-settings AC-7)
  ● no raw literal reaches a JSX child in readings/, transit/, settings/, shell/, cards/, lore/, gallery/, account/, ask/ or setup/ (criterion 16b/20b, AC-17)
    +   "setup/LanguageStep.tsx: \"Choose\"",
Tests:       1 failed, 35 skipped, 36 total
--- reverted ---
  ✓ no raw literal reaches a JSX child in readings/, transit/, settings/, shell/, cards/, lore/, gallery/, account/, ask/ or setup/ (criterion 16b/20b, AC-17) (55 ms)
Tests:       35 skipped, 1 passed, 36 total
=== PROBE 2 (planted: 'getAnalysis' in setup/SetupFlow.tsx) ===
  ✕ no file under settings/ or setup/ names the paid or card channels (native-settings AC-7) (3 ms)
  ○ skipped no raw literal reaches a JSX child in readings/, transit/, settings/, shell/, cards/, lore/, gallery/, account/, ask/ or setup/ (criterion 16b/20b, AC-17)
  ● no file under settings/ or setup/ names the paid or card channels (native-settings AC-7)
    +   "setup/SetupFlow.tsx",
Tests:       1 failed, 35 skipped, 36 total
Ran all test suites matching /src\/native-guards.test.ts/i with tests matching "settings/ or setup/ names the paid".
=== PROBE 3 (planted: 'retryCard' in setup/SetupFlow.tsx) ===
  ✕ no file under settings/ or setup/ names the paid or card channels (native-settings AC-7) (4 ms)
  ○ skipped no raw literal reaches a JSX child in readings/, transit/, settings/, shell/, cards/, lore/, gallery/, account/, ask/ or setup/ (criterion 16b/20b, AC-17)
  ● no file under settings/ or setup/ names the paid or card channels (native-settings AC-7)
    +   "setup/SetupFlow.tsx",
Tests:       1 failed, 35 skipped, 36 total
Ran all test suites matching /src\/native-guards.test.ts/i with tests matching "settings/ or setup/ names the paid".
--- reverted ---
  ✓ no file under settings/ or setup/ names the paid or card channels (native-settings AC-7) (2 ms)
Tests:       35 skipped, 1 passed, 36 total
 M src/native-guards.test.ts
(git status above)
=== PROBE 4 (planted: '#c9a45c' + fetch( in setup/StepMarks.tsx) ===
    +   "app-native/src/setup/StepMarks.tsx: #c9a45c",
    +   "app-native/src/setup/StepMarks.tsx",
Tests:       2 failed, 48 passed, 50 total
--- reverted ---
Tests:       50 passed, 50 total
```
(Probe 1 is the raw-JSX-literal walk that `setup` just joined; probes 2–3 the paid/card-channel
walk that `setup` just joined; probe 4 the existing colour guard and architecture rule-5 fetch
guard, which already walk `app-native/src` — two failures, one per guard.) The trailing
` M src/native-guards.test.ts` was the step-8 guard edit itself, committed in bf355b6.

## AC coverage by jest (component/App level)
AC1, AC2, AC3, AC4, AC5, AC7, AC8, AC9, AC10, AC16, AC17, AC18 — `src/App.test.tsx`;
AC13 — `src/App.light-ground.test.tsx`; AC11, AC12, AC14, AC15, AC16 (component) —
`src/setup/setup.test.tsx`; AC15 unit half — `src/birth-input/birth-form.test.tsx`;
AC18 unit half — `src/setup/setup-progress.test.ts`; AC19 — birth-sheet, city-picker,
settings suites unchanged and green; AC20 — i18n parity + guards (probes above);
AC21 — this file. AC6, AC22, AC23, AC24 are device checks (plan step 10, coordinator).

Status: steps 1–9 green → ready for the coordinator's step 10.
