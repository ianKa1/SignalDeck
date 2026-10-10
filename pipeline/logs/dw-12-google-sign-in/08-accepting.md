# 08 accepting — fresh-context acceptance check

Checker: fresh context, did not see the implementation before grading. Code under test:
worktree `/Users/kaimao/Projects/astrology-wt/dw-12-google-sign-in`, branch
`feature/dw-12-google-sign-in` @ `05fd511` (feature/divination_web with dw-7 and dw-9 merged in).
Criteria: `scratchpad/dw-12-criteria.md`.

Setup: a throwaway Postgres 18 cluster (conda `initdb`) in the checker's scratch dir,
`127.0.0.1:54313`, with databases `astrace_test` (pytest), `astrace_app` (real app), `astrace_t2` and
`astrace_base` (triage). Every `DATABASE_URL` used was `postgresql://astrace@127.0.0.1:54313/…`.
The shared remote database in `.env` was never contacted: no process got `--env-file .env`, and the
shell had no `DATABASE_URL` (`env | grep -c DATABASE_URL` → 0). The real-app backend ran on :8003 with
explicit env only (`DATABASE_URL=…127.0.0.1:54313/astrace_app ANALYSIS_LLM=claude-cli
CORS_ALLOW_ORIGINS=http://localhost:5176 GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com`). The
process environment, read with `ps eww`, showed DATABASE_URL host = `127.0.0.1:54313`. Vite ran on
:5176 with `VITE_API_BASE=http://localhost:8003 VITE_GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com`.
Browser: headless Chrome 154 over CDP with a fresh `--user-data-dir` in scratch.

Incident, not a finding: around 23:14:56 something outside this check sent Postgres a smart-shutdown
signal and killed the checker's `conda run` background wrappers. The cluster was restarted and the
servers relaunched with nohup and direct env-binary paths. Nothing graded depends on the interrupted
run.

| ID | Verdict | Evidence | Kind |
|---|---|---|---|
| S1 | PASS | `test_s1_no_database_is_503_and_google_is_never_asked` and `test_s1_no_client_id_is_503` pass. Checker probe `test_s1_probe` gets 503 `{"detail":"accounts unavailable"}` with the recording fake's `calls == []`, both with `db.is_configured` → False and with a db but no `GOOGLE_CLIENT_ID`. In the real app, a backend with no DATABASE_URL answers `POST /api/auth/google` with 503 `accounts unavailable`. | TESTS/CODE + REAL APP |
| S2 | PASS | 9 claim-policy tests pass (verified email returned, audience == client id; `false`, string `"true"`, missing verified claim, missing or empty email, and `ValueError` all → None; `TransportError` → `GoogleUnavailable`). Checker probe `test_s2_probe` repeats them independently and passes. Code: `claims.get("email_verified") is not True` → None; `TransportError` is caught before the generic branch. | TESTS/CODE |
| S3 | PASS | `""` → 422 and 4097 chars → 422 (`Field(min_length=1,max_length=4096)`). A rejected token → 401 `{"detail":"not signed in"}`. No `set-cookie` header on the 422, 401, 503 or 200 answers (checker probe and the S4 probe). | TESTS/CODE |
| S4 | PASS | Live PG (throwaway). Checker probe with the exact email `Dw12.Tester@Example.com` and sub `google-sub-SENTINEL-4242`: 200 with keys `{accessExpiresAt, accessToken, email, refreshToken}`, a 43-char url-safe accessToken, and an accessExpiresAt that `fromisoformat` parses. whoami with the Bearer → 200 `{"email":"Dw12.Tester@Example.com"}`. Refresh → 200 with a new, different pair. The repo's `test_s4_happy_path_whoami_and_refresh` also passes live. | TESTS (live PG) |
| S5 | PASS | Checker probe: a second sign-in as `dw12.tester@example.com` leaves exactly one `users` row (`users.email` is citext, migration 001), and `session_user_id` of both access tokens is that row's id. A user created beforehand with `_upsert_user('prior-probe@example.com')` is reused (same id, count 1). The repo's `test_s5_upsert_by_email_is_one_user` passes live. | TESTS (live PG) |
| S6 | PASS | Checker probe: `row_to_json` dumps of `users`, `sessions` and `refresh_tokens` contain none of the sentinel sub, the raw credential, or the raw access or refresh token. Every `token_hash` matches `^[0-9a-f]{64}$`. `users` columns are `['id','email','created_at']`, the same as `001_identity.sql`. dw-12 adds no migration (the latest is 012, from dw-7). The repo's test_s6 passes live. | TESTS (live PG) |
| S7 | PASS | Checker probe: logout with the bearer and `{refreshToken}` → 204. Afterwards whoami → 401 and refresh → 401. The repo's test_s7 passes live. The real app shows the same in R4. | TESTS (live PG) + REAL APP |
| S8 | PASS | `test_s8_no_log_or_print_names_a_secret` (AST scan of google.py, `sign_in_google` and `post_google`) passes, and its scanner bites on a planted log (`test_s8_scanner_bites_on_a_planted_log`). Reading the code, google.py, `sign_in_google` and `post_google` contain no log or print call. With caplog at DEBUG, the checker probe drove S4 and captured neither the sub nor the credential. The repo's live `test_s8_debug_logs_carry_no_sub_or_credential` passes. | TESTS/CODE (live PG) |
| S9 | PASS | `test_only_google_module_imports_google_auth`, `test_google_auth_pin_bites_on_a_planted_import` and `test_genai_pinned_to_the_native_gateway` pass. A real planted edit (`from google.oauth2 import id_token` appended to `app/accounts/service.py`) turned the pin red: `['accounts/go...s/service.py'] == ['accounts/google.py']`, 1 failed. The edit was reverted (`git checkout`) and the tests are green again. `requirements.txt` contains `google-auth[requests]>=2.30`. | TESTS/CODE |
| C1 | PASS | `core-google-session.test.ts` C1 passes: `calls == []`, then `signed-out`. Code: with no provider or no access token it calls `setSession('signed-out')` before any fetch. | TESTS/CODE |
| C2 | PASS | C2 passes: signed-in with the email, one call to `/api/auth/whoami` with `Authorization: Bearer old-access`. | TESTS/CODE |
| C3 | PASS | Both C3 tests pass: 401 → refresh 200 → 200 ends signed-in with the NEW triple in KV. Refresh 401 → signed-out, all three keys null, settles in under 2 s, one refresh POST. The real app shows the same in R3. | TESTS/CODE + REAL APP |
| C4 | PASS | C4 tests pass: 503 → `unavailable` and a rejected fetch → `offline`, with the tokens still in KV in both cases. A retry re-runs whoami. | TESTS/CODE |
| C5 | PASS | Four C5 tests pass: 200 → `'ok'`, signed-in, triple under `astrace.auth.access/.refresh/.expiresAt`, body exactly `{"credential":"cred"}`. 401 → `'invalid'` with status unchanged. 503 → `'unavailable'`. A thrown fetch → `'error'`. | TESTS/CODE |
| C6 | PASS | Both C6 tests pass: the logout POST carries the bearer and `{refreshToken}`, the tokens are cleared and the status is signed-out, also when the logout fetch rejects. Birth, transcript and sessions KV keys survive. | TESTS/CODE |
| C7 | PASS | The source check passes. The checker read `google-session.ts`: its only import specifiers are `../platform` and `./types`. The concurrent-401 test issues ONE refresh POST (the single-flight `inFlight` in `webTokenStore`). | TESTS/CODE |
| W1 | PASS | `AuthGate.test.tsx` W1 ×2 pass: empty KV shows the eyebrow, title, body and button slot, with no stage, side, form, `.chat` or `.log-bar`, and 0 fetches. A dead pair produces only `/api/auth/` URLs. The real app shows the same in R1. | TESTS/CODE + REAL APP |
| W2 | PASS | W2 passes: the stub callback `cred` with a 200 renders `[data-slot=stage]` and `[data-slot=side]`, and the masthead shows the email and "Sign out". The real app (R2) shows the chip `dw12.accept@example.com` and "Sign out". | TESTS/CODE + REAL APP |
| W3 | PASS | Three W3 tests pass: 401 shows the invalid line and keeps the button, 503 shows the unavailable message, checking shows "Opening the door…" (en.auth.checking), and offline shows "Try again", which re-runs whoami (count 1 → 2). The real app shows the unavailable message in R5. | TESTS/CODE |
| W4 | PASS | W4 passes: with an empty client id the unconfigured message shows, the `loadGoogleIdentity` and `renderGoogleButton` spies are never called, and there is no script and no fetch. The real app shows the same in R5. | TESTS/CODE + REAL APP |
| W6 | PASS (note) | W6 tests pass. The copy switches to zh and the button re-renders, with `renderGoogleButton(…, 'zh')` at the stubbed module boundary. GIS itself receives `locale:"zh_CN"`, which follows the spec review's N8 and plan 03's settled deviation ("W6 asserts zh_CN instead of zh"), since GIS locales are region-qualified. en↔zh parity passes (`i18n.test.ts`, generic leaf-path parity that covers `auth`). The reduced-motion block has `.threshold__card { animation: none; }`, checked against the real `auth.css?raw`. | TESTS/CODE |
| W5 | PASS | W5 passes: Sign out returns to the gate, the logout carried the bearer and `{refreshToken}`, and the birth KV record is unchanged. The real app shows the same in R4. | TESTS/CODE + REAL APP |
| W7 | PASS | `google.test.ts` passes: two `loadGoogleIdentity()` calls append exactly one `script[src="https://accounts.google.com/gsi/client"]`. `initialize` gets `client_id` and `auto_select:false`, and `renderButton` gets `{theme:'filled_black', shape:'pill', size:'large', text:'signin_with', locale:'en'}`. | TESTS/CODE |
| G1 | PASS | The Google-origin guard (named G12 in the code; the plan renamed G10 → G12 because G10 was taken) passes. A real planted edit appended `'https://accounts.google.com/gsi/client'` to `web-divination/src/auth/SignInScreen.tsx`, and the guard went red with `+ "web-divination/src/auth/SignInScreen.tsx"`. The edit was reverted and the guard is green again. G1 (barrel-only, line 194), G3, G9, G12 and G13, the colour guards ("no chromatic colour literal outside theme/tokens.ts", "web-divination has exactly one colour home") and the text guards pass: `architecture` + `color-guard` + `text-variant-guard` give 49/49. `npm test` gives jest 90 suites / 1072 tests and vitest 26 files / 248 tests, all passing, exit 0. `npm run typecheck` exits 0 in both workspaces. | TESTS/CODE |
| G2 | PASS | `GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com TOKENROUTER_API_KEY=dw12-sentinel-secret npm --workspace web-divination run build` → exit 0. `dist/assets/index-*.js` contains the client id. There are 0 files containing `dw12-sentinel-secret`, and 0 containing RESEND, GEMINI_API or postgres. | TESTS/CODE (build) |
| G3 | PASS | The CLAUDE.md diff has four amendments. The backend paragraph gains the forced-Google exception for web-divination. Commands gains the `GOOGLE_CLIENT_ID` two-readers paragraph. Rule 3 now says `google.auth`/`google.oauth2` may be imported only by `accounts/google.py`. Rule 12 gains the `POST /api/auth/google` paragraph and the KV-backed provider. | TESTS/CODE |
| R1 | PASS | `/api/health` → `{"status":"ok","db":"ok","ephemeris":"ok"}`. The DATABASE_URL host is `127.0.0.1:54313`, read from the uvicorn process env; migrations landed in `astrace_app`. A fresh profile at :5176 shows only the gate: eyebrow "Before the sky opens", title "Sign in to meet your planets", and a GIS iframe `https://accounts.google.com/gsi/button?theme=filled_black&shape=pill&size=large…`, with one GSI script. There is no stage, side, form, chat or log bar. The network log has 0 requests to :8003 and 0 to `/api/chart` or `/api/divination/*`; the only hosts are localhost:5176 and accounts.google.com. Screenshot `r1-gate.png` (scratch). | REAL APP |
| R2 | PASS | The pair was minted by the scratch `mint.py` (`_upsert_user` + `_mint_bearer` on astrace_app; the script asserts the 127.0.0.1:54313 prefix) for `dw12.accept@example.com`. It was written to the three KV keys along with a birth record and one session-log record, and the page was reloaded. Result: gate gone, stage and side present, `svg.wheel` drawn (69 marks, stage status `ready`), birth summary "1990-06-15 · 08:30 · Beijing (Asia/Shanghai)", chip email `dw12.accept@example.com`, "Sessions · 1". A second reload is identical. Backend log: `GET /api/auth/whoami 200`, `POST /api/chart 200`. | REAL APP |
| R3 | PASS | `DELETE FROM sessions WHERE token_hash=sha256(access)` → DELETE 1, then reload. Backend log: whoami 401 → `POST /api/auth/token/refresh` 200 → whoami 200. The app opens (stage and wheel, chip). KV now holds a changed access token and a new 43-char refresh token. | REAL APP |
| R4 | PASS | Clicking "Sign out" → `POST /api/auth/logout 204` and the gate returns. KV auth keys are null, while the birth and sessions KV values are byte-identical. A reload stays on the gate (button present) with 0 backend requests. `/api/auth/token/refresh` gives 401 for the originally minted refresh token and 401 for the rotated one that logout revoked. Signing in again with a newly minted pair for the same email shows the same birth summary, "Sessions · 1", birth and sessions KV byte-identical, and still one `users` row. | REAL APP |
| R5 | PASS | Backend restarted with DATABASE_URL unset: health `db:"unconfigured"`. The signed-in browser reloads to the gate with "Sign-in is unavailable — the server has no account database." and "Try again", no button, and the tokens kept. `POST /api/auth/google` gives 503 both from curl and from the page. A `vite build` with no client id (shell unset; the root `.env` has no GOOGLE_CLIENT_ID key; bundle contains 0 `apps.googleusercontent`), served by `vite preview`, shows "Sign-in isn't set up (no Google client id).", no button and no GSI script. | REAL APP |
| U1 | NOT RUN — needs user input | Needs a real `GOOGLE_CLIENT_ID` for an OAuth web client whose authorized JS origins include `http://localhost:5173` and `http://localhost:5180`, plus a real Google account for the popup. Neither exists on this machine, so this was not faked. To run it: put the id in the root `.env` (shell-exported to the backend), start Vite on :5173 or :5180, and use a fresh throwaway db. Then check: a fresh browser sees only the gate; "Sign in with Google" completes; a chart and one Venus reply work; a reload stays signed in; sign-out returns to the gate; `users` holds exactly one row for that email; and S6's dump contains no `sub`. | — |

Suites: the full server suite db-free (`DATABASE_URL=` pytest -q) gives 1225 passed, 55 skipped, exit 0.
The dw-12 live-PG set (`test_google_auth.py`, `test_boundaries.py`, `test_auth_integration.py`,
`test_native_tokens.py`, run with the throwaway DATABASE_URL) gives 78 passed and 0 skipped. The
checker's own probe file gives 4 passed live.

Out-of-scope observation: running the WHOLE server suite with a live DATABASE_URL gives 28
failures, in the OTP-PG, card/explain-store column-list, cors, analysis, ask-fitness, and
divination persona/summary tests. None of these touch dw-12 files. The same subset run on the base
branch `feature/divination_web` @ c4342d6 against a fresh db fails the same 26. The other two,
`test_p5_miss_then_hit` and `test_s2_miss_then_hit`, fail only in the full live-db ordering. These
failures are pre-existing suite-under-PG debt, not dw-12 regressions, and are not graded here.

Cleanup: backend, Vite, the Vite preview, headless Chrome and the Postgres cluster were all stopped.
The cluster dir, browser profile and scratch build dir were deleted. `lsof` shows 8003, 5176, 54313 and 9337
free. Both planted edits were reverted, and `git status --short` in the worktree is clean.
`web-divination/dist/` (gitignored) holds the G2 build.

ACCEPTANCE: INCOMPLETE — U1 needs user input
