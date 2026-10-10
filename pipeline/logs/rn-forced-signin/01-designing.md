# rn-forced-signin — 01 designing

Date: 2026-09-30. Branch: `dev` (primary checkout, clean, HEAD 04ae600). No code changed, no branch switch, no commit. Root `.env` values not read (only `.env.example` names).

## Inputs read
- CLAUDE.md (rules 3, 5, 9, 11, 12, 13, 14, 15; backend/Commands paragraphs), pipeline/PIPELINE.md (skills per stage, pipeline-mode overrides, spec requirements, decision precedence), QUEUE.md entry `rn-forced-signin` (tier-1 user rulings 2026-09-30).
- Specs dw-12-google-sign-in, dw-16-web-account-db, dw-18-divination-auth.
- Coordinator-relayed user rulings received mid-stage (both tier 1, 2026-09-30):
  1. Dev bundle only (`com.astrace.app.dev`), with list-shaped audiences; the Google URL scheme derived from the client id in app config; the Apple key and capability on the dev App ID; a TestFlight-capable dev build against dev Render with no dev-client dependency.
  2. The native Google id lives in ONE env var, `GOOGLE_IOS_CLIENT_ID`: the server reads it as a comma list, `app.config.ts` reads the same var, the runtime gets it via `extra` / expo-constants, and there is no `…_IDS` and no `EXPO_PUBLIC_` duplicate.

## Code verified (targeted reads)
- server: `accounts/{routes,service,google,profiles,tokens,email}.py`, `accounts/web/routes.py`, `main.py` (full route list), migrations 001/002/003/006/007/013, `tests/conftest.py`, `tests/test_boundaries.py` (`_served_routes` walk, B4, email pin), `.env.example`, requirements.txt.
  - The conda env has cryptography 49, requests, httpx and google-auth 2.56.2. PyJWT is NOT installed, so the spec adds it.
- core: `platform/{api,auth,poll,index}.ts`, `account/{service,sync,types,index}.ts`, `identity-lifecycle`, `chart/service.ts`, `cards/image-uri.ts`; every `/api/` path in core and web-divination.
- app-native: `account/tokenStore.ts`, `account/deepLink.ts`, `platform/{boot,image-prefetch,mmkv-kv}.ts`, `theme/reload.ts`, `App.tsx`, `session.ts`, `settings/SettingsScreen.tsx`, the AccountSheet header, `app.config.ts`, `eas.json`, `package.json` (Expo SDK 57), `scripts/phone.sh`, the five `source={{ uri` image sites.

## Bugs confirmed
- (a) Refresh re-entry hang. `app-native/src/account/tokenStore.ts:60` `runRefresh` posts through `apiFetch`. A 401 on the refresh makes `apiFetch` (`packages/core/src/platform/api.ts:62`) call `provider.refresh()`, which returns the same in-flight promise, so the promise awaits itself and never settles. The fix is D14 (plain fetch in `platform/token-store.ts`, as in `web-divination/src/platform/auth.ts:61`); regression test C1.
- (b) Cold-start restore race. `app-native/src/platform/boot.ts` ends with `void tokenStore.loadFromSecureStore()` (fire-and-forget). `account/deepLink.ts` `startDeepLinkCatcher` checks `getRefreshToken()` synchronously once `getInitialURL()` resolves, so a slower Keychain read leaves the app anonymous. The fix is D13 (`bootAccount` awaits the load, then restores); regression test C2.

## Other findings that shaped decisions
- web-divination calls exactly one non-web, non-planet_chat route: `/api/chart`, via core `chart/service.ts:60` with a bare `fetch` and no bearer. The spec decides that `/api/chart` accepts a native OR web bearer (`require_account_or_web`) and that the chart seam moves to `postJson`. The web keeps working with its existing `webTokenStore`.
- web-divination imports only `google-session` from `@astrace/core/account`. Nothing it uses depends on OTP, link, cookie, native-landing or email.
- The cookie session shares the `sessions` table (no separate table). The dead tables are exactly `login_tokens` (001) and `otp_codes` (007). The next migration numbers are 014 (drop) and 015 (`apple_identities`).
- `postJson` without `{auth:true}` uses a bare `fetch`: every native generative route is called without a bearer today, so D10 makes every core request authenticated.
- Card pixels render in five `expo-image` sites plus one prefetch. The `remoteImageSource` helper carries the headers (D12).

## Skills
- `frontend-design` loaded first (gate + Settings → Account visual bar: system Apple button, a matched achromatic Google button, wordmark only, one status line, Reduce Motion branch).
- `feature-spec` (pipeline mode) wrote Goal / Non-goals / Decided defaults / Acceptance Criteria.
- `architecture-designer` (pipeline mode) wrote the Architecture section (reuse, module map, contracts, wire, forbidden edges, CLAUDE.md and guard amendments; no migration steps).
- The spec is over the ~1,500 + 1,500 word guidance (≈6,600 words including criteria). The coordinator ruled that completeness of decisions outranks the budget for this feature.

## Revision within the stage
- After the first write, the second coordinator message arrived (the single `GOOGLE_IOS_CLIENT_ID` ruling). The spec was revised in place:
  - `GOOGLE_IOS_CLIENT_IDS` → `GOOGLE_IOS_CLIENT_ID` (a comma list on the server).
  - `EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID` removed. `app.config.ts` now reads the same var from the env with a single-key root-`.env` fallback, uses the FIRST list entry, derives `iosUrlScheme` and writes `extra.googleIosClientId`, which the app reads via expo-constants.
  - EAS builds get the var from EAS environments (`environment` on each profile), not from `eas.json` `env`.
  - B1/B2/R5/L-header were updated. The earlier "copy the id into eas.json" decision was dropped.

## Output
- Spec: `pipeline/specs/rn-forced-signin.md`.
- Superseded DECISIONS.md headings are listed verbatim in the spec, including the tier-1 conflict: the dw-12 user ruling's "WEB tree only" scope versus the newer 2026-09-30 queue ruling, which governs.

## Transition
designing → spec-review
