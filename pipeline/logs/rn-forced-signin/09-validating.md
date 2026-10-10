# rn-forced-signin — 09 validating (2026-09-30, parallel-wave worker)

Branch `feature/rn-forced-signin` at `6c92af3` (steps 0–15 committed).
Scope of this log: everything that needs NO simulator. Step 16 (dev-client
rebuild) and step 17's A1 half are coordinator-serialized and not run here.

## Suites (from the step-15 run, same commit)

- Root `npm run typecheck` → EXIT 0.
- Root `npm test` → jest `Test Suites: 93 passed, 93 total` / `Tests: 1134 passed, 1134 total`;
  vitest `Test Files 48 passed (48)` / `Tests 447 passed (447)`; EXIT 0.
- Server (step 7): dormant `1503 passed, 123 skipped` EXIT 0; live env on
  fresh dbs `24 failed, 1591 passed, 11 skipped` — the 24 are exactly dev
  d47d24a's pre-existing live-env failures (see 08-implementing, step 5/7);
  0 skips in native_signin_live / route_auth / auth_integration /
  profiles_integration / db_integration / web_accounts_live.

## A2 — curl against two local backends (no --env-file; LLM/image keys blanked)

Commands (repo root of the worktree):

    env TOKENROUTER_API_KEY= ANTHROPIC_API_KEY= OPENAI_API_KEY= LLM_API_KEY= GEMINI_API_KEY= GOOGLE_API_KEY= \
      DATABASE_URL=postgresql://astrace@127.0.0.1:54317/rfs_main WEB_DATABASE_URL= \
      ~/miniconda3/envs/astrology/bin/python -m uvicorn app.main:app --app-dir server --port 8017 --host 127.0.0.1
    env <same keys blanked> DATABASE_URL= WEB_DATABASE_URL= \
      ~/miniconda3/envs/astrology/bin/python -m uvicorn app.main:app --app-dir server --port 8018 --host 127.0.0.1

Verbatim results (valid bodies, no bearer):

```
== :8017 (DATABASE_URL rfs_main, WEB_DATABASE_URL empty)
GET  /api/health -> {"status":"ok","db":"ok","webDb":"unconfigured","ephemeris":"ok"} 200
POST /api/chart (no bearer) -> {"detail":"not signed in"} 401
POST /api/transits (no bearer) -> {"detail":"not signed in"} 401
POST /api/analysis (no bearer) -> {"detail":"not signed in"} 401
POST /api/ask/fitness (no bearer) -> {"detail":"not signed in"} 401
GET  /api/analysis/card/x (no bearer) -> {"detail":"not signed in"} 401
GET  /openapi.json -> 404
== :8018 (DATABASE_URL empty, WEB_DATABASE_URL empty)
GET  /api/health -> {"status":"ok","db":"unconfigured","webDb":"unconfigured","ephemeris":"ok"} 200
POST /api/chart (no bearer) -> {"detail":"accounts unavailable"} 503
POST /api/transits (no bearer) -> {"detail":"accounts unavailable"} 503
POST /api/analysis (no bearer) -> {"detail":"accounts unavailable"} 503
POST /api/ask/fitness (no bearer) -> {"detail":"accounts unavailable"} 503
GET  /api/analysis/card/x (no bearer) -> {"detail":"accounts unavailable"} 503
GET  /openapi.json -> 404
```

A2 PASS: health 200 on both; chart / transits / analysis / ask fitness /
card pixels 401 with the main db and 503 with no db (chart included, web db
also empty); `/openapi.json` 404. Both servers stopped afterwards.

## Pending (needs device — coordinator-serialized)

- Step 16: dev-client rebuild on the simulator (new fingerprint).
- Step 17 A1: fresh install → the opening, then ONLY the gate; idb
  accessibility dump has no rail, chart or settings element.

Status: validating — needs device.
