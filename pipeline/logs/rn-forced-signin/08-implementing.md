# rn-forced-signin — 08 implementing (2026-09-30, parallel-wave worker)

Worktree `/Users/kaimao/Projects/astrology-wt/rn-forced-signin`, branch
`feature/rn-forced-signin` at `d47d24a` (dev). Throwaway PG cluster:
`initdb`/`pg_ctl` from the conda env, data dir
`<scratchpad>/rfs/rfspg`, `127.0.0.1:54317`, dbs `rfs_main`, `rfs_web`,
`rfs_mig`. Every server/pytest run below sets `DATABASE_URL`,
`WEB_DATABASE_URL`, `TEST_DATABASE_URL`, `TEST_WEB_DATABASE_URL` explicitly
(to the cluster or empty). `.env` is never read or passed.

## Step 0 — worktree, latest dev, baseline

- `git -C /Users/kaimao/Projects/astrology log --oneline -3 dev` → head
  `d47d24a`, same as the branch; nothing to merge.
- `rn-appearance-dark-light` has NOT landed: `theme/tokens.ts:39`
  `export type Ground = 'ink' | 'paper' | 'plaster' | 'exhibition'`. So D16/U3's
  "dark ground" binds to `ink`. Keep-key confirmed:
  `theme/ground-store.ts:20 GROUND_STORAGE_KEY = 'astrology.ground.v1'`.
- Census constants on dev: `MARKER_TOTAL = 61`, `RAW_TAG_TOTAL = 53`
  (`text-variant-guard.test.ts:221-222`).
- Baseline (run in parallel):
  - `npm test` (root) → jest `Test Suites: 92 passed, 92 total` /
    `Tests: 1091 passed, 1091 total`; vitest `Tests 445 passed (445)`; EXIT 0.
  - `npm run typecheck` → EXIT 0.
  - `DATABASE_URL= WEB_DATABASE_URL= TEST_DATABASE_URL= TEST_WEB_DATABASE_URL= npm run server:test`
    (as `cd server && conda run … pytest -q`) → `1446 passed, 99 skipped, 1 warning in 159.09s`; EXIT 0.

## Step 1 — PyJWT and migrations

- `conda run -n astrology pip install "PyJWT[crypto]>=2.8"` → `Successfully installed PyJWT-2.15.1` (cryptography 49.0.0 already present).
- `requirements.txt` + `PyJWT[crypto]>=2.8`; new `014_drop_email_sign_in.sql`
  (DROP login_tokens, otp_codes) and `015_apple_identities.sql` (the Wire
  table). 014/015 were still free on dev.
- `test_db_integration.py::test_all_tables_exist`: now requires
  `sessions, refresh_tokens, apple_identities` and asserts
  `login_tokens`/`otp_codes` absent.
- `DATABASE_URL=TEST_DATABASE_URL=…54317/rfs_mig WEB_DATABASE_URL= TEST_WEB_DATABASE_URL= pytest tests/test_db_integration.py tests/test_db.py -q -rs`
  → `12 passed in 0.54s` (0 skipped).
- Second `db.apply_migrations()` on rfs_mig → `second run: []` (R6).
  Table list after: analysis_cache, apple_identities, card_images, journal,
  natal_artifacts, planet_chat_summary, planet_chat_voice, profiles,
  refresh_tokens, schema_migrations, sessions, users.

## Step 2 — Verifiers

- New `server/app/accounts/apple.py` (Contract: `AppleUnconfigured`,
  `AppleUnavailable`, `AppleRevokeFailed`, `AppleIdentity`, `bundle_ids`,
  `_verify_token` (PyJWKClient RS256, 1 h JWKS cache), `verified_identity`,
  `client_secret` (ES256, 300 s), `_post` (httpx, 10 s),
  `revoke_authorization`, plus `revocation_configured()` so the service can
  answer 503 before anything irreversible).
- `google.py`: `ios_client_ids()`; `verified_email(credential, audiences=None)` —
  None keeps the `GOOGLE_CLIENT_ID` string path byte-identical; `[]` raises
  `GoogleUnconfigured`. Docstring names the two app importers.
- New `tests/test_apple.py`: S3 verifier half (incl. a real PyJWT decode of a
  locally signed RS256 token with the JWKS lookup replaced), D4 (P-256 key
  stored with `\n` escapes), exchange-then-revoke order, failure modes.
- `DATABASE_URL= … pytest tests/test_apple.py tests/test_google_auth.py -q`
  → `46 passed, 1 warning in 0.63s`; `test_google_auth.py` unedited.

## Step 3 — Native sign-in and deletion

- `tokens.py`: `+ hash_subject(provider, sub)`; the login/session/cookie/OTP/link
  helpers were removed in the same edit (step 4's tokens half, done here
  because the rewritten service no longer needs them).
- `service.py` rewritten: `sign_in_google`, `sign_in_apple` (lookup by
  subject hash → else email upsert + link → else `NO_EMAIL`), `whoami` →
  `(email, apple_linked)`, `delete_account(access, apple)` → deleted /
  unauthorized / apple-required / apple-rejected; `ProviderUnavailable`
  (503) for unconfigured/unreachable providers and unconfigured revocation;
  the Apple revoke runs OUTSIDE any db transaction and before the DELETE.
  The link/OTP/cookie flows and the email import are gone (step 4's service
  half).
- `routes.py` rewritten: `POST /google {idToken}`, `POST /apple
  {identityToken, nonce}`, whoami / logout / DELETE account / profiles
  bearer-only; `/request-link`, `/verify`, `/otp/*`, `/native-landing` and
  every `Cookie` parameter removed (step 4's route half).
- New `tests/test_native_signin.py` (S1, S2 route half, S3 route 503/401,
  S7 source scan) and `tests/test_native_signin_live.py` (S4, S5, S6+S7
  caplog, D1, D2, D3, logout).
- Live env (`DATABASE_URL=TEST_DATABASE_URL=…54317/rfs_main WEB_DATABASE_URL= TEST_WEB_DATABASE_URL=`):
  `pytest tests/test_native_signin.py tests/test_native_signin_live.py -q -rs`
  → `28 passed, 1 warning in 1.10s` (0 skipped).
- Known red until step 4: the cookie/link/OTP suites (`test_auth_api`,
  `test_auth_integration`, `test_otp_auth`, `test_accounts_email`,
  `test_native_tokens`, `test_accounts_tokens`, `test_ratelimit`,
  `test_profiles_integration`) still exercise the removed flows.

## Step 4 — Removals (D21)

- `git rm server/app/accounts/email.py server/tests/test_otp_auth.py server/tests/test_accounts_email.py`.
  (The link/OTP/cookie/native-landing routes, service flows, token helpers
  and `LINK_*`/`OTP_*` constants were already removed in step 3's rewrite.)
- Trimmed to bearer-only: `test_auth_api.py` (dormant 503 for google/apple/
  refresh/whoami/logout/delete, no Set-Cookie; 422 bodies),
  `test_auth_integration.py` (Google-fake sign-in, whoami, logout revokes,
  401s, one users row, expired-session purge), `test_native_tokens.py`
  (landing/link units and dormant link cases dropped; lifecycle signs in via
  `/api/auth/google`; the "cookie session is the same identity" halves became
  "a second device's sign-in"), `test_accounts_tokens.py` (+ hash_subject,
  absence of the old helpers), `test_ratelimit.py` (window units kept; the
  link gates replaced by the refresh-per-token gate + absence of LINK/OTP
  constants), `test_profiles_integration.py` (user minted via
  `_upsert_user`/`_mint_bearer`, bearer header on the client).
- `.env.example`: + `GOOGLE_IOS_CLIENT_ID`, `APPLE_BUNDLE_IDS`, `APPLE_TEAM_ID`,
  `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` (no values); − `RESEND_API_KEY`,
  `APP_BASE_URL` (`EMAIL_FROM` was not present).
- Live env: `pytest tests/test_auth*.py tests/test_native*.py tests/test_accounts*.py tests/test_ratelimit.py tests/test_profiles*.py -q -rs`
  → first run `1 failed, 63 passed` (a multi-line whoami equality in
  test_native_tokens still expected `{"email"}` only; fixed) → `64 passed, 1 warning in 1.17s`, 0 skipped.
- `grep -rn resend server/app` → empty.
- Known red until step 6: `test_boundaries.py::test_only_email_gateway_references_resend`.

## Step 5 — Gates and main.py

- New `server/app/accounts/gate.py`: `require_account` (503 without
  DATABASE_URL, else 401 unless the native bearer resolves) and
  `require_account_or_web` (always consults `service.session_user_id` AND
  `web.service.user_for`; 503 only when BOTH raise their unavailable error;
  never names the web door itself).
- `main.py`: `openapi_url=None`; `dependencies=[Depends(require_account)]` on
  the nine identity-free native routes; `require_account_or_web` on
  `/api/chart`; card route `Cache-Control: private, max-age=31536000, immutable`
  and its "UNAUTHENTICATED and not dormancy-gated by design" docstring
  rewritten to cite this feature's reversal of gallery-all-cards (N2); module
  docstring updated.
- `tests/conftest.py`: `NATIVE_GATE_TEST_MODULES = {test_route_auth,
  test_native_signin, test_native_signin_live, test_boundaries}` and the
  `_native_account_gate_stubbed` autouse fixture (stubs both gates on the
  module's and main's app; guarded by `hasattr(a, "dependency_overrides")`).
- New `tests/test_route_auth.py` (R1b, R2 incl. spies, R3, R4, R5 removed
  routes + no Set-Cookie; `_no_override` autouse assertion).
- `DATABASE_URL= WEB_DATABASE_URL= TEST_DATABASE_URL=…/rfs_main TEST_WEB_DATABASE_URL=…/rfs_web pytest tests/test_route_auth.py -q -rs`
  → `57 passed, 1 warning in 1.61s` (0 skipped).
- Full suite in the live env, done-when "no newly failing route suite". The
  full suite with DATABASE_URL set was NEVER green on dev: the content caches
  (analysis, cards, planet_chat) switch to Postgres when DATABASE_URL is set,
  and tests that isolate only the SQLite path then share rows. Proven by a
  side-by-side run on FRESH databases of the same cluster:
  - dev `d47d24a` (detached worktree `<scratchpad>/rfs/devbase`, dbs
    base_main/base_web): `27 failed, 1507 passed, 11 skipped` — failures in
    test_analysis_api (4), test_ask_fitness (3), test_card_store_pg,
    test_cors (2), test_explain_store_pg, test_otp_auth (3),
    test_planet_chat_persona (5), test_planet_chat_roster, test_planet_chat_summary (5),
    test_planet_chat_turn, test_transit_today_api.
  - branch (dbs br_main/br_web): `28 failed, 1584 passed, 11 skipped` — the
    same set minus test_otp_auth (deleted), plus
    `test_boundaries::test_only_email_gateway_references_resend`,
    `test_boundaries::test_b4_google_verifier_has_one_app_importer`,
    `test_web_accounts::test_a4_main_db_google_route_is_gone` (all three are
    step 6's rewrites) and `test_planet_chat_rename::test_n5_migration_013…`.
  - n5 asserted `apply_pending(conn) == ["013_planet_chat_rename"]`, i.e.
    that 013 is the LAST migration; 014/015 broke that. Fixed by applying a
    folder copy up to 013 (as the test already does up to 012) →
    `tests/test_planet_chat_rename.py` `15 passed`.
  So no route suite newly fails; the pre-existing live-env failures are not
  this feature's and are reported to the coordinator.

## Merge — dev into the branch (coordinator note)

The coordinator reported `rn-appearance-dark-light` landed on dev as
`d35517f`. After step 5's commit: `git merge dev --no-edit` → merge commit
`b106b4c`, no conflicts (20 files, all theme/docs). Now
`theme/tokens.ts:39 export type Ground = 'dark' | 'light'`; census constants
unchanged at `MARKER_TOTAL = 61`, `RAW_TAG_TOTAL = 53`;
`GROUND_STORAGE_KEY = 'astrology.ground.v1'` unchanged (D15 keep-list holds).
D16/U3's "dark ground" therefore binds to `dark` (Apple button WHITE on
`dark`, BLACK on `light`).

## Step 6 — Pins, and CLAUDE.md in the same commit

- `test_boundaries.py`:
  - `test_only_email_gateway_references_resend` → `test_no_email_gateway`
    (no `accounts/email.py`, no `resend` in any app file);
  - `test_only_apple_module_imports_pyjwt` (PyJWT and `appleid.apple.com`
    only in `accounts/apple.py`, with an in-test plant);
  - B4 → `test_b4_google_verifier_app_importers` (exactly
    `accounts/service.py` + `accounts/web/service.py`; plants in
    `accounts/gate.py`, `accounts/routes.py`, `main.py` go red);
  - `test_every_route_requires_a_bearer` — `PUBLIC_ROUTES` (8),
    `IN_HANDLER_AUTH` (12), gated `NATIVE_GATED` (9) + `EITHER_GATED` (1) +
    `WEB_GATED` (4) = 34; keys are (path, method − HEAD) over the flattened
    `_served_routes` walk, gates found in the decorator list AND the
    dependant tree; (a) exact sets + disjointness + no stale entry, (b)
    in-test plants: open POST on the app, via an included router, under
    `/api/web/`, (c) no `/openapi.json`, `/docs`, `/redoc`;
  - `test_gated_handlers_take_no_identity_and_tiers_never_import_accounts`
    (the Architecture's forbidden edges: no identity parameter on a gated
    handler; chart/interpretation/cards/ask/planet_chat/selection/generation
    never import accounts; accounts/web never imports gate/apple).
- `test_web_accounts.py`: A4 → `test_a4_prime_native_google_route_never_touches_the_web_door`
  (`{"credential"}` → 422; `DATABASE_URL` unset + dummy `WEB_DATABASE_URL`
  → 503 with spies on `web.service.sign_in_google`, `db.connect_web`,
  `db.web_is_configured` (installed after startup) at zero calls;
  `sign_in_google` exists and its source names none of `accounts.web`,
  `web_service`, `connect_web`, `web_is_configured` — N5).
- `DATABASE_URL= WEB_DATABASE_URL= pytest tests/test_boundaries.py -q` →
  first run `1 failed, 42 passed` (the in-test plant hosts were plain
  `FastAPI()`, which serve `/docs`, `/redoc`, `/openapi.json`; they now
  disable those) → `43 passed in 0.81s`. `tests/test_web_accounts.py` →
  `34 passed`.
- Real plants in app code, each shown red once and reverted (`pytest tests/test_boundaries.py -q`):
  - open `@app.post("/api/planted_open")` in main.py → `FAILED test_every_route_requires_a_bearer` (1 failed, 42 passed);
  - `import jwt` in accounts/service.py → `FAILED test_only_apple_module_imports_pyjwt`;
  - `from . import google as google_verifier` in accounts/gate.py → `FAILED test_b4_google_verifier_app_importers`;
  - a new `accounts/email.py` naming api.resend.com → `FAILED test_no_email_gateway`;
  - open `@web_router.post("/planted")` in accounts/web/routes.py → `FAILED test_every_route_requires_a_bearer`;
  - reverted → `43 passed in 0.66s`.
- CLAUDE.md: backend paragraph (accounts REQUIRED on both clients, the
  allowlist and the three gates); new "NATIVE SIGN-IN ENV" paragraph in
  Commands (`GOOGLE_IOS_CLIENT_ID` read by server and app.config.ts,
  `APPLE_*`, EAS `environment`, the `testflight` profile); line "Everything
  except analysis works with no keys" reworded (N4); the `APP_BASE_URL`
  paragraph deleted; rule 3 (google importers pair + renamed B4 + PyJWT
  pin); rule 6's "anonymous draws" wording; rule 11 dormancy sentence;
  rule 12 native paragraph rewritten (OTP, magic-link, cookie,
  native-landing, email-gateway sentences deleted) and the web paragraph's
  last sentence replaced; rule 14's card header quoted as
  `private, max-age=31536000, immutable` (N7).
- `grep -n "GOOGLE_IOS_CLIENT_ID\|apple_identities\|test_b4_google_verifier_app_importers" CLAUDE.md`
  → hits at 79, 88, 135, 290, 506, 513.

## Step 7 — Server milestone

- First dormant run (`DATABASE_URL= WEB_DATABASE_URL= TEST_DATABASE_URL= TEST_WEB_DATABASE_URL= npm run server:test`):
  `1 failed, 1502 passed, 123 skipped` — `test_cors.py::test_unset_env_adds_no_cors_headers - assert 503`.
  Cause: test_cors reloads `app.main`, building a NEW app the conftest
  native-gate stub never saw, then posts `/api/chart`. Fix: `_reload` in
  test_cors installs the same two overrides on the reloaded app (the suite
  tests CORS, not who may call).
- Re-run, dormant: `1503 passed, 123 skipped, 1 warning in 131.74s`, EXIT 0.
- Re-run, live env on FRESH dbs `m7_main`/`m7_web` (all four URLs set,
  `-rfEs`): `24 failed, 1591 passed, 11 skipped in 135.43s`.
  - The 24 failures are EXACTLY dev's pre-existing live-env failures (the
    step-5 dev baseline run: 27 = these 24 + the 3 deleted `test_otp_auth`
    ones): `comm` of the two sorted FAILED lists → only-in-branch: none;
    only-in-dev: the three test_otp_auth cases. They are the content-cache
    suites that isolate only the SQLite path (analysis, ask fitness,
    card/explain store pg, cors' `db == "unconfigured"`, planet_chat
    persona/roster/summary/turn, transit_today) — not this feature's, and
    reported to the coordinator.
  - The 11 skips are the keyed LLM smoke, ASK_FITNESS_LIVE, the synastry
    kill-switch and one fixture-sky case; `grep` for
    native_signin|route_auth|auth_integration|profiles_integration|db_integration|web_accounts_live
    among SKIPPED → none (0 skips in the named suites).
- Deviation from the literal done-when ("passes twice"): the live-env run
  cannot be green on dev either; recorded as a pre-existing condition.

## Step 8 — Transport (D10, D11) and the web side

- `packages/core/src/platform/poll.ts`: `postJson` always goes through
  `apiFetch` and reports a final 401; `PostJsonOptions` removed (and its
  barrel export). `cardImageUrl`'s comment now says the route needs the
  bearer. Comments in `platform/api.ts` / `platform/auth.ts` rewritten
  (every surface installs a bearer provider; both listeners act on their own
  session only).
- `chart/service.ts`: bare `fetch(apiUrl('/api/chart'))` → `postJson('/api/chart', data, mine.signal)`.
- `planet_chat/{summary,roster,persona}.ts`: the `undefined, { auth: true }` arguments dropped.
- `account/google-session.ts`: the `onUnauthorized` listener returns early
  unless the WEB session is `signed-in`; the stale "never fires on native"
  comment corrected.
- `web-divination/src/auth/core-planet-chat-auth.test.ts` (sanctioned R7
  exception, N1): the whole C1 block rewritten — "postJson always carries
  the bearer" (no opts), "the header is always sent" (was "without opts no
  Authorization header"), "a final 401 on any route IS reported" (inverted
  from "a 401 without auth is NOT reported"); the `{auth:true}` arguments in
  C2 dropped. Plus one more consequence of D15 not listed in N1: the two
  cases that assert `getGoogleSession().status === 'signed-out'` after a
  refused refresh (C2 "401, refresh refused…" and C3 "a final 401 yields
  error unauthorized…") now sign the web session in first through its real
  `restoreGoogleSession()` (stubbed whoami), because the listener now acts
  only while signed in. Their assertions are unchanged.
- `npm test --workspace web-divination` → `Test Files 47 passed (47)`,
  `Tests 445 passed (445)`; `npm run typecheck --workspace web-divination` → clean.
- The new R7 web vitest (native `onSessionEnded` spy) lands with step 9.

## Step 9 — Core account (D13, D15, D17)

- `packages/core/src/account/service.ts` rewritten: `signInWithProvider('google',
  {idToken}) | ('apple', {identityToken, nonce})` → `SignInOutcome`;
  `restoreAccount()` (single-flight; no refresh token → signed-out with no
  request; whoami 200 → signed-in + sync; final 401 → session ends; 503 →
  unavailable; throw → offline); `logout()` (POST {refreshToken} with the
  bearer, 5 s cap, best effort, then session end); `deleteAccount(apple?)` →
  'ok' | 'failed' | 'unavailable'; `onSessionEnded(cb)`; one module-load
  `onUnauthorized` listener that ends the session only while `signed-in`;
  `endSession()` is once-per-session (stopSync, provider.clear(), deliver
  null, `signed-out`, listeners). `resetAccountForTests()` seam. The
  link/OTP/cookie/verify/refreshAccount APIs are gone.
- `types.ts`: `Account = {email, appleLinked} | null`, `AccountStatus` +
  `'offline'`, `SignInOutcome`, `AppleReauthorization`, `DeleteOutcome`
  (`VerifyOutcome` kept for the web google-session). `index.ts` exports
  updated; the merge channel exports removed.
- `sync.ts`: conflict channel removed — account data present → adopted
  silently; account empty + device data → PUT; pull failure → abort, unarmed.
  `reportUnauthorized()` on a 401 from the GET pull and the PUT push. A
  `generation` counter keeps a pull that resolves after the session ended from
  arming push-on-save. A 200 whose body has no `profiles` array is a failed
  pull, not an empty account (found by the test below: the stub's generic 204
  body `{}` crashed `profiles.find`).
- Orphaned core vitest files (run by no runner, typechecked by no tsconfig):
  `account/service.test.ts` DELETED (every case targeted a removed API);
  `account/sync.test.ts` edited — the conflict case became "account wins",
  merge-state assertions dropped.
- New `app-native/src/account/core-account.test.ts` (C4, C5 native half incl.
  chart service, sync pull 401 and push 401, and "no native session → no
  end", C6). `npx jest src/account/core-account.test.ts` → first run
  `1 failed, 16 passed` (the Apple case's unrouted /api/profiles, see above)
  → `Tests: 17 passed, 17 total`.
- New web vitest `web-divination/src/auth/web-session-scope.test.ts` (R7):
  signed-in web session + final 401 → web signed-out, native
  `onSessionEnded` spy 0; not signed in → nothing changes.
  `npx vitest run src/auth/web-session-scope.test.ts` → `Tests 2 passed (2)`.

## Step 10 — Token store and boot fixes (D13, D14, D15)

- `git mv account/tokenStore.ts platform/token-store.ts` (+ test). Refresh is
  now `fetch(apiUrl('/api/auth/token/refresh'))` with no Authorization
  header; a non-2xx, a throw or a bad body returns `false`. Keys exported.
- New `platform/device-wipe.ts` (`wipeDevice`: MMKV `clearExcept(['astrology.lang.v1',
  'astrology.ground.v1'])`, `tokenStore.clear()`, `Image.clearMemoryCache`,
  `Image.clearDiskCache`, `signOutProviders()`; each step best effort).
- New `platform/account-boot.ts` (`bootAccount`: wires `onSessionEnded →
  wipeDevice → requestReload` once, AWAITS `loadFromSecureStore`, then
  `restoreAccount`).
- `platform/boot.ts`: the fire-and-forget `void tokenStore.loadFromSecureStore()`
  removed; imports `./token-store`. `boot.test.ts` gains a source check that
  boot no longer starts the load.
- `mmkv-kv.ts`: `clearExcept(keep)`. `jest/expo-image-mock.js`: `clearMemoryCache`,
  `clearDiskCache` jest.fns. `theme/reload.ts` comment: two callers.
- C1 reproduction against the OLD refresh: a temporary copy
  `git show d47d24a:app-native/src/account/tokenStore.ts > src/platform/oldTokenStoreRepro.ts`
  plus a temporary test running the same C1 case →
  `✕ whoami 401 + refresh 401 → … under 1 s (1002 ms)` / `restore hung` /
  `Tests: 1 failed, 1 total`. Both temporary files deleted. With the new
  store: `✓ … (1 ms)`.
- New `platform/account-boot.test.ts` (C2 slow Keychain 50 ms; C3 empty /
  503 / throw; C7 wipe with a rejected logout fetch + anonymous not wiped).

## Step 11 — Native modules and the sign-in port

- `npx expo install expo-apple-authentication expo-crypto expo-constants` →
  `~57.0.2`, `~57.0.3`, `~57.0.20`; `@react-native-google-signin/google-signin`
  `^16.1.5` added by hand; root `npm install` → 16.1.5 resolved.
- jest mocks `jest/google-signin-mock.js`, `jest/apple-authentication-mock.js`
  (host `AppleAuthenticationButton` element), `jest/expo-crypto-mock.js`
  (node crypto), mapped in `jest.config.js`. `expo-constants` is NOT mapped
  globally (other expo packages read it); suites that need a given `extra`
  `jest.mock('expo-constants', …)` locally.
- New `platform/sign-in.ts` per the App contract (`googleConfigured`,
  `appleConfigured`, `appleAvailable`, `googleIdToken`, `appleCredential` with
  a 32-byte hex nonce and sha256 to Apple, `signOutProviders`, and re-exports
  of Apple's button + enums so the gate never names the SDK).
- `native-guards.test.ts`: `the sign-in SDKs are named by exactly one module`
  (+ in-test plant), `the sign-in path names no dev client, no __DEV__ and no
  local address (D20)` over `account/**` + `platform/{sign-in,token-store,account-boot}.ts`
  (+ in-test plant). First run failed the self-check: `stripComments` eats the
  `//` of `http://localhost`, so this guard uses a URL-aware stripper.
- Real plants, each red once then reverted:
  `import 'expo-dev-client'` in platform/sign-in.ts → `✕ the sign-in path names no dev client…`;
  `import … from 'expo-apple-authentication'` in platform/boot.ts →
  `✕ the sign-in SDKs are named by exactly one module` (the SignInGate plant
  is repeated in step 13 once that file exists). Reverted → `Tests: 34 passed`.
- `npx jest src/native-guards.test.ts src/platform` → `Test Suites: 8 passed`, `Tests: 74 passed`.
- `npm run typecheck` for app-native is expected red until steps 13–14
  delete/rewrite AccountSheet, OtpInput, deepLink, useMergeState, App.tsx.

## Step 12 — Authenticated images (D12)

- New `platform/remote-image.ts` (`bearerHeaders()`, `remoteImageSource(uri)`
  → `{uri, headers: {Authorization}}` while a token is held).
- The five sites (`gallery/GalleryScreen.tsx`, `cards/detail/CardDetail.tsx`,
  `transit/CardStage.tsx`, `transit/PinnedHeader.tsx`, `readings/DeckCard.tsx`)
  → `source={remoteImageSource(…)}`; `image-prefetch.ts` passes
  `{cachePolicy: 'disk', headers: bearerHeaders()}`.
- C9: `test-support/bearer.ts` (`withBearer()`), and one case per site in
  stage.test, transit/reading.test (pinned thumb), detail.test, gallery.test,
  readings/reading.test (deck), plus image-prefetch.test.
- `native-guards`: `no source={{ uri outside platform/` + planted self-check.
- `npx jest src/native-guards.test.ts src/platform src/gallery src/cards src/transit src/readings`
  → `Test Suites: 32 passed, 32 total`, `Tests: 433 passed, 433 total`.

## Step 13 — The gate (D16)

- `frontend-design` loaded (Skill tool) before the UI code. Direction: a
  threshold, not a form — the ground, the wordmark in the display serif at
  ~38 %, two provider doors in the lower third in one achromatic pair
  matched to Apple's system button, one quiet note line; nothing else.
- `theme/tokens.ts`: `signInFill` / `signInInk` (achromatic: dark
  #ffffff/#000000, light #000000/#ffffff) in a new `signIn` role family;
  frozen values in `tokens.test.ts`. `theme/paint.ts`: `PAINT.signInButton`
  (rest only; pressed/disabled are opacity) + `paint.test.ts` element list.
- `assets/brand/google-g.png`: Google's own "G" (200×204 RGBA) fetched from
  `https://developers.google.com/static/identity/images/g-logo.png`.
- i18n: `account.*` OTP/merge/sheet keys and `settings.signIn` removed;
  `auth.*` (gate) and a new `account.*` (Settings › Account) added in en and
  zh; `i18n.test.ts`'s en==zh allow-list loses the two placeholder keys.
- New `account/SignInGate.tsx`; `App.tsx`: opening → gate unless `signed-in`
  → shell; `bootAccount()` once at mount (deepLink catcher removed).
- `App.test.tsx`: deepLink mock dropped; "no stored account → only the gate"
  and "stored valid pair → the rail, no gate" (N3).
- New `account/sign-in-gate.test.tsx` (U1–U3; "dark ground" = `dark` after
  the rn-appearance-dark-light merge) → `Tests: 17 passed, 17 total`.
- Rulings: text-variant-rulings (gate wordmark title, notes, actionQuiet,
  the one local raw label in signInInk); surface-paint-rulings
  (`google` spreads `PAINT.signInButton.rest`, `retryPressed` spreads
  `PAINT.tap.pressed`, opacity-only pressed/disabled) and the FLOORS table
  gains `signInButton: 1`.
- G1 real plant: `import * as AppleAuthentication from 'expo-apple-authentication'`
  appended to account/SignInGate.tsx → `✕ the sign-in SDKs are named by
  exactly one module (rn-forced-signin)` (1 failed, 35 passed); reverted.
- `architecture.test.ts` flagged `identity-lifecycle/wipeAllLocal` as an
  unconsumed core export (core's account service no longer calls it): the
  device wipe now runs core `wipeAllLocal()` first (stores clear their
  in-memory state too), then the MMKV clear.

## Step 14 — Settings › Account, the deletions, and census

- New `account/AccountSection.tsx` (eyebrow, email `fieldValue`, Sign out /
  Delete account… `actionQuiet`, inline confirm `prose` + `actionLabel`
  (`waiting` Deleting…) + Keep; Apple-linked → `appleCredential()` first,
  cancel keeps the confirm; failure `note`). `SettingsScreen.tsx` renders it
  in place of the row + sheet.
- `git rm` AccountSheet.tsx, OtpInput.tsx, deepLink.ts, useMergeState.ts and
  account-sheet / account-merge / otp-input / deepLink tests.
  `useAccount.ts` header rewritten.
- `settings/settings.test.tsx`: `verifyToken` → `signInWithProvider('google',
  {idToken:'g'})` against a stubbed `/api/auth/google`; `logout()` reset →
  `resetAccountForTests()`; the account-row cases → "the account section".
- New `account/account-section.test.tsx` (C8, U4 incl. a source walk that no
  email/OTP input exists and the four files are gone).
- Comments: theme/reload.ts (step 10), platform/secure-store.ts,
  native-guards.test.ts (the `account/` folder note, N3), ask.test.tsx,
  BirthSheet.tsx, SkySheet.tsx, theme/sheet.ts.
- Census re-pinned (`text-variant-guard.test.ts`): raw tags 53 → 47,
  markers 61 → 53, local floor 45 → 37 (measured: 53 = 37 local + 13 exempt
  + 3 inherit). Consumer floors (`theme/text-variants.test.tsx`):
  sectionTitle 8 → 3, fieldLabel 6 → 4, prose 11 → 6, actionLabel 13 → 12.
  Note in `docs/text-variant-census.md` §T (rows 164–173 appended, the
  AccountSheet/OtpInput rows retired).
- Root: `npm run typecheck` → EXIT 0 (app-native + web-divination);
  `npm test` → jest `Test Suites: 92 passed, 92 total` / `Tests: 1126 passed,
  1126 total`; vitest `Test Files 48 passed (48)` / `Tests 447 passed (447)`; EXIT 0.
- `grep -rn "AccountSheet\|OtpInput\|deepLink\|useMergeState" app-native/src`
  → only comments recording the removal, the census/floor notes, and
  account-section.test.tsx's absence check.

## Step 15 — app.config.ts and eas.json (D19, D20)

- `app.config.ts`: `VARIANTS[v].signIn` (dev true, prod false);
  `readRootEnvKey(key)` reads ONE key from the repo-root `.env` (never
  printed); `googleIosClient(env, reader)` takes the FIRST list entry, requires
  `<prefix>.apps.googleusercontent.com`, derives
  `com.googleusercontent.apps.<prefix>`; `buildConfig(env, reader)` (the
  default export calls it) adds, only when the flag is on,
  `ios.usesAppleSignIn: true`, `extra.appleSignIn: true` and — only with a
  well-formed id — the google-signin plugin + `extra.googleIosClientId`.
  `extra.appleSignIn` is `false` on prod. The dev scheme comment no longer
  mentions OTP. Env typed as a local `ConfigEnv` (RN's `ProcessEnv` requires
  NODE_ENV and broke the test's stand-ins under tsc — found by the first
  root typecheck: 6 × TS2345, fixed).
- `eas.json`: `environment` on development (`development`) and preview
  (`preview`); new `testflight` profile (extends preview, store,
  autoIncrement, environment preview, env APP_VARIANT=dev +
  EXPO_PUBLIC_API_BASE=https://astrology-dev.onrender.com, channel preview).
  No Google id anywhere in eas.json.
- New `src/app-config.test.ts` (B1 stubbed-reader cases, B2) → `Tests: 8 passed, 8 total`.
- B1 live (from app-native/):
  - `APP_VARIANT=dev GOOGLE_IOS_CLIENT_ID="123-abc.apps.googleusercontent.com,999-zzz.apps.googleusercontent.com" npx expo config --type public --json`
    → `ios.bundleIdentifier: com.astrace.app.dev`, `ios.usesAppleSignIn: True`,
    plugin `['@react-native-google-signin/google-signin', {'iosUrlScheme': 'com.googleusercontent.apps.123-abc'}]`,
    `extra.googleIosClientId: 123-abc.apps.googleusercontent.com`, `extra.appleSignIn: True`.
  - `APP_VARIANT=prod GOOGLE_IOS_CLIENT_ID=123-abc.apps.googleusercontent.com npx expo config --type public --json`
    → `com.astrace.app`, `usesAppleSignIn None`, google plugin `[]`,
    extra `{variant: prod, appleSignIn: False}`, `'iosUrlScheme' in json` → False.
  - `grep -rn "EXPO_PUBLIC_GOOGLE\|GOOGLE_IOS_CLIENT_IDS" app-native --exclude-dir=node_modules --exclude-dir=ios --exclude-dir=android` → no output (exit 1).
- Root after step 15: `npm run typecheck` EXIT 0; `npm test` EXIT 0 — jest
  `Test Suites: 93 passed` / `Tests: 1134 passed`; vitest `Test Files 48 passed` / `Tests 447 passed`.

Transition: implementing → validating (steps 0–15 done; 16–17's device half
is coordinator-serialized).
