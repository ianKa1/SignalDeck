# 06 — validating (2026-09-29, parallel-wave worker)

## Suites (after the 05-merge of dw-17)

- `DATABASE_URL= WEB_DATABASE_URL= TEST_WEB_DATABASE_URL=postgresql://astrace@127.0.0.1:54316/dw16_web TEST_DATABASE_URL=postgresql://astrace@127.0.0.1:54316/dw16_main pytest -q`
  → **1431 passed, 50 skipped** (the 50 = pre-existing DATABASE_URL-guarded main-db
  suites; the dw-16 live suite ran, 0 skipped).
- `npm test` → jest **1078 passed**; vitest **45 files, 427 passed**. `npm run typecheck` → 0 errors.

## Real app (plan step 12; U1 — live Google — is NOT this worker's: skipped, hand-back)

Setup (the user's :8000 / :5173 untouched throughout; checked with lsof before and after):
- Dev cluster 127.0.0.1:54320: `CREATE DATABASE astrace_web`; main db `astrace_dev`.
- Backend from the worktree on :8001, env set explicitly in the shell, no `--env-file`:
  `DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_dev WEB_DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_web CORS_ALLOW_ORIGINS=http://localhost:5174 ANALYSIS_LLM=claude-cli GOOGLE_CLIENT_ID=<from .env, not printed> uvicorn app.main:app --app-dir server --port 8001`.
  `ps eww` of the listener showed exactly those four values (both URLs on 127.0.0.1).
- Vite on :5174 (`VITE_API_BASE=http://localhost:8001 npx vite --port 5174 --strictPort`).
- Two isolated headless Chromes (`--user-data-dir=<scratch>/dw16-work/chrome-A|B`, CDP
  9316/9317) driven by a small node CDP script (`scratchpad/dw16-work/cdp.mjs`, r2a/r2b/r3/r4.mjs).
- Google is stood in for by minted pairs (script below, recorded verbatim); tokens
  are written to scratch JSON files, never printed.

First attempt (before the merge) was abandoned: the backend had been started under
`env -i`, and the claude CLI exited 1 (`job divination_voice failed … claude CLI exited 1`)
— the persona reply never arrived. Restarted with the normal shell environment plus the
explicit DB/CORS/LLM variables (the shell has no DATABASE_URL/WEB_DATABASE_URL: `env | grep -c` → 0),
after truncating the web tables and re-minting.

### The mint script (scratchpad/dw16-work/mint.py)

```python
"""dw-16 validation: stand in for Google by minting a web bearer pair.

Upserts web_users by email and mints a pair with the SAME helper the
/api/web/auth/google route uses (accounts.web.service._mint) — only the Google
verification is skipped. WEB_DATABASE_URL must be the local astrace_web;
refuses anything else. Writes {email, accountId, accessToken, refreshToken,
accessExpiresAt} JSON to the path given (never printed).
"""
import json
import os
import sys

WEB = "postgresql://astrace@127.0.0.1:54320/astrace_web"
os.environ["WEB_DATABASE_URL"] = WEB
os.environ["DATABASE_URL"] = ""
sys.path.insert(0, "/Users/kaimao/Projects/astrology-wt/dw-16-web-account-db/server")

from app import db  # noqa: E402
from app.accounts.web import service  # noqa: E402

email, out = sys.argv[1], sys.argv[2]
assert db.web_is_configured()
with db.connect_web() as conn:
    user_id = conn.execute(
        "INSERT INTO web_users (email) VALUES (%s) ON CONFLICT (email) "
        "DO UPDATE SET email = web_users.email RETURNING id",
        (email,),
    ).fetchone()[0]
    access, refresh, expires = service._mint(conn, user_id)
with open(out, "w") as f:
    json.dump({"email": email, "accountId": str(user_id), "accessToken": access,
               "refreshToken": refresh, "accessExpiresAt": expires.isoformat()}, f)
print(f"minted a pair for {email} -> account {user_id}")
```

Minted: U `dw16.u@example.com` ×2 pairs (a1, a2 → account be7c8506-…), V `dw16.v@example.com`
(5b0e454a-…), W `dw16.w@example.com` (7580a2ae-…).

### R1

`curl localhost:8001/api/health` → `{"status":"ok","db":"ok","webDb":"ok","ephemeris":"ok"}`;
process env as above; `astrace_web` tables: web_access_tokens web_birth_profiles
web_refresh_tokens web_schema_migrations web_sessions web_users. **PASS**

### R2 (loop closed, minted)

Browser A (pair a1): app opened (owner set to U's accountId); filled the birth form in
the UI (1990-06-15 08:30, CN → Beijing) → `PUT /api/web/profile 204`; `/chat/venus`,
sent "dw16 check: what does my Venus want this week?" → a 833-char Venus reply; backend
log: `POST /api/divination/turn 200`, then exactly two `PUT /api/web/sessions/s-1790716847902 204`
(user line, reply); dirty set empty. `astrace_web`:
`dw16.u@example.com|s-1790716847902|venus|open|2|persona|833|…` and profile
`1990-06-15|Beijing`.
Browser B (FRESH profile, pair a2 = second pair for U): opened with the same birth data
(chip "☉1990-06-15·Beijing"), running head "Sessions · 1", the Sessions list shows the Venus
conversation ("In progress"), `/chat/venus` shows the wheel and the same 2-entry transcript
with the reply in the chat (screenshot r2-B-chat.png). **PASS**

### R3

B: U signs out through the chip → account keys `[]`. V's pair → app opens as
dw16.v@example.com, "Sessions · 0", the birth FORM (no birth data), no session cards.
V signs out → account keys `[]`; all localStorage keys = `astrology.profile.v1`,
`astrology.lang.v1` (no birth-data, transcript, session-log, owner or dirty key). **PASS**

### R4 (import)

B seeded with legacy data (Shanghai birth data, a Venus open record + transcript, a sealed
Saturn record; no owner) and W's pair → the import card, app not mounted:
"This browser remembers | Bring these into your account? | This browser holds 2
conversations and a birth chart from before you signed in to dw16.w@example.com. | Import |
Discard" (screenshot r4-import-card.png). Import → app opens, owner = W's accountId,
"Sessions · 2". `astrace_web`: `s-1780000000000|saturn|sealed|2|ready`,
`s-1780000100000|venus|open|2|`, profile `1988-03-02|Shanghai`. Reload → no import card,
the app opens. **PASS**

### R5 (main untouched)

`astrace_dev` before / after (scratchpad snapshot.sh):
- tables (identical): analysis_cache card_images divination_summary divination_voice journal
  login_tokens natal_artifacts otp_codes profiles refresh_tokens schema_migrations sessions users
- users=1 sessions=1 refresh_tokens=1 before AND after (identical); schema_migrations 12 → 12.
- The one delta: `divination_voice` 2 → 3 — the Venus character card the persona job
  generated for U's chart (rule 9's content-keyed, identity-free cache, by design; not an
  account table). **PASS** (users/sessions/refresh_tokens + table list identical, as the criterion states)

### Privacy spot-check

The :8001 backend log contains none of the six raw tokens, no transcript text
("dw16 check", "legacy:") and no birth place (Beijing, Shanghai).

### U1

Not run by this worker (needs the user's live Google sign-in) — hand-back item.

Teardown: :8001, :5174 and both Chromes stopped; :8000/:5173 still listening (the user's).

Status: validating → docs-sync (no trip back to implementing; cycles unchanged).
