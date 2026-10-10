# rn-ask-input-disabled — spec

## Goal

Gate the Ask screen's question input (QUEUE.md `rn-ask-input-disabled`, user-requested 2026-09-30):
the field cannot be focused, typed into or submitted, it reads as disabled, a short en/zh
"coming soon" note says why, and no `/api/ask` request can leave the app. One constant re-enables it.

## Non-goals

- No deletion or refactor of the Ask code (`AskScreen`, `QuestionField`, `FinalVersion`, `DrawRing`,
  core's `checkFitness`) or of any Ask test.
- No server change: `/api/ask/fitness` stays as it is.
- No change to the ring stage, the starter chips, the title or the rail tab. The Ask tab stays in the rail.
- No runtime or remote toggle (env var, feature-flag service, settings switch). The flag is a
  source constant.
- No new text variant, PAINT entry, token or colour.
- `DEV_ENTRY` (`ask/dev-entry.ts`) is not touched. With it switched on, a developer still mounts
  settled past the field. That is a gitignored developer shortcut and has no field to gate.

## Decided defaults

1. **The flag.** It lives in a new sibling module `app-native/src/ask/ask-gate.ts` as
   `export const ASK_INPUT_ENABLED = false`, one exported boolean constant with a short header
   comment. Re-enabling means changing `false` to `true` on that line. This follows the
   `dev-entry.ts` precedent: a sibling constant that the screen reads and that nothing else knows about.
2. **One reader.** `AskScreen.tsx` is the only non-test file that imports the flag.
   `QuestionField` does not import it. It gets a plain `disabled: boolean` prop, so it stays a
   pure, prop-driven composition (its import pin at `ask.test.tsx:833-839` is unchanged).
3. **Gated twice, like the cap.** The field is disabled at the widget (non-editable input,
   disabled ASK). `AskScreen.submit` also returns before it touches the AbortController,
   the state or `checkFitness` when the flag is off. A submit that reached the seam by any route
   still sends nothing.
4. **Keyboard submit.** There is no keyboard submit path today. The input is `multiline` with
   `returnKeyType="default"` and has no `onSubmitEditing` (`QuestionField.tsx:71-88`). The only
   caller of `checkFitness` in the app is `AskScreen.submit` (`AskScreen.tsx:152`). Gate 3 covers
   both, and nothing else needs gating.
5. **What "visibly disabled" looks like.** It reuses the field's existing inert figures and adds
   nothing new:
   - the `ask-field` wrapper takes the inert-layer opacity already used while checking (0.5,
     `QuestionField.tsx:129-133`);
   - the input is `editable={false}` and reports `accessibilityState.disabled: true`;
   - ASK is a disabled `Pressable` wearing `PAINT.actionOutlined.waiting` (`submitInert`), with
     its label in the `actionLabel` variant's `waiting` tone (textFaint) and still reading
     `ask.submit` ("ASK"), not "checking".

   The placeholder stays visible (`ask.placeholder`, or a starter's example).
6. **The note.** A new dictionary leaf, `ask.comingSoon`:
   - en: `Asking is coming soon.`
   - zh: `提问即将开放。`

   It renders only while the flag is off, in `AskScreen` directly under the `QuestionField`
   (inside the existing `field` wrapper), as `<Txt variant="note" testID="ask-coming-soon">`,
   centred. Its StyleSheet entry holds layout keys only (`marginTop: space.sm`,
   `textAlign: 'center'`). The key is `ask.comingSoon`. It does not collide with the retired
   `cards.comingSoon` that `ask.test.tsx:261-266` pins as gone: that test reads `en.cards`/`zh.cards`
   and a different string, and it stays as written.
7. **The rest of the screen stays live.** The title (which stays in its expanded face, because
   the input can never take focus), the four starter chips (a tap still swaps the placeholder;
   they fire no request) and the ring (it rolls and commits nothing) all behave as before.
8. **Existing tests keep grading the Ask code with the flag on.** The three suites that type into
   or press the field (`ask/ask.test.tsx`, `ask/ask-flow.test.tsx`,
   `text-variant-rulings.test.tsx`) each gain a top-level
   `jest.mock(<path to ask-gate>, () => ({ ASK_INPUT_ENABLED: true }))`, with no other change to
   their cases. The disabled behaviour is graded by a new suite that uses the real constant. RNTL
   13.3.3's `fireEvent` already refuses `focus`/`changeText` on a non-editable `TextInput` and
   `press` on a disabled `Pressable`, so the jest harness shows what a user sees.
9. **Proving that no request leaves.** The new suite does not mock core's ask barrel. It spies on
   `globalThis.fetch` as a property, using the `fitness-seam.test.ts:61-71` idiom, so `checkFitness`
   runs for real and would reach the spy if it were ever called. The suite must never write the
   literal token `fetch` + `(` (`ask.test.tsx:841-847` scans every file under `src/ask`).
10. **Census floor.** The `note` floor in `theme/text-variants.test.tsx:246` goes 12 → 13, with a
    provenance comment in that table's style. No raw tag or marker is added, so the
    text-variant-guard residue totals are unchanged.

## Architecture

### Reuse (file:line)

| What | Where | Used for |
|---|---|---|
| Sibling-constant seam precedent | `app-native/src/ask/dev-entry.ts:70-76` | shape of `ask-gate.ts` (one exported const, read by `AskScreen` only) |
| The one submit, the one `checkFitness` caller | `app-native/src/ask/AskScreen.tsx:146-186` | early return when the flag is off |
| Field mount + props | `app-native/src/ask/AskScreen.tsx:269-282` | pass `disabled`; render the note under it |
| Inert-layer wrapper figure | `app-native/src/ask/QuestionField.tsx:70`, `:129-133` | apply when `checking` OR `disabled` |
| Input editability | `app-native/src/ask/QuestionField.tsx:81` | `editable={!checking && !disabled}` + `accessibilityState` |
| ASK inert paint + tone | `QuestionField.tsx:94`, `:101`, `:105`, `:149-151` | disabled when `!canSubmit` OR `disabled`; inert paint and `waiting` tone when disabled |
| `note` variant | `app-native/src/theme/text-variants.ts:59` | the coming-soon line |
| Dictionary ask block | `app-native/src/i18n/en.ts:523-`, `app-native/src/i18n/zh.ts` ask block | new leaf `ask.comingSoon` beside `checking` |
| fetch-spy idiom | `app-native/src/ask/fitness-seam.test.ts:61-77` | new suite's no-request proof |

### Module map (delta only)

```
app-native/src/ask/
├── ask-gate.ts            NEW: ASK_INPUT_ENABLED = false (the one home of the flag)
├── ask-gate.test.tsx      NEW: disabled-state suite (real flag, real core, spied fetch)
├── AskScreen.tsx          CHANGED: reads the flag; gates submit; passes `disabled`; renders the note
├── QuestionField.tsx      CHANGED: `disabled` prop → non-editable input, inert wrapper, disabled ASK
├── ask.test.tsx           CHANGED: jest.mock flag ON; import pin allows './ask-gate'
└── ask-flow.test.tsx      CHANGED: jest.mock flag ON
app-native/src/i18n/en.ts, zh.ts            CHANGED: ask.comingSoon
app-native/src/text-variant-rulings.test.tsx CHANGED: jest.mock flag ON
app-native/src/theme/text-variants.test.tsx  CHANGED: note floor 12 → 13
```

### Contracts

- **`ask-gate.ts`** exports `ASK_INPUT_ENABLED: boolean` and nothing else. It imports nothing. It
  owns the fact that the Ask input is open. It does not read env vars, `__DEV__` or storage.
- **`QuestionField`** gains the required prop `disabled: boolean`. When it is true: the input is
  non-editable with `accessibilityState={{ disabled: true }}`, the `ask-field` wrapper is inert
  (0.5), and ASK is `disabled` with `accessibilityState.disabled` true, `submitInert` paint and the
  `waiting` tone. Its `onPress` also returns without calling `onSubmit`. The label stays
  `ask.submit`. Its imports stay `react`, `react-native`, `../i18n` and `../theme`. It still sends
  nothing (rule 5).
- **`AskScreen`** imports `ASK_INPUT_ENABLED` from `./ask-gate`. `submit(normalized)` is a no-op
  when the flag is false: no abort, no state change, no `checkFitness`. It passes
  `disabled={!ASK_INPUT_ENABLED}` and renders `ask-coming-soon` only when the flag is false.
  Nothing else in the file branches on the flag.
- **Wire**: unchanged. Nothing new goes over the network, and while the flag is off nothing goes at all.

### Dependency rules / forbidden edges

- `ask-gate.ts` has no imports. Only `AskScreen.tsx` imports it among non-test files. Test files
  may mock it.
- ❌ `QuestionField.tsx` must not import `./ask-gate`. The flag enters it as a prop, so the field
  stays testable in both states and its import pin holds.
- ❌ No file outside `app-native/src/ask/` reads the flag. The shell (`shell/AppShell.tsx:67`)
  mounts `<AskScreen />` unchanged.
- Rules 5, 8, 13 and 15 are unchanged. No `fetch(`/`apiUrl(` token is added under `src/ask`. The new
  string is a dictionary leaf. The note is a `<Txt variant>` with `variant` on the `<Txt` line.
  No colour literal and no inline colour are used. The inert look comes from existing PAINT and tone.

### Guard / test amendments

- `ask/ask.test.tsx:795-814`: the AskScreen import allowlist gains `'./ask-gate'`, with a comment
  citing this feature. Nothing is weakened: the list is an allowlist and gets one named sibling.
- `theme/text-variants.test.tsx:246`: the `note` floor goes 12 → 13, with a provenance comment.
- `text-variant-guard.test.ts` (`RAW_TAG_TOTAL` 53, `MARKER_TOTAL` 61 — the constants at :220-222; the test title's "48/55" is stale), `color-guard.test.ts`,
  `architecture.test.ts`, `surface-paint-rulings.test.tsx` and `i18n/i18n.test.ts` are not edited
  and must pass as they are. The parity test covers the new leaf in both dictionaries.
- CLAUDE.md is not amended. No boundary moves.

## Acceptance Criteria

Unless a criterion says otherwise, each one is checked with `npx jest` from `app-native/`. AC-1
to AC-6 are graded in `app-native/src/ask/ask-gate.test.tsx`, which uses the real `ask-gate`
constant, the real `@astrace/core/ask` barrel and a `jest.spyOn(globalThis, 'fetch')` spy.

- **AC-1 The one flag.** `app-native/src/ask/ask-gate.ts` exports `ASK_INPUT_ENABLED` equal to
  `false`. Among non-test files under `app-native/src`, exactly one file (`ask/AskScreen.tsx`)
  contains the specifier `./ask-gate` or `ask-gate'`. `QuestionField.tsx` does not.
- **AC-2 Visibly disabled (en).** On a mounted `<AskScreen />`:
  - `ask-input` has `props.editable === false` and `accessibilityState.disabled === true`;
  - the flattened `ask-field` style has `opacity` 0.5;
  - `ask-submit` has `accessibilityState.disabled === true`;
  - the ASK label reads `en.ask.submit` in `tokens.textFaint`;
  - `ask-coming-soon` renders the text `Asking is coming soon.` at the `caption` font size in
    `tokens.textFaint` (the `note` binding).
- **AC-3 zh.** After `setLanguage('zh')`, `ask-coming-soon` reads `提问即将开放。` and the ASK
  label reads `zh.ask.submit`. `en.ask.comingSoon === 'Asking is coming soon.'` and
  `zh.ask.comingSoon === '提问即将开放。'`. `i18n/i18n.test.ts` passes.
- **AC-4 Cannot focus or type.** `fireEvent(ask-input, 'focus')` leaves `ask-intro-expanded`
  rendered and `ask-how-short` absent. `fireEvent.changeText(ask-input, 'why do I keep doing this')`
  leaves `ask-input`'s value `''`.
- **AC-5 No request leaves.** In one test: focus the input, `changeText` it, press `ask-submit`,
  tap each of the four `ask-domain-*` chips, and then call the `onSubmit` prop of the rendered
  `QuestionField` element directly with `'why do I keep doing this'` inside `act`, flushing
  pending promises. After all of that, the `fetch` spy has 0 calls (so no URL containing
  `/api/ask` was requested), `ask-submit` still exists, and neither `ask-final` nor `ask-decline`
  is rendered.
- **AC-6 The rest of the screen stays.** With the flag off, these all render: `ask-title`, the four
  `ask-domain-*` chips in `DOMAINS` order, the ring stage (`draw-ring-scroll` and `ring-band`),
  and `ask-submit`. Tapping `ask-domain-career` changes `ask-input`'s placeholder to
  `en.ask.example.career`.
- **AC-7 Re-enabling is the one line.** `ask/ask.test.tsx`, `ask/ask-flow.test.tsx` and
  `text-variant-rulings.test.tsx` each mock `ask-gate` to `{ ASK_INPUT_ENABLED: true }`. With that
  mock and no other edit to their cases, every existing case passes: typing, ASK → `checkFitness`,
  the plate, ASK THIS → settled, and the ASK label's accent/waiting rulings. No existing Ask test
  case is deleted. Evidence is `git diff --stat` plus the case counts before and after. With the
  flag on, `ask-coming-soon` is absent. That is asserted in `ask.test.tsx` or in the new suite
  through a mock.
- **AC-8 Guards hold.** `npx jest src/architecture.test.ts src/color-guard.test.ts
  src/text-variant-guard.test.ts src/theme/text-variants.test.tsx src/surface-paint-rulings.test.tsx`
  passes:
  - the residue constants stay at `RAW_TAG_TOTAL` 53 and `MARKER_TOTAL` 61;
  - the `note` floor is 13 and met;
  - the AskScreen import pin in `ask.test.tsx` allows `./ask-gate`;
  - the "no `fetch(`/`apiUrl(` under `src/ask`" scan passes, including the new suite.
- **AC-9 Whole suites.** `npm test` and `npm run typecheck` at the repo root both pass.
- **AC-10 Loop closed on the simulator.** Setup per `.claude/skills/verify/SKILL.md`: the
  backend runs with its access log visible, and the dev client is on the iOS simulator. Open the
  Ask tab, tap the question field, then tap ASK. The result must be:
  - no keyboard appears and no caret shows in the field;
  - the field and ASK look dimmed;
  - `Asking is coming soon.` shows under the field;
  - the title, the four chips and the ring are still on screen;
  - the backend access log shows no line containing `/api/ask` for the whole session.

  Switching the app language to 中文 shows `提问即将开放。`. Screenshots and the log excerpt are
  recorded in the validating log.
