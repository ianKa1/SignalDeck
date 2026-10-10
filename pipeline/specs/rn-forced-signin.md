# rn-forced-signin — app-native opens only after Google or Apple sign-in

## Goal

app-native gets a forced sign-in gate (Sign in with Apple, Sign in with Google). The server verifies the provider token, upserts the main-db user by email and mints the existing native bearer pair. Every route except `/api/health` and the sign-in/refresh/sign-out routes requires a bearer. OTP, magic link, cookie session and the email gateway are removed. QUEUE.md `rn-forced-signin` (user rulings 2026-09-30, plus the coordinator-relayed ruling of the same day: list-shaped audiences, one env name, a TestFlight-capable build).

> **Rework 2026-09-30 (user feedback, tier 1: "the app to launch is the PRODUCTION variant").** This replaces the earlier "dev bundle only" scope. Changed IDs:
> - Non-goals (prod setup → prod rollout);
> - D3 (comma-list audiences; re-amended: no tags);
> - D16 (variant-neutral Apple copy);
> - D19 (no `signIn` flag; Apple on both variants; per-bundle Google id);
> - D20 (`testflight` = prod);
> - Contracts (`google.ios_client_ids`, app config), plus the Reuse and module-map rows for app.config, eas.json and google.py;
> - CLAUDE.md Commands bullet;
> - S2, B1, B2, U1 (opt-out wording);
> - LIVE L1–L6 (L5 rewritten, L6 new).
> Every other decision and criterion is unchanged.
>
> **Re-amendment (user decision, tier 1, 2026-09-30).** The bundle-tag syntax is withdrawn. `GOOGLE_IOS_CLIENT_ID` is `<prod id>,<dev id>` and the build picks BY POSITION (D19). The `.env` Apple key that was in place then is being revoked; no criterion or step relies on its current values. Re-changed IDs: Non-goals, D3, D6, D19, D20, Contracts (google.py, app.config), the Reuse and module-map rows, the CLAUDE.md Commands bullet, S2, B1, D2, U1 (unchanged text, checked), the LIVE preamble, L5 and L6. This also folds in review 15's F1, F2 and notes 1, 3 and 5.

## Non-goals

- *(Rework)* Production ROLLOUT: merging `dev` → `main`, the prod Render dashboard env vars, and running migrations 013–015 on the prod database. The prod VARIANT itself is in scope: it builds with both providers (D19, D20), and its sign-ins are proven against a non-prod backend (L6).
- Android sign-in.
- Any web-divination behaviour change: `/api/web/*`, the web Google flow and the planet_chat gate stay byte-identical. The one web-visible delta is that `/api/chart` now needs the bearer the web app already holds (D11).
- Merging web and native identities (dw-16 ruling); onboarding after first sign-in (`rn-onboarding-after-signin`); rate-limiting sign-in; storing any provider token, name or picture; a `submit.testflight` block (the existing `submit.production` `ascAppId` submits a `testflight` build, post-rollout, see L5); removing the opening animation (it still plays, then hands off to the gate or the app); the dev variant's NSLocalNetworking strings (dev-only, never in a store build now that `testflight` is prod). *(Re-amended: stale text reworded.)*

## Decided defaults

1. **SDKs (iOS only).**
   - Google: `@react-native-google-signin/google-signin` `^16` (not in SDK 57's bundle list, so it is pinned by hand), Original API plus its config plugin. `configure({iosClientId})` with no `webClientId`, so `aud` is the iOS client id; the id comes from `extra.googleIosClientId`.
   - Apple: `expo-apple-authentication`, EMAIL scope only.
   - `expo-crypto` (nonce) and `expo-constants` (a direct dependency now) are added via `npx expo install`.
   - A dev-client rebuild is needed (and brings a new fingerprint).
2. **Apple nonce.** The client draws a raw random nonce, passes `sha256hex(raw)` to Apple and sends `raw` to the server. The server requires `claims.nonce == sha256hex(raw)`. Google needs no nonce; `exp` bounds replay.
3. **Server verification.**
   - Google: the existing `accounts/google.py` (issuer, signature, `exp`), with `aud` ∈ the audiences parsed from `GOOGLE_IOS_CLIENT_ID` (D19: split on commas, trim each entry, drop empties; every remaining entry is an audience, however many there are) and `email_verified is True`. *(Rework, re-amended: no tags.)*
   - Apple: the new `accounts/apple.py`, RS256 against Apple's JWKS (cached 1 h), with `iss` `https://appleid.apple.com`, `aud` ∈ `APPLE_BUNDLE_IDS`, `exp`, `sub`, the nonce check, and `email_verified` accepted as `true` or `"true"`.
4. **Identity (main db).**
   - Users are upserted by email.
   - Google stores no subject.
   - Apple gets `apple_identities(subject_hash PK, user_id FK users ON DELETE CASCADE, created_at)`, with `subject_hash = sha256("apple:"+sub)`, looked up first. If it is found, that user signs in. If it is not found and there is an email, upsert by email and link. If there is neither, the answer is 401 `apple email missing`.
   - One email is one account across providers; relay addresses are just emails.
5. **PII ruling.** Email stays the ONLY PII. The Apple `sub` is an opaque team-scoped id, kept only as a hash. No provider token, code or refresh token is ever stored or logged.
6. **Deletion and Apple revocation.** `DELETE /api/auth/account` (bearer) takes an optional `{apple: {identityToken, authorizationCode, nonce}}`.
   - A user with no Apple link is deleted at once.
   - An Apple-linked user must send the body, from a fresh Sign in with Apple run at deletion time. The server verifies the token and requires its subject hash to be this user's link. It exchanges the code at `https://appleid.apple.com/auth/token`, with `client_id` = the token's `aud`, i.e. the signing app's OWN bundle (`com.astrace.app` from the prod app, `com.astrace.app.dev` from dev; re-amended, explicit) and a `client_secret` JWT (ES256; `kid` `APPLE_KEY_ID`; `iss` `APPLE_TEAM_ID`; `sub` = client_id; `aud` `https://appleid.apple.com`; 5-minute life). It then revokes the returned refresh token at `/auth/revoke`, using local variables only.
   - The user is deleted only after a successful revoke; the delete cascades everything.
   - No body → 422 `apple reauthorization required`. A bad or foreign token → 403. Revocation unconfigured → 503. Exchange or revoke fails → 502 `apple revoke failed`, and nothing is deleted.
7. **Test seams.** Module-level functions that tests monkeypatch (the `google._verify_token` precedent): `google._verify_token`, `apple._verify_token`, `apple._post`. The client secret is tested with a P-256 key generated in the test. No suite reaches Google or Apple.
8. **Route auth.** Every served route is in exactly one of three exact sets (the pin, Architecture):
   - PUBLIC (no bearer): `GET /api/health`; `POST /api/auth/{google,apple,token/refresh,logout}`; `POST /api/web/auth/{google,token/refresh,logout}`. Logout is bearer-optional and answers 204 even for a dead pair.
   - GATED (decorator dependency; its value reaches no handler, so rule 9 holds):
     - `require_account` (native): `/api/transits`, `/api/transits/standing`, `/api/transits/day`, `/api/analysis`, `/api/analysis/deck`, `/api/analysis/transit-card`, `/api/analysis/transit/today`, `GET /api/analysis/card/{card_key}` and `/api/ask/fitness`;
     - `require_account_or_web`: `/api/chart`, web-divination's one non-web route;
     - `require_web_account`: the four planet_chat routes, unchanged.
   - IN_HANDLER_AUTH (the handler resolves the bearer itself, unchanged in kind):
     - native (5): `GET /api/auth/whoami`, `DELETE /api/auth/account`, `GET /api/profiles`, `PUT|DELETE /api/profiles/{nickname}`;
     - web (7): `GET /api/web/auth/whoami`, `DELETE /api/web/account`, `GET|PUT /api/web/profile`, `GET /api/web/sessions`, `PUT|DELETE /api/web/sessions/{session_id:path}`.
   - 8 + 14 + 12 = 34 served routes. `FastAPI(openapi_url=None)` removes the schema route (docs and redoc are already off; nothing reads the schema).
9. **Dormancy.** Without `DATABASE_URL`, the native GATED and native IN_HANDLER routes and the native sign-in routes answer 503 `accounts unavailable`. `/api/chart` answers 503 only when neither database is configured. `/api/health` still answers 200. The `/api/web/*` and planet_chat routes keep depending on `WEB_DATABASE_URL` alone. `GOOGLE_IOS_CLIENT_ID` unset → `/api/auth/google` 503; `APPLE_BUNDLE_IDS` unset → `/api/auth/apple` 503; certificates or JWKS unreachable → 503. Order: 422 body → 503 db → 503 provider → 401 (the gated routes answer 401/503 before the body is validated, dw-18 order).
10. **Client transport; one rule for a final 401.** Every core request carries the bearer. `postJson` always goes through `apiFetch`, and its `auth` option is removed. Core `chart/service.ts` moves to `postJson`. ANY final 401 (after the one refresh) on a bearer request made while signed in ends the session (D15), whichever path sent it:
    - `postJson` reports it;
    - `account/sync.ts` reports its own `/api/profiles` 401s;
    - restore's `whoami` handles it directly (D13);
    - logout and delete are session ends already.
11. **Web keeps working.** The web app's `/api/chart` request now carries its web bearer, which `require_account_or_web` accepts. A final 401 there signs the browser out, exactly like a planet_chat 401 today.
12. **Card pixels.** `GET /api/analysis/card/{card_key}` needs the native bearer and answers `Cache-Control: private, max-age=31536000, immutable`. The five remote `<Image>` sites and `prefetchImages` send the bearer via `remoteImageSource(uri)`. An expired token fails like a missing image; this is accepted because boot's `whoami` refreshes the pair first.
13. **Boot (fix b).** `boot.ts` no longer fire-and-forgets the Keychain load. `bootAccount()` awaits `loadFromSecureStore()`, then runs core `restoreAccount()`:
    - no refresh token → `signed-out`, with no request;
    - otherwise `whoami` via `apiFetch`: 200 → `signed-in` + sync; a final 401 → session ended (D15); 503 → `unavailable`; a throw → `offline` (tokens kept on both). This is deliberate: a signed-in user launching offline sees "Can't reach Astrace" + Try again, not the app (every screen needs the network). The hand-back flags it for the user.
    The gate shows only the wordmark until the status settles.
14. **Refresh (fix a).** The token store moves to `app-native/src/platform/token-store.ts` and refreshes with a plain `fetch(apiUrl('/api/auth/token/refresh'))` with no Authorization header, mirroring `web-divination/src/platform/auth.ts`. A 401 there returns `false` instead of re-entering its own in-flight promise.
15. **Session end = device wipe.** Sign out, Delete account, a final 401 while signed in, and a dead pair at restore each fire core `onSessionEnded` once. The app then clears:
    - every MMKV key except `astrology.lang.v1` and `astrology.ground.v1`;
    - the secure-store triple;
    - the expo-image memory and disk caches;
    - `GoogleSignin.signOut()`.
    Then it calls `requestReload()`. Sign out posts `/api/auth/logout {refreshToken}` best-effort (5 s cap), with no confirmation. An anonymous upgrader (no tokens) is not wiped. Each `onUnauthorized` listener acts only on its own session: the native service ignores the signal unless a native session is signed in, and web `google-session` ignores it unless the web session is signed in (its stale "never fires on native" comment is corrected).
16. **Gate** (`account/SignInGate.tsx`, rendered by `App.tsx` instead of `AppShell` unless the status is `signed-in`).
    - The ground; the wordmark as `<Txt variant="title">` at ~38 % height; two buttons in the lower third, each 50 pt tall, `min(width − 2·space.xl, 320)` wide, radius 25, `space.md` apart.
    - Apple first: the system `AppleAuthenticationButton` (SIGN_IN; WHITE on the dark ground, BLACK on light grounds; its label is in the device locale). Google second: a Pressable in the same achromatic pair (new tokens `signInFill`/`signInInk`, `PAINT.signInButton`), with Google's "G" PNG and "Sign in with Google" / "通过 Google 登录" as a marked local raw Text.
    - One `note` line below:
      - "Signing in…" (buttons disabled);
      - "Sign-in didn't go through. Try again.";
      - for `no-email`: "Apple didn't share an email. In Settings › Apple ID › Sign in with Apple, stop using Astrace, then try again. *(Rework: variant-neutral; the dev app's name also begins "Astrace".)*";
      - "Sign-in is unavailable right now." / "Can't reach Astrace.", each with "Try again" (`actionQuiet`, re-runs `bootAccount`) and the buttons hidden.
    - Not set up in this build (`googleConfigured()` / `appleConfigured()` false) → that button renders DISABLED, with "Google sign-in isn't set up in this build." / "Apple sign-in isn't set up in this build." Apple configured but the device reports it unavailable → the Apple button is ABSENT.
    - A cancelled sheet shows no line. The buttons fade in over 400 ms, with no animation under Reduce Motion. Nothing else is on screen. zh has parity.
17. **Birth data follows the account, no conflict UI.** After each sign-in or restore, sync pulls `/api/profiles`:
    - the pull fails → abort, and push-on-save stays unarmed;
    - the account has data → it is adopted silently (server wins);
    - the account is empty and the device has data → upload (keeps an anonymous upgrader's chart);
    - both empty → the first-run entry.
    The conflict channel and `useMergeState` are deleted.
18. **Settings → Account** (`account/AccountSection.tsx` replaces the row and `AccountSheet`).
    - An eyebrow, the email (`fieldValue`), then "Sign out" and "Delete account…" (`actionQuiet`).
    - Delete opens an inline confirm: `prose` "Delete your account and everything saved to it? This can't be undone.", then "Delete account" (`actionLabel`, `waiting` "Deleting…") and "Keep".
    - For an `appleLinked` account, Sign in with Apple runs first; a cancel keeps the confirm open.
    - A failure shows the `note` "Couldn't delete your account. Try again."
    - A 204 ends the session (D15).
    - `whoami` and both sign-in responses carry `appleLinked`.
19. **Env names and the per-variant Google id (FINAL; rework re-amended 2026-09-30, user decision).**
    - Server:
      - `GOOGLE_IOS_CLIENT_ID`: still the ONE name (no `…_IDS`, no `EXPO_PUBLIC_` duplicate). Written `<prod id>,<dev id>`: comma-separated, no spaces, PRODUCTION (`com.astrace.app`) FIRST, DEV (`com.astrace.app.dev`) SECOND. The server splits on commas, trims, drops empties and accepts every entry as an audience. There are no tags.
      - `APPLE_BUNDLE_IDS`: `com.astrace.app,com.astrace.app.dev`.
      - `APPLE_TEAM_ID`, `APPLE_KEY_ID`.
      - `APPLE_PRIVATE_KEY`: the `.p8` PEM, with `\n` escapes unescaped.
      - Removed: `RESEND_API_KEY`, `EMAIL_FROM`, `APP_BASE_URL`. Web `GOOGLE_CLIENT_ID` is unchanged.
    - **The build picks by position.** A Google client id does not encode its bundle, so the order is the contract. `app.config.ts` reads `GOOGLE_IOS_CLIENT_ID` (from `process.env`, else that single key from the repo-root `.env`), splits it on commas, and trims each entry, KEEPING empty slots so positions never shift:
      - all entries empty, or the variable unset → Google is cleanly disabled on both variants: no plugin, no `extra.googleIosClientId`, and the gate shows the disabled button with its note (D16). This is the guard that replaces the old flag.
      - exactly ONE entry → BOTH variants use it (the single-value rule, e.g. a per-environment EAS value).
      - exactly TWO entries → `APP_VARIANT=prod` takes entry 1 and `dev` takes entry 2. An empty slot (`,<dev>` or `<prod>,`) disables Google for that variant only.
      - MORE than two entries → `app.config.ts` THROWS, with a message naming the entry count and the expected `<prod id>,<dev id>` shape, never a value. A silent "use the first two" could ship the wrong id after a careless append.
      - The chosen entry must match `<prefix>.apps.googleusercontent.com`. A malformed entry disables Google for that variant only.
      - From the chosen id the config derives the google-signin plugin's `iosUrlScheme` (`com.googleusercontent.apps.<prefix>`) and writes `extra.googleIosClientId`.
    - **Apple on both variants.** The `VARIANTS[v].signIn` flag is REMOVED. Both variants set `ios.usesAppleSignIn: true` and `extra.appleSignIn: true`. `appleConfigured()` stays (it reads `extra.appleSignIn`), so a future variant can opt out by data alone.
    - **What the user sets** (`<PROD_ID>` / `<DEV_ID>` = the two iOS OAuth client ids, each `….apps.googleusercontent.com`). The live checks run only after the user supplies the NEW Apple key and key id; the current `.env` key is being revoked.
      - repo-root `.env`: `GOOGLE_IOS_CLIENT_ID=<PROD_ID>,<DEV_ID>`, `APPLE_BUNDLE_IDS=com.astrace.app,com.astrace.app.dev`, plus `APPLE_TEAM_ID`, the new `APPLE_KEY_ID` and the new `APPLE_PRIVATE_KEY`.
      - EAS environments, one value each (the single-value rule applies): `production` → `GOOGLE_IOS_CLIENT_ID=<PROD_ID>`; `preview` and `development` → `GOOGLE_IOS_CLIENT_ID=<DEV_ID>`. The full `<PROD_ID>,<DEV_ID>` pair is also correct in any of them. Visibility must be plain text or sensitive, NOT secret, so `app.config.ts` resolves the same value locally (`eas build` config resolution) and on the build server. The value is public anyway.
      - dev Render (`astrology-dev`): `GOOGLE_IOS_CLIENT_ID=<PROD_ID>,<DEV_ID>` plus the four Apple variables (the server accepts both ids).
      - prod Render: the same five, but only at the user's rollout (non-goal).
      - Apple Developer: Sign in with Apple enabled on BOTH App IDs. The user is creating a NEW key now, so make `com.astrace.app` the key's PRIMARY App ID and group `com.astrace.app.dev` under it. Users then see the production identity in Apple ID settings and the consent sheet. One `.p8` key signs both bundles' revocation secrets, and the server is unchanged either way (`client_id` = token `aud`).
      - Google Cloud: a second iOS OAuth client for `com.astrace.app`.
20. **Build profiles (rework 2026-09-30).**
    - `testflight` is now the PROD variant: `extends: "production"`, `distribution: "store"`, `autoIncrement: true`, `environment: "production"`, env `APP_VARIANT=prod` and `EXPO_PUBLIC_API_BASE=https://astrace.onrender.com`, channel `production`.
    - `production` also names `environment: "production"`. `development` → `development` and `preview` → `preview` are unchanged (dev variant, dev Render).
    - Nothing Google-related is committed to `eas.json`. Local builds use the root-`.env` fallback. Switching the local `ios/` project between variants needs `npx expo prebuild --clean` first, as `scripts/phone.sh` does.
    - The sign-in path imports no `expo-dev-client` / `expo-dev-launcher` / `expo-dev-menu`, reads no `__DEV__`, and names no localhost or LAN address (unchanged).
21. **Removed** (itemized in the module map): the email gateway; the link, OTP, cookie and native-landing flows, routes, helpers and tests; `AccountSheet`, `OtpInput`, `deepLink`, `useMergeState`. Migration 014 drops `login_tokens` and `otp_codes`, and 015 creates `apple_identities`; `sessions` and `refresh_tokens` stay.
22. **Validation environment.** Live-PG tests run on a throwaway local cluster (`test_auth_integration.py` recipe); a skip is not a pass. Every backend run sets `DATABASE_URL` and `WEB_DATABASE_URL` explicitly and never uses the Neon URLs.

### Earlier decisions this supersedes (journal them under **Supersedes**, verbatim)

- *(Rework 2026-09-30)* `### 2026-09-30 · rn-forced-signin · spec-review — spec auto-approved (round 3); forced Google + Apple native sign-in on the main db, OTP/magic-link/cookie/email removed, every route bearer-gated`. Only its "dev bundle only" scope is superseded, through three of its points:
  - the dev-only `VARIANTS[v].signIn` flag (prod: no Apple, no Google);
  - "the build uses the FIRST list entry";
  - the `testflight` profile as the dev variant against dev Render (EAS `preview`).
  The newer user feedback (QUEUE `feedback:` 2026-09-30, tier 1) governs. Every other point of that approval stands.
- *(Rework)* `### 2026-09-30 · rn-forced-signin · accepting — every non-LIVE criterion PASS; parked `blocked` on the user's credentials and live sign-in (L1–L5)`: its B1/B2 verdicts and L1–L5 list are stale for the reworked criteria and are re-graded.

- `### 2026-09-28 · dw-12-google-sign-in · user ruling — forced Google sign-in for the web app`: its What scopes the forced gate to "the WEB tree only", and its scoped default says "app-native is untouched". CONFLICT with a tier-1 entry: the queue's 2026-09-30 user ruling is newer and forces sign-in on app-native, so the newer ruling governs. The web half stands.
- `### 2026-09-28 · dw-12-google-sign-in · spec-review — spec auto-approved (round 1); forced web gate over the existing bearer path; CLAUDE.md "accounts optional" amended for web only`: the "accounts optional" text is removed for native too.
- `### 2026-09-29 · dw-18-divination-auth · spec-review — spec auto-approved (round 2); the four divination routes gated in main.py by accounts/web's `require_web_account`, the client bearer via apiFetch`: its non-goal "native and shared routes stay exactly as they are", including `/api/chart` unauthenticated, and `postJson`'s opt-in `auth`.
- `### 2026-09-29 · dw-16-web-account-db · spec-review — spec auto-approved (round 1); a separate web db behind a second `app/db` door, accounts/web package, the browser copy as an owned cache`: ONLY its route-removal half is superseded ("`/api/auth/google` and `service.sign_in_google` are removed", pinned by `test_web_accounts.py::test_a4_main_db_google_route_is_gone`), together with the B4 "one app importer" pin. A NATIVE `/api/auth/google` (`{idToken}`, iOS audiences, main db) returns under a new contract. The separate web db, every `/api/web/*` route and the two-accounts-per-email rule stand. This is a tier-3 loop decision, revised here.
- `### 2026-08-28 · signin-birthdata-merge · spec-review — auto spec approval (PASS)`, `### 2026-08-28 · signin-birthdata-merge · planning — push-on-save arms only after a successful pull` (its refresh-path "conflict held" half only; arm-after-pull stays) and `### 2026-08-28 · signin-birthdata-merge · accepting — auto-finalized (ALL PASS 10/10)`: the conflict ask is removed. The ask was user ruling 3 of 2026-08-28 (queue notes). The newer queue ruling "no conflict UI" governs.
- No `rn-auth-otp` / `rn-accounts-*` / magic-link entries survive in DECISIONS.md (history cleared 2026-07-25). Their surviving encodings are CLAUDE.md rule 12's OTP/native-landing/cookie paragraphs and the backend "Accounts are OPTIONAL" paragraph, which are loop-derived text rewritten here.

## Architecture

There is no epic file; the reuse below was verified by targeted reads on `04ae600` (branch `dev`).

### Reuse

| Need | Existing | Use |
|---|---|---|
| Identity mint | `accounts/service.py` `_require_db` :16, `_upsert_user` :45, `_mint_bearer` :58, `refresh_access` :213, `session_user_id` :248, `whoami` :263, `logout` :277, `delete_account` :298 | Reused. `delete_account` gains the Apple branch. |
| Google verification | `accounts/google.py` `_verify_token` :82, `verified_email` :92 (cached certs :42) | `verified_email(credential, audiences=None)`: `None` reads `GOOGLE_CLIENT_ID` exactly as today (web byte-identical); native passes the parsed `GOOGLE_IOS_CLIENT_ID`; an empty list raises `GoogleUnconfigured`. |
| Bearer parse | `accounts/routes.py` `_parse_bearer` :71 | Used by the new gates. |
| Web bearer | `accounts/web/routes.py` `_caller` :115, `require_web_account` :126; `web/service.py` `WebUnavailable` :18, `_require_web` :24, `user_for` :102 | `require_account_or_web` falls back to `web.service.user_for`. |
| Route walk and pins | `tests/test_boundaries.py` `test_b1_web_door_named_only_by_db_accounts_web_and_main` :979, `test_b4_google_verifier_has_one_app_importer` :1075, `_served_routes` :1094, `_route_dependencies` :1109 | The new all-routes pin. |
| Suite stub precedent | `tests/conftest.py` :105-138 (`PLANET_CHAT_ROUTE_TEST_MODULES` :105, `_web_account_gate_stubbed` :116) | The inverted native-gate stub (below). |
| Bearer transport | core `platform/api.ts` `apiFetch` :47, `platform/auth.ts` `onUnauthorized`/`reportUnauthorized`, `platform/poll.ts` `postJson` :41 | `postJson` loses the opt-in (D10). |
| Plain-fetch refresh | `web-divination/src/platform/auth.ts` :61 | Mirrored in `app-native/src/platform/token-store.ts`. |
| Sync | core `account/sync.ts` `startSync` :149, slot logic :159-162, `armPushOnSave` :136 | Conflict branch → adopt. |
| Wipe | core `identity-lifecycle` `wipeAllLocal`; `profile.clearAllProfiles`; `app-native/src/theme/reload.ts` `requestReload` | Session end. |
| KV | `app-native/src/platform/mmkv-kv.ts` `instance()` :24 | + `clearExcept(keep)`. |
| Image | `app-native/src/platform/image-prefetch.ts` :20; five `source={{ uri` sites (`gallery/GalleryScreen.tsx:294`, `cards/detail/CardDetail.tsx:817`, `transit/PinnedHeader.tsx:59`, `transit/CardStage.tsx:106`, `readings/DeckCard.tsx:112`) | → `remoteImageSource`. |
| Variants | `app.config.ts` `VARIANTS` :45, `resolveVariant` :94 | + the Google plugin chosen by position (prod 1st, dev 2nd, a single entry for both); Apple on both (rework: no `signIn` flag). |

### Module map (created or changed only)

```
server/
├── requirements.txt                  CHG  + PyJWT[crypto]>=2.8
└── app/
    ├── accounts/
    │   ├── apple.py                  NEW  sole PyJWT importer and sole referencer of appleid.apple.com:
    │   │                                  verify identity token, client-secret JWT, exchange + revoke
    │   ├── google.py                 CHG  verified_email(credential, audiences=None); ios_client_ids(): every non-empty trimmed entry (rework, no tags)
    │   ├── gate.py                   NEW  require_account, require_account_or_web (decorator dependencies)
    │   ├── service.py                CHG  + sign_in_google, sign_in_apple, apple_linked; delete_account(apple);
    │   │                                  − link/OTP/cookie flows; no email import
    │   ├── routes.py                 CHG  + POST /google, /apple; whoami/delete bearer-only; − 5 routes, − Cookie
    │   ├── tokens.py                 CHG  − login/session/cookie/OTP/link helpers; + hash_subject(provider, sub)
    │   ├── ratelimit.py              CHG  − LINK_*/OTP_* constants
    │   └── email.py                  DEL
    ├── db/migrations/014_drop_email_sign_in.sql   NEW  DROP TABLE login_tokens, otp_codes
    ├── db/migrations/015_apple_identities.sql     NEW
    └── main.py                       CHG  openapi_url=None; dependencies=[Depends(require_account)] ×9,
                                           require_account_or_web on /api/chart; card Cache-Control private
server/tests/
├── test_native_signin.py             NEW  google/apple routes, claim policy, dormancy (fakes)
├── test_native_signin_live.py        NEW  DATABASE_URL-guarded: upsert, link, deletion + revoke, no-PII dump
├── test_apple.py                     NEW  verifier policy, client secret (test P-256 key), exchange/revoke fake
├── test_route_auth.py                NEW  gate behaviour, every gated route 401/503, allowlist
├── conftest.py                       CHG  suite-wide native-gate stub except the gate modules
├── test_boundaries.py                CHG  all-routes pin; PyJWT pin; email pin rewritten; B4 importers
├── test_otp_auth.py, test_accounts_email.py   DEL
├── test_web_accounts.py              CHG  A4 replaced by A4′ (native /api/auth/google exists, never touches the web door)
├── test_ratelimit.py                 CHG  SlidingWindow units kept; the request-link gate test removed
├── test_db_integration.py            CHG  post-migration table set: login_tokens absent (was :51 present)
├── test_profiles_integration.py      CHG  users minted via _upsert_user/_mint_bearer, not request-link (:49-54)
├── test_auth_api.py, test_auth_integration.py, test_native_tokens.py (astrace://login cases),
│   test_accounts_tokens.py (login/link helpers)   CHG  cookie/link/OTP cases removed, bearer-only
└── unchanged on purpose: test_db.py (:67 asserts the immutable 001 file text), test_profiles_api.py,
    test_web_accounts_live.py (A3 still holds), test_google_auth.py (web path)
packages/core/src/
├── account/service.ts                CHG  signInWithProvider, restoreAccount, logout, deleteAccount(apple?),
│                                          onSessionEnded, appleLinked; − link/OTP/cookie; onUnauthorized hook
├── account/sync.ts                   CHG  − conflict channel; account wins
├── account/google-session.ts         CHG  onUnauthorized listener acts only when the web session is signed in; comment fixed
├── account/types.ts, index.ts        CHG  AccountStatus + 'offline'; SignInOutcome; exports
├── account/service.test.ts, sync.test.ts   CHG  link/OTP/conflict cases → provider sign-in, account-wins
├── platform/poll.ts                  CHG  postJson always via apiFetch + report; − PostJsonOptions
├── platform/api.ts, auth.ts          CHG  comments only (every surface installs a bearer provider)
├── chart/service.ts                  CHG  postJson instead of bare fetch
└── planet_chat/{summary,persona,roster}.ts  CHG  drop `{auth:true}` argument
app-native/
├── app.config.ts                     CHG  google-signin plugin from the entry at this variant's position; usesAppleSignIn on both (rework)
├── eas.json                          CHG  + testflight (prod, extends production); `environment` on all four profiles (rework)
├── package.json                      CHG  + google-signin ^16, expo-apple-authentication, expo-crypto, expo-constants
├── assets/brand/google-g.png         NEW
└── src/
    ├── App.tsx                       CHG  opening → SignInGate | AppShell by status; bootAccount once
    ├── platform/token-store.ts       NEW  (moved from account/tokenStore.ts) plain-fetch refresh
    ├── platform/account-boot.ts      NEW  bootAccount(); onSessionEnded → wipeDevice → requestReload
    ├── platform/sign-in.ts           NEW  the one importer of google-signin, expo-apple-authentication, expo-crypto
    ├── platform/device-wipe.ts       NEW  MMKV clearExcept, secure clear, image caches, Google signOut
    ├── platform/remote-image.ts      NEW  remoteImageSource(uri)
    ├── platform/image-prefetch.ts, mmkv-kv.ts, boot.ts   CHG
    ├── account/SignInGate.tsx        NEW
    ├── account/AccountSection.tsx    NEW
    ├── account/useAccount.ts         CHG  (kept)
    ├── account/{AccountSheet,OtpInput,deepLink,useMergeState,tokenStore}.ts(x) DEL; their tests
    │   (account-sheet, account-merge, otp-input, deepLink) DEL; tokenStore.test.ts → platform/token-store.test.ts
    ├── platform/boot.test.ts, platform/secure-store.ts (comment), settings/settings.test.tsx (verifyToken → minted
    │   sign-in), surface-paint-rulings.test.tsx, text-variant-rulings.test.tsx (AccountSheet rulings)   CHG
    ├── settings/SettingsScreen.tsx   CHG  AccountSection replaces row + sheet
    ├── theme/tokens.ts, paint.ts     CHG  signInFill/signInInk; PAINT.signInButton
    ├── theme/reload.ts               CHG  comment: two callers
    ├── i18n/en.ts, zh.ts             CHG  − OTP/merge keys; + auth namespace
    └── five image sites              CHG  source={remoteImageSource(uri)}
web-divination/src/auth/core-planet-chat-auth.test.ts  CHG  C1 "without opts no header" → always sent
CLAUDE.md, .env.example, docs/text-variant-census.md   CHG
```

### Contracts

**`accounts/apple.py`** imports nothing from `app`.
- `AppleUnconfigured` and `AppleUnavailable` are its errors.
- `bundle_ids() -> list[str]`.
- `_verify_token(token, audiences) -> dict` is the only JWKS/PyJWT decode, monkeypatched by tests.
- `verified_identity(token, raw_nonce) -> AppleIdentity(sub, email | None, audience) | None`: unconfigured → raise `AppleUnconfigured`; JWKS unreachable → raise `AppleUnavailable`; any other failure (including a nonce mismatch, or an email present but unverified) → `None`.
- `client_secret(client_id, now) -> str` (ES256).
- `_post(url, form) -> dict` is the one HTTP call (httpx, 10 s timeout).
- `revoke_authorization(code, client_id) -> None` raises `AppleUnconfigured` / `AppleRevokeFailed`.
- Nothing here stores or logs a token, a code, a `sub` or claims.

**`accounts/google.py` (rework)**: `ios_client_ids() -> list[str]` splits `GOOGLE_IOS_CLIENT_ID` on commas, trims and drops empties; every entry is an audience, with no tags and no count limit on the server. The web path (`GOOGLE_CLIENT_ID`) is untouched.

**`app.config.ts` (rework, re-amended)**: `googleIosClient(variant, env, readRootEnv) -> {clientId, urlScheme} | null`. It implements D19's positional rule: unset or all-empty → null; one entry → that entry for both variants; two → prod is index 0 and dev is index 1, with an empty or malformed slot giving null for that variant; more than two → throw (count only, no values). `buildConfig` passes its own variant, and the `VARIANTS[v].signIn` field is deleted.

**`accounts/gate.py`**
- `require_account(authorization=Header(None)) -> None`: 503 `accounts unavailable` without `DATABASE_URL`; 401 `not signed in` unless `session_user_id` resolves the bearer.
- `require_account_or_web(...) -> None`: try `service.session_user_id(bearer)`, catching `AccountsUnavailable`; then try `accounts.web.service.user_for(bearer)`, catching `WebUnavailable`. If either resolves → pass. If BOTH raised → 503 `accounts unavailable`. Otherwise → 401. It decides dormancy ONLY through those two caught exceptions and never calls `db.is_configured`/`db.web_is_configured`/`db.connect_web`, so B1's web-door pin (only `db/`, `accounts/web/`, `main.py` name the web door) stays green unchanged.
- It imports `accounts.service`, `accounts.web.service` and `accounts.routes._parse_bearer`; `main.py` is its only importer.

**`service`**
- `sign_in_google(id_token)` and `sign_in_apple(identity_token, nonce)` return `(email, access, refresh, expires, apple_linked) | None | "no-email"`.
- `delete_account(access_raw, apple: dict | None) -> "deleted" | "unauthorized" | "apple-required" | "apple-rejected"`; it raises `AccountsUnavailable` and `AppleRevokeFailed`.
- Opportunistic expired-row cleanup as `verify_native` did.

**Core `account`**
- `signInWithProvider('google', {idToken}) | ('apple', {identityToken, nonce}) → Promise<SignInOutcome>`, where `SignInOutcome = 'ok' | 'invalid' | 'no-email' | 'unavailable' | 'error'`.
- `restoreAccount()`, `logout()`, and `deleteAccount(apple?) → 'ok' | 'failed' | 'unavailable'`.
- `onSessionEnded(cb)`. A module-load `onUnauthorized` listener ends a signed-in NATIVE session. `sync.ts` calls `reportUnauthorized()` itself on a final 401 from its `apiFetch` calls (`/api/profiles` GET/PUT), so every final 401 reaches that one listener (D15).
- `Account = {email, appleLinked} | null`.
- It never imports `web-account` or `google-session`. The provider SDKs stay app-side: core sees only token strings.

**App.** `platform/sign-in.ts` (the one reader of `Constants.expoConfig.extra.googleIosClientId` and `extra.appleSignIn`) exports `googleConfigured()` (`extra.googleIosClientId` set), `appleConfigured()` (`extra.appleSignIn === true`, the build flag alone), `appleAvailable()` (`appleConfigured() && await isAvailableAsync()`), `googleIdToken() → string | 'cancelled'` and `appleCredential() → {identityToken, authorizationCode, nonce} | 'cancelled'`, and throws on other errors. The gate renders the Apple button: ABSENT when `appleConfigured()` is true but the device reports unavailable; DISABLED with its "isn't set up" note when `appleConfigured()` is false; enabled otherwise. The `account/` UI calls these plus core. It never calls `fetch`.

### Wire

| Route | Auth | Body | Success | Errors |
|---|---|---|---|---|
| `POST /api/auth/google` | public | `{idToken}` (1–4096) | 200 `{email, appleLinked, accessToken, refreshToken, accessExpiresAt}` | 401 `not signed in`, 422, 503 |
| `POST /api/auth/apple` | public | `{identityToken (1–4096), nonce (16–128)}` | 200 same | 401 `not signed in` / `apple email missing`, 422, 503 |
| `POST /api/auth/token/refresh` | public | `{refreshToken}` | unchanged | unchanged |
| `POST /api/auth/logout` | public (bearer optional) | `{refreshToken?}` | 204 | 503 |
| `GET /api/auth/whoami` | native bearer | — | 200 `{email, appleLinked}` | 401, 503 |
| `DELETE /api/auth/account` | native bearer | `{apple?: {identityToken, authorizationCode, nonce}}` | 204 | 401, 403, 422, 502, 503 |
| `/api/profiles*` | native bearer | unchanged | unchanged | unchanged (the cookie is gone) |
| the nine identity-free native routes | `require_account` | unchanged | unchanged | + 401/503 before the body is validated |
| `POST /api/chart` | `require_account_or_web` | unchanged | unchanged | + 401/503 |

`apple_identities`: `subject_hash text PRIMARY KEY`, `user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE`, `created_at timestamptz NOT NULL DEFAULT now()`.

### Dependency rules and forbidden edges

- ❌ `jwt` (PyJWT) is imported only by `accounts/apple.py`, and `appleid.apple.com` appears only there. ❌ `google.auth`/`google.oauth2` stay only in `accounts/google.py`, whose app importers become exactly `accounts/service.py` and `accounts/web/service.py`.
- ❌ No `app/` file references `api.resend.com`, and `accounts/email.py` does not exist.
- ❌ No handler of a gated identity-free route takes an identity parameter. `chart/`, `interpretation/`, `cards/`, `ask/`, `planet_chat/`, `selection/` and `generation` never import `accounts`.
- ❌ `accounts/web/` never imports `accounts/gate.py` or `apple.py`, and the native service never names the web door (`gate.py` is the one module that sees both, read-only).
- ❌ Core `account/service.ts` never imports `google-session`, `web-account` or any provider SDK. ❌ Only `app-native/src/platform/sign-in.ts` imports `@react-native-google-signin/google-signin`, `expo-apple-authentication` or `expo-crypto`. ❌ No `source={{ uri` remains in `app-native/src` outside `platform/`. The existing rule that `fetch(`/`apiUrl(` appear only under `app-native/src/platform/` covers `token-store.ts`.

### Test-suite stub (decided)

`conftest.py` stubs `require_account` and `require_account_or_web` (`dependency_overrides → None`) for every module EXCEPT `NATIVE_GATE_TEST_MODULES = {test_route_auth, test_native_signin, test_native_signin_live, test_boundaries}`. These gates are orthogonal to what the ~100 route suites test. The gate is proven unstubbed in `test_route_auth.py`, which asserts at start that no override is installed. The route pin is static, so no stub can hide an open route. The dw-18 planet_chat stub list is untouched.

### CLAUDE.md and guard amendments (same commit)

- **Project/backend paragraph**: "Accounts are OPTIONAL (passwordless email magic link …)" becomes: accounts are REQUIRED on both clients. app-native signs in with Google or Apple on the main db (rn-forced-signin, user ruling 2026-09-30); web-divination signs in with Google on the web db. The server's only PII is the account email. The `APP_BASE_URL` paragraph is deleted. Commands gains the env names of D19: `GOOGLE_IOS_CLIENT_ID=<prod id>,<dev id>` (production first). The server accepts every id; a prod build takes entry 1 and a dev build entry 2; a single entry serves both; more than two fails the build. It also gains the `testflight` profile (the PROD variant against `https://astrace.onrender.com`) (rework).
- **Rule 3**: + "PyJWT (`jwt`) only by `server/app/accounts/apple.py`". The sentence "that module's ONE app importer is `accounts/web/service.py` (dw-16, `test_b4_google_verifier_has_one_app_importer`)" becomes "its app importers are exactly `accounts/service.py` (native, rn-forced-signin) and `accounts/web/service.py` (web, dw-16); pinned by `test_b4_google_verifier_app_importers`". The test is renamed because its old name would lie.
- **Rule 11**: the dormancy sentence becomes: "without `DATABASE_URL` every native-gated route answers 503; `/api/health` stays 200 with its additive `db` field; `/api/chart` also serves web bearers when only the web db is configured."
- **Rule 12**: rewritten.
  - Native identity is Google or Apple sign-in on `/api/auth/google|apple`, verified server-side (audiences `GOOGLE_IOS_CLIENT_ID` / `APPLE_BUNDLE_IDS`, Apple nonce), upserted by email, minting the bearer pair in `sessions` + `refresh_tokens`.
  - The Apple `sub` is kept only as a sha256 hash in `apple_identities`; email is the only PII.
  - Deletion revokes Apple via a fresh authorization code, and no provider token is stored.
  - Every route except the allowlist requires a bearer (the gates of D8).
  - The OTP, magic-link, cookie, native-landing and email-gateway sentences are deleted.
  - The web (GOOGLE SIGN-IN) paragraph stays except its last sentence. "The main db's `/api/auth/google` is gone; every other `/api/auth/*` route is unchanged." becomes "`/api/auth/google` is the NATIVE Google sign-in on the main db (rn-forced-signin, see the native paragraph); the web sign-in is `/api/web/auth/google` only, and the two never share a database."
- **Guards** (each with a planted self-check):
  - `test_every_route_requires_a_bearer`: the pin keys each served route by (path, methods − {HEAD}) and holds three EXACT sets from D8: `PUBLIC_ROUTES`, `IN_HANDLER_AUTH` and the gated set.
    - (a) The served set equals `PUBLIC_ROUTES ∪ IN_HANDLER_AUTH ∪ {routes whose flattened dependant tree contains require_account, require_account_or_web or require_web_account}`. The three are disjoint, and no set holds a stale entry.
    - (b) A planted route in none of the sets goes red: an open POST on the app, one through an included router, and one under `/api/web/`.
    - (c) No served path is `/openapi.json`, `/docs` or `/redoc`.
    - The behavioural half lives in `test_route_auth.py`, unstubbed: every `IN_HANDLER_AUTH` entry answers 401 with no bearer (live-PG; the web entries live-WEB) and 503 with its own database unset (native → `DATABASE_URL`, web → `WEB_DATABASE_URL`).
  - `test_only_apple_module_imports_pyjwt`.
  - The rewritten `test_no_email_gateway` (no `resend`, no `email.py`).
  - B4 is renamed `test_b4_google_verifier_app_importers`. It asserts the importers are EXACTLY [`accounts/service.py`, `accounts/web/service.py`], and a plant in a third file (e.g. `accounts/gate.py`) goes red. Planting in any file outside the pair is as strong as the old one-importer pin.
  - `test_web_accounts.py` A4 → A4′ (criterion R7).
  - The existing S5 planet_chat pin is unchanged.
  - app-native `native-guards.test.ts` gains: the provider SDKs only in `platform/sign-in.ts`, the no-`source={{ uri` rule, and the sign-in path's no-dev-client rule (D20).
  - The text-variant census totals are re-pinned (the AccountSheet/OtpInput sites leave, the gate's one local marker arrives) with a note in `docs/text-variant-census.md`. The removed AccountSheet paint/variant rulings are replaced by rulings for `SignInGate`/`AccountSection`.

## Acceptance Criteria

Suites: `npm run server:test`, `npm test`, `npm run typecheck`. Server tests use FAKE verifiers only (monkeypatched `google._verify_token`, `apple._verify_token`, `apple._post`). "Live-PG" = guarded on `DATABASE_URL` pointing at a throwaway local cluster (a skip is not a pass). **LIVE** = needs the user's real credentials or a device/store build; these are deferred to one hand-back.

**Server: sign-in**
- **S1 (dormant)**: with `DATABASE_URL` unset, `POST /api/auth/google {idToken:"x"}` and `POST /api/auth/apple {identityToken:"x", nonce:"n"*16}` → 503 `accounts unavailable`, and recording fakes are not called. With a db configured (monkeypatched `db.is_configured`) but `GOOGLE_IOS_CLIENT_ID` unset → google 503. With `APPLE_BUNDLE_IDS` unset → apple 503. Empty or 4097-character tokens and a 15-character nonce → 422.
- **S2 (Google policy; rework, re-amended)**: with `GOOGLE_IOS_CLIENT_ID="a.apps.googleusercontent.com, b.apps.googleusercontent.com,,c.apps.googleusercontent.com"`, `ios_client_ids()` returns `[a…, b…, c…]` (trimmed, the empty entry dropped, more than two allowed on the server), and the fake receives exactly that audience list. `email_verified:"true"` (a string), `false`, or a missing email → 401. With `verified_email(cred)` and no list, the fake still receives `GOOGLE_CLIENT_ID` as a string (web path unchanged; existing `test_google_auth.py` green).
- **S3 (Apple policy)**: `verified_identity` with fakes returns the identity for `{sub, email, email_verified:"true", nonce:sha256hex(raw), aud:"com.astrace.app.dev"}` and for `email_verified: true`. It returns `None` for a nonce mismatch, a missing nonce, or `email_verified:"false"` with an email present. A missing email yields `email=None`. The fake raising a JWKS/transport error → `AppleUnavailable` → the route answers 503. The audiences passed equal the parsed `APPLE_BUNDLE_IDS`.
- **S4 (live-PG, Google)**: the fake verifier returns `Rn.Tester@Example.com` → 200 with a 43-character `accessToken`, a `refreshToken`, a parseable `accessExpiresAt` and `appleLinked:false`. `whoami` with the bearer → that email. Refresh → a new pair. A second sign-in as `rn.tester@example.com` → ONE `users` row.
- **S5 (live-PG, Apple link)**: a first Apple sign-in (sub `apple-SENTINEL-1`, email `relay1@privaterelay.appleid.com`) → 200, one `apple_identities` row whose `subject_hash` = sha256("apple:apple-SENTINEL-1"), `appleLinked:true`. A second sign-in with the same sub and NO email → 200 as the same user. A new sub with no email → 401 `apple email missing`, and no row is added. An Apple sign-in with sub `apple-SENTINEL-2` and email `rn.tester@example.com` links to S4's user (one users row, `appleLinked:true` on whoami).
- **S6 (live-PG, nothing but email)**: after S4 and S5, a dump of every text column of every main-db table contains neither the sentinel subs, the raw tokens, the nonce nor the id token. Token columns are 64-hex. `users` has exactly the columns `id, email, created_at`.
- **S7 (no logging)**: a source scan of `apple.py`, `google.py` and the sign-in/delete service and route functions finds no log/print call naming a token, a code, `sub`, `claims` or `nonce`. S4 and S5 driven with caplog at DEBUG capture no sentinel.

**Server: deletion and revocation**
- **D1 (live-PG)**: a Google-only user: `DELETE /api/auth/account` with the bearer, no body → 204. Their sessions, refresh_tokens, profiles and journal rows are gone. `_post` was never called.
- **D2 (live-PG)**: an Apple-linked user, no body → 422 `apple reauthorization required`, and the user remains. A body whose token's sub is another user's → 403, and the user remains. A valid body → `_post` is called first with `https://appleid.apple.com/auth/token` (form `grant_type=authorization_code`, the code, `client_id=com.astrace.app.dev`, a `client_secret`), then with `https://appleid.apple.com/auth/revoke` (`token` = the fake's refresh token, `token_type_hint=refresh_token`) → 204, and the user and their `apple_identities` rows are gone. The same run with a fake token whose `aud` is `com.astrace.app` → the exchange and revoke forms carry `client_id=com.astrace.app`, and the `client_secret`'s `sub` is `com.astrace.app` (re-amended: the signing app's own bundle).
- **D3 (live-PG)**: the revoke fake raising → 502 `apple revoke failed`, and the user still exists. With `APPLE_KEY_ID` unset → 503, and the user still exists.
- **D4 (client secret, db-free)**: with a test-generated P-256 PEM (with `\n` escapes) in `APPLE_PRIVATE_KEY`, `client_secret("com.astrace.app.dev", now)` decodes with the matching public key: ES256, header `kid` = `APPLE_KEY_ID`, `iss` = `APPLE_TEAM_ID`, `sub` = the client id, `aud` = `https://appleid.apple.com`, `exp − iat` ≤ 300.

**Server: route auth and removals**
- **R1 (pin)**: `test_every_route_requires_a_bearer` passes: served = PUBLIC ∪ IN_HANDLER_AUTH ∪ gated with the exact D8 lists, and there are no stale entries. It goes red on each planted violation (an open POST, a route via an included router, an ungated `/api/web/x`). `GET /openapi.json` → 404, and the served set has no `/openapi.json`. The dw-18 S5 pin stays green.
- **R1b (in-handler, unstubbed)**: each of the five native IN_HANDLER_AUTH routes answers 401 with no bearer (live-PG) and 503 with `DATABASE_URL` unset. Each of the seven web ones answers 401 with no bearer (live-WEB) and 503 with `WEB_DATABASE_URL` unset. Valid bodies are sent where a body is required.
- **R2 (401/503, unstubbed)**: for each of the nine native-gated routes with a valid body, no bearer → 401 (live-PG) and 503 with `DATABASE_URL` unset. A spy on `compute_chart`/`generation.ensure_*`/`cards_store.get_image`/`fitness.check_bounded` records zero calls. A web access token → 401 on them (live, both dbs).
- **R3 (chart either bearer)**: `POST /api/chart` → 401 with no bearer; 200 with a native bearer; 200 with a web bearer (live, both dbs); 503 only when both URLs are unset. A body failing the schema with no bearer → 401, not 422.
- **R4 (card pixels)**: `GET /api/analysis/card/{key}` for a stored key with a bearer → 200 `image/png`, `Cache-Control: private, max-age=31536000, immutable`; with none → 401.
- **R5 (removed)**: `/api/auth/request-link`, `/verify`, `/otp/request`, `/otp/verify`, `/native-landing` and `/openapi.json` → 404/405. No response from any `/api/auth/*` route carries `Set-Cookie`. `accounts/email.py` does not exist, and no `app/` file contains `resend`. `.env.example` names `GOOGLE_IOS_CLIENT_ID`, `APPLE_BUNDLE_IDS`, `APPLE_TEAM_ID`, `APPLE_KEY_ID` and `APPLE_PRIVATE_KEY` without values, and no longer names `RESEND_API_KEY`, `EMAIL_FROM` or `APP_BASE_URL`.
- **R6 (migrations, live-PG)**: on an empty db, all migrations apply, and afterwards `login_tokens` and `otp_codes` do not exist while `sessions`, `refresh_tokens` and `apple_identities` do. A second run applies nothing. `test_only_apple_module_imports_pyjwt` and B4 (google importers = `accounts/service.py`, `accounts/web/service.py`) pass and bite on plants.
- **R7 (web unchanged)**: the existing web suite (`test_web_accounts.py`, `test_web_accounts_live.py`, `test_planet_chat_auth.py`, `test_google_auth.py`) and web-divination's vitest pass unchanged, with two exceptions.
  - A4 is rewritten as A4′ (below).
  - `core-planet-chat-auth.test.ts`'s "without opts no Authorization header" becomes "the header is always sent".
  A new web vitest: with the web session signed in, a final 401 signs the web session out, and a native `onSessionEnded` listener registered in the same test never fires.
- **A4′ (replaces `test_a4_main_db_google_route_is_gone`, db-free)**:
  - `POST /api/auth/google {"credential":"x"}` → 422, because the native body is `{idToken}` and the web body is refused.
  - With `DATABASE_URL` unset and `WEB_DATABASE_URL` set to a dummy, `POST /api/auth/google {"idToken":"x"}` → 503. Spies on `accounts.web.service.sign_in_google`, `db.connect_web` and `db.web_is_configured` record zero calls.
  - `hasattr(main_service, "sign_in_google")`, and `inspect.getsource(main_service.sign_in_google)` names neither `web` nor `connect_web`.
  - It lives in `test_web_accounts.py` in A4's place. It is stronger than A4: it proves the native route cannot reach the web database, not merely that a path is absent.

**Core and app (jest/vitest; stubbed fetch, fake secure store)**
- **C1 (fix a, refresh hang)**: with stored tokens and a server that answers 401 to both `whoami` and `/api/auth/token/refresh`, `restoreAccount()` settles within one test tick budget (under 1 s, fake timers not needed). The refresh POST is sent exactly once, with NO `Authorization` header. The status ends `signed-out` and `onSessionEnded` fires once. The same test run against the old `apiFetch`-based refresh times out (documented in the log as the reproduction).
- **C2 (fix b, cold-start race)**: a secure store whose `getItem` resolves after 50 ms holding a valid triple: `bootAccount()` ends `signed-in`, and the `whoami` request carried `Authorization: Bearer <stored access>`. No `whoami` is sent before the load resolves, and no `signed-out` status is ever emitted.
- **C3**: `bootAccount()` with an empty store → `signed-out` with zero requests. whoami 503 → `unavailable`, tokens kept. A rejected fetch → `offline`, tokens kept.
- **C4 (sign-in)**: `signInWithProvider('google', {idToken:'g'})` posts exactly `{"idToken":"g"}` to `/api/auth/google` and, on 200, persists the triple to the secure store and sets `signed-in` with `appleLinked`. 401 → `'invalid'`; 401 `apple email missing` → `'no-email'`; 503 → `'unavailable'`; throw → `'error'`. Apple posts `{identityToken, nonce}` to `/api/auth/apple`.
- **C5 (every request authenticated)**: `postJson` sends `Authorization: Bearer` for `/api/analysis`, `/api/transits/day` and `/api/ask/fitness`, and core `chart/service` sends it on `/api/chart`. A final 401 from any `postJson` call → `reportUnauthorized` → a signed-in native session ends (`onSessionEnded` exactly once, even though web `google-session` is loaded through the same barrel and its session status stays unchanged). With no native session signed in, a report fires no `onSessionEnded`. A signed-in session whose sync pull (`GET /api/profiles`) or push-on-save PUT gets a final 401 also ends, with `onSessionEnded` exactly once (D10's one rule).
- **C6 (birth data follows the account)**: the account has data A and the device has B → after sign-in the device shows A and no conflict state exists (the `conflict` phase is gone from the type). Account empty, device B → a `PUT /api/profiles/traveler` with B. Pull 500 → no PUT, and no later save PUTs. Account A, device empty → A adopted.
- **C7 (session end wipes)**: with MMKV holding birth data, `astrace.cards.shown.v1*`, `astrace.transit.archive.v1*`, the anchor, `astrology.lang.v1` and `astrology.ground.v1`, `logout()` (even with a rejected fetch) → the logout POST carried `{refreshToken}` and the bearer; afterwards only the language and ground keys remain, the three secure keys are gone, `Image.clearDiskCache`, `Image.clearMemoryCache` and `GoogleSignin.signOut` were called, and `requestReload` fired once. An anonymous device (no tokens) booting to the gate is NOT wiped.
- **C8 (deletion)**: `AccountSection` → Delete account… → confirm → for `appleLinked:false`, `DELETE /api/auth/account` with no body. For `appleLinked:true`, the Apple mock is called first and the body carries `{apple:{identityToken, authorizationCode, nonce}}`. Cancelled Apple → no request and the confirm stays. 502 → the failure note, and no wipe. 204 → the wipe of C7.
- **C9 (images)**: each of the five image sites renders `source` with `headers.Authorization = "Bearer <access>"`. `prefetchImages` passes the same headers. `native-guards` finds no `source={{ uri` outside `platform/`.

**Gate UI (jest render)**
- **U1**: status `signed-out` → the screen contains the wordmark, an `AppleAuthenticationButton` and a "Sign in with Google" button, and nothing else: no tab rail, no chart, no Settings, no text input. `checking` → the wordmark only, no buttons. With `appleConfigured()` true and the availability mock false → the Apple button is absent. With a mocked `Constants` carrying `extra.appleSignIn: false` and no `extra.googleIosClientId` (no shipped variant does this any more; it is the opt-out path, rework), both buttons render disabled with their "isn't set up in this build" notes, and pressing them calls no provider mock and sends no request.
- **U2**: pressing Google with the `googleIdToken` mock → `'cancelled'` → no request and no status line. With an idToken and a 401 → "Sign-in didn't go through. Try again."; `no-email` → the Apple copy; `unavailable` → the message plus "Try again" and hidden buttons; "Try again" re-runs `bootAccount`. In flight → "Signing in…" and both buttons disabled. With `googleConfigured()` false → the Google button disabled with its note. With `extra.appleSignIn` false but `isAvailableAsync()` true → `appleConfigured()` and `appleAvailable()` are both false, and the Apple button is DISABLED with its note, not absent.
- **U3**: zh renders the zh copy, and the `auth` namespace keeps en↔zh parity (existing parity test). Under Reduce Motion no `withTiming` is called on the gate. The Apple button style is WHITE on the dark ground and BLACK otherwise.
- **U4**: Settings shows the email, "Sign out" and "Delete account…". There is no email/OTP input anywhere in `app-native/src`, and `AccountSheet`, `OtpInput`, `deepLink` and `useMergeState` do not exist.
- **G1**: architecture, colour, text-variant, paint and type guards pass (the census totals are re-pinned with a census note, and the new tokens are achromatic and live in `theme/tokens.ts`). The provider-SDK and dev-client guards pass and bite on a planted `import … from 'expo-apple-authentication'` in `account/SignInGate.tsx` and a planted `expo-dev-client` import in `platform/sign-in.ts`. The CLAUDE.md amendments are present.

**Build config (no store build needed)**
- **B1 (rework, re-amended: the positional rule)**: from `app-native/`, with `GOOGLE_IOS_CLIENT_ID="222-prod.apps.googleusercontent.com,111-dev.apps.googleusercontent.com"`:
  - `APP_VARIANT=prod npx expo config --type public --json` shows `ios.bundleIdentifier: com.astrace.app`, `ios.usesAppleSignIn: true`, `extra.appleSignIn: true`, the google-signin plugin with `iosUrlScheme: com.googleusercontent.apps.222-prod`, and `extra.googleIosClientId: 222-prod.apps.googleusercontent.com`.
  - `APP_VARIANT=dev …` shows `com.astrace.app.dev`, `usesAppleSignIn: true`, `extra.appleSignIn: true`, `iosUrlScheme: com.googleusercontent.apps.111-dev` and `extra.googleIosClientId: 111-dev.apps.googleusercontent.com`.
  - Jest on `buildConfig` / `googleIosClient` with a stubbed env pins every edge:
    - a single `333-one.apps.googleusercontent.com` → BOTH variants use `333-one` (scheme and extra);
    - `" 222-prod.apps.googleusercontent.com , 111-dev.apps.googleusercontent.com "` (spaces) → the same result as without spaces;
    - `",111-dev…"` → prod has no Google and dev has `111-dev`; `"222-prod…,"` → prod `222-prod`, dev none;
    - a malformed entry in one slot → that variant only has no Google;
    - unset in both the shell and the root `.env` (stubbed reader), or `","` → no Google on either variant, while Apple stays on;
    - three entries → `buildConfig` throws, and the message contains the count `3` and contains none of the three ids.
  - No `VARIANTS` entry has a `signIn` key.
  - No file under `app-native/` (excluding `node_modules/`, `ios/`, `android/`) and no `eas.json` string contains `EXPO_PUBLIC_GOOGLE` or `GOOGLE_IOS_CLIENT_IDS`.
- **B2 (rework)**: `eas.json`'s `testflight` profile resolves to `distribution: store`, `APP_VARIANT: prod`, `EXPO_PUBLIC_API_BASE: https://astrace.onrender.com`, `environment: production` and a channel. `production` names `environment: production`, `development` names `development`, and `preview` names `preview`; `development` and `preview` still build `APP_VARIANT: dev` against their existing bases. No profile's `env` carries a Google client id. A jest test reads `eas.json` and pins this.

**Real app (iOS simulator, `.claude/skills/verify`; local backend on a throwaway cluster, started with an explicit `DATABASE_URL` and an empty `WEB_DATABASE_URL`)**
- **A1**: a dev-client build of this branch: a fresh install (app deleted first) shows the opening, then ONLY the gate (wordmark plus the two buttons). An idb accessibility dump lists no tab rail, chart or settings element.
- **A2**: `curl` against the local backend: `/api/health` → 200. `POST /api/chart`, `/api/transits`, `/api/analysis` and `/api/ask/fitness` with valid bodies and no bearer → 401, and `GET /api/analysis/card/x` → 401. On a second backend with `DATABASE_URL=` empty they answer 503 (chart included, with the web db also empty).

**LIVE (rework 2026-09-30; deferred to the single user hand-back).** Needs: `GOOGLE_IOS_CLIENT_ID=<PROD_ID>,<DEV_ID>` in the root `.env` and the per-environment EAS values (D19); `APPLE_*` in the root `.env` with the NEW key and key id (the current key is being revoked, so nothing runs on it); Sign in with Apple on both App IDs; dev and prod device builds rebuilt; a real Apple ID and Google account. L1–L4 and L6 gate this entry. **Transport for the prod build (L6, decided):** the prod variant's Info.plist is never edited (no `NSAllowsLocalNetworking`, no `NSLocalNetworkUsageDescription`, no ATS exception).
  - First choice: the iOS SIMULATOR with `EXPO_PUBLIC_API_BASE=http://127.0.0.1:8000`, the backend bound to loopback. Step 1 is a reachability probe: tap Sign in with Google once and confirm the uvicorn log shows `POST /api/auth/google`.
  - If ATS refuses the loopback cleartext (no request reaches the log), or Apple sign-in cannot complete on the simulator, use the decided fallback: an HTTPS tunnel to the local uvicorn (`cloudflared tunnel --url http://127.0.0.1:8000`) with `EXPO_PUBLIC_API_BASE=https://<tunnel-host>`, rebuilt, on the simulator or a device.
  - The log records which path ran. L5 is POST-ROLLOUT: it needs the user's prod rollout (a non-goal), so it is recorded for the user and does not gate acceptance.
- **L1 LIVE (dev variant)**: on the DEV app (`com.astrace.app.dev`) against the local backend (LAN), "Sign in with Google" completes, and the app opens with the account's birth data (or the first-run entry). `users` gains one row for that email.
- **L2 LIVE (dev variant)**: on a device, the dev app's "Sign in with Apple" completes (share or hide email). `apple_identities` holds one hashed row, and the dump holds no raw `sub`.
- **L3 LIVE**: kill and relaunch → still signed in, with no gate flash beyond the wordmark. Settings → Sign out → the gate. Relaunch → the gate. Signing in again restores the birth data from the account.
- **L4 LIVE**: Delete account on an Apple-linked account → Apple's reauthorization sheet → 204 → the gate. The account row is gone, and on the device Settings › Apple ID › Sign in with Apple no longer lists the app (the next Apple sign-in shows the first-time share-email sheet).
- **L5 LIVE, POST-ROLLOUT (rework)**: a `testflight` build (the PROD variant `com.astrace.app`), submitted with `eas submit --profile production` (the existing `submit.production` `ascAppId`) and installed through TestFlight, with `https://astrace.onrender.com` running this feature with the D19 env: both Google and Apple sign-in complete, and the app loads a chart from `https://astrace.onrender.com`.
- **L6 LIVE (new, rework, re-amended; prod variant before rollout; gating)**: after `npx expo prebuild --clean`, `APP_VARIANT=prod EXPO_PUBLIC_API_BASE=<the transport above> npx expo run:ios` builds the prod bundle against the local backend, which runs with `GOOGLE_IOS_CLIENT_ID=<PROD_ID>,<DEV_ID>`, both `APPLE_BUNDLE_IDS` and the NEW Apple key.
  - (a) Google sign-in completes with the PROD client id (the token's `aud` is entry 1).
  - (b) Apple sign-in completes (token `aud` = `com.astrace.app`).
  - (c) On that Apple-linked account, Settings → Delete account… → Apple's reauthorization sheet → 204 → the gate. The 204 itself proves the prod revocation: by D6, the server deletes only after Apple accepted the exchange and revoke made with `client_id` = the token's `aud` = `com.astrace.app` (a 502 here means the key or grouping is wrong). The account row is gone, and Settings › Apple ID › Sign in with Apple no longer lists the app.
  - (d) After `npx expo prebuild --clean` back to dev, the dev app still signs in with both providers (L1/L2 re-run once).
