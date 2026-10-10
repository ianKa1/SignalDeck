# 04 — implementing (dw-2-venus-chat)

Date: 2026-09-28. Branch: feature/dw-2-venus-chat (primary checkout). Worker run.
Skills: git-commit per step (autonomous overrides); frontend-design before steps 6–7.

## Step 1 — `llm.stream_turn` for all providers
- Files: `server/app/llm.py` (`_TURN_MAX_TOKENS`, `Provider.stream` concrete default, `AnthropicProvider.stream`, `OpenAICompatProvider.stream`, `LocalClaudeProvider.stream` via `Popen` + `_flatten_turn`/`_drain_into`/`_stop_process`, `stream_turn`), `server/tests/test_llm_stream.py` (new, 16 tests), `CLAUDE.md` rule 3.
- Recorded a real `claude -p --output-format stream-json --verbose --include-partial-messages --model haiku` run first; the fake NDJSON in the test mirrors its shape (system init, thinking deltas, per-block `assistant` snapshots, `text_delta` stream events, final `result`).
- Note: `Provider.stream` is concrete (raises AnalysisUnavailable), not abstract, so existing `_FakeProvider(Provider)` fakes in the suite stay valid.
- Check: `pytest tests/test_llm_stream.py tests/test_llm_backup_mode.py tests/test_llm_providers.py tests/test_boundaries.py -q` → `80 passed, 1 warning in 2.06s`.

## Step 2 — `app/divination` prompts + Tier C fences
- Files: `server/app/divination/{__init__.py,render.py,personas/venus.txt}`, `server/tests/test_divination_render.py` (new, 8 tests), `server/tests/test_boundaries.py` (`test_divination_imports_only_llm_prompts_chart_dictionary`, `test_no_tier_imports_divination`, `test_divination_keeps_no_state`, each with self-checks), `CLAUDE.md` rule 10.
- `render.py` registers topic `divination`: `persona.venus` (asset), `lang.en`, `lang.zh`, `side.role`; `FINGERPRINT`, `MOODS`, `MOOD_SCHEMA`, `system_prompt`, `turn_messages` (D2 merge/drop), `side_prompt`.
- The `main.py`-is-an-importer positive assertion is deferred to step 3 (main does not import divination yet).
- Check: `pytest tests/test_divination_render.py tests/test_boundaries.py tests/test_prompts.py -q` → `49 passed in 0.51s`.
- Plant: appended `from app.cards import store` to render.py → `AssertionError: assert ['divination/render.py'] == []`, `1 failed, 2 passed`; reverted.

## Step 3 — `turn.py`, wire models, route, rule-14 pin
- Files: `server/app/divination/turn.py` (new), `server/app/models.py` (`DivinationTranscriptEntry`, `DivinationTurnRequest`), `server/app/main.py` (route `divination_turn_stream` → `StreamingResponse(divination_turn.turn_events(...))`, lifespan `divination_turn.shutdown()`, `ask_fitness` docstring now cites the new pin), `server/tests/test_divination_turn.py` (new), `server/tests/test_boundaries.py` (`GENERATE_ON_REQUEST_RE` + `stream_turn`, `test_main_names_the_synchronous_exceptions`, main.py positive importer assertion), `server/tests/test_ask_fitness.py` (old pin removed), `CLAUDE.md` rule 14 ONE→TWO.
- Implementation decisions (for journaling):
  - **D5 keepalive comments.** `turn_events` waits in 0.25 s slices and emits `: keepalive\n\n` after each idle second. Reason: Starlette iterates a sync generator via `iterate_in_threadpool`; a generator blocked inside `next()` cannot be closed on disconnect, so without a periodic yield a disconnected turn would hold a thread (and the CLI process) until the deadline. SSE comments are legal and the core parser ignores them (C1).
  - **D6 empty reply → `error{unavailable}`.** A provider stream that ends with no text at all gets `error {unavailable}`, not `done`; the spec's delta cardinality is 0..n but an empty reply is not a reply.
  - **D7 restartable executor.** `turn._pool()` creates the executor lazily and again after `shutdown()`. First full-suite run failed 11 tests with scheduling onto a dead pool: another suite's `with TestClient(app)` ran the lifespan shutdown. Pinned by `test_executor_survives_an_app_restart`.
  - Route function is named `divination_turn_stream` (module import alias is `divination_turn`, as in the spec's snippet).
- Check: `pytest tests/test_divination_turn.py tests/test_boundaries.py tests/test_ask_fitness.py -q` → `62 passed`; first `npm run server:test` → `11 failed, 997 passed` (dead executor, fixed above); rerun → `1009 passed, 50 skipped, 1 warning in 100.59s`.

## Step 4 — core stream port + SSE parser + guard
- Files: `packages/core/src/platform/{stream.ts,sse.ts}` (new), `platform/index.ts` (exports), `app-native/src/architecture.test.ts` (`CORE_STREAM_RE` guard over ALL core .ts files incl. tests, no allowlist, + self-checks; `divination` added to `BARREL_DEEP_IMPORT_RE`), `web-divination/src/platform/sse.test.ts` (new, D1), `CLAUDE.md` rule 1.
- `sse.test.ts` also asserts `configureStreamPost`/`getStreamPost` so the new barrel exports have a consumer (the public-API guard lives in the same jest file).
- Check: `npx jest src/architecture.test.ts` → `Tests: 38 passed, 38 total`; `npx vitest run src/platform/sse.test.ts` → `Tests 8 passed (8)`.
- Plant (C4): appended `export const __plant = new TextDecoder()` to `packages/core/src/platform/poll.ts` → `✕ core names no Web stream API …` with `+ "packages/core/src/platform/poll.ts"`; reverted via `git checkout`.

## Step 5 — core `divination` domain
- Files: `packages/core/src/divination/{types.ts,turn.ts,transcript.ts,index.ts}` (new), `packages/core/package.json` (`"./divination"`), `web-divination/src/chat/core-divination.test.ts` (new, D1, 11 tests).
- Barrel carries the temporary `// @public-intent domain: dw-2 chat panel mounts in step 7` (D3).
- Choices: a transport throw BEFORE the response → `network`; a throw mid-stream (not aborted) → `interrupted` (the same as a stream that ends without done/error). Corrupt KV → `[]`; malformed individual entries are dropped, valid ones kept. `toWire` also clips each text to 8,000 chars (the server's cap) so an oversize stored entry cannot 422 every later turn.
- Check: `npx vitest run src/chat/core-divination.test.ts` → `Tests 11 passed (11)`; root `npm run typecheck` → both workspaces clean; `npx jest src/architecture.test.ts` → all passed.
- Correction: the step-5 commit (e34d155) landed with the public-API guard RED (`divination/MOODS`, `divination/TURN_PATH` had no consumer) — I ran the guard after committing. Fix commit: `TURN_PATH` made module-private, `MOODS`/`isMood` asserted in `core-divination.test.ts`. After: `npx jest src/architecture.test.ts` → `38 passed`; vitest file → `12 passed`; typecheck clean.

## Step 6 — web adapter, boot wiring, tokens, i18n
- Skill `frontend-design` loaded before this step.
- Files: `web-divination/src/platform/{stream.ts (new), stream.test.ts (new), boot.ts, boot.test.ts}`, `src/theme/tokens.ts` (`venus` #d9967c rose-copper, `venusGhost` rgba glow), `src/i18n/{en.ts,zh.ts}` (`chat` namespace: title, eyebrow, subtitle, greeting, placeholder, hint, send, stop, retry, listening, stopped, you, logLabel, errors×5, moods×5), `src/i18n.test.ts` (compile-time `Record<TurnErrorCode|Mood,string>` binding + runtime check).
- `webStreamPost` is the only `getReader()`/`TextDecoder` site; it cancels the reader when the consumer stops early.
- Check: `npx vitest run` → `Test Files 12 passed (12)`, `Tests 49 passed (49)` (first run failed on an apostrophe in a test title, fixed); root typecheck clean; `npx jest src/architecture.test.ts src/color-guard.test.ts` → `41 passed`.

## Step 7 — chat panel
- Files: `web-divination/src/chat/{useChat.ts,ChatPanel.tsx,chat.css,ChatPanel.test.tsx}` (new), `src/app/{App.tsx,App.test.tsx}` (panel mounted in the `<aside>` at the dw-2 comment; W4), `packages/core/src/divination/index.ts` (temporary `@public-intent domain` marker removed, D3 closed).
- Design: an almanac plate like the birth card, voice in rose-copper — ♀ sigil ring with a soft glow, replies as letter prose (`--font-body` 1.02rem/1.6, indented second paragraphs, no bubble) under a small-caps "♀ Venus" eyebrow in `var(--venus)`, user lines right-aligned italic `--text-dim` on a `line-soft` hairline, twinkling ✦✦✦ "listening", blinking ♀ caret, mood as a small-caps tag. Reduced motion: stars and caret static.
- Behaviour notes: Enter sends unless Shift is held or an IME composition is active (pinyin confirms with Enter); textarea `maxLength` 2,000; log pinned to bottom unless scrolled >48 px up; `aria-busy` while in flight; an unanswered trailing user entry (error, stop-before-text, or reload) shows the translated error line + Retry (after a reload the line reads "The reply was cut off.", as the original code is not stored).
- Check: `npx vitest run` → `Test Files 13 passed (13)`, `Tests 57 passed (57)`; root `npm test` → jest `Tests: 1069 passed` + vitest `57 passed`; root `npm run typecheck` clean; `npm run server:test` → `1009 passed, 50 skipped`.
- Plant (C5/G3): appended `fetch('/x')` to `src/chat/useChat.ts` → `✕ web-divination names no network API outside src/platform (G3)` naming `web-divination/src/chat/useChat.ts`; reverted.
