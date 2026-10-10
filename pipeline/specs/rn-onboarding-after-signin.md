# rn-onboarding-after-signin — the opening is the sign-in page, and a first sign-in runs a three-step setup

## Goal

QUEUE.md `rn-onboarding-after-signin` (user, 2026-09-30, incl. the same-day
addition). The sign-in gate becomes the opening page itself: the two words play,
then the Google/Apple buttons appear beneath them on that same page. After a
sign-in into an account with no birth profile, the app runs Appearance → Language
→ Birth data before it opens; an account that has a profile goes straight in.

## Non-goals

- No change to the server, the wire, `/api/profiles`, the sign-in routes or the
  bearer pair. No migration.
- No change to sign-in itself: the providers, the gate's states and copy
  (signing in, failed, no email, unavailable, offline + Try again, not-set-up
  notes), the Apple/Google button pair and its paint stay as rn-forced-signin
  built them. Only the page they sit on changes.
- No new appearance, language or birth-data capability. Settings keeps its
  three controls unchanged; the setup writes the SAME stores Settings writes
  (`setGround` + reload, `setLanguage`, `saveBirthData`).
- The current-location anchor (Settings › Location, `LocationRow`) is not part
  of setup. "Location" in the notes is the BIRTH place, picked with the existing
  `CityPicker` inside the birth form (decided default 9).
- No skip and no back navigation inside setup; no "edit later" reminders; no
  marketing copy, no carousel, no account-creation explainer.
- No change to the opening's tunables (`theme/motion.ts` `OPENING_*`), its two
  lines, its face or its Reduce-Motion behaviour.
- web-divination is untouched.

## Decided defaults

1. **One threshold page.** The opening page and the gate are ONE mounted page
   for the whole signed-out life of the app. It plays the existing opening
   sequence unchanged (`OpeningPrototype`, reused, not re-implemented); the
   "Astrace" wordmark is removed. When the sequence has finished (the moment it
   used to hand off) AND the account status is `signed-out`, the provider
   buttons fade in below the words (the gate's existing 400 ms fade, the words
   do not move); `unavailable`/`offline` show their note + Try again in the same
   place. While the status is `unknown`/`checking`, or the words have not
   finished, only the words show. Nothing unmounts or cross-fades between the
   words and the buttons.
2. **Reduce Motion.** Words visible at once (the opening's existing reduced
   rest), and the buttons shown at once — no fade — as soon as the status is
   `signed-out`. The opening's reduced hold no longer gates the buttons.
3. **Signed-in launch.** A restored session behaves as today: the words play,
   then the page hands off to setup or the app. The buttons never appear for a
   signed-in launch.
4. **When setup runs.** Setup shows when ALL hold: the status is `signed-in`;
   the post-sign-in profile pull (core account sync) has finished successfully;
   and the device then holds no birth data (the account had none to adopt, and
   none was on the device). This is the operational meaning of "a FIRST sign-in
   (an account with no birth profile yet)". While the pull is in flight the
   threshold shows the words only. If the pull FAILS, setup is not shown and the
   app opens as it does today (its existing first-run entry asks for birth data)
   — a returning user on a bad network is never asked to re-enter data the
   account already holds.
5. **Setup persists until it is finished.** Setup is finished when birth data is
   saved. An account that signs in, picks an appearance and then quits sees
   setup again at its next launch, resuming at the step it reached. Progress is
   a device key (`astrology.setup.v1`, values `language` | `birth`), cleared
   when setup finishes, and NOT kept by the session-end wipe (only language and
   appearance are kept), so sign-out mid-setup forgets it. A stale key with
   birth data present is cleared and ignored.
6. **Steps.** Fixed order Appearance → Language → Birth data; forward only. A
   tap on an option IS the choice and advances; there is no separate Continue
   on the first two steps. Each step marks the device's current value
   (fresh device: Dark, English).
7. **Appearance applies immediately.** Choosing the ground already in use
   advances with no reload. Choosing the other one stores the progress key
   (`language`), then calls the existing `setGround` and `requestReload`. After
   the reload, while the progress key is present, the threshold shows the words
   at rest at once (no fade sequence, no hold) and hands to the Language step as
   soon as restore + pull settle — the user sees the next step in the new
   appearance, not the opening again.
8. **Language applies immediately** through `setLanguage` (live, no reload);
   the Birth step renders in the chosen language.
9. **Birth data reuses the existing form.** The birth-input form body (date and
   time dials, time-unknown switch, `CityPicker`, core validation, the
   `saveBirthData` write) is lifted out of `BirthSheet` so the sheet and the
   setup render the SAME form; the sheet keeps its modal, grip and dismiss. In
   setup the form sits on a full page (no dismiss) under the step title; its
   submit reads "Open my chart" / "打开我的星盘". A successful save sends the
   data to the account through core's existing push-on-save (`PUT
   /api/profiles/<slot>`), clears the progress key, and the app opens on the
   chart. Validation errors and "save failed" show exactly as in the sheet.
10. **Look.** Every step stands on the threshold's ground with the same quiet:
    a three-mark progress row (current mark lit), one question in the display
    serif, and the answers. Appearance answers are two plates, each printed in
    its OWN ground's colours (read from `GROUND_TOKENS`, never a literal) with
    its label (Dark / Light, 深色 / 浅色); Language answers are "English" and
    "中文", each in its own script; the selected answer carries the existing
    selected paint. Text is `<Txt variant>` only, paint from `PAINT`, colour
    from tokens (rules 13 and 15); any new raw text tag is a deliberate census
    change.
11. **Copy (en / zh).** Appearance: "How should Astrace look?" / "Astrace 的外观";
    Language: "Which language?" / "选择语言"; Birth: "When and where were you
    born?" / "你在何时何地出生？"; submit as in 9; the step row's accessibility
    label "Step N of 3" / "第 N 步，共 3 步". New keys in both dictionaries
    (parity test).
12. **Accessibility.** Each option is a button with its label and a
    selected-state; the step title is a header.
13. **Earlier decisions this feature revises** (tier 3, Decision precedence):
    the opening-animation-prototype approval (2026-08-29: "a standalone
    two-line opening page mounted first by App.tsx" that hands off to the app)
    — the opening now also hosts the gate; and rn-forced-signin's gate design
    (spec D16, approved 2026-09-30: wordmark at ~38 %, the opening handing off
    to a separate gate page, "the wordmark only" while checking) — replaced by
    1–2. Their code, tests and docs are amended in this feature and the journal
    entry names them under Supersedes.
14. **Device verification harness (validation only, never committed).** The
    simulator cannot complete a live Google/Apple sign-in, so device checks use:
    a throwaway Postgres cluster; a backend started from a scratch wrapper that
    monkeypatches `app.accounts.google._verify_token` (the rn-forced-signin test
    seam) to return a chosen email; and a temporary, uncommitted edit in the
    worktree making `googleIdToken()` return a fixed string. The edit is
    reverted before any commit (`git status` clean is logged). Accounts with and
    without a profile are seeded through the real routes.

## Architecture

Client-only (`app-native/src` + one additive core read). No epic file applies;
the survey below is targeted at the modules this feature changes.

### Reused as-is (file:line)

- `OpeningPrototype` (`opening/OpeningPrototype.tsx:54`) — the sequence, its
  font/Reduce-Motion gating (:70–90) and its `onDone` JS timer.
- Gate behaviour (`account/SignInGate.tsx:74–152`): provider calls, status →
  note mapping, Apple slot, busy/line state, Try again → `bootAccount`.
- `bootAccount` (`platform/account-boot.ts:32`), session end → `wipeDevice` →
  `requestReload` (:24–30); `wipeDevice` keeps only `KEPT_KEYS`
  (`platform/device-wipe.ts:29`), so the new progress key is wiped for free.
- `setGround` (`theme/ground-store.ts:89`) + `requestReload` (`theme/reload.ts:28`),
  `setLanguage` (`i18n/lang-store.ts:81`), `GROUND_TOKENS`
  (`theme/tokens.ts:281`), `PAINT.chip.selected` (`theme/paint.ts:69`).
- core account sync's pull/adopt/push (`packages/core/src/account/sync.ts:109–138`)
  and push-on-save — the setup's save reaches the account only through it.
- `useBirthData` (`birth-input/useBirthData.ts:27`), `CityPicker`.

### Module map (NEW / CHG)

```
packages/core/src/account/
  sync.ts            CHG  + a sync-phase channel (below); no behaviour change
  index.ts           CHG  + export getAccountSync, subscribeAccountSync, type AccountSync
app-native/src/
  App.tsx            CHG  the one composer: threshold | setup | shell (below)
  opening/OpeningPrototype.tsx  CHG  + `still` prop, + `children` slot beneath the words;
                          onDone semantics unchanged
  account/SignInGate.tsx        CHG  becomes the gate's CONTROLS only (buttons, note, retry),
                          no page, no wordmark; gains a `revealed` prop (words finished)
  account/useAccountSync.ts     NEW  useSyncExternalStore over core's sync phase
  birth-input/BirthForm.tsx     NEW  the form body lifted from BirthSheet.tsx:69–275
                          (state, dials, switch, CityPicker, validation, saveBirthData,
                          errors) with props { initial, active, onSaved, submitLabel?, type? }
  birth-input/BirthSheet.tsx    CHG  Modal + scrim + grip + ScrollView around <BirthForm>
  setup/                        NEW folder
    SetupFlow.tsx      the three steps; reads the progress key, renders the step
    AppearanceStep.tsx two ground plates
    LanguageStep.tsx   English / 中文
    BirthStep.tsx      title + <BirthForm submitLabel=…> on a page
    StepMarks.tsx      the three-mark progress row
    setup-progress.ts  the progress key: read / write / clear over core getKV()
  i18n/en.ts, zh.ts  CHG  + `setup` block
```

### Contracts

**core `account` (additive).** `type AccountSync = 'idle' | 'pulling' | 'ready'
| 'failed'`. `startSync` sets `pulling` on entry; `ready` after a successful
pull (adopt/push done, before push-on-save arms); `failed` on an aborted pull;
`stopSync` sets `idle`. A pull superseded by a newer generation sets nothing.
`getAccountSync()` / `subscribeAccountSync(listener) → unsubscribe` mirror the
status channel idiom (`service.ts:285`). No new request, no wire change; core
still imports no React.

**`OpeningPrototype`.** `{ onDone, still?: boolean, children?: ReactNode }`.
`still` → both lines statically visible from first render, no timing call, and
`onDone` fires on the next tick (no hold). `children` render in the lower
region below the block; the component does not know what they are. Still no
figure in the file, still imports react / react-native / reanimated / ../theme
only (AC-6/AC-7 of its own suite keep holding).

**`SignInGate`** → `{ revealed: boolean }` (App passes `wordsDone || reduced`, so under Reduce Motion the opening's hold never gates the buttons — D2). Renders nothing visible while
`!revealed`; otherwise exactly today's lower region (buttons when
`signed-out`, notes, Try again). The 400 ms fade starts from `revealed &&
signed-out`; under Reduce Motion it shows at once. testID `sign-in-gate`
moves to this controls root.

**`App.tsx` (the composer).** State: `wordsDone` (from `onDone`), `status`
(useAccount), `sync` (useAccountSync), `birthData` (useBirthData), `progress`
(read once at mount from setup-progress). Render:

```
status==='signed-in' && wordsDone && sync==='ready' && birthData===null → <SetupFlow initialStep={progress}/>
status==='signed-in' && wordsDone && (sync==='failed' || birthData!==null)  → <AppShell/>
otherwise → <OpeningPrototype still={progress!==null} onDone=…>
              <SignInGate revealed={wordsDone}/></OpeningPrototype>
```

When `sync==='ready'` and `birthData!==null` while a progress key exists, App
clears it. App still owns the one mount point of `opening/`, so the
"nothing but App.tsx imports the folder" pin is unchanged.

**`SetupFlow`.** `{ initialStep: 'language' | 'birth' | null }` (null →
appearance). Appearance tap: same ground → step = language (progress written);
other ground → `writeProgress('language')`, `setGround(g)`, `requestReload()`.
Language tap → `setLanguage(l)`, `writeProgress('birth')`, step = birth. Birth
`onSaved` → `clearProgress()`; App's render rule then mounts the shell because
`birthData` is non-null. SetupFlow names no paid seam, no `fetch`/`apiUrl`.

**`setup-progress.ts`.** Key `astrology.setup.v1`; values `language` | `birth`;
read returns null for anything else; every access best-effort (try/catch), via
`getKV()` from the `@astrace/core/platform` barrel.

**`BirthForm`.** The sheet keeps its Modal, scrim dismiss, grip and `sheet-cancel`; the sheet maps `onSaved` to its `onClose`. `active` re-seeds the draft (the sheet passes `visible`, the
step passes `true`), `onSaved` runs after `saveBirthData` succeeds. testIDs
unchanged (`sheet-date`, `sheet-time`, `sheet-time-unknown`, `sheet-submit`,
`sheet-save-failed`), so the existing birth-sheet suite is the regression
check. Raw `<Text>` tags and their census markers MOVE with the code (totals
unchanged by the split).

### Dependency rules / forbidden edges

- `setup/` may import `../birth-input`, `../theme`, `../i18n`,
  `@astrace/core/platform` (getKV), and nothing from `account/`, `shell/`,
  `screens/`, `settings/`. App.tsx is its only importer.
- `opening/` imports stay react / react-native / reanimated / ../theme; it does
  not import `account/`. Composition happens in App.tsx only.
- `account/SignInGate.tsx` does not import `opening/` or `setup/`.
- core never imports app code or i18n (rules 1, 2, 8); `useAccountSync` is the
  only app reader of the sync channel besides tests.
- No new `fetch(`/`apiUrl(` outside `src/platform/` (rule 5).

### Guard and doc amendments (equal or stronger)

- `native-guards.test.ts`: `setup` joins the raw-JSX-literal walk (:535) and
  the paid/card-channel walk that today covers `settings/` (:249).
- `text-variant-guard.test.ts` residue: changes only by the new setup files'
  raw tags, documented in the comment block (:195–223); target zero new raw
  tags (setup uses `Txt`), so totals unchanged.
- `opening/opening.test.tsx` AC-7 pin unchanged (App.tsx sole importer);
  its suite gains the `still` and `children` cases.
- `App.test.tsx` and `account/sign-in-gate.test.tsx` rewrite their wordmark
  assertions (forced-signin U1 "wordmark") to the lines-plus-buttons page.
- `i18n.test.ts` parity covers the new `setup` keys automatically.
- CLAUDE.md: no rule changes (no boundary moves). `docs/ARCHITECTURE.md` and
  the opening/gate header comments are synced at docs-sync.

### Wire shapes

None new. Setup's save is the existing `PUT /api/profiles/{nickname}` with
`{birthData}` from core push-on-save; the pull is the existing `GET
/api/profiles`.

## Acceptance Criteria

Suites: `npm test` (app-native jest, web-divination vitest), `npm run typecheck`,
`npm run server:test`. "Device" = the iPhone 17 simulator with a dev build of the
feature branch, driven per `.claude/skills/verify/SKILL.md`, using harness 14.

**Threshold (one page)**

- **AC1** (jest, App): no stored account → after the opening's full duration
  (`OPENING_FADE_MS·OPENING_OVERLAP + OPENING_FADE_MS + OPENING_HOLD_MS`) the
  tree holds `opening-line-1`, `opening-line-2` AND `sign-in-google` together,
  no text "Astrace" heading, and no `tab-chart`; 1 ms before that duration no
  `sign-in-buttons` exists.
- **AC2** (jest): the opening lines' host is the same instance before and after
  the buttons appear (the opening is not unmounted at hand-off when signed-out).
- **AC3** (jest, Reduce Motion): both lines statically visible and the buttons
  present with no `withTiming` call, as soon as the status is `signed-out`.
- **AC4** (jest): status `checking` after the words finish → lines, no buttons;
  `unavailable` → the "unavailable" note + Try again beneath the lines;
  `offline` → the offline note + Try again; every existing SignInGate behaviour
  test (busy note, failed, no-email, cancelled, not-set-up notes, Apple
  absent/disabled) passes against the new page.
- **AC5** (jest): stored valid account whose profile pull returns a profile with
  birth data → the lines first, then `tab-chart`; `sign-in-buttons` never
  appears at any tick.
- **AC6** (device): fresh install → the two lines play, then "Sign in with
  Apple" and "Sign in with Google" appear below the second line on the same
  page (idb dump: both buttons' y greater than the second line's y + height; no
  "Astrace" heading; screenshot logged).

**Setup decision**

- **AC7** (jest): signing in (provider mocked) into an account whose
  `/api/profiles` returns `{profiles: []}` with no device birth data → the
  Appearance step (`setup-appearance`) renders; no `tab-chart`.
- **AC8** (jest): while `/api/profiles` is unresolved → lines only: no setup
  step, no buttons, no `tab-chart`.
- **AC9** (jest): `/api/profiles` answers 500 → no setup step; `tab-chart`
  renders.
- **AC10** (jest): an account whose pull returns birth data → no setup step; the
  device's birth data equals the account's; `tab-chart` renders.

**Steps**

- **AC11** (jest): Appearance shows exactly two options, Dark and Light, with
  the current ground marked selected. Tapping the current ground → the Language
  step renders, no reload requested, ground unchanged.
- **AC12** (jest): tapping the other ground → the ground store holds it, the
  progress key equals `language`, and the reload seam is called exactly once.
- **AC13** (jest): booting with progress key `language`, ground `light`, a
  stored account and an empty profile pull → the Language step renders with no
  `withTiming` call on the opening lines, and the step's page background equals
  `GROUND_TOKENS.light.ground`.
- **AC14** (jest): Language shows "English" and "中文" with the current one
  selected; tapping 中文 → `getLanguage() === 'zh'`, the stored language is
  `zh`, the progress key is `birth`, and the Birth step's title reads
  "你在何时何地出生？".
- **AC15** (jest): the Birth step renders the shared form (`sheet-date`,
  `sheet-time`, `sheet-time-unknown`, the city picker) and no dismiss control;
  submitting empty shows the date and place errors and stays on the step.
- **AC16** (jest): a valid submit (1990-06-15 08:30, a picked city) → a `PUT
  /api/profiles/<slot>` whose body carries that birth data, the progress key is
  removed, and `tab-chart` renders.
- **AC17** (jest): booting with progress key `birth`, a stored account and an
  empty pull → the Birth step directly.
- **AC18** (jest): a session end mid-setup removes the progress key and keeps
  the language and ground keys.
- **AC19** (jest): `BirthSheet` in Settings still opens prefilled, saves and
  closes, and dismisses on the scrim (existing birth-sheet and settings suites
  pass); Settings still offers Dark/Light, English/中文 and the birth row.
- **AC20** (jest): every new user-visible string resolves in en and zh (i18n
  parity test), and the setup files contain no raw colour literal, no raw
  `<Text>` without a census marker, and no `fetch(`/`apiUrl(` (existing guards
  green; any census total change is documented in the guard).

**Whole suites and device**

- **AC21**: `npm test`, `npm run typecheck` and `npm run server:test` pass, with
  no guard weakened (any amended pin is equal-or-stronger and named in the
  journal).
- **AC22** (device, harness 14, empty account): sign in → Appearance → tap
  Light → the app reloads straight into the Language step on the light ground
  (pixel sample of the page background ≈ `GROUND_TOKENS.light.ground`) without
  the opening playing → tap 中文 → the Birth step in Chinese → enter a date,
  time and city, submit → the chart page with the rail. The backend log shows
  `PUT /api/profiles/… 200`, and the profile row in the throwaway db holds that
  date.
- **AC23** (device): Settings → Sign out → the threshold (lines then buttons, in
  Light and Chinese). Sign in again as the same account → no setup step; the
  chart for the saved birth data loads (`POST /api/chart 200` in the log).
- **AC24** (device, Reduce Motion on): fresh launch → both lines and both
  buttons visible in the first settled screenshot, with no fade observed across
  a 4-frame burst.
