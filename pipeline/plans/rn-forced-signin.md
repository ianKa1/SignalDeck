# Plan — rn-forced-signin

Spec: `pipeline/specs/rn-forced-signin.md` (Decided defaults D1–D22, Architecture, criteria). The spec and its Architecture section are the source of truth; this plan only orders them. Reviews: `logs/rn-forced-signin/02-, 04-, 06-spec-review.md`; the round-3 planner notes N1–N7 are folded into steps 0, 5, 6, 8, 13, 14 and 18.

Worktree `../astrology-wt/rn-forced-signin`, branch `feature/rn-forced-signin` off `dev`. Throwaway Postgres cluster: 127.0.0.1:54317, scratchpad dir `rfspg`, dbs `rfs_main`, `rfs_web` and `rfs_mig` (the recipe is in the docstring of `server/tests/test_auth_integration.py`, using the conda env's `initdb`/`pg_ctl`). Every backend and pytest run sets `DATABASE_URL`, `WEB_DATABASE_URL`, `TEST_DATABASE_URL` and `TEST_WEB_DATABASE_URL` explicitly, either to the local cluster or empty. Never pass `--env-file .env`, never read `.env`, and never use the Neon URLs. "Live env" below means `DATABASE_URL=TEST_DATABASE_URL=…54317/rfs_main WEB_DATABASE_URL=TEST_WEB_DATABASE_URL=…54317/rfs_web`. Server commands run from `server/` via `conda run -n astrology`. App commands run from `app-native/` unless stated. Each step ends with a `/git-commit` (`(<type>): rn-forced-signin — …`) unless it says it commits together with the next one.

## Steps

### Setup

- [x] **0. Worktree, latest dev, baseline.**
  - Create the worktree and run `git merge dev` so it has the latest dev.
  - Check whether `rn-appearance-dark-light` has landed (`Ground` in `app-native/src/theme/tokens.ts` names `dark`/`light` rather than `ink`/`exhibition`). If it has, every "dark ground" in D16/U3 means `dark`; take the census constants from the merged `text-variant-guard.test.ts`; and confirm D15's keep-key is still `astrology.ground.v1` (grep the ground store). Record what you found in the implementing log.
  - Run `npm install` at the root, start the cluster, and create the three dbs.
  - Done-when: root `npm test` and `npm run typecheck` are green, and `DATABASE_URL= WEB_DATABASE_URL= npm run server:test` is green. Record `RAW_TAG_TOTAL`/`MARKER_TOTAL` and the pass counts.

### Server

- [x] **1. PyJWT and migrations.**
  - `server/requirements.txt` gets `PyJWT[crypto]>=2.8`; install it into the conda env.
  - Add `db/migrations/014_drop_email_sign_in.sql` and `015_apple_identities.sql`, with the table as given under Wire. If dev has taken 014 by then, renumber.
  - `tests/test_db_integration.py`: the post-migration table set now has no `login_tokens`/`otp_codes` and does have `apple_identities`.
  - Done-when: `DATABASE_URL=…/rfs_mig pytest tests/test_db_integration.py tests/test_db.py -q` passes with 0 skipped, and a second `apply_migrations()` on `rfs_mig` applies nothing (R6).

- [x] **2. Verifiers.**
  - New `app/accounts/apple.py` per its Contract, with the seams `_verify_token` and `_post` (D7).
  - `accounts/google.py`: `verified_email(credential, audiences=None)` and `ios_client_ids()`.
  - New `tests/test_apple.py` covers S3's verifier half, D4 (a P-256 key generated in the test, stored with `\n` escapes) and the exchange-then-revoke order through a recording `_post`.
  - Done-when: `pytest tests/test_apple.py tests/test_google_auth.py -q` passes, with `test_google_auth.py` unedited (S2, web half).

- [x] **3. Native sign-in and deletion.**
  - `accounts/tokens.py`: add `hash_subject`.
  - `accounts/service.py`: add `sign_in_google`, `sign_in_apple`, `apple_linked`, `appleLinked` on whoami, and `delete_account(access, apple)` (D4, D6, Contracts).
  - `accounts/routes.py`: add `POST /google` and `/apple`. whoami and DELETE become bearer-only, with the DELETE body per D6. Error order per D9.
  - New `tests/test_native_signin.py` covers S1, S2 (route half), S3's route 503 and S7's source scan.
  - New `tests/test_native_signin_live.py` (guarded on `DATABASE_URL`, refuses any non-localhost host) covers S4–S6, S7's caplog half and D1–D3.
  - Done-when: in the live env, `pytest tests/test_native_signin*.py -q` passes with 0 skipped.

- [x] **4. Removals (D21).**
  - Delete `accounts/email.py` and the link, OTP, cookie and native-landing routes, service flows and token helpers. Remove `Cookie`. Remove the `LINK_*`/`OTP_*` constants from `ratelimit.py`.
  - Delete `tests/test_otp_auth.py` and `tests/test_accounts_email.py`.
  - Trim to bearer-only (per the module map): `test_auth_api.py`, `test_auth_integration.py`, `test_native_tokens.py`, `test_accounts_tokens.py`, `test_ratelimit.py`, and `test_profiles_integration.py` (users minted via `_upsert_user`/`_mint_bearer`).
  - `.env.example`: add the D19 names with no values and drop `RESEND_API_KEY`, `EMAIL_FROM` and `APP_BASE_URL`.
  - Done-when: in the live env, `pytest tests/test_auth*.py tests/test_native*.py tests/test_accounts*.py tests/test_ratelimit.py tests/test_profiles*.py -q` is green with 0 skipped, and `grep -rn resend server/app` is empty.

- [x] **5. Gates and main.py.**
  - New `accounts/gate.py` per its Contract. `require_account_or_web` always consults both services, even with no header, so its 503-vs-401 decision is correct.
  - `main.py`:
    - `openapi_url=None`;
    - `dependencies=[Depends(require_account)]` on the nine routes, and `require_account_or_web` on `/api/chart`;
    - the card route answers `Cache-Control: private, max-age=31536000, immutable`, and its docstring's "UNAUTHENTICATED and not dormancy-gated by design" is rewritten to cite rn-forced-signin's reversal of gallery-all-cards (N2).
  - `tests/conftest.py`: add the `NATIVE_GATE_TEST_MODULES` stub (Architecture, "Test-suite stub").
  - New `tests/test_route_auth.py` covers R1b, R2, R3, R4 and R5's 404/405 and no-`Set-Cookie` checks, and asserts at its start that no override is installed.
  - Done-when: in the live env, `pytest tests/test_route_auth.py -q` passes with 0 skipped, and the full `pytest -q` shows no newly failing route suite.

- [x] **6. Pins, and CLAUDE.md in the same commit.**
  - `tests/test_boundaries.py`:
    - add `test_every_route_requires_a_bearer` with the (a), (b) and (c) plants;
    - add `test_only_apple_module_imports_pyjwt`;
    - rewrite `test_only_email_gateway_references_resend` as `test_no_email_gateway`;
    - rename B4 to `test_b4_google_verifier_app_importers` (the exact pair, plus a plant in `gate.py`).
  - `tests/test_web_accounts.py`: A4 becomes A4′. The getsource check matches the identifiers `accounts.web`, `web_service`, `connect_web` and `web_is_configured`, not the bare `web` (N5).
  - `CLAUDE.md`, per "CLAUDE.md and guard amendments":
    - the Project/backend paragraph;
    - delete the `APP_BASE_URL` paragraph;
    - Commands: the D19 env names, the `testflight` profile, and line 117 "Everything except analysis works with no keys" reworded (app-native needs `DATABASE_URL` plus the provider ids) (N4);
    - rules 3, 11 and 12;
    - rule 14's quoted card header becomes `private, max-age=31536000, immutable` (N7).
  - Done-when: `pytest tests/test_boundaries.py tests/test_web_accounts.py -q` is green; each plant is shown red once (record it in the log, then revert); `grep -n "GOOGLE_IOS_CLIENT_ID\|apple_identities\|test_b4_google_verifier_app_importers" CLAUDE.md` finds hits.

- [x] **7. Server milestone.**
  - Done-when: `npm run server:test` (root) passes twice: in the live env, with 0 skips in `test_native_signin_live`, `test_route_auth`, `test_auth_integration`, `test_profiles_integration`, `test_db_integration` and `test_web_accounts_live`; and with all four URLs empty. Commit.

### Core

- [x] **8. Transport (D10, D11) and the web side.**
  - `packages/core/src/platform/poll.ts`: `postJson` always goes through `apiFetch` and reports a final 401. Remove `PostJsonOptions`.
  - Update the comments in `api.ts`/`auth.ts`. `chart/service.ts` moves to `postJson`. `planet_chat/{summary,persona,roster}.ts` drop `{auth:true}`.
  - `account/google-session.ts`: the listener acts only while the web session is signed in; fix its comment.
  - `web-divination/src/auth/core-planet-chat-auth.test.ts`: the whole "C1 — postJson carries the bearer only when asked" block becomes "always sent". The `:165` "401 without auth is NOT reported" case is inverted, and the `{auth:true}` arguments at `:147/:180/:195` are dropped. This is the sanctioned R7 exception (N1).
  - New web vitest (R7): with a signed-in web session, a final 401 signs it out, and a native `onSessionEnded` spy never fires. This commits with step 9, since `onSessionEnded` arrives there.
  - Done-when: `npm test --workspace web-divination` and `npm run typecheck --workspace web-divination` are green.

- [x] **9. Core account (D13, D15, D17).**
  - `account/service.ts`: `signInWithProvider`, `restoreAccount`, `logout`, `deleteAccount(apple?)`, `onSessionEnded`, the module-load `onUnauthorized` listener, and `Account` = `{email, appleLinked}`.
  - `types.ts` and `index.ts`: `'offline'` and `SignInOutcome`.
  - `sync.ts`: remove the conflict channel (the account wins) and call `reportUnauthorized()` on a final 401 from `/api/profiles`.
  - The graded tests live in NEW `app-native/src/account/core-account.test.ts` (jest, barrel imports only): C4, C5's native half and sync 401, and C6. `packages/core/src/account/{service,sync}.test.ts` are run by no runner (see Risks); edit them only to drop removed APIs.
  - Done-when: `npx jest src/account/core-account.test.ts` is green. `npm run typecheck` may still fail, but only in files that steps 10–14 delete or rewrite; commit steps 9–10 together.

### App-native

- [x] **10. Token store and boot fixes (D13, D14, D15).**
  - `account/tokenStore.ts` becomes `platform/token-store.ts`, with the plain-`fetch` refresh.
  - New `platform/account-boot.ts` (`bootAccount`, and the `onSessionEnded` → `wipeDevice` → `requestReload` wiring).
  - `platform/boot.ts` no longer fire-and-forgets the Keychain load.
  - `mmkv-kv.ts` gains `clearExcept`. New `platform/device-wipe.ts`.
  - Tests:
    - `platform/token-store.test.ts` (from `tokenStore.test.ts`) covers C1. Also run the C1 case once against the old `apiFetch` refresh, as a temporary copy from `git show dev:…`, and log the timeout as the reproduction.
    - `platform/account-boot.test.ts` covers C2, C3 and C7.
    - `platform/boot.test.ts` is updated.
  - Done-when: `npx jest src/platform` is green.

- [x] **11. Native modules and the sign-in port.**
  - `npx expo install expo-apple-authentication expo-crypto expo-constants`. Add `@react-native-google-signin/google-signin@^16` to `app-native/package.json`, then run `npm install` at the root.
  - Add jest mocks under `app-native/jest/` for the three SDKs, `expo-constants`' `extra`, and the expo-image cache calls.
  - New `platform/sign-in.ts` per the App contract.
  - `native-guards.test.ts`: provider SDKs only in `platform/sign-in.ts`, and the D20 no-dev-client / no-`__DEV__` / no-localhost rule over the sign-in path, each with the G1 plant.
  - Done-when: `npx jest src/native-guards.test.ts src/platform` is green, and both plants are shown red once, then reverted.

- [x] **12. Authenticated images (D12).**
  - New `platform/remote-image.ts`. The five `source={{ uri` sites switch to `remoteImageSource`, and `image-prefetch.ts` sends the headers.
  - `native-guards` gains the no-`source={{ uri`-outside-`platform/` rule.
  - The C9 test sits beside `image-prefetch.test.ts` or in the sites' existing suites.
  - Done-when: `npx jest src/native-guards.test.ts src/platform src/gallery src/cards src/transit src/readings` is green.

- [x] **13. The gate (D16).** Load `/frontend-design` first.
  - `theme/tokens.ts`: achromatic `signInFill`/`signInInk`. `theme/paint.ts`: `PAINT.signInButton`.
  - `assets/brand/google-g.png`.
  - `i18n/en.ts`/`zh.ts`: add the `auth` namespace and remove the OTP/merge keys.
  - New `account/SignInGate.tsx`.
  - `App.tsx`: the opening hands off to the gate or the shell by status, and `bootAccount` runs once.
  - `App.test.tsx`: drop the `./account/deepLink` mock; the opening now goes to the gate, and to the shell only when signed-in (N3).
  - New `account/sign-in-gate.test.tsx` covers U1–U3, binding "dark ground" per step 0.
  - Add rulings for SignInGate to `text-variant-rulings`/`surface-paint-rulings`.
  - Done-when: `npx jest src/account src/App.test.tsx src/i18n src/theme src/surface-paint-rulings.test.tsx src/text-variant-rulings.test.tsx` is green.

- [x] **14. Settings → Account, the deletions, and census.**
  - New `account/AccountSection.tsx`; `settings/SettingsScreen.tsx` uses it.
  - Delete `AccountSheet`, `OtpInput`, `deepLink`, `useMergeState` and their four tests. Update `useAccount.ts`.
  - `settings/settings.test.tsx`: a minted sign-in replaces `verifyToken`.
  - New `account/account-section.test.tsx` covers C8 and U4.
  - Comments only: `theme/reload.ts`, `platform/secure-store.ts`, and `native-guards.test.ts:525` (AccountSheet) (N3).
  - Re-pin the census constants in `text-variant-guard.test.ts` from the step-0 figures, and add a note in `docs/text-variant-census.md`.
  - Done-when: from the repo root, `npm test` and `npm run typecheck` are green (G1, U4), and `grep -rn "AccountSheet\|OtpInput\|deepLink\|useMergeState" app-native/src` returns only the comments that record the removal.

### Config

- [x] **15. `app.config.ts` and `eas.json` (D19, D20).**
  - `app.config.ts`: the `VARIANTS[v].signIn` flag and a single-key root-`.env` reader, which never logs the value and is injectable for tests. Also the google-signin plugin with its derived `iosUrlScheme`, `extra.googleIosClientId`, `ios.usesAppleSignIn` and `extra.appleSignIn`.
  - `eas.json`: the `testflight` profile, plus `environment` on development, preview and testflight.
  - New `src/app-config.test.ts` covers B1's stubbed-reader case and B2's `eas.json` pin.
  - Done-when:
    - `APP_VARIANT=dev GOOGLE_IOS_CLIENT_ID="123-abc.apps.googleusercontent.com,999-zzz.apps.googleusercontent.com" npx expo config --type public --json` matches B1;
    - the `APP_VARIANT=prod` run matches B1;
    - `grep -rn "EXPO_PUBLIC_GOOGLE\|GOOGLE_IOS_CLIENT_IDS" app-native --exclude-dir=node_modules --exclude-dir=ios --exclude-dir=android` is empty;
    - `npx jest src/app-config.test.ts` is green.
  - Then set `validating`.

### Device (coordinator-serialized: the implementer reports `validating — needs device`)

- [x] **16. Dev-client rebuild. [needs device]** _(DONE — logs/rn-forced-signin/11-validating.md; fingerprint fa8f265489b5ad6ff09b1349c1803a815e2c2176.)_
  - Start a worktree backend on :8017 with no `--env-file`: `DATABASE_URL=…/rfs_main WEB_DATABASE_URL= conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --port 8017 --host 0.0.0.0`.
  - Then `APP_VARIANT=dev GOOGLE_IOS_CLIENT_ID=123-abc.apps.googleusercontent.com EXPO_PUBLIC_API_BASE=http://127.0.0.1:8017 npx expo run:ios` on the simulator. The fake id only yields a URL scheme; this is not a live sign-in.
  - Done-when: the build installs, launches and connects to Metro. The log records the new fingerprint.

- [x] **17. Non-live checks.** A2 needs no device; A1 [needs device]. _(A2 DONE by the worker — logs/rn-forced-signin/09-validating.md; A1 DONE on the simulator — logs/rn-forced-signin/11-validating.md.)_
  - A2: curl :8017 as in A2. Then start a second backend on :8018 with `DATABASE_URL=` and `WEB_DATABASE_URL=` both empty, and confirm the 503s.
  - A1: delete the app, install fresh, see the opening and then only the gate; the idb accessibility dump has no rail, chart or settings (per `.claude/skills/verify/SKILL.md`).
  - Stop both servers.
  - Done-when: the evidence is in the validating log.

### Docs-sync

- [x] **18. Docs.** _(Non-device half DONE by the worker — logs/rn-forced-signin/10-docs-sync.md, commit c828f73; re-checked after 16/17 by the coordinator — logs/rn-forced-signin/12-docs-sync.md.)_
  - Run `/update-architecture-doc` on `docs/ARCHITECTURE.md`, including the card-pixel passages near :3174 and :5279 that still say "unauthenticated" (N2).
  - Write `docs/features/rn-forced-signin.md` from what was actually built.
  - Re-check the CLAUDE.md amendments from step 6 against the final code (rules 3, 11, 12 and 14, Commands, the backend paragraph), plus the census note.
  - Draft the single hand-back: L1–L5, the env names to set (root `.env`, the EAS `preview` environment, the dev Render dashboard), and the deliberate offline-launch behaviour (D13).
  - Done-when: `git diff --stat dev -- docs CLAUDE.md` lists all three docs, and `grep -n "UNAUTHENTICATED\|unauthenticated" docs/ARCHITECTURE.md server/app/main.py` has no card-route hit.

## Acceptance map

| Criterion | Made to pass by | Graded in |
|---|---|---|
| S1 dormant, 422s | 3 | `test_native_signin.py` |
| S2 Google policy | 2, 3 | `test_native_signin.py`, `test_google_auth.py` |
| S3 Apple policy | 2, 3 | `test_apple.py`, `test_native_signin.py` |
| S4 Google upsert (live-PG) | 1, 3 | `test_native_signin_live.py` |
| S5 Apple link (live-PG) | 1, 3 | `test_native_signin_live.py` |
| S6 only email at rest | 3, 4 | `test_native_signin_live.py` |
| S7 no logging | 2, 3 | `test_native_signin*.py` |
| D1–D3 deletion and revoke | 2, 3 | `test_native_signin_live.py` |
| D4 client secret | 2 | `test_apple.py` |
| R1 route pin, openapi | 5, 6 | `test_boundaries.py` |
| R1b in-handler | 3, 5 | `test_route_auth.py` |
| R2 gated 401/503, spies | 5 | `test_route_auth.py` |
| R3 chart takes either bearer | 5 | `test_route_auth.py` |
| R4 card pixels | 5 | `test_route_auth.py` |
| R5 removed, env | 4, 5 | `test_route_auth.py`, `test_boundaries.py`, grep |
| R6 migrations, PyJWT, B4 | 1, 6 | `test_db_integration.py`, `test_boundaries.py` |
| R7 web unchanged (+ N1 exception, new vitest) | 6, 8, 9 | web suites, `npm test --workspace web-divination` |
| A4′ | 3, 6 | `test_web_accounts.py` |
| C1 refresh hang | 10 | `platform/token-store.test.ts` |
| C2 cold-start race | 10 | `platform/account-boot.test.ts` |
| C3 boot outcomes | 9, 10 | `platform/account-boot.test.ts` |
| C4 sign-in | 9 | `account/core-account.test.ts` |
| C5 every request authenticated | 8, 9 | `core-account.test.ts`, web vitest |
| C6 account wins | 9 | `core-account.test.ts` |
| C7 wipe | 10 | `platform/account-boot.test.ts` |
| C8 deletion UI | 14 | `account/account-section.test.tsx` |
| C9 images | 12 | site suites, `native-guards.test.ts` |
| U1–U3 gate | 13 | `account/sign-in-gate.test.tsx`, `i18n.test.ts` |
| U4 settings, removals | 14 | `account-section.test.tsx`, grep |
| G1 guards, CLAUDE.md | 6, 11, 13, 14 | root `npm test`, step 6 grep |
| B1 expo config | 15 | step 15 commands, `app-config.test.ts` |
| B2 eas profiles | 15 | `app-config.test.ts` |
| A1 fresh install shows the gate | 16, 17 | validating log (simulator) |
| A2 curl 401/503 | 5, 17 | validating log |
| L1–L5 | 16, 18 | **LIVE: deferred to the user hand-back** |

## Risks for the implementer

- **Core tests run nowhere.** `packages/core/src/**/*.test.ts` are vitest files from the deleted `frontend/` runner. app-native jest (`roots: src`) and web-divination vitest (`include: src/**`) both skip them, and neither tsconfig includes them. Criteria graded there would pass vacuously, so C-tests go in `app-native/src` or `web-divination/src` through barrels (the `core-planet-chat-auth.test.ts` precedent).
- `app.main`'s lifespan migrates whatever `DATABASE_URL` holds. The worktree has no `.env`; keep it that way, and never pass `--env-file`.
- FastAPI resolves decorator dependencies before it reports body errors (the dw-18 precedent). This is what gives R3's "bad body without a bearer → 401". Keep the gates as `dependencies=[…]`, never as handler parameters (rule 9).
- The conftest stub keys on module basenames. A misspelt entry in `NATIVE_GATE_TEST_MODULES` would silently stub the proving suite; `test_route_auth.py`'s opening assertion catches this.
- `session_user_id` and `web.service.user_for` check their db before the bearer. `require_account_or_web` must not short-circuit on a missing header, or R3's 503 becomes 401.
- **Merge interplay with `rn-appearance-dark-light`:**
  - it renames `ink`→`dark` and `exhibition`→`light`;
  - both features re-pin the census and the paint rulings;
  - whichever lands second rebases the constants and the Apple WHITE/BLACK binding.
  If it lands mid-implementation, merge dev again before step 13.
- The simulator's dev client (`com.astrace.app.dev`) is shared with other features' validation. Steps 16–17 replace it and change the fingerprint, so the coordinator serializes them.
- The google-signin plugin fails `expo config` or prebuild when `iosUrlScheme` is malformed. The config must omit the plugin entirely when the id is missing or malformed (B1), not pass an empty scheme.

## Rework (2026-09-30)

Source: the amended spec (D3, D6, D19, D20, Contracts, S2, B1, B2, D2, U1, LIVE preamble/L5/L6), `logs/rn-forced-signin/14-designing.md` (Re-amendment) and `16-spec-review.md` (PASS). Rework items only.

- [x] **R1. Positional Google id + Apple on both variants** — `app-native/app.config.ts`.
  - Delete `VARIANTS[v].signIn` (type + both entries); export `VARIANTS` read-only for the B1 "no `signIn` key" pin.
  - `googleIosClient(variant, env, readRootEnv)`: split on commas, trim, KEEP empty slots; all empty/unset → null; 1 entry → both variants; 2 → prod idx 0, dev idx 1 (empty or malformed slot → null for that variant); >2 → throw naming the count and the `<prod id>,<dev id>` shape, never a value.
  - `buildConfig`: passes its variant; `ios.usesAppleSignIn: true` and `extra.appleSignIn: true` on both variants unconditionally.
  - Done-when: typecheck clean; B1 jest (R3) green.
- [x] **R2. eas.json** — `testflight` = `extends: production`, `distribution: store`, `autoIncrement`, `environment: production`, env `APP_VARIANT=prod` + `EXPO_PUBLIC_API_BASE=https://astrace.onrender.com`, channel `production`; `production` gains `environment: production`. Dev profiles unchanged. Done-when: B2 jest green.
- [x] **R3. `app-native/src/app-config.test.ts` B1/B2 rewrite** — every positional edge from spec B1 (prod/dev pair, single entry both, spaces, `,dev`, `prod,`, malformed slot, unset/`","` with Apple still on, 3 entries throw with `3` and no ids), no `signIn` key in `VARIANTS`, the app-native-wide `EXPO_PUBLIC_GOOGLE`/`GOOGLE_IOS_CLIENT_IDS` scan (excluding node_modules/ios/android); B2 per spec. Done-when: green, and plant-and-revert probes (first-entry rule restored; `signIn` key re-added; testflight back to dev) each go red.
- [x] **R4. Server tests** — S2: `ios_client_ids()` on `"a, b,,c"` → `[a,b,c]` and the fake receives that list (`test_native_signin.py`). D2: a fake `aud: com.astrace.app` deletion → exchange and revoke carry `client_id=com.astrace.app` and the client secret's `sub` is `com.astrace.app` (`test_native_signin_live.py`). No server code change expected (google.py and service.py already match D3/D6). Done-when: db-less suite and live-PG suite green.
- [x] **R5. Comment/doc touch-ups in code** — `platform/sign-in.ts` and other comments that say "dev only"/"first entry" (grep), `.env.example` GOOGLE_IOS_CLIENT_ID comment. Done-when: `grep -rn "dev only\|FIRST entry\|signIn flag"` over the changed files has no stale hit.
- [x] **R6. Docs** — CLAUDE.md Commands bullet (positional rule, Apple both variants, testflight = prod), `docs/ARCHITECTURE.md` matching passages, `docs/features/rn-forced-signin.md` (primary checkout) "Rework" section. Done-when: `grep -n "signIn\|FIRST\|dev variant only" CLAUDE.md docs/ARCHITECTURE.md` has no stale sign-in hit.
- [x] **R7. Validate** — root `npm test`, `npm run typecheck`; server db-less pytest; live-PG native suites on 127.0.0.1:54317; `npx expo config --json --type public` dev and prod with fake ids covering the slot rule. Logs 17/18.
