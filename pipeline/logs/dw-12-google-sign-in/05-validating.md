# 05 validating — dw-12-google-sign-in (worker #3, cycle 0)

Branch `feature/dw-12-google-sign-in` at `a5cb27a`. The shared remote Postgres in `.env` was never contacted: no backend in this feature was started with `--env-file`, `.env` was never exported, and every `DATABASE_URL` below names `127.0.0.1:54312`.

## Suites (tests only)
- `cd server && conda run -n astrology pytest -q` → `1151 passed, 55 skipped, 1 warning in 122.43s (0:02:02)` (the 55 skips are the env-guarded live-PG suites, incl. dw-12's 5; run live below).
- `npm test` → jest `Test Suites: 90 passed, 90 total` / `Tests: 1072 passed, 1072 total`; vitest `Test Files 23 passed (23)` / `Tests 199 passed (199)`.
- `npm run typecheck` → 0 errors (app-native + web-divination).
- Live-PG, throwaway cluster `/tmp/dw12-pg.ZJL2` (initdb -U astrace --auth=trust; pg_ctl `-p 54312 -c unix_socket_directories='' -c listen_addresses=127.0.0.1`; createdb astrace_dw12): `DATABASE_URL=postgresql://astrace@127.0.0.1:54312/astrace_dw12 conda run -n astrology pytest tests/test_google_auth.py tests/test_auth_integration.py -q -rs` → `31 passed, 1 warning in 0.68s` — zero skips (S4–S8 live cases PASSED; per-test names in 04-implementing.md step 2).
- G2 build + G12/G13 bites: recorded in 04-implementing.md (steps 4–5).

## Real app (ran for real)
Backend (no `--env-file`; env verified from the live process with `ps eww`: `DATABASE_URL=postgresql://astrace@127.0.0.1:54312/astrace_dw12`, `CORS_ALLOW_ORIGINS=http://localhost:5176`, `ANALYSIS_LLM=claude-cli`, `GOOGLE_CLIENT_ID=dw12-placeholder.apps.googleusercontent.com`):
`conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --port 8003`. Lifespan migrated the throwaway db (`schema_migrations` count 11).
Web: `cd web-divination && VITE_API_BASE=http://localhost:8003 GOOGLE_CLIENT_ID=dw12-placeholder.apps.googleusercontent.com npx vite --port 5176`.
Browser: headless Chrome 154 over CDP (:9333), fresh profile in `mktemp -d /tmp/dw12-chrome.XXXX`; a small node CDP driver (`scratchpad/dw12/cdp.mjs`, not shipped) with Network/Runtime events; screenshots in `scratchpad/dw12/`.

Mint script (validation only, never committed) — `scratchpad/dw12/mint.py`, run as `DATABASE_URL=postgresql://astrace@127.0.0.1:54312/astrace_dw12 PYTHONPATH=server conda run -n astrology python mint.py dw12.real@example.com`:
```python
# dw-12 validation only (NOT shipped): mint a bearer pair on the THROWAWAY db
# exactly as the Google route would after verification: _upsert_user + _mint_bearer.
import json, os, sys
assert os.environ["DATABASE_URL"].startswith("postgresql://astrace@127.0.0.1:54312/"), "throwaway db only"
from app import db
from app.accounts.service import _upsert_user, _mint_bearer
email = sys.argv[1]
with db.connect() as conn:
    uid = _upsert_user(conn, email)
    access, refresh, exp = _mint_bearer(conn, uid)
print(json.dumps({"email": email, "userId": str(uid), "accessToken": access, "refreshToken": refresh, "accessExpiresAt": exp.isoformat()}))
```
Output (tokens truncated here): `dw12.real@example.com 40f831d1-7bdf-4ba0-b8ae-4b4338449e25 Z9B0CK… Sozp5Q… 2026-10-06T01:49:24.709671+00:00`. Later mints (pair2, pair3) returned the SAME user id.

- **R1 PASS.** `GET :8003/api/health` → `{"status":"ok","db":"ok","ephemeris":"ok"}`; DATABASE_URL host `127.0.0.1`. Fresh profile at `http://localhost:5176/`: eyebrow "Before the sky opens", title "Sign in to meet your planets", the body line; `gsiScripts: 1`; button slot present with a GIS iframe (even with the placeholder id); `stage/side/chat: false`. Full request list: `GET http://localhost:5176/`, `GET https://accounts.google.com/gsi/client`, `…/gsi/style`, `…/gsi/button?theme=filled_black&shape=pill&size=large&text=signin_with&…&client_id=dw12-placeholder.apps.googleusercontent.com…&hl=en`, favicon. Requests to :8003: `[]` (no /api/chart, no /api/divination, not even whoami — empty KV). Screenshot `r1-gate.png`. (Then the Beijing 1990-06-15 08:30 birth record was written to `astrology.birthData.v1.traveler` as device data for R2.)
- **R2 PASS.** Minted pair written to the three KV keys, reload → app: 10 planets on the wheel, side "Your birth 1990-06-15 · 08:30 · Beijing (Asia/Shanghai) … ☉ Gemini · ☽ Pisces · ↑ Cancer", masthead email `dw12.real@example.com` (title attr same) + "Sign out"; :8003 requests `OPTIONS/GET /api/auth/whoami`, then `OPTIONS/POST /api/chart`. Second reload: identical state, `GET whoami` then `POST /api/chart`. Screenshot `r2-app.png`.
- **R3 PASS.** `psql … -c "DELETE FROM sessions WHERE token_hash = '<sha256(access)>'"` → `DELETE 1`; reload → app opened with the email; requests `GET whoami` (401) → `POST /api/auth/token/refresh` → `GET whoami` → `POST /api/chart`; KV refresh rotated `true`, access rotated `true`, new expiresAt `2026-10-06T01:49:42…`.
- **R4 PASS.** "Sign out" → requests `OPTIONS/POST /api/auth/logout`; auth keys `[null,null,null]`; device KV (`astrology.birthData.v1.traveler`, `astrology.profile.v1`) byte-identical; gate shown (`r4-gate-after-signout.png`); reload stays on the gate (`gate true stage false`). `curl POST :8003/api/auth/token/refresh` with the originally minted refresh token → `401`, with the rotated one KV held → `401`. Sign in again (pair2 via the script) → device KV identical to before sign-out (`true`). To exercise the SESSION LOG too: one real Venus turn through claude-cli ("Will this week bring clarity about my work?" → reply began "I can't promise you this week. The chart I'm holding is the sky from the night you were born…"), then End → `Sessions · 1`; sign out (device KV unchanged `true`), sign in again (pair3) → `astrology.divination.sessions.v1` identical `true`, "Sessions · 1", email shown (`r4-resigned-in.png`). `select count(*) from users where email='dw12.real@example.com'` → `1`.
- **R5 PASS.** Backend killed and restarted with `env -u DATABASE_URL` (live env has no DATABASE_URL; health `{"status":"ok","db":"unconfigured","ephemeris":"ok"}`); KV still held pair3 (minted before the restart). Reload → gate with "Sign-in is unavailable — the server has no account database." + "Try again", no button slot, no stage; only `GET /api/auth/whoami`. Try again → one more whoami, same state. Direct `POST /api/auth/google {credential:"x"}` → `503 {"detail":"accounts unavailable"}` (`r5-unavailable.png`). Then Vite restarted with `GOOGLE_CLIENT_ID= VITE_GOOGLE_CLIENT_ID=`, auth keys cleared → "Sign-in isn't set up (no Google client id).", no button slot, 0 GSI scripts, requests only the page + favicon (`r5-unconfigured.png`).
- **U1 PENDING USER INPUT** — not run, not faked. Needs: a real `GOOGLE_CLIENT_ID` for an OAuth 2.0 *Web* client whose Authorized JavaScript origins include `http://localhost:5173` and `http://localhost:5180`, put in the root `.env` (and shell-exported to the backend), plus a Google account to click through; run on a FRESH throwaway cluster with `ANALYSIS_LLM=claude-cli`, Vite on :5173 or :5180 (never :5176), `CORS_ALLOW_ORIGINS` naming that origin.

## Teardown
uvicorn (8003), Vite (5176), headless Chrome (9333) killed; `pg_ctl stop`, `/tmp/dw12-pg.ZJL2` and `/tmp/dw12-chrome.*` deleted. `lsof -iTCP:{8003,5176,54312,9333} -sTCP:LISTEN` → 0 lines each.

## Incident (shared scratchpad)
The session scratchpad is shared by all wave workers. While starting Chrome I first used `scratchpad/chrome-profile`, got `SingletonLock: File exists`, and ran `rm -rf scratchpad/chrome-profile` — that directory belonged to ANOTHER worker's live headless Chrome (`--remote-debugging-port=9232`). I recreated the empty directory immediately and moved all my files under `scratchpad/dw12/`. That worker's browser may have lost its profile state (cookies/localStorage on disk); its process was left running and untouched otherwise. Reported to the coordinator.

**Transition:** validating → docs-sync (cycle 0; R1–R5 pass on the real app; U1 pending user input).
