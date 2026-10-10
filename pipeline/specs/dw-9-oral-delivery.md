# dw-9-oral-delivery — spoken, not essays

## Goal

Venus answers in 2–4 short bubbles (1–3 sentences, one point each), with the shape enforced by the SERVER's stream segmenter, not by the prompt. Each turn carries a chart-grounded "because" and one sharp question back, and a "go deeper" chip fetches the long version. QUEUE.md `dw-9-oral-delivery`; epic `pipeline/epics/divination-web.md`.

## Non-goals

- Inline tags and pills (dw-10), and call B. dw-9 parses no side field from the prose, and nothing here reads what the prose SAYS.
- The persona sheet, the voice and the header (dw-7). Other characters and handoff (dw-8). Current transits (dw-11).
- Checking that a reply is "deep enough" and regenerating it. A streamed reply cannot be taken back. Depth is instructed and then judged on the real app (Decided default 6).
- Any change to `llm.py`, the side read, `done`, `dice`, the summary route or its key material, the session-log store, `main.py`, or `app-native/`.
- Re-bubbling pre-dw-9 transcripts. Old entries render through the same blank-line split, so their paragraphs become bubbles.

## Decided defaults

1. **The bubble is structural, cut by the server.** A new pure segmenter, `divination/bubbles.py`, sits between `llm.stream_turn` and the SSE frames. It passes the model's text through verbatim and changes it in only three ways:
   - A **line break** (any run of `\n`/`\r`) ends the current bubble. The newlines are never sent. Leading whitespace and newlines before a bubble's first visible character are dropped, so no bubble is empty.
   - The **sentence cap**: once a bubble holds its maximum number of sentences, the next non-whitespace character opens a new bubble. The model's own sentence is never split.
   - The **bubble cap**: when a bubble past the maximum would open, the segmenter stops. The turn cancels the provider stream (the existing cancel path) and drops the rest. The side read and `done` then run on the bubbles already sent. The cut is logged at INFO with the counts and never reaches the wire.

   This does not break the no-prose-parsing ruling. That ruling is about side FIELDS (mood, refs, dice), which carry meaning and must come from structured calls. The segmenter extracts nothing. It reads only typography (line breaks and sentence-ending punctuation), produces no field, and makes no claim about content. A model-emitted delimiter token was rejected because it would be protocol written inside the prose channel, which is the tag mechanism call B would have to rule on.
2. **What counts as a sentence end.** A run of terminators, plus any closing quotes or brackets right after it (`" ” ’ ' ) ] 」 』 ）`).
   - CJK terminators (`。！？…`) end the sentence at once.
   - ASCII terminators (`. ! ?`) end it only when whitespace or the end of the stream follows. So `3.5` and `U.S.` inside a word do not count.
   - A terminator run counts once (`?!`, `...`).

   `e.g. ` over-counts, costing only an early break.

   Whitespace is sent as it comes. The one exception is whitespace after a sentence end that fills the cap: it is held until the next character, and dropped if a break follows. A bubble's text on the client is the concatenation of its deltas, trimmed.
3. **Budgets.** A chat or cast turn gets at most **4 bubbles × 3 sentences**. A deeper turn gets at most **6 bubbles × 4 sentences**. The server sets no minimum (a one-bubble answer to "hi" is fine); the prompt asks for 2–4 bubbles (up to six when going deeper).
4. **The event.** `bubble {index}` is a new SSE event, sent when bubble `index` (≥ 1) opens, just before its first `delta`. Bubble 0 opens implicitly with the first delta. So a one-bubble reply is byte-identical to dw-6's stream, and the dw-2/3/5 event-list tests pass unchanged.
   - No `delta` contains a newline.
   - The indexes go 1, 2, … with no gaps.
   - `bubble` never comes before the first delta, and never after `done` or `error`.
   - `done` and `error` are unchanged.
5. **The transcript stores one entry per turn.** A persona reply stays ONE entry, and its `text` is its bubbles joined by a blank line (`\n\n`). Since a bubble cannot contain a newline, splitting that text on the blank line gives back the bubbles exactly: the join is the client's own lossless encoding of the `bubble` events, not a reading of the prose. Everything that is per entry keeps working untouched:
   - dw-3 chips and dw-4 activation (per-entry `chartRefs`);
   - dw-5 dice (per-entry `dice`, recall);
   - dw-6 summaries (`text` on the wire; the summary key is unchanged for an equal text) and the sessions reader (`SessionTranscript` already splits on the blank line, so each bubble becomes a paragraph).

   No new field is added to persona entries.
6. **The depth rule is instructed, and proven where proof is possible.** Two new prompt fragments, `depth.chart` (with birth data) and `depth.none`, require:
   - one point per bubble;
   - at least one "because" that names a placement or aspect in the data, and one concrete consequence for THIS question;
   - no statement that would be true of anyone, and no generic comfort;
   - one sharp question back, in the last bubble, and no covering of every case.

   Without birth data, the "because" rests on the person's own words (`chart.none` stands).

   Per the user's leak lesson (reading-quality-bar), the fragments describe the SHAPE and contain no sample phrases or quotable nouns.

   What the tests can prove: that the fragments are present, their order, the budgets, and that the old length lines are gone. What only the real app can show: that a reply names real placements, is specific, and ends on one question. The existing side read gives a structural proxy there: with birth data, `done.chartRefs` must be non-empty. The acceptance checker judges the rest against the rubric in A2, verifying the named placements against `/api/chart`.
7. **The old length rules go.** These lines conflict with bubbles, so they are removed:
   - `venus.txt` lines 7 (60–180 words, one to three paragraphs) and 10 (the optional question back);
   - `venus-dice.txt` line 11 (it becomes "Keep your voice and your shape rules.");
   - the three-paragraph sentence in `lang.zh`.

   The new `shape.chat` and `shape.deeper` fragments replace them. `shape.chat` asks for 2–4 bubbles, each 1–3 sentences on its own line, with no lists and no markdown.
8. **Go deeper is an action on the existing route.** The request's `action` gains `"deeper"`. It is a stateless turn:
   - The client sends the transcript (whose last entry must be a persona reply, else 422) and, as the `message`, its localized ask line (`chat.deeperAsk`).
   - The server uses the deeper budget and `shape.deeper`: take the last reply further, name the placements behind it and how they combine, and say what follows for the question.
   - It never rolls dice. Dice already in the transcript stay in view (recall and `side.dice` as today).
   - The user entry is stored with a device-only `deeper: true` (like dw-5's `cast`). Retry of it re-sends `deeper`.
9. **What the person sees** (the frontend-design bar: keep the letter-and-seal register, add no colour tokens and no fonts).
   - **Slips.** A reply is a stack of paper slips under ONE ♀ eyebrow: notes passed across a table, not coloured chat blobs.
     - Each slip is a panel-toned card with a 1px `--line-soft` frame, a 2px `--venus` left rule and a 2px radius, capped at 92% of the column width, with 8px between slips.
     - It rises in with the existing `chat-arrive` motion.
     - The dice card sits above the first slip. The chips and the mood sit after the last slip.
     - Old letters render the same way.
   - **Typing pause.** When `bubble {n}` arrives, the finished slip stays put, and a ghost slip (dashed `--line-soft` frame, the existing three ✦ stars pulsing, labelled "Venus is writing" for assistive tech) holds the place. It holds for `clamp(8 ms × characters of the finished bubble, 450 ms, 1100 ms)`. Text that arrives meanwhile is buffered and revealed when the pause ends.
     - Pauses queue: each bubble gets its own pause.
     - `done` is applied (the entry is stored, the chips shown, the wheel lit) only after the last pause.
     - Stop flushes everything received into the stopped entry. An error flushes it into the failure's partial.
     - Reduced motion keeps the pause, which is pacing, not motion, but the stars are static and the slips do not rise.
   - **The go-deeper chip.** The chip is a quiet small-caps text button in `--venus`, "go deeper ⌄" / "展开说说 ⌄", with a dotted underline and a visible focus ring.
     - It sits under the LAST stored persona reply when no turn is pending, the reply was not stopped, and the reply did not itself answer a deeper ask.
     - Pressing it sends the ask line as a deeper turn. The user's line then shows as a normal italic note with a faint "· deeper" / "· 深入" mark, like the cast mark.
     - The chip is gone while the turn runs.
10. **The client guards the grammar.** Core's `streamTurn` yields `bubble` only after a delta, and only with the next integer index. Anything else is dropped, like a late `dice`. `TurnEvent` gains `{type:'bubble', index}`.

## Architecture

Cites `pipeline/epics/divination-web.md` (reuse map, dependency rules, turn event grammar). Only dw-9's delta is written here.

### Reuse (verified at b308a92)

| Need | Existing | Use |
|---|---|---|
| The stream loop and cancel | `divination/turn.py:200` `turn_events`; `:222` worker submit; `:127` `_drain` (checks `cancel`, closes the provider in `finally`); `:246` `cancel.set()` | Put the segmenter between `chunks.get` and `frame("delta")`. A cap stop takes the `_END` path early and sets `cancel`. |
| The side read | `turn.py:167` `_side_read(message, reply, …)` | It gets `"\n\n".join(bubbles)`. Otherwise unchanged. |
| Prompt composition | `render.py:185` `system_prompt`, `:223` return expression; fragments `:47-119`; `lang.zh` `:53` | New fragments are declared after `dice.recall`, and the shape/depth pair is inserted after the persona base. |
| Persona assets | `personas/venus.txt:7,10`; `personas/venus-dice.txt:11` | Remove or replace those lines (Decided default 7). |
| Action field | `models.py:395` `action: Literal["chat","cast"]`; `:373` validator pattern | + `"deeper"` and a model validator |
| Client grammar | core `divination/types.ts:31` `TurnAction`, `:39` `TranscriptEntry`, `:66` `TurnEvent`; `turn.ts:58-88` frame loop (the `sawDice` guard pattern) | Additive |
| Device flags | `transcript.ts:24` `sanitize` (keeps `cast`) | Keep `deeper` the same way |
| Chat state and render | `useChat.ts:40` `Pending`, `:73` `run`, `:136` `retry` (casts again); `ChatPanel.tsx:41` `paragraphs`, `:48` `Prose`, `:162` `Entry`, `:258-274` pending and listening; `chat.css:98` `chat-arrive`, `:483` reduced-motion block, `.chat__stars` | Slips reuse `paragraphs()` as the bubble split. The ghost slip reuses the stars. |
| Log reader | `log/SessionTranscript.tsx:10` `paragraphs` | Unchanged. The blank-line join renders each bubble as a paragraph. |

### Module map (created or changed only)

```
server/app/divination/
├── bubbles.py              NEW  pure segmenter: Budget, CHAT, DEEPER, Segmenter
├── turn.py                 CHG  segment the drained chunks; bubble frames; stop at the cap
├── render.py               CHG  + shape.chat / shape.deeper / depth.chart / depth.none;
│                                 lang.zh loses its paragraph sentence;
│                                 system_prompt(..., action="chat"); turn_messages passes it
└── personas/venus.txt, venus-dice.txt   CHG  length lines out
server/app/models.py        CHG  action + "deeper"; deeper needs a persona-last transcript
server/tests/
├── test_divination_bubbles.py  NEW  B1–B5
├── test_divination_turn.py     CHG  + T2–T5 (existing tests untouched)
├── test_divination_render.py   CHG  + T6
└── test_boundaries.py          CHG  + test_bubbles_is_pure
packages/core/src/divination/
├── types.ts                CHG  TurnAction += 'deeper'; TurnEvent += bubble; entry.deeper?
├── turn.ts                 CHG  bubble frame guard
└── transcript.ts           CHG  sanitize keeps deeper
web-divination/src/chat/
├── pacer.ts                NEW  bubble reveal queue (pure; injected timer)
├── useChat.ts              CHG  Pending.bubbles + typing; pacer; deeper send/retry
├── ChatPanel.tsx           CHG  Slips, GhostSlip, DeeperChip; Entry/pending render
├── chat.css                CHG  slip, ghost slip, deeper chip, reduced motion
web-divination/src/i18n/en.ts, zh.ts  CHG  chat.deeper / deeperAsk / deeperMark / writing
```

The core barrel `index.ts` needs no change, because the types are already exported by name.

### Module contracts

**`divination/bubbles.py`**: stdlib only (`dataclasses`, `re`). It performs no I/O and has no clock.
- `Budget(bubbles: int, sentences: int)`, with `CHAT = Budget(4, 3)` and `DEEPER = Budget(6, 4)`.
- `Segmenter(budget)`:
  - `feed(chunk) -> list[Op]` and `close() -> list[Op]`, where an `Op` is `("delta", text)` or `("bubble", index)`;
  - `.stopped: bool` becomes true at the cap, and later feeds return `[]`;
  - `.bubbles -> list[str]` holds the trimmed bubble texts sent so far.
- It is deterministic and independent of chunk boundaries: any split of the same text gives the same bubbles, and the same break positions relative to the text.
- It follows the rules of Decided defaults 1–2. `close()` flushes nothing but held whitespace, which it drops.

**`divination/turn.py`**:
- `turn_events(request, person)` picks `bubbles.DEEPER` when `request.action == "deeper"`, and `CHAT` otherwise.
- For each drained chunk, it maps the segmenter's ops to frames (`delta {text}`, `bubble {index}`). When `.stopped`, it logs, sets `cancel` and leaves the loop as on `_END`.
- The empty-reply check becomes "no delta sent".
- The side read's `reply` is `"\n\n".join(seg.bubbles)`.
- A cast still rolls first, and only `action == "cast"` rolls.
- The signature, deadline, keepalives and error codes are unchanged.

**`divination/render.py`**:
- `system_prompt(persona, lang, ctx=None, cast=None, action="chat")` builds, in order: persona base → `shape.chat` or `shape.deeper` → `depth.chart` (ctx present) or `depth.none` → the rest exactly as today (chart section → dice → lang).
- `turn_messages(..., action="chat")` passes `action` through.
- `turn.py` passes `request.action`.
- These fragments are English. Their sentence rules name both `。！？` and `.!?`, so one text serves both languages.

**`models.DivinationTurnRequest`**:
- `action: Literal["chat","cast","deeper"] = "chat"`.
- An after-validator: `deeper` needs a non-empty `transcript` whose last entry has `role == "persona"`. Otherwise it is a 422 before any stream opens.

**core `streamTurn`**:
- A `bubble` frame is yielded as `{type:'bubble', index}` only when a delta was already yielded and `index === lastIndex + 1` (starting at 1) as an integer. It is otherwise dropped.
- `TranscriptEntry` gains `deeper?: true` (user entries, device-only). `toWire` is unchanged and so never sends it.

**web `chat/pacer.ts`**: `createPacer({onReveal, schedule, pauseFor})` takes `push(event)` for delta, bubble and end, plus `flush()` and `dispose()`.
- It reveals deltas at once, unless a pause is running.
- A `bubble` event opens a pause of `pauseFor(prevBubbleChars)`, which is the clamp in Decided default 9. During it, `onReveal` reports `typing: true` and later events queue.
- `end` fires after the queue drains.
- `flush()` reveals everything at once.
- It holds no React state, so vitest drives it with fake timers.

**web `useChat`**:
- `Pending` becomes `{phase, bubbles: string[], typing: boolean, dice?}`.
- `done` is stored at the pacer's `end`. Stop and error call `flush()` first.
- `send(message, action)` accepts `'deeper'` and marks the user entry `deeper: true`.
- `retry` re-sends `'deeper'` for a deeper entry.
- `canDeepen` is true when the last entry is an unstopped persona reply, the entry before it is not deeper, and no turn is pending.
- The persona entry's `text` is `bubbles.map(trim).filter(Boolean).join('\n\n')`.

**web `ChatPanel`**:
- `Entry` renders `paragraphs(entry.text)` as slips under one eyebrow.
- The pending letter renders `pending.bubbles` as slips, the caret on the last one, and a `GhostSlip` (`role="status"`, `chat.writing`) while `typing`.
- `DeeperChip` renders under the last entry when `canDeepen`.
- dw-7's header and greeting blocks are not touched.

### Wire (additive)

| Event | Carries | Added in |
|---|---|---|
| `bubble` | `{index}`, an integer ≥ 1 | dw-9: sent just before the first `delta` of bubble `index`. Never first, never after `done`/`error`. |
| `delta` | `{text}` | dw-9 tightens it: never contains `\n`. |

- **Order:** `dice`? → `delta` (`bubble` `delta`+)* → `done` | `error`.
- **Request:** `action` ∈ `chat | cast | deeper`. `deeper` with a transcript that is empty or ends on a user entry is a 422.
- **Unchanged:** `done`, `error`, the summary wire and the transcript wire.

### Dependency rules and forbidden edges

- ❌ `bubbles.py` imports nothing from `app` (it is stdlib only). The new `test_bubbles_is_pure` includes a planted-import self-check.
- ❌ `bubbles.py` never interprets content: no word lists, no keyword matching, no field output. It reads only line breaks, terminators, closers and whitespace. This is enforced by review plus B-tests on typography only.
- `turn.py` may import `bubbles`. `render.py` does not need it.
- The epic fence, the importer list and the no-state regex are unchanged. `bubbles.py` falls under them automatically.
- ❌ `main.py` and `llm.py` do not change. The streamed-turn exception is unchanged, and `test_main_names_the_synchronous_exceptions` passes as is.
- The web keeps the dw-1 guards: the pacer's timer is injected, and it makes no network call and holds no colour literal.

### Guard and CLAUDE.md amendments (same commit)

- `test_boundaries.py`: add `test_bubbles_is_pure`. No existing pin changes.
- CLAUDE.md rule 10, one sentence appended after the cast sentence: "A persona reply is cut into bubbles by the pure `divination/bubbles.py` (stdlib only; line breaks and sentence ends become `bubble` events under a per-action cap of bubbles × sentences, the provider stream cancelled at the cap). It reads typography, never content, so side fields still come only from the side read; `action:"deeper"` is a turn with the longer budget."
- Epic file: at docs-sync (the grammar table gains `bubble`, and the request gains `deeper`).

### Shared files (landing-conflict surface; dw-9 lands after dw-7)

- **`render.py`, shared with dw-7.**
  - Both insert into `system_prompt` directly after the persona base. The merged order is persona → shape → depth → dw-7 `self.*` → chart → dice → lang, and dw-7's P10 order (persona < `self.read` < sheet < `chart.read`) still holds.
  - Both add a keyword parameter (`voice=None` for dw-7, `action="chat"` for dw-9). Both are kept.
  - Fragment declarations: dw-9's go after dw-7's.
- **dw-7's chart-less golden fixtures** (`server/tests/fixtures/divination_chartless_{en,zh}.txt`) MUST be re-recorded at dw-9's landing merge, from the merged `render.system_prompt("venus", lang)`. The diff must be exactly dw-9's persona-line removals, the shape and depth fragments, and the `lang.zh` edit. The DECISIONS.md 2026-09-28 dw-7 planning risk anticipated this.
- **`turn.py`**: dw-7 adds `voice=None` and a pass-through, and dw-9 changes the loop body. The hunks are separate.
- **`ChatPanel.tsx`**: dw-7 owns the header and greeting. dw-9 owns `Prose`/`Entry`, the pending render and the chip, and leaves the greeting `Letter`'s inner content alone.
- **`i18n/en.ts`/`zh.ts`**: dw-9 appends keys inside `chat` (after `houses`). dw-7 appends a `persona` namespace.
- **`models.py`**: dw-9 edits `DivinationTurnRequest` in place. dw-7 and dw-12 add models at EOF.
- **Untouched by dw-9:** `main.py`, `llm.py`, `store.py`, `summary.py`, `generation.py`, migrations, `log/`, `theme/`, `App.tsx`.

## Acceptance Criteria

Server tests monkeypatch `llm.stream_turn` and `llm.generate_sections` only. Charts are REAL (chart A is the dw-3 fixture: 1990-06-15 08:30 Beijing). Run `npm run server:test`, `npm test` and `npm run typecheck`.

**Segmenter** (pure unit tests on `bubbles.Segmenter`)
- **B1**: Chunks `["Hi.\nThe", "re.\n\n\nLast"]` produce the ops delta "Hi.", bubble 1, delta "The", delta "re.", bubble 2, delta "Last". No delta contains `\n`.
- **B2 (sentence cap)**: The chat budget fed "One. Two. Three. Four. Five." as one chunk gives bubble 0 = exactly "One. Two. Three.", then `bubble 1`, then "Four. Five.". No sentence is split. "Pi is 3.5 here. Next" counts one sentence end.
- **B3 (CJK)**: "一。二！三？四。" gives a break before "四". `他说："好。"然后` counts one sentence, ending after `"`.
- **B4 (bubble cap)**: Five one-line paragraphs under the chat budget give exactly 4 bubbles, and the segmenter reports stopped after the 4th. Under the deeper budget, seven paragraphs give 6 bubbles. Twenty sentences with no line break give 4 bubbles of 3 sentences, then stop.
- **B5**: Leading `"\n\n  "` produces no bubble event and no leading whitespace. An all-whitespace stream produces no delta.

**Turn** (`test_divination_turn.py` and siblings)
- **T1**: The existing dw-2/3/5 event-list tests pass UNCHANGED, because single-paragraph fakes produce no `bubble`.
- **T2**: A fake yielding "A.\n\nB." streams delta "A.", `bubble {"index":1}`, delta "B.", then `done`. The side read's `reply` equals "A.\n\nB.".
- **T3 (cut)**: Use a fake that yields five one-line paragraphs and then blocks on an event for 5 s.
  - The stream holds exactly 3 `bubble` events and no text of paragraph 5.
  - `done` arrives in under 2 s, so the cut does not wait for the provider to end.
  - The side read's `reply` has exactly 4 paragraphs.
  - The fake's generator is closed (its `finally` ran) once the turn ends.
- **T4 (cast order)**: A cast with a two-paragraph fake streams `dice`, delta, `bubble 1`, delta, `done`.
- **T5 (deeper)**:
  - `action:"deeper"` with a transcript ending in a persona entry streams under the 6 × 4 budget: a seven-paragraph fake gives 5 `bubble` events.
  - The system prompt contains `shape.deeper` and no `shape.chat`.
  - No `dice` frame is sent.
  - With an empty transcript, or one ending in a user entry, `deeper` answers 422 and calls no fake.
  - `action:"roll"` is 422.
- **T6 (prompt)**:
  - A chat turn's system text has persona base < `shape.chat` < `depth.none` (no birth data) or `depth.chart` (chart A) < the chart section < lang.
  - `venus.txt` no longer contains "60 to 180" or "three", `venus-dice.txt` does not contain "180", and `lang.zh` does not contain "三段".
  - `depth.chart` contains the key phrases for "because", consequence, "one question" and not-true-of-anyone.
  - FINGERPRINT differs from HEAD b308a92's.
- **T7 (boundaries)**:
  - `test_bubbles_is_pure` passes: `bubbles.py` imports only the stdlib. A planted `from app import llm` turns it red.
  - `test_main_names_the_synchronous_exceptions`, the divination fence, the no-state and importer tests pass unchanged.
  - `main.py` and `llm.py` are unchanged from b308a92.

**Core and web** (vitest, fake timers, stubbed stream)
- **C1**: `streamTurn` yields `bubble` 1 then 2 between deltas. It drops a `bubble` before the first delta, a repeated index, a skipped index, and a non-integer index. `TurnAction` accepts `'deeper'`.
- **C2**: A stored user entry with `deeper: true` survives reload (transcript sanitize). `toWire` never sends `deeper`. A persona entry's text is stored as the bubbles joined by `\n\n`, and `toWire`/`summaryWire` send exactly that text.
- **W1**: A stream of delta "A.", `bubble 1`, delta "B.", `done` renders:
  - one slip "A." first;
  - a ghost slip (role status, "Venus is writing") for 450 ms, since "A." is short, with "B." not yet in the DOM;
  - then two slips.
  
  The stored entry appears (chips shown, `showRefs` called) only after that pause.
- **W2**: The pause for a 100-character first bubble is 800 ms, and for a 300-character one it is 1,100 ms. Two quick breaks produce two sequential pauses.
- **W3**: Stop during a pause stores a stopped entry holding every received bubble, and an error mid-pause shows the same text as the partial.
- **W4 (chip)**:
  - The chip is shown under the last finished persona entry only.
  - It is hidden while pending, under a stopped entry, and under a reply to a deeper ask.
  - Pressing it POSTs a turn with `action:"deeper"` and `message` = `chat.deeperAsk`, and appends a user entry with `deeper: true` whose line shows the "· deeper" mark.
  - Retry of a failed deeper entry re-sends `action:"deeper"`.
- **W5**: An old entry whose text holds three blank-line paragraphs renders as three slips under one eyebrow, with its chips after the last one. `SessionTranscript` renders a two-bubble entry as two paragraphs, and the log tests pass unchanged.
- **W6**:
  - The i18n parity test passes with `chat.deeper`, `chat.deeperAsk`, `chat.deeperMark` and `chat.writing` in en and zh.
  - `chat.css` has a `prefers-reduced-motion: reduce` block that stops the ghost-slip stars and the slip rise.
  - The colour, barrel, network and arithmetic guards pass, and no token is added to `theme/tokens.ts`.

**Real app** (backend with `ANALYSIS_LLM=claude-cli`, `DATABASE_URL` overridden to empty so SQLite is used, and CORS for the Vite origin; Vite with `VITE_API_BASE` set to that backend; any free ports; chart A entered)
- **A1 (shape)**: Ask three questions in turn: "Should I tell him how I feel?", "Why do I always pick people who pull away?" and "Is this friendship worth saving?".
  - Each reply renders as 2–4 slips, each of at most 3 sentences.
  - The network panel's event stream shows `bubble` events between deltas.
  - A ghost slip with stars is visible between slips on at least one reply (a screenshot is logged).
- **A2 (depth, checker's rubric)**: For each A1 reply, the log quotes the reply verbatim, and all of these hold:
  - (a) It names at least one placement or aspect, and each named one matches chart A's `/api/chart` output.
  - (b) It states one consequence specific to the question asked.
  - (c) It contains exactly one question to the person, in its last slip.
  - (d) At most one sentence names neither a chart fact nor a detail of the question.
  - (e) `done.chartRefs` is non-empty.
- **A3 (go deeper)**: Press "go deeper" under the first reply.
  - The reply has more sentences than the reply it deepens, at most 6 slips, and each slip at most 4 sentences.
  - It names at least two placements or aspects of chart A (verified) and says how they bear on each other.
  - The chip is absent under it and returns under the next ordinary reply.
- **A4 (continuity)**:
  - A reload shows the same slips and chips.
  - Pressing a chip lights the wheel.
  - End session produces a summary card.
  - Reopening that session shows each bubble as its own paragraph.
- **A5 (zh)**: With 中, the same first question gets 2–4 Chinese slips, each ending in 。/？/！, with at most 3 sentences each.
