# 21 · live verification (coordinator) — evidence from the :8017 log and rfs_live

Source: <scratchpad>/live-prep/backend-8017.log (34 lines, emails masked when viewed) and psql/pg_dump on 127.0.0.1:54317/rfs_live (counts and booleans only).

Context: the user ran the live steps on a physical iPhone 15 Pro with a standalone Release build of the DEV variant (com.astrace.app.dev, base http://192.168.1.13:8017, built by the coordinator's parent from this worktree). Phone requests come from 192.168.1.6; simulator requests would come from 127.0.0.1.

Auth/profile request sequence (client IP, request, status):
- 127.0.0.1 POST /api/auth/google 401, POST /api/auth/apple 422/401 — live-prep junk-token probes, not sign-ins.
- 192.168.1.6 POST /api/auth/apple 200 → GET /api/profiles 200 → PUT /api/profiles/Kai 204 (first-run birth data saved) → chart 200 etc.
- 192.168.1.6 POST /api/auth/logout 204
- 192.168.1.6 POST /api/auth/google 200 → GET /api/profiles 200 → GET /api/auth/whoami 200 → GET /api/profiles 200
- 192.168.1.6 POST /api/auth/logout 204
- NO request from 127.0.0.1 after the probes (the PROD simulator app never reached :8017); NO `DELETE /api/auth/account`; NO `/api/auth/token/refresh`.

DB: users 2 (one Apple-linked created 21:28:08, one Google created 21:28:35 — two different accounts); apple_identities 1, 64-hex hash 1; profiles 1, owned by the Apple-linked user; sessions 0, refresh_tokens 0 (both signed out). pg_dump: 0 Apple-subject-shaped strings, 0 JWT-shaped strings.

Per criterion:
- L1 (dev Google): PASS — dev build ⇒ GOOGLE entry 2 (bundle com.astrace.app.dev); POST /api/auth/google 200 from the phone, new users row.
- L2 (dev Apple, device): PASS — aud com.astrace.app.dev (dev build); 200; one hashed apple_identities row; no raw sub/token at rest.
- L3 (session): PARTIAL — sign-out 204 twice (sessions/refresh now 0) PASS. Not shown: relaunch-keeps-session (the only whoami follows a fresh Google sign-in; no relaunch without a sign-in POST is distinguishable) and sign-in-again-restores-birth-data (the second sign-in was a DIFFERENT account — Google, no profile; the Apple account that owns the profile never signed in again).
- L4 (delete Apple-linked account): NOT RUN — no DELETE /api/auth/account.
- L6 (prod variant): NOT RUN — no request from the prod app; Google entry 1 and Apple aud com.astrace.app never exercised; no prod deletion.

Transition: none (remains blocked; missing steps handed back)

## Round 2 (user "GO ON", 2026-09-30) — new log lines 35–42 and rfs_live
- 192.168.1.6 POST /api/auth/apple 200 → GET /api/profiles 200 → POST /api/chart 200 (+ analysis 202/502: LLM keys deliberately blank) → DELETE /api/auth/account 204.
- DB after: users 1 (only the Google account aaf7…, created 21:28:35); apple_identities 0; profiles 0; sessions 0; refresh_tokens 0.
- The Apple sign-in matched the EXISTING Apple-linked user (1fb8…): had it created a new user, users would have been 3 before the delete and 2 after; it is 1. Its profile came back (GET /api/profiles 200 followed by a chart computed for it) → "sign in again → birth data restored" PASS.
- Restart keeps the session: in the app code, `GET /api/auth/whoami` is sent ONLY by core `restoreAccount()` via `bootAccount()` (App.tsx boot, or the gate's Try again) — the sign-in path never calls it. Line 32's `whoami 200` (after the Google sign-in at line 30, with no new sign-in POST before it, followed by the sync's GET /api/profiles) is therefore a boot restore from the Keychain. Caveat: the log cannot distinguish a cold relaunch from a Settings-triggered JS reload (appearance/language change also re-runs boot); both exercise the same Keychain load + whoami restore. Accepted as L3 evidence with this caveat recorded.
- L4: DELETE /api/auth/account 204 on the Apple-linked account → the Apple revoke succeeded (a failed revoke answers 502 and deletes nothing); the apple_identities row and profile are gone. The "no longer listed in Apple ID settings" half is the user's observation (reported as done: "GO ON").

Verdicts: L1 PASS, L2 PASS, L3 PASS (caveat above), L4 PASS (dev audience com.astrace.app.dev). L6 DEFERRED by user ruling to the prod TestFlight check during rollout (with L5) — open, not passed.

Transition: blocked → accepting → done
