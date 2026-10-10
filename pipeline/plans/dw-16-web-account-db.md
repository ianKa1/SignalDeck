# Plan — dw-16-web-account-db

Spec: `pipeline/specs/dw-16-web-account-db.md` (decided defaults D1–D17, Architecture, criteria). Worktree `../astrology-wt/dw-16-web-account-db`. Throwaway cluster for tests: 127.0.0.1:54316 (dbs `dw16_web`, `dw16_main`, scratchpad `dw16pg`). Every backend/pytest run sets `DATABASE_URL` and `WEB_DATABASE_URL` explicitly (local or empty); the Neon URLs in `.env` are never used.

Review notes settled here: N2 the main-db live guard for D3/A3 is `TEST_DATABASE_URL` (localhost only, fixture copies it into `DATABASE_URL`); N4 logout with a dead/missing bearer → 204; N5 PUT session body bound: total `sum(len(text)) ≤ 2,000,000` chars (422 above) on top of D5's per-entry limits; N7 D1's identical-URL warning is tested with caplog (criterion D1); N8 C8 also asserts ≤ 2 PUTs per turn for a streamed reply; N9 C8 gains an offline DELETE tombstone retried at next boot; N1 docs-sync updates the epic.

## Steps

- [x] **0. Baseline.** Run the three suites in the worktree and record counts in the implementing log. Done-when: pytest, jest+vitest, typecheck green (numbers logged).

- [x] **1. db web door.** `server/app/db/migrations.py` (directory + ledger parameters; main call unchanged), `server/app/db/__init__.py` (web door per Architecture; identical URL → dormant + one WARNING at startup via `web_config_warning()` that main.py logs), `server/app/db/web_migrations/001_web_accounts.sql` (five `web_` tables, citext, FKs cascade, CHECK state, PK (user_id,id), index on (user_id, started_at)). `server/tests/conftest.py` pops `WEB_DATABASE_URL`. Done-when: `pytest tests/test_db*.py -q` green; a scratch call of `apply_web_migrations()` on `dw16_web` twice applies then nothing.

- [x] **2. accounts/web service + data.** `server/app/accounts/web/{__init__,service,data}.py` per contracts (only `db.connect_web`; `WebUnavailable`; expired-row cleanup; `put_session` upsert; profile null deletes). Done-when: module imports with no db; unit tests in step 4 pass.

- [x] **3. routes + main wiring; remove the main-db Google path.** `accounts/web/routes.py` (pydantic bodies with D5 limits + N5 total bound, id regex, persona list from `app.divination.persona`? NO — B3 forbids; use `models.DivinationPersona`'s values via `app.models`), `main.py` (include router, lifespan `apply_web_migrations` when configured + the warning, `/api/health` `webDb`), delete `service.sign_in_google`, `routes.post_google`/`GoogleBody`, fix `accounts/google.py` docstring. Done-when: `curl` against a TestClient: `/api/web/auth/whoami` 503 with no web URL; `/api/auth/google` 404/405.

- [x] **4. Server tests.** `tests/test_google_auth.py` route tests retarget `/api/web/auth/google` (web door monkeypatched configured for S1-style checks); new `tests/test_web_accounts.py` (D1 incl. caplog warning, A4, S6, S7 source scan, logout-204 N4 with web door patched dormant/configured as needed); new `tests/test_web_accounts_live.py` guarded on `TEST_WEB_DATABASE_URL` (+ `TEST_DATABASE_URL` for D3/A3), refusing non-localhost hosts, truncating `web_*` tables per test: D2, D3, A1–A3, S1–S5, S7 caplog. Done-when: `TEST_WEB_DATABASE_URL=postgresql://astrace@127.0.0.1:54316/dw16_web TEST_DATABASE_URL=postgresql://astrace@127.0.0.1:54316/dw16_main conda run -n astrology pytest tests/test_web_accounts*.py tests/test_google_auth.py -q` all pass, 0 skipped.

- [x] **5. Boundary tests B1–B4** appended to `tests/test_boundaries.py`, each with a planted self-check. Done-when: full `npm run server:test` green.

- [x] **6. Core: session log + transcript additions.** `divination/transcript.ts` `replaceTranscript`; `divination/session-log.ts` remove the sessions cap (keep `SESSION_LIMITS.refs`; drop `.sessions` or keep documented unused? — drop and fix its test), add `replaceSessions`, `deleteSession`, `clearSessions`; barrel exports. Tests in `web-divination/src/log/core-session-log.test.ts` (C10 + replace/delete/clear). Done-when: vitest for that file green.

- [x] **7. Core: google-session to the web routes.** `account/google-session.ts` endpoints `/api/web/auth/*`, `accountId` in the snapshot (missing → unavailable), `deleteGoogleAccount()`; barrel export; web `platform/auth.ts` refresh URL. Update `auth/core-google-session.test.ts` (C1). Done-when: that test file green.

- [x] **8. Core: web-account module.** `packages/core/src/web-account/{cloud,cache,sync,index}.ts`, `packages/core/package.json` export. Pull/replace (D10 incl. older-open sealing), owner logic (D8), import (D9), wipe (D11: traveler birth data via `clearBirthData`, `clearSessions`, `ACTIVE_KEY`, dirty, owner), save scheduler (D7: diff per id vs last-sent seeded by pull; 300 ms coalesce; one in flight per id; strip `cause`; dirty set persisted; tombstones for `deleteSessionEverywhere`; profile save on birth-data change), flush-before-pull at boot, suppression during pull/wipe. Tests: `web-divination/src/auth/core-web-account.test.ts` covering C2–C9 (+N8, N9) with stubbed fetch and fake timers. Done-when: that file green; `npm run typecheck` green.

- [x] **9. Web gate + import card.** `session.ts` calls `installWebAccount()`; `auth/useAccountData.ts`; `auth/AuthGate.tsx` (signed-in + ready); `auth/ImportCard.tsx`; states in `SignInScreen`/gate for syncing/error; i18n en/zh. Load /frontend-design first. Tests `auth/AuthGate.test.tsx` updated (W1, W2; existing W-tests keep passing with a ready account stub). Done-when: auth tests + parity test green.

- [x] **10. Delete controls.** `log/SessionsScreen.tsx` reader Delete + inline confirm, `log/useSessions.ts` `remove`, `auth/AccountChip.tsx` Delete account + confirm, CSS in existing files with tokens only, i18n. Tests W3, W4 in `SessionsScreen.test.tsx` and a new `auth/AccountChip.test.tsx`. Done-when: `npm test` + `npm run typecheck` green; colour/text guards green.

- [x] **11. Docs + env.** CLAUDE.md (D17 amendments: backend paragraph, Commands, rules 3, 6, 11, 12), `.env.example` commented `WEB_DATABASE_URL=` with the deploy note (no value). Done-when: grep shows each amendment; G2 check.

- [x] **12. Validate on the real app** (validating stage): create `astrace_web` on the dev cluster; start a SEPARATE backend in the worktree on :8001 with `DATABASE_URL=…54320/astrace_dev WEB_DATABASE_URL=…54320/astrace_web CORS_ALLOW_ORIGINS=http://localhost:5174` and no `--env-file` (keys for the turn via `ANALYSIS_LLM=claude-cli`), Vite on :5174 with `VITE_API_BASE=http://localhost:8001`; snapshot `astrace_dev` table list + counts; mint pairs with a log-recorded script; two headless-Chrome profiles over CDP for R1–R5. The user's :8000/:5173 stay untouched. Done-when: R1–R5 evidence in the validating log.

## Acceptance map

| Criterion | Step |
|---|---|
| D1 | 1, 4 |
| D2, D3 | 1, 4 |
| A1, A2, A3 | 2, 3, 4 |
| A4 | 3, 4 |
| S1–S6 | 2, 3, 4 |
| S7 | 4 |
| B1–B4 | 5 |
| C1 | 7 |
| C2–C9 | 8 |
| C10 | 6 |
| W1, W2 | 9 |
| W3, W4 | 10 |
| G1 | 6–10 |
| G2 | 11 |
| R1–R5 | 12 |
| U1 | hand-back after accepting of everything else |

## Risks for the implementer

- The jest barrel-consumption guard (architecture.test.ts :944) fails on any new core barrel export that nothing outside its domain uses — export only what web code consumes (or tests in other folders).
- `recordEntry`'s first write prepends a header then later entries don't touch the log key; the save diff must read `listSessions()` (entries come from the transcript), not the raw KV.
- The pull writes birth data through `saveBirthData`, which fires the chart fetch and the save scheduler — suppress saves during the pull, and seed last-sent from the pulled profile.
- `hydrateWebTokens` runs at import; dw-12-era tokens will 401 → restore ends signed-out → an UNOWNED legacy cache must survive (C9).
- `models.py` imports heavy chart modules? `accounts/web/routes.py` importing `app.models` must not trip B3 (models is HTTP-layer, allowed). Persona ids come from `models.DivinationPersona`.
- React StrictMode double-mount: `installWebAccount` and the pull must be idempotent (one in flight).
- Live tests: `app.main` lifespan migrates `DATABASE_URL` when set — the live-web fixture must not leave the Neon or dev-cluster URL in the env; it sets `DATABASE_URL` to the throwaway main db or pops it.
