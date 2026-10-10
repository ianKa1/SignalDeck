# Implementation Plan: dw-2-venus-chat

Spec: `pipeline/specs/dw-2-venus-chat.md` (WHAT + Architecture, reviewed PASS
in `logs/dw-2-venus-chat/02-spec-review.md`). Epic: `pipeline/epics/divination-web.md`.
Branch `feature/dw-2-venus-chat`. Steps 1–7 are `implementing`, 8 is
`validating`, 9 is `docs-sync`. Tick a box only after its done-when passed
and its `/git-commit` landed (`(<type>): dw-2-venus-chat — <summary>`).
Load `/frontend-design` before steps 6–7. Automated tests use fake
providers only; no paid key, no network.

## Settled review notes

- **Unanswered user entry.** Send stays enabled when the transcript ends in
  a user entry, and Retry is also offered. `render.turn_messages` merges
  adjacent same-role entries (joined by a blank line) and drops leading
  `persona` entries, so the wire never yields consecutive `user` turns or an
  assistant-first list.
- **S11 pattern.** `test_divination_keeps_no_state` in `test_boundaries.py`
  greps comment-stripped `server/app/divination/**/*.py` for
  `CREATE TABLE|INSERT\s+INTO|UPDATE\s+\w+\s+SET|sqlite3|psycopg|app\.db|app\.journal|\.\.\s*import\s+(db|journal)|open\([^)]*['"][wa]`
  and expects no hit. The importer half scans `server/app/**/*.py` for
  `app\.divination|from \.divination|from \. import divination|from \.\.divination`
  and expects exactly `main.py`.
- **Disconnect cancellation.** Pinned by a unit test that calls
  `turn_events(req)`, takes one frame, calls `.close()`, and asserts that the
  fake provider generator's `close()` ran within 1 s (step 3).

## Steps

- [x] **1. `llm.stream_turn` for all providers.**
  Files: `server/app/llm.py`, `server/tests/test_llm_stream.py` (new), `CLAUDE.md` (rule 3).
  Add `stream_turn` and `_TURN_MAX_TOKENS` for the Anthropic,
  OpenAI-compat and claude-cli (`Popen`, stream-json) branches. Resolve
  providers exactly as `generate_sections` does. Amend rule 3.
  Done when: `cd server && conda run -n astrology pytest tests/test_llm_stream.py tests/test_llm_backup_mode.py tests/test_llm_providers.py tests/test_boundaries.py -q` is green, and the S8 cases each have a fake client/`Popen`.

- [x] **2. `app/divination` prompts + Tier C fences.**
  Files: `server/app/divination/{__init__.py,render.py,personas/venus.txt}`,
  `server/tests/test_divination_render.py` (new), `server/tests/test_boundaries.py`,
  `CLAUDE.md` (rule 10).
  Register the `divination` topic (persona, `lang.en`/`lang.zh`,
  `side.role`), `MOODS`, `MOOD_SCHEMA`, `turn_messages` (with the merge
  above), and `side_prompt`. Add
  `test_divination_imports_only_llm_prompts_chart_dictionary` (with
  self-checks), `test_no_tier_imports_divination`, and
  `test_divination_keeps_no_state`.
  Done when: `pytest tests/test_divination_render.py tests/test_boundaries.py tests/test_prompts.py -q` is green (S10 fresh-registry fingerprint and `topics()`; S2 message mapping + merge). Planting `from app.cards import store` in `render.py` turns the fence red (check by hand, then revert).

- [x] **3. `turn.py`, the wire models, the route, and the rule-14 pin.**
  Files: `server/app/divination/turn.py`, `server/app/models.py`,
  `server/app/main.py` (route + `_lifespan` calls `turn.shutdown()`; `ask_fitness`
  docstring names the new test), `server/tests/test_divination_turn.py` (new),
  `server/tests/test_boundaries.py` (widen `GENERATE_ON_REQUEST_RE` with
  `stream_turn`; add `test_main_names_the_synchronous_exceptions`),
  `server/tests/test_ask_fitness.py` (delete the old pin), `CLAUDE.md` (rule 14: ONE→TWO).
  Done when: `pytest tests/test_divination_turn.py tests/test_boundaries.py tests/test_ask_fitness.py -q` is green (S1–S7 plus the disconnect-close test), and `npm run server:test` passes.

- [x] **4. Core stream port + SSE parser + guard.**
  Files: `packages/core/src/platform/{stream.ts,sse.ts,index.ts}`,
  `app-native/src/architecture.test.ts` (sibling `CORE_STREAM_RE` for
  `ReadableStream|TextDecoder|getReader\(`, a test naming the offending file,
  and self-checks), `web-divination/src/platform/sse.test.ts` (new; see
  Deviation D1), `CLAUDE.md` (rule 1: the StreamPost port).
  Done when: `cd app-native && npx jest src/architecture.test.ts` and `cd web-divination && npx vitest run src/platform/sse.test.ts` are green (C1). A planted `new TextDecoder()` in `packages/core/src/platform/poll.ts` turns the guard red and names the file (then revert) (C4).

- [x] **5. Core `divination` domain.**
  Files: `packages/core/src/divination/{types.ts,turn.ts,transcript.ts,index.ts}`,
  `packages/core/package.json` (`"./divination"` export),
  `web-divination/src/chat/core-divination.test.ts` (new; D1).
  Add `streamTurn`, `toWire`, and the KV transcript store (key
  `astrology.divination.transcript.v1.venus`; a snapshot that is stable per
  raw string; corrupt → `[]`). Until step 7 lands, the barrel carries
  `// @public-intent domain: dw-2 chat panel mounts in step 7`. Step 7
  removes it.
  Done when: `npx vitest run src/chat/core-divination.test.ts` covers C2 (fake StreamPost: 200/422/503/throw/interrupted/unknown `dice`/abort) and C3, and `npm run typecheck` at the root is green.

- [x] **6. Web adapter, boot wiring, tokens, i18n.**
  Files: `web-divination/src/platform/{stream.ts,boot.ts,boot.test.ts}`,
  `web-divination/src/theme/tokens.ts` (`venus`, `venusGhost`),
  `web-divination/src/i18n/{en.ts,zh.ts}` (the `chat` namespace).
  `webStreamPost` is the only `getReader()`/`TextDecoder` site. `boot.ts`
  calls `configureStreamPost(webStreamPost)`.
  Done when: `boot.test.ts` asserts that `getStreamPost()` is the web
  adapter after boot. An adapter test over a stubbed `fetch` with a
  `ReadableStream` body yields decoded chunks, including a multi-byte
  character split across chunks. `npx vitest run` passes, including the
  `src/i18n.test.ts` parity test.

- [x] **7. Chat panel.**
  Files: `web-divination/src/chat/{ChatPanel.tsx,useChat.ts,chat.css,ChatPanel.test.tsx}`,
  `web-divination/src/app/{App.tsx,App.test.tsx}`, and the core divination
  barrel (drop the temporary marker).
  Build every state in the spec's Client behaviour. The panel mounts in
  the `<aside>` at the `dw-2` comment. `chat.css` uses only `var(--…)`.
  Done when: `ChatPanel.test.tsx` covers W1, W2, W3 and W5 and
  `App.test.tsx` covers W4 (a fake StreamPost via `configureStreamPost`).
  `npm test`, `npm run typecheck` and `npm run server:test` all pass at the
  root. The C5 guards (barrels, G3, colour, parity, public-API) are green.
  A planted `fetch(` in `src/chat/useChat.ts` turns G3 red (then revert).

- [x] **8. Validating prep and real-app run (A1–A7).**
  Leave :8000 alone; another checkout holds it. Backend, from the repo root:
  `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5173 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001`.
  Web: `VITE_API_BASE=http://localhost:8001 npm run web` (:5173 is strict,
  so free it first). Drive the app with claude-in-chrome:
  - Use computed style for A1.
  - Take 3 or more `innerText` samples ≥200 ms apart for A2.
  - Use `read_network_requests` for A3.
  - Reload for A4 and A6.
  - Use the language toggle for A5.
  - Kill and restart the :8001 process for A7.
  Done when: all A1–A7 are observed and recorded in the validating log.
  Both processes are stopped afterwards.

- [x] **9. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (`/update-architecture-doc`),
  `docs/features/dw-2-venus-chat.md`, and `pipeline/epics/divination-web.md`
  ("Built so far" and "Target modules").
  Done when: the docs name `stream_turn`, `app/divination`, the StreamPost
  port and the second rule-14 exception, and
  `git diff --stat main -- docs` shows the edits.

## Acceptance map

| Criterion | Step |
|---|---|
| S1 SSE order | 3 |
| S2 system prompt + message mapping | 2 (render), 3 (route passes it through) |
| S3 side-read failure / off-enum → null | 3 |
| S4 timeout | 3 |
| S5 mid-stream unavailable | 3 |
| S6 no provider → 503 | 3 |
| S7 422 cases | 3 |
| S8 per-provider `stream_turn` | 1 |
| S9 boundary fences, regex, pin | 2 (fences), 3 (regex + pin) |
| S10 fingerprint + topic | 2 |
| S11 no state, sole importer | 2 (`test_divination_keeps_no_state`), rechecked at 3 |
| C1 `parseSse` | 4 |
| C2 `streamTurn` mapping | 5 |
| C3 transcript + `toWire` | 5 |
| C4 core stream guard | 4 |
| C5 existing guards + root suites | 7 |
| W1 send → stream → mood → KV | 7 |
| W2 Stop | 7 |
| W3 error + Retry | 7 |
| W4 reload renders, trailing user → Retry | 7 |
| W5 Shift+Enter, whitespace | 7 |
| A1–A7 real app | 8 |

## Deviations (for journaling)

- **D1: core seam tests live in web-divination's vitest tree.**
  `packages/core/src/**/*.test.ts` runs under no runner
  (`docs/ARCHITECTURE.md` ~l.4257, and app-native jest `roots` is `src`).
  C1–C3 tests therefore go in `web-divination/src/platform/sse.test.ts` and
  `web-divination/src/chat/core-divination.test.ts`, and import only through
  the `@astrace/core/*` barrels. This follows dw-1's
  `chart/chart-view-additions.test.ts` precedent.
- **D2: adjacent same-role merge in `render.turn_messages`.** It also drops
  leading persona entries. This settles the review's consecutive-user note
  on the server. The spec's `turn_messages` contract did not state it.
- **D3: temporary `@public-intent domain` marker** on the core divination
  barrel between steps 5 and 7. The step-7 commit removes it. This is an
  intermediate state only, following dw-1's D5.
- **D4: the S11 check is a pytest test**
  (`test_divination_keeps_no_state`), not an ad-hoc grep, so it keeps
  biting after this feature lands.

## Risks for the implementer

- **Starlette streaming threads.** Starlette iterates a sync generator
  through `iterate_in_threadpool`. On disconnect it cancels the task, but
  the blocked `queue.get` inside the generator only returns when its
  timeout expires. Poll the queue in short slices (≤0.25 s) against the
  deadline and the cancel flag, or a disconnected turn holds a threadpool
  slot and the CLI subprocess until the deadline (240 s).
- **CLI stream-json.** Check it against the installed `claude --help`:
  `--verbose` is required with `stream-json` under `-p`, and
  `--include-partial-messages` exists. On close, `terminate()` then
  `wait(2)` then `kill()`, and drain stderr so a full pipe cannot block.
  Do not reuse `_invoke`'s `subprocess.run`: the existing backup tests
  monkeypatch `llm.subprocess.run`, so patch `llm.subprocess.Popen` instead.
- **`uvicorn --env-file` does not override the shell.**
  `load_dotenv(override=False)` means the shell's `ANALYSIS_LLM=claude-cli`
  wins. Confirm in step 8 that the side read also runs on the CLI (no paid
  key spent).
- **The side read and the deadline.** Under claude-cli, `generate_sections`
  can take tens of seconds. A2 needs a mood tag, so if the 240 s default
  runs out in real use, report it; do not shorten the persona.
- **Mood validation.** `generate_sections`' shape check only confirms that
  keys are present, so `turn.py` must reject off-enum moods itself (S3).
- **SSE framing.** Each `data:` must be a single line. `json.dumps` never
  emits a raw newline, so do not split the data by hand. Validate and gate
  the 503 BEFORE building the `StreamingResponse`: once it starts, the
  status is already 200.
- **`useSyncExternalStore` snapshot.** `getTranscript` must return the same
  array for the same raw KV string, or React loops. Streaming text is React
  state in `useChat`, never KV, until done or stop.
- **Colour guard on CSS.** Write `var(--venus)`. A literal `rgba(...)` in
  `chat.css` fails the walk, and `apply.ts` already kebabs new token keys.
- **Barrel guard in tests.** The guard walks web test files too (G1), so
  test imports of `parseSse` go through `@astrace/core/platform` only.
