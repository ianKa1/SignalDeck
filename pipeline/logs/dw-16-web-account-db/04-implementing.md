# 04 — implementing (2026-09-29, parallel-wave worker)

Worktree `/Users/kaimao/Projects/astrology-wt/dw-16-web-account-db`, branch
`feature/dw-16-web-account-db` from 2e6cfe8. Every pytest run sets
`DATABASE_URL` and `WEB_DATABASE_URL` explicitly (empty, or the throwaway
cluster 127.0.0.1:54316 dbs `dw16_main` / `dw16_web`); `.env` is never loaded.

## Step 0 — baseline

- `DATABASE_URL= WEB_DATABASE_URL= pytest -q` (server/): **1380 passed, 55 skipped**.
- `npm test`: jest **1078 passed**; vitest **42 files, 386 passed**.
- `npm run typecheck`: green (app-native + web-divination).

## Step 1 — db web door

- `db/migrations.py`: `apply_pending(conn, directory=MIGRATIONS_DIR, ledger="schema_migrations")`,
  `migration_files(directory=MIGRATIONS_DIR)`; ledger names allow-listed
  (`schema_migrations`, `web_schema_migrations`). Main call unchanged.
- `db/__init__.py`: `web_is_configured`, `connect_web`, `web_health`,
  `apply_web_migrations`, `web_config_warning` (identical URL → dormant + message).
- `db/web_migrations/001_web_accounts.sql`: five `web_` tables + index
  `(user_id, started_at)`.
- `tests/conftest.py` pops `WEB_DATABASE_URL` at import.
- Scratch apply on `dw16_web` (both URLs explicit, throwaway cluster):
  `True ok` / `['001_web_accounts']` / `[]`; tables = web_access_tokens,
  web_birth_profiles, web_refresh_tokens, web_schema_migrations, web_sessions,
  web_users; `dw16_main` still 0 tables.
- `pytest tests/test_db.py -q` → 7 passed.

## Steps 2–3 — accounts/web + routes + main wiring

- `accounts/web/{__init__,service,data,routes}.py`: `WebUnavailable`; `sign_in_google`
  (require-web FIRST, then `google.verified_email`; upsert `web_users` by citext
  email; mint into `web_access_tokens`/`web_refresh_tokens`), `refresh_access`
  (DELETE … RETURNING rotation), `user_for`, `logout`, `delete_account`
  (cascade). `data.py`: profile get/put(null deletes), sessions list
  (`started_at DESC NULLS LAST, updated_at DESC`) / upsert on (user_id,id) /
  delete; timestamps written back as `YYYY-MM-DDTHH:MM:SS.sssZ` (the browser's
  own `toISOString` shape, so a pulled record round-trips byte-identically).
- `routes.py` `web_router` (`/api/web`): D4/D5 bodies; session id checked on a
  `{session_id:path}` param so `..%2Fx` reaches the regex (422), N5 total text
  bound 2,000,000; persona from `models.DivinationPersona`; own refresh gate.
- `main.py`: includes `web_router`; lifespan logs `web_config_warning()` once
  and applies web migrations when configured; `/api/health` + `webDb`.
- Removed `accounts/service.sign_in_google` (+ its `google` import) and
  `accounts/routes.post_google`/`GoogleBody`; `google.py` docstring names
  `accounts/web/service.py` as its one app importer. `test_health.py` expects
  the additive `webDb` field.
- Done-when (TestClient, no URLs): `/api/web/auth/whoami` → 503
  `{"detail":"web accounts unavailable"}`; `/api/auth/google` → 404;
  `PUT /api/web/sessions/..%2Fx` → 422.

## Steps 4–5 — server tests + boundaries

- `test_google_auth.py`: db-free route cases retargeted to `/api/web/auth/google`
  with `db.web_is_configured` patched; S8 static scan reads the web service/route;
  the main-db live section (S4–S8 on `/api/auth/google`) removed — its web
  equivalents are A1/A2/S7 in the live file.
- `test_web_accounts.py` (db-free, 34): D1 (10 routes × 503, verifier never
  called; identical URLs dormant; ONE startup WARNING via caplog, URL not
  logged; distinct URL migrated at startup), A4, S6 (13 × 422 incl. N5 and an
  id/path mismatch; limits inclusive), S7 static scan + planted bite.
- `test_web_accounts_live.py` (14): D2, D2-main, D3, A1, N4, A2, A3, S1–S5, S7 caplog.
  Command: `TEST_WEB_DATABASE_URL=postgresql://astrace@127.0.0.1:54316/dw16_web
  TEST_DATABASE_URL=postgresql://astrace@127.0.0.1:54316/dw16_main DATABASE_URL=
  WEB_DATABASE_URL= pytest tests/test_web_accounts*.py tests/test_google_auth.py -q`
  → **67 passed, 0 skipped**.
- `test_boundaries.py` + B1–B4 (each with a planted self-check) → 39 passed.
- Full suite (same env incl. both TEST_ URLs): **1431 passed, 50 skipped**
  (the 50 are the pre-existing DATABASE_URL-guarded main-db suites).

Commit f45d28b — steps 1–5 (server).

## Step 6 — core session log + transcript

- `transcript.ts` + `replaceTranscript` (sanitized; empty removes the key).
- `session-log.ts`: cap removed (`SESSION_LIMITS = { refs: 8 }`), `write` keeps every
  live record; + `parseSessionRecord` (wire row → record, open entries attached),
  `replaceSessions`, `deleteSession`, `clearSessions`; barrel exports them.
- `log/core-session-log.test.ts`: the two cap tests became C10/C5 no-cap tests
  (60 sealed stay 60 after recordEntry + End); + 4 tests for the new writers → 40 passed.

## Step 7 — google-session on the web routes

- `account/google-session.ts`: `/api/web/auth/{whoami,google,logout}`, snapshot
  `{status,email,accountId}` (a whoami/sign-in without accountId → unavailable/error),
  `deleteGoogleAccount()` (DELETE /api/web/account; 204 → tokens cleared, signed-out).
  Web `platform/auth.ts` refresh → `/api/web/auth/token/refresh` (plain fetch).
- `auth/core-google-session.test.ts` retargeted + 4 new (C1) → 20 passed.

## Step 8 — core `web-account`

- `packages/core/src/web-account/{cloud,cache,sync,index}.ts`, package export
  `./web-account`. cloud: typed outcomes over apiFetch; `sessionWire` (strips
  `cause`, nulls) is both the PUT body and the diff key. cache: OWNER_KEY,
  DIRTY_KEY `{profile,sessions[],deleted[]}`, `hasLegacyData`, `legacyCount`,
  `wipeCache`. sync: status channel, open (owner match → flush dirty → pull; other
  owner → wipe → pull; no owner + legacy → adopt transcripts, ask), D10 resolve,
  pull seeds last-sent from the cache AFTER the write (jsonb reorders keys, so
  seeding from the wire would re-PUT), scheduler (300 ms/record, one in flight,
  dirty persisted at schedule time, retried on every change), tombstones,
  sign-out wipe of an owned cache only.
- Decision: a failed dirty FLUSH at boot skips the pull and opens on the owned
  cache (a pull would overwrite the unsaved change). Logged as a deviation.
- `auth/core-web-account.test.ts` → 17 passed (C2 ×2, C3, C4, C5, C6, error+retry,
  C7, C8 ×5 incl. N8 two PUTs/turn and never-concurrent, N9 tombstone, C9 ×3).

## Step 9 — gate + import card (after /frontend-design)

- `session.ts` installs web-account (`lang: getLanguage`); `auth/useAccountData.ts`;
  `SignInScreen` exports the `Threshold` card; `auth/ImportCard.tsx` (filled pill
  Import, text-button Discard); `AuthGate` renders the app only for signed-in +
  ready, else Opening your sky… / import card / Couldn't load your account + Try again.
- i18n en/zh: auth.syncing, loadError, import*, deleteAccount*, keep; log.delete,
  deleteConfirm, deleteYes, keep. The dw-12 `auth.body` line ("Your chart and
  conversations stay in this browser") was false now → rewritten (deviation: copy).
- AuthGate tests retargeted (/api/web/auth/*, accountId, W5 now asserts the wipe)
  + 4 new (W1 ×3, W2). App.test route mounts set the owner so the seeded cache is
  the account's (pull 503 → open on the owned cache).

## Step 10 — delete controls

- `log/SessionsScreen.tsx` reader: quiet Delete → inline confirm (Delete / Keep);
  `useSessions.remove` → `deleteSessionEverywhere`. `auth/AccountChip.tsx`: faint
  "Delete account" beneath Sign out → inline confirm; failure line. CSS tokens only.
- Tests: SessionsScreen +2 (W3), new `auth/AccountChip.test.tsx` (W4 + failure).
- Guard: `architecture.test.ts` BARREL_DEEP_IMPORT_RE gains `web-account` (+ self-check).
- A reduced-motion CSS test reads the FIRST reduced-motion block of log.css; the new
  block moved to the file end.

## Step 11 — docs + env

- CLAUDE.md: backend paragraph (replaces "chat, logs and caches stay device-local"),
  Commands (`WEB_DATABASE_URL` local/deploy/tests), rule 3 (google.py's one app
  importer), rule 6 (no journal writes, B3), rule 11 (two URLs/folders/ledgers,
  `web_` prefix, B1/B2), rule 12 (two PII budgets; Google on /api/web/auth/google).
- `.env.example`: commented `# WEB_DATABASE_URL=` with the local/deploy note, no value.

## Suites after step 11

- `npm test`: jest 1078 passed; vitest 44 files, 419 passed. `npm run typecheck`: 0 errors.
