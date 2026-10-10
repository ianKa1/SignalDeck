# 06 — implementing (2026-09-29, worker, worktree ../astrology-wt/dw-18-divination-auth)

Skills: /git-commit per step (autonomous overrides). Frontend-facing? Only the gate reappearing on a 401 — no new UI (no /frontend-design pass needed for zero new visuals).

## Step 0 — baseline (4a74364, worktree)
- Throwaway dbs created on 127.0.0.1:54316: `dw18_web`, `dw18_main` (DROP IF EXISTS + CREATE).
- `DATABASE_URL= WEB_DATABASE_URL= npm run server:test` → `1 failed, 1417 passed, 63 skipped` — the one failure `test_llm_providers.py::test_keyless_import_and_call` ran concurrently with jest; re-run alone → `1 passed`. Load flake, pre-existing; it passed in every later full run.
- `npm test` → jest `Tests: 1078 passed, 1078 total`; vitest `Test Files 45 passed (45)`, `Tests 427 passed (427)`. `npm run typecheck` → clean.

## Step 1 — server gate
- `accounts/web/routes.py`: `require_web_account(authorization=Header(None)) -> None`, wrapping `_caller` (503 `web accounts unavailable` / 401 `not signed in`).
- `main.py`: the four `/api/divination/*` decorators gain `dependencies=[Depends(require_web_account)]`; module docstring names the gate. Handler bodies unchanged.
- `tests/conftest.py`: autouse `_web_account_gate_stubbed`, keyed on the exact module list `DIVINATION_ROUTE_TEST_MODULES` (dice, persona, roster, sky, summary, turn).
  - FOUND: the first full run failed 126 tests (503s) — `test_cors.py` `importlib.reload(app.main)` makes `app.main.app` a NEW object while those modules still hold the old `from app.main import app`. Fix: the fixture stubs BOTH `request.module.app` and `app.main.app`.
- `tests/prompt_lab/divination_chat_lab.py`: `main.app.dependency_overrides[require_web_account] = lambda: None` before its TestClient (not collected; `ast.parse` OK).

## Step 2 — server tests
- NEW `tests/test_divination_auth.py` (no override; `_no_override` autouse asserts it before/after each test): S1 dormant 503 ×4 routes ×{no header, bearer}; S2 none/`Bearer `/`Basic x`/unknown ×4, expired ×4, native main-db token ×4, `{}` → 401 ×4, malformed → 422 `json_invalid` ×4 — all with zero calls on the spies `_person`, `turn_events`, `ensure_divination_summary`, `ensure_divination_voice`, `cached_summary`, `cached_voice`, `cached_for`, `llm.stream_turn`, `llm.generate_sections`; S3 stored summary/voice → 401 with zero store reads, then the bearer gets the same bytes with no model call; S4 minted web pair → sheets 200 (6), persona/summary 200, turn 200 `text/event-stream` delta<done, all byte-identical to the overridden run (deterministic fake stream/side read); S6 handler signatures ⊆ {request, response}, gate returns None; self-check that conftest's list excludes this module (source text — `import conftest` resolved to another conftest in the full run).
- `tests/test_boundaries.py` S5: flattened route walk. FOUND: FastAPI 0.139 keeps an included router as ONE `_IncludedRouter` entry in `app.routes` (`/api/auth/whoami` was absent from the flat list), so the walk descends `effective_candidates()` (full path + combined include/route dependencies). Pins exactly four divination paths, all gated; `/api/chart`, `/api/ask/fitness`, `/api/auth/whoami`, `/api/web/auth/whoami`, `/api/health` ungated. Self-checks: a planted app-level route AND a router-mounted `/api/divination/mounted` go red; the same router included with the gate at include level is green.
- Mutation check: removing the gate from `/summary` → `11 failed, 75 passed` on auth+boundaries; restored.
- Full: `DATABASE_URL= WEB_DATABASE_URL= TEST_WEB_DATABASE_URL=…54316/dw18_web TEST_DATABASE_URL=…54316/dw18_main pytest -q` → `1478 passed, 50 skipped` (every skip a pre-existing `DATABASE_URL not set`/live-key guard); `tests/test_divination_auth.py tests/test_web_accounts_live.py -rs` → `59 passed`, 0 skipped.

## Step 3 — core transport
- `platform/auth.ts`: `onUnauthorized(cb) → unsubscribe`, `reportUnauthorized()` (barrel-exported). `platform/poll.ts`: `postJson(path, body, outer, timeoutMs?, opts?: PostJsonOptions)`; `{auth:true}` sends via `apiFetch` (same inner signal = same timeout/abort composition) and reports on a final 401; no-opts path is the old bare `fetch` byte-for-byte. `platform/api.ts` header comment updated (and states `credentials:'same-origin'` must stay). `PostJsonOptions` type-exported.
- `divination/turn.ts`: bearer header from the provider; a 401 drains the refused body (so the web adapter's cleanup runs — an unstarted iterator would never run it), refreshes once, retries; a final 401 drains, reports, yields `error {unauthorized}`. `types.ts` gains `'unauthorized'`. `summary.ts`/`persona.ts`/`roster.ts` pass `undefined, { auth: true }`.
- `account/google-session.ts`: module-load `onUnauthorized` → provider `clear()` + `signed-out` (inert on native: nothing reports).
- i18n en/zh gain `chat.errors.unauthorized` — the parity test binds `Record<TurnErrorCode, string>`, so every code needs a string; it is never rendered (see step 4).
- NEW `web-divination/src/auth/core-divination-auth.test.ts` (10 tests): C1 (bearer with auth, none without — 4- and 5-arg native shapes; a no-auth 401 never reports), C2 (401→refresh→retry with `Bearer new-access`; refused refresh → 1 report, KV triple null, session `signed-out`; double `clear()` harmless), C3 (bearer + 200 parse; 401→drain→refresh→retry; final 401 → `[{type:'error',code:'unauthorized'}]`, 1 send, 1 report, signed out), C4 (sheets/persona/summary carry `Bearer old-access`). → `10 passed`.
- Guards: `npx jest src/architecture.test.ts src/color-guard.test.ts` → `50 passed`. Typecheck clean.

## Step 4 — app behaviour
- `chat/useChat.ts`: `canRetry` is false when the failure is `unauthorized` → no chat error, no Retry. (First try — an early `return` before `setFailure` — was NOT enough: the new ChatPanel test showed the failure block still rendered `interrupted`, because `canRetry` is true whenever the last entry is the user's.)
- `ChatPanel.test.tsx` + "dw-18: a refused bearer (401) shows no chat error and no Retry".
- `App.test.tsx` + "C5 (dw-18)": signed-in app on /chat/venus with six seeded transcripts, sessions, dirty, owner, active, birth; the StreamPost answers 401 and the stubbed refresh 503 → the sign-in gate returns, one send carried `Bearer acc-1`, and all of KEY, the six transcripts, sessions, active, dirty, owner and the three `astrace.auth.*` keys are absent. Mutation: commenting out google-session's `void signOutRefused()` → C5 `1 failed`; restored.
- `npm run typecheck` clean; `npm test` → jest `1078 passed`; vitest `46 files, 439 passed`.

## Step 5 — docs
- CLAUDE.md (worktree): backend paragraph ("The gate is a UI gate: identity-free routes stay unauthenticated" → divination routes require a web bearer, identity-free native routes stay unauthenticated); rule 10 divination paragraph (four routes gated in main.py by `require_web_account`, pinned by the S5 test; no identity enters the package); rule 12 web paragraph (the ONE gate). `grep -c require_web_account CLAUDE.md` → 2 (+ the backend paragraph by path).
- Epic (primary checkout) "Dependency rules for this epic": dw-18 ✔ bullet (gate, narrowing of the dw-12 forbidden edge, core divination ↛ account, signal via platform).
