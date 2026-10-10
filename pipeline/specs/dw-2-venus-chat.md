# Feature Specification: dw-2-venus-chat

DIVINATION WEB EPIC, entry 2 of 6. Epic architecture:
`pipeline/epics/divination-web.md` (cited, not restated). Rulings:
DECISIONS.md "2026-09-28 · divination-web epic · user rulings".

## Goal

Implement QUEUE.md `dw-2-venus-chat`: the user chats with Venus in a panel
beside the wheel. Her reply streams in word by word, in character, over
`POST /api/divination/turn` (SSE). The transcript lives on the device and
survives a reload.

## Non-goals

- **No chart grounding.** Birth data is not sent. There is no natal
  context and no `chartRefs`; that is dw-3. Venus must not claim to know
  the user's placements.
- No dice (dw-5), no summaries, "end session" or history list (dw-6), and
  no wheel activation (dw-4).
- No persona other than `venus`. The wire accepts only `"venus"`.
- No server conversation state of any kind: no session id, no table, no
  cache of turns, and no journal write (rules 6 and 9; epic dependency
  rules).
- No accounts or auth header on the turn. It is identity-free.
- No "clear conversation" control and no multiple threads. A new thread is
  dw-6's "end session".
- No deploy, no Render CORS change, no native (app-native) chat screen. The
  native app does not configure the stream port.
- No markdown rendering of replies. Replies are plain paragraphs.
- No paid-key requirement in any automated test.

## Decided defaults

**Persona and voice**
- `server/app/divination/personas/venus.txt` is a registered asset of a
  new prompt topic `divination` (`register_topic`). Its content:
  - She speaks in the first person as Venus: warm, candid, a little wry;
    relationships first (love, attraction, friendship, self-worth).
  - She answers the actual question, 60–180 words, in 1–3 plain
    paragraphs, with no headings, lists or emoji.
  - She never says she is an AI or a language model. If asked, she stays
    in character without lying about facts.
  - She does not yet have the user's chart and invents no placements. If
    asked about their chart, she says she has not read it yet.
  - She never gives medical, legal or financial directives.
- A second registered fragment per language tells her to reply in English
  or in Simplified Chinese. `lang` picks it.
- `divination.FINGERPRINT` is the topic fingerprint. No dw-2 cache keys
  on it; it exists so a persona edit is visible to later content-keyed
  stores (dw-6).

**Mood (the one dw-2 side field)**
- A closed enum of five: `tender`, `playful`, `candid`, `wistful`,
  `radiant`.
- It is produced AFTER the reply finishes by one structured
  `generate_sections` call (the "side read"). That call reads the last
  user message and the finished reply, and returns `{mood}`. The mood is
  never parsed from the prose.
- If the side read fails, is refused or runs past the deadline, `done`
  still arrives with `mood: null`, because the reply stands.
- The UI shows the mood as a small-caps tag under the finished reply, in
  the current language. `null` shows no tag.

**Limits and validation (422 on violation, before any stream opens)**
- `persona` must be `"venus"`.
- `lang` must be `en` or `zh`.
- `message`, trimmed, is 1–2,000 characters.
- `transcript` has at most 40 entries. Each entry is `{role: "user" |
  "persona", text}` with text of 1–8,000 characters.
- The client sends at most the last 40 entries. Older entries stay on the
  device but are not sent.

**Timeouts**
- One deadline per turn covers both the stream and the side read. It is
  60 s by default, 240 s under `ANALYSIS_LLM=claude-cli`, and
  `DIVINATION_TURN_TIMEOUT_S` overrides it. A non-positive or non-numeric
  value warns once and falls back to the default, like
  `fitness_timeout_s`.
- If the deadline passes before the reply text ends, the stream sends
  `error {code:"timeout"}` and closes.
- If it passes during the side read, `done {mood:null}` is sent.

**Failures**
- No provider configured (not backup mode and no key): a plain JSON 503
  with no stream, gated the way `judge_available` is.
- A provider failure or refusal after the stream opened:
  `error {code:"unavailable"}`. Text already sent stays on screen but is
  not saved as a reply.
- No retries inside a turn. The user retries.

**Client behaviour** (web, `src/chat/`)
- The panel mounts in the App side slot, below the placements. It is
  always present, with or without birth data.
- An opening greeting from Venus comes from the dictionary and is shown
  above the transcript. It is never sent and never persisted.
- Sending:
  - Enter sends and Shift+Enter adds a newline. An empty or
    whitespace-only message cannot be sent.
  - The user's entry is appended and persisted immediately.
  - While a turn is in flight, the send button becomes **Stop** and the
    input stays editable but cannot send.
- Streaming states:
  - *Awaiting*: after send and before the first `delta`, a "Venus is
    listening" line with three twinkling stars (static under
    `prefers-reduced-motion`).
  - *Streaming*: the text grows in place with a blinking ♀ caret at its
    end. `aria-busy="true"` is set on the log.
  - *Done*: the caret goes, the mood tag appears, and the persona entry
    `{role:"persona", text, mood}` is persisted.
- **Stop** aborts the request. Any partial text is kept and persisted as a
  persona entry with `stopped: true` and a "stopped" note. It is sent as
  context on later turns. Stopping before any text persists nothing.
- On an error (a wire error, a non-200, or a stream that ends without
  `done`), the user's message stays, followed by an error line in the
  current language with **Retry**. Retry re-sends that message with the
  transcript before it. The same state is shown after a reload when the
  last persisted entry is a user message.
- Scrolling:
  - The log is a scroll box, at most 60vh tall on desktop.
  - It stays pinned to the bottom while text streams, unless the user has
    scrolled more than 48 px up.
- Look:
  - The panel continues the ink-and-gold ground.
  - Venus's replies are set as letter prose (`--font-body`, 1.02rem, line
    height 1.6) with no bubble, under a small ♀ "Venus" eyebrow in a new
    rose-copper token `venus`.
  - User lines are right-aligned italic with `--text-dim` and a thin
    `line-soft` rule.
  - All colours come from `theme/tokens.ts` (rule 13): add `venus`, and
    add `venusGhost` for the caret glow if it is needed.
- **i18n**: a new `chat` namespace in en and zh, with exact-key parity
  (greeting, placeholder, send, stop, retry, listening, stopped, the error
  codes, the five moods, and the panel title).

**Storage**
- KV key `astrology.divination.transcript.v1.venus`. It holds a JSON array
  of entries.
- It is not profile-namespaced: the web pins one local profile, and
  birth-data edits leave the conversation intact.
- A corrupt value reads as empty. It is never thrown.

**Local runs**
- The backend runs on a free port, not :8000, which another checkout
  holds:
  `CORS_ALLOW_ORIGINS=http://localhost:5173 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001`
- The web runs with `VITE_API_BASE=http://localhost:8001 npm run web`.
- Manual LLM checks use `ANALYSIS_LLM=claude-cli`.
- Code defaults stay unchanged.

## Architecture

Cites the epic's Reuse map, Target modules and Dependency rules. Written
here is dw-2's delta only.

### Reuse (verified 2026-09-28)

| Need | Existing | Use |
|---|---|---|
| Provider resolution | `llm.py` `_backup_mode_active` :393, `_resolve_cli_model` :398, `_get_provider` :559, `_model_id_as_sent` :374, `_get_client` :449 | Reuse. `stream_turn` resolves providers exactly as `generate_sections` :668 does. |
| Structured side read | `llm.generate_sections` :668 | Called by `divination/turn.py`, never by main.py. |
| Prompt assets | `prompts.register_topic` :129, `.asset` :93, `.declare`, `.text`, `.fingerprint` :118 | Pattern of `ask/fitness_prompt.py` :21-33. |
| Bounded-wait shape | `ask/fitness.py`: `fitness_timeout_s` :228, `_executor` :251, `check_bounded` :254, `shutdown` :266; `judge_available` :191 | Copy the shape, per turn. |
| Sync-exception pin | `tests/test_ask_fitness.py:561` `test_main_names_the_one_synchronous_judge` | Superseded (below). |
| Delivery guard | `tests/test_boundaries.py:102` `GENERATE_ON_REQUEST_RE`, :115 | Widened with `stream_turn`. |
| Tier C fence pattern | `test_boundaries.py:162` `_forbidden_imports_re`, :179 `_offenders`, :233-272 (ask) | Copied for divination. |
| Core KV | `packages/core/src/platform/storage.ts` `getKV` | Transcript storage. |
| Core API base | `platform/api.ts` `apiUrl` | Core builds the turn URL. |
| Web composition root | `web-divination/src/platform/boot.ts` | Installs the stream adapter. |
| Web side slot | `web-divination/src/app/App.tsx` (the `dw-2` comment in `<aside>`) | Mounts `ChatPanel`. |

### Module map (new or changed)

```
server/app/
├── llm.py                     + stream_turn(system, messages) -> Iterator[str]
├── divination/                NEW Tier C package (the fourth, beside interpretation, cards, ask)
│   ├── __init__.py
│   ├── personas/venus.txt     persona asset
│   ├── render.py              topic registry, system prompt, messages, side-read prompt + MOOD schema
│   └── turn.py                deadline, worker thread, SSE framing, availability gate
├── models.py                  + DivinationTurnRequest, TranscriptEntry (pydantic, limits above)
└── main.py                    + POST /api/divination/turn (StreamingResponse); lifespan calls turn.shutdown()
server/tests/  test_llm_stream.py, test_divination_turn.py, test_boundaries.py (+divination fences),
               test_ask_fitness.py (pin renamed; see Amendments)
packages/core/src/
├── platform/stream.ts         NEW port: StreamPost + configureStreamPost/getStreamPost
├── platform/sse.ts            NEW pure SSE parser over string chunks
├── platform/index.ts          + exports of both
├── divination/{types,turn,transcript,index}.ts   NEW (wire types, streamTurn, KV transcript)
└── package.json exports       + "./divination"
web-divination/src/
├── platform/stream.ts         NEW web adapter: fetch + body.getReader() + TextDecoder
├── platform/boot.ts           + configureStreamPost(webStreamPost)
├── chat/                      NEW ChatPanel + useChat hook + chat.css
├── app/App.tsx                mounts <ChatPanel/> in the side slot
├── theme/tokens.ts            + venus (+ venusGhost)
└── i18n/{en,zh}.ts            + chat namespace
```

### Module contracts

**`llm.stream_turn(system: str, messages: list[{"role": "user"|"assistant", "content": str}]) -> Iterator[str]`**
- Yields non-empty text chunks in order. It raises `AnalysisUnavailable`
  on config error, transport failure or refusal, before or during
  iteration.
- `generator.close()` closes the SDK stream or kills the subprocess.
- It uses its own output cap `_TURN_MAX_TOKENS` (8,000) and has no
  thinking, no JSON schema and no 429 retry.
- Per provider:
  - *Anthropic*: `messages.stream(...)` over `text_stream`.
  - *OpenAI-compat*: `chat.completions.create(stream=True)` with the
    system message prepended, yielding `delta.content`.
  - *claude-cli*: `claude -p --output-format stream-json --verbose
    --include-partial-messages --model <cli model>` via `Popen`, with the
    transcript flattened into one role-labelled prompt on stdin. It reads
    NDJSON lines and yields `text_delta` text from `stream_event`
    content-block deltas. If no partial deltas arrive, it yields the final
    `assistant` message's text once. A non-zero exit or an `is_error`
    result raises.
- Still the only SDK importer (rule 3). The CLI branch stays stdlib-only.

**`divination/render.py`** (Tier C prompt building; no I/O)
- `PROMPTS = register_topic("divination")`, holding `persona.venus` (the
  asset), `lang.en`, `lang.zh`, and `side.role`. `FINGERPRINT =
  PROMPTS.fingerprint`.
- `MOODS = ("tender","playful","candid","wistful","radiant")` and
  `MOOD_SCHEMA` (strict: `{mood: enum}`).
- `turn_messages(persona, transcript, message, lang) -> (system,
  messages)` maps `persona`→`assistant` and appends the new user message.
- `side_prompt(message, reply, lang) -> (system, user)`.

**`divination/turn.py`**
- `turn_available() -> bool` works like `judge_available`.
- `turn_timeout_s() -> float` works like `fitness_timeout_s`.
- `turn_events(request) -> Iterator[bytes]` yields SSE frames:
  - A worker on the module `_executor` drains `llm.stream_turn` into a
    `queue.Queue`.
  - The generator waits on the queue with the remaining deadline and emits
    `delta` per chunk.
  - Then the side read runs (`generate_sections` on the executor under the
    remaining deadline), then `done`.
  - On deadline it emits `error{timeout}` and sets a cancel flag. The
    worker closes the provider generator at its next chunk.
  - A client disconnect (the generator closed) sets the same flag.
- `shutdown()` works like fitness's.

**`main.py` `divination_turn`**
- Validates the request (pydantic → 422).
- Returns a JSON 503 when `not turn_available()`.
- Otherwise returns `StreamingResponse(divination_turn.turn_events(req),
  media_type="text/event-stream", headers={"Cache-Control": "no-cache",
  "X-Accel-Buffering": "no"})`.
- Its docstring names the rule-14 exception, `dw-2-venus-chat`, and the
  pinning test.

**core `platform/stream.ts`**
- `type StreamPost = (url: string, init: {body: string; headers:
  Record<string,string>; signal?: AbortSignal}) => Promise<{status:
  number; chunks: AsyncIterable<string>}>`.
- `configureStreamPost(fn)` and `getStreamPost()`. With no adapter
  configured, `getStreamPost()` throws `Error('stream reader not
  configured')`.
- The port names no Web global.

**core `platform/sse.ts`**
- `parseSse(chunks: AsyncIterable<string>): AsyncIterable<{event: string;
  data: string}>`.
- It handles frames split across chunks, `\r\n`, multi-line `data:`, and
  `:` comments. It is pure string logic.

**core `divination`** (barrel `@astrace/core/divination`)
- Types:
  - `PersonaId = 'venus'`
  - `Mood`
  - `TranscriptEntry {role:'user'|'persona'; text; mood?: Mood|null; stopped?: true}`
  - `TurnRequest`
  - `TurnEvent = {type:'delta';text} | {type:'done';mood:Mood|null} | {type:'error';code:TurnErrorCode}`
  - `TurnErrorCode = 'timeout'|'unavailable'|'invalid'|'network'|'interrupted'`
- `streamTurn(req, {signal?}): AsyncIterable<TurnEvent>`:
  - POSTs `apiUrl('/api/divination/turn')` through `getStreamPost()`.
  - HTTP 422 → `invalid`, other non-200 → `unavailable`.
  - A thrown transport error → `network`.
  - A stream ending without `done` or `error` → `interrupted`.
  - An abort ends the iteration silently, with no event.
  - Unknown event names are ignored, which lets dw-3 and dw-5 add events.
- `toWire(entries)` returns the last 40 entries as `{role, text}`.
- Transcript store on `getKV()`:
  - `getTranscript(persona)` returns a stable snapshot for
    `useSyncExternalStore`.
  - Also `appendEntry(persona, entry)` and `subscribeTranscript(persona,
    cb)`.
- No astrology arithmetic and no React.

**web `platform/stream.ts`**
- `webStreamPost` is the one place `response.body.getReader()` and
  `TextDecoder` (`stream: true`) appear.
- It sends `fetch(url, {method:'POST', body, headers, signal})`.

**web `chat/`**
- Renders the states in Decided defaults.
- It reaches the network only via `streamTurn`, and storage only via the
  core transcript store.

### Wire (fixed by dw-2; later entries only ADD events)

Request `POST /api/divination/turn`, `Content-Type: application/json`:
`{"persona":"venus","transcript":[{"role":"user"|"persona","text":"…"}],"message":"…","lang":"en"|"zh"}`

Response `200 text/event-stream`, frames `event: <name>\ndata: <json>\n\n`:

| Event | Data | Cardinality |
|---|---|---|
| `delta` | `{"text": str}` (non-empty) | 0..n, in order; concatenation = the reply |
| `done` | `{"mood": "tender"\|"playful"\|"candid"\|"wistful"\|"radiant"\|null}` | exactly one, last, on success. dw-3 adds `chartRefs` |
| `error` | `{"code": "timeout"\|"unavailable"}` | exactly one, last, on failure. Never follows `done` |

Non-stream answers: `422` (validation) and `503 {"detail":"divination
unavailable"}` (no provider).

### Dependency rules and forbidden edges

- `divination` may import `app.llm`, `app.prompts` and (from dw-3 on)
  chart and dictionary.
- ❌ It may not import interpretation, cards, ask, selection, db,
  accounts, journal, jobs or generation.
  - Pinned by `test_divination_imports_only_llm_prompts_chart_dictionary`,
    with self-checks.
- ❌ No tier or infrastructure package imports `divination`. Only main.py
  may (`test_no_tier_imports_divination`).
- ❌ main.py never names `stream_turn` or `generate_sections`; it names
  `turn_events` exactly once.
- ❌ `packages/core/src` never names `ReadableStream`, `TextDecoder` or
  `getReader(`. The stream enters only through the port.
- ❌ `web-divination/src/chat` names no network API. The existing guard G3
  already covers this, and the adapter sits in `src/platform/`, which G3
  allows.
- The core → app direction is unchanged. The web imports
  `@astrace/core/divination` and `/platform` through barrels only
  (existing guard).

### Amendments (same commit as the code)

- **CLAUDE.md rule 14.** Replace "ONE synchronous exception" with "TWO".
  The second is `POST /api/divination/turn`: a streamed SSE turn on the
  request thread (streamed-turn ruling, 2026-09-28), bounded by
  `divination/turn.turn_timeout_s` (60 s paid / 240 s claude-cli /
  `DIVINATION_TURN_TIMEOUT_S`). A timeout sends `error{timeout}`, and the
  server keeps no turn state. Both exceptions are pinned by
  `test_main_names_the_synchronous_exceptions`.
- **The pin.** `test_main_names_the_one_synchronous_judge` is renamed
  `test_main_names_the_synchronous_exceptions` and moves to
  `test_boundaries.py`. It asserts:
  - `check_bounded(` and `turn_events(` each appear once in comment-free
    main.py;
  - each route's docstring cites its feature slug and the new test name;
  - main.py never names `generate_sections` or `stream_turn`.
  - The `ask_fitness` docstring is updated to the new name.
- **Rule 3.** `llm.py` also owns the multi-turn streaming entry
  `stream_turn` for all providers. The claude-cli transport is stdlib
  `subprocess` with `stream-json`.
- **Rule 10.** `app/divination` is a Tier C package parallel to
  interpretation, cards and ask. It may import llm, prompts, chart and
  dictionary, and nothing imports it but main.py. It is test-enforced in
  `test_boundaries.py`.
- **Rule 1.** Name the stream port: core reads HTTP streams only through
  the `core/platform` `StreamPost` port. `ReadableStream`, `TextDecoder`
  and `getReader(` are added to the core Web-global guard
  (`app-native/src/architecture.test.ts:102` family, as a sibling regex
  with self-checks). The web adapter lives app-side, in
  `web-divination/src/platform/stream.ts`, so `web-kv.ts` stays the only
  exempt core file.
- **Rule 5.** It already covers "HTTP only, network only in platform/".
  No text change is needed.
- **Epic file.** Nothing is needed now: docs-sync records what landed.

## Acceptance Criteria

Server tests use FAKE providers only (a monkeypatched `llm.stream_turn`
and `generate_sections`, or fake SDK clients and a fake `Popen`). No paid
key and no network are needed. Run: `npm run server:test`, `npm test`,
`npm run typecheck`.

**Server**
- **S1**: With a fake `stream_turn` yielding `["Hel","lo, ","dear."]` and
  a fake side read returning `{mood:"tender"}`, `POST
  /api/divination/turn` (TestClient) answers 200 `text/event-stream`. The
  body parses to exactly `delta Hel`, `delta lo, `, `delta dear.`, `done
  {"mood":"tender"}`, in that order.
- **S2**: The fake `stream_turn` receives a system prompt containing the
  `venus.txt` text and the `lang.zh` fragment when `lang:"zh"`. Its
  messages are the transcript with `persona`→`assistant`, followed by the
  new user message last.
- **S3**: A side read raising `AnalysisUnavailable` gives `done
  {"mood":null}`, and the deltas are unchanged. A side read returning a
  mood outside the enum also gives `null`.
- **S4**: A fake `stream_turn` that yields one chunk and then sleeps past
  `DIVINATION_TURN_TIMEOUT_S=0.5` gives `delta`, then `error
  {"code":"timeout"}`, and no `done`. The response completes within 3 s.
- **S5**: A fake `stream_turn` raising `AnalysisUnavailable` after one
  chunk gives `delta`, then `error {"code":"unavailable"}`.
- **S6**: With no provider key and `ANALYSIS_LLM` unset, the route answers
  a JSON 503 and `stream_turn` is never called.
- **S7**: Each of these answers 422 and never calls the fake: `persona:
  "mars"`, `lang:"fr"`, an empty or whitespace message, a 2,001-character
  message, 41 transcript entries, and a role `"system"`.
- **S8**: `llm.stream_turn` unit tests, one per provider:
  - a fake Anthropic client whose `text_stream` yields chunks;
  - a fake OpenAI client yielding `delta.content` chunks (with `None`
    skipped);
  - a fake `Popen` emitting recorded `stream-json` NDJSON lines
    (`stream_event` text deltas and a final `result`).
  Each yields exactly the text chunks. For each, a transport error raises
  `AnalysisUnavailable`. For the CLI, a non-zero exit or an `is_error`
  result raises, and argv contains `--output-format stream-json`.
- **S9**: `test_boundaries.py` passes with the new tests:
  - the divination fence, with self-checks that bite on `from
    app.interpretation import x` and `from .. import jobs`;
  - `test_no_tier_imports_divination`;
  - `GENERATE_ON_REQUEST_RE` matching `stream_turn(`;
  - `test_main_names_the_synchronous_exceptions`.
  Planting `from app.cards import store` in `divination/render.py` turns
  the fence red.
- **S10**: `divination.render.FINGERPRINT` changes when `venus.txt`
  changes (a test registers a modified copy in a fresh registry), and the
  topic `divination` appears in `prompts.topics()`.
- **S11**: grep: no file under `server/app/divination/` contains a table,
  write or insert statement. The only non-test importer of
  `app.divination` is `main.py`.

**Core and guards**
- **C1**: `parseSse` reassembles events split across arbitrary chunk
  boundaries. The test feeds the S1 body one character at a time and gets
  the same four events; `\r\n` and `:` comment lines are handled.
- **C2**: `streamTurn` with a fake `StreamPost`:
  - maps a 200 stream to the `TurnEvent`s;
  - maps 422 → `invalid`, 503 → `unavailable`, and a thrown error →
    `network`;
  - maps a stream ending after deltas with no `done` → `interrupted`;
  - ignores an unknown event `dice` without error;
  - on an aborted signal, ends with no further events.
- **C3**: The transcript store round-trips through the KV port. A corrupt
  KV value reads as `[]`. `toWire` of 45 entries returns the last 40 as
  `{role,text}` only.
- **C4**: `app-native/src/architecture.test.ts` passes. Planting
  `new TextDecoder()` in any `packages/core/src` file turns the new core
  stream guard red, naming the file. The regex self-checks cover
  `ReadableStream` and `getReader(`.
- **C5**: The existing guards stay green:
  - barrels only;
  - no network outside `web-divination/src/platform` — planting
    `fetch(` in `src/chat/` turns G3 red;
  - colour only in `theme/tokens.ts`;
  - the en/zh parity test covers the `chat` namespace;
  - root `npm test` and `npm run typecheck` pass.

**Web (vitest, fake StreamPost)**
- **W1**: Typing "Will he call?" and pressing Enter first shows the user
  line and the "listening" state. After the fake stream sends deltas, the
  reply text grows (asserted between deltas), and after `done
  {mood:"candid"}` the reply shows the mood tag in the current language.
  KV then holds both entries.
- **W2**: While streaming, the button reads Stop. Clicking it aborts the
  fake's signal, and the partial text stays with the "stopped" note,
  persisted as `stopped: true`.
- **W3**: An `error {timeout}` shows the translated error and a Retry
  button. Retry calls `streamTurn` again with the same message and the
  transcript before it, and success replaces the error with the reply.
- **W4**: Remounting the App with a pre-seeded KV transcript renders it in
  order. A seed ending in a user entry shows Retry.
- **W5**: Shift+Enter inserts a newline and does not send. A
  whitespace-only input cannot be sent.

**Real app** (backend on :8001 with `ANALYSIS_LLM=claude-cli` and CORS
for :5173; `VITE_API_BASE=http://localhost:8001 npm run web`)
- **A1**: The chat panel sits in the side column beside the wheel with
  Venus's greeting. Its computed text colour of the "Venus" eyebrow equals
  the `venus` token value.
- **A2**: Asking "How do I know if a friendship is worth saving?" shows
  the listening state, then text that grows across at least 3 successive
  DOM samples taken ≥200 ms apart before completion (it is not one final
  paint). The reply is in first-person Venus voice, 1–3 paragraphs, with
  no markdown symbols (`#`, `*`, `- `). A mood tag appears.
- **A3**: The browser network panel shows one `POST
  /api/divination/turn` with response type `text/event-stream`. No other
  divination request is made, and the request body has no birth data.
- **A4**: Reload shows the same transcript, with the greeting, user line,
  reply and mood.
- **A5**: With the language set to 中, a new question gets a reply in
  Chinese, and the UI labels are Chinese.
- **A6**: Sending a question and pressing Stop mid-reply leaves the
  partial text with the "stopped" note. After a reload it is still there.
- **A7**: Stopping the backend and sending shows the translated error with
  Retry. Restarting the backend and pressing Retry streams a reply.
