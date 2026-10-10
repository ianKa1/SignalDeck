# Plan — dw-18-divination-auth

Spec: `pipeline/specs/dw-18-divination-auth.md`. Worktree `../astrology-wt/dw-18-divination-auth`. Throwaway test cluster 127.0.0.1:54316 (create fresh dbs `dw18_web`, `dw18_main`). Every backend/pytest run sets `DATABASE_URL` and `WEB_DATABASE_URL` explicitly (local or empty); never `--env-file .env`; the Neon URLs are never used.

Review notes settled: provider `clear()` is idempotent (removing absent KV keys is a no-op) — C2 asserts a double clear is harmless; `apiFetch`'s `credentials:'same-origin'` stays as is (the gate reads only the bearer; never switch to `include`); S4's byte comparison uses a deterministic fake `stream_turn`; postJson's new argument is an options object as the 5th parameter (existing 4-arg calls unchanged).

## Steps

- [x] **0. Baseline.** Suites in the worktree; counts logged. Done-when: green.
- [x] **1. Server gate.** `accounts/web/routes.py` `require_web_account`; `main.py` four decorators `dependencies=[Depends(require_web_account)]`; autouse override fixture for existing divination route tests (module-level fixtures or a conftest fixture keyed on the test module list); prompt-lab override stub. Done-when: full `npm run server:test` green with explicit empty URLs.
- [x] **2. Server tests.** New `server/tests/test_divination_auth.py`: S1 (dormant, spies incl. `cached_for`), S2 (live-WEB on `TEST_WEB_DATABASE_URL` + `TEST_DATABASE_URL` for the native token; `{}` → 401, malformed → 422, zero calls), S3, S4 (deterministic fake `stream_turn`, bytes equal to overridden run), S6 signatures; boundary S5 in `test_boundaries.py` with a planted-route self-check. Done-when: those tests pass with 0 skips when the TEST_* URLs are set.
- [x] **3. Core transport.** `platform/auth.ts` `onUnauthorized`/`reportUnauthorized`; `platform/poll.ts` `postJson(path, body, outer, timeoutMs?, opts?)` → `apiFetch` when `opts.auth`, report on a final 401; `platform/api.ts` comment; `platform/index.ts` exports; `divination/turn.ts` (bearer header, release first chunks, one refresh, retry, `unauthorized`), `types.ts`, `summary.ts`, `persona.ts`, `roster.ts` pass `{auth:true}`; `account/google-session.ts` subscribes. Tests C1–C4 (+ double-clear) in the existing core test files under `web-divination/src/**/core-*.test.ts`. Done-when: vitest + typecheck green; jest guards green.
- [x] **4. App behaviour.** `chat/useChat.ts` handles `unauthorized` silently if needed; C5 test (App-level: a divination 401 → gate, wipe keys absent). Done-when: `npm test` green.
- [x] **5. Docs.** CLAUDE.md (backend paragraph, rule 10 divination paragraph, rule 12 web paragraph), epic dependency rule (absolute path in the primary checkout). Done-when: grep shows each.
- [x] **6. Validate on the real app** (validating stage): backend from the worktree :8001 with `DATABASE_URL=…54320/astrace_dev WEB_DATABASE_URL=…54320/astrace_web CORS_ALLOW_ORIGINS=http://localhost:5174 ANALYSIS_LLM=claude-cli` (normal shell env, not `env -i`); a second backend :8004 with `WEB_DATABASE_URL=` empty for R1's 503; Vite :5174; minted web pair in headless Chrome (CDP 9322). R1–R3. Done-when: evidence in the validating log; servers stopped.

## Acceptance map

| Criterion | Step |
|---|---|
| S1–S4, S6 | 1, 2 |
| S5 | 2 |
| C1–C4 | 3 |
| C5 | 4 |
| G1 | 3–5 |
| R1–R3 | 6 |

## Risks for the implementer

- Existing divination tests are many; an override fixture that leaks into `test_divination_auth.py` would make S1/S2 vacuous — the new module asserts `app.dependency_overrides` has no `require_web_account` entry.
- The jest barrel-consumption guard: `onUnauthorized`/`reportUnauthorized` must be consumed outside `platform` (google-session and poll are inside core — check the guard's corpus rule).
- `postJson` through `apiFetch` must keep its own timeout abort composition.
