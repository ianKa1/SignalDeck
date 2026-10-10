# dw-12-google-sign-in — the web app opens only after Google sign-in

## Goal

web-divination is gated behind a mandatory Google sign-in. The server verifies the Google ID token, upserts the user by email and returns the existing bearer pair. The session survives a reload, and sign-out returns the browser to the gate. QUEUE.md `dw-12-google-sign-in` (user ruling 2026-09-28); epic `pipeline/epics/divination-web.md`.

## Non-goals

- Any change to `app-native/`. Its accounts stay optional and anonymous-first, its sign-in stays OTP or magic link, and its token store is untouched.
- Per-user server data. Chat, transcripts, the session log, birth data and caches stay device-local and identity-free. There is no profile sync, no journal write and no new table. dw-12 adds no migration.
- Server-side enforcement on non-auth routes. `/api/chart`, `/api/divination/*` and every other identity-free route stay unauthenticated (Decided default 3).
- Google One Tap, automatic sign-in, account linking, sign-in with any other provider, account deletion from the web, and a "switch account" flow.
- Hosting, a Render change, or a production Google client. The app stays local (epic ruling).
- Storing Google's `sub`, name, picture, or the ID token itself, anywhere.
- Rate-limiting the new route. Signed ID tokens cannot be brute-forced; the existing refresh gate still covers rotation.

## Decided defaults

1. **The flow.** The browser shows the Google Identity Services (GIS) "Sign in with Google" button. GIS hands the page an ID token (`credential`). The page posts it to `POST /api/auth/google`. The server checks the token's signature, issuer, expiry and audience (`GOOGLE_CLIENT_ID`) with `google-auth`, requires `email_verified === true`, upserts the user by that email and mints the existing native bearer pair. The route returns the same body shape as native `verify`: `{email, accessToken, refreshToken, accessExpiresAt}`.
2. **Scopes, honestly.** The app asks Google for nothing beyond the default Sign-in-with-Google ID token, and never requests an OAuth access token or any API scope. The button's consent screen is Google's. It names the basic profile (name, picture) alongside email, and the button cannot narrow it. The "openid + email only" minimum therefore holds for what Astrace reads and keeps: the server reads `email` and `email_verified` and discards every other claim. The redirect-based `scope=openid email` flow was rejected: it needs authorized redirect URIs the user was not asked for, plus nonce and state handling, for no stored-data difference.
3. **The gate is a UI gate, and it fails closed.** Until the core session status is `signed-in`, `main.tsx` renders the sign-in screen instead of `<App/>`. Nothing that fetches mounts: the chart subscription, chat, session bar and session resume all stay unmounted. Before sign-in the browser sends only `/api/auth/*` requests and the GIS script load. The server does not demand a bearer on divination or chart routes. The epic rules that divination carries no identity, the routes are shared with app-native, and the app is local-only. The forced sign-in is the user's product gate, not access control. Journaled as such.
4. **Existing device-local data.** It is untouched by sign-in and sign-out. Birth data, the transcript and the session log are the device's, not the account's. They are hidden while the gate is up and reappear after any sign-in on that browser. The session's email is never written to storage; it comes from `whoami` at each boot.
5. **Tokens on the web.** A web `AuthTokenProvider` keeps the triple in memory and in the KV port (localStorage) under `astrace.auth.access`, `astrace.auth.refresh` and `astrace.auth.expiresAt`. On web the Secure port is itself a KV facade, so KV is used directly and synchronously. localStorage is readable by page script; that is accepted for a local-only app and stated in CLAUDE.md. The refresh token rotates through `POST /api/auth/token/refresh`, single-flight, on any 401 from `apiFetch`.
6. **Boot and reload.** With no stored access token the status is `signed-out` immediately and no request is sent. With one, the app calls `GET /api/auth/whoami` through `apiFetch`, which carries the bearer and refreshes once on a 401:
   - 200 → `signed-in` with the email.
   - 401 after the refresh → tokens cleared → `signed-out`.
   - 503 → `unavailable`, tokens kept.
   - A network failure → `offline`, tokens kept.
   The screen shows `checking` until the answer arrives.
7. **Sign-out.** A quiet "Sign out" button sits in the masthead. It posts `/api/auth/logout` with the bearer and `{refreshToken}`, so both rows are revoked. Whatever the answer, even a network error, it then clears the local tokens and returns to the gate. There is no confirmation, since nothing local is lost.
8. **Dormant and unconfigured, stated honestly.** Without `DATABASE_URL` or `GOOGLE_CLIENT_ID`, `POST /api/auth/google` answers the generic 503 `accounts unavailable` before touching Google. The web app is then UNUSABLE: the gate shows "Sign-in is unavailable — the server has no account database" and nothing else. With no web client id, the gate shows "Sign-in isn't set up (no Google client id)", loads no script and renders no button. The epic's "local only" product now needs a Postgres database to open at all.
9. **Where the client id lives.** One home: `GOOGLE_CLIENT_ID` in the repo-root `.env`.
   - The server reads it as the audience.
   - `vite.config.ts` reads exactly that one key from the root `.env` with `loadEnv(mode, <repo root>, 'GOOGLE_CLIENT_ID')` and exposes it as `import.meta.env.VITE_GOOGLE_CLIENT_ID`. A shell `VITE_GOOGLE_CLIENT_ID` overrides it.
   - A client id is public by nature. No other root `.env` value reaches the bundle.
   - `.env.example` gains the key with a comment naming the authorized origins.
10. **GIS loading.** `web-divination/src/platform/google.ts` injects `<script src="https://accounts.google.com/gsi/client" async>` once, lazily, when the gate first needs the button. `index.html` gains no external script. The button is rendered with `theme:"filled_black"`, `shape:"pill"`, `size:"large"`, `text:"signin_with"`, and `locale` set to the app language (it re-renders on a language switch). There is no One Tap prompt and `auto_select` is false.
11. **Gate screen design.** The design follows the existing dark celestial theme, with no new colour tokens.
    - The masthead is the same Header: wordmark, tagline and language toggle, with no account chrome.
    - Below it, centred in a `panel` card with a `line` hairline border, stands a threshold:
      - an eyebrow, "Before the sky opens" (small caps, `text-faint`);
      - a display-serif title, "Sign in to meet your planets" (`voice`);
      - one body line: "Google tells Astrace your email — only that is kept. Your chart and conversations stay in this browser." (`text-dim`);
      - the Google button slot.
    - A faint decorative ring sits behind the card: a static SVG circle with twelve tick marks in `line-soft`. It is decorative only (`aria-hidden`) and computes nothing.
    - State lines replace the button slot:
      - `checking`: "Opening the door…";
      - `invalid`: "Google sign-in didn't go through. Try again." above the button;
      - `unavailable` and `offline`: the message plus a "Try again" button that re-runs the boot check;
      - `unconfigured`: the message only.
    - The card fades in over 400 ms, with no animation under reduced motion.
12. **Signed-in chrome.** In the masthead, left of the language toggle, the email is shown in small `text-faint` type, truncated with an ellipsis at 24ch and given a `title`, followed by a "Sign out" text button (`text-dim`, `voice` on hover and focus). On narrow screens the email hides and the button remains.
13. **Email case.** `users.email` is `citext` (migration 001), so the email is passed through as Google returns it.
14. **Validation inputs.** A non-shared Postgres is NOT a user input: `initdb`, `pg_ctl` and `postgres` 18.4 ship in the conda env `astrology`, and the throwaway-cluster recipe is in `server/tests/test_auth_integration.py`'s docstring. Every dw-12 real-app run starts the backend WITHOUT `--env-file .env` and with `DATABASE_URL` pointed at that local cluster, so the shared Neon database named in `.env` is never contacted. Without Google, a signed-in state is produced by minting a bearer pair directly in the throwaway database with a log-recorded script (not shipped code) and placing it in localStorage. The only user inputs are `GOOGLE_CLIENT_ID` (an OAuth web client whose authorized JavaScript origins include `http://localhost:5173` and `http://localhost:5180`) and a Google account to click through. Only U1 needs them. The live check runs Vite on :5173 or :5180, never the worker's :5176, with `CORS_ALLOW_ORIGINS` naming that origin.

## Architecture

Cites `pipeline/epics/divination-web.md`. That file's rulings, reuse map and dependency rules stand. It has no accounts section, so dw-12's reuse was verified here by targeted reads.

### Reuse (verified 2026-09-28)

| Need | Existing | Use |
|---|---|---|
| Identity mint | `accounts/service.py` `_require_db` :16, `_upsert_user` :45, `_mint_bearer` :58 | Reused verbatim. Nothing new is minted. |
| Refresh, whoami, logout | `routes.py` `post_token_refresh` :237, `get_whoami` :282, `post_logout` :303 (bearer via `_parse_bearer` :71; logout revokes `refreshToken` from the body) | Unchanged. The web calls them as native does. |
| Dormant 503 | `routes.py` `_UNAVAILABLE` :53, `AccountsUnavailable` (service :12) | Reused. |
| Native response shape | `post_verify` native branch :163-177 | Copied as the Google route's body. |
| Bearer transport | core `platform/api.ts` `apiFetch` :41 (bearer injection + one refresh on a 401); `platform/auth.ts` port :28, `configureAuthTokenProvider` :51 | Reused. The web installs a provider. |
| Provider precedent | `app-native/src/account/tokenStore.ts` (single-flight refresh via `apiFetch`) | Its shape is mirrored. G9 forbids importing it. |
| KV | core `platform/storage.ts` `getKV` :33 | Token persistence. |
| Outcome type | core `account/types.ts` `VerifyOutcome` | Reused for the sign-in result. |
| Single-importer guard shape | `test_boundaries.py` `GENAI_RE` :20, `test_genai_pinned_to_the_native_gateway` :59 | Copied for google-auth. |
| Live-PG test recipe | `tests/test_auth_integration.py` :1-25 (skipif without `DATABASE_URL`) | The Postgres half of dw-12's server tests. |
| Library | `google-auth` 2.56.2 and `requests` 2.34.2 are already in the conda env, pulled in by `google-genai` | Declared explicitly. |

Core `account/service.ts` is deliberately NOT reused. Its sign-in tail starts profile sync (`startSync` → `/api/profiles`), which would put per-user data on the server, and its `logout` runs `wipeAllLocal`, which would destroy device data (Decided default 4).

### Module map (created or changed only)

```
server/
├── requirements.txt              CHG  + google-auth[requests]>=2.30
└── app/accounts/
    ├── google.py                 NEW  sole google-auth importer; ID token → verified email
    ├── service.py                CHG  + sign_in_google(credential)
    └── routes.py                 CHG  + POST /api/auth/google, GoogleBody
server/tests/
├── test_google_auth.py           NEW  fake-verifier unit/API tests + env-guarded live-PG tests
└── test_boundaries.py            CHG  + test_only_google_module_imports_google_auth (appended)
packages/core/src/
├── account/google-session.ts     NEW  web bearer session: restore / sign in / sign out + status channel
├── account/index.ts              CHG  + exports (appended)
└── platform/auth.ts, api.ts      CHG  comments only: a browser surface may install a provider
web-divination/
├── vite.config.ts                CHG  loadEnv GOOGLE_CLIENT_ID → import.meta.env.VITE_GOOGLE_CLIENT_ID
└── src/
    ├── platform/auth.ts          NEW  webTokenStore: AuthTokenProvider over KV
    ├── platform/google.ts        NEW  GIS script loader + button render (the one GIS origin)
    ├── platform/boot.ts          CHG  step 6: configureAuthTokenProvider(webTokenStore)
    ├── auth/                     NEW  AuthGate.tsx, SignInScreen.tsx, AccountChip.tsx,
    │                                  useGoogleSession.ts, auth.css, *.test.tsx,
    │                                  core-google-session.test.ts
    ├── main.tsx                  CHG  <AuthGate><App/></AuthGate>
    ├── app/Header.tsx            CHG  renders <AccountChip/> (null unless signed in)
    └── i18n/en.ts, zh.ts         CHG  + `auth` namespace (appended last)
app-native/src/architecture.test.ts  CHG  + G10 (appended)
.env.example, CLAUDE.md              CHG
```

`App.tsx`, `main.py`, `models.py`, migrations and the divination packages are untouched. The router is already included at main.py:112.

### Module contracts

**`accounts/google.py`**
- `_verify_token(credential, audience) -> dict` is the ONLY line that touches google-auth: `id_token.verify_oauth2_token(credential, google.auth.transport.requests.Request(), audience)`, imported lazily. Tests monkeypatch it.
- `verified_email(credential) -> str | None` reads `GOOGLE_CLIENT_ID`:
  - unset → raise `GoogleUnconfigured`;
  - a `google.auth.exceptions.TransportError` (certificate fetch) → raise `GoogleUnavailable`;
  - a `ValueError` or any other verification failure → `None`;
  - it returns the email only when the claims carry a non-empty `email` and `email_verified is True`.
- It never returns, stores or logs `sub`, other claims or the credential.
- It imports nothing from the app.

**`service.sign_in_google(credential)`**
- Calls `_require_db()` FIRST. With no db, Google is never consulted.
- Then calls `verified_email`. `GoogleUnconfigured` and `GoogleUnavailable` are re-raised as `AccountsUnavailable`; `None` → return `None`.
- Then, on one connection: delete expired `sessions` and `refresh_tokens` rows (the `verify_native` cleanup), `_upsert_user`, `_mint_bearer`.
- Returns `(email, access_raw, refresh_raw, access_expires_at)`.

**`routes.post_google(body: GoogleBody)`**
- `GoogleBody = {credential: str}`, non-empty, at most 4096 characters; otherwise 422.
- `AccountsUnavailable` → 503; `None` → 401 `not signed in`; otherwise 200 with the native body.
- It sets no cookie.

**core `account/google-session.ts`** (React-free; imports only `../platform` and `./types`)
- `GoogleSession = {status: 'checking'|'signed-out'|'signed-in'|'unavailable'|'offline', email: string|null}`. The initial status is `checking`.
- `restoreGoogleSession(): Promise<void>` follows Decided default 6.
- `signInWithGoogle(credential): Promise<VerifyOutcome>`:
  - it POSTs via `apiFetch`;
  - on 200 it persists through the provider, then sets `signed-in` → `'ok'`;
  - 401 → `'invalid'`, status unchanged;
  - 503 → status `unavailable` → `'unavailable'`;
  - a throw → `'error'`.
- `signOutGoogle(): Promise<void>` follows Decided default 7.
- `getGoogleSession()` and `subscribeGoogleSession(listener)` complete the channel.
- It never imports `./service`, `./sync`, `../profile` or `../identity-lifecycle`.

**web `platform/auth.ts` `webTokenStore`**
- Implements `AuthTokenProvider`, hydrating synchronously from KV at module load.
- `persist` writes memory and all three KV keys. `clear` removes both.
- `refresh` is single-flight over `apiFetch('/api/auth/token/refresh')`; only a complete triple is persisted.
- `isNative()` returns `false`. No core path that reads it is used by the web.
- It never logs a token.

**web `platform/google.ts`**
- `googleClientId(): string | null`.
- `loadGoogleIdentity(): Promise<void>` injects the script once and rejects on load error.
- `renderGoogleButton(el, lang, onCredential): void` calls `initialize({client_id, callback, auto_select:false})` and then `renderButton`.

**web `auth/`**
- `AuthGate` calls `restoreGoogleSession()` once on mount and renders `children` only when the status is `signed-in`; otherwise it renders `<Header/>` plus `SignInScreen`.
- `SignInScreen` owns the `invalid` and `unconfigured` view states.
- `AccountChip` shows the email and a "Sign out" button.
- `useGoogleSession` is `useSyncExternalStore` over the core channel.

### Wire

`POST /api/auth/google`, a new route:

| Case | Status | Body |
|---|---|---|
| Request | — | `{credential: string}` |
| Signed in | 200 | `{email, accessToken, refreshToken, accessExpiresAt}` (ISO-8601) |
| Rejected: bad signature, audience, issuer or expiry, `email_verified` not true, no email | 401 | `{detail:"not signed in"}` |
| No `DATABASE_URL`, no `GOOGLE_CLIENT_ID`, or Google's certificates unreachable | 503 | `{detail:"accounts unavailable"}` |
| Empty or oversize credential | 422 | FastAPI validation body |

`/whoami`, `/token/refresh` and `/logout` are unchanged. CORS already allows the `Authorization` header (main.py:104-110, `allow_headers=["*"]`).

### Dependency rules and forbidden edges

- ❌ No `app/` module but `accounts/google.py` may import `google.auth` or `google.oauth2` (rule 3). `google.genai` stays pinned to `cards/gemini_gateway.py`, and the two patterns are disjoint.
- ❌ `accounts/google.py` imports nothing from `app`. Only `accounts/service.py` imports it.
- ❌ `divination/`, `chart/` and main.py's non-auth routes never read `Authorization` or call `session_user_id`. The epic's no-identity rule for divination is unchanged.
- ❌ `core/account/google-session.ts` never imports the profile-sync or wipe paths (Decided default 4).
- ❌ Only `web-divination/src/platform/google.ts` names `accounts.google.com`. Network doors stay in `src/platform/` (G3). `auth/` reaches core only through the `@astrace/core/account` and `@astrace/core/platform` barrels (G1).
- The web and native trees still never import each other (G9).

### CLAUDE.md and guard amendments (same commit)

- **Backend paragraph** ("Accounts are OPTIONAL…"): append "EXCEPT web-divination: by user ruling 2026-09-28 (dw-12) the web app opens only after a FORCED Google sign-in; app-native stays optional and anonymous-first. The gate is a UI gate: identity-free routes stay unauthenticated, and chat, logs and caches stay device-local."
- **Commands**: `GOOGLE_CLIENT_ID` in the root `.env` feeds the server's audience check and the web bundle via `vite.config.ts` loadEnv. It is public, and it is the only root `.env` key the bundle sees.
- **Rule 3**: add "`google.auth`/`google.oauth2` (google-auth) only by `server/app/accounts/google.py`", enforced by `test_only_google_module_imports_google_auth`.
- **Rule 12**: add a Google paragraph:
  - `POST /api/auth/google` verifies the ID token server-side against `GOOGLE_CLIENT_ID` and requires `email_verified`;
  - it upserts by email, and the `sub`, other claims and the token are never stored or logged;
  - it reuses `_upsert_user` and `_mint_bearer` and returns the native body;
  - it is dormant-503 without `DATABASE_URL` or `GOOGLE_CLIENT_ID`;
  - web-divination installs a KV-backed `AuthTokenProvider` (tokens in localStorage, accepted for a local-only app).
- **core `platform/auth.ts` and `api.ts` comments**: "absent on web" becomes "absent on a cookie web surface; web-divination installs a bearer provider (dw-12)."
- **Guards**:
  - `test_boundaries.py` gains `test_only_google_module_imports_google_auth`.
  - `architecture.test.ts` gains G10: the string `accounts.google.com` appears, comments stripped, only in `web-divination/src/platform/google.ts`, and `web-divination/index.html` contains no `<script` with an `http` src. It gets a synthetic self-check bite.

### Shared files (landing-conflict surface with dw-7 and dw-9)

- `i18n/en.ts` and `zh.ts`: dw-7 appends `persona`, dw-9 appends inside `chat`, and dw-12 appends `auth` last. Append-only hunks.
- `test_boundaries.py`: one appended test.
- CLAUDE.md: the backend paragraph and rules 3 and 12. dw-7 and dw-9 touch rules 9, 10 and 11.
- dw-12 touches no file in `chat/`, `divination/`, main.py, models.py or migrations, so dw-7's migration 012 stays unrenumbered.

## Acceptance Criteria

Server tests monkeypatch `app.accounts.google._verify_token` (the fake verifier) and never reach Google. "Live-PG" tests are env-guarded on `DATABASE_URL` and MUST be run against a throwaway local cluster (Decided default 14). A skip is not a pass, and the Neon URL in `.env` is never used. Run `npm run server:test`, `npm test` and `npm run typecheck`. **[USER-INPUT]** marks the one criterion that needs inputs the loop cannot create.

**Server**
- **S1 (dormant)**: With `DATABASE_URL` unset, `POST /api/auth/google {credential:"x"}` → 503 `accounts unavailable`, and a fake verifier that records calls was NOT called. With a db configured (a monkeypatched `db.is_configured`) but `GOOGLE_CLIENT_ID` unset → 503.
- **S2 (claim policy, db-free)**: `verified_email` with `GOOGLE_CLIENT_ID` set and a fake `_verify_token`:
  - returns the email for `{email, email_verified:true, sub}`;
  - returns `None` for `email_verified:false`, for `email_verified:"true"` (a string), for a missing email, and when the fake raises `ValueError`;
  - raises `GoogleUnavailable` when the fake raises `google.auth.exceptions.TransportError`;
  - the fake receives the audience equal to `GOOGLE_CLIENT_ID`.
- **S3 (route shape)**: an empty credential → 422 and a 4097-character one → 422. A rejected token → 401 `not signed in`. No response from the route carries a `Set-Cookie` header.
- **S4 (live-PG happy path)**: A fake verifier returns email `Dw12.Tester@Example.com`, `email_verified:true` and `sub` `"google-sub-SENTINEL-4242"`.
  - The route → 200 with `email`, a 43-character url-safe `accessToken` (`tokens.new_token`), a `refreshToken` and a parseable `accessExpiresAt`.
  - `GET /api/auth/whoami` with `Authorization: Bearer <accessToken>` → 200 with that email.
  - `POST /api/auth/token/refresh` with the refresh token → 200 and a new pair.
- **S5 (live-PG upsert by email)**: Signing in twice, the second time as `dw12.tester@example.com`, yields ONE `users` row, and both access tokens resolve to the same user id. A user created beforehand through `_upsert_user` with the same email is reused, not duplicated.
- **S6 (live-PG nothing but email)**: After S4, a dump of every text column of `users`, `sessions` and `refresh_tokens` contains neither the sentinel `sub` nor the raw credential nor the raw access or refresh token. The token columns hold 64-hex hashes only. The `users` columns are exactly those of migration 001.
- **S7 (live-PG sign-out revokes)**: `POST /api/auth/logout` with the bearer and `{refreshToken}` → 204. Afterwards `whoami` with that access token → 401, and a refresh with that refresh token → 401.
- **S8 (no logging of secrets)**: A source scan of `accounts/google.py`, `service.sign_in_google` and `routes.post_google` finds no `log`/`logger`/`print` call whose arguments name `credential`, `claims`, `sub` or a token variable. Driving S4 with caplog at DEBUG captures neither the sentinel `sub` nor the credential.
- **S9 (single importer)**: `test_only_google_module_imports_google_auth` passes (importers of `google.auth`/`google.oauth2` == `["accounts/google.py"]`) and goes red on a planted `from google.oauth2 import id_token` in another `app/` file. `test_genai_pinned_to_the_native_gateway` still passes. `requirements.txt` lists `google-auth[requests]`.

**Core session (vitest, `auth/core-google-session.test.ts`, stubbed `fetch`, real KV)**
- **C1**: With empty KV, `restoreGoogleSession()` sends no request and the status becomes `signed-out`.
- **C2**: With stored tokens and a `whoami` 200, the status is `signed-in` with the email, and the request carried `Authorization: Bearer <access>`.
- **C3**: `whoami` 401 → refresh 200 → `whoami` 200 ends `signed-in`, and the rotated triple is in KV. With the refresh also 401 → `signed-out` and all three KV keys are removed.
- **C4**: `whoami` 503 → `unavailable`, and a rejected fetch → `offline`. The tokens stay in KV in both cases.
- **C5**: `signInWithGoogle("cred")`:
  - 200 → `'ok'`, `signed-in`, and the triple is in KV under the three decided keys;
  - 401 → `'invalid'` with the status unchanged;
  - 503 → `'unavailable'`;
  - throw → `'error'`.
  The request body is exactly `{"credential":"cred"}`.
- **C6**: `signOutGoogle()` POSTs `/api/auth/logout` with the bearer and `{refreshToken}`, then clears the tokens and sets `signed-out`. It does the same when that fetch rejects. The birth-data, transcript and session-log KV keys seeded before are still present afterwards.
- **C7**: `google-session.ts` imports nothing outside `../platform` and `./types` (source check). A concurrent pair of 401s triggers ONE refresh POST (webTokenStore single-flight).

**Web (vitest; `platform/google` stubbed)**
- **W1 (the gate)**: signed-out → the page shows the eyebrow, title, email-only line and a button slot. There is no chart stage, no birth form, no chat panel and no session bar. The only `fetch` URLs recorded are under `/api/auth/` (none at all with empty KV).
- **W2**: The stub's `onCredential("cred")` with a 200 → the gate is replaced by the app (the `[data-slot="stage"]` and `[data-slot="side"]` slots render), and the masthead shows the email and a "Sign out" button.
- **W3**: A 401 on sign-in shows the `invalid` line and keeps the button. A 503 shows the unavailable message. `checking` shows "Opening the door…". `offline` shows "Try again", and pressing it re-runs `whoami`.
- **W4**: With `googleClientId()` null, the gate shows the unconfigured message, and `loadGoogleIdentity` and `renderGoogleButton` are never called.
- **W5**: Pressing "Sign out" returns to the gate, and the birth-data KV record is unchanged.
- **W6**: A language switch on the gate changes the copy to zh and re-renders the button with `locale:"zh"`. The `auth` namespace keeps en↔zh parity (existing parity test). Reduced motion → the gate card has no animation (the stylesheet check, as in dw-6's W8).
- **W7 (loader)**: Against a jsdom document, `loadGoogleIdentity()` called twice appends exactly ONE `script[src="https://accounts.google.com/gsi/client"]`. `renderGoogleButton` passes `client_id`, `auto_select:false`, `theme:"filled_black"`, `shape:"pill"` and `text:"signin_with"`.

**Guards and build**
- **G1**: The G10 guard passes and bites on a synthetic `accounts.google.com` in `auth/SignInScreen.tsx`. G1, G3 and G9 still pass. The color and text guards pass (no new colour literal outside `theme/tokens.ts`). `npm test` and `npm run typecheck` are green.
- **G2**: `GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com TOKENROUTER_API_KEY=dw12-sentinel-secret npm --workspace web-divination run build` → `dist/` contains `dw12-test.apps.googleusercontent.com` and does not contain `dw12-sentinel-secret`.
- **G3**: The CLAUDE.md amendments above are present: the backend paragraph, Commands, and rules 3 and 12.

**Real app** (throwaway Postgres on 127.0.0.1; backend started without `--env-file .env`, with that `DATABASE_URL`, a placeholder `GOOGLE_CLIENT_ID` and `CORS_ALLOW_ORIGINS` naming the Vite origin; Vite with the same placeholder id; any ports; driven in a real browser)
- **R1**: `/api/health` reports `db: "ok"`, and the log records the `DATABASE_URL` host as `127.0.0.1`. A fresh profile shows only the gate with the Google button iframe. The network log shows no request to `/api/chart` or `/api/divination/*`.
- **R2**: A bearer pair minted by the log-recorded script (`_upsert_user` + `_mint_bearer` on the throwaway db) is written to the three KV keys, and the page is reloaded. The app opens with saved birth data restored and the wheel drawn, and the masthead shows the email. A second reload stays signed in.
- **R3**: The access row is deleted from `sessions` and the page reloaded. The app still opens (refresh ran), and KV holds a new refresh token.
- **R4**: "Sign out" returns to the gate. Reloading stays on the gate. The minted refresh token now gets 401 from `/api/auth/token/refresh`. Signing in again (R2's script) shows the same birth data and session log as before.
- **R5**: The backend restarted without `DATABASE_URL` → the gate shows the unavailable message and no button path completes. A Vite build without any client id → the unconfigured message.
- **U1 [USER-INPUT: `GOOGLE_CLIENT_ID` for an OAuth web client with authorized JS origins `http://localhost:5173` and `http://localhost:5180`, and a Google account]**: With the real id in the root `.env` (shell-exported to the backend), Vite on :5173 or :5180, and the throwaway db:
  - a fresh browser sees only the gate;
  - "Sign in with Google" completes, and the app works (a chart and one Venus reply);
  - a reload stays signed in;
  - sign-out returns to the gate;
  - `users` holds exactly one row, for that email, and S6's dump contains no `sub`.
