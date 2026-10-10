# 10 — accepting U1 (first check of the user's run, 2026-09-29)
Source: :8001 backend log (scratchpad/u1-backend.log, 38 lines) + astrace_web / astrace_dev queries. User reported PASS, answered YES to import.

Ordered :8001 requests:
  GET whoami 401 → POST token/refresh 401 (stale dw-12 pair, spec D14) → POST /api/web/auth/google 200 → GET profile 200 → PUT profile 204 → PUT sessions ×4 204 (s-1790728491263 venus open 22 entries, …264 mars open 4, …265 jupiter open 1, s-1790708752743 moon sealed 10) → GET profile 200 → GET sessions 200 → POST divination/sheets 200 → [browser B] POST /api/web/auth/google 200 → GET profile 200 → GET sessions 200 → POST divination/sheets 200. No other request.

Per step:
- Step 1 (sign in A, import): EVIDENCED — google 200; import = profile PUT + 4 session PUTs; astrace_web has exactly ONE non-test web_users row (created 20:34:51).
- Step 2 (send one message, reply saved): NOT EVIDENCED — no /api/divination/turn on :8001 and no session PUT after the import; all 4 web_sessions rows were last updated 20:34:55 (the import second). The 4 rows are the imported chats only; no new chat reached the web db.
- Step 3 (same account in browser B sees data): EVIDENCED at the server — second google 200, profile + sessions GET 200, still one users row (visual presence reported by the user).
- Step 4 (sign out in B): NOT EVIDENCED — no POST /api/web/auth/logout in the log; the account still holds 2 access + 2 refresh token rows (both browsers' pairs live).
- web_birth_profiles: 1 row. Tokens: sha256 only (not re-dumped here; covered by A2).
- astrace_dev: users/sessions/refresh_tokens now 2/2/2 (was 1/1/1). New rows at 20:26:49, 20:31:09, 20:35:03 — the user's earlier attempt on the old :5173/:8000 site (pre-dw-16 main-db Google route); :8001 logged no /api/auth/* request. Not caused by dw-16.

Verdict: U1 INCOMPLETE (steps 2 and 4 unevidenced). Not finalized; asked the user for those two steps only.

## Second check (after the user's steps 2′–4′), 74-line log
- 2′ EVIDENCED: two `POST /api/divination/turn` 200 (lines 51, 58), each followed by `PUT /api/web/sessions/s-1790728491265` 204 (54; 59–60). The jupiter row went 1 → 4 entries (user/persona/user/persona), updated 20:38:37.
- 3′ EVIDENCED: after the last PUT (line 60), another connection ran `GET /api/web/auth/whoami` 200, `GET /api/web/profile` 200, `GET /api/web/sessions` 200 (63–65).
- 4′ EVIDENCED: `POST /api/web/auth/logout` 204 (69), then a manual re-sign-in `POST /api/web/auth/google` 200 (70; GIS auto_select false, no prompt()). Token rows now: the pair minted 20:35:14 (second browser's sign-in) and the pair minted 20:40:16 (re-sign-in); the pair minted 20:34:51 (first sign-in) is GONE and no `/token/refresh` ran after line 9 — so the logout deleted exactly the signed-out browser's access + refresh rows. (By timing the browser that signed out held the FIRST pair, i.e. it was browser A rather than B; immaterial to the criterion.) The re-sign-in pulled (GET profile/sessions) with NO PUT and no import prompt, consistent with the local copy having been wiped at sign-out (an owned surviving cache would flush; unowned data would prompt and PUT).
- Still exactly one non-test web_users row; web_birth_profiles 1.
Verdict: U1 PASS.
