# 08 — accepting

Fresh-context acceptance check of `feature/dw-16-web-account-db` (worktree
`/Users/kaimao/Projects/astrology-wt/dw-16-web-account-db`, HEAD `ac2c294`),
against the criteria D1–D3, A1–A4, S1–S7, B1–B4, C1–C10, W1–W4, G1–G2, R1–R5
(+ plan notes N2–N9). U1 not run (it needs the user's live Google sign-in).

Database safety: every pytest run and server set `DATABASE_URL` and
`WEB_DATABASE_URL` explicitly in the shell. Nothing used `--env-file .env`, and
the root `.env` was never read or printed. Live suites ran on the throwaway
cluster 127.0.0.1:54316, in fresh dbs `acc_web`/`acc_main` (plus `acc_base`,
created for the base-commit comparison and then dropped). The real app ran
against the dev cluster 127.0.0.1:54320 (`astrace_dev` + `astrace_web`).

## Suites run

| Suite | Result |
|---|---|
| `test_web_accounts.py` + `test_web_accounts_live.py` with `TEST_WEB_DATABASE_URL=…54316/acc_web TEST_DATABASE_URL=…54316/acc_main DATABASE_URL= WEB_DATABASE_URL=` | **47 passed, 0 skipped** (`-rs` lists no skips) |
| Full server suite (same env) | **1431 passed, 50 skipped**. The skips are pre-existing: native live-PG suites keyed on `DATABASE_URL`, synastry-disabled, one fixture sky |
| Native auth/db suites (`test_auth_api`, `test_auth_integration`, `test_native_tokens`, `test_otp_auth`, `test_profiles_api`, `test_profiles_integration`, `test_accounts_tokens`, `test_accounts_email`, `test_db`, `test_db_integration`) LIVE with `DATABASE_URL=…54316/acc_main` | 72 passed, 3 failed. The failures are `TestOtpPostgres::{test_wrong_code_increments_attempts, test_fifth_wrong_attempt_locks_even_correct_code, test_expired_code_401}` (psycopg "last operation didn't produce records"). **They fail identically on the base commit `cd44a2c`** (scratch worktree, fresh db `acc_base`: 3 failed, 16 passed), so they are pre-existing and not caused by dw-16. None of these files is touched by the diff |
| `npm test` (root) | jest 90 suites / 1078 tests passed; vitest 45 files / 427 tests passed |
| `npm run typecheck` | app-native and web-divination clean |
| `npx jest architecture color-guard text-variant-guard` | 3 suites / 55 tests passed |

## Verdicts

| # | Verdict | Evidence |
|---|---|---|
| D1 | PASS | `test_d1_unset_web_url_is_unconfigured` (web_is_configured False, web_health "unconfigured", `connect_web()` and `apply_web_migrations()` raise `DBNotConfigured`). `test_d1_health_reports_web_db_unconfigured` (`webDb:"unconfigured"`). `test_d1_every_web_route_is_503…` is parametrized over all 10 routes (5 auth/account + 5 data), each with a VALID body and a bearer, and each answers 503 `{"detail":"web accounts unavailable"}` with the fake verifier's call list empty. `test_d1_web_url_equal_to_main_url_stays_dormant` and (N7) `test_d1_identical_urls_log_one_warning_at_startup` (caplog: exactly one WARNING, the URL not in the log, web migrations not applied) |
| D2 | PASS (live) | `test_d2_web_migrations_create_exactly_the_web_tables`: after DROP, `apply_web_migrations()==["001_web_accounts"]`, the public tables are exactly the 5 `web_*` + `web_schema_migrations`, and a second call gives `[]`. `test_d2_main_runner_is_unchanged`: main `apply_migrations()==[]`, no `web_` table in the main db, no web file in `migration_files()`. `test_d1_migration_folders_are_separate`: an unknown ledger name raises ValueError |
| D3 | PASS (live, two dbs) | `test_d3_web_traffic_leaves_the_main_db_identical`: acc_main table list and every table's `count(*)` are equal before and after sign-in + profile PUT + session PUT + GET |
| A1 | PASS (live) | `test_a1_sign_in_whoami_refresh_logout`: email `Dw16.Tester@Example.com` echoed; uuid accountId; 43-char `[A-Za-z0-9_-]` tokens; parseable expiry; whoami gives the same email and accountId; refresh gives a new pair and the old refresh 401; after logout whoami 401 and refresh 401. N4: `test_n4_logout_with_a_dead_or_missing_bearer_is_204` |
| A2 | PASS (live) | `test_a2_one_user_per_email_and_nothing_raw_at_rest`: case-variant re-sign-in gives 1 `web_users` row and the same accountId. A `row_to_json` dump of all 5 web tables contains no sub sentinel, neither credential, and none of the 4 raw tokens. Token hashes match `[0-9a-f]{64}`. `web_users` columns = id, email, created_at |
| A3 | PASS (live, both dbs) | `test_a3_web_and_native_tokens_never_cross`: a native bearer minted in acc_main gets 200 on `/api/auth/whoami` and 401 on `/api/web/auth/whoami` and `/api/web/sessions`. A web bearer gets 401 on `/api/auth/whoami` and `/api/profiles` |
| A4 | PASS | `test_a4_main_db_google_route_is_gone` (404/405, and `accounts/service` has no `sign_in_google`, confirmed in the diff). The native auth suites are unchanged by the diff (only `test_google_auth.py`/`test_health.py` were edited, to the new route). The 3 live OTP failures are pre-existing on `cd44a2c` (see Suites) |
| S1 | PASS (live) | `test_s1_profile_round_trip`: null → PUT 204 → GET equals the body → PUT null → GET null (row deleted) → `1990-13-40` gives 422 |
| S2 | PASS (live) | `test_s2_session_upsert_seal_and_verbatim_entries`: the 2→4 entry upsert leaves one row. Sealed with a ready summary shows `state:"sealed"`, `endedAtUtc`, the summary and `updatedAtUtc` > the earlier one. `mood`/`chartRefs`/`dice` round-trip `==` |
| S3 | PASS (live) | `test_s3_sixty_records_newest_start_first`: 60 back, ids in started_at DESC order |
| S4 | PASS (live) | `test_s4_isolation`: U and V each see only their own `s-1`. V's DELETE of U's `s-9` gives 404 and the row survives. All 5 data routes give 401 with no bearer and with a bogus bearer |
| S5 | PASS (live) | `test_s5_account_delete_cascades_only_the_caller`: 204, then 0 rows for U in all 5 tables, ≥1 row for V in each, and U's token is now 401 |
| S6 | PASS | `test_s6_bad_session_bodies_are_422` covers id `..%2Fx`, 65 chars, persona pluto, lang fr, sealed without end, 0 entries, 2001 entries, role system, empty text, 20,001 chars, summary `done`, plus N5 (record over 2 M chars) and id mismatch. `test_s6_limits_are_inclusive` shows the boundary values are valid. My own run on the real server with a live W bearer and `curl --path-as-is`: PUT `../x` gives 422, PUT `..%2Fx` 422, PUT 65 chars 422, DELETE `../x` 422 |
| S7 | PASS | Live `test_s7_debug_logs…`: caplog at DEBUG over sign-in, profile and session PUTs/GETs contains no text sentinel, no city `Dw16Sentinelville`, no credential, sub or tokens. Static `test_s7_no_web_module_logs…` finds no log/print call at all in `accounts/web/`, and its planted self-check bites. Real app: `backend.log` has no chat sentinel, city or token |
| B1 | PASS (bites) | Planted in the worktree and then reverted. `db.connect_web()` in `divination/turn.py` turns `test_b1_web_door…` red. `import psycopg` in `accounts/web/data.py` turns `test_only_db_package_imports_psycopg` red. `db.connect()` in `accounts/web/data.py` turns test_b1 red. `db.web_is_configured()` in `accounts/service.py` turns test_b1 red. Baseline: 39/39 green |
| B2 | PASS (bites) | Plants: `INSERT INTO users` in `accounts/web/data.py` turns `test_b2…` red. `CREATE TABLE users_shadow` in the web migration turns test_b2 red. `CREATE TABLE web_leak` in the last main migration turns test_b2 red |
| B3 | PASS (bites) | Plants: `from ...divination import turn` in `accounts/web/data.py` turns `test_b3…` red. `from ... import llm` in `accounts/web/routes.py` turns test_b3 red. `from ..accounts.web import data` in `divination/turn.py` turns test_b3 red (and also `test_divination_borrows_only_the_restate_helper`). `test_divination_keeps_no_state` is untouched by the diff (the boundary diff only appends) and passes |
| B4 | PASS (bites) | Plants: `from . import google` in `accounts/service.py` turns `test_b4…` red. `from google.oauth2 import id_token` in `accounts/web/service.py` turns `test_only_google_module_imports_google_auth` and test_b4 red. After every plant `git checkout`, then `git status`/`git diff` are empty |
| C1 | PASS | `core-google-session.test.ts`: whoami, google, refresh and logout URLs are all `/api/web/auth/*`. The snapshot carries `accountId` (a missing accountId counts as unavailable/error). Sign-in stores the triple and puts the email in the session. Refresh goes by plain `fetch` with no Authorization header (`webTokenStore.refresh`), and "two concurrent 401s trigger ONE refresh POST" |
| C2 | PASS | `core-web-account.test.ts` C2: the PUT of `/api/web/sessions/s-3` is sent before both GETs; afterwards birth data and log equal the pulled data and the dirty set is empty. Also: a pull failure falls back to the owned cache |
| C3 | PASS | C3 test: the status sequence is only `['ready']` (no asking). Y's birth data, venus transcript, log and active key are gone. X's pulled record is shown, the owner is X, and 0 PUTs are sent |
| C4 | PASS | C4 test: `{status:'asking', pending:{count:2}}` with only whoami sent. Import sends 1 PUT profile with the local birth data and PUTs `s-open` and `s-old`, all before the GET sessions. The owner is X. A reload asks nothing and sends no PUT |
| C5 | PASS | C5 test: no `PUT /api/web/profile`, and the account's BIRTH_B is shown |
| C6 | PASS | C6 test: 0 PUTs, local birth data and transcript wiped, the pulled record shown, the owner set |
| C7 | PASS | C7 test: venus transcript = t2 entries. The log is `[s-t2 open, s-t1 sealed]`. s-t1 is PUT sealed with `endedAtUtc` = its updatedAt and `summary:{status:'pending'}`. `POST /api/divination/summary` is called, and s-t2 is not PUT |
| C8 | PASS | C8 tests: a turn is 2 PUTs (N8) with entries 1 and 2. End sends a PUT sealed/pending, then a PUT ready (tone torn). Coalescing: 1 PUT for 2 entries, max in-flight 1 per id. A 500 then a rejected fetch keep the id in the persisted dirty key, and the next 204 clears it. A failed summary is sent as `{status:'failed'}` without `cause`. A birth-data change triggers a PUT profile. N9: an offline DELETE tombstone is sent at the next boot before the GETs |
| C9 | PASS | C9 tests: `signOutGoogle` with the logout fetch rejected removes the traveler birth data, all 6 transcripts, the log, active, dirty and owner keys, and `astrology.lang.v1` stays `zh`. A restore that ends signed-out (401/401) wipes an OWNED cache and keeps an unowned one |
| C10 | PASS | `core-session-log.test.ts` "C10 (dw-16): no cap": 60 sealed records stay 60 after `recordEntry` (61 in total) and 62 after an End, and the oldest `s-1059` is kept |
| W1 | PASS | `AuthGate.test.tsx` "the account data (dw-16)": while the sessions GET is held, "Opening your sky…" shows and there is no stage and no `.chat`; once released, the stage shows. A 500 pull with no owned cache shows "Couldn't load your account", and Try again runs the pull a second time and opens the app. A 503 pull over an owned cache opens the app on the cache |
| W2 | PASS | AuthGate W2: eyebrow, title, count + email text, Import and Discard buttons, no stage while asking; Import sends a PUT profile and a PUT session and sets the owner. zh keys added in step (the `web-divination/src/i18n.test.ts` parity suite passes). Real app R4 shows the card with n = 2. Minor copy note, not a criterion: n = 1 renders "holds 1 conversations" (no singular form) |
| W3 | PASS | `SessionsScreen.test.tsx` W3: Delete opens the confirm; Keep closes it with 2 cards still listed and no DELETE sent; Delete → confirm → Delete leaves 1 card, KV holds `['s-2000']`, and `DELETE /api/web/sessions/s-1000` is sent. Deleting an open Moon record clears that transcript and DELETEs that id |
| W4 | PASS | `AccountChip.test.tsx`: Keep sends nothing. Confirm sends `DELETE /api/web/account` with the bearer, and on 204 birth data, owner and tokens are gone and the gate title shows. A 500 shows the failure line and keeps everything |
| G1 | PASS | architecture, color-guard and text-variant guards: 55/55. The added lines of the diff under web-divination/packages/app-native contain no hex, `rgb(`/`rgba(` or `hsl(` literal. The `BARREL_DEEP_IMPORT_RE` gains `web-account` with self-checks. `npm test` and `npm run typecheck` are green |
| G2 | PASS | The worktree CLAUDE.md has every D17 amendment: the Backend paragraph (web db, a browser cache owned by one account, cleared at sign-out, turn stateless), replacing the dw-12 "device-local" sentence (`grep device-local` finds nothing). Commands names `WEB_DATABASE_URL` (local astrace_web, the Render dashboard, `TEST_WEB_DATABASE_URL` local-only). Rule 6 says no journal event. Rule 11 covers two URLs, two folders and ledgers, `web_` tables and the one consumer. Rule 12 is rewritten (two PII budgets, cascade, never logged, Google on `/api/web/auth/google`). Rule 3 names the google.py app importer. `.env.example` has `# WEB_DATABASE_URL=` with no value |
| R1 | PASS | Backend from the worktree on :8003: `/api/health` gives `{"status":"ok","db":"ok","webDb":"ok","ephemeris":"ok"}`. `ps eww` on the uvicorn pid shows `DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_dev`, `WEB_DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_web`, `CORS_ALLOW_ORIGINS=http://localhost:5176`, `ANALYSIS_LLM=claude-cli`. astrace_web has web_users, web_access_tokens, web_refresh_tokens, web_birth_profiles, web_sessions (+ web_schema_migrations) |
| R2 | PASS | Browser A (:9320, profile dw16acc-profile-0) holds U's pair 0 (`acc16.u@example.com`, d720f919…). The app opens and the owner is set to U. The birth form is saved (1991-03-21 14:45 Shanghai), which sends `PUT /api/web/profile` 204. The Venus message "…acc16-sentinel" gets a reply in 14 s (claude-cli), and `PUT /api/web/sessions/s-1790717742202` 204 goes out twice (user line, then reply). The DB then has `s-1790717742202\|venus\|open\|2 entries\|…acc16-sentinel\|persona` and U's profile row. Browser B (:9321, fresh profile; only `astrology.profile.v1` beforehand) holds U's SECOND pair (0chN…). whoami, profile and sessions GETs follow. B shows the same birth data in KV, the chip `☉1991-03-21·Shanghai`, a 10-planet wheel and the chat with the user line. Its KV venus transcript has roles [user, persona]. /sessions shows 1 card, "Venus · begun 29 Sept 2026 … acc16-sentinel · In progress" |
| R3 | PASS | B's tokens are replaced with V's pair WITHOUT a sign-out (the other-owner path). After reload the owner is V (250a610b…), the page says signed in as acc16.v, birth data is null and the form shows, there are no transcripts, the log is `[]`, "Sessions · 0", no sentinel text, and /sessions has 0 cards. Sign out (UI) sends `POST /api/web/auth/logout`, the gate returns, and localStorage keys = `["astrology.profile.v1"]` only (no birth-data, transcript, session-log, owner, dirty or token key) |
| R4 | PASS | B, signed out and clean, is pre-seeded with legacy data and no owner: birth data 1988-11-02 Beijing, an open Moon record + transcript, and a sealed Saturn record. With W's pair, the gate asks: "This browser remembers / Bring these into your account? / This browser holds 2 conversations and a birth chart from before you signed in to acc16.w@example.com." (app hidden). Import sends PUT profile, PUT `s-1790000000001`, PUT `s-1790000000000`, then GET profile and GET sessions, and sets the owner to W. astrace_web holds both W rows (moon open 2 entries, saturn sealed 2 entries) and W's profile (1988-11-02). A reload does not ask again (only the whoami/profile/sessions GETs) and /sessions shows 2 cards. Note: the Saturn row's summary is `failed`, not `ready`, because my seed used tone `steady`, which is not in `TONES`. Core's existing record parser downgrades it; the fault was in my seed, not in dw-16 |
| R5 | PASS | astrace_dev before and after R1–R4, table list identical (`analysis_cache,card_images,divination_summary,divination_voice,journal,login_tokens,natal_artifacts,otp_codes,profiles,refresh_tokens,schema_migrations,sessions,users`, no `web_` table) and `users=1 sessions=1 refresh_tokens=1` both times (`diff` gives IDENTICAL) |
| U1 | not run (user input) | Needs the user's live Google sign-in in two browsers |

## Real-app recipe (recorded)

- Backend (worktree root): `DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_dev WEB_DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_web CORS_ALLOW_ORIGINS=http://localhost:5176 ANALYSIS_LLM=claude-cli conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --port 8003`
- Vite (web-divination/): `VITE_API_BASE=http://localhost:8003 npx vite --port 5176 --strictPort`
- Browsers: two headless Chrome 154 instances, `--remote-debugging-port=9320/9321`, `--user-data-dir=<scratchpad>/dw16acc-profile-{0,1}`.
- Stand-in for Google: the mint script below, run from `server/` as
  `PYTHONPATH=. DATABASE_URL= WEB_DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_web conda run -n astrology python mint.py <email>`
  for `acc16.u` ×2 (a pair per browser), `acc16.v`, `acc16.w` @example.com.
  The pair was written into `astrace.auth.access`/`.refresh`/`.expiresAt` through CDP `Runtime.evaluate`, and no credential was typed.

```python
"""dw-16 acceptance: mint a WEB bearer pair for an email straight into
astrace_web (stands in for Google). Uses accounts/web/service's own helpers:
the same web_users upsert as sign_in_google, then service._mint."""
import json, sys
from app import db
from app.accounts.web import service

assert db.web_is_configured()
email = sys.argv[1]
with db.connect_web() as conn:
    user_id, stored = conn.execute(
        "INSERT INTO web_users (email) VALUES (%s) "
        "ON CONFLICT (email) DO UPDATE SET email = web_users.email RETURNING id, email",
        (email,),
    ).fetchone()
    access, refresh, exp = service._mint(conn, user_id)
print(json.dumps({"accountId": str(user_id), "email": str(stored),
                  "access": access, "refresh": refresh, "expiresAt": exp.isoformat()}))
```

Teardown: backend :8003, Vite :5176 and both Chromes were stopped (the ports are
free again). The base-commit scratch worktree was removed and `acc_base`
dropped. The worktree's `git status`/`git diff` are empty. The 54316 and
54320 clusters are still running. Rows left in astrace_web: users
acc16.{u,v,w}@example.com with their tokens, profiles and sessions.

## Overall

All checked criteria PASS (D1–D3, A1–A4, S1–S7, B1–B4, C1–C10, W1–W4, G1–G2,
R1–R5). U1 is pending the user's live Google sign-in. Two findings do not
block acceptance:
1. The `TestOtpPostgres` live failures (3) predate this branch. They reproduce
   on `cd44a2c`.
2. With n = 1, the import card copy reads "1 conversations".
