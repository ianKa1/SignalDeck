# 07 — validating (dw-14-web-navigation)

Worktree `/Users/kaimao/Projects/astrology-wt/dw-14-web-navigation`, branch
`feature/dw-14-web-navigation`. Evidence files under the session scratchpad
`dw14/` (outputs `r1.out`…`r5.out`, screenshots `shots/`, driver `run.mjs`,
step scripts `s0-r1.mjs`, `s-r2.mjs`…`s-r5.mjs`, `s-narrow.mjs`, `s-lost.mjs`).

## Step 14 — automated (first pass, at be37638)

- root `npm test` → exit 0: jest `Tests: 1075 passed, 1075 total`; vitest `Test Files 33 passed (33)`, `Tests 343 passed (343)`.
- root `npm run typecheck` → exit 0.
- `npm --workspace web-divination run build` → exit 0.
- `cd server && DATABASE_URL= conda run -n astrology pytest -q` → `1380 passed, 55 skipped, 1 warning in 117.29s (0:01:57)`, exit 0 (no server file changed; same as baseline).

## Step 15 — real app R1–R5

Setup (ports 8002 / 5175 / 54342 / CDP 9342; nothing on 8000, 5173, 5180, 8001, 5174 touched):
- DB: `initdb -D dw14/pg -U astrace -A trust -E UTF8`; `pg_ctl -D dw14/pg -o "-p 54342 -k '' -c listen_addresses=127.0.0.1" start`; `createdb -h 127.0.0.1 -p 54342 -U astrace astrace_dw14`.
- Backend (NO `--env-file`): `env -u DATABASE_URL DATABASE_URL=postgresql://astrace@127.0.0.1:54342/astrace_dw14 GOOGLE_CLIENT_ID=dw14-placeholder.apps.googleusercontent.com ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5175 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --port 8002`.
  Live env via `ps eww`: `CORS_ALLOW_ORIGINS=http://localhost:5175`, `ANALYSIS_LLM=claude-cli`, `DATABASE_URL=postgresql://astrace@127.0.0.1:54342/astrace_dw14`, `GOOGLE_CLIENT_ID=dw14-placeholder.apps.googleusercontent.com`.
  `curl localhost:8002/api/health` → `{"status":"ok","db":"ok","ephemeris":"ok"}`.
- Vite: `cd web-divination && VITE_API_BASE=http://localhost:8002 GOOGLE_CLIENT_ID=dw14-placeholder.apps.googleusercontent.com npx vite --port 5175 --strictPort`.
- Browser: headless Chrome 154 (`--remote-debugging-port=9342`, fresh `--user-data-dir=dw14/chrome-profile`, 1280×900), driven by `dw14/run.mjs` over CDP.
- Sign-in: `dw14/mint.py`, run as `DATABASE_URL=postgresql://astrace@127.0.0.1:54342/astrace_dw14 PYTHONPATH=server conda run -n astrology python mint.py dw14.real@example.com`:
```python
# dw-14 validation only (NOT shipped): mint a bearer pair on the THROWAWAY db
# exactly as the Google route would after verification: _upsert_user + _mint_bearer.
import json, os, sys
assert os.environ["DATABASE_URL"].startswith("postgresql://astrace@127.0.0.1:54342/"), "throwaway db only"
from app import db
from app.accounts.service import _upsert_user, _mint_bearer
email = sys.argv[1]
with db.connect() as conn:
    uid = _upsert_user(conn, email)
    access, refresh, exp = _mint_bearer(conn, uid)
print(json.dumps({"email": email, "userId": str(uid), "accessToken": access, "refreshToken": refresh, "accessExpiresAt": exp.isoformat()}))
```
  pair1 → `dw14.real@example.com 6bb1605f-eedc-47d4-a29e-90831fe930fd elzr6R… 2026-10-06T19:49:34.237082+00:00`; pair2 (R5) → same user id `6bb1605f-…`, access `V8yDL6…`. Written to `astrace.auth.access/.refresh/.expiresAt` with the Beijing 1990-06-15 08:30 birth record and `astrology.divination.active.v1 = "venus"`, then reload.

### Raw driver output

`r1.out`:
```
gate status 200
gate shown: true
R1 reload status 200
R1 state {"path":"/","title":"The six · Astrace","plates":["venus","moon","mars","jupiter","saturn","mercury"],"last":["venus"],"wheel":false,"chat":false,"dialog":false,"email":"dw14.real@example.com","nav":["The six|/|page","Sessions · 0|/sessions|null"],"birth":"Your birth1990-06-15 · 08:30 · Beijing (Asia/Shanghai)Edit"}
R1 reload again 200
R1 after reload {"path":"/","title":"The six · Astrace","plates":["venus","moon","mars","jupiter","saturn","mercury"],"last":["venus"],"wheel":false,"chat":false,"dialog":false,"email":"dw14.real@example.com","nav":["The six|/|page","Sessions · 0|/sessions|null"],"birth":"Your birth1990-06-15 · 08:30 · Beijing (Asia/Shanghai)Edit"}
placement line (moon): in Pisces · 8th house
requests to :8002 ["GET http://localhost:8002/api/auth/whoami","OPTIONS http://localhost:8002/api/auth/whoami","OPTIONS http://localhost:8002/api/divination/sheets","POST http://localhost:8002/api/divination/sheets","POST http://localhost:8002/api/divination/sheets","OPTIONS http://localhost:8002/api/divination/sheets","GET http://localhost:8002/api/auth/whoami","POST http://localhost:8002/api/divination/sheets","POST http://localhost:8002/api/divination/sheets"]
```

`r2.out`:
```
R2 after click {"path":"/chat/moon","title":"Moon · Astrace","wheel":true,"planets":10,"chat":"Moon","plates":0,"user":[],"persona":["☽MoonCome and sit in the quiet with me. I keep watch over your nights, and I notice what y"],"focused":"H2.chat__title screen-heading"}
R2 reply arrived after 16 s
R2 exchange {"path":"/chat/moon","title":"Moon · Astrace","wheel":true,"planets":10,"chat":"Moon","plates":0,"user":["You: Will this restless week settle down?"],"persona":["☽MoonCome and sit in the quiet with me. I keep watch over your nights, and I notice what y","☽MoonSome of it, yes.Part of this week's itch is a small snag in the sky that's gone by Sa"],"focused":"TEXTAREA.chat__input"}
sessions KV [{"state":"open","id":"s-1790711430952","persona":"moon","lang":"en","startedAtUtc":"2026-09-29T19:50:30.952Z"}]
R2 home link {"path":"/","title":"The six · Astrace","wheel":false,"planets":0,"plates":6,"user":[],"persona":[],"focused":"H2.roster__title screen-heading"}
R2 Back {"path":"/chat/moon","title":"Moon · Astrace","wheel":true,"planets":10,"chat":"Moon","plates":0,"user":["You: Will this restless week settle down?"],"persona":["☽MoonCome and sit in the quiet with me. I keep watch over your nights, and I notice what y","☽MoonSome of it, yes.Part of this week's itch is a small snag in the sky that's gone by Sa"],"focused":"BODY."}
R2 Forward {"path":"/","title":"The six · Astrace","wheel":false,"planets":0,"plates":6,"user":[],"persona":[],"focused":"BODY."}
R2 Back again then reload: 200
R2 after reload {"path":"/chat/moon","title":"Moon · Astrace","wheel":true,"planets":10,"chat":"Moon","plates":0,"user":["You: Will this restless week settle down?"],"persona":["☽MoonCome and sit in the quiet with me. I keep watch over your nights, and I notice what y","☽MoonSome of it, yes.Part of this week's itch is a small snag in the sky that's gone by Sa"],"focused":"BODY."}
```

`r3.out`:
```
R3 list {"path":"/sessions","title":"Sessions · Astrace","cards":["moon|/sessions/s-1790711430952|☽Moon·begun 29 Sept 2026Will this restless week settle down?In progress"],"reader":"Choose a session to read it again.","nav":["The six|null","Sessions · 1|page"]}
R3 opened {"path":"/sessions/s-1790711430952","title":"Sessions · Astrace","cards":["moon|/sessions/s-1790711430952|☽Moon·begun 29 Sept 2026Will this restless week settle down?In progress"],"reader":"← All sessions☽Moon·begun 29 Sept 2026Will this restless week settle down?In progressContinue with Moon →The conversationYou: Will this restless week settle down?☽MoonSome of it, yes.Part of this week's itch is a small snag in the sky that's gone by Saturday, ","continueLink":"/chat/moon","nav":["The six|null","Sessions · 1|page"]}
R3 reload 200
R3 after reload {"path":"/sessions/s-1790711430952","title":"Sessions · Astrace","cards":["moon|/sessions/s-1790711430952|☽Moon·begun 29 Sept 2026Will this restless week settle down?In progress"],"reader":"← All sessions☽Moon·begun 29 Sept 2026Will this restless week settle down?In progressContinue with Moon →The conversationYou: Will this restless week settle down?☽MoonSome of it, yes.Part of this week's itch is a small snag in the sky that's gone by Saturday, ","continueLink":"/chat/moon","nav":["The six|null","Sessions · 1|page"]}
R3 Back {"path":"/sessions","title":"Sessions · Astrace","cards":["moon|/sessions/s-1790711430952|☽Moon·begun 29 Sept 2026Will this restless week settle down?In progress"],"reader":"Choose a session to read it again.","nav":["The six|null","Sessions · 1|page"]}
```

`r4.out`:
```
R4 /sessions HTTP 200 {"path":"/sessions","title":"Sessions · Astrace","appRoot":true,"signOutVisible":"Sign out:true","lost":null,"missing":null,"screen":"Sessions"}
   one click on the masthead link → /
R4 /sessions/s-1790711430952 HTTP 200 {"path":"/sessions/s-1790711430952","title":"Sessions · Astrace","appRoot":true,"signOutVisible":"Sign out:true","lost":null,"missing":null,"screen":"Sessions"}
   one click on the masthead link → /
R4 /chat/saturn HTTP 200 {"path":"/chat/saturn","title":"Saturn · Astrace","appRoot":true,"signOutVisible":"Sign out:true","lost":null,"missing":null,"screen":"Saturn"}
   one click on the masthead link → /
R4 /nowhere HTTP 200 {"path":"/nowhere","title":"Off the chart · Astrace","appRoot":true,"signOutVisible":"Sign out:true","lost":"No page by that name in this sky","missing":null,"screen":"No page by that name in this sky"}
   one click on the masthead link → /
R4 /chat/pluto HTTP 200 {"path":"/chat/pluto","title":"Off the chart · Astrace","appRoot":true,"signOutVisible":"Sign out:true","lost":"No character by that name","missing":null,"screen":"No character by that name"}
   one click on the masthead link → /
R4 /sessions/s-0 HTTP 200 {"path":"/sessions/s-0","title":"Sessions · Astrace","appRoot":true,"signOutVisible":"Sign out:true","lost":null,"missing":"That session isn't on this device","screen":"Sessions"}
   one click on the masthead link → /
R4 / HTTP 200 {"path":"/","title":"The six · Astrace","appRoot":true,"signOutVisible":"Sign out:true","lost":null,"missing":null,"screen":"The six"}
   one click on the masthead link → /
```

`r5.out`:
```
R5 End → bar card seal-card persona-scope seal-card--pending
KV after End [{"state":"sealed","id":"s-1790711430952","persona":"moon","lang":"en","startedAtUtc":"2026-09-29T19:50:30.952Z","endedAtUtc":"2026-09-29T19:51:55.356Z","entries":[{"role":"user","text":"Will this res
R5 sealed card seal-card persona-scope seal-card--ready :: ☽Moon·29 Sept 2026“Will this restless week settle down?”☽✶♅☽Tone: uneasyYou came in feeling unsettled by a restless week and asked whether it would pass, and the conversation ended with that question still open, without saying whether the restlessness comes from outside or from within.
R5 list ["/sessions/s-1790711430952|seal-card persona-scope seal-card--ready seal-card--button"]
R5 R3 URL still resolves /sessions/s-1790711430952 :: seal-card persona-scope seal-card--ready :: continue=false
R5 signed out {"path":"/sessions/s-1790711430952","gate":true,"app":false,"access":null}
   requests ["OPTIONS http://localhost:8002/api/auth/logout","POST http://localhost:8002/api/auth/logout"]
R5 reload 200
R5 after re-sign-in /sessions/s-1790711430952 :: dw14.real@example.com :: ← All sessions☽Moon·29 Sept 2026“Will this restless week settle down?”☽✶♅☽Tone: uneasyYou came in feeling unsettled by a restless week and asked whether it would pass, and the conversation ended with 
```

### Verdicts
- **R1 PASS.** `/` with active `venus`: six plates in roster order, "last" on Venus only, no `[data-slot=stage]`/wheel, no `.chat`, no dialog; title "The six · Astrace"; running head `The six|/|page`, `Sessions · 0|/sessions|null`; the Moon plate's engraved line "in Pisces · 8th house" (sheets 200). A reload stays on `/` with the plates (`r1-home.png`).
- **R2 PASS.** Moon name → `/chat/moon`, 10 planets on the wheel, "Moon" chat, focus on `H2.chat__title screen-heading`. A real claude-cli turn ("Will this restless week settle down?") answered in 16 s; the log KV at once held `{"state":"open","id":"s-1790711430952","persona":"moon",…}` (no entries key). Masthead home link → `/`; Back → `/chat/moon` with the exchange; Forward → `/`; Back then reload → `/chat/moon` with the exchange and the wheel (10 planets), not Home, not another character (`r2-chat-moon.png`, `r2-reloaded.png`). Backend: `POST /api/divination/turn 200`.
- **R3 PASS.** No End pressed. Home → Sessions: `/sessions`, one Moon card `/sessions/s-1790711430952` "☽ Moon · begun 29 Sept 2026 · Will this restless week settle down? · In progress". Opened: `/sessions/s-1790711430952`, the reader shows the question, the Moon reply and "Continue with Moon →" (`/chat/moon`). Reload of that URL: identical. Back: `/sessions` (`r3-list.png`, `r3-reader.png`).
- **R4 PASS** (after the not-found layout fix below). Cold loads: `/sessions`, `/sessions/s-1790711430952`, `/chat/saturn`, `/nowhere`, `/chat/pluto`, `/sessions/s-0` and `/` each answered HTTP 200 with the app (Vite SPA fallback; `vite.log` has no 404). `/nowhere` → "No page by that name in this sky", `/chat/pluto` → "No character by that name", `/sessions/s-0` → "That session isn't on this device". On all seven, "Sign out" is visible and one click on the masthead wordmark reaches `/` (six plates).
- **R5 PASS.** At `/chat/moon` End session → bar card `seal-card--pending`, KV record `{"state":"sealed","id":"s-1790711430952",…,"startedAtUtc":"2026-09-29T19:50:30.952Z","endedAtUtc":"2026-09-29T19:51:55.356Z",…}` — the SAME id as R3's URL; the claude-cli summary sealed it (`seal-card--ready`, "“Will this restless week settle down?” … Tone: uneasy …"). `/sessions` lists `/sessions/s-1790711430952` (ready), which still resolves (no Continue link: sealed). Sign out from that URL → gate, path unchanged `/sessions/s-1790711430952`, access key null, requests `OPTIONS/POST /api/auth/logout` only. pair2 written, reload → that session's reader again, chip `dw14.real@example.com` (`r5-sealed.png`, `r5-gate.png`, `r5-back-in.png`).

### Defects found in the real app → back to implementing (cycles: 1)
1. **Not-found sat in the left grid column at ≥960 px** (`shots/r4_chat_pluto.png`): `main.layout.layout--lost` kept the chat grid's two columns. Fix: `.layout.layout--lost { grid-template-columns: minmax(0, 1fr); }`. Re-checked: `.lost` spans `{"left":36,"width":1208,"vw":1280}`, centred (`r4_nowhere_fixed.png`).
2. **The masthead overflowed at phone width (390 px)**: the new running head crowded the brand into a one-word column and the page scrolled sideways (`scrollWidth 411` at `innerWidth 390`; `narrow_.png` first capture). Fix: under 720 px the masthead stacks (brand row; running head full-width; chip + language toggle). Re-checked `/`, `/sessions/s-1790711430952`, `/chat/moon`: `scrollW 390 = vw 390`; on the session URL the list pane is `display:none` (reader alone, D2) (`narrow_*.png`).
Both CSS-only, commit 5f26840. Re-run after the fix: root `npm test` exit 0 (jest `1075 passed`; vitest `33 files / 343 tests passed`), `npm run typecheck` exit 0, web build exit 0.

## Teardown
Chrome (9342), Vite (5175), uvicorn (8002) killed; `pg_ctl -D dw14/pg stop -m fast` → "server stopped"; `dw14/pg`, `dw14/chrome-profile` and the pair files deleted. `lsof -iTCP:{9342,5175,8002,54342} -sTCP:LISTEN` → 0 lines each.

Status: validating → docs-sync.
