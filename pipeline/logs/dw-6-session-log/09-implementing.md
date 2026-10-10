# 09 implementing — dw-6-session-log (cycle 1: acceptance FAIL on A4)

Cause (08-accepting.md): End → backend killed → restart (~12 s) → reload left the card `failed`: the 5 s poll hit a refused connection (C5: rejected fetch → failed) and `resumeSummaries()` resumed only `pending`.

Decided fix (coordinator, journaled), implemented exactly:
- `packages/core/src/divination/summary.ts`: new core-internal `pollSummary(req, signal)` → `{ok:true, wire}` | `{ok:false, cause:'network'|'server'}` (`network` = rejected fetch; `server` = non-200/202, invalid 200 body, exhausted budget, abort). `fetchSummary` is now a wrapper over it (still null on any failure — contract unchanged). Not exported from the barrel.
- `session-log.ts`: `SessionSummary` failed gains optional `cause` (device-local, never on the wire); parse keeps a valid cause, drops anything else (old records → no cause → non-network). The loop stores `{status:'failed', cause}`. `resumeSummaries()` resumes `pending` AND `failed` with cause `network` (sets it `pending`, starts the loop); in-flight de-dupe unchanged.
- `web-divination/src/log/useSessions.ts`: comment only.
- Tests: C5 cases now assert the recorded cause (502/503/invalid tone/budget → `server`, rejected fetch → `network`) — strengthened, not weakened; C6 unchanged. New: network-failed record resumed on load → ready (with a second resume while in flight issuing nothing); server-failed and cause-less records NOT resumed; an A4 end-to-end core test (202, then refused → failed/network → resume → 200 → ready); App-level: on load a network-failed record is re-POSTed and a server-failed one is not.
- Docs: `docs/ARCHITECTURE.md` core summary/session-log bullets, the web `useSessions` line, web test count 163; feature doc known-limitations (gitignored).

Suites (verbatim):
- `npx vitest run src/log` → `Tests 47 passed (47)`.
- Root `npm test`: app-native `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`; web `Test Files 19 passed (19)` / `Tests 163 passed (163)`.
- `npm run typecheck` → 0 errors.
- Server `pytest -q` → `1129 passed, 50 skipped, 1 warning in 105.52s (0:01:45)` (no server change).
