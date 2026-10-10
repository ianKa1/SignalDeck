# 08 implementing — dw-5-astro-dice

Worker #2 of the dw-4/5/6 parallel wave. Worktree
`/Users/kaimao/Projects/astrology-wt/dw-5-astro-dice`, branch
`feature/dw-5-astro-dice` (from `feature/divination_web` @ 2f45dfb).

## Step 0 — worktree prep check

- `git branch --show-current` → `feature/dw-5-astro-dice`
- `.env` → symlink to `/Users/kaimao/Projects/astrology/.env`; `server/data/`
  holds only the three `.se1` symlinks (no `.db` file, none symlinked).
- Baseline (before any edit):
  - server `conda run -n astrology pytest -q` → `1035 passed, 50 skipped, 1 warning in 200.90s`
  - root `npm test`: first run app-native `Tests: 6 failed, 1063 passed, 1069 total`
    (timeouts under the three-worker CPU load, e.g. city-picker.test.tsx:191);
    immediate rerun of `npx jest` in app-native → `Tests: 1069 passed, 1069 total`.
    web-divination → `Test Files 13 passed (13) / Tests 72 passed (72)`.
  - root `npm run typecheck` → both `tsc --noEmit` clean.
- No commit (nothing changed).

## Step 1 — dice module and wire model

- New `server/app/divination/dice.py` (`_RNG = random.SystemRandom()`,
  `Roll`, `roll`, `faces`, `chart_links`, `to_wire`); `models.py` gains
  `DivinationDice` (StrictInt house, faces checked against the dictionary
  keys), `DivinationTranscriptEntry.dice` + a model validator rejecting dice
  on a user entry, and `DivinationTurnRequest.action: Literal["chat","cast"] = "chat"`.
- New `server/tests/test_divination_dice.py`: roll/faces/wire/links (real
  fixture chart, incl. `time:null`), D8 (5 bad faces + user-entry dice +
  valid + action), D9 (SystemRandom pin, 3,600 real rolls cover all faces,
  source scan + 8 planted-string self-checks).
- `pytest tests/test_divination_dice.py -q` → `23 passed in 0.33s`
- full server suite → `1058 passed, 50 skipped, 1 warning in 118.48s`

## Step 2 — prompt fragments and render seams

- New `personas/venus-dice.txt` (asset `dice.venus`); `render.py` registers
  `dice.venus`, `dice.marker`, `side.dice`, `dice.recall` before `FINGERPRINT`;
  `system_prompt(…, cast)` adds brief + marker + JSON (`faces` + `inYourChart`
  when ctx) between the chart section and the lang line; new `recall_note`;
  `turn_messages(…, cast)` folds each persona entry's `dice.recall` onto the
  LAST user message before it (so a merged user pair gets it at the end, and
  two merged persona entries still find the asking user message); a dropped
  leading persona entry drops its note; `side_prompt(…, dice_in_view=False)`.
- `test_divination_render.py`: `test_topic_is_registered`'s exact fragment
  set gained the four dw-5 names (the one existing assertion that had to
  change: it pins the registry's exact contents); appended D4/D5/D7/D10/D11
  builder tests. Existing side_prompt/grounded tests unedited and passing.
- divination + boundaries suites → `108 passed, 1 warning in 3.52s`
- full server suite → `1065 passed, 50 skipped, 1 warning in 120.45s`

## Step 3 — cast turns

- `turn.py`: after the `deadline` line (plan deviation D1), a cast rolls
  (`dice.roll()`) and yields `frame("dice", dice.to_wire(cast))` BEFORE
  `render.natal_context`; `action` read via `getattr(request, "action",
  "chat")` so dw-2's SimpleNamespace disconnect test runs unedited; new
  `_wire_entry` passes a persona entry's `dice` as a dict; `cast` goes to
  `turn_messages`; `_side_read(…, dice_in_view)` with `dice_in_view = cast is
  not None or any transcript entry has dice`. Module docstring names the event.
- `__init__.py` docstring names `dice`; CLAUDE.md rule 10 gains the spec's
  Amendments sentence verbatim.
- `test_divination_dice.py` appended route tests: D1 (exact first frame +
  once + 1.5 s slow stream → dice before first keepalive), D2 (absent vs
  "chat" byte-equal, zero RNG calls), D3 (3 cases, zero RNG calls), D4
  (order + JSON), D5, D6 (unavailable / timeout / natal failure), D7, D8
  route (6 × 422 + valid), D11 (a)(b)(c) + cast-without-birth mood-only.
- divination + boundaries → `131 passed, 1 warning in 5.64s`;
  `test_divination_turn.py` and `test_boundaries.py` unedited.
- full server suite → `1088 passed, 50 skipped, 1 warning in 130.98s`

## Step 4 — core client

- core `chart/index.ts` value-exports `SIGNS` beside `BODIES`.
- core `divination/types.ts`: `Dice`, `TurnAction`, `isDice` (body in BODIES,
  sign in SIGNS, integer house 1–12), `TurnRequest.action` (required), the
  `dice` TurnEvent, `TranscriptEntry.dice?`/`cast?`, `WireEntry.dice?`;
  `turn.ts` yields `dice` only when well formed, before any delta and once
  (plan deviation D2: regardless of action); `transcript.ts` `sanitize` keeps
  persona `dice` (via isDice) and user `cast === true`, `toWire` adds persona
  dice only; barrel exports `isDice`, `Dice`, `TurnAction`.
- `useChat.ts` minimal to keep typecheck green: `action: 'chat'` on the
  request, and the error branch narrowed to `event.type === 'error'` (dice
  handled properly in step 5).
- `core-divination.test.ts`: REQ gains `action: 'chat'` (required field);
  appended C1 (order + action in body, second/late dice dropped, 6 malformed
  dice dropped, extra keys stripped) and C2 (KV round trip, malformed/user
  dice and non-true cast dropped, toWire).
- DEVIATION (journal): dw-2's `ChatPanel.test.tsx` W1 pins the EXACT request
  body with `toEqual`; since Send must now carry `action:"chat"` (spec W1),
  that one expected object gained `action: 'chat'` (one added line). The
  plan's step-5 "passes unedited" was not satisfiable against the spec.
- `npx vitest run src/chat/core-divination.test.ts` → `Tests 31 passed (31)`
- web vitest → `Test Files 13 passed (13) / Tests 84 passed (84)`
- root `npm run typecheck` → both clean; app-native jest → `Tests: 1069 passed, 1069 total`

## Step 5 — chat state

- `useChat.ts`: `send(message, action='chat')` (user entry gains `cast: true`
  on a cast), `run(message, before, action)`; the `dice` event sets
  `pending.dice` via a functional update and every later delta carries it
  (the replace-per-delta risk); the finished and the stopped persona entry
  keep `dice`; `Failure.dice`; `retry` re-casts when the last user entry has
  `cast`.
- web typecheck clean; `npx vitest run src/chat` → `Test Files 2 passed (2) / Tests 45 passed (45)`

## Step 6 — dice card and cast button (`/frontend-design` loaded first)

- New `chat/DiceCard.tsx`: `figure.dice` (aria-label from `chat.diceAria`),
  small-caps `chat.diceLabel` figcaption, three 52px SVG pentagons (fixed
  coordinates, no trig) with `--panel` fill / `--line` stroke / inner
  `--line-soft` hairline; planet glyph `--venus`, sign glyph `--voice`, house
  numeral `--text` in `--font-body`; captions `--text-dim` 0.78rem (hidden
  while that die tumbles). Live (`rolling` at mount, not reduced motion):
  70 ms fixed-order face stepping, settles at 700/900/1,100 ms, then
  `dice__die--landed` glow (drop-shadow in `--venus-ghost`); `data-rolling`
  present until all three settle. Reduced motion via `useSyncExternalStore`
  over `matchMedia` (absent → not reduced). Timers cleared on unmount.
- `ChatPanel.tsx`: "Cast the dice" button (pentagon mark, `--venus` outline,
  `--venus-ghost` hover, `--voice` focus-visible outline, disabled like Send,
  never replaced by Stop) left of Send; DiceCard above the prose in stored
  entries, in the pending letter (one Letter instance across awaiting →
  streaming so the roll is not restarted; the listening line now sits BELOW
  that letter), and in the failure letter; user cast line gets
  `· {chat.castMark}`.
- `chat.css` appended block (cast button, dice card, `dice-tumble`,
  `dice-glow`, reduced-motion rule). i18n en/zh: `cast`, `diceLabel`,
  `diceAria`, `castMark`, `houses` 1–12.
- New `DiceCard.test.tsx`: W2 (fake-timer roll → settle, en label), W2 zh,
  W3 stored settled, W4 reduced motion, timer cleanup, W6 (aria-hidden SVGs,
  no inline colour; the CSS side is app-native's color-guard, which walks
  web-divination .css — a `?raw` read returned '' under vitest, so the test
  does not re-read CSS).
- `npx vitest run src/chat/DiceCard.test.tsx` → `Tests 6 passed (6)`;
  `src/i18n.test.ts` parity passing (11 passed with DiceCard earlier);
  root typecheck clean; root npm test → app-native `1069 passed`, web
  `Test Files 14 passed (14) / Tests 90 passed (90)`.

## Step 7 — panel integration tests

- `ChatPanel.test.tsx`: one appended `describe('ChatPanel Astro Dice (dw-5)')`
  (10 tests: W1 cast/Enter/Send actions + disabled states + mark; W2 live
  card rolling before text, same instance while prose streams, settled
  faces (real timers, `waitFor` ≤2 s — the fake-timer timing is pinned in
  DiceCard.test.tsx because the controllable stream's `setTimeout(0)` pump
  needs real timers); W2 zh label/button/mark; W3 stored settled above
  prose + KV entry; W3 KV remount settled, chat reply without card; W4
  reduced motion; W5 failed cast → settled card + error + Retry re-casts;
  W5 follow-up wire dice (no `cast` on the wire); W5 stop before text →
  nothing stored / stop after text keeps dice; W6 aria-hidden). The header
  import gained `vi` (one-line change).
- `npx vitest run src/chat` → `Tests 61 passed (61)`
- root typecheck clean; root npm test → app-native `Tests: 1069 passed, 1069 total`,
  web `Test Files 14 passed (14) / Tests 100 passed (100)`
- `grep -rn "Math.random" web-divination/src` → no output
