# 04 implementing — dw-12-google-sign-in (worker #3)

Worktree `/Users/kaimao/Projects/astrology-wt/dw-12-google-sign-in`, branch `feature/dw-12-google-sign-in` (from `b308a92`). Fresh start (no boxes ticked).

## Step 0 — prep check (no commit; nothing changed)
- `git branch --show-current` → `feature/dw-12-google-sign-in`; `.env` → symlink to primary `.env`; `server/data/` holds only the three `*.se1` symlinks (no `.db`); `node_modules/@astrace/core -> ../../packages/core`; `env | grep -c DATABASE_URL` → `0`.
- `conda run -n astrology python -c "import google.auth, google.oauth2.id_token, requests; print(google.auth.__version__)"` → `2.56.2`.
- `initdb`, `pg_ctl`, `postgres`, `createdb` (and `psql`) present in `~/miniconda3/envs/astrology/bin`.
- Baseline before any edit: server `1129 passed, 50 skipped, 1 warning in 172.84s`; `npm test` → jest `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`, vitest `Test Files 19 passed (19)` / `Tests 163 passed (163)`; `npm run typecheck` clean. Confirmed server tests never load `.env` (no dotenv in conftest/app outside `app/examples`).

## Step 1 — verifier + single-importer pin
- NEW `server/app/accounts/google.py`: `GoogleUnconfigured`, `GoogleUnavailable`, `_make_cached_transport` (N7: memoizes 200 GETs to `*googleapis.com*` for 1 h; subclasses `google.auth.transport.Request`), `_default_transport` (one module-level `requests.Session`), `_verify_token` (the one `id_token.verify_oauth2_token` call), `verified_email` (TransportError → GoogleUnavailable checked before the generic branch; `email_verified is True` only).
- NEW `server/tests/test_google_auth.py` db-free half (S2 cases + 3 transport tests).
- `test_boundaries.py` APPENDED: `GOOGLE_AUTH_RE`, `test_only_google_module_imports_google_auth`, `test_google_auth_pin_bites_on_a_planted_import` (tmp app-shaped tree with a planted `from google.oauth2 import id_token` → importer list grows; regexes disjoint from GENAI_RE both ways).
- `server/requirements.txt` + `google-auth[requests]>=2.30`. CLAUDE.md rule 3 sentence.
- `pytest -q tests/test_google_auth.py tests/test_boundaries.py` → `37 passed in 0.51s`; full server suite → `1143 passed, 50 skipped, 1 warning in 111.93s`.
- Commit `8448c7c` (feat): verifier + pin.

## Step 2 — service and route
- `service.sign_in_google(credential)`: `_require_db()` first; `GoogleUnconfigured`/`GoogleUnavailable` → `AccountsUnavailable`; None → None; one connection: expired `sessions`/`refresh_tokens` cleanup, `_upsert_user`, `_mint_bearer`.
- `routes.GoogleBody` (`credential: Field(min_length=1, max_length=4096)`), `POST /api/auth/google` → native body, 401 `not signed in`, 503 `accounts unavailable`, no cookie.
- Tests appended to `test_google_auth.py`: S1 (no db → 503, recorder not called; `db.is_configured` patched True + no client id → 503), cert outage → 503, S3 (422 empty / 4097; 401 no Set-Cookie), S8 static AST scan of google.py + `sign_in_google` + `post_google` source with a planted-log bite, and a `@live` class S4–S7 + S8 caplog.
- CLAUDE.md rule 12: the Google paragraph (server bullets; the web token-store sentence lands in step 5).
- Db-free: `pytest -q tests/test_google_auth.py` → `20 passed, 5 skipped` (the 5 skips = the live cases).
- Throwaway cluster: `mktemp -d /tmp/dw12-pg.XXXX` → `/tmp/dw12-pg.mjr6`; `initdb -U astrace --auth=trust -E UTF8`; `pg_ctl -o "-p 54312 -c unix_socket_directories='' -c listen_addresses=127.0.0.1" start`; `createdb -h 127.0.0.1 -p 54312 -U astrace astrace_dw12`. Host 127.0.0.1 (never the `.env` URL).
- `DATABASE_URL=postgresql://astrace@127.0.0.1:54312/astrace_dw12 conda run -n astrology pytest tests/test_google_auth.py tests/test_auth_integration.py -v` → `31 passed, 1 warning`, zero skips; S4 `test_s4_happy_path_whoami_and_refresh PASSED`, S5 `test_s5_upsert_by_email_is_one_user PASSED`, S6 `test_s6_nothing_but_email_is_stored PASSED`, S7 `test_s7_logout_revokes_both_tokens PASSED`, S8 `test_s8_debug_logs_carry_no_sub_or_credential PASSED`; all six `test_auth_integration.py` cases PASSED.
- Cluster stopped (`pg_ctl stop`), dir deleted; `lsof -i :54312` → nothing.
- Full server suite (no DATABASE_URL): `1151 passed, 55 skipped, 1 warning in 125.30s`.
- Commit `3f9644e` (feat): service + route.

## Step 3 — core session + web token store
- NEW `packages/core/src/account/google-session.ts` (imports only `../platform`, `./types`): `GoogleSession{status,email}`, stable-snapshot channel (`getGoogleSession`/`subscribeGoogleSession`), `restoreGoogleSession` (one in-flight promise; no access token → `signed-out` with no request; whoami 200/401→clear/503/throw → signed-in/signed-out/unavailable/offline), `signInWithGoogle` (200 persist → 'ok'; 401 'invalid'; 503 'unavailable'; throw/other 'error'), `signOutGoogle` (logout with `{refreshToken}`, then clear regardless), `resetGoogleSessionForTests`. Barrel: one appended export block.
- core `platform/auth.ts`, `api.ts`: comments only ("absent on a cookie web surface; web-divination installs a bearer provider (dw-12)").
- NEW `web-divination/src/platform/auth.ts` `webTokenStore` (+ `hydrateWebTokens`, key consts): KV-synchronous hydrate at load, plain `fetch(apiUrl(...))` single-flight refresh (N1), complete-triple-only persist, `isNative()` false. `boot.ts` step 6 `configureAuthTokenProvider(webTokenStore)` + header comment; `boot.test.ts` gains the install assertion.
- NEW `web-divination/src/auth/core-google-session.test.ts`: C1–C7 + StrictMode shared restore + no-refresh-token-no-request.
- `npx vitest run src/auth src/platform` → `Test Files 4 passed (4)`, `Tests 31 passed (31)`. grep for service/sync/profile/identity-lifecycle imports in google-session.ts → no match (exit 1).
- **Deviation (type-only core fix):** the web typecheck now follows `@astrace/core/account`'s barrel (→ service → identity-lifecycle → … → `transit-day`), and web's `isolatedModules` rejected `transit-day/index.ts` re-exporting two interfaces as values (`TS1205` on `TransitEvidence`, `TransitQuote`). Fixed by marking both `type` — no runtime change; native jest unaffected.
- Root `npm test` → jest `90 passed` / `1069 passed`; vitest `Test Files 20 passed (20)`, `Tests 180 passed (180)`. `npm run typecheck` clean.
- Commit `a6bb555` (feat): core session + web token store.

## Step 4 — GIS loader, client-id plumbing, guards
- NEW `web-divination/src/platform/google.ts`: `GSI_SRC`, `googleClientId()`, `loadGoogleIdentity()` (one tag; forgets a failed one), `gsiLocale` (zh → `zh_CN`, N8), `renderGoogleButton` (`initialize({client_id, callback, auto_select:false})` then `renderButton(el, {theme:'filled_black', shape:'pill', size:'large', text:'signin_with', locale})`), `resetGoogleIdentityForTests`. NEW `google.test.ts` (W7): `Test Files 1 passed`, `Tests 7 passed`. `vi.stubEnv` works through the `define` in vitest.
- `vite.config.ts` → function form: `loadEnv(mode, repoRoot, 'GOOGLE_CLIENT_ID')`, `process.env.VITE_GOOGLE_CLIENT_ID ?? env.GOOGLE_CLIENT_ID ?? ''`, one `define` key, `css.include: [/log\.css/, /auth\.css/]`. NEW `src/vite-env.d.ts` (the one key's type). `.env.example` + commented `GOOGLE_CLIENT_ID` with the origins. CLAUDE.md Commands paragraph.
- `app-native/src/architecture.test.ts` APPENDED: G12 (`accounts.google.com`, comments stripped with a `://`-aware stripper, only in `platform/google.ts`; `index.html` has no `<script … src=http…>`), G13 (vite.config.ts source pin: no envDir/envPrefix, one loadEnv with prefix exactly `'GOOGLE_CLIENT_ID'`, no `...env`, exactly one define key `import.meta.env.VITE_GOOGLE_CLIENT_ID`, built from `env.GOOGLE_CLIENT_ID`, no `env[`), plus a synthetic self-check. First run failed G12 (the existing `text` stripper ate `//accounts.google.com` inside the string) → fixed with `stripCommentsKeepUrls`; then `Tests: 41 passed, 41 total`.
- Live bites: planted `web-divination/src/auth/SignInScreen.tsx` with the GSI URL → G12 red (`+ "web-divination/src/auth/SignInScreen.tsx"`), file removed; planted `envPrefix: ['VITE_']` in vite.config.ts → G13 red (`+ "envPrefix"`), file restored.
- G2 build: `GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com TOKENROUTER_API_KEY=dw12-sentinel-secret npm --workspace web-divination run build` → built; `grep -rl dw12-sentinel dist` empty; `grep -rl dw12-test dist` ALSO empty at this step — nothing imports `platform/google.ts` until step 5 mounts the gate, so the `define`d value is tree-shaken. The positive half is re-run at step 5 (recorded there). `dist/` removed (gitignored).
- Root `npm test` → jest `90 passed` / `1072 passed`; vitest `21 passed` / `187 passed`; typecheck clean.
- Commit `a6ef580` (feat): GIS loader + plumbing + G12/G13.

## Step 5 — gate, chip, i18n, styles, mount (`/frontend-design` loaded first)
- i18n `auth` namespace APPENDED after `bodies` in en.ts and zh.ts (eyebrow, title, body, buttonLabel, checking, invalid, unavailable, offline, loadFailed, unconfigured, retry, signOut, signedInAs).
- NEW `auth/useGoogleSession.ts`, `AuthGate.tsx` (one `restoreGoogleSession()` on mount; renders children only when `signed-in`, else `.shell` + `<Header/>` + `<SignInScreen/>`; keeps `<html lang>` in step), `SignInScreen.tsx` (DD11: eyebrow, display-serif title, body line, button slot `[data-slot="google-button"]`; state lines checking / invalid (above the button, `role=alert`) / unavailable + Try again / offline + Try again / unconfigured; a GIS load failure shows `loadFailed` + Try again — an addition not in DD11, see deviations; static twelve-tick SVG ring from a literal rotation list, `aria-hidden`), `AccountChip.tsx` (email 24ch ellipsis + `title`, "Sign out"; null unless signed in), `auth.css` (only `var(--…)`; 400 ms `threshold-rise`; email hidden ≤640px; reduced-motion block kills the card animation and transitions).
- `app/Header.tsx`: `.masthead__tools` wraps `<AccountChip/>` + the language toggle. `main.tsx`: `<AuthGate><App/></AuthGate>`. CLAUDE.md: backend paragraph EXCEPT clause; rule 12 web token-store sentence.
- Tests: `AuthGate.test.tsx` (W1 empty KV → threshold, no stage/side/form/.chat/.log-bar, `fetch` never called; W1 dead pair → only `/api/auth/` URLs; W2 credential → app slots + `.chat`/`.log-bar`/form present, email with title, Sign out, body `{"credential":"cred"}`; W3 401 invalid line + button kept, 503 unavailable + Try again, checking text, offline → Try again re-runs whoami (count 1 → 2) → app; W5 sign out → gate, logout carried bearer + `{refreshToken}`, birth KV unchanged). `SignInScreen.test.tsx` (W4 unconfigured, `loadGoogleIdentity`/`renderGoogleButton` spies never called, no script, no fetch; W6 zh copy + GIS `locale:"zh_CN"` + `renderGoogleButton(…, 'zh')` + `<html lang=zh-CN>`; load-failure retry; W6 reduced-motion stylesheet + no colour literal; ring aria-hidden with 12 lines).
- First typecheck: 6 × `TS2550 Property 'at' does not exist` (web lib is ES2020) in the two test files → replaced `.at(-1)!` with `.slice(-1)[0]!`.
- `npx vitest run src/auth src/i18n.test.ts` → `Test Files 4 passed (4)`, `Tests 34 passed (34)` (parity test included).
- `grep -rnE "#[0-9a-fA-F]{3,8}\b|rgb\(" web-divination/src/auth` → nothing. `grep -n "dw-12" CLAUDE.md` → lines 33 (backend paragraph), 61 (Commands), 237 (rule 3), 389 (rule 12).
- `git diff feature/divination_web --stat`: 26 files; app-native only `architecture.test.ts`; nothing under `web-divination/src/{chat,log,chart}` or `server/app/{divination,main.py,models.py,db}`. Other core touch: the type-only `transit-day/index.ts` fix (step 3).
- G2 positive half (re-run from step 4): `GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com TOKENROUTER_API_KEY=dw12-sentinel-secret npm --workspace web-divination run build` → `✓ built in 134ms`; `grep -rl dw12-test dist` → `web-divination/dist/assets/index-C2MGEyZ8.js`; `grep -rl dw12-sentinel dist` → nothing; dist `index.html` has only `<script type="module" crossorigin src="/assets/index-C2MGEyZ8.js">`. dist removed.
- Root: jest `Test Suites: 90 passed` / `Tests: 1072 passed`; vitest `Test Files 23 passed (23)` / `Tests 199 passed (199)`; typecheck 0 errors.
- Commit `a5cb27a` (feat): gate, chip, i18n, styles, mount. Steps 1–5 done → validating.
