# 09 accepting — fresh-context acceptance check

Branch `feature/dw-2-venus-chat` @ 5e72f50. Checker saw only the criteria, the
repo, and the run instructions. Suite totals: `npm run server:test` → 1009
passed, 50 skipped, EXIT 0; `npm test` → app-native 90 suites / 1069 tests
passed + web-divination 13 files / 57 tests passed, EXIT 0; `npm run typecheck`
→ EXIT 0. Real app: backend `:8001` (`ANALYSIS_LLM=claude-cli`, CORS for
:5173), `VITE_API_BASE=http://localhost:8001 npm run web` on :5173, driven in
Chrome. Birth record already in the browser (1990-06-15, Beijing).

| ID | Verdict | Where checked | Evidence |
|----|---------|---------------|----------|
| S1 | PASS | TESTS | `test_s1_deltas_then_done_in_order`: fake `stream_turn` ["Hel","lo, ","dear."] + side `{mood:"tender"}` → 200, `text/event-stream`, events exactly delta×3 then `done {"mood":"tender"}`. Passing. |
| S2 | PASS | TESTS | `test_s2_system_prompt_and_messages`: `VENUS in system`, `lang.zh` fragment in, `lang.en` not; messages `[user, assistant(persona), user(new)]`. Passing. |
| S3 | PASS | TESTS | `test_s3_side_read_failure_gives_null_mood` parametrised over `AnalysisUnavailable`, `{mood:"furious"}`, `{tone:…}` → `done {"mood":null}`, deltas unchanged. |
| S4 | PASS | TESTS | `test_s4_timeout_mid_stream`: `DIVINATION_TURN_TIMEOUT_S=0.5`, fake sleeps 3 s after one chunk → `[delta, error{timeout}]`, no done, `elapsed < 3`. |
| S5 | PASS | TESTS | `test_s5_provider_failure_mid_stream` → `[delta, error{unavailable}]`. |
| S6 | PASS | TESTS | `test_s6_no_provider_is_a_json_503`: no key, no `ANALYSIS_LLM` → 503 `{"detail":"divination unavailable"}`, `called == []`. |
| S7 | PASS | TESTS | `test_s7_validation_is_422_and_never_calls_the_provider`: persona mars, lang fr, "", whitespace, 2001 chars, 41 entries, role system (+2 extra) → 422, fake never called. |
| S8 | PASS | TESTS | `tests/test_llm_stream.py`: anthropic `text_stream` chunks + transport error; openai `delta.content` skipping None + transport/mid-stream errors; CLI fake `Popen` with recorded stream-json → exact chunks, argv `--output-format stream-json`, non-zero exit raises, `is_error` raises, absent binary raises. All pass (68 passed in the focused run). |
| S9 | PASS | TESTS + planted | Fence self-checks bite on `from app.interpretation import x` / `from .. import jobs`; `test_no_tier_imports_divination`; `GENERATE_ON_REQUEST_RE` asserts `llm.stream_turn(`; `test_main_names_the_synchronous_exceptions` present. Planted `from app.cards import store` in `divination/render.py` → `FAILED test_divination_imports_only_llm_prompts_chart_dictionary` (1 failed, 20 passed); reverted, green. |
| S10 | PASS | TESTS | `test_fingerprint_moves_with_the_persona` (modified venus.txt copy in fresh `PromptRegistry` → fingerprint differs); `test_topic_is_registered` (`topics()["divination"] is render.PROMPTS`). |
| S11 | PASS | CODE grep + TESTS | `grep -rli "create table|insert into|update … set" server/app/divination/` → no hits; non-test importers of divination: only `server/app/main.py:29`. `test_divination_keeps_no_state` green. |
| C1 | PASS | TESTS | `web-divination/src/platform/sse.test.ts`: S1 body one char at a time, every split point, `\r\n` (incl. split pair), `:` comments → same 4 events. |
| C2 | PASS | TESTS | `chat/core-divination.test.ts` streamTurn: 200 → TurnEvents; 422→invalid, 503→unavailable, throw→network; deltas w/o done → interrupted; `dice` ignored; aborted signal → no further events. |
| C3 | PASS | TESTS | transcript store: KV round-trip; corrupt value → `[]`; `toWire` of 45 → last 40, keys exactly `role,text`. |
| C4 | PASS | TESTS + planted | architecture.test.ts green; self-checks cover `ReadableStream`, `TextDecoder`, `getReader(`. Planted `new TextDecoder()` in `packages/core/src/divination/types.ts` → "core names no Web stream API…" red, naming `packages/core/src/divination/types.ts`; reverted. |
| C5 | PASS | TESTS + planted | Barrels, colour, i18n parity (full leaf-path en↔zh parity includes `chat`, plus a chat-namespace test) all green in `npm test`. Planted `fetch('/x')` in `web-divination/src/chat/useChat.ts` → G3 red naming the file; reverted. Root `npm test` + `npm run typecheck` EXIT 0. |
| W1 | PASS | TESTS | ChatPanel.test.tsx W1 (+ zh variant: mood `坦率`): user line + "Venus is listening", reply grows between deltas ("Perhaps" → "Perhaps not tonight."), mood `candid`, KV holds both entries. |
| W2 | PASS | TESTS | W2: button "Stop", click aborts fake signal, partial kept with "— stopped", stored `stopped: true`. |
| W3 | PASS | TESTS | W3: `error{timeout}` → "Venus took too long to answer." + Retry; retry resends same message with prior transcript; success replaces error. |
| W4 | PASS | TESTS | App.test.tsx W4: seeded transcript renders in order after greeting; seed ending in user entry shows Retry. |
| W5 | PASS | TESTS | W5: Shift+Enter → `"line one\nline two"`, no call; whitespace → Send disabled, no call. |
| A1 | PASS | REAL APP | `.chat` inside `[data-slot="side"]` (x=1026, beside stage slot x=288–928); greeting "Sit with me a while…"; `.chat__eyebrow` computed colour `rgb(217, 150, 124)` = token `venus: '#d9967c'`. |
| A2 | PASS | REAL APP | Sent via real keyboard. Samples ~1 s apart: listening=true ×3, then reply length 283 → 612 → 867 → 928 (4 growing samples) while `aria-busy=true`, then done with mood tag "candid". Reply 3 `<p>` paragraphs, first person ("I've watched this for a very long time"), no `#`, `*`, or `- `. |
| A3 | PASS | REAL APP | Per turn one `POST /api/divination/turn` (fetch wrapper: 1 request, 0 other divination requests; body keys `persona, transcript, message, lang`, no birth-like data). Resource Timing: `responseStatus 200`, `contentType text/event-stream`; response header `text/event-stream; charset=utf-8`. Backend log shows one POST per turn (+ a single CORS preflight OPTIONS on the first cross-origin call). Note: the Chrome extension's network reader listed this request as statusCode 503, contradicted by the server log (200), Resource Timing (200), and the streamed reply; treated as a tool artefact. |
| A4 | PASS | REAL APP | After reload: 3 entries — greeting, "You: How do I know if a friendship is worth saving?", reply ending "…between you two?" + "candid". |
| A5 | PASS | REAL APP | Toggled 中: title 金星, subtitle 爱情、友谊，以及你的价值, placeholder 向金星提问…, button 发送, hint "Enter 发送 · Shift+Enter 换行", mood 坦率. Chinese question → reply 312/354 CJK chars ("想联系就联系吧。渐渐疏远的友谊…"), request `lang: "zh"`. |
| A6 | PASS | REAL APP | Clicked Stop mid-stream: partial ends mid-sentence (`…"Do`) + "— stopped"; KV last entry `{role:persona, stopped:true}`; after reload still shows `…"Do` + "— stopped". |
| A7 | PASS | REAL APP | Killed the :8001 backend and sent "Is it too late to apologise?" → "The sky is out of reach — check the connection." + Retry. Restarted the backend, clicked Retry → streamed reply ("…What are you sorry for, and how long has it been?") with mood "candid", error gone. |

Housekeeping: all planted edits reverted (`git status --short` clean before
this log was written); servers on :8001 and :5173 stopped, :8000 (the other
checkout) untouched; browser tab closed. To start from a clean chat, the
checker removed a pre-existing `astrology.divination.transcript.v1.venus` KV
value from this Chrome profile, left over from earlier sessions. The language
setting was restored to `zh`.

ACCEPTANCE: PASS
