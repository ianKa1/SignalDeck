# 07 — validating, pass 2 (after cycle 1) — dw-2-venus-chat

Date: 2026-09-28. Branch feature/dw-2-venus-chat @ 9692533. Cycles used: 1 (see 05-validating.md → 06-implementing.md).

## Suites (on 9692533, the final code)
- `npm run server:test` → `1009 passed, 50 skipped, 1 warning in 100.50s (0:01:40)`
- root `npm test` → app-native jest `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`; web-divination vitest `Test Files 13 passed (13)` / `Tests 57 passed (57)`
- root `npm run typecheck` → 0 errors (both workspaces)
- web build (pass 1, no web change since) → built.

## Real app (same setup as pass 1: backend :8001 with claude-cli + CORS :5173, Vite :5173 with VITE_API_BASE=http://localhost:8001, claude-in-chrome)
- **A7 — PASS.** Killed the :8001 backend (lsof confirmed it was free) and sent "Why do I miss people who were bad for me?". The UI showed "The sky is out of reach — check the connection." with a Retry button; KV's last entry was the user message. Restarted the backend (bd45301 code), installed the 200 ms sampler, and clicked Retry. Samples: failure line (275 ms) → listening (3275) → caret with text length 13 (5275) → 263 → 503 → 711 → 886 (9275) → done with the mood (12275). Reply: 3 paragraphs, 166 words, no markdown, mood "candid", with a Venus touch ("I have watched lovers mourn a lamp they mistook for the evening star").
- **A2 — PASS (re-run on the fixed code, with the exact criterion question).** "How do I know if a friendship is worth saving?" → listening at 11.9 s (CLI start-up), then text lengths 139 → 348 → 609 → 861 → 881 across 5 samples about 1 s apart, then the mood tag at 22.9 s. 3 paragraphs, 169 words, `hasMarkdown: false`, first person ("I have watched a great many people keep something alive alone, like a rose in a vase…"), mood "candid".
- **A5 — PASS (re-run after the zh fix, 9692533).** UI in 中 (placeholder 向金星提问…, send 发送, eyebrow ♀金星). "为什么我总是喜欢上不喜欢我的人？" → a Chinese reply in 3 paragraphs in 14.4 s, mood 坦率; it also draws on the earlier turn ("你之前也跟我说过…"), which shows the transcript reaching the model. The intermediate run on bd45301 (before the zh line) gave 4 paragraphs; that is what triggered the zh fix, recorded in 06-implementing.md.
- A1, A3, A4, A6 passed in pass 1 (05-validating.md). The fixes touched only the server's CLI transport and prompt text, not the web client, the wire or storage, so those did not need a re-run. A4 and A6 persistence was also seen again in pass 2: every reload showed the full ordered transcript, including the stopped entry.

## Exercised on the real app vs covered by tests only
- Real app: A1, A2, A3, A4, A5, A6, A7 (all seven).
- Tests only: S1–S11 (pytest, fake providers), C1–C5 (jest guards + vitest through the core barrels), W1–W5 (vitest, fake StreamPost). Two of the test-only behaviours also showed up on the real app along the way: the disconnect/stop cancellation (no `claude … stream-json` process left 3 s after Stop) and the keepalive-tolerant SSE parsing (the CLI start-up gap of about 11 s passed without a stream error).
- Not exercised anywhere against a real paid provider: the Anthropic and OpenAI-compat `stream` branches are covered only by fake-client unit tests (S8). By design, no paid key is used.

## Observations for the record
- The claude-in-chrome `read_network_requests` tool reported `statusCode: 503` for a turn that the server logged as 200 and the page received as 200 `text/event-stream`. Treated as a tool artifact.
- The profile's `.env` has a DATABASE_URL (`/api/health` → `"db":"ok"`). Irrelevant to dw-2: divination touches no db (S11 pin).

## Servers stopped
Backend :8001 (3 launches), Vite :5173, and the Chrome tab closed. `lsof` shows 8001 and 5173 free, 8000 still pid 34607 (the other checkout). No leftover uvicorn/vite/claude-stream processes.

## Transition
validating → docs-sync.
