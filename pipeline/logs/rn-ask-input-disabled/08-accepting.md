# rn-ask-input-disabled — accepting (fresh-context acceptance check)

Checker: fresh context, no sight of the implementation before this run.
Code under test: worktree `/Users/kaimao/Projects/astrology-wt/rn-ask-input-disabled`,
branch `feature/rn-ask-input-disabled` (HEAD f8f8fb4; clean tree), compared with `git diff dev...HEAD`.
Scope: the spec's Acceptance Criteria section only (AC-1 … AC-10).
Scratch / evidence dir: `/private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/ask-accept/`.

## Diff under test

```
git diff dev...HEAD --stat
 app-native/src/ask/AskScreen.tsx             |  21 +++
 app-native/src/ask/QuestionField.tsx         |  16 ++-
 app-native/src/ask/ask-flow.test.tsx         |   6 +
 app-native/src/ask/ask-gate.test.tsx         | 193 +++++++++++++++++++++++++++
 app-native/src/ask/ask-gate.ts               |  13 ++
 app-native/src/ask/ask.test.tsx              |  18 +++
 app-native/src/i18n/en.ts                    |   2 +
 app-native/src/i18n/zh.ts                    |   2 +
 app-native/src/text-variant-rulings.test.tsx |   6 +
 app-native/src/theme/text-variants.test.tsx  |   2 +-
 docs/ARCHITECTURE.md                         |  41 +++++-
 docs/text-variant-census.md                  |  26 +++-
 12 files changed, 335 insertions(+), 11 deletions(-)
```

## Commands and verbatim results

### The graded suite (AC-1 … AC-6)

`npx jest src/ask/ask-gate.test.tsx` (app-native/):
```
PASS src/ask/ask-gate.test.tsx
  AC-1 — the one flag
    ✓ ask-gate exports ASK_INPUT_ENABLED = false
    ✓ among non-test files under src, only ask/AskScreen.tsx names the gate; QuestionField does not
  AC-2 — visibly disabled (en)
    ✓ the input is non-editable and reports disabled; the field dims; ASK is disabled in the waiting tone
    ✓ the coming-soon line reads en.ask.comingSoon in the note binding (caption × textFaint)
  AC-3 — zh
    ✓ the dictionary carries both leaves
    ✓ after setLanguage(zh) the note and the ASK label are the zh leaves
  AC-4 — cannot focus or type
    ✓ a focus leaves the intro expanded; a changeText leaves the value empty
  AC-5 — no request leaves
    ✓ focus, type, ASK, every starter, then the seam called directly: the fetch spy sees nothing
  AC-6 — the rest of the screen stays
    ✓ title, the four starters in DOMAINS order, the ring stage and ASK all render
    ✓ a starter still swaps the placeholder
Tests:       10 passed, 10 total
```
Suite checked against the spec's setup: real `./ask-gate` (no mock), real `@astrace/core/ask`
(no mock), `jest.spyOn(globalThis, 'fetch')`.

### Non-vacuity flips (each reverted with `git checkout`; tree confirmed clean after)

1. Flag flipped `false` → `true` in `ask-gate.ts`:
   ```
   ✕ ask-gate exports ASK_INPUT_ENABLED = false
   ✓ among non-test files ... (static scan, unaffected by the value — expected)
   ✕ the input is non-editable and reports disabled; ...
   ✕ the coming-soon line reads en.ask.comingSoon ...
   ✓ the dictionary carries both leaves (dictionary, unaffected — expected)
   ✕ after setLanguage(zh) the note and the ASK label are the zh leaves
   ✕ a focus leaves the intro expanded; a changeText leaves the value empty
   ✕ focus, type, ASK, every starter, then the seam called directly: the fetch spy sees nothing
   ✓ title, the four starters ... (AC-6 is "stays with the flag off"; also true when on — expected)
   ✓ a starter still swaps the placeholder
   Tests:       6 failed, 4 passed, 10 total
   ```
2. Only the second gate removed (deleted `if (!ASK_INPUT_ENABLED) return` from `AskScreen.submit`,
   widget gate left intact), `-t AC-5`:
   ```
   ✕ focus, type, ASK, every starter, then the seam called directly: the fetch spy sees nothing
   Expected number of calls: 0
   Received number of calls: 1
   ```
   So AC-5's direct `onSubmit` call really reaches the network edge through real core; the gate
   is what holds it.
3. `import './ask-gate'` appended to `QuestionField.tsx`, `-t AC-1`:
   ```
   ✕ among non-test files under src, only ask/AskScreen.tsx names the gate; QuestionField does not
   ```
After each: `git checkout <file>`; `git status --short` empty.

### AC-7 — the re-enable suites

`git diff dev...HEAD --numstat` on the three suites: `6 0 ask-flow.test.tsx`, `18 0 ask.test.tsx`,
`6 0 text-variant-rulings.test.tsx` — additions only; `grep '^-[^-]'` on their diff returns nothing
(no case deleted, no line changed). Each adds `jest.mock('./ask-gate' | './ask/ask-gate', () => ({ ASK_INPUT_ENABLED: true }))`.

Case counts (`it(` in source; dev vs HEAD) and jest assertion counts at HEAD:
```
src/ask/ask.test.tsx               dev: 48  head: 49   (jest: 49)  +1 = the "gate open → no note" case
src/ask/ask-flow.test.tsx          dev: 6   head: 6    (jest: 6)
src/text-variant-rulings.test.tsx  dev: 28  head: 28   (jest: 28)
```
`npx jest src/ask/ask.test.tsx src/ask/ask-flow.test.tsx src/text-variant-rulings.test.tsx`:
```
PASS src/ask/ask-flow.test.tsx
PASS src/text-variant-rulings.test.tsx
PASS src/ask/ask.test.tsx
Tests:       83 passed, 83 total
```
The added case in `ask.test.tsx` ("rn-ask-input-disabled — with the gate open there is no note")
asserts `queryByTestId('ask-coming-soon')` is null and `ask-input` is editable under the ON mock.

### AC-8 — guards

`grep` in `text-variant-guard.test.ts`: `const MARKER_TOTAL = 61`, `const RAW_TAG_TOTAL = 53`.
`git diff dev...HEAD --stat` on text-variant-guard / color-guard / architecture /
surface-paint-rulings / i18n tests: empty (unedited).
`theme/text-variants.test.tsx`: `note: 13` with provenance comment. `ask.test.tsx` AskScreen import
allowlist gains `'./ask-gate'` with a comment. No `fetch(`/`apiUrl(` in any `src/ask/*` file (the
architecture scan excludes test files by design; the new suite contains no `fetch(` either).

`npx jest src/architecture.test.ts src/color-guard.test.ts src/text-variant-guard.test.ts src/theme/text-variants.test.tsx src/surface-paint-rulings.test.tsx src/i18n/i18n.test.ts`:
```
PASS src/i18n/i18n.test.ts
PASS src/color-guard.test.ts
PASS src/text-variant-guard.test.ts
PASS src/theme/text-variants.test.tsx
PASS src/architecture.test.ts
PASS src/surface-paint-rulings.test.tsx
Tests:       104 passed, 104 total
```

### AC-9 — whole suites (repo root of the worktree)

`npm test` (script: `npm test --workspace app-native && npm test --workspace web-divination`):
```
Test Suites: 92 passed, 92 total
Tests:       1091 passed, 1091 total
 Test Files  47 passed (47)
      Tests  445 passed (445)
```
(vitest ran, so the jest leg exited 0 under `&&`; one "worker failed to exit gracefully" warning,
not a failure.)
`npm run typecheck`: exit 0 (`tsc --noEmit` app-native, then web-divination, no output).

### AC-10 — simulator (per device-rules.md)

- Backend: own uvicorn on :8001 from the worktree, `DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_dev`,
  `WEB_DATABASE_URL=` and all LLM/image keys blank; access log to `backend.log`.
- Metro: own, :8091, `EXPO_PUBLIC_API_BASE=http://localhost:8001 APP_VARIANT=dev`.
- Freshness: fetched the bundle from :8091 (12 MB) —
  `'Asking is coming soon.' in b → True`, `'ask-coming-soon' in b → True`, `'localhost:8001' in b → True`.
  Metro log: `iOS Bundled 5059ms app-native/index.ts (1627 modules)` on relaunch.
- Simulator iPhone 17 `7DB5C491-…`, `com.astrace.app.dev` terminated and opened on `…localhost%3A8091`.

Screens (scratch dir):
- `02-ask.png` — Ask tab: title "ASK WHAT MATTERS MOST. / LET THE UNIVERSE LEAD YOU", ring stage,
  chips LOVE / CAREER / BONDS / SELF, the field with placeholder "what's on your mind?", ASK, and
  "ASKING IS COMING SOON." centred under the field (note variant, uppercased by its role).
- `03-after-field-tap.png` — after tapping the field (201,688 pt): identical to 02; no keyboard,
  no caret, title stays in its expanded face.
- `04-after-ask-tap.png` — after tapping ASK (343,744 pt): identical; no checking label, no plate.
- `06-ask-zh.png` — after Settings → 中文: note reads "提问即将开放。", ASK reads "提问", chips 爱情/事业/亲友/自我.
- `07-zh-after-taps.png` — field and ASK tapped again in zh; still no keyboard/caret.
- `08-settings-en-restored.png` — language restored to EN.
- `09-baseline-dev-8081-ask.png` — the same tab on the user's Metro (branch dev, pre-feature), for comparison.

Dimming, pixel-measured (PIL luminance, max / median over the placeholder box):
```
feature field (placeholder box)  (71, 13.0)
baseline field (placeholder box) (133, 17.0)
feature ASK label                (133, 9.0)
baseline ASK label               (133, 9.0)
```
The field is dimmed (placeholder peak 133 → 71, the 0.5 inert layer). The ASK label is in the
faint waiting face. That matches the dev baseline, where an empty field already shows ASK inert, so
at an empty field the gate does not dim ASK any further. It reads as dimmed, as the criterion asks,
and the unit suite pins it `disabled` + `textFaint`.

Backend access log, whole session:
```
INFO:     127.0.0.1:64020 - "GET /api/auth/whoami HTTP/1.1" 401 Unauthorized
INFO:     127.0.0.1:64020 - "POST /api/auth/token/refresh HTTP/1.1" 401 Unauthorized
INFO:     127.0.0.1:64020 - "POST /api/chart HTTP/1.1" 200 OK
INFO:     127.0.0.1:64025 - "POST /api/analysis HTTP/1.1" 200 OK
INFO:     127.0.0.1:64020 - "POST /api/analysis/deck HTTP/1.1" 200 OK
INFO:     127.0.0.1:64060 - "POST /api/analysis/deck HTTP/1.1" 200 OK
--- /api/ask count: 0
```

Cleanup (mandatory, done): app terminated, reopened on `…localhost%3A8081` (loaded; Ask tab
rendered the dev-branch screen, then tapped back to CHART); language left at EN; stopped only my
own PIDs 81254 (uvicorn :8001) and 81181 (Metro :8091) via python `os.kill`. After cleanup
:8000, :8081 (`packager-status:running`) and :5173 are still listening, :8001/:8091 are gone.
Worktree `git status --short` is empty.

## Per-criterion verdict

| AC | Verdict | Evidence |
|----|---------|----------|
| AC-1 The one flag | PASS | `ask-gate.ts` exports `ASK_INPUT_ENABLED: boolean = false`; scan finds only `ask/AskScreen.tsx`; the flag flip and the QuestionField-import flip each turn it red |
| AC-2 Visibly disabled (en) | PASS | editable false, a11y disabled, ask-field opacity 0.5, ask-submit disabled, ASK label `en.ask.submit` in textFaint, note "Asking is coming soon." at caption size in textFaint; red under the flag flip |
| AC-3 zh | PASS | zh note `提问即将开放。`, ASK `zh.ask.submit`; both dictionary leaves exact; `i18n.test.ts` passes |
| AC-4 Cannot focus or type | PASS | intro stays expanded, `ask-how-short` absent, value `''`; red under the flag flip |
| AC-5 No request leaves | PASS | fetch spy 0 calls after the full sequence including the direct `onSubmit`; ask-submit present; no final/decline. Removing gate 2 alone gives 1 call, so the test is not vacuous |
| AC-6 Rest of screen stays | PASS | title, 4 chips in DOMAINS order, draw-ring-scroll + ring-band, ask-submit; career chip swaps placeholder to `en.ask.example.career` |
| AC-7 Re-enable is one line | PASS | 3 suites mock the gate ON; additions only, no case deleted (48→49, 6→6, 28→28); 83/83 pass; the gate-open no-note case is present |
| AC-8 Guards hold | PASS | 104/104; RAW_TAG_TOTAL 53, MARKER_TOTAL 61 unchanged; note floor 13; allowlist has `./ask-gate`; network scan passes |
| AC-9 Whole suites | PASS | jest 1091/1091 (92 suites), vitest 445/445 (47 files); typecheck exit 0 |
| AC-10 Simulator | PASS | fresh bundle proven; after tapping the field and ASK there is no keyboard and no caret; field dimmed (pixel 133→71) and ASK in its faint inert face; note under the field; title, chips and ring present; zh shows `提问即将开放。`; 0 `/api/ask` lines in the access log |

All ten criteria pass.

Transition: accepting → done
