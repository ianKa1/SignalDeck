# Implementation Plan: dw-5-astro-dice

Spec: `pipeline/specs/dw-5-astro-dice.md` (WHAT + Architecture, PASS in
`logs/dw-5-astro-dice/06-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Parallel wave with dw-4 and dw-6.

Worktree `/Users/kaimao/Projects/astrology-wt/dw-5-astro-dice`, branch
`feature/dw-5-astro-dice`, worker #2: backend :8002, Vite :5175. Every
command runs from the WORKTREE root. Pipeline files are read and written by
absolute path under `/Users/kaimao/Projects/astrology/pipeline/`. Steps 0–7
are `implementing`, 8 is `validating`, 9 is `docs-sync`. Tick a box only
after its done-when passed and its `/git-commit` landed
(`(<type>): dw-5-astro-dice — <summary>`). Load `/frontend-design` before
step 6. Automated tests use fakes only: monkeypatched `llm.stream_turn`,
`llm.generate_sections` and `dice._RNG` (the `PLUTO_SCO_8` stub) on the
server; a fake `StreamPost` and fake timers on the web. Server tests run
`conda run -n astrology pytest -q` from `server/` (single file:
`… pytest tests/test_divination_dice.py -q`); web tests `npx vitest run <file>`
from `web-divination/`.

## Settled review notes

- **Roll vs the deadline line.** Keep `deadline = …` as the first line of
  `turn_events`; the roll and the `dice` yield come right after it and
  BEFORE `render.natal_context`. The deadline therefore also covers the
  roll (microseconds) and the timeout budget is still measured from
  request start. "First statement pair" in the contract means "first
  frame-producing statements"; D1/D6 only observe frame order.
- **`streamTurn` yields `dice` regardless of action.** The core client does
  not know or check the request's action for the dice branch; its only
  gates are `isDice`, "no delta yet" and "no dice yet". The server never
  sends `dice` on a chat turn (D2), so this is harmless. C1 exercises it
  with a cast request only; no chat-specific test is added.

## Steps

- [x] **0. Verify worktree prep (the coordinator did it; this step only checks).**
  Branch is `feature/dw-5-astro-dice`; `node_modules/@astrace/core`
  resolves; `.env` and the three `server/data/*.se1` are symlinks into the
  primary checkout; no `server/data/*.db` is a symlink.
  Done when: `git branch --show-current`, `ls -l .env server/data/*.se1
  server/data/*.db` agree, and root `npm test`, `npm run typecheck` and the
  server pytest are all green BEFORE any edit (the baseline).

- [x] **1. Dice module and the wire model.**
  Files: `server/app/divination/dice.py` (new), `server/app/models.py`,
  `server/tests/test_divination_dice.py` (new).
  `Roll`, `_RNG`, `roll`, `faces`, `chart_links`, `to_wire` per the
  contract; `DivinationDice`, `entry.dice` (user-entry rejection),
  `request.action`. Tests: the stub `_RNG`, the D9 pin/coverage/source scan
  with its planted-string self-check, `chart_links` on the real fixture
  chart (incl. `time:null`), and D8 via the model.
  Done when: `pytest tests/test_divination_dice.py -q` passes D8, D9 and
  the pure-function cases; the full server suite stays green.

- [x] **2. Prompt fragments and the render seams.**
  Files: `server/app/divination/personas/venus-dice.txt` (new),
  `server/app/divination/render.py`, `server/tests/test_divination_render.py`.
  Write the brief per Decided defaults "How Venus reads them". Register
  `dice.venus`, `dice.marker`, `side.dice`, `dice.recall` before
  `FINGERPRINT`. Extend `system_prompt(…, cast)`, `turn_messages(…, cast)`
  (recall fold, dropped-leading-entry rule) and
  `side_prompt(…, dice_in_view=False)`.
  Done when: render tests pass D10's fragment assertions, the D4/D5 prompt
  order and JSON on pure calls, the D7 fold, and `side_prompt` default
  output equals dw-3's (existing tests unedited).

- [x] **3. Cast turns.**
  Files: `server/app/divination/turn.py`, `server/app/divination/__init__.py`
  (docstring), `server/tests/test_divination_dice.py`, `CLAUDE.md` (rule 10
  sentence, verbatim from the spec's Amendments).
  Roll and yield `dice` after the deadline line, before the natal context;
  pass `cast` and the transcript's dice through; `_side_read` gains
  `dice_in_view`.
  Done when: the dice suite passes D1 (incl. the 1.5 s slow-stream
  keepalive ordering), D2, D3, D4, D5, D6, D7 and D11 (a)(b)(c) end to end
  through the SSE route with the real fixture chart; `test_divination_turn.py`
  and `test_boundaries.py` pass unedited; the full server suite is green.

- [x] **4. Core client.**
  Files: `packages/core/src/chart/index.ts` (value export `SIGNS`),
  `packages/core/src/divination/{types.ts,turn.ts,transcript.ts,index.ts}`,
  `web-divination/src/chat/core-divination.test.ts`.
  `Dice`, `isDice`, `TurnAction`, the `dice` event, `dice`/`cast` on
  entries, `WireEntry.dice`; the `streamTurn` gates (settled note 2);
  `sanitize`/`toWire` per contract. Every existing caller gains
  `action` (TurnRequest now requires it).
  Done when: `npx vitest run src/chat/core-divination.test.ts` passes C1
  and C2; root `npm run typecheck` is green.

- [x] **5. Chat state.**
  Files: `web-divination/src/chat/useChat.ts`.
  `send(message, action='chat')`, `run(message, before, action)`,
  `pending.dice` set on the `dice` event and preserved across later
  `setPending` calls, `failure.dice`, `dice` on the finished/stopped
  persona entry, `cast:true` on the user entry, `retry` re-casting.
  Keep hunks local (wave risk).
  Done when: root `npm run typecheck` is green and the existing
  `ChatPanel.test.tsx` passes unedited (Enter/Send still `action:"chat"`).

- [x] **6. Dice card and cast button (load `/frontend-design` first).**
  Files: `web-divination/src/chat/{DiceCard.tsx,DiceCard.test.tsx}` (new),
  `web-divination/src/chat/{ChatPanel.tsx,chat.css}`,
  `web-divination/src/i18n/{en,zh}.ts`.
  The pentagon card (rolling via `data-rolling`, stepped faces, staggered
  settles at 700/900/1,100 ms, glow, reduced motion), the Cast button, the
  card in `Entry`, pending and failure, the `· cast` mark; the five i18n
  keys in both languages. Colours only `var(--…)`; no `Math.random`.
  Done when: `npx vitest run src/chat/DiceCard.test.tsx` passes W2's
  rolling→settled on fake time, W4 and W6; `npx vitest run src/i18n.test.ts`
  passes parity.

- [x] **7. Panel integration tests.**
  Files: `web-divination/src/chat/ChatPanel.test.tsx` (one APPENDED
  `describe`).
  Done when: `npx vitest run src/chat` passes W1–W6 (incl. zh label, KV
  remount settled, failed-cast Retry re-casting, follow-up wire `dice`);
  root `npm test` and `npm run typecheck` are green; C3's
  `grep -rn "Math.random" web-divination/src` prints nothing.

- [x] **8. Validating: the real app (A1–A8).**
  Leave :8000 and :5173 alone (other checkouts; dw-4 uses 8001/5174).
  Backend from the worktree root:
  `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5175 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8002`.
  Web: `cd web-divination && VITE_API_BASE=http://localhost:8002 npx vite --port 5175`
  (vite.config pins 5173 with `strictPort`; the CLI flag overrides it; do
  NOT use `npm run web`). Enter the fixture birth (1990-06-15 08:30,
  Beijing). Drive with claude-in-chrome: `read_network_requests` for the
  body and first SSE frame, screenshots for A1/A4/A6, `javascript_tool`
  for `data-rolling` timing.
  Done when: A1–A8 are recorded with observed values in
  `logs/dw-5-astro-dice/`'s validating log (A3/A5: each chart claim beside
  the Placements panel value), both processes are stopped, and D10/C3's
  `git diff --stat feature/divination_web...HEAD` shows no `main.py`,
  `test_boundaries.py`, `app-native/`, `App.tsx` or `tokens.ts`.

- [x] **9. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (via `/update-architecture-doc`: `dice.py`,
  the cast action, the recall fold, `side.dice`, the web `DiceCard`),
  `docs/features/dw-5-astro-dice.md` (new, same shape as dw-3's),
  `/Users/kaimao/Projects/astrology/pipeline/epics/divination-web.md`
  ("Built so far": dice.py, the `action` field, persona-entry `dice` on the
  wire, the recall fold; the `dice.py` target marked ✔).
  Done when: the docs name `dice.py`, `SystemRandom`, `action:"cast"`,
  `dice.recall`, `side.dice` and `DiceCard`, and
  `git diff --stat feature/divination_web...HEAD -- docs` shows the edits.

## Acceptance map

| Criterion | Step |
|---|---|
| D1 dice first frame, before keepalive | 3 |
| D2 chat unchanged, zero RNG calls | 3 |
| D3 422 never rolls | 1 (model), 3 (route) |
| D4 grounded prompt order + JSON | 2 (pure), 3 (route) |
| D5 no chart / time unknown | 1 (links), 2, 3 |
| D6 failure after the roll | 3 |
| D7 recall fold | 2, 3 |
| D8 wire validation | 1 |
| D9 real randomness + source scan | 1 |
| D10 fragments, boundaries untouched | 2, 3 (diff at 8) |
| D11 side.dice whenever dice in view | 2, 3 |
| C1 streamTurn dice gates, action in body | 4 |
| C2 transcript round-trip, toWire | 4 |
| C3 root suites, parity, footprint, no Math.random | 7 (footprint at 8) |
| W1 Cast button, action, disabled states, mark | 7 |
| W2 rolling → settled, aria-label en/zh | 6, 7 |
| W3 stored card settled; chat has none | 7 |
| W4 reduced motion | 6 |
| W5 failed cast, Retry re-casts, follow-up dice | 5, 7 |
| W6 var colours, glyphs aria-hidden | 6 |
| A1–A8 real app | 8 |

## Deviations (for journaling)

- **D1: roll after the deadline line** (review note 1): the spec's "first
  statement pair" is read as "before `natal_context`", with `deadline`
  computed first.
- **D2: `streamTurn` accepts `dice` regardless of action** (review note 2);
  gates are `isDice`, no prior delta, no prior dice.

## Risks for the implementer

- **Wave landing conflicts.** dw-4 lands first and touches `useChat.ts`
  (`clearActivation`/`showRefs` inside `run`, a shrink-clear effect),
  `ChatPanel.tsx` (`ChartRefChips` and its `Entry` call site), `chat.css`
  (the dw-3 chip block) and `ChatPanel.test.tsx`. dw-6 likely touches
  `models.py`, `render.py`, `__init__.py`, core `types.ts`/`index.ts`,
  i18n and CLAUDE.md rule 10. Append, never reorder or reformat
  neighbours; put the dice card above `ChartRefChips` without editing that
  component. At landing the coordinator merges `feature/divination_web`
  into this worktree; re-run steps 3, 4 and 7's done-when there. The
  fingerprint moves in both dw-5 and dw-6; no hash is pinned, so that
  merge is text-only.
- **`setPending` replaces the object.** Today each delta calls
  `setPending({phase, text})`; unchanged, that drops `pending.dice` after
  the first delta and the card vanishes mid-reply. Use a functional update
  or carry the dice in a ref.
- **`TurnRequest.action` becomes required.** Every `streamTurn` caller
  and core test fixture needs it, or typecheck fails in both workspaces.
- **`FINGERPRINT` freezes the registry.** Any fragment declared after it is
  read raises; declare all four above line 95 of `render.py`, never in
  `dice.py`.
- **Recall fold vs the merge rules.** Fold the recall onto the user message
  AFTER dw-3's consecutive-role merge, or a merged pair gets the note on
  the wrong half. A leading persona entry the transcript drops takes its
  recall with it.
- **Keepalive ordering in D1** depends on the roll preceding the first
  `_wait`. Moving the roll after `natal_context` would still pass D1 on a
  fast fixture but fail D6's natal-failure case; keep it before.
- **D9 source scan reads raw text.** No docstring or comment anywhere in
  `divination/` may spell `random.seed`, `random.Random(` or
  `random.choice(` literally (write "never seeded"), or the scan bites
  on prose; `dice.py` calls `_RNG.choice`, which the regex does not match.
- **DiceCard timers leak.** Clear the stepping interval and settle
  timeouts on unmount and when `rolling` turns false (done arrives before
  1,100 ms). Fake-timer tests must `act()` around `advanceTimersByTime`.
- **Rolling is live-only.** `rolling` comes from `pending.dice` alone; the
  moment the persona entry is appended the card renders from the entry,
  settled. If `done` lands before 1,100 ms the jump to settled is correct.
- **Reduced motion in Chrome.** claude-in-chrome has no emulation panel.
  If A8 cannot be emulated, record W4 plus a CSSOM read of the
  `prefers-reduced-motion` rule and say so in the log.
- **A4 randomness is real.** Three casts can legally repeat a face; the
  criterion is only "not all three rolls identical". Cast a fourth rather
  than touching `_RNG`.
- **claude-cli latency.** A cast reply may take tens of seconds; the dice
  settle long before text, which is the point of A1. Do not raise
  `DIVINATION_TURN_TIMEOUT_S` in `.env` (it is a symlink shared with the
  primary checkout).
