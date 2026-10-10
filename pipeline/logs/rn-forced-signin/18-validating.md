# rn-forced-signin — 18 validating (rework, 2026-09-30)

Branch `feature/rn-forced-signin` at `f17ba8b` (code at `159ca81`). Throwaway Postgres only:
`127.0.0.1:54317` (data dir `<scratchpad>/rfs/rfspg`, already running — `pg_ctl status`: "server is running (PID: 90952)").
Every server process: `DATABASE_URL`/`WEB_DATABASE_URL` set explicitly; `TOKENROUTER_API_KEY ANTHROPIC_API_KEY OPENAI_API_KEY LLM_API_KEY GEMINI_API_KEY GOOGLE_API_KEY` blanked. No Neon URL, no simulator, no ports 8000/8081/8082/5173/54320.

## Client suites (worktree root)

- `npm test` → jest `Test Suites: 93 passed, 93 total` / `Tests: 1141 passed, 1141 total`; vitest `Test Files 48 passed (48)` / `Tests 447 passed (447)`; exit 0 (run after the code commit and again after the docs commit, same result).
- `npm run typecheck` → app-native and web-divination `tsc --noEmit`, exit 0.

## Server

- db-less: `env DATABASE_URL= TEST_DATABASE_URL= WEB_DATABASE_URL= TEST_WEB_DATABASE_URL= <keys blank> conda run -n astrology pytest -q` → `1504 passed, 124 skipped, 1 warning in 115.00s` (was 1503/123: +1 S2 case, +1 skipped live D2 case).
- live main db: `env <keys blank> DATABASE_URL=…/rfs_main TEST_DATABASE_URL=…/rfs_main WEB_DATABASE_URL= TEST_WEB_DATABASE_URL= conda run -n astrology pytest tests/test_native_signin_live.py tests/test_auth_integration.py tests/test_profiles_integration.py tests/test_native_tokens.py tests/test_native_signin.py -q -rs` → `51 passed, 1 warning in 1.11s` (0 skipped; includes the new `test_d2_prod_bundle_token_revokes_with_its_own_client_id`).
- live both test dbs: `env <keys blank> DATABASE_URL= WEB_DATABASE_URL= TEST_DATABASE_URL=…/rfs_main TEST_WEB_DATABASE_URL=…/rfs_web conda run -n astrology pytest tests/test_route_auth.py tests/test_web_accounts_live.py -q -rs` → `70 passed, 1 warning in 1.83s` (0 skipped).
- migrations on a fresh db: `drop/create database rfs_mig`, then `DATABASE_URL=TEST_DATABASE_URL=…/rfs_mig pytest tests/test_db_integration.py -q -rs` → `5 passed in 0.52s`.

## B1 — `npx expo config --json --type public` (app-native, FAKE ids)

`APP_VARIANT=<v> GOOGLE_IOS_CLIENT_ID=<value> npx expo config --json --type public`, fields extracted:

```
== prod [222-prod.apps.googleusercontent.com,111-dev.apps.googleusercontent.com]
com.astrace.app usesAppleSignIn= True appleSignIn= True scheme= com.googleusercontent.apps.222-prod extraId= 222-prod.apps.googleusercontent.com
== prod [333-one.apps.googleusercontent.com]
com.astrace.app usesAppleSignIn= True appleSignIn= True scheme= com.googleusercontent.apps.333-one extraId= 333-one.apps.googleusercontent.com
== prod [,111-dev.apps.googleusercontent.com]
com.astrace.app usesAppleSignIn= True appleSignIn= True scheme= None extraId= None
== prod [222-prod.apps.googleusercontent.com,]
com.astrace.app usesAppleSignIn= True appleSignIn= True scheme= com.googleusercontent.apps.222-prod extraId= 222-prod.apps.googleusercontent.com
== dev [222-prod.apps.googleusercontent.com,111-dev.apps.googleusercontent.com]
com.astrace.app.dev usesAppleSignIn= True appleSignIn= True scheme= com.googleusercontent.apps.111-dev extraId= 111-dev.apps.googleusercontent.com
== dev [333-one.apps.googleusercontent.com]
com.astrace.app.dev usesAppleSignIn= True appleSignIn= True scheme= com.googleusercontent.apps.333-one extraId= 333-one.apps.googleusercontent.com
== dev [,111-dev.apps.googleusercontent.com]
com.astrace.app.dev usesAppleSignIn= True appleSignIn= True scheme= com.googleusercontent.apps.111-dev extraId= 111-dev.apps.googleusercontent.com
== dev [222-prod.apps.googleusercontent.com,]
com.astrace.app.dev usesAppleSignIn= True appleSignIn= True scheme= None extraId= None
== prod [3 entries]
Error: Error reading Expo config at /Users/kaimao/Projects/astrology-wt/rn-forced-signin/app-native/app.config.ts:
GOOGLE_IOS_CLIENT_ID has 3 entries; a build expects at most two, written "<prod id>,<dev id>" (production first), or one id for both variants.
exit=1
```

Root-`.env` path (shell var unset; only booleans printed, no value): `prod: root-.env google configured = True | apple = True`; `dev: root-.env google configured = True | apple = True` — the user's current root `.env` value parses under the new rule (≤ 2 entries, the slot for each variant well-formed).

## Mutation probes (plant → `npx jest src/app-config.test.ts` → restore from a scratchpad copy; `cmp` confirmed byte-identical restore; tree clean)

| Plant | Result |
|---|---|
| P1 first-non-empty rule restored | 4 failed (dev entry 2, empty slot, malformed slot, root fallback) |
| P2 no throw on > 2 entries | 1 failed (three entries THROW) |
| P3 throw message includes the raw value | 1 failed (three entries THROW, no ids) |
| P4 empty slots dropped (positions shift) | 1 failed (empty slot) |
| P5 `signIn` key re-added to prod | 1 failed (no signIn key) |
| P6 `usesAppleSignIn` dev-only | 3 failed |
| P7 testflight `extends: preview` | 1 failed (B2 testflight) |
| P8 production loses `environment` | 1 failed (B2 environments) |
| P9 `EXPO_PUBLIC_GOOGLE` planted in app.config.ts | 1 failed (second-spelling scan) |

## Grades (rework criteria)

- S2 PASS (new server case + existing). D2 PASS (incl. the fake `com.astrace.app` case). B1 PASS (jest + expo config + probes). B2 PASS. U1 unchanged and green (sign-in-gate suite in the jest total). All other non-LIVE criteria re-run green (suites above).
- LIVE L1–L4, L6: not run (coordinator/user — need the real ids in EAS/root `.env`, the NEW Apple key, a device or simulator). L5 post-rollout, non-gating.

Status: validating complete for every non-LIVE criterion — needs coordinator device/live work (L1–L4, L6).
