# 10 validating — dw-6-session-log (cycle 1, after the A4 fix `5094be7`)

Backend: `DATABASE_URL= ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5176 conda run … uvicorn app.main:app --app-dir server --env-file <scratch copy of .env WITHOUT the DATABASE_URL line, outside the repo> --port 8003`. `/api/health` → `{"status":"ok","db":"unconfigured","ephemeris":"ok"}` at first start AND after the restart. Vite: `VITE_API_BASE=http://localhost:8003 npx vite --port 5176`. Own Chrome tab 1503514366. The scratch env copy was deleted afterwards.

Suites: see 09-implementing.md (server 1129 passed / 50 skipped; app-native 1069 passed; web 163 passed; typecheck 0).

- **A1 — PASS (real app).** Two exchanges ("My partner forgets every date that matters to me…", "How do I tell him without starting a fight?"); End enabled; after End the chat shows only the greeting; POST body keys `["persona","lang","transcript"]`, 4 entries; statuses `[202, 200]`; ready in 6 s — "Does my partner forgetting the dates that matter to me mean he doesn't care, and how do I tell him without a fight?", tone `uneasy`, toneNote English.
- **A4 — PASS (real app), real restart sequence.** One exchange ("Why do I feel jealous when my sister gets engaged?"). End at 00:22:55.48Z → POST 202. uvicorn killed at 00:22:56.67Z (~1.2 s after End). The next poll at 00:23:00.61Z was REJECTED (connection refused); record became `{"status":"failed","cause":"network"}` (checked 00:23:11Z). Backend restarted, healthy at 00:23:19Z (db unconfigured; row count unchanged — the in-memory job died). Page reloaded: with no user action the record went `pending` → `ready` in 6.1 s (server log: 202 then 200) — "Why do I feel jealous that my sister is getting engaged?", tone `uneasy`; first in the Sessions list.
- SQLite `divination_summary` count 7 (all sessions sealed in this worktree across validation, smoke and this run).

Shutdown: tab closed; my uvicorn (8003) and vite (5176) killed; `lsof -i :8003 -i :5176 -sTCP:LISTEN` → none.

Earlier runs and Neon: 05-validating and the 07-merge smoke ran with `DATABASE_URL=` set empty in the environment plus `--env-file .env`. uvicorn loads the env file with python-dotenv without override, so the empty value stood; `/api/health` reported `"db":"unconfigured"` at each first start, and every sealed summary appeared in the worktree's SQLite (`count(*)` 4 → 5 → 7, matching sessions sealed). No run pointed at Neon. The restarts inside 05 used the identical command (health not re-queried there, but those sessions' rows also landed in SQLite).

Transition: validating → docs-sync done (docs updated in the fix commit) → back to the coordinator for accepting.
