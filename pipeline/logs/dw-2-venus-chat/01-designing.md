# dw-2-venus-chat · 01 designing

Date: 2026-09-28. Branch: feature/dw-2-venus-chat. Output: `pipeline/specs/dw-2-venus-chat.md`.

## Read
- CLAUDE.md; PIPELINE.md (skills per stage, pipeline-mode overrides, epic files, spec requirements, auto spec review); QUEUE.md dw-2 entry + epic comment; `pipeline/epics/divination-web.md`; DECISIONS.md from "2026-09-28 · divination-web epic" on; dw-1 spec (structure only).
- Targeted code confirmation: `server/app/llm.py` :374-701 (providers, resolution, generate_sections); `prompts.py` :80-141; `main.py` :360-410 (ask_fitness) + CORS/lifespan; `ask/fitness.py` :191, :228-269; `tests/test_ask_fitness.py:561`; `tests/test_boundaries.py` (tier fences, GENERATE_ON_REQUEST_RE :102); `packages/core/src/platform/{index,api,storage}.ts`, core AbortSignal/TextDecoder usage; `web-divination/src/{app/App.tsx, platform/boot.ts, session.ts, i18n/*, theme/tokens.ts, app/app.css}`; `app-native/src/architecture.test.ts` WEB_GLOBAL_RE :102 and G3 :553-565.

## Skills invoked (in order)
1. `frontend-design` — visual bar: letter-prose replies, no bubbles, ♀ eyebrow + caret in a new rose-copper `venus` token, twinkling-star listening state (static under reduced motion), right-aligned italic user lines.
2. `feature-spec` (pipeline mode) — Goal, Non-goals, Decided defaults, Acceptance Criteria.
3. `architecture-designer` (pipeline mode) — Architecture section (delta over the epic file; no Migration Steps).

## Key decided defaults
- Mood = closed 5-value enum, produced by a post-stream structured side read (`generate_sections`), never parsed from prose; side-read failure → `done {mood:null}`.
- One per-turn deadline (60 s paid / 240 s claude-cli / `DIVINATION_TURN_TIMEOUT_S`) covering stream + side read.
- Limits: message ≤2,000 chars, transcript ≤40 entries (client sends last 40), 422 before streaming; no-provider → JSON 503.
- Stop keeps partial text as `stopped:true` persona entry; errors keep the user message with Retry (also after reload).
- KV key `astrology.divination.transcript.v1.venus` (not profile-namespaced); greeting is dictionary text, never sent/persisted.
- No chart data sent (dw-3); only `venus` accepted; no clear-conversation control.

## Architecture choices
- `llm.stream_turn(system, messages) -> Iterator[str]` for Anthropic, OpenAI-compat, claude-cli (`stream-json --verbose --include-partial-messages`, Popen); no retry, own 8k cap.
- `app/divination/{render,turn}.py` + `personas/venus.txt`; turn.py copies fitness's executor/deadline shape with a worker → queue; cancel flag on timeout/disconnect.
- SSE grammar fixed: `delta {text}`, `done {mood}`, `error {code: timeout|unavailable}`; client adds `invalid|network|interrupted`; unknown events ignored.
- core: `platform/stream.ts` StreamPost port + pure `platform/sse.ts`; `core/divination` (types, streamTurn, transcript on KV). Web adapter `web-divination/src/platform/stream.ts`, installed in boot.ts.
- Amendments: rule 14 (TWO exceptions; pin renamed `test_main_names_the_synchronous_exceptions`, moved to test_boundaries.py); rule 3 (stream_turn); rule 10 (divination Tier C fence); rule 1 (stream port; core guard bans ReadableStream/TextDecoder/getReader); GENERATE_ON_REQUEST_RE + `stream_turn`.

## Word counts (wc -w)
- Spec without criteria and architecture (header, Goal, Non-goals, Decided defaults): 1,158
- Architecture: 1,420
- Acceptance Criteria: 964

## Status
designing → spec-review
