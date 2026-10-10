# 04 · spec-review (round 2)

**Verdict: FAIL.** One real defect remains. All three round-1 defects are fixed, and all six notes are applied. The one new defect: the spec reverses a dw-16 decision without saying so. Because of that, one criterion (R7) cannot pass as written, and one CLAUDE.md sentence would stay false after landing. The fix is small.

## Round-1 items: resolution checked against the code (dev, 04ae600)

- **F1 resolved.** D8 sets `FastAPI(openapi_url=None)`. R1 asserts `GET /openapi.json` → 404 and that `/openapi.json`, `/docs` and `/redoc` are not served. R5 lists `/openapi.json`. Nothing in `server/app` or `server/tests` reads the schema (grep `openapi`: no hits).
- **F2 resolved.** The pin now uses three exact sets. I counted them against the code:
  - Served after the change: `/api/auth/*` has 6 routes (google, apple, token/refresh, logout, whoami, DELETE account); `/api/profiles*` has 3; `/api/web/*` has 10; main.py has 15 (health, chart, the nine native routes, the four planet_chat routes). That is 34.
  - PUBLIC 8 + GATED 14 (9 + 1 + 4) + IN_HANDLER 12 (5 + 7) = 34. The sets are disjoint and complete.
  - The web in-handler routes all call `_require_web()` before looking at the bearer (`web/service.py` `user_for`, `delete_account`). So R1b's "503 with `WEB_DATABASE_URL` unset" holds even with no bearer. The native in-handler routes do the same through `_require_db()`.
  - `DELETE /api/web/account` stays byte-identical because the source-regex recogniser is gone.
  - The existing S5 pin checks only top-level `require_web_account`, so `/api/chart`'s new `require_account_or_web` keeps it green.
- **F3 resolved.** D19 adds a `signIn` flag, `extra.appleSignIn`, and `appleAvailable()` = flag ∧ `isAvailableAsync()`. D16 adds the Apple "isn't set up" copy. B1 covers the prod config, and U1/U2 cover the flags-off cases. The Non-goals no longer contradict D19.
- **N1–N5 applied:**
  - N1: google-signin is pinned `^16`.
  - N2: `expo-constants` is a direct dependency.
  - N3: D15 says each listener acts only on its own session. C5 and R7 pin both directions, and google-session is CHG with its comment fixed.
  - N4: D9 is reworded.
  - N5: the B1 scan exclusions are added.
- **N6 is only partly applied** (see note 1 below).

## Defect (must be fixed)

**F1. The spec reverses dw-16's "main-db `/api/auth/google` is removed" but never says so. As a result R7 cannot pass, and CLAUDE.md rule 12 would contradict the code.**

- **What dw-16 decided.** DECISIONS `### 2026-09-29 · dw-16-web-account-db · spec-review — spec auto-approved (round 1); …` (tier 3) says "`/api/auth/google` and `service.sign_in_google` are removed." Three things encode it today:
  - `server/tests/test_web_accounts.py::test_a4_main_db_google_route_is_gone`. It asserts that `POST /api/auth/google` returns 404/405 and that `not hasattr(main_service, "sign_in_google")`.
  - CLAUDE.md rule 12's web paragraph: "The main db's `/api/auth/google` is gone; every other `/api/auth/*` route is unchanged."
  - CLAUDE.md rule 3 / B4: "that module's ONE app importer is `accounts/web/service.py`".
- **Where the spec conflicts.** It brings back both `POST /api/auth/google` and `service.sign_in_google` (D8, the module map, Contracts). But:
  - R7 requires "the whole existing web suite (`test_web_accounts*.py`, …) … pass unchanged". A4 will fail against the new code, so R7 cannot be met as written.
  - The rule-12 amendment says "The web paragraph is unchanged". That leaves the "`/api/auth/google` is gone … every other `/api/auth/*` route is unchanged" sentence in place, and it would be false after landing.
  - The Supersedes list names dw-12, dw-18 and signin-birthdata-merge, but not dw-16. PIPELINE "Decision precedence" requires every conflicting earlier decision to be listed in the spec and journaled under **Supersedes**.
  - The B4/rule-3 widening itself is handled ("google-auth's app importers are named", "B4 updated to the two importers").
- **Fix:**
  1. Add the dw-16 spec-review entry to "Earlier decisions this supersedes", verbatim heading, scoped to its route-removal half and the B4 "one app importer" pin. The separate web db, the web routes and the two-accounts rule stand.
  2. Add `test_web_accounts.py` to the module map as CHG, and replace A4 with an equal-or-stronger pin rather than deleting it. For example:
     - `POST /api/auth/google {credential:"x"}` → 422 (the native body is `{idToken}`);
     - the native route never calls `web_service.sign_in_google` or opens the web door (a spy);
     - `main_service.sign_in_google` exists and `accounts/service.py` names no web-door symbol (already covered by B1).
  3. Word R7 as "pass unchanged except A4, which is rewritten as above".
  4. In the rule-12 amendment, replace the web paragraph's last sentence with one that points at the native paragraph ("`/api/auth/google` is the NATIVE Google sign-in on the main db (rn-forced-signin); the web sign-in is `/api/web/auth/google` only").

## Non-blocking notes (fold in while revising)

1. **Word budget (N6).** Goal through Decided defaults is still about 2,250 words against the ~1,500 budget. This is not a correctness defect.
2. **Test files missing from the module map.** Besides A4, these existing suites also encode removed flows and will need edits:
   - `tests/test_ratelimit.py` drives `/api/auth/request-link`;
   - `tests/test_db_integration.py:51` asserts `login_tokens` exists after migrations, which R6 inverts;
   - `tests/test_db.py:67` names `CREATE TABLE login_tokens`. Check whether it is only a parser fixture.

   List them as CHG so the plan does not discover them late.
3. **The B1 web-door pin constrains `gate.py`.** `test_b1_web_door_named_only_by_db_accounts_web_and_main` forbids `web_is_configured`/`connect_web` outside `db/`, `accounts/web/` and `main.py`. `require_account_or_web` must therefore decide "503 only when neither is configured" by catching `AccountsUnavailable` and `WebUnavailable` from the two services, not by calling `db.web_is_configured()`. Say so in the gate contract.
4. **Apple "absent" vs. "disabled" is under-specified.** U1 wants the Apple button absent when `isAvailableAsync()` is false, but disabled with a note when the build flag is off. `platform/sign-in.ts` exports only `appleAvailable()` (flag ∧ available), which merges the two. Either export `appleConfigured()` (the flag alone) as well, or drop the "absent" case.
5. **401 from `/api/profiles` in sync.** D15 ends the session on "a final 401 while signed in", but D10 only says `postJson` reports. State whether a final 401 from the `apiFetch` calls in `account/sync.ts` also ends the session. The restore path is covered by D13.
6. **Offline launch.** By D13/D16, a signed-in user who launches offline sees "Can't reach Astrace" with no app behind it. This is a decided default, fine as is, but worth one line in the hand-back so the user knows it is deliberate.

## Checklist

1. **Serves the rulings, right-sized: yes.** The queue notes and extra rulings (a)–(f) are all covered:
   - dev bundle only, with list audiences: D3, D19;
   - one env name with a derived scheme, read through `extra`: D19, B1;
   - TestFlight-capable, no dev-client or localhost dependency: D20, B2, G1;
   - fakes in tests, with LIVE deferred to L1–L5.

   Card-pixel auth and the web `/api/chart` bearer follow from "every route requires a bearer". No invented scope.
2. **Checkable: yes, except R7**, which cannot pass as written (F1). LIVE criteria are clearly separated.
3. **Contract:**
   - Rules 3, 11 and 12 and the accounts paragraph are rewritten explicitly.
   - The all-routes pin, the PyJWT single importer, the provider-SDK and dev-client guards and R1b are stronger than what they replace.
   - Rule 12 holds: only hashes are kept at rest, the Apple `sub` is kept only as a hash, and codes and tokens stay in local variables.
   - The gap: the A4 guard and one rule-12 sentence are left to break silently instead of being superseded and replaced (F1).
4. **Non-goals stated; every open point decided: yes.**

Transition: spec-review → spec-review (revise)
