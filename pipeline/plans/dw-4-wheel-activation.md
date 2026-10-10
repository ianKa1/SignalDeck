# Implementation Plan: dw-4-wheel-activation

Spec: `pipeline/specs/dw-4-wheel-activation.md` (WHAT + Architecture, PASS in
`logs/dw-4-wheel-activation/02-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Parallel wave with dw-5 and dw-6.

Worktree `/Users/kaimao/Projects/astrology-wt/dw-4-wheel-activation`, branch
`feature/dw-4-wheel-activation`, worker #1: backend :8001, Vite :5174. Every
command below runs from the WORKTREE root. Pipeline files are read and
written by absolute path under `/Users/kaimao/Projects/astrology/pipeline/`.
Steps 0–5 are `implementing`, 6 is `validating`, 7 is `docs-sync`. Tick a box
only after its done-when has passed and its `/git-commit` has landed
(`(<type>): dw-4-wheel-activation — <summary>`). Load `/frontend-design`
before step 4. Automated tests use fakes only: a fake `StreamPost` and a
stubbed `fetch` that returns `chart/fixtures.ts` charts. The web suite runs as
`npx vitest run <file>` from `web-divination/`.

## Settled review notes

- **G2 baseline.** G2 is checked with
  `git diff --stat feature/divination_web...HEAD` (three dots, from the merge
  base), not `2f45dfb`. It then lists only dw-4's own paths, even after the
  working branch is merged in for conflict resolution.
- **`data-planet-node` is unconditional.** Hub-node circles always carry
  `data-planet-node="<body>"`. Read the contract as "absent or null activation
  → markup identical to dw-1, apart from `data-planet-node`". T5 asserts only
  that there is no `data-active`/`data-lit`/`data-echo`, plus dw-1's count of
  10 `[data-planet]`.
- **wheel.css rationale, corrected.** `wheel-fade` and `wheel-rise` are
  `from`-only. `wheel-draw` also has `to { stroke-dashoffset: 0 }`, but 0 is
  the resting value, so changing `both` to `backwards` looks the same. Do
  NOT edit any keyframe. Change only the fill mode on the five reveal rules.
- **Clear on transcript shrink.** `useChat` clears the activation whenever the
  persona transcript gets SHORTER than the length it last saw. That covers
  dw-6 ending or replacing a session, where a stale `"<entry>:<ref>"` chip id
  would otherwise mark a chip in the new transcript as pressed (D1).

## Steps

- [x] **0. Verify worktree prep (the coordinator did it; this step only checks).**
  Confirm the branch is `feature/dw-4-wheel-activation`. Confirm
  `node_modules/@astrace/core` resolves. Confirm `.env` and the three
  `server/data/*.se1` are symlinks into the primary checkout, and that no
  `server/data/*.db` is a symlink.
  Done when: `git branch --show-current`, `ls -l .env server/data/*.se1` and
  `npm run typecheck` all agree. Root `npm test` is green BEFORE any edit, so
  this is the baseline.

- [x] **1. The store and the mapping.**
  Files: `web-divination/src/chart/{wheel-activation.ts,wheel-activation.test.ts}` (new).
  Build the module-level store (`showRefs`, `clearActivation`,
  `getActivation`, `subscribeActivation`, `useActivation`) and the pure
  `activationFor`, exactly per the spec's contract. It does equality and set
  membership only. Imports go through barrels, and chart/divination imports
  are type-only.
  Done when: `npx vitest run src/chart/wheel-activation.test.ts` passes T1,
  T2, T3 and T6, and root `npm test` passes, which proves the G1/G4/G5 guards
  accept the new file.

- [x] **2. Wheel attributes.**
  Files: `web-divination/src/chart/{ChartWheel.tsx,ChartWheel.test.tsx}`.
  Add the optional `activation` prop: `data-active` on the svg, and
  `data-lit`/`data-echo` on planet groups, chords, conjunction dots and hub
  nodes. Hub circles gain `data-planet-node`. Leave geometry and the
  Ascendant node's `data-aspect-node` untouched.
  Done when: `npx vitest run src/chart/ChartWheel.test.tsx` passes T4 and T5,
  with the dw-1 cases unedited.

- [x] **3. Stage wiring.**
  Files: `web-divination/src/chart/{ChartStage.tsx,ChartStage.test.tsx}`.
  `ChartStage` passes `activationFor(shown, useActivation()?.refs ?? [])` to
  the wheel. The remount key does not change.
  Done when: a ChartStage test in which `showRefs([VENUS])` runs while the
  fixture chart is ready shows `data-active`. The same call against the
  empty/loading ring shows none. `npx vitest run src/chart` passes.

- [x] **4. Wheel look and motion.**
  Files: `web-divination/src/chart/wheel.css`.
  Add the tier rules under `.wheel[data-active]`: dim 0.18, ring and houses
  0.55, echo 0.6, lit glow/fill/stroke in `var(--…)` only. The 900ms
  transition goes on the base selectors and the 600ms one on the active
  selectors. Reduced motion sets `transition: none` on every activation
  selector. The five reveal rules change `both` → `backwards`.
  Done when: G3 holds (`grep -n "animation:.* both" web-divination/src/chart/wheel.css`
  prints nothing, and the reduced-motion block lists every activation
  selector), and root `npm test` is green, including the colour guard.

- [x] **5. Chat drives it: turn events, chips, shrink-clear.**
  Files: `web-divination/src/chat/{useChat.ts,ChatPanel.tsx,chat.css,ChatPanel.test.tsx}`,
  `web-divination/src/app/App.test.tsx` (one appended `describe`).
  - `run` calls `clearActivation()` first, and `showRefs(chartRefs)` right
    after the non-empty persona append. `useChat` also has the shrink-clear
    (D1).
  - `ChartRefChips` takes the entry index. Each `li` holds a
    `button type="button"` with `aria-pressed`. The aspect `aria-label` moves
    from the `li` to the button.
  - `chat.css` edits only the dw-3 chip block (hover/focus/pressed states).
  - The dw-3 W4 test is REPLACED by the new W4.
  Done when: `npx vitest run src/chat src/app` passes W1–W6. Root `npm test`
  and `npm run typecheck` are green, and so is en/zh parity with no new key
  (G1).

- [x] **6. Validating: the real app (A1–A6).**
  Leave :8000 and :5173 alone; other checkouts hold them. Backend, from the
  worktree root:
  `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5174 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001`.
  Web: `cd web-divination && VITE_API_BASE=http://localhost:8001 npx vite --port 5174`
  (vite.config pins 5173 with `strictPort`, and the CLI flag overrides it;
  do NOT use `npm run web`). Enter the fixture birth (1990-06-15 08:30,
  Beijing). Drive the app with claude-in-chrome, using `javascript_tool` for
  `getComputedStyle` opacity, filter and transition-duration, and
  screenshots for A1 and A2.
  Done when: A1–A6 are recorded in `logs/dw-4-wheel-activation/`'s validating
  log with the observed values, both processes are stopped, and G2's
  `git diff --stat feature/divination_web...HEAD` is clean of `server/`,
  `packages/`, `app-native/`, `App.tsx`, `tokens.ts` and `i18n/`.

- [x] **7. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (via `/update-architecture-doc`: the web
  `chart/` section gains the activation store and the new `chat → chart`
  edge), `docs/features/dw-4-wheel-activation.md` (new, same shape as dw-3's),
  and `/Users/kaimao/Projects/astrology/pipeline/epics/divination-web.md`
  ("Built so far": the store, `data-planet-node`, chip buttons; the
  "Target modules" `chart/` line marked ✔).
  Done when: the docs name `wheel-activation.ts`, `activationFor`, the three
  data attributes and the shrink-clear, and
  `git diff --stat feature/divination_web...HEAD -- docs` shows the edits.

## Acceptance map

| Criterion | Step |
|---|---|
| T1 planet ref → lit + echo family | 1 |
| T2 aspect refs, lit wins over echo, Ascendant end | 1 |
| T3 null/empty/miss → null; misses ignored; time-unknown | 1 |
| T4 wheel attributes, incl. Ascendant node | 2 |
| T5 no prop / null → no tier attributes, dw-1 intact | 2 |
| T6 store semantics | 1 |
| W1 done lights; not while streaming | 5 (with 3) |
| W2 send/Retry clears; `[]`, Stop, failure stay inactive | 5 |
| W3 no chart → no activation, chip still toggles | 5 (with 3) |
| W4 chips are buttons, names unchanged en + zh | 5 |
| W5 press / switch / unpress, Enter + Space | 5 |
| W6 KV-restored and older chips | 5 |
| G1 root suites, guards, parity | 1–5 (final at 5) |
| G2 footprint | 6 |
| G3 reduced motion, no `both` fill | 4 |
| A1–A6 real app | 6 |

## Deviations (for journaling)

- **D1: shrink-clear in `useChat`.** The spec says nothing in `useChat`'s
  state machine changes beyond the two calls. The plan adds one effect: it
  tracks the transcript's last-seen length and calls `clearActivation()`
  when the length drops. This settles review note 4. It never fires inside
  dw-4, where transcripts only grow, but it protects dw-6. It is a third
  touch on the shared `useChat.ts`.
- **D2: G2 uses the three-dot merge-base diff** instead of `2f45dfb`
  (review note 1).

## Risks for the implementer

- **Wave landing conflicts.** dw-5 (the dice card) and dw-6 (the session
  log) also edit `chat/useChat.ts`, `chat/ChatPanel.tsx`, `chat/chat.css`,
  `chat/ChatPanel.test.tsx` and `app/App.test.tsx`. Keep dw-4's hunks small
  and local: the two calls plus the shrink effect inside `useChat`, only
  `ChartRefChips` and its `Entry` call site, only the dw-3 chip CSS block,
  and an APPENDED `describe` in App.test. Do not reformat or reorder
  neighbouring code or imports. If a wave sibling lands first, the
  coordinator merges the working branch into this worktree; re-run step 5's
  done-when there.
- **The store is module-level, so it leaks between tests.** Call
  `clearActivation()` in `beforeEach` in every file that touches it. W6's
  "remount from KV" must clear it by hand to simulate a reload, because a
  React remount does not reset module state.
- **W1's "not while streaming" needs a gated fake stream.** Hold the fake
  `StreamPost` open after a delta, assert no `data-active`, then release
  `done`. W2's "cleared before the stream yields" is asserted right after
  the send click, before the first gate opens.
- **Animations beat transitions.** While a reveal animation runs, it owns
  `opacity`/`transform`. An activation during the reveal only shows once the
  animation ends. That is correct, but in A1 sample computed styles after
  the reveal (about 2 s after chart load), not straight after entering the
  birth data. The reveal animates the `.wheel__nodes` GROUP, while the tier
  attributes sit on the node circles. Both opacities multiply, which is fine.
- **Specificity.** The lit stroke width must beat `.wheel__chord--tight` and
  the dashed/solid rules. Scope every tier rule as
  `.wheel[data-active] … [data-lit]`, not as bare attribute selectors.
- **Transition placement.** The 900ms return lives on the BASE selectors,
  so it also applies before any activation. The first-ever activation
  therefore uses the 600ms rule on the active selectors, because the
  destination state's duration wins. Reduced-motion `none` must cover both
  selector sets.
- **Chip a11y.** Moving `aria-label` onto the button keeps W4's names. The
  planet chip needs no label, because its visible name is the name. The
  `li` keeps the rise-in `animationDelay` style. A `button` inside the
  `ul`'s `li` keeps the list semantics that dw-3's tests query.
- **A5 emulation.** claude-in-chrome has no DevTools emulation panel. If
  `prefers-reduced-motion` cannot be emulated, record G3 plus a CSSOM read of
  the `@media (prefers-reduced-motion: reduce)` rules via `document.styleSheets`,
  and say plainly in the log that live emulation was not possible.
- **Birth-data edit keeps the activation.** The wheel remounts on a new
  chart key and replays the reveal, and `activationFor` re-matches. Do not
  clear the store from `chart/`.
