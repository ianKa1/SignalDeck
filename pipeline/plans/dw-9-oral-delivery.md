# Implementation Plan: dw-9-oral-delivery

Spec: `pipeline/specs/dw-9-oral-delivery.md` (WHAT + Architecture; PASS in
`logs/dw-9-oral-delivery/02-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Parallel wave with dw-7 (lands FIRST)
and dw-12.

Worktree `/Users/kaimao/Projects/astrology-wt/dw-9-oral-delivery`, branch
`feature/dw-9-oral-delivery`, worker #2: backend :8002, Vite :5175. Every
command runs from the WORKTREE root; pipeline files by absolute path under
`/Users/kaimao/Projects/astrology/pipeline/`. Steps 0–6 are `implementing`,
7 is `validating`, 8 is `docs-sync`. Tick a box only after its done-when
passed and its `/git-commit` landed (`(<type>): dw-9-oral-delivery —
<summary>`). Load `/frontend-design` before step 6. Automated tests use
fakes only: monkeypatched `llm.stream_turn` / `llm.generate_sections` on
the server; stubbed stream, injected timer and vitest fake timers on the
web. Server: `conda run -n astrology pytest -q` from `server/` (one file:
`… pytest tests/test_divination_bubbles.py -q`). Web: `npx vitest run
<file>` from `web-divination/`. Root: `npm test`, `npm run typecheck`.

## Settled review notes

- **N1 — T3 is tested as the code can honour it.** `_drain` checks
  `cancel` only when the provider hands over its next chunk, and a
  generator blocked in another thread cannot be closed from outside. T3
  therefore asserts: exactly 3 `bubble` frames, no paragraph-5 text,
  `done` in under 2 s, side-read `reply` of 4 paragraphs, and — after the
  test SETS the fake's event — the fake's `finally` runs within 1 s and no
  further chunk is framed. "Cancels the provider stream at the cap" means
  "at the provider's next chunk".
- **N2 — the turn stays in flight until the pacer ends.** `controllerRef`
  and `pending` are cleared at the pacer's `end`, not at the stream's end:
  until then Send is disabled, Stop is live, `canDeepen` is false. Stop
  AFTER `done` arrived but before the pacer ended behaves exactly like
  Stop mid-stream: flush, store the entry with `stopped: true`, and DROP
  the received mood and chartRefs (no chips, no `showRefs`).
- **N3.** `test_divination_render.py::test_topic_is_registered` gains
  `shape.chat`, `shape.deeper`, `depth.chart`, `depth.none`. dw-7 adds
  `self.*` to the same set literal: a known merge hunk, keep both.
- **N4 — no empty delta, ever.** The segmenter never returns
  `("delta", "")`: not when a chunk boundary falls on a break or inside a
  terminator/closer run, not when held whitespace is released, not from
  `close()`. B1 and B5 assert it over every split of their inputs.
- **N5 — no server minimum.** If A1 yields one-slip replies, the fix loop
  tunes `shape.chat`'s wording; it never adds a minimum to `Budget`.

## Steps

- [x] **0. Verify worktree prep (coordinator did it; this only checks).**
  Branch `feature/dw-9-oral-delivery`; `node_modules/@astrace/core`
  resolves; `.env` and the three `server/data/*.se1` are symlinks into the
  primary checkout; no `server/data/*.db` is a symlink. Record the
  unedited `render.FINGERPRINT` (for T6's pin).
  Done when: `git branch --show-current` and `ls -l .env server/data/`
  agree; root `npm test`, `npm run typecheck` and the server pytest are
  green BEFORE any edit (baseline); the fingerprint is noted in the
  implementing log.

- [x] **1. The pure segmenter.**
  Files: `server/app/divination/bubbles.py` (new),
  `server/app/divination/__init__.py` (docstring bullet),
  `server/tests/test_divination_bubbles.py` (new),
  `server/tests/test_boundaries.py` (`test_bubbles_is_pure` + planted
  `from app import llm` self-check).
  `Budget`, `CHAT`, `DEEPER`, `Segmenter` per the contract (DD1–2);
  typography only. Each B case runs whole-string AND every two-way chunk
  split, asserting identical bubbles and no empty/newline delta (N4).
  Done when: B1–B5 pass; the purity pin and its self-check pass; full
  server suite green.

- [x] **2. Prompt fragments and the old length rules.**
  Files: `server/app/divination/render.py` (`shape.chat`, `shape.deeper`,
  `depth.chart`, `depth.none` declared after `dice.recall`, before
  `FINGERPRINT`; `lang.zh` loses its 三段 sentence; `system_prompt(...,
  action="chat")` inserts shape → depth after the persona base;
  `turn_messages` passes `action`), `personas/venus.txt` (lines 7, 10
  out), `personas/venus-dice.txt` (line 11 → "Keep your voice and your
  shape rules."), `server/tests/test_divination_render.py` (N3 set; T6
  with a `DW5_FINGERPRINT` constant from step 0).
  Fragments describe shape only — no sample phrases (reading-quality-bar).
  Done when: T6 passes; existing render/turn/dice tests pass (update only
  order lists that pin the old section sequence); full suite green.

- [x] **3. The turn cuts bubbles; `deeper` on the route.**
  Files: `server/app/divination/turn.py` (segmenter between `chunks.get`
  and the frames; budget by action; cap → log INFO, `cancel.set()`, leave
  as on `_END`; empty check = no delta sent; side read gets
  `"\n\n".join(seg.bubbles)`; `close()` ops flushed on `_END`; pass
  `request.action` to `turn_messages`), `server/app/models.py`
  (`DivinationTurnRequest.action` += `"deeper"` + after-validator),
  `server/tests/test_divination_turn.py` (T2–T5; T3 per N1 with an
  event-blocked fake released in `finally`), `CLAUDE.md` (the spec's rule
  10 sentence, verbatim).
  Done when: T1 (existing event-list tests UNCHANGED), T2–T5 and T7 pass;
  `git diff feature/divination_web...HEAD -- server/app/main.py
  server/app/llm.py` is empty; full suite green.

- [x] **4. Core grammar.**
  Files: `packages/core/src/divination/types.ts` (`TurnAction` +
  `'deeper'`; `TurnEvent` + `{type:'bubble', index}`; `TranscriptEntry.deeper?:
  true`), `packages/core/src/divination/turn.ts` (bubble guard beside the
  `sawDice` pattern), `packages/core/src/divination/transcript.ts`
  (`sanitize` keeps `deeper`), `web-divination/src/chat/core-divination.test.ts`.
  Done when: C1 and C2's sanitize/`toWire` halves pass; root
  `npm run typecheck` and `npm test` green (app-native guards walk core).

- [x] **5. The pacer.**
  Files: `web-divination/src/chat/pacer.ts` (new),
  `web-divination/src/chat/pacer.test.ts` (new).
  `createPacer({onReveal, schedule, pauseFor})`, `push` / `flush` /
  `dispose`, plus the exported clamp (8 ms × chars, 450–1100 ms). Pure: no
  React, timer injected.
  Done when: `npx vitest run src/chat/pacer.test.ts` passes W2's
  arithmetic (16 → 450, 100 → 800, 300 → 1100), queued sequential pauses,
  `end` only after the queue drains, `flush` reveals all at once;
  `grep -nE "fetch\(|setTimeout|#[0-9a-fA-F]{3,8}\b" src/chat/pacer.ts`
  prints nothing.

- [x] **6. Slips, ghost slip, chip, i18n, styles (load `/frontend-design`).**
  Files: `web-divination/src/chat/useChat.ts` (`Pending` per contract;
  pacer wiring; N2 lifetime and Stop-after-done; `send`/`retry` with
  `deeper`; `canDeepen`; persona text = trimmed bubbles joined by `\n\n`),
  `ChatPanel.tsx` (`Entry`/pending as slips, `GhostSlip`, `DeeperChip`,
  "· deeper" mark; dw-7's header/greeting untouched), `chat.css` (slip,
  ghost, chip, reduced motion; `var(--…)` only),
  `web-divination/src/i18n/{en,zh}.ts` (`chat.deeper`, `deeperAsk`,
  `deeperMark`, `writing` appended after `houses`),
  `ChatPanel.test.tsx` (W1, W3–W5), `useChat`-level C2 join case.
  Done when: `npx vitest run src/chat src/log src/i18n.test.ts` passes
  W1–W6 and C2's join half; root `npm test` and `npm run typecheck` green;
  `git diff feature/divination_web...HEAD --stat -- web-divination/src/theme
  web-divination/src/log` is empty.

- [x] **7. Validating: the real app (A1–A5).**
  :8000/:5173 belong to another checkout; leave 8001/5174 (dw-7) and
  8003/5176 (dw-12) alone. The repo `.env` sets `DATABASE_URL` to a SHARED
  REMOTE Postgres: copy it to a scratch file OUTSIDE the repo without that
  line (never edit the symlinked `.env`). Backend from the worktree root:
  `DATABASE_URL= ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5175 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file <scratch> --port 8002`;
  `curl localhost:8002/api/health` must report db unconfigured BEFORE any
  POST. Web: `cd web-divination && VITE_API_BASE=http://localhost:8002 npx vite --port 5175`.
  Chart A (1990-06-15 08:30 Beijing). Drive with claude-in-chrome:
  `read_network_requests` for the event stream, screenshot of a ghost
  slip; fetch `/api/chart` to verify every named placement.
  Done when: the validating log in `logs/dw-9-oral-delivery/` records
  A1–A5 with each reply quoted verbatim, A2's (a)–(e) judged per reply,
  A3's sentence counts, A5's zh slips; both processes stopped.

- [x] **8. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (via `/update-architecture-doc`: the
  segmenter, `bubble` event, `deeper` action, pacer, slips),
  `docs/features/dw-9-oral-delivery.md` (new, dw-6's shape). Do NOT edit
  the epic: report its delta to the coordinator (grammar table + `bubble`,
  `delta` carries no newline, request `action` + `deeper`, "Built so far"
  dw-9, `bubbles.py`/`pacer.ts` targets built).
  Done when: the docs name `bubbles.py`, `Segmenter`, `bubble`,
  `shape.chat`, `depth.chart`, `createPacer` and `DeeperChip`; the epic
  delta is in the handback report.

## Acceptance map

| Criterion | Step |
|---|---|
| B1 line breaks, no newline delta | 1 |
| B2 sentence cap, `3.5` | 1 |
| B3 CJK, closing quote | 1 |
| B4 bubble cap, both budgets | 1 |
| B5 leading/all whitespace, no empty delta | 1 |
| T1 old event lists unchanged | 3 |
| T2 two bubbles, side-read reply | 3 |
| T3 cut at the cap (N1 wording) | 3 |
| T4 cast order | 3 |
| T5 deeper budget, prompt, no dice, 422s | 2 (prompt), 3 (turn, model) |
| T6 prompt order, length lines gone, fingerprint | 2 |
| T7 boundaries; main/llm unchanged | 1 (purity), 3 (full) |
| C1 bubble guard, `'deeper'` | 4 |
| C2 deeper survives reload; join stored and sent | 4 (sanitize/toWire), 6 (join) |
| W1 ghost slip 450 ms, done after pause | 6 |
| W2 pause arithmetic, sequential pauses | 5 (pacer), 6 (rendered) |
| W3 Stop/error during pause | 6 |
| W4 chip visibility, POST, mark, retry | 6 |
| W5 old entries as slips; SessionTranscript | 6 |
| W6 parity, reduced motion, guards, no tokens | 6 |
| A1–A5 real app | 7 |

## Deviations (for journaling)

- **Diff baselines after the landing merge.** T7 says main.py/llm.py are
  "unchanged from b308a92", but dw-7 (landing first) edits `main.py`.
  The check runs as `git diff feature/divination_web...HEAD` (dw-9's own
  delta), before and after merging the working branch in.
- **T6's "FINGERPRINT differs from b308a92's"** is pinned as a
  `DW5_FINGERPRINT` constant recorded at step 0, like `DW2_FINGERPRINT`.
- N1, N2 (incl. Stop-after-done drops mood/refs), N4, N5 as settled above.

## Risks for the implementer

- **Landing after dw-7.** The coordinator merges `feature/divination_web`
  into this worktree. Expected hunks: `render.py` (keep both keyword
  params; merged order persona → shape → depth → `self.*` → chart → dice →
  lang; dw-9's declarations after dw-7's), `test_topic_is_registered`
  (union of both sets), `turn.py` (dw-7's `voice` pass-through vs dw-9's
  loop body), `ChatPanel.tsx` (dw-7 header/greeting vs dw-9 Entry/pending),
  i18n (dw-9 inside `chat`, dw-7's `persona` namespace at the end),
  CLAUDE.md rule 10 (keep both sentences), dw-7's `N3` order lists.
  **Re-record dw-7's chart-less goldens**
  `server/tests/fixtures/divination_chartless_{en,zh}.txt` from the MERGED
  `render.system_prompt("venus", lang)`; the fixture diff must be exactly
  the persona-line removals, the shape/depth fragments and the `lang.zh`
  edit — anything else is a merge error. Re-run steps 2, 3 and 6's
  done-when after the merge.
- **The segmenter's state crosses chunks.** A terminator at a chunk's end
  is not a sentence end until the next chunk shows whitespace (ASCII) or
  the stream ends; closers may arrive in the next chunk. Hold, never
  guess; `close()` resolves the tail.
- **Cap vs held text.** The stop fires on the first visible character of
  the over-cap bubble, before any of it is framed; that chunk's earlier
  ops (the last allowed bubble's tail) must still be framed.
- **Empty-reply check.** An all-whitespace provider stream now yields no
  delta and must still be the `unavailable` error.
- **T3 thread hygiene.** Release the fake's event in a `finally`, or a
  wedged worker thread hangs later tests.
- **React and the pacer.** The pacer calls `onReveal` from timers; guard
  against a disposed pacer after unmount or abort, and dispose on
  unmount, or tests log act() warnings and state updates leak.
- **Stop during a pause after `done`.** `streamTurn` has already
  finished, so aborting the controller changes nothing: Stop must set its
  own flag the run checks at pacer end (N2).
- **Retry of a deeper entry** takes `entries.slice(0, -1)` as before; the
  server's 422 relies on that slice ending in a persona reply.
- **Double pacing on remount.** The pending letter is ephemeral; a reload
  mid-pause loses it exactly like a reload mid-stream today (accepted).
- **Empty `DATABASE_URL`.** If `/api/health` still reports a db, stop:
  the scratch env is wrong, and a boot would migrate the shared Postgres.
- **claude-cli latency.** Replies take seconds per bubble; A1's ghost
  slip screenshot needs a reply with ≥2 slips, so re-ask if the first is
  one slip (and see N5 if all are).
