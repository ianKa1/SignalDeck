# 04 implementing — dw-9-oral-delivery (worker #2)

Worktree `/Users/kaimao/Projects/astrology-wt/dw-9-oral-delivery`, branch
`feature/dw-9-oral-delivery` from `feature/divination_web` @ b308a92.
Fresh start (no plan box was ticked).

## Step 0 — worktree prep and baseline

- `git branch --show-current` → `feature/dw-9-oral-delivery`.
- `ls -l .env server/data/` → `.env -> /Users/kaimao/Projects/astrology/.env`;
  `seas_18.se1`, `semo_18.se1`, `sepl_18.se1` symlinks into the primary
  checkout; no `*.db` present (none symlinked).
- `node_modules/@astrace/core -> ../../packages/core`.
- Shell `DATABASE_URL` empty; the server tests never load `.env`.
- Baseline BEFORE any edit:
  - server `conda run -n astrology pytest -q` → `1129 passed, 50 skipped, 1 warning in 168.69s`
  - root `npm run typecheck` → both workspaces `tsc --noEmit` clean
  - root `npm test` → app-native `Test Suites: 90 passed, 90 total` /
    `Tests: 1069 passed, 1069 total`; web-divination `Test Files 19 passed (19)` /
    `Tests 163 passed (163)`
- Unedited `render.FINGERPRINT` = **`e482d4f819a3ce7b`** (T6 pins it as
  `DW5_FINGERPRINT`).

Step 0 has no code change, so it has no commit of its own; it is ticked with
step 1's commit.

## Step 1 — the pure segmenter

- NEW `server/app/divination/bubbles.py`: `Budget`, `CHAT = Budget(4, 3)`,
  `DEEPER = Budget(6, 4)`, `Segmenter(budget)` with `feed`/`close`,
  `.stopped`, `.bubbles`. A per-character state machine (run state
  cjk/ascii for terminator runs + closers; `_pending` = the next visible
  char opens a bubble; `_visible` = the current bubble has text).
  Whitespace is sent as it comes, except before a bubble's first visible
  char and after a cap-filling end (dropped — nothing is ever held, so
  `close()` returns `[]`). Deltas are merged per `feed` and flushed before
  each `bubble` op, so an op list never carries an empty delta.
- NEW `server/tests/test_divination_bubbles.py`: B1–B5 (+ exactly-at-cap,
  typography-only, `close()` emits nothing). `_every_split` runs every case
  whole AND at every two-way split, asserting identical bubbles, the same
  `stopped`, no empty / newline delta, bubble indexes 1..n, never first.
- `test_boundaries.py::test_bubbles_is_pure` (AST walk; non-stdlib imports
  must be `[]`); self-checks: planted `from app import llm` → `["app"]`,
  `from . import render` → `["."]`, `import requests` → `["requests"]`.
- `divination/__init__.py` docstring bullet for `bubbles`.
- Results: `pytest tests/test_divination_bubbles.py -q` → `12 passed`;
  `pytest tests/test_boundaries.py -q` → `24 passed`; full server suite →
  `1142 passed, 50 skipped, 1 warning in 119.71s`.

## Step 2 — prompt fragments and the old length rules

- `render.py`: `shape.chat`, `shape.deeper`, `depth.chart`, `depth.none`
  declared after `dice.recall`, before `FINGERPRINT`. Shape-only wording, no
  sample phrases or quotable nouns. `lang.zh` loses its 三段 sentence (keeps
  "Reply in Simplified Chinese … not a translation of English phrasing.").
  `system_prompt(..., action="chat")`: persona → shape → depth → chart →
  dice → lang; `turn_messages(..., action="chat")` passes it through.
- `personas/venus.txt`: lines 7 (60–180 words) and 10 (optional question
  back) removed. `venus-dice.txt` line 11 → "- Keep your voice and your
  shape rules."
- `test_divination_render.py`: N3 set gains the four fragments;
  `DW5_FINGERPRINT = "e482d4f819a3ce7b"`; T6 order (no chart en/zh, chart A,
  cast), T5 prompt half, old-length-lines-gone, depth key phrases,
  fingerprint moved. No existing order list needed an update.
- New FINGERPRINT: `d5788f0f0e3c1297`.
- Results: `pytest tests/test_divination_render.py tests/test_divination_turn.py
  tests/test_divination_dice.py -q` → `118 passed`; full server suite →
  `1150 passed, 50 skipped, 1 warning in 113.96s`.

## Step 3 — the turn cuts bubbles; `deeper` on the route

- `turn.py`: `Segmenter(DEEPER if action == "deeper" else CHAT)` between
  `chunks.get` and the frames; ops → `delta`/`bubble` frames; `_END` →
  `seg.close()` ops then break; at `.stopped` → INFO log with the budget,
  `cancel.set()`, break (the side read and `done` follow as on `_END`).
  Empty check = "no delta sent" (an all-whitespace provider stream is
  `unavailable`). Side read `reply` = `"\n\n".join(seg.bubbles)`.
  `action` read once via `getattr(request, "action", "chat")` (the
  disconnect test's SimpleNamespace carries none) and passed to
  `turn_messages`. Docstring's event table gains `bubble`.
- `models.py`: `action: Literal["chat","cast","deeper"]` + model
  after-validator `check_deeper_has_a_reply` (non-empty transcript whose
  last entry is persona).
- `CLAUDE.md` rule 10: the spec's sentence appended verbatim after the cast
  sentence.
- `test_divination_turn.py` (existing tests untouched — T1): T2 (two bubbles
  + side-read reply), no-newline-delta across chunk shapes, whitespace-only
  reply → `unavailable`, T3 (N1: 5 paragraphs then `release.wait(5)`;
  exactly bubbles 1–3, no "Paragraph 5", `done` in < 2 s, side-read reply of
  4 paragraphs; after `release.set()` in `finally` the fake's `finally` ran
  within 1 s; no "Paragraph 6"), T4 cast order `dice, delta, bubble, delta,
  done`, T5 deeper (7 paragraphs → bubbles 1–5, no dice, `shape.deeper` in
  the system prompt and no `shape.chat`, reply of 6), chat turn uses
  `shape.chat`, 422s for deeper+empty, deeper+user-last, `action:"roll"` —
  none calls the fake.
- `git diff feature/divination_web -- server/app/main.py server/app/llm.py
  | wc -l` → `0`.
- Results: `pytest tests/test_divination_turn.py -q` → `49 passed`; full
  server suite → `1160 passed, 50 skipped, 1 warning in 128.37s`.

## Step 4 — core grammar

- `packages/core/src/divination/types.ts`: `TurnAction` += `'deeper'`;
  `TurnEvent` += `{type:'bubble', index}`; `TranscriptEntry.deeper?: true`
  (docs: device-only; a persona reply's text is its bubbles joined by a
  blank line).
- `turn.ts`: `bubble` frame yielded only when `sawDelta` and
  `data.index === lastBubble + 1` (strict equality ⇒ integer, next in
  sequence); otherwise dropped — beside the `sawDice` guard.
- `transcript.ts`: `sanitize` keeps `deeper: true` on a user entry (not on a
  persona entry); `toWire` unchanged (never sends it).
- `web-divination/src/chat/core-divination.test.ts`: C1 (1 then 2 between
  deltas; drops before-first-delta, 1.5, "1", repeated, skipped, missing
  index; `'deeper'` is a TurnAction and is sent), C2 (deeper survives a
  fresh KV read; non-true / persona deeper dropped; `toWire` and
  `summaryWire` send the `\n\n`-joined text and never `deeper`).
- Results: `npx vitest run src/chat/core-divination.test.ts` → `37 passed`;
  root `npm run typecheck` clean (both workspaces); root `npm test` →
  app-native `90 passed` suites / `1069 passed` tests; web-divination
  `19 passed` files / `169 passed` tests.

## Step 5 — the pacer

- NEW `web-divination/src/chat/pacer.ts`: `createPacer({onReveal, onEnd,
  schedule, pauseFor?})` → `push` / `flush` / `dispose`; exported
  `bubblePause(chars)` = clamp(8 ms × chars, 450, 1100) and its constants.
  `PacerEvent` = delta | bubble | end; `PacerView` = `{bubbles, typing}`.
  A bubble event starts a pause sized by the finished slip's trimmed
  code-point length; later events queue; after the pause the ghost stays
  (`typing: true`) until the next bubble's first text arrives; `end` fires
  (once) after the queue drains. `flush()` skips every pause, drops a
  queued `end`, returns the non-empty bubbles. `dispose()` cancels the
  timer and silences all later callbacks. Deviation (additive): an
  explicit `onEnd` callback rather than reporting `end` through
  `onReveal` — the hook stores the entry there.
- NEW `pacer.test.ts` (fake timers through the injected `schedule`): W2
  arithmetic (16 → 450, 2 → 450, 100 → 800, 300 → 1100), buffered text
  during a pause (449 ms still typing, 450 reveals), 100/300-char sequential
  pauses, two quick breaks = two pauses with `end` after the second, ghost
  held until text, `end` once, `flush`, `dispose`, injected rule.
- `grep -nE "fetch\(|setTimeout|#[0-9a-fA-F]{3,8}\b" src/chat/pacer.ts` →
  no output (exit 1).
- Results: `npx vitest run src/chat/pacer.test.ts` → `10 passed`; root
  `npm run typecheck` clean; root `npm test` → app-native `90`/`1069`
  passed; web-divination `20` files / `179` tests passed.

## Step 6 — slips, ghost slip, chip, i18n, styles (`/frontend-design` loaded)

- `useChat.ts`: `Pending = {phase, bubbles, typing, dice?}`; a pacer per
  turn (`onReveal` → `setPending`, `onEnd` resolves the turn's `ended`
  promise; an abort listener resolves it `false`). Stream events: delta /
  bubble → pacer; `done` → mood+refs kept, then `pacer.push(end)` and the
  run AWAITS the pacer end (N2: `controllerRef` and `pending` clear only
  then, so Send stays disabled, Stop live, no chip). After the loop:
  `pacer.flush()` + `dispose()`; aborted (mid-stream or mid-pause after
  done) → stopped entry, mood/refs DROPPED; done+ended → stored entry +
  `showRefs`; otherwise → failure with the flushed partial. Entry text =
  exported `joinBubbles` (trim, drop empties, `\n\n`). `send(…, 'deeper')`
  stores `deeper: true`; `retry` re-sends `deeper`; `canDeepen` = no pending
  ∧ last is an unstopped persona entry ∧ the entry before it is not deeper.
  `useChat(persona, schedule = setTimeout-based)` — the timer is injected
  into the pacer from here.
- `ChatPanel.tsx`: `Slips` (a `.chat__prose.chat__slips` stack of
  `p.chat__slip`, caret on the last while streaming and not typing),
  `GhostSlip` (role="status", three ✦ stars, visually-hidden
  `chat.writing`), `DeeperChip` (button `.chat__deeper`, "go deeper ⌄").
  Stored entries, the pending letter and the failure partial render as
  slips; the greeting keeps `Prose` (letter prose, untouched — dw-7's
  surface). User line gains "· deeper" mark (`.chat__deeper-mark`, cast-mark
  styling). The chip renders inside the LAST entry's letter, after the mood,
  when `canDeepen`.
- `chat.css`: slip (panel paper, 1px `--line-soft` frame, 2px `--venus`
  left rule, 2px radius, max 92%, 8px gap, `chat-arrive` rise), dashed
  ghost slip, the chip (small caps, `--venus`, dotted underline, `--voice`
  focus ring), and a reduced-motion block (slip, chip, ghost stars:
  `animation: none`). `var(--…)` only; no token added.
- i18n en/zh `chat.deeper` / `deeperAsk` / `deeperMark` / `writing`
  appended after `houses` ("go deeper" / "Go deeper — tell me more about
  that." / "deeper" / "Venus is writing"; "展开说说" / "展开说说吧——再讲深一点。"
  / "深入" / "金星正在书写").
- `vite.config.ts` (test block only): `css.include` gains `/chat\.css/`, so
  the `?raw` import in the W6 reduced-motion test reads the real sheet
  (vitest blanks CSS otherwise — dw-6 did the same for log.css). Not in the
  plan's file list; a test-harness line, journal as a minor deviation.
- `ChatPanel.test.tsx`: W1 (real timers: one slip, ghost role=status with
  "Venus is writing", "B." absent, nothing stored / no chips / wheel dark /
  Stop live; then two slips ≥ 430 ms after the pause began; stored
  `A.\n\nB.` with refs, wheel lit; one eyebrow; chips after the last slip;
  next turn's wire text is the join — C2's join half), W2 rendered (two
  sequential pauses, ≥ 880 ms), W3 (Stop after done mid-pause → stopped,
  no mood/refs/chip/activation; Stop mid-stream mid-pause flushes the held
  bubble; error mid-pause → partial of both slips), W4 (chip under last
  finished entry only; hidden under stopped, deeper-reply, unanswered user
  line and while pending; press POSTs `action:"deeper"` + ask line, stores
  `deeper: true`, " · deeper" mark; returns under the next ordinary reply;
  Retry re-sends deeper; zh strings), W5 (three-paragraph old entry → three
  slips under one eyebrow, chips after; greeting has no slip;
  `SessionTranscript` renders a two-bubble entry as two paragraphs — test
  kept in `src/chat/` so `src/log` stays untouched), W6 reduced-motion block.
- Results: `npx vitest run src/chat src/log src/i18n.test.ts` → `9 passed`
  files / `147 passed` tests; root `npm run typecheck` clean; root
  `npm test` → app-native `90`/`1069`; web-divination `20` files / `194`
  tests. `git diff feature/divination_web --stat -- web-divination/src/theme
  web-divination/src/log` → empty.
