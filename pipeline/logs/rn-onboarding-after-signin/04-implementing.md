# 04 — implementing (worker, worktree ../astrology-wt/rn-onboarding-after-signin)

Branch `feature/rn-onboarding-after-signin` from dev @ 5d72459.

## Step 1 — core sync phase
- `packages/core/src/account/sync.ts`: `AccountSync` ('idle'|'pulling'|'ready'|'failed'),
  `getAccountSync`/`subscribeAccountSync`; `startSync` sets `pulling` on entry,
  `failed` on an aborted pull, `ready` after adopt/push and before push-on-save
  arms; `stopSync` sets `idle`; a superseded generation sets nothing.
- `index.ts` exports them (+ type).
- Tests: `app-native/src/account/core-account.test.ts` C7 (4 tests: transitions,
  adopt-before-ready, failed on 500 and throw, stale pull after logout stays idle).
- `npx jest src/account` → 3 suites, 46 tests passed. `npm run typecheck` green.

## Step 2 — app hooks + progress key
- NEW `app-native/src/account/useAccountSync.ts` (useSyncExternalStore over the phase).
- NEW `app-native/src/setup/setup-progress.ts` (`astrology.setup.v1`, `language`|`birth`,
  best-effort read/write/clear over core `getKV()`), `setup-progress.test.ts` (8 tests:
  key name, round-trip, 4 junk values, throwing KV, KEPT_KEYS excludes the key and keeps
  lang + ground).
- `npx jest src/setup` → 8 passed; architecture + native-guards → 83 passed; tsc green.

## Step 3 — lift BirthForm
- NEW `app-native/src/birth-input/BirthForm.tsx` ({initial, active, onSaved, submitLabel?, type?}):
  the form body verbatim (dials, switch, CityPicker, validation, saveBirthData, errors,
  submit, save-failed) + the pure helpers + the form's styles. Raw `<Text>` tags and their
  `text-variant: local` markers moved with the code (5 tags, 5 markers; totals unchanged).
- CHG `BirthSheet.tsx`: Modal + KeyboardAvoidingView scrim + dismiss + grip + ScrollView +
  serif title + `<BirthForm active={visible} onSaved={onClose}>` + `sheet-cancel`.
- Guard pin repointed (equal strength): `surface-paint-rulings.test.tsx` E1 (`submit`/
  `submitPressed`) and field (`row`/`rowOpen`) now name `birth-input/BirthForm.tsx`, where
  those StyleSheet entries now live.
- NEW `birth-input/birth-form.test.tsx` (4 tests: shared fields + no dismiss/cancel; empty
  submit → date + place errors, no save, no onSaved; submitLabel; valid save → onSaved once).
- `npx jest src/birth-input src/settings` + paint/text/type/colour/architecture/native guards
  → 12 suites, 174 tests passed. tsc green.

## Step 4 — opening `still` + children
- CHG `app-native/src/opening/OpeningPrototype.tsx`: `still?` (shared values and the static
  `visible` twin start at 1; a dedicated effect fires `onDone` via `setTimeout(…, 0)`;
  the sequence effect never runs) and `children?` rendered in the lower flex region
  (`testID="opening-lower"`), so the block never moves. No figure added (0/1 only), same
  import set (+ `type ReactNode` from react).
- `opening.test.tsx` +3 tests (still with probe+fonts pending → visible, no timing, onDone at
  next tick once; still with probe answering → no sequence; children in the lower region
  after the block, sequence unchanged). AC-6/AC-7 pins pass unchanged.
- `npx jest src/opening` → 12 passed; tsc green; text-variant/native/architecture guards 88 passed.

## Step 5 — gate as controls
- CHG `app-native/src/account/SignInGate.tsx`: `{ revealed: boolean }`; no page, no ground,
  no wordmark, no `useWindowDimensions().height`/`WORDMARK_Y`; root `sign-in-gate` is the
  controls root (`flex: 1`, centred, fills the opening's lower region). Buttons from
  `revealed && signed-out`; notes/Try again only when revealed; fade (400 ms) starts on that
  edge; Reduce Motion → at once. Every provider/note/Apple-slot behaviour unchanged.
- `grep brand.wordmark app-native/src/account/SignInGate.tsx` → no match.
- Tests: `sign-in-gate.test.tsx` U1 wordmark assertions inverted (no wordmark); checking →
  nothing (no buttons/note/retry); NEW U4 (not revealed × signed-out/unavailable/offline →
  nothing, no withTiming; revealed later → one 400 ms fade; no ground/no header).
  `text-variant-rulings.test.tsx` gate ruling: "wordmark = title" → `not.toContain
  ('brand.wordmark')` + `not.toMatch(/variant="title"/)` (stronger: the gate may carry no
  display title at all); the note-count (3) and the one-raw-Text pins unchanged.
- App.tsx: minimal compile fix only (`<SignInGate revealed />`, same behaviour as before);
  the composer is step 7.
- `npx jest src/account src/text-variant-rulings.test.tsx src/text-variant-guard.test.ts
  src/surface-paint-rulings.test.tsx` → 104 passed; App.test 4 passed; tsc green.

## Step 6 — setup screens (frontend-design skill loaded before steps 3/5/6)
- NEW `app-native/src/setup/`: `SetupFlow.tsx` (step state from `initialStep`; ground tap:
  same → progress `language` + Language step; other → progress `language`, `setGround`,
  `requestReload` once — a `leaving` ref drops further taps; language tap → `setLanguage`,
  progress `birth`, Birth step; Birth `onSaved` → `clearProgress()`), `AppearanceStep.tsx`
  (two plates: a 3:4 miniature page in the plate's OWN ground from `GROUND_TOKENS[g]` —
  ground fill, `line` hairline, two `theme` rules echoing the opening's two lines; label under
  the plate as `<Txt variant="navLabel" tone="selected">`; frame `PAINT.chip.rest/selected/
  pressed`), `LanguageStep.tsx` ("English"/"中文" full-width pills, `<Txt variant="fieldValue">`,
  chip paint), `BirthStep.tsx` (KeyboardAvoidingView + ScrollView, title + `<BirthForm initial
  ={null} active submitLabel={dict.setup.submit}>`), `StepMarks.tsx` (three 18×2 rules,
  `PAINT.indicator` lit / `PAINT.divider` unlit; a11y label "Step N of 3").
  Every option: role button + label + `selected` state; every question `<Txt variant="title"
  accessibilityRole="header">`. Zero raw `<Text>` tags (census totals unchanged).
- CHG `i18n/en.ts`, `zh.ts`: `setup` block (D11 copy). `i18n.test.ts`'s exhaustive
  identical-to-en allowlist +`setup.english`, `setup.chinese` (same rule as `lang.en`/`lang.zh`:
  a language offers its own name in both dictionaries).
- NEW `setup/setup.test.tsx` (AC11 ×3, AC12, AC14, AC15, AC16 component-level incl. the
  recorded `PUT /api/profiles/traveler` body, + a folder import-allowlist pin).
  The "App.tsx is the only importer" pin is added in step 7 (App does not import setup yet).
- `npx jest src/setup` → 16 passed, no act() warnings; text-variant/colour/native/architecture/
  i18n/type/theme/paint/rulings suites → 283 passed; tsc green.

## Step 7 — compose in App
- CHG `app-native/src/App.tsx`: state `wordsDone`, `status` (useAccount), `sync`
  (useAccountSync), `birthData` (useBirthData), `progress` (readProgress, once per JS world).
  Render rule exactly per spec: signed-in ∧ wordsDone ∧ sync ready ∧ no birth data → SetupFlow
  (initialStep = progress); signed-in ∧ wordsDone ∧ (sync failed ∨ birth data) → AppShell;
  otherwise `<OpeningPrototype still={progress !== null}>` with `<SignInGate revealed=
  {wordsDone || (ready && reduced)}>` as its child (`idle` and `pulling` → threshold). An effect
  clears a stale progress key when sync is ready with birth data.
- REWRITTEN `src/App.test.tsx` (15 tests): AC1, AC2 (same host instance), AC3, AC4 (checking →
  lines only; whoami 503 → unavailable note + Try again under the lines), AC5 (doors never at
  any 250 ms tick), AC7 (Google mocked → Appearance), AC8, AC9, AC10, stale-key cleared, AC16
  end-to-end (PUT body, key removed, tab-chart), AC17, AC18 (on mmkvKV: logout mid-setup →
  key gone, lang + ground kept, one reload), status bar ×2. The fetch stub leaves the shell's
  own channels (chart, transits) in flight.
- NEW `src/App.light-ground.test.tsx` — AC13. DEVIATION from plan wording ("jest.isolateModules"):
  an isolateModules sandbox re-required React/reanimated and failed with a null dispatcher
  inside reanimated's `useSharedValue` (two React instances). A sibling file that applies
  `light` and then `require`s App proves the same claim (ground applied before App's modules
  evaluate) with one module world. Asserts no withTiming, the Language step, page background
  `GROUND_TOKENS.light.ground`.
- `setup/setup.test.tsx` + the pin "nothing but App.tsx imports setup/ (tests aside)".
- Full app-native jest: 97 suites, 1186 tests passed. tsc green.

## Step 8 — guards + headers
- CHG `native-guards.test.ts`: `setup` joins the raw-JSX-literal walk and the paid/card-channel
  walk (settings AC-7 test now walks `settings/` + `setup/`; titles and comments updated).
  Both strictly widen coverage.
- Headers: App.tsx, OpeningPrototype.tsx, SignInGate.tsx, BirthSheet.tsx (+ BirthForm.tsx)
  were rewritten in their steps; `platform/account-boot.ts`'s "the gate shows only the
  wordmark" sentence updated now. Census totals did not move (setup has zero raw tags), so
  the text-variant-guard comment block is unchanged.
- Plant-and-revert probes: see 05-validating.md (all four turned their guard red, all
  reverted green).
- Full `npm test` (jest 97 suites / 1186 tests; vitest 48 files / 447 tests) and `npm run
  typecheck` green. The jest "A worker process has failed to exit gracefully" line is
  PRE-EXISTING: reproduced on the base commit 5d72459's sources (1141 tests) in this worktree;
  `--detectOpenHandles` over every suite this feature touched reports no open handle.
