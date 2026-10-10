# rn-forced-signin — 19 accepting (after the 2026-09-30 rework)

This is a fresh-context acceptance of the worktree `/Users/kaimao/Projects/astrology-wt/rn-forced-signin`, branch `feature/rn-forced-signin`, HEAD `f17ba8b`. The rework commits are `159ca81` (feat) and `f17ba8b` (docs) on top of `c828f73`. The spec is `pipeline/specs/rn-forced-signin.md` (Acceptance Criteria, as amended).

## Scope of the diff

`git diff c828f73..HEAD --stat`:
- Changed: `.env.example`, `CLAUDE.md`, `app-native/app.config.ts`, `app-native/eas.json`, `app-native/src/app-config.test.ts`, the `auth.noEmail` string in `i18n/en.ts` and `i18n/zh.ts` ("Astrace Dev" → "Astrace"), a comment in `native-guards.test.ts`, `docs/ARCHITECTURE.md`, `server/tests/test_native_signin.py` and `server/tests/test_native_signin_live.py`.
- Untouched: no file under `server/app/`, `packages/` or `web-divination/`, and no app-native runtime source except those two i18n strings.

So unchanged criteria keep their verdicts from 13-accepting, on green suites plus the spot-checks below.

## Suites (keys blanked: TOKENROUTER/ANTHROPIC/OPENAI/LLM/GEMINI/GOOGLE_API_KEY)

- `npm test` (root) → jest `Test Suites: 93 passed, 93 total` / `Tests: 1141 passed, 1141 total`; vitest `Test Files 48 passed (48)` / `Tests 447 passed (447)`; exit=0
- `npm run typecheck` → app-native and web-divination `tsc --noEmit`, exit=0
- db-less: `env DATABASE_URL= TEST_DATABASE_URL= WEB_DATABASE_URL= TEST_WEB_DATABASE_URL= <keys blank> conda run -n astrology pytest -q` → `1504 passed, 124 skipped, 1 warning in 211.26s`, exit=0
- Live main db. Throwaway cluster 127.0.0.1:54317, my own databases `acc19_main`, `acc19_web` and `acc19_mig`, all dropped afterwards. Command: `DATABASE_URL=TEST_DATABASE_URL=…/acc19_main WEB_DATABASE_URL= TEST_WEB_DATABASE_URL= pytest tests/test_native_signin_live.py tests/test_auth_integration.py tests/test_profiles_integration.py tests/test_native_tokens.py tests/test_native_signin.py -q -rs` → `51 passed, 1 warning in 1.12s` (0 skipped)
- Live both test dbs: `DATABASE_URL= WEB_DATABASE_URL= TEST_DATABASE_URL=…/acc19_main TEST_WEB_DATABASE_URL=…/acc19_web pytest tests/test_route_auth.py tests/test_web_accounts_live.py -q -rs` → `70 passed, 1 warning in 2.70s` (0 skipped)
- Migrations on a fresh db: `DATABASE_URL=TEST_DATABASE_URL=…/acc19_mig pytest tests/test_db_integration.py -q -rs` → `5 passed in 0.46s`

## Rework criteria, re-graded

### S2

Run `-v -k "s2 or d2"` on live main. All of these PASSED:
- `test_s2_native_google_passes_the_parsed_ios_audience_list`
- `test_s2_server_accepts_every_trimmed_entry_with_no_count_limit`: `"a…, b…,,c…"` → `ios_client_ids() == [a,b,c]`, and the fake receives `("tok", [a,b,c])`
- `test_s2_web_path_still_passes_google_client_id_as_a_string`
- `test_s2_empty_audience_list_is_unconfigured`
- `test_s2_route_rejects_unverified_google_claims[string-true|false|no-email]`
- `test_s2_google_cert_outage_is_503`

`test_google_auth.py` is green in the db-less run.

### D2

`test_d2_apple_linked_user_needs_a_fresh_reauthorization` PASSED. It checks:
- no body → 422 `apple reauthorization required`, user kept
- foreign sub → 403, user kept, no `_post`
- valid → `/auth/token` with `grant_type=authorization_code`, the code, `client_id=com.astrace.app.dev` and `client_secret`, then `/auth/revoke` with `token=apple-refresh-SENTINEL` and `token_type_hint=refresh_token` → 204
- the user is gone, and sessions, refresh_tokens, profiles, journal and apple_identities are all 0

`test_d2_prod_bundle_token_revokes_with_its_own_client_id` PASSED. With `aud=com.astrace.app`, both forms carry `client_id=com.astrace.app`, and the `client_secret` JWT's `sub` is `com.astrace.app`.

Plant probe: I hard-coded `"com.astrace.app.dev"` in place of `identity.audience` at `server/app/accounts/service.py:260` and re-ran `-k d2`. Result: `FAILED …test_d2_prod_bundle_token_revokes_with_its_own_client_id` / `1 failed, 1 passed`. I restored with `git checkout app/accounts/service.py`, and the tree is clean.

### B1

`APP_VARIANT=<v> GOOGLE_IOS_CLIENT_ID=<fake> npx expo config --json --type public`, fields extracted:

```
== prod [222-prod.apps.googleusercontent.com,111-dev.apps.googleusercontent.com]
com.astrace.app usesAppleSignIn= True extra.appleSignIn= True scheme= com.googleusercontent.apps.222-prod extra.googleIosClientId= 222-prod.apps.googleusercontent.com
== prod [333-one.apps.googleusercontent.com]
com.astrace.app usesAppleSignIn= True extra.appleSignIn= True scheme= com.googleusercontent.apps.333-one extra.googleIosClientId= 333-one.apps.googleusercontent.com
== dev [222-prod.apps.googleusercontent.com,111-dev.apps.googleusercontent.com]
com.astrace.app.dev usesAppleSignIn= True extra.appleSignIn= True scheme= com.googleusercontent.apps.111-dev extra.googleIosClientId= 111-dev.apps.googleusercontent.com
== dev [333-one.apps.googleusercontent.com]
com.astrace.app.dev usesAppleSignIn= True extra.appleSignIn= True scheme= com.googleusercontent.apps.333-one extra.googleIosClientId= 333-one.apps.googleusercontent.com
== prod [3 entries]
Error: Error reading Expo config at …/app-native/app.config.ts:
GOOGLE_IOS_CLIENT_ID has 3 entries; a build expects at most two, written "<prod id>,<dev id>" (production first), or one id for both variants.
exit=1
```

`app-config.test.ts` passes inside the 1141 jest tests. I read it, and it pins every edge the spec lists:
- prod takes entry 1, and dev takes entry 2
- a single entry is used by both variants
- spaces change nothing
- `,dev` and `prod,` empty slots are handled per variant
- a malformed slot affects that variant only, and Apple stays on
- unset in both the shell and the stubbed root reader, or `","`, gives no Google, and Apple stays on
- three entries throw with `3` in the message and none of the ids
- no `VARIANTS` entry has a `signIn` key
- no `EXPO_PUBLIC_GOOGLE` or `GOOGLE_IOS_CLIENT_IDS` anywhere under app-native

My own `grep -rlE "EXPO_PUBLIC_GOOGLE|GOOGLE_IOS_CLIENT_IDS" app-native --exclude-dir={node_modules,ios,android}` returns no hits (exit 1). That includes `eas.json`.

### B2

`eas.json` read directly:
- `testflight`: `extends: production`, `distribution: store`, `environment: production`, `autoIncrement`, `env {APP_VARIANT: prod, EXPO_PUBLIC_API_BASE: https://astrace.onrender.com}`, `channel: production`.
- `production`: `environment: production`.
- `development`: `environment: development`, dev at `http://172.16.21.6:8000`.
- `preview`: `environment: preview`, dev at `https://astrology-dev.onrender.com`.

No profile `env` carries a Google id. The jest `B2 — eas.json` block pins all of this and passes.

### U1

Read in `src/account/sign-in-gate.test.tsx`, all inside the green jest run:
- signed-out: wordmark, Apple button and Google button; no rail, chart, settings or TextInput
- checking: wordmark only
- Apple unavailable: the button is absent
- opt-out path: `appleSignIn:false` and no `googleIosClientId` → both buttons disabled with their notes, and presses call no provider and send no request

Note, not a failure: that last test is still titled "the prod build (both flags off)". The spec now says no shipped variant does this, so the label is stale and the behaviour is right.

## Spot-checks of unchanged criteria on HEAD

- **R1**: `pytest tests/test_boundaries.py -v -k every_route` → `test_every_route_requires_a_bearer PASSED`. `test_r5_removed_routes_are_gone[GET-/openapi.json] PASSED`. `test_route_auth.py` is green in both the db-less and the live runs.
- **C1**: `npx jest -t "C1|U3" --verbose` → `✓ whoami 401 + refresh 401 → one bare refresh POST, signed-out, onSessionEnded once, under 1 s`.
- **U3**: same run → `✓ zh renders the zh copy`, `✓ Reduce Motion: no withTiming on the gate; motion on: the buttons fade in` and `✓ the Apple button is WHITE on the dark ground and BLACK on light`. The i18n parity suite is green in the full jest run.
- **A2**: I ran my own backends: `uvicorn app.main:app --app-dir server --host 127.0.0.1`, keys blanked, no `--env-file`. Valid birth-data bodies.

```
:8021  DATABASE_URL=…/acc19_main  WEB_DATABASE_URL=
GET /api/health -> {"status":"ok","db":"ok","webDb":"unconfigured","ephemeris":"ok"} [200]
POST /api/chart -> {"detail":"not signed in"} [401]
POST /api/transits -> {"detail":"not signed in"} [401]
POST /api/analysis -> {"detail":"not signed in"} [401]
POST /api/ask/fitness -> {"detail":"not signed in"} [401]
GET /api/analysis/card/x -> {"detail":"not signed in"} [401]
GET /openapi.json -> {"detail":"Not Found"} [404]
:8022  DATABASE_URL=  WEB_DATABASE_URL=
GET /api/health -> {"status":"ok","db":"unconfigured","webDb":"unconfigured","ephemeris":"ok"} [200]
POST /api/chart -> {"detail":"accounts unavailable"} [503]
POST /api/transits -> {"detail":"accounts unavailable"} [503]
POST /api/analysis -> {"detail":"accounts unavailable"} [503]
POST /api/ask/fitness -> {"detail":"accounts unavailable"} [503]
GET /api/analysis/card/x -> {"detail":"accounts unavailable"} [503]
GET /openapi.json -> {"detail":"Not Found"} [404]
```

Both backends were stopped afterwards (no listener on 8021/8022). I touched no `.env` file, no simulator, no other port and nothing under `app-native/ios`.

## Per-criterion verdict

**Server: sign-in**
- S1: PASS (unchanged; suites green)
- S2: PASS (re-graded, rework)
- S3: PASS (unchanged)
- S4: PASS (unchanged; live 0 skipped)
- S5: PASS (unchanged)
- S6: PASS (unchanged)
- S7: PASS (unchanged)

**Server: deletion and revocation**
- D1: PASS (unchanged)
- D2: PASS (re-graded, rework; the prod-aud case passes, and my plant shows the test catches a hard-coded client id)
- D3: PASS (unchanged)
- D4: PASS (unchanged)

**Server: route auth and removals**
- R1: PASS (spot-checked)
- R1b, R2, R3, R4, R5, R6, R7, A4′: PASS (unchanged; live and db-less suites green, 0 skipped live)

**Core and app**
- C1: PASS (spot-checked)
- C2 to C9: PASS (unchanged; jest green)

**Gate UI**
- U1: PASS (re-graded; stale test title noted)
- U2: PASS (the `noEmail` copy changed and the test reads `en.auth.noEmail`; green)
- U3: PASS (spot-checked)
- U4: PASS (unchanged)
- G1: PASS (guards green in jest)

**Build config**
- B1: PASS (re-graded, rework)
- B2: PASS (re-graded, rework)

**Real app**
- A1: PASS (unchanged from 13-accepting; no app runtime code changed except one i18n string)
- A2: PASS (spot-checked by curl)

**LIVE**
- L1: NOT RUN — LIVE
- L2: NOT RUN — LIVE
- L3: NOT RUN — LIVE
- L4: NOT RUN — LIVE
- L5: NOT RUN — LIVE (post-rollout, non-gating)
- L6: NOT RUN — LIVE

Every non-LIVE criterion passes.

Transition: accepting → (awaiting LIVE L1–L4, L6)
