# 02 · spec-review (round 1)

**Verdict: FAIL**, with three real defects. The spec is otherwise strong: its intent matches the rulings, its scope is right-sized, its criteria are concrete, and LIVE is cleanly separated.

## Facts verified against the code (branch `dev`, 04ae600)

- **Refresh hang (fix a) is diagnosed correctly.** `app-native/src/account/tokenStore.ts` `runRefresh()` posts through core `apiFetch`. A 401 there makes `apiFetch` call `provider.refresh()`, which returns the same pending `inFlight` promise that is awaiting it, so it never settles. A plain `fetch` refresh, as in `web-divination/src/platform/auth.ts:61`, is the right fix.
- **Cold-start race (fix b) is diagnosed correctly.** `platform/boot.ts` ends with `void tokenStore.loadFromSecureStore()`, which is fire-and-forget.
- **Routes match.** main.py serves exactly the nine identity-free native routes that D8 lists, plus `/api/chart`. web-divination's only non-`/api/web` and non-planet_chat request is `/api/chart`, through core `chart/service.ts:60` (bare `fetch`). The web app never mounts the chart before `AuthGate` reaches signed-in, so adding a bearer does not race its restore.
- **Migration numbering is right.** Main-db migrations end at `013_planet_chat_rename.sql`, so 014 and 015 are the next free numbers. The web db has its own `web_migrations/` folder and ledger, so there is no collision.
- **The Apple revocation design stores nothing raw.** It keeps only `sha256("apple:"+sub)` and holds the code and tokens in local variables. Rule 12 holds. `users` is `id, email, created_at`. Profiles, journal, sessions and refresh_tokens all `ON DELETE CASCADE`.
- **The native libraries fit SDK 57.** `expo-apple-authentication` (~57.0.1), `expo-crypto` (~57.0.1) and `expo-constants` (~57.0.7) are in SDK 57's `bundledNativeModules.json`. `@react-native-google-signin/google-signin` is not in that file. Its latest is 16.1.5 with peer `expo >=52.0.40`, so it is compatible, but `npx expo install` will not pin it to an SDK version (see note N1).
- **Reload works in a store build.** `requestReload` uses expo's `reloadAppAsync`, which works in release builds, so the D15 wipe-and-reload does not depend on the dev client (ruling d).
- **The superseded decisions are handled correctly.** The dw-12 "app-native is untouched" line is in that entry's *Scoped defaults (Claude's)*, not its What. It is tier 3, and the spec revises it correctly under Supersedes.

## Defects (each must be fixed)

**F1. `/openapi.json` breaks the all-routes pin and the user ruling.**
- `FastAPI(... docs_url=None, redoc_url=None)` leaves `openapi_url` at its default. The served-route walk today includes `{GET, HEAD} /openapi.json`.
- That route is neither in D8's allowlist nor gated. `test_every_route_requires_a_bearer`, with `PUBLIC_ROUTES` "exactly D8's eight", goes red on unchanged code.
- It also contradicts the ruling "every route except /api/health and the sign-in routes requires a bearer".
- **Fix:** decide it. Recommended: `openapi_url=None` in main.py (nothing in the repo reads the schema; docs are already off). Add to R1/R5 that `GET /openapi.json` → 404, and that the pin's served set contains no `/openapi.json`.

**F2. The pin's in-handler recogniser does not match the code the spec keeps.**
- R1 accepts a route only if it has a gate dependency or its endpoint source calls `_require_user(` or `_caller(`.
- `DELETE /api/web/account` (`accounts/web/routes.py:205`) calls neither. It uses `service.delete_account(_parse_bearer(authorization))` and must stay byte-identical (Non-goals, R7). The pin therefore fails on the untouched web route.
- The two native routes D8 names as in-handler resolvers do not call `_require_user(` today either: `GET /api/auth/whoami` and `DELETE /api/auth/account`, which calls `delete_account(bearer…)` and needs the raw bearer for its Apple branch. The spec does not say they must.
- **Fix:** replace the source-regex recogniser with an explicit, exact `IN_HANDLER_AUTH` set of (method, path). It holds the three native in-handler routes (`whoami`, `DELETE /api/auth/account`, `/api/profiles*`) and every `/api/web/*` route outside the web allowlist.
- The pin checks three things:
  - (a) the served set equals `PUBLIC_ROUTES ∪ IN_HANDLER_AUTH ∪ gated`, with no stale entry;
  - (b) every `IN_HANDLER_AUTH` entry answers 401 with no bearer in an unstubbed test (live-PG), and 503 when its database is unset;
  - (c) a planted route that is in none of the three sets goes red.
- Keep the planted-violation self-checks R1 already lists.

**F3. Prod-variant behaviour is contradictory and cannot be checked.**
- The Non-goals say the prod variant builds "with `usesAppleSignIn: false` and no Google URL scheme… its gate reports 'not set up'". But D19 derives the Google `iosUrlScheme` and `extra.googleIosClientId` from `GOOGLE_IOS_CLIENT_ID` for every variant. Through the root-`.env` fallback, a local `APP_VARIANT=prod` build would pick up the dev client id and scheme.
- Nothing hides the Apple button on prod either. `AppleAuthenticationButton.isAvailableAsync()` is true on any iOS 13+ device whatever the entitlement, so prod would show an Apple button whose sheet fails. No "not set up" line for Apple is defined.
- **Fix:** add one variant flag in `VARIANTS` (for example `signIn: true` for dev only). It gates the Google plugin, `extra.googleIosClientId` and `ios.usesAppleSignIn`, and writes `extra.appleSignIn`. `platform/sign-in.ts`'s `appleAvailable()` then requires `extra.appleSignIn && isAvailableAsync()`.
- Extend B1: `APP_VARIANT=prod GOOGLE_IOS_CLIENT_ID=…` shows no google-signin `iosUrlScheme`, no `extra.googleIosClientId`, and `extra.appleSignIn` false or absent.
- Extend U1/U2: with both flags off, the gate shows the "isn't set up in this build" copy and no working buttons.

## Non-blocking notes (fold in while revising)

- **N1.** D1 says all three libraries install "with `npx expo install` (SDK 57 pins)". That is true for `expo-apple-authentication` and `expo-crypto`, not for google-signin, which is not in SDK 57's `bundledNativeModules.json`. Pin its major (`^16`) explicitly.
- **N2.** `platform/sign-in.ts` imports `expo-constants`, which is only a transitive dependency of `expo` today. Add it to `app-native/package.json` (~57.0.7) alongside the three.
- **N3. The two `onUnauthorized` listeners now cross-fire.**
  - `account/google-session.ts:216-230` says its listener "never fires" on native. After D10, native `postJson` 401s do report, so that listener will run on native. It calls `getAuthTokenProvider()?.clear()` on the native token store and sets the web session to `signed-out`.
  - Conversely, the native service's new module-load listener loads on web through the `@astrace/core/account` barrel.
  - Both are probably harmless, since the wipe clears the tokens anyway and native is never signed in on web. Pin them: add to C5 "on native a final 401 fires `onSessionEnded` exactly once", and to R7/web vitest "a web 401 never fires native `onSessionEnded`". Also update the stale comment.
- **N4.** D9's "`/api/health` is the only route that answers normally" is inaccurate without `DATABASE_URL`. `/api/web/*` and the planet_chat routes depend on `WEB_DATABASE_URL`, not `DATABASE_URL`. Reword it.
- **N5.** B1's "no file under `app-native/`" should exclude `node_modules/`, `ios/` and `android/`.
- **N6.** The WHAT sections (Decided defaults in particular) run well over the ~1,500-word pipeline budget. This is not a correctness defect.

## Checklist

1. **Serves the rulings, right-sized: yes.** The gate, the two providers, main-db native accounts, the removals and the new migration, the all-routes bearer rule, Settings → Account with Apple revocation, birth data via `/api/profiles` with no conflict UI, both fixes and the rule-12 rewrite are all covered. The additional rulings (a)–(f) are all encoded:
   - dev bundle only, with list audiences: D3, D19;
   - one env name, with extra-based runtime access and a derived scheme: D19, B1;
   - TestFlight and no dependence on the dev client: D20, B2, G1;
   - fakes only in tests, LIVE deferred: the AC preamble and L1–L5.

   Card-pixel auth and the web `/api/chart` bearer follow directly from "every route requires a bearer". No invented scope.
2. **Criteria checkable: yes, except where F1–F3 make R1 and B1 fail or leave them underspecified.** LIVE criteria are clearly separated.
3. **Contract: the rewrites are explicit.** Rules 3, 11 and 12 and the accounts paragraph are covered, and the guards are replaced by stronger pins (all-routes, PyJWT single importer, B4, provider-SDK and dev-client guards). F1 and F2 are the places where the new pin, as written, is unsound against the real route table.
4. **Non-goals stated; every open point decided: yes, except F3** (prod-variant gating is undecided, and contradicts itself).

Transition: spec-review → spec-review (revise)
