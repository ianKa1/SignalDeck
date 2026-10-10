# 13 — accepting (fresh-context acceptance check)

Scope: exactly the Acceptance Criteria section of `pipeline/specs/rn-forced-signin.md`.
Code under test: worktree `/Users/kaimao/Projects/astrology-wt/rn-forced-signin`,
branch `feature/rn-forced-signin`, HEAD `c828f73` (`git diff dev...HEAD`: 122 files).
No code edited. Mutation probes were restored with `git checkout`, and `git status --short` was empty afterwards.
No `.env` file was read. Every server and test process ran with the provider keys blanked
and with `DATABASE_URL` / `WEB_DATABASE_URL` set explicitly. The databases were fresh
throwaway databases I created on 127.0.0.1:54317 (`acc_*`) and dropped at the end.

## Commands and verbatim results

```
# worktree root
npm test            → app-native: Test Suites: 93 passed, 93 total / Tests: 1134 passed, 1134 total
                      web-divination: Test Files 48 passed (48) / Tests 447 passed (447)   EXIT 0
npm run typecheck   → app-native tsc --noEmit, web-divination tsc --noEmit                  EXIT 0

# server, db-less (DATABASE_URL= WEB_DATABASE_URL=)
pytest -q -rs       → 1503 passed, 123 skipped, 1 warning in 123.48s                         EXIT 0
                      (the skips are the live halves, run below)

# server, live-PG, feature suites (DATABASE_URL=TEST_DATABASE_URL=…/acc_main,
#   TEST_WEB_DATABASE_URL=…/acc_web, WEB_DATABASE_URL=)
pytest -rs -v test_native_signin_live test_native_signin test_apple test_route_auth
   test_db_integration test_auth_integration test_profiles_integration test_web_accounts
   test_web_accounts_live test_planet_chat_auth test_google_auth test_native_tokens
   test_auth_api test_accounts_tokens
                    → 257 passed, 1 warning in 3.31s   (0 skipped)

# server, live-PG, FULL suite (same env)
                    → 24 failed, 1591 passed, 11 skipped
# dev (git archive dev server → scratch; same env, own fresh dbs)
                    → 36 failed, 1498 passed, 11 skipped
```

Branch-vs-dev comparison of the full live run: 23 of the 24 branch failures also fail on dev:
test_analysis_api ×3, test_ask_fitness ×3, test_card_store_pg, test_cors ×2,
test_explain_store_pg, test_planet_chat_persona ×5, roster, summary ×5, turn, and
test_transit_today_api. Dev's 12 extra failures come from the server-only export, which has no
`packages/` for the parity and rename guards, and from removed OTP tests.
The 24th failure, `test_analysis_api_pg::test_backends_serve_byte_equal_bodies`, is not in dev's
list. Run alone on a fresh db, it passes on both the branch and dev, twice each, and
dev's own full run failed the sibling `test_analysis_api::test_happy_path_wire_shape`.
It is the known shared-row content-cache class and order-dependent, not this feature.

### Mutation probes (each restored; tree clean afterwards)

| plant | suite | result |
|---|---|---|
| `import * as _Probe from 'expo-apple-authentication'` appended to `account/SignInGate.tsx` | native-guards | `✕ the sign-in SDKs are named by exactly one module` (1 failed / 36) |
| `import 'expo-dev-client'` appended to `platform/sign-in.ts` | native-guards | `✕ the sign-in path names no dev client, no __DEV__ and no local address` (1 failed) |
| `import jwt` appended to `app/accounts/service.py` | test_boundaries -k pyjwt | 1 failed |
| `from . import google as _g` appended to `app/accounts/gate.py` | test_boundaries -k b4 | 1 failed |
| `@app.post('/api/probe-open')` appended to `app/main.py` | test_boundaries -k every_route_requires | 1 failed |
| after restore | -k "pyjwt or b4 or every_route_requires or s5_every_planet" | 4 passed |

### Independent S4→S5→S6 probe (scratch script, fresh db, no per-test cleanup)

```
S4 google 200 / token len 43 appleLinked False / whoami {'email': 'Rn.Tester@Example.com', 'appleLinked': False}
S4 refresh 200 / S4 second 200
S5 apple1 200 True / same sub no email → relay1@privaterelay.appleid.com
S5 new sub no email 401 {'detail': 'apple email missing'} / apple2 200 rn.tester@example.com True
users [('relay1@privaterelay.appleid.com',), ('rn.tester@example.com',)]
apple_identities hash1 074f58c8…e32f == sha256("apple:apple-SENTINEL-1")
db leaks: none / SENTINEL anywhere in db: False / users columns ['id','email','created_at']
DEBUG log leaks: none / SENTINEL in log: False
```

### R6 on an empty db (`acc_mig`)

```
first run applied: ['001_identity', … '014_drop_email_sign_in', '015_apple_identities']  (15)
second run applied: []
login_tokens False, otp_codes False, sessions True, refresh_tokens True, apple_identities True
```

### Build config (from app-native/, fake id)

```
APP_VARIANT=dev GOOGLE_IOS_CLIENT_ID="123-abc…,999-zzz…" npx expo config --type public --json
  bundleIdentifier com.astrace.app.dev / usesAppleSignIn True
  extra.googleIosClientId 123-abc.apps.googleusercontent.com / extra.appleSignIn True
  plugin ['@react-native-google-signin/google-signin', {'iosUrlScheme': 'com.googleusercontent.apps.123-abc'}]
APP_VARIANT=prod GOOGLE_IOS_CLIENT_ID=123-abc… npx expo config …
  bundleIdentifier com.astrace.app / usesAppleSignIn None / extra.googleIosClientId None
  extra.appleSignIn False / 'com.googleusercontent.apps' anywhere in config: False
grep -rl "EXPO_PUBLIC_GOOGLE|GOOGLE_IOS_CLIENT_IDS" app-native (excl node_modules, ios, android)
  → app-native/src/app-config.test.ts only (the B2 guard's own negative regex)
```

### A2 curl (own backends, from the worktree root)

```
:8019  DATABASE_URL=…/acc_curl  WEB_DATABASE_URL=
GET /api/health -> 200 {"status":"ok","db":"ok","webDb":"unconfigured","ephemeris":"ok"}
POST /api/chart -> 401 {"detail":"not signed in"}
POST /api/transits -> 401 / POST /api/analysis -> 401 / POST /api/ask/fitness -> 401
GET /api/analysis/card/x -> 401 {"detail":"not signed in"}
PUT /api/profiles/traveler (valid body) -> 401; GET whoami -> 401; DELETE account -> 401
:8020  DATABASE_URL=  WEB_DATABASE_URL=
GET /api/health -> 200 {"status":"ok","db":"unconfigured","webDb":"unconfigured","ephemeris":"ok"}
POST /api/chart, /api/transits, /api/analysis, /api/ask/fitness -> 503 {"detail":"accounts unavailable"}
GET /api/analysis/card/x -> 503
both: request-link, verify, otp/request, otp/verify, native-landing, /openapi.json, /docs, /redoc -> 404
both: Set-Cookie on /api/auth/{whoami,logout,token/refresh,google} -> 0
```
Both backends were stopped afterwards; I stopped only the processes I started.

## Per-criterion verdict

**Server: sign-in**
- **S1 PASS**: `test_s1_dormant…` covers both routes → 503 `accounts unavailable` with recorder fakes uncalled. `test_s1_unconfigured_provider_is_503` patches `db.is_configured` with the env unset. `test_s1_bad_bodies…` covers the empty and 4097-character tokens and the 15-character nonce → 422. Curl on :8019/:8020 agrees.
- **S2 PASS**: the list `[a, b]` reaches the fake. String `"true"`, `False` and a missing email → 401. The web path passes the string `GOOGLE_CLIENT_ID`, and `test_google_auth.py` is green and unchanged.
- **S3 PASS**: `test_apple.py` covers the identity, the boolean `email_verified`, `email=None`, and `None` for a nonce mismatch, a missing nonce or an unverified email. A JWKS error → `AppleUnavailable`, and the route answers 503 with audiences equal to the parsed list.
- **S4 PASS**: live test plus my probe. 200, a 43-character access token, a parseable expiry, `appleLinked:false`, whoami returns the email, refresh rotates, and there is one users row.
- **S5 PASS**: live test plus my probe. The hash equals sha256("apple:apple-SENTINEL-1"). Reuse with no email works, a new sub with no email → 401 and no row, and the cross-provider link sets whoami `appleLinked:true`.
- **S6 PASS**: my un-cleaned S4+S5 dump has no sentinel, token or nonce. Token columns are 64-hex (live test). `users` = `id, email, created_at`.
- **S7 PASS**: the source scan (`test_s7_*`, which also asserts no logging at all in the sign-in modules) passes. The DEBUG caplog in the live test and in my probe holds no sentinel.

**Server: deletion and revocation**
- **D1 PASS**: 204, and the sessions, refresh_tokens, profiles, journal and apple rows are all 0. `_post` was never called.
- **D2 PASS**: no body → 422 `apple reauthorization required`. A foreign sub → 403. Valid → token exchange (`grant_type`, `code`, `client_id=com.astrace.app.dev`, `client_secret`), then revoke (`token` = the fake refresh, `token_type_hint=refresh_token`) → 204, and the rows are gone.
- **D3 PASS**: a revoke failure → 502 `apple revoke failed`, user kept. `APPLE_KEY_ID` unset → 503, user kept, no `_post`.
- **D4 PASS**: `test_client_secret_is_an_es256_jwt_apple_accepts` uses a P-256 PEM with `\n` escapes. It checks ES256, `kid`, `iss`, `sub`, `aud`, and exp − iat ≤ 300.

**Server: route auth and removals**
- **R1 PASS**: the pin's three sets equal D8 exactly (8 + 14 + 12 = 34), are disjoint and have no stale entries. It plants an open POST, an included-router route and `/api/web/x`. My own planted route in `main.py` turns it red. No `/openapi.json` route is served (404 by curl). The dw-18 S5 pin is green.
- **R1b PASS**: 5 native routes → 503 with no main db and 401 live. 7 web routes → 503 with no web db and 401 live. No stubs (`_no_override`). The PUT checks are also confirmed by curl with a valid body.
- **R2 PASS**: 9 routes → 503 dormant with the full spy set at zero calls, and 401 live for no bearer, garbage and a web token. Note: the live half spies only `compute_transits`, `check_bounded` and `get_image`. The dormant half spies all four named targets.
- **R3 PASS**: 401 with no bearer, 200 native, 200 web, 503 only with both unset (one db set → 401). A bad body with no bearer → 401.
- **R4 PASS**: 200 `image/png`, `private, max-age=31536000, immutable`; none → 401.
- **R5 PASS**: the removed routes and `/openapi.json` → 404 (test + curl). No `Set-Cookie`. `accounts/email.py` is absent and no `app/` file names `resend`. `.env.example` names the five new keys with empty values and none of `RESEND_API_KEY`, `EMAIL_FROM` or `APP_BASE_URL`.
- **R6 PASS**: on an empty db the 15 migrations apply and a second run applies nothing. The tables are as required. The PyJWT and B4 pins pass, and both turned red on my plants.
- **R7 PASS (with note)**: `test_web_accounts_live`, `test_planet_chat_auth` and `test_google_auth` pass live and are unchanged; `test_web_accounts` changes only at A4 → A4′. Web vitest passes: 48 files, 447 tests. Edits beyond the two named exceptions:
  - the inverted "401 IS reported" case and the dropped `{auth:true}` arguments, both sanctioned as N1 in 07-planning;
  - two `await signedIn()` preconditions, which D15 forces (spec line 65: google-session acts only while signed in) and which leave every assertion unchanged.
  The new `web-session-scope.test.ts` covers the required case (web signed out, native `onSessionEnded` 0).
- **A4′ PASS**: `{credential}` → 422. With `DATABASE_URL` unset and a dummy web URL → 503, with the spies at zero calls. `sign_in_google` exists, and I checked that its source contains neither `web` nor `connect_web`.

**Core and app**
- **C1 PASS**: `token-store.test.ts` sends one bare refresh POST, ends signed-out with `onSessionEnded` ×1, in under 1 s. The old-store reproduction (`restore hung`, 1002 ms) is recorded in 08-implementing.md (Step 10).
- **C2 PASS**: with a 50 ms Keychain, nothing is sent before the load, the whoami carries the stored bearer, and `signed-out` is never emitted.
- **C3 PASS**: an empty store gives 0 requests. 503 → `unavailable` and a throw → `offline`, with tokens kept in both cases.
- **C4 PASS**: exact bodies, the triple persisted, and `appleLinked` set. 401/invalid, no-email, 503 and throw are each mapped.
- **C5 PASS**: the bearer is sent on the three postJson paths and on `/api/chart`. A final 401 ends the session once, with web google-session status unchanged. With no native session, nothing ends. A sync pull or PUT 401 ends the session once.
- **C6 PASS**: all four cases hold, and the conflict exports are gone from the barrel and the types.
- **C7 PASS**: the logout POST carries `{refreshToken}` and the bearer even when fetch rejects. Only the lang and ground keys remain, the secure store is empty, both image caches are cleared, Google `signOut` is called, and the app reloads once. An anonymous device is not wiped.
- **C8 PASS**: not Apple-linked → a body-less DELETE. Apple-linked → the Apple mock is called, then the body is `{apple:{…}}`. A cancelled Apple run sends no request and keeps the confirm. 502 → the note and no wipe. 204 → the session ends (C7 wipe).
- **C9 PASS**: all five sites (gallery, detail, PinnedHeader, CardStage, DeckCard) have header tests, as does `prefetchImages`. The bare-uri guard passes and bites in its self-check, and a grep finds no `source={{ uri` outside `platform/`.

**Gate UI**
- **U1 PASS**, **U2 PASS**, **U3 PASS**: `sign-in-gate.test.tsx` asserts each item as worded, including that the prod flags disable both buttons with no mock or request, and that the Apple button is DISABLED rather than absent when `appleSignIn` is false and the device reports available.
- **U4 PASS**: email, Sign out and Delete account… are shown. The four files are absent, and no email/OTP input exists (test + grep; only comments mention them).
- **G1 PASS**: architecture, colour, text-variant, paint and type suites are green. The census has a re-pin note (§T), the new `signInFill`/`signInInk` tokens are achromatic and live in `theme/tokens.ts`, and the CLAUDE.md amendments are present. Both SDK guards turned red on my plants.

**Build config**
- **B1 PASS (with note)**: the dev and prod `expo config` outputs are exactly as required, and the stubbed-reader jest case passes. The forbidden-name grep hits only `app-config.test.ts`, the B2 guard's own `/EXPO_PUBLIC_GOOGLE|GOOGLE_IOS_CLIENT_IDS/` regex, which asserts the names are absent. No config, `eas.json` or source file uses them.
- **B2 PASS**: `testflight` has `distribution: store`, `APP_VARIANT: dev`, the dev-Render base, `environment: preview` and channel `preview`. `development` and `preview` name their environments. No profile `env` holds a Google id. Pinned by jest.

**Real app**
- **A1 PASS**: from the coordinator's device evidence, read by me. In `a1-t3.png` the opening ("READ THE UNIVERSE") sits behind the dev-launcher first-run sheet. `a1-gate.png` shows only the wordmark, a white Apple button and a white Google button (plus the dev-client's Tools bubble). `a1-describe-all.json` lists Application, Heading "Astrace", the two buttons and the dev-launcher gear/Tools, with no tab, chart or settings element. The simulator was not touched.
- **A2 PASS**: curl results above.

**LIVE**
- **L1**: NOT RUN — LIVE (deferred to user)
- **L2**: NOT RUN — LIVE (deferred to user)
- **L3**: NOT RUN — LIVE (deferred to user)
- **L4**: NOT RUN — LIVE (deferred to user)
- **L5**: NOT RUN — LIVE (deferred to user)

Every non-LIVE criterion passes.

Transition: accepting → (awaiting LIVE L1–L5)
