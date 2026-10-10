# 09 — accepting

Fresh-context acceptance check of `feature/dw-18-divination-auth` (worktree
`/Users/kaimao/Projects/astrology-wt/dw-18-divination-auth`, HEAD 9b70741),
2026-09-29. Every pytest run set `DATABASE_URL=` and `WEB_DATABASE_URL=`
explicitly, and the live tests pointed `TEST_WEB_DATABASE_URL` /
`TEST_DATABASE_URL` at fresh throwaway databases `acc18_web` / `acc18_main` on
127.0.0.1:54316. Those databases were dropped afterwards. No Neon URL was used
and `.env` was never read. The backends' environments were checked with
`ps eww`.

## Verdict

| # | Verdict | Evidence |
|---|---|---|
| S1 | PASS | `test_s1_dormant_web_door_is_503_before_any_work` covers 4 routes × {no header, `Bearer some-token`} with a valid body: 503 `{"detail":"web accounts unavailable"}` each time. The `Spies` counting wrappers cover `main._person`, `turn_events`, both `ensure_divination_*`, `cached_summary`, `cached_voice`, `cached_for` and `llm.stream_turn`, plus `generate_sections`. They total 0. |
| S2 | PASS | Live, with no skips: none, `Bearer ` empty, `Basic x` and an unknown 43-char token (`test_s2_bad_bearer…`, 16 cases); an expired token made by backdating `expires_at` (4 cases); a main-db native `_mint_bearer` access token (4 cases, with `TEST_DATABASE_URL`). All give 401 `not signed in` with zero spy calls. `{}` without a bearer gives 401, not 422 (4 cases). Malformed JSON gives 422 `json_invalid` with zero spy calls (4 cases). |
| S3 | PASS | `test_s3_cached_hit_is_still_401…`, for summary and persona: the first bearer request stores the row (JOBS_SYNC, 200). The next request without a bearer gets 401 with all spies at 0, `cached_summary`/`cached_voice`/`cached_for` included. A request with the bearer then gets the byte-identical hit with `generate_sections`=0. |
| S4 | PASS | `test_s4_valid_bearer_passes_byte_identical_to_ungated`, live with a minted web pair: sheets returns 200 with 6 sheets, persona and summary return 200/202, and turn returns 200 `text/event-stream` with `event: delta` before `event: done` (fake `stream_turn`). Status, content-type and body all equal the same four requests with `require_web_account` overridden. |
| S5 | PASS | `test_s5_every_divination_route_requires_a_web_account` walks a flattened `app.routes` (included routers too). It asserts exactly the four paths and that each carries the gate, and that `/api/chart`, `/api/ask/fitness`, `/api/auth/whoami`, `/api/web/auth/whoami` and `/api/health` do not. Planted checks: (a) appending an unguarded `@app.post("/api/divination/planted")` to main.py turned it red (path list ≠ the four); (b) removing the dependency from `/api/divination/sheets` turned it red (`['/api/divination/sheets'] == []`). Both were reverted with `git checkout` and the worktree `git status` was clean. `test_boundaries.py` then passed again (40). |
| S6 | PASS | `test_s6_handlers_take_only_the_body_and_response` checks that each endpoint's params are a subset of {request, response}. `test_s6_the_gate_returns_nothing` checks the gate's `-> None`. The existing `test_b3_accounts_web_imports_no_tier_and_divination_no_accounts` is green. |
| C1 | PASS | `core-divination-auth.test.ts` C1: `postJson(…, {auth:true})` sends `Bearer old-access`. Without opts, with and without a timeout, it sends `Authorization` null. A 401 without auth is not reported. |
| C2 | PASS | C2: the calls are exactly `[SHEETS old-access, REFRESH, SHEETS new-access]` and the KV holds the rotated triple. When the refresh returns 401, reports=1, the KV triple is null, the provider is null and `getGoogleSession().status === 'signed-out'`. |
| C3 | PASS | C3: StreamPost headers carry `Bearer old-access` and a 200 parses to delta/done as before. A 401 releases the body, refreshes and retries with `new-access`. A final 401 gives `[{type:'error',code:'unauthorized'}]`, a single send, reports=1, tokens cleared and signed-out. |
| C4 | PASS | C4: `fetchSheets`, `fetchPersona` and `fetchSummary` each send `Bearer old-access`, with the exact call list asserted. |
| C5 | PASS | `App.test.tsx` "C5 (dw-18)" seeds the traveler birth, six transcripts, sessions, active, dirty, owner and tokens, then gets a 401 on the stream. The sign-in gate title appears, with no `.running-head` and no `.chat__error`. Every listed key and all three `astrace.auth.*` keys end up absent. The `ChatPanel` dw-18 test shows no error and no Retry for `unauthorized`. |
| G1 | PASS | Root `npm test`: jest 90/90 suites (1078 tests); vitest 46 files (439 tests). `npm run typecheck` exits 0. The architecture, colour and text-variant guards pass 3/3 suites (55 tests). CLAUDE.md is amended as D7 specifies (the backend paragraph "require a web bearer…; identity-free native routes stay unauthenticated", rule 10's divination paragraph and rule 12's web paragraph). `pipeline/epics/divination-web.md` has the dw-18 status block and the "dw-18 ✔" dependency-rule line. Full backend suite, live: 1478 passed, 50 skipped. All skips are pre-existing: native `DATABASE_URL` integrations and disabled synastry. No divination, web or boundary test was skipped. |
| R1 | PASS | Worktree backend on :8003 (dev cluster 54320 `astrace_dev`/`astrace_web`, CORS 5176, claude-cli). `curl` of all four routes with a valid body and no header gave `{"detail":"not signed in"}` 401. A second backend on :8005 with `WEB_DATABASE_URL=` (and `DATABASE_URL=`) gave `{"detail":"web accounts unavailable"}` 503 on all four. The log lines for these eight requests are only the uvicorn access lines. `pgrep -P` found no child process under either backend. Caveat: the app's divination logger is not printed by uvicorn at this log level, so "no log line" is weak evidence on its own; the absence of a child process and S1/S2's spies are the load-bearing evidence. |
| R2 | PASS | Minted `dw18acc-check@example.com` with the web service `_mint` and PUT a profile. Tokens went into localStorage in headless Chrome (CDP 9323) against Vite :5176 → :8003. The picker showed all six characters with placements, from sheets 200. Venus's greeting loaded (persona 200). One reply streamed (turn 200) and was saved: `web_sessions` row `venus`, 2 entries, and PUT `/api/web/sessions/…` 204. End session produced a ready summary card with a tone (summary 202 → 200), and the row was sealed with a summary. Network log: every `/api/divination/{sheets,persona,turn,summary}` request carried `Authorization: Bearer` (43 chars). `/api/chart` carried none, as it should. |
| R3 | PASS | With the chat open, `DELETE FROM web_access_tokens/web_refresh_tokens WHERE user_id=<test user>` deleted 1 row from each. Sending "Are you still there?" gave turn 401 (with bearer), then `token/refresh` 401, and no retry. "Sign in to meet your planets" was shown with no `.chat__error`. localStorage went from the tokens + birth + active + sessions + owner keys to only `astrology.profile.v1`. |

## Fixture scope (asked explicitly)

The conftest `_web_account_gate_stubbed` fixture applies only to
`DIVINATION_ROUTE_TEST_MODULES` (dice, persona, roster, sky, summary, turn).
`test_divination_auth` is not in the list. `_no_override` (autouse)
asserts before and after every test that `require_web_account` is not in
`app.dependency_overrides`, and `test_this_module_is_not_in_the_stubbed_list`
checks conftest's source. All 46 tests in the module passed live with no skips.

## Cleanup

The :8003 and :8005 backends, Vite :5176 and Chrome 9323 were stopped. The
test web user was deleted, and its sessions, profile and tokens cascaded
(counts 0). I also deleted the one `divination_summary` row my R2 run created
in `astrace_dev`. No other rows were touched. The throwaway `acc18_*`
databases were dropped, and both clusters were left running. The worktree is
clean.
