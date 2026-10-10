# 06 · spec-review (round 3)

**Verdict: PASS.** The round-2 defect is resolved, every round-1 and round-2 note has landed, and the revision introduced no defect that would make the feature wrong. Below are four notes the planner must fold in (N1–N4) and several smaller ones. None changes what the feature does. They correct an enumeration or a journal line.

## Earlier findings: resolution checked against the code (dev, 04ae600)

- **Round-2 F1 (the dw-16 reversal was never superseded): resolved, all four parts.**
  1. The Supersedes list has the dw-16 spec-review heading verbatim. It is scoped correctly: the route-removal half and the B4 one-importer pin are revised; the web db, `/api/web/*` and two-accounts-per-email stand.
  2. `test_web_accounts.py` is CHG, and A4 (`:163 test_a4_main_db_google_route_is_gone`) is replaced by A4′. A4′ is genuinely stronger. The web body gets 422. With `DATABASE_URL` unset it answers 503, and spies prove the native route never reaches `web.service.sign_in_google`, `connect_web` or `web_is_configured`.
  3. R7 names A4 as an exception.
  4. The rule-12 web paragraph's last sentence ("The main db's `/api/auth/google` is gone; every other `/api/auth/*` route is unchanged", present in CLAUDE.md today) is rewritten. Rule 3's "ONE app importer … `test_b4_google_verifier_has_one_app_importer`" is rewritten, and the renamed B4 still bites on a third importer.
- **Round-1 F1 (`/openapi.json`): still resolved.** main.py:115 sets only `docs_url`/`redoc_url` to None today. D8 adds `openapi_url=None`, and R1/R5 pin it.
- **Round-1 F2 (the in-handler recogniser): still resolved.** I recounted the routes against the code:
  - `accounts/routes.py` after the change: google, apple, token/refresh, logout, whoami, DELETE account (6) plus profiles GET/PUT/DELETE (3).
  - `web/routes.py`: 10.
  - main.py: health, chart, the nine identity-free routes (main.py:199–420) and four planet_chat routes (15).
  - Total 34 = PUBLIC 8 + GATED 14 + IN_HANDLER 12. The sets are disjoint.
  - `session_user_id` (service.py:248) and `user_for` (web/service.py:102) both check their db BEFORE looking at the bearer. So `require_account_or_web` can get the "503 only when both dbs are unset, even with no bearer" behaviour of R3/A2 purely by catching `AccountsUnavailable`/`WebUnavailable`, and B1 (test_boundaries.py:979) stays green.
- **Round-1 F3 (the prod variant): still resolved.** The `signIn` flag, `extra.appleSignIn`, and `appleConfigured()` vs `appleAvailable()` are consistent across D16, Contracts, U1 and U2.
- **Round-2 notes:**
  - N2: test files listed. `test_ratelimit`, `test_db_integration:51` and `test_profiles_integration:49-54` are verified. `test_db.py` is untouched correctly.
  - N3: the gate contract is stated.
  - N4: absent vs. disabled is settled.
  - N5: D10 gives one rule for a final 401, and C5 covers sync.
  - N6: the offline launch is flagged for the hand-back.
  - N1 (budget) is still over at ~2,330 words. Not blocking.
- **Supersedes headings:** all six are verbatim against DECISIONS.md (lines 3375, 3440, 3865, 3934, 1176, 1197, 1219).

## Checklist

1. **Serves the rulings, right-sized: yes.** The queue notes and extra rulings (a)–(f) are each encoded:
   - (a) dev bundle only, list audiences, prod out of scope: D3, D19, Non-goals;
   - (b) derived reversed scheme: D19, B1;
   - (c) Apple for `com.astrace.app.dev`: D2 client_id;
   - (d) TestFlight store build with no dev-client, localhost or `__DEV__` in the sign-in path: D20, B2, G1, L5;
   - (e) one env name read by the server and `app.config.ts`, runtime via `extra`, no second name: D19, B1;
   - (f) fakes in tests, LIVE deferred to one hand-back: L1–L5.

   Card-pixel auth and the web `/api/chart` bearer follow from "every route requires a bearer". No invented scope.
2. **Checkable: yes.** Every criterion names a curl, a pytest or a jest/vitest assertion, or an `expo config` output. LIVE is separated. R7's exception list is incomplete (N1), but its intent is unambiguous from D10/C5 and the file is already CHG.
3. **Contract: holds.**
   - Rules 3, 11 and 12 and the accounts paragraph are rewritten explicitly.
   - Every removed pin gets an equal-or-stronger replacement: the all-routes pin with plants, R1b/R2 unstubbed, A4′, B4 exact-pair with a plant, the PyJWT single importer, `test_no_email_gateway` as an absence pin, and the provider-SDK and dev-client guards.
   - Rule 9 holds: gates are decorator dependencies whose value reaches no handler.
   - Rule 5 holds: the refresh `fetch` lives in `platform/token-store.ts`.
   - Rule 12 holds: sha256 only, the Apple `sub` hashed, code and tokens in locals.
   - Rule 13 holds: achromatic tokens in `theme/tokens.ts`. Rule 15 holds: the one local marker, with the census re-pinned.
4. **Non-goals stated; every open point decided: yes.**

## Notes for the planner (fold in; not blocking)

- **N1. R7's exception list undercounts `core-planet-chat-auth.test.ts`.**
  - Besides ":154 without opts no Authorization header", the test at `:165` ("a 401 without auth is NOT reported (identity-free routes never sign out)") asserts the opposite of D10/C5. It must be inverted, or it contradicts C5.
  - The `{auth: true}` fifth argument at `:147`, `:180` and `:195` becomes a type error under `npm run typecheck` once `PostJsonOptions` is removed (web-divination's tsconfig includes `src`).
  - Treat the whole "C1 — postJson carries the bearer only when asked" block, plus those argument removals, as the sanctioned exception. Journal it as the plan's clarification of R7.
- **N2. One more earlier decision conflicts but is not listed.** `### 2026-08-14 · gallery-all-cards · spec-review — approved; the wall points at pixels instead of hoarding them` decides that `GET /api/analysis/card/{cardKey}` is "unauthenticated, not dormancy-gated". main.py:306-313 repeats this in its docstring ("UNAUTHENTICATED and not dormancy-gated by design").
  - D8/D12 reverse it (the `require_account` 401/503 and `Cache-Control: private`). It is tier 3, overridden by the queue ruling "every route … requires a bearer", so it does not block.
  - Add it to the journal entry's **Supersedes**, and have the implementer rewrite that docstring and the `docs/ARCHITECTURE.md` passages that say the same (around :5250 and :3171).
- **N3. `app-native/src/App.test.tsx` is missing from the module map.** It mocks `./account/deepLink` (deleted) and asserts opening → shell, which becomes opening → gate. List it as CHG. `native-guards.test.ts:525` has a comment naming `AccountSheet`; update it with the guard edits.
- **N4. CLAUDE.md Commands, line 117: "Everything except analysis works with no keys at all"** becomes false for app-native, which now needs `DATABASE_URL` plus the provider ids. Fold that into the Commands amendment.
- **N5.** A4′'s "`inspect.getsource(main_service.sign_in_google)` names neither `web` nor …" should match identifiers (`accounts.web`, `web_service`, `connect_web`, `web_is_configured`), not the bare substring `web`, which a docstring could trip.
- **N6.** `rn-appearance-dark-light` (validating) renames `ink`→`dark`, and both features re-pin the text-variant census and paint rulings. Whichever lands second rebases the census totals, and D16/U3's "dark ground" should bind to whatever the ground is called after that merge. `astrology.ground.v1` (D15's keep-list) is unchanged by that feature's notes, but re-check it at merge.
- **N7.** CLAUDE.md rule 14 says the card route is "Cache-Control: immutable". It stays true under `private, max-age=31536000, immutable`, but docs-sync should update the quoted header.
- **N8.** The budget is still ~2,330 words against ~1,500 for Goal through Decided defaults. Accepted as is on the last round.

Transition: spec-review → spec-approved
