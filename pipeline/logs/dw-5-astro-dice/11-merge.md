# 11 merge — dw-5-astro-dice ← feature/divination_web (dw-4 landed as 71bab4b)

The coordinator asked for this under PIPELINE.md Parallel waves rule 6. It
was done inside the worktree `/Users/kaimao/Projects/astrology-wt/dw-5-astro-dice`.

`git merge feature/divination_web` produced 3 conflicts. ChatPanel.test.tsx
and chat.css auto-merged. Both were checked through the full web suite
below, with no test edited.

## Conflicts and resolutions (both features kept)

- `web-divination/src/chat/useChat.ts`
  - Header comment: kept both paragraphs, dw-5's cast paragraph and then
    dw-4's activation paragraph.
  - `run` signature: kept dw-5's `(message, before, action: TurnAction)`
    AND dw-4's `clearActivation()` as the first statement.
  - Auto-merged, and verified in place: dw-4's
    `if (chartRefs.length > 0) showRefs(chartRefs)` after the append (which
    also carries dw-5's `dice`); dw-4's transcript-shrink clear; dw-5's dice
    event, pending/failure dice, `send(…, action)`, and Retry re-casting.
- `web-divination/src/chat/ChatPanel.tsx`
  - Header comment: took dw-4's chip text. The dw-3 wording "static labels
    … dw-4 makes them interactive" is obsolete, so it was replaced, and
    dw-5's DiceCard paragraph was appended after it.
  - Imports: both, `../chart/wheel-activation` then `./DiceCard`.
  - Auto-merged, and verified: `Entry({entry, index, dict})` renders the
    DiceCard above the prose and then dw-4's `ChartRefChips … entry={index}`
    (press buttons with `aria-pressed`); the pending and failure DiceCards;
    the Cast button.
- `docs/ARCHITECTURE.md`
  - Repo-map `chat/` line: merged both (dw-4's press-button seals +
    activation; dw-5's Cast button, DiceCard and action).
  - Chat paragraph: merged. dw-4's `showRefs`/`clearActivation`/shrink-clear
    plus dw-5's `dice?`, stopped-with-dice, `send(message, action)` and
    Retry re-cast.
  - Data-flow chain: merged. Refs and dice go to the chip row and to
    `showRefs` → the lit wheel, plus the dice recall.
  - Feature index: dw-4's entry, then dw-5's.

Merge commit: `0c8910d (chore): dw-5-astro-dice — merge feature/divination_web (dw-4) and resolve chat conflicts`.

## Suites after the merge (verbatim summaries)

- server `conda run -n astrology pytest -q` → `1088 passed, 50 skipped, 1 warning in 106.13s (0:01:46)`
- root `npm test` → app-native `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`;
  web-divination `Test Files 15 passed (15)` / `Tests 115 passed (115)`.
  This includes dw-4's `wheel-activation.test.ts`, `ChartWheel.test.tsx`,
  `ChartStage.test.tsx`, `App.test.tsx`, dw-4's ChatPanel chip tests, and
  dw-5's dice tests.
- root `npm run typecheck` → 0 errors
- `grep -rn "Math.random" web-divination/src` → none
- The dw-4 guards are the app-native jest guards (architecture, colour) and
  the web guard tests above. All pass, and none was edited.

## Real-app smoke (8002 / 5175, claude-cli, fixture birth)

This ran on headless Chrome with a fresh profile (CDP :9335; the page's
`visibilityState` was "visible"). Backend `/api/health` →
`{"status":"ok","db":"ok","ephemeris":"ok"}`.
- The cast body had `action:"cast"` and the fixture birthData. The first
  SSE frame was `event: dice` `{"planet": "Uranus", "sign": "Libra", "house": 1}`.
  The card was rolling before any text (`cardBeforeText: true`) and was
  settled 1,222 ms after the click. Its aria-label read
  `The dice: Uranus, Libra, 1st house`. No wheel activation was present at
  send (`svg[data-active]` absent).
- The reply names all three faces first. Its chart claims: "Your own Uranus
  sits in Capricorn in your sixth house" (Uranus Capricorn H6 ✔); "Your
  Venus in Taurus in the tenth house" ✔; "its opposition to Pluto" ✔.
- `done.chartRefs` = Uranus, Venus, Venus|opposition|Pluto. Every chip is a
  placement the reply calls the user's OWN. Uranus is both the die and the
  user's own Uranus, which the reply names explicitly, so its chip is
  legitimate. No planet was named only as a die, and no such chip appeared.
- The chips are `button[aria-pressed="false"]`. After done the wheel was
  active, with lit planets Venus, Uranus and Pluto and lit aspect
  `Venus|opposition|Pluto` (dw-4's showRefs). Pressing the first chip
  (Uranus) gave `aria-pressed="true"`, and the only lit planet became
  Uranus with no lit aspects.

## Teardown

Killed uvicorn PID 17313 and vite PID 17302; the headless Chrome was killed
by its script. `lsof` on 8002 and 5175 shows nothing.
