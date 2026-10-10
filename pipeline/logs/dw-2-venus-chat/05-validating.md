# 05 — validating, pass 1 (dw-2-venus-chat)

Date: 2026-09-28. Branch feature/dw-2-venus-chat @ 72ee0ee.

## Suites (on 72ee0ee — the last code commit)
- `npm run server:test` → `1009 passed, 50 skipped, 1 warning in 100.87s (0:01:40)`
- root `npm test` → app-native jest `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`; web-divination vitest `Test Files 13 passed (13)` / `Tests 57 passed (57)`
- root `npm run typecheck` → both workspaces `tsc --noEmit` clean
- `npm run build --workspace web-divination` → `✓ built in 129ms` (the >500 kB chunk warning pre-dates dw-2)

## Real app
Backend: `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5173 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001` (:8000 left to the astrology2 checkout, pid 34607). Web: `VITE_API_BASE=http://localhost:8001 npm run web` on :5173. Driven with the claude-in-chrome extension (connected), viewport 1700 CSS px. The browser profile already had birth data (unknown-time chart), so the wheel was drawn.

- **A1 — PASS.** `.chat` is inside `[data-slot="side"]`, left edge 1026.5 px ≥ stage right edge 928.5 px (beside the wheel, below the placements). Greeting shown ("Sit with me a while. I keep the evening sky…"). Eyebrow computed colour `rgb(217, 150, 124)` equals a probe element coloured with the `--venus` token (`equal: true`; #d9967c).
- **A2 — FAIL (paragraph count).** Asked "How do I know if a friendship is worth saving?" through the real textarea + Enter. A 200 ms DOM sampler recorded: `listening` at t=864 ms, then streaming text lengths 139 (4070 ms) → 348 (5070) → 577 (6069) → 833 (7069) → 880 (8071), then done with the mood tag at 13071 ms. So text grows across 5 samples ≥200 ms apart, the listening state was shown, a mood tag appeared ("candid"), there is no markdown (`#`, `*`, `- ` absent), 163 words. BUT the reply has **4 paragraphs** (the last is a lone closing question, "So tell me, what happened between you?"), and the spec says 1–3. The voice is also generic second-person advice with little of Venus in it: first person appears only as "tell me".
- **A3 — PASS.** A page-level fetch wrapper saw exactly one `POST http://localhost:8001/api/divination/turn`, with status 200 and content-type `text/event-stream`. Body keys: `persona, transcript, message, lang`; transcript entries carry only `role, text`; no birth fields (regex for birth|latitude|longitude|timezone|"date"|"time" → false). `performance.getEntriesByType('resource')` lists that one divination URL only. NOTE: the extension's `read_network_requests` listed the turn with `statusCode: 503`. That contradicts the uvicorn access log (`"POST /api/divination/turn HTTP/1.1" 200 OK` for both turns) and the page's `Response.status` (200). I read it as a tool artifact on a long streaming response and recorded it rather than smoothing it over.
- **A4 — PASS.** After a reload, the log shows the greeting, then the user line, then the reply with the mood "candid", in order.
- **A5 — PASS for language, same paragraph problem.** After clicking 中, the UI labels were Chinese (title 金星, placeholder 向金星提问…, send 发送, hint "Enter 发送 · Shift+Enter 换行", mood 坦率). "我总是在感情里付出更多，这正常吗？" got a reply in Chinese (16 s end to end), mood 坦率, but again in 4 paragraphs with a lone closing question. (The first attempt typed into nothing because the input had scrolled; I re-clicked. Not an app issue.)
- **A6 — PASS.** Asked "Tell me what makes someone easy to love.", waited for the caret with 60+ chars, then clicked Stop. The partial text stayed with "— stopped"; KV holds `{role:"persona", stopped:true, text:"People who are easy to love … They tell you what they want"}`; the button went back to Send. After a reload it is still there with the note. Server side: 3 s later no `claude -p --output-format stream-json` process remained (the cancel path killed the CLI).
- **A7 — not yet run** (it needs a backend restart; folded into the fix re-run).

## Verdict
Fail on A2 (and the A5 reply shape). Back to implementing — cycle 1.
Diagnosis: under claude-cli the persona text goes in as the stdin prompt. It runs underneath Claude Code's own default system prompt, in the repo's cwd (so the repo CLAUDE.md is in context too). The persona is then only an instruction among others, and the "1–3 paragraphs" rule is soft; the model adds a closing question as its own paragraph.
