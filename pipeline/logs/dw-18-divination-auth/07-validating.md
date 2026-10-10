# 07 — validating (2026-09-29, worker, worktree @ 54f76e9)

Setup (all from the worktree, explicit local URLs; confirmed with `ps eww`):
- :8001 `DATABASE_URL=…127.0.0.1:54320/astrace_dev WEB_DATABASE_URL=…127.0.0.1:54320/astrace_web CORS_ALLOW_ORIGINS=http://localhost:5174 ANALYSIS_LLM=claude-cli` (normal shell env). `/api/health` → `{"status":"ok","db":"ok","webDb":"ok","ephemeris":"ok"}`.
- :8004 same but `WEB_DATABASE_URL=` → `"webDb":"unconfigured"`.
- Vite :5174 `VITE_API_BASE=http://localhost:8001`; headless Chrome CDP 9322, profile `scratchpad/dw18-chrome`; driver `scratchpad/dw18-drive.mjs`.
- Test user minted with `accounts/web/service._mint` (script `scratchpad/dw18_mint.py`): `dw18+735a731f@example.com` (id 186e0193-…); profile PUT 204. The dev web db had 7 users before; the test user was deleted at the end (cascade) → 7 again. No real account row touched.

## R1 — PASS
curl, valid bodies, no Authorization:
```
8001 turn     {"detail":"not signed in"} 401
8001 summary  {"detail":"not signed in"} 401
8001 persona  {"detail":"not signed in"} 401
8001 sheets   {"detail":"not signed in"} 401
8004 turn     {"detail":"web accounts unavailable"} 503
8004 summary  {"detail":"web accounts unavailable"} 503
8004 persona  {"detail":"web accounts unavailable"} 503
8004 sheets   {"detail":"web accounts unavailable"} 503
8001 turn Basic: {"detail":"not signed in"} 401
8001 turn unknown bearer: {"detail":"not signed in"} 401
8001 chart (shared, ungated): 200
```
Backend logs: only the uvicorn access lines for those requests (no `app.divination.*` log line); `pgrep -P` on both uvicorn workers → no child process (no claude-cli spawn).

## R2 — PASS
Signed-in app (minted pair in `astrace.auth.*`): Sign out visible 0.5 s; picker's six `.roster__placement` lines loaded (sheets 200); /chat/venus → persona 200 (voice already cached in the dev db); one reply streamed via claude-cli in 10.0 s and saved (venus transcript length 2 in KV; session PUT 204); End session → Sessions → the card became `seal-card--ready` "Will this week be kind to me?" (summary 202 → 200, 4.0 s). Screenshots `scratchpad/dw18-r2-{home,venus,reply,summary}.png` (reply with Venus/Moon pills; sealed card "UNEASY").
Network log: every divination POST carried `Authorization: Bearer 71mePy…` (sheets, persona, turn, summary ×2). The only header-less divination rows are the CORS `OPTIONS` preflights, which CORSMiddleware answers without reaching a route. `/api/chart` (shared) sent none, as specified.

## R3 — PASS
First attempt navigated to /chat/venus AFTER the rows were deleted: the boot `whoami` (dw-12) already signed the browser out — not the path R3 describes, so it was redone: re-minted a pair for the same user, opened /chat/venus signed in (keys present: the three `astrace.auth.*`, birthData, active, sessions, owner), then deleted that user's `web_access_tokens` and `web_refresh_tokens` rows (DELETE 1 / DELETE 1) with the page still open, and sent "Are you still there?":
```
POST /api/divination/turn 401 auth=Bearer HDOGHt…
POST /api/web/auth/token/refresh 401 auth=null
ok (0.5s): sign-in gate returned
chat still mounted: false
chat error shown: false
remaining auth/owned keys: []
```
Screenshot `scratchpad/dw18-r3-gate.png` — "Sign in to meet your planets".

Teardown: Chrome, Vite, both backends stopped; ports 8001/8004/5174/9322 free; user's :8000 (pid 6038) and :5173 (pid 6029) untouched; clusters left running. Residue: the dev main db's content-keyed, identity-free `divination_summary` cache gained one row for the test transcript (no identity; left in place).

Status: validating → docs-sync.
