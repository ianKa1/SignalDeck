# rn-forced-signin — 03 designing (revision round 1)

Date: 2026-09-30. Input: the verdict in `02-spec-review.md` (FAIL: F1–F3, notes N1–N6). No code touched, and no `.env` values read. The spec `pipeline/specs/rn-forced-signin.md` was revised in place. Non-goals and Decided defaults were rewritten compactly; the Architecture and Acceptance Criteria were patched.

## Defects fixed
- **F1 (`/openapi.json` ungated).**
  - D8 decides `FastAPI(openapi_url=None)`. Docs and redoc were already off, and nothing reads the schema.
  - The module map's main.py line records it.
  - R1 now asserts `GET /openapi.json` → 404 and that the served set holds no `/openapi.json`, `/docs` or `/redoc`. R5 lists `/openapi.json` among the 404/405 paths.
- **F2 (source-regex recogniser).**
  - D8 now defines three exact, disjoint sets: PUBLIC (8), GATED (the 9 `require_account` routes, `/api/chart` via `require_account_or_web`, and the 4 planet_chat routes via `require_web_account`) and `IN_HANDLER_AUTH`. `IN_HANDLER_AUTH` holds 5 native routes (whoami, `DELETE /api/auth/account`, the three `/api/profiles*` routes) and 7 web routes (web whoami, `DELETE /api/web/account`, profile GET/PUT, sessions GET/PUT/DELETE).
  - The pin is keyed by (path, methods − HEAD). It requires served = PUBLIC ∪ IN_HANDLER_AUTH ∪ gated, with no stale entries. A planted route outside all three sets turns it red: an open POST, one via an included router, one under `/api/web/`.
  - The new R1b is the unstubbed behavioural half: each in-handler route answers 401 without a bearer (live-PG / live-WEB) and 503 with its own db unset.
  - The source-text check is gone, so `DELETE /api/web/account` stays byte-identical.
- **F3 (prod-variant contradiction).**
  - D19 adds one dev-only flag, `VARIANTS[v].signIn`. It gates the whole `GOOGLE_IOS_CLIENT_ID` read (and hence the plugin `iosUrlScheme` and `extra.googleIosClientId`), `ios.usesAppleSignIn`, and a new `extra.appleSignIn`.
  - `appleAvailable()` requires `extra.appleSignIn && isAvailableAsync()`.
  - D16 adds "Apple sign-in isn't set up in this build."
  - B1 gains the prod config check (`APP_VARIANT=prod GOOGLE_IOS_CLIENT_ID=…` → no scheme, no extra id, no `usesAppleSignIn`, `appleSignIn` false).
  - U1 gains both flags off (both buttons disabled with notes, no provider call, no request), and U2 gains Apple-flag-off while `isAvailableAsync` is true.

## Notes applied
- **N1:** google-signin is pinned `^16` (it is not in SDK 57's bundled modules).
- **N2:** `expo-constants` (~57.0.7) is a direct dependency (D1 and the module map).
- **N3:**
  - D15: each `onUnauthorized` listener acts only on its own signed-in session, and the stale google-session comment is corrected. The module map lists `account/google-session.ts` as CHG.
  - C5: a native 401 fires `onSessionEnded` exactly once and leaves the web session status unchanged; with no native session, no fire.
  - R7: a web vitest shows that a web 401 signs the web session out and never fires native `onSessionEnded`.
- **N4:** D9 is reworded. Without `DATABASE_URL` the native routes answer 503 while `/api/health` answers 200, and `/api/web/*` and planet_chat depend on `WEB_DATABASE_URL` alone.
- **N5:** B1's file scan excludes `node_modules/`, `ios/` and `android/`.
- **N6:** Goal through Decided defaults were trimmed to about 2,250 words, with no decision dropped. Merged non-goals and compressed defaults account for the cut. The total spec is about 6,350 words.

## Unchanged
Every other decision, the env names (`GOOGLE_IOS_CLIENT_ID`, `APPLE_BUNDLE_IDS`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`), the superseded headings, and the LIVE list (L1–L5).

## Transition
spec-review (revise) → spec-review (round 2)
