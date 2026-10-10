# 10 accepting — fresh-context acceptance re-check (post divination_web merge)

Checker: fresh context. I did not write this code and did not copy verdicts from 08.
Code under test: worktree `/Users/kaimao/Projects/astrology-wt/dw-12-google-sign-in`, branch
`feature/dw-12-google-sign-in` @ `0305c1c`. That commit merges feature/divination_web: dw-8, dw-10,
dw-11 and dw-13, including the six-planet roster picker.
Criteria: `scratchpad/dw-12-criteria.md`.

## Setup

- **Postgres.** A throwaway Postgres cluster from conda `initdb` lived in the checker scratch
  (`scratchpad/dw12acc/pg`). It was TCP only (`-k ''`, `listen_addresses=127.0.0.1`) on port
  54313 and used trust auth for user `astrace`. It held three databases:
  - `astrace_test` for the repo's live-PG tests;
  - `astrace_probe` for the checker probe;
  - `astrace_app` for the real app.
- **The shared remote database was never contacted.** The shell had no DATABASE_URL
  (`env | grep -c DATABASE_URL` → 0), and no process got `--env-file .env`. Every process was
  started with `env -u DATABASE_URL` plus an explicit value. The server code's only dotenv
  loaders are in `app/examples` and `tests/prompt_lab`. Both use `os.environ.setdefault`, so an
  explicit `DATABASE_URL=` (empty or local) always wins.
- **Backend runs.** Every DATABASE_URL host was read with `ps eww`:
  - Real app: uvicorn on 127.0.0.1:8003. DATABASE_URL host = `127.0.0.1:54313`
    (db `astrace_app`). The other env was `GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com`,
    `CORS_ALLOW_ORIGINS=http://localhost:5176` and `ANALYSIS_LLM=claude-cli`.
  - R5 restart: the same env minus DATABASE_URL. `ps eww` showed no DATABASE_URL variable at all.
- **Vite.** Vite dev ran on :5176 with `VITE_API_BASE=http://localhost:8003` and
  `VITE_GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com`. The shell value was set
  explicitly because the root `.env` now carries a GOOGLE_CLIENT_ID key; only the key name was
  inspected, never the value. For R5, `vite preview` on :5176 served a scratch build.
- **Browser.** Headless Chrome 154 over CDP (:9337) with a fresh `--user-data-dir` in scratch,
  driven by the scratch `cdp.mjs` using Node 25's native WebSocket.

## Verdicts

| ID | Verdict | Evidence | Kind |
|---|---|---|---|
| S1 | PASS | **Repo tests:** `test_s1_no_database_is_503_and_google_is_never_asked` and `test_s1_no_client_id_is_503` pass.<br>**Checker probe `test_s1`:** with `db.is_configured` → False, the route answers 503 `{"detail":"accounts unavailable"}` and the recording fake's `calls == []`. With `is_configured` → True and no GOOGLE_CLIENT_ID, it answers 503.<br>**Real app:** the backend with no DATABASE_URL answers `POST /api/auth/google` with 503 `accounts unavailable` (R5). | TESTS/CODE + REAL APP |
| S2 | PASS | **Repo tests:** 9 claim-policy tests pass.<br>**Checker probe `test_s2`:** a verified email is returned, and the audience equals `GOOGLE_CLIENT_ID`. `email_verified:false`, `"true"` (a string), a missing email and a `ValueError` all give None. `google.auth.exceptions.TransportError` raises `GoogleUnavailable`.<br>**Code:** the check is `claims.get("email_verified") is not True`, and `TransportError` is caught before the generic branch. | TESTS/CODE |
| S3 | PASS | **Checker probe `test_s3`:**<br>- `""` → 422 and 4097 characters → 422.<br>- A 4096-character credential that the fake rejects → 401 `{"detail":"not signed in"}`.<br>- No `set-cookie` header on the 422, 401 or 503 answers, or on the 200 in S4.<br>**Code:** `Field(min_length=1, max_length=4096)`. | TESTS/CODE |
| S4 | PASS | **Checker probe (live throwaway PG, fresh db `astrace_probe`):** used the exact email `Dw12.Tester@Example.com` and sub `google-sub-SENTINEL-4242`.<br>- The route returns 200 with keys `{accessExpiresAt, accessToken, email, refreshToken}`.<br>- `accessToken` matches `[A-Za-z0-9_-]{43}`, and `accessExpiresAt` parses with `fromisoformat`.<br>- whoami with the Bearer → 200 with that email.<br>- Refresh → 200 with a new pair (both tokens differ).<br>**Repo test:** `test_s4_happy_path_whoami_and_refresh` passes live. | TESTS (live PG) |
| S5 | PASS | **Checker probe:** a second sign-in as `dw12.tester@example.com` leaves exactly one `users` row in total, and `session_user_id` of both access tokens is the same id (email is citext). A user created beforehand with `_upsert_user('prior.probe@example.com')` is reused: same id, count 1.<br>**Repo test:** test_s5 passes live. | TESTS (live PG) |
| S6 | PASS | **Checker probe:**<br>- `row_to_json` dumps of `users`, `sessions` and `refresh_tokens` contain none of: the sentinel sub, the raw credential, the raw access or refresh token from sign-in, or the raw tokens from refresh.<br>- Every `token_hash` matches `^[0-9a-f]{64}$`.<br>- `users` columns are `['id','email','created_at']`, the same as `001_identity.sql`.<br>- There is no new migration: the latest, 011 and 012, come from dw-6 and dw-7.<br>**Repo test:** test_s6 passes live. | TESTS (live PG) |
| S7 | PASS | **Checker probe:** logout with the bearer and `{refreshToken}` → 204. Afterwards whoami → 401 and refresh → 401.<br>**Real app:** R4 shows the same.<br>**Repo test:** test_s7 passes live. | TESTS (live PG) + REAL APP |
| S8 | PASS | **Source scan (grep):**<br>- `accounts/google.py`: the only match is the word "logged" in the docstring; there is no call.<br>- `sign_in_google`: no log or print call.<br>- `post_google`: no log or print call.<br>**Repo tests:** `test_s8_no_log_or_print_names_a_secret` passes, and its scanner bites (`test_s8_scanner_bites_on_a_planted_log`).<br>**Checker probe:** drove S4 with caplog at DEBUG and captured neither the sub nor the credential. | TESTS/CODE (live PG) |
| S9 | PASS | **Pin tests:** `test_only_google_module_imports_google_auth`, `test_google_auth_pin_bites_on_a_planted_import` and `test_genai_pinned_to_the_native_gateway` pass (3 passed).<br>**Real planted edit:** appending `from google.oauth2 import id_token` to `app/accounts/service.py` turned the pin red (`['accounts/go...s/service.py'] == ['accounts/google.py']`, 1 failed). After `git checkout`, the tests are green again.<br>**requirements.txt:** has `google-auth[requests]>=2.30`. | TESTS/CODE |
| C1 | PASS | `core-google-session.test.ts` C1 passes: empty KV → no request, and the status is signed-out. | TESTS/CODE |
| C2 | PASS | C2 passes: the status is signed-in with the email, and the whoami request carried `Authorization: Bearer <access>`. | TESTS/CODE |
| C3 | PASS | **Tests:** both C3 tests pass:<br>- whoami 401, then refresh 200, then whoami 200 → signed-in with the rotated triple.<br>- Refresh 401 → signed-out with all three keys removed.<br>**Real app:** R3 shows the same. | TESTS/CODE + REAL APP |
| C4 | PASS | C4 tests pass: 503 → `unavailable` and a rejected fetch → `offline`. The tokens stay in KV in both cases. | TESTS/CODE |
| C5 | PASS | Four C5 tests pass:<br>- 200 → `ok`, signed-in, and the triple is under `astrace.auth.access/.refresh/.expiresAt`.<br>- 401 → `invalid` with the status unchanged.<br>- 503 → `unavailable`.<br>- A thrown fetch → `error`.<br>The body is exactly `{"credential":"cred"}`. | TESTS/CODE |
| C6 | PASS | Both C6 tests pass. The logout POST carries the bearer and `{refreshToken}`, then the tokens are cleared and the status is signed-out. The same happens when the logout fetch rejects. The birth, transcript and sessions KV keys survive. | TESTS/CODE |
| C7 | PASS | The source-check test passes. The checker also read `packages/core/src/account/google-session.ts`: its only imports are `../platform` and `./types`. Two concurrent 401s produce ONE refresh POST. | TESTS/CODE |
| W1 | PASS | **Tests:** `AuthGate.test.tsx` W1 ×2 pass.<br>- With empty KV (a birth record seeded), the gate shows the eyebrow, title, body and button slot. There is no stage, side, form, `.chat`, `.log-bar` or `.roster`, and `urls == []`.<br>- With a dead pair, every URL is under `/api/auth/`.<br>**Real app:** R1 shows the same. | TESTS/CODE + REAL APP |
| W2 | PASS | **Test:** W2 passes. The stub callback `cred` with a 200 renders the stage, side, `.chat`, `.log-bar` and form. The masthead shows the email and "Sign out". The posted body is `{"credential":"cred"}`.<br>**Real app:** R2 and R3 show the email chip and "Sign out". | TESTS/CODE + REAL APP |
| W3 | PASS | **Tests:** the three W3 tests pass.<br>- A 401 shows the invalid line and keeps the button.<br>- A 503 shows the unavailable message with "Try again".<br>- `checking` shows "Opening the door…".<br>- Offline shows "Try again", which re-runs whoami (whoami count 1 → 2).<br>**Real app:** R5 shows the unavailable message. | TESTS/CODE + REAL APP |
| W4 | PASS | **Test:** W4 passes. With an empty client id, the unconfigured message shows, and the `loadGoogleIdentity` and `renderGoogleButton` spies are never called. There is no script and no fetch.<br>**Real app:** R5 shows the same. | TESTS/CODE + REAL APP |
| W5 | PASS | **Test:** W5 passes. Sign out returns to the gate, the logout carried the bearer and `{refreshToken}`, and the birth KV record is unchanged.<br>**Real app:** R4 shows the same. | TESTS/CODE + REAL APP |
| W6 | PASS (note) | **Tests:**<br>- The copy switches to zh (title, eyebrow and body), and the button re-renders.<br>- The app calls `renderGoogleButton(…, 'zh')`.<br>- en↔zh leaf parity passes in `i18n.test.ts`.<br>- In the reduced-motion block, `.threshold__card { animation: none; }` is checked against the real `auth.css?raw`.<br>**Note:** GIS itself receives `locale:"zh_CN"`. That follows spec-review N8, settled in plan 03 ("W6 asserts zh_CN instead of zh"). | TESTS/CODE |
| W7 | PASS | `google.test.ts` passes:<br>- Two `loadGoogleIdentity()` calls append exactly one `script[src="https://accounts.google.com/gsi/client"]`.<br>- `initialize` gets `client_id` and `auto_select:false`.<br>- `renderButton` gets `{theme:'filled_black', shape:'pill', size:'large', text:'signin_with', locale:'en'}`. | TESTS/CODE |
| G1 | PASS | **Guard name:** the criteria's G10 is named G12 in the code (review note N3).<br>**Real planted edit:** appending `'https://accounts.google.com/gsi/client'` to `web-divination/src/auth/SignInScreen.tsx` turned G12 red (`+ "web-divination/src/auth/SignInScreen.tsx"`). After the revert it is green again.<br>**Other guards:** G1 (barrels), G3, G9, G12 and G13 pass. The color guards and text guards pass. `architecture` + `color-guard` + `text-variant-guard` give 49/49.<br>**Suites:** `npm test` and `npm run typecheck` exit 0 (see Suites). | TESTS/CODE |
| G2 | PASS | `GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com TOKENROUTER_API_KEY=dw12-sentinel-secret npm --workspace web-divination run build` → exit 0.<br>- `dist/assets/index-*.js` contains `dw12-test.apps.googleusercontent.com`.<br>- 0 files contain `dw12-sentinel-secret`.<br>- The only `*.apps.googleusercontent.com` string in the bundle is the sentinel, not the real id from `.env`. | TESTS/CODE (build) |
| G3 | PASS | CLAUDE.md in the worktree has all four amendments:<br>- The backend paragraph has the web-divination forced-Google exception (2026-09-28 ruling).<br>- Commands has the `GOOGLE_CLIENT_ID` two-readers paragraph.<br>- Rule 3 says `google.auth`/`google.oauth2` may be imported only by `accounts/google.py`.<br>- Rule 12 has the GOOGLE SIGN-IN paragraph and the KV-backed provider. | TESTS/CODE |
| R1 | PASS | **Backend:** `/api/health` → `{"status":"ok","db":"ok","ephemeris":"ok"}`. The DATABASE_URL host is `127.0.0.1:54313`, read with `ps eww` on the uvicorn pid.<br>**Fresh profile at :5176:** only the gate shows ("Before the sky opens" / "Sign in to meet your planets" / the email-only line). There is one GSI script and a GIS iframe `https://accounts.google.com/gsi/button?theme=filled_black&shape=pill&size=large&text=signin_with…`. There is no stage, side, form, chat, log bar or roster.<br>**Network:** the only hosts are `localhost:5176` and `accounts.google.com`. There are 0 requests to :8003 and 0 to `/api/chart` or `/api/divination/*`.<br>Screenshot: `r1-gate.png`. | REAL APP |
| R2 | PASS | **Setup:** the pair was minted for `dw12.accept@example.com` by the scratch `mint.py` (`_upsert_user` + `_mint_bearer` on `astrace_app`; it asserts the 127.0.0.1:54313 prefix). It was written to the three KV keys, together with a birth record and one session-log record, and the page was reloaded.<br>**Result:**<br>- The gate is gone, and the stage and side render.<br>- `svg.wheel` is drawn.<br>- The birth summary reads "1990-06-15 · 08:30 · Beijing (Asia/Shanghai)".<br>- The masthead shows `dw12.accept@example.com` and "Sign out".<br>- With no active character, the six-planet roster opens over the app. That is the expected post-merge behaviour.<br>**Second reload:** still signed in, with the wheel drawn.<br>**Network:** whoami 200, `POST /api/chart` 200, and `/api/divination/sheets` 200.<br>Screenshots: `r2-app.png`, and `r3-app.png` with Venus active. | REAL APP |
| R3 | PASS | `DELETE FROM sessions WHERE token_hash = sha256(access)` → DELETE 1. The active character was set to venus, then the page was reloaded.<br>**Network (page and backend log):** whoami 401 → `POST /api/auth/token/refresh` 200 → whoami 200.<br>**Result:** the app opens (stage, wheel, chat, email chip, "Sessions · 1"). KV now holds a changed access token and a new 43-character refresh token. | REAL APP |
| R4 | PASS | **Sign out:** clicking "Sign out" → `POST /api/auth/logout` 204, and the gate returns. The three auth KV keys are null. The birth and sessions KV values are byte-identical, and the active character is kept.<br>**Reload:** stays on the gate with 0 backend requests.<br>**Refresh tokens:** `/api/auth/token/refresh` answers 401 for the originally minted refresh token and 401 for the rotated one that logout revoked.<br>**Sign in again:** R2's script minted a new pair for the same email. The page shows the same birth summary and "Sessions · 1", the birth and sessions KV are byte-identical, and `users` still holds exactly one row (`dw12.accept@example.com`).<br>Screenshots: `r4-gate.png`, `r4-back.png`. | REAL APP |
| R5 | PASS | **Backend restarted with no DATABASE_URL:** health reports `db:"unconfigured"`. The signed-in browser reloads to the gate with "Sign-in is unavailable — the server has no account database." and "Try again". No button or iframe is shown, and the tokens are kept. `POST /api/auth/google` → 503 from curl and from the page's own fetch.<br>**Build with no client id:** built with `env -u GOOGLE_CLIENT_ID VITE_GOOGLE_CLIENT_ID=` into a scratch outDir; the bundle has 0 `googleusercontent` strings. Served by `vite preview`, it shows "Sign-in isn't set up (no Google client id).", with no GSI script, no iframe and 0 requests to accounts.google.com.<br>Screenshots: `r5-unavailable.png`, `r5-unconfigured.png`. | REAL APP |
| U1 | NOT RUN — user step | This criterion needs a real `GOOGLE_CLIENT_ID` for an OAuth web client (JS origins :5173 and :5180) and a real Google account. It is a live Google sign-in that only the user can do. Nothing was faked and no credentials were typed. | — |

## Suites

| Suite | Result |
|---|---|
| `npm test` (worktree root) | jest 90 suites / 1072 tests, all passing. vitest 30 files / 308 tests, all passing. Exit 0. |
| `npm run typecheck` | Exit 0 in both workspaces. |
| Server db-free (`DATABASE_URL= pytest -q`) | 1378 passed, 55 skipped, exit 0. |
| dw-12 live-PG files (`test_google_auth.py test_boundaries.py test_auth_integration.py test_native_tokens.py`) with `DATABASE_URL=…127.0.0.1:54313/astrace_test` | 85 passed, 0 skipped. |
| Checker probe (`scratchpad/dw12acc/test_probe.py`, live on `astrace_probe`) | 4 passed. |
| Auth vitest subset (`src/auth`, `platform/google.test.ts`, `i18n.test.ts`) | 5 files / 46 tests passed. |

## Cleanup

- **Processes:** the backend, Vite dev, `vite preview`, headless Chrome and the Postgres cluster (`pg_ctl stop -m fast`) were all stopped.
- **Scratch files:** the cluster dir, Chrome profile, scratch build and minted-token files were deleted.
- **Ports:** `lsof` shows 8003, 5176, 54313 and 9337 free, and no leftover processes.
- **Worktree:** both planted edits (S9, G1) were reverted with `git checkout`. `git status --short` in the worktree is clean.
- **Build output:** `web-divination/dist/` (gitignored) holds the G2 sentinel build.
- **Screenshots and logs:** kept in `scratchpad/dw12acc/`.

ACCEPTANCE: PASS (all but U1)
