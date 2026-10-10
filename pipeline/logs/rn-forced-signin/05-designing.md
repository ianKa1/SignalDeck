# rn-forced-signin — 05 designing (revision round 2, the last allowed)

Date: 2026-09-30. Input: `04-spec-review.md` (FAIL on one defect, F1, plus six non-blocking notes). No code touched, and no `.env` values read. The spec `pipeline/specs/rn-forced-signin.md` was revised in place.

## F1 — the silent reversal of dw-16's "main-db `/api/auth/google` is removed"
I applied all four parts of the reviewer's fix:
1. **Supersedes.** Added the verbatim heading `### 2026-09-29 · dw-16-web-account-db · spec-review — spec auto-approved (round 1); a separate web db behind a second `app/db` door, accounts/web package, the browser copy as an owned cache`. It is scoped to the route-removal half (pinned by `test_a4_main_db_google_route_is_gone`) and the B4 "one app importer" pin. The web db, the `/api/web/*` routes and the two-accounts rule stand.
2. **A4 replaced by a stronger pin.** `test_web_accounts.py` is listed as CHG in the module map, and the new criterion A4′ replaces A4:
   - the web-shaped body `{credential}` → 422;
   - with no `DATABASE_URL` and a dummy `WEB_DATABASE_URL`, `{idToken}` → 503, and spies on `web.service.sign_in_google`, `db.connect_web` and `db.web_is_configured` record zero calls;
   - `main_service.sign_in_google` exists, and its source names no web-door symbol.
   B4 is renamed `test_b4_google_verifier_app_importers`: the importers are exactly the two service modules, and a plant in a third file goes red.
3. **R7 reworded.** The web suites pass unchanged except A4 (rewritten as A4′) and `core-planet-chat-auth.test.ts`'s "no header without opts" case.
4. **CLAUDE.md.**
   - Rule 12: the web paragraph's last sentence becomes "`/api/auth/google` is the NATIVE Google sign-in on the main db (rn-forced-signin, see the native paragraph); the web sign-in is `/api/web/auth/google` only, and the two never share a database."
   - Rule 3: its "ONE app importer" sentence is rewritten to name both importers and the renamed test. I checked the current text at CLAUDE.md:270-275 and :509-522.

## Notes folded in
1. **Budget.** D1, D7, D8, D12 and D21 were compressed, and the helper list in D19 moved to Contracts (one home). No decision was lost. Goal through the Supersedes list is about 2,330 words; the dw-16 entry and the new rules in D10 and D13 added words.
2. **Test suites.** I grepped `server/tests`, `app-native/src`, `packages/core/src` and `web-divination/src` for request-link, magic, otp, login_tokens, native-landing, the email gateway, cookie, sign_in_google, requestLink, verifyToken/Code, the merge conflict and tokenStore. False hits (`otp` inside other words) were checked and dropped. Listed in the module map:
   - server: `test_web_accounts.py`, `test_ratelimit.py` (the request-link gate test at :50), `test_db_integration.py` (:51) and `test_profiles_integration.py` (:49-54, which minted users via request-link) as CHG. `test_native_tokens.py` (the `astrace://login` cases at :65 and :162) and `test_accounts_tokens.py` (login/link helpers) are named in the existing CHG line.
   - server, unchanged on purpose: `test_db.py:67` (it asserts the immutable 001 migration text), `test_profiles_api.py`, and `test_web_accounts_live.py` (A3 still holds).
   - core: `service.test.ts` and `sync.test.ts` CHG.
   - app-native: the account-sheet, account-merge, otp-input and deepLink tests are DEL; `tokenStore.test.ts` becomes `platform/token-store.test.ts`; `platform/boot.test.ts` (imports `../account/tokenStore`), `settings/settings.test.tsx` (uses `verifyToken`), the `platform/secure-store.ts` comment, and `surface-paint-rulings`/`text-variant-rulings` are CHG.
   - web: `core-planet-chat-auth.test.ts` CHG.
3. **Gate contract.** `require_account_or_web` decides dormancy only by catching `AccountsUnavailable` and `WebUnavailable` from the two services. It never calls `db.is_configured`, `web_is_configured` or `connect_web`, so the B1 web-door pin (`test_boundaries.py:979`) stays green unchanged.
4. **Apple.** `platform/sign-in.ts` exports `appleConfigured()` (the build flag alone) separately from `appleAvailable()` (flag and device). The flag off means the button is DISABLED with a note; flag on but the device unavailable means ABSENT. D16, the Contracts, U1 and U2 are made consistent.
5. **One rule for a final 401 (D10).** Any final 401 on a bearer request made while signed in ends the session. `postJson` reports it; `account/sync.ts` reports its own `/api/profiles` 401s; restore's `whoami` is D13; logout and delete are already session ends. C5 is extended with the sync-pull/PUT case.
6. **Offline launch.** It stays a decided default. D13 now says it is deliberate and that the hand-back flags it for the user.

## Re-verification of cites (dev, 04ae600)
- **Correct as written:** service.py :16/:45/:58/:213/:248/:263/:277/:298; google.py :42/:82/:92; routes.py `_parse_bearer` :71; web/routes.py :115/:126; api.ts :47; poll.ts :41; web auth.ts :61; sync.ts :136/:149/:159-162; image-prefetch.ts :20; the five `source={{ uri` sites (294, 817, 59, 106, 112); chart/service.ts :60; test_boundaries :1094/:1109.
- **Corrected:** mmkv-kv `instance()` :23 → :24; app.config.ts `VARIANTS` :50 → :45; `resolveVariant` :92 → :94; conftest stub :108-138 → :105-138.
- **Added:** web/service.py `WebUnavailable` :18, `_require_web` :24, `user_for` :102; test_boundaries B1 :979 and B4 :1075.
- **Counts checked:** 34 served routes after the change = PUBLIC 8 + GATED 14 (9 + 1 + 4) + IN_HANDLER 12 (5 + 7); nine native-gated routes; five image sites.

## Transition
spec-review (revise) → spec-review (round 3)
