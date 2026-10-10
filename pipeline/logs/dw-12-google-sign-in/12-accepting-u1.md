# 12 accepting — U1 evidence (user reported "The login succeeded.", no per-step breakdown)

Backend :8010 log (scratchpad/u1/backend.log), requests in order (uniq -c):
  1 GET /api/health 200            (my probe)
  1 POST /api/auth/google 401      (my junk-credential probe, before the user)
  1 POST /api/auth/google 200      ← the user's live Google sign-in
  1 POST /api/chart 200
  1 POST /api/divination/sheets 200
  5×202 + 1×200 POST /api/divination/persona, then 4×202 + 1×200 (two character cards generated)
NOT present: GET /api/auth/whoami (any status), POST /api/auth/token/refresh, POST /api/divination/turn, POST /api/auth/logout.

Throwaway db 127.0.0.1:54330/astrace_u1:
- users: 1 row; columns exactly id, email, created_at (no sub column).
- sessions: 1 row, token_hash 64-hex. refresh_tokens: 1 row, token_hash 64-hex (columns token_hash, user_id, created_at, expires_at).
- row_to_json dump of users+sessions+refresh_tokens: 0 matches for "sub"/JWT prefix eyJ/Google access-token prefix ya29.

Per-step verdict:
- Step 1 (gate only on a fresh profile): not directly observable server-side; consistent (no app request precedes the google 200). PASS by consistency.
- Step 2 (Google popup → POST /api/auth/google 200): PASS.
- Step 3 (app opens, chart): PASS (chart 200, sheets 200 after sign-in).
- Step 4 (a character reply streams): NOT EXERCISED — no /api/divination/turn request. Characters were opened (two persona cards generated) but no message was sent.
- Step 5 (reload keeps the session): NOT EXERCISED — a reload of a signed-in app calls GET /api/auth/whoami; none in the log.
- Step 6 (sign-out returns to the gate, refresh revoked): NOT EXERCISED — no POST /api/auth/logout; the session and refresh rows are still present (logout deletes them).
- S6 on live Google data: PASS (one user row, hashes only, no sub or raw token).

U1: INCOMPLETE — steps 4, 5, 6 need the user. Servers and cluster left running.

## Update (after the user's further steps; log re-read)
Requests since sign-in (port-grouped): google 200 → chart 200 → divination/turn 200 ×3 (ports 61831, 61890, 61922) → summary 202 → 200 → logout 204 (63433) → google 200 (63433, a second sign-in).
Timing: the summary job ran at 15:05:52 (log line 35) and the logout came after it (line 39). The first sign-in predates the 15:01:48 voice job.
DB now: users 1 row (unchanged — the re-sign-in reused it by email). sessions: 1 row, created 15:06:13. refresh_tokens: 1 row, created 15:06:13. Both are 64-hex and both postdate the logout, so the first sign-in's session and refresh rows were DELETED by logout, and the second sign-in minted new ones. Dump: 0 sub/JWT/ya29 matches.
- Step 4: PASS (3 streamed turns 200).
- Step 6: PASS (logout 204; the first pair's rows are gone, so its refresh token can no longer refresh). The UI's return to the gate is not directly observable server-side; the immediate new google 200 on the same connection is consistent with the gate showing the button again.
- Step 5 (reload → whoami): still NOT EXERCISED — no GET /api/auth/whoami in the log. Waiting on the user.

## Update — reload
After the second sign-in: GET /api/auth/whoami 200 (a preflight OPTIONS precedes it), then POST /api/chart 200, sheets 200 and persona 200. No /api/auth/token/refresh was needed, because the access token was fresh. DB: users 1, sessions 1, refresh_tokens 1 (unchanged; the reload minted nothing).
- Step 5: PASS — the reload stayed signed in and the app reopened with the saved birth data.

U1 VERDICT: PASS (steps 1–6; step 1 by consistency, since the server can't observe it). Combined with 10-accepting.md (all but U1 PASS): ACCEPTANCE: PASS.
