# 05 validating — dw-6-session-log (worker #3)

Cycle 0 (no trip back to implementing). Worktree HEAD `6c40436`.

## Suites (verbatim summaries)
- Server (`conda run -n astrology pytest -q` in server/): `1074 passed, 50 skipped, 1 warning in 104.03s (0:01:44)`.
- Root `npm test`: app-native `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`; web-divination `Test Files 17 passed (17)` / `Tests 114 passed (114)` (run at step 7; nothing changed since).
- Root `npm run typecheck`: 0 errors.
- S10/W9: `git diff 2f45dfb --stat -- server/app/divination/turn.py server/app/divination/render.py server/app/llm.py web-divination/src/chat web-divination/src/chart web-divination/src/theme packages/core/src/divination/types.ts` → empty.

## Real app
Backend (worktree root): `DATABASE_URL= ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5176 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8003`. The shared `.env` sets a Neon `DATABASE_URL`; it was overridden EMPTY (uvicorn's env-file does not override set vars) — `/api/health` → `{"status":"ok","db":"unconfigured","ephemeris":"ok"}`, so SQLite in the worktree's `server/data/divination.db`. Web: `cd web-divination && VITE_API_BASE=http://localhost:8003 npx vite --port 5176`. Chrome via claude-in-chrome in my own tab (1503514278). Birth entered through the form: 1990-06-15 08:30, China → Beijing (Asia/Shanghai); chart drawn (Sun Gemini, Moon Pisces, Asc Cancer). Request bodies/statuses captured by wrapping `window.fetch` in the page (read_network_requests had not been armed before the page load).

- **A1 — PASS (real app).** Two exchanges ("I keep falling for people who are emotionally unavailable…", "So how do I stop confusing that ache with love?"); End enabled (`endDisabled:false`). After End: chat log = 1 article (greeting), 0 user entries; pending card showed the opening line + "Venus is sealing this session" (screenshot). POST `http://localhost:8003/api/divination/summary`, body keys `["persona","lang","transcript"]`, 4 entries, entry keys `["role","text"]` (no birthData, no id). Statuses `[202,202,200]`; sealed in 5.3 s. Card: question "Why do I keep falling for emotionally unavailable people, and how do I stop mistaking that ache for love?", tone `uneasy`, toneNote present (English).
- **A2 — PASS (real app).** Chat chips under reply 1: `Saturn opposition Ascendant`, `Moon`, `Venus opposition Pluto`; reply 2: `Venus`, `Venus trine Saturn`, `Moon`. Card seals: `["Saturn opposition Ascendant","Moon","Venus opposition Pluto","Venus","Venus trine Saturn"]` = the first-seen union.
- **A3 — PASS (real app).** Reload: chat only greeting; "Sessions · 1"; screen swap unmounted the stage; list name "Why do I keep … love? — 28 Sept 2026"; reader card question identical; every paragraph of all 4 entries present verbatim in the letters; no textarea (screenshot).
- **A4 — PASS (real app), with one procedural note.** First attempt: End at 23:29:53.127Z, uvicorn killed at 23:29:53.18 (POST had answered 202). The page kept polling while the backend was down; the next poll's fetch REJECTED and the card went `failed` — as C5 pins (a rejected fetch → failed). So a pending card only survives a restart if no poll lands during the downtime. Second attempt: End (POST 202 at 23:30:51), page navigated to about:blank (record left `pending` in KV), uvicorn killed 46 ms later, DB rows still 1 (the job died with the process), backend restarted (health up in ~1.5 s), page reloaded → mount-time `resumeSummaries` POSTed → card `ready` in 8.6 s with no user action ("Should I tell my best friend that I have feelings for her?", `tender`). The failed card from attempt 1 was then Retried from the reader (real-app W4): `ready` in 8.0 s.
- **A5 — PASS (real app).** Switched to 中, new session ("我和男朋友异地快两年了…"), End: record `lang:"zh"`, question "异地快两年，越来越觉得疏远，这段感情还值得坚持下去吗？", tone `uneasy` (shown 不安), toneNote Chinese. The three English cards keep English questions; their chrome relabelled (基调: 温柔 / 两难 / 不安, 往来记录, ← 星盘) (screenshot).
- **A6 — PASS (real app).** `sqlite3 server/data/divination.db '.schema divination_summary'` → exactly `summary_key, summary, persona, lang, model, prompt_version, created_at, doctrine`. `select count(*)` → `4` = 4 distinct sealed sessions (the Retry re-used the same content key). All rows `doctrine = 1724c6ffca4cff24` = `summary.FINGERPRINT`, `model = claude-cli/opus`.

Tests only (not driven on the real app): S1–S9 route/store internals, C1–C8 edge cases (cap 50, corrupt KV, MAX_POLLS exhaustion, 45-entry trim), W3 dice row (dw-5 not landed — no dice on real entries), W6 narrow layout, W8 reduced motion.

Shutdown: tab 1503514278 closed; `pkill` of my uvicorn (8003) and vite (5176); `lsof -i :8003 -i :5176` shows no listener (only a Chrome CLOSE_WAIT client socket).

Transition: validating → docs-sync.
