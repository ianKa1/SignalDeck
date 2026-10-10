# Plan — dw-19-rename-planet-chat

Spec: `pipeline/specs/dw-19-rename-planet-chat.md` (D1–D11). Worktree `../astrology-wt/dw-19-rename-planet-chat`. Throwaway cluster 127.0.0.1:54316 (fresh dbs `dw19_web`, `dw19_main`). Every backend/pytest run sets `DATABASE_URL` and `WEB_DATABASE_URL` explicitly (local or empty); never `--env-file .env`; the Neon URLs are never used.

Review notes settled: NB2 the `DIVINATION WEB EPIC` allowlist entry is bound to CLAUDE.md AND the exact string `formerly the DIVINATION WEB EPIC`; NB3 the epic's current-state sections are checked under N10; N-c the SQLite first-use move is guarded by a module-level lock and is idempotent (re-check both paths inside the lock). The allowlist file `rename-allowlist.json` (repo root) entries are `{path_glob, pattern}` pairs, read by both guards.

## Steps

- [x] **0. Golden values + baseline.** On the base commit, record `summary_key`/`voice_key` for fixed inputs (for N4) and suite counts in the log. Done-when: values logged; suites green.
- [x] **1. Server rename.** `git mv server/app/divination server/app/planet_chat`; update imports, identifiers, routes `/api/planet_chat/*`, 503 detail, logs, thread prefix, `main.py`, `generation.py`, `models.py` (`PlanetChat*Request`, `PlanetChatPersona`), `accounts/web` gate references, prompt topic names with frozen key literals (D5), env var + fallback (D4), `server/app/ARCHITECTURE.md`; rename test files and fixtures; conftest stub list; prompt-lab files. Done-when: `npm run server:test` green (explicit URLs).
- [x] **2. Data bridges (server).** Migration `013_planet_chat_rename.sql` (tables + pkey constraints); store names only new tables; SQLite move/rename helper with lock (D7); tests N4 (goldens), N5 (live, `TEST_DATABASE_URL`), N6, N7. Done-when: those tests pass, 0 skips with TEST_* URLs set.
- [x] **3. Core + web rename.** `git mv packages/core/src/divination packages/core/src/planet_chat`, package.json export `./planet_chat`; all importers (`web-account`, `account`, web tree); identifiers; KV keys + `migrateLegacyKeys()` (D8) called lazily by the three readers; dw-16 wipe list; core test files renamed kebab-case; `architecture.test.ts`/`color-guard.test.ts` paths and rule names. Test N8. Done-when: `npm test` + `npm run typecheck` green.
- [x] **4. UI name + rename guards.** N9 grep (log "none existed" or the strings changed); `rename-allowlist.json`; server guard `test_no_divination_in_live_code` + jest guard, both with planted self-checks (N2). Done-when: both guards green and bite.
- [x] **5. Docs.** CLAUDE.md (D10/D11), `docs/ARCHITECTURE.md`, `.env.example`, the epic's current-state sections (absolute path). Done-when: N1 grep lists only the allowlist; N10 checks.
- [x] **6. Validate on the real app** (validating stage): record the dev cluster's `divination_summary`/`divination_voice` row counts; backend :8001 from the worktree with explicit `DATABASE_URL=…54320/astrace_dev WEB_DATABASE_URL=…54320/astrace_web CORS_ALLOW_ORIGINS=http://localhost:5174 ANALYSIS_LLM=claude-cli` (migration 013 applies at startup); Vite :5174; headless Chrome CDP 9324 seeded with old `astrology.divination.*` keys + a minted `@example.com` web pair; R1. Note: after landing, the user's :8000 (old code) would find the tables renamed — flag in the report. Done-when: R1 evidence logged; servers stopped; test user deleted.

## Acceptance map

| Criterion | Step |
|---|---|
| N3 | 1 |
| N4–N7 | 2 |
| N8 | 3 |
| N2, N9 | 4 |
| N1, N10 | 5 |
| R1 | 6 |

## Risks for the implementer

- Migration 013 applied to the dev cluster's `astrace_dev` by the validation backend RENAMES the tables the user's still-running old backend (:8000, primary checkout) reads — its summary/voice caches would miss (and its store would try to create the old tables in Postgres? check: the store's Postgres path relies on migrations; a miss just regenerates). Do R1 against a COPY: `createdb -T astrace_dev astrace_dev_dw19` on the dev cluster, and use that as the main db for R1, leaving `astrace_dev` untouched until the user's backend is restarted on landed code.
- The jest barrel-consumption guard and G-guards reference `divination` paths — move them in the same commit as the files.
- `git mv` of `packages/core/src/divination` changes the vite alias/tsconfig paths only if they name the module (they alias `packages/core/src/` wholesale — verify).
