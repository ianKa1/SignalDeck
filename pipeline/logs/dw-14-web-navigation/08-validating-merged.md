# 08 — validating on the merged code (dw-14-web-navigation + dw-15)

Coordinator message (after 07): dw-15-wheel-spotlight landed on
`feature/divination_web` as 8032e68; merge it in, resolve, re-run the suites,
and run the R checks on the merged code with the spotlight live on `/chat/<id>`.

## Merge (commit 0e17d38, `(chore): dw-14-web-navigation — merge feature/divination_web (dw-15)`)

`git merge --no-commit --no-ff feature/divination_web` → conflicts in
`app-native/src/architecture.test.ts`, `web-divination/src/app/App.tsx`,
`web-divination/src/test-setup.ts` (CLAUDE.md, en/zh, docs/ARCHITECTURE.md auto-merged).
- `App.tsx`: kept the routed App (ours); dw-15's one-line change
  `<ChartStage persona={active} />` moved to `app/ChatScreen.tsx` as
  `<ChartStage persona={persona} />` — the route's character.
- `architecture.test.ts`: both appended blocks kept (dw-15 G14/G15, then dw-14
  G16/G17); header comment names G14–G17. My first resolution dropped the
  shared closing `})` of dw-15's self-check (it sat outside the conflict hunk):
  `npm test` → `FAIL src/architecture.test.ts … Jest encountered an unexpected token`,
  tsc `src/architecture.test.ts(1281,1): error TS1005: '}' expected.` → restored.
- `test-setup.ts`: both — dw-15's node-environment guard on `localStorage`,
  plus `window` guards around dw-14's `scrollTo` stub and `replaceState` reset.
- dw-15's `chart/ChartStage.focus.test.tsx` mounts App: each case now starts at
  `/chat/venus`; F3's "no character" half is Home `/` (no wheel, no control, no
  focus — a chat route always has a character); F5 switches character by a
  move to `/chat/saturn` (pushState + popstate) instead of writing the "last"
  KV, and "the same one keeps the mode" re-notifies the same path and re-writes
  the KV — the mode stays.
- `npm install` at the root (dw-15 added canvaskit-wasm to web-divination).

Suites on the merge:
- root `npm test` → exit 0: jest `Tests: 1078 passed, 1078 total`; vitest `Test Files 42 passed (42)`, `Tests 386 passed (386)`.
- `npm run typecheck` → exit 0. `npm --workspace web-divination run build` → exit 0.
- `git diff 8032e68 -- web-divination/package.json` → empty (dw-14 adds no dependency).
- Server: no server file changed on either side (`git diff --name-only 416c3dd 8032e68 -- server` → 0, `416c3dd HEAD` → 0); the 07 pytest run stands (`1380 passed, 55 skipped`).

## R1–R5 again, on the merge

Same recipe as 07: fresh cluster (`initdb`/`pg_ctl` `-p 54342 -k ''` 127.0.0.1,
`createdb astrace_dw14`), backend :8002 without `--env-file` (live env
`CORS_ALLOW_ORIGINS=http://localhost:5175`, `ANALYSIS_LLM=claude-cli`,
`DATABASE_URL=postgresql://astrace@127.0.0.1:54342/astrace_dw14`; health
`{"status":"ok","db":"ok","ephemeris":"ok"}`), Vite :5175, fresh headless Chrome
profile on CDP :9342, pairs minted by `mint.py` for `dw14.merged@example.com`
(user `4534a1bb-a639-40ac-a001-34fd6234615b`; pair1 `WNqIbK…`, pair2 `nwmhPe…`).
First attempt: R1's script still had the 07 pair baked in (from the deleted
cluster) → `GET /api/auth/whoami 401`, `POST /api/auth/token/refresh 401`, the
gate stayed (`timeout waiting for document.querySelectorAll('.roster__plate').length === 6`).
The scripts now read the pair file at run time; rerun below.
R2's state now also reports the wheel's `data-focus`, the stage's `data-spotlight` and the shell's `data-persona`.

`r1.out` (merged):
```
gate status 200
gate shown: true
R1 reload status 200
R1 state {"path":"/","title":"The six · Astrace","plates":["venus","moon","mars","jupiter","saturn","mercury"],"last":["venus"],"wheel":false,"chat":false,"dialog":false,"email":"dw14.merged@example.com","nav":["The six|/|page","Sessions · 0|/sessions|null"],"birth":"Your birth1990-06-15 · 08:30 · Beijing (Asia/Shanghai)Edit"}
R1 reload again 200
R1 after reload {"path":"/","title":"The six · Astrace","plates":["venus","moon","mars","jupiter","saturn","mercury"],"last":["venus"],"wheel":false,"chat":false,"dialog":false,"email":"dw14.merged@example.com","nav":["The six|/|page","Sessions · 0|/sessions|null"],"birth":"Your birth1990-06-15 · 08:30 · Beijing (Asia/Shanghai)Edit"}
placement line (moon): in Pisces · 8th house
requests to :8002 ["GET http://localhost:8002/api/auth/whoami","OPTIONS http://localhost:8002/api/divination/sheets","POST http://localhost:8002/api/divination/sheets","POST http://localhost:8002/api/divination/sheets","OPTIONS http://localhost:8002/api/divination/sheets","GET http://localhost:8002/api/auth/whoami","POST http://localhost:8002/api/divination/sheets","POST http://localhost:8002/api/divination/sheets"]
```

`r2.out` (merged):
```
R2 after click {"path":"/chat/moon","title":"Moon · Astrace","wheel":true,"planets":10,"chat":"Moon","plates":0,"user":[],"persona":["☽MoonCome and sit in the quiet with me. I keep watch over your nights, and I notice what y"],"focused":"H2.chat__title screen-heading","focus":"Moon","spotlight":"loading","shell":"moon"}
R2 reply arrived after 14 s
R2 exchange {"path":"/chat/moon","title":"Moon · Astrace","wheel":true,"planets":10,"chat":"Moon","plates":0,"user":["You: Will this restless week settle down?"],"persona":["☽MoonCome and sit in the quiet with me. I keep watch over your nights, and I notice what y","☽MoonSome of it will, yeah.This week the Sun sits at an awkward angle to your Moon. It pea"],"focused":"TEXTAREA.chat__input","focus":"Moon","spotlight":"live","shell":"moon"}
sessions KV [{"state":"open","id":"s-1790711847399","persona":"moon","lang":"en","startedAtUtc":"2026-09-29T19:57:27.399Z"}]
R2 home link {"path":"/","title":"The six · Astrace","wheel":false,"planets":0,"plates":6,"user":[],"persona":[],"focused":"H2.roster__title screen-heading","focus":null,"spotlight":null,"shell":null}
R2 Back {"path":"/chat/moon","title":"Moon · Astrace","wheel":true,"planets":10,"chat":"Moon","plates":0,"user":["You: Will this restless week settle down?"],"persona":["☽MoonCome and sit in the quiet with me. I keep watch over your nights, and I notice what y","☽MoonSome of it will, yeah.This week the Sun sits at an awkward angle to your Moon. It pea"],"focused":"BODY.","focus":"Moon","spotlight":"live","shell":"moon"}
R2 Forward {"path":"/","title":"The six · Astrace","wheel":false,"planets":0,"plates":6,"user":[],"persona":[],"focused":"BODY.","focus":null,"spotlight":null,"shell":null}
R2 Back again then reload: 200
R2 after reload {"path":"/chat/moon","title":"Moon · Astrace","wheel":true,"planets":10,"chat":"Moon","plates":0,"user":["You: Will this restless week settle down?"],"persona":["☽MoonCome and sit in the quiet with me. I keep watch over your nights, and I notice what y","☽MoonSome of it will, yeah.This week the Sun sits at an awkward angle to your Moon. It pea"],"focused":"BODY.","focus":"Moon","spotlight":"live","shell":"moon"}
```

`r3.out` (merged):
```
R3 list {"path":"/sessions","title":"Sessions · Astrace","cards":["moon|/sessions/s-1790711847399|☽Moon·begun 29 Sept 2026Will this restless week settle down?In progress"],"reader":"Choose a session to read it again.","nav":["The six|null","Sessions · 1|page"]}
R3 opened {"path":"/sessions/s-1790711847399","title":"Sessions · Astrace","cards":["moon|/sessions/s-1790711847399|☽Moon·begun 29 Sept 2026Will this restless week settle down?In progress"],"reader":"← All sessions☽Moon·begun 29 Sept 2026Will this restless week settle down?In progressContinue with Moon →The conversationYou: Will this restless week settle down?☽MoonSome of it will, yeah.This week the Sun sits at an awkward angle to your Moon. It peaks on Oc","continueLink":"/chat/moon","nav":["The six|null","Sessions · 1|page"]}
R3 reload 200
R3 after reload {"path":"/sessions/s-1790711847399","title":"Sessions · Astrace","cards":["moon|/sessions/s-1790711847399|☽Moon·begun 29 Sept 2026Will this restless week settle down?In progress"],"reader":"← All sessions☽Moon·begun 29 Sept 2026Will this restless week settle down?In progressContinue with Moon →The conversationYou: Will this restless week settle down?☽MoonSome of it will, yeah.This week the Sun sits at an awkward angle to your Moon. It peaks on Oc","continueLink":"/chat/moon","nav":["The six|null","Sessions · 1|page"]}
R3 Back {"path":"/sessions","title":"Sessions · Astrace","cards":["moon|/sessions/s-1790711847399|☽Moon·begun 29 Sept 2026Will this restless week settle down?In progress"],"reader":"Choose a session to read it again.","nav":["The six|null","Sessions · 1|page"]}
```

`r4.out` (merged):
```
R4 /sessions HTTP 200 {"path":"/sessions","title":"Sessions · Astrace","appRoot":true,"signOutVisible":"Sign out:true","lost":null,"missing":null,"screen":"Sessions"}
   one click on the masthead link → /
R4 /sessions/s-1790711847399 HTTP 200 {"path":"/sessions/s-1790711847399","title":"Sessions · Astrace","appRoot":true,"signOutVisible":"Sign out:true","lost":null,"missing":null,"screen":"Sessions"}
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

`r5.out` (merged):
```
R5 End → bar card seal-card persona-scope seal-card--pending
KV after End [{"state":"sealed","id":"s-1790711847399","persona":"moon","lang":"en","startedAtUtc":"2026-09-29T19:57:27.399Z","endedAtUtc":"2026-09-29T19:57:56.147Z","entries":[{"role":"user","text":"Will this res
R5 sealed card seal-card persona-scope seal-card--ready :: ☽Moon·29 Sept 2026“Will this restless week settle down?”☽Tone: uneasyThey came in unsettled by a restless week, and by the end nothing in their own words showed the feeling had eased.
R5 list ["/sessions/s-1790711847399|seal-card persona-scope seal-card--ready seal-card--button"]
R5 R3 URL still resolves /sessions/s-1790711847399 :: seal-card persona-scope seal-card--ready :: continue=false
R5 signed out {"path":"/sessions/s-1790711847399","gate":true,"app":false,"access":null}
   requests ["OPTIONS http://localhost:8002/api/auth/logout","POST http://localhost:8002/api/auth/logout"]
R5 reload 200
R5 after re-sign-in /sessions/s-1790711847399 :: dw14.merged@example.com :: ← All sessions☽Moon·29 Sept 2026“Will this restless week settle down?”☽Tone: uneasyThey came in unsettled by a restless week, and by the end nothing in their own words showed the feeling had eased.The
```

`spot.out` (merged):
```
/chat/saturn {"focus":"Saturn","spotlight":"live","toggle":"♄Show full chart","last":"saturn"}
/chat/venus {"focus":"Venus","spotlight":"live","toggle":"♀Show full chart","last":"venus"}
```

### Verdicts (merged)
- **R1 PASS** — six plates, "last" on Venus, no wheel/chat/dialog, stays on `/` across reloads.
- **R2 PASS** — `/chat/moon`: wheel (10 planets) with the spotlight LIVE focused on the Moon (`focus: "Moon"`, `spotlight: "live"`, shell `data-persona="moon"`); a real claude-cli turn in 14 s; open record `s-1790711847399` at once; home link `/`; Back `/chat/moon` with the exchange (spotlight live); Forward `/`; Back + reload `/chat/moon` with the exchange, the wheel and the live spotlight.
- **R3 PASS** — `/sessions` shows the Moon "In progress" card; `/sessions/s-1790711847399` shows the exchange and "Continue with Moon →"; reload identical; Back `/sessions`.
- **R4 PASS** — all six cold URLs + `/` HTTP 200 with the app; the three not-found screens; Sign out visible and one wordmark click reaches `/` on each.
- **R5 PASS** — End seals the SAME id `s-1790711847399` (`startedAtUtc` kept, `endedAtUtc` set), summary `ready` via claude-cli; `/sessions` lists that id, which still resolves; Sign out from it → gate, URL unchanged, only `/api/auth/logout`; pair2 + reload → that session's reader.
- Spotlight follows the ROUTE: `/chat/saturn` → `focus Saturn`, live, toggle "♄Show full chart", last-key `saturn`; `/chat/venus` → `focus Venus` (`shots/spot_chat_saturn.png`).

Screenshots: `dw14/shots/` (merged run), `dw14/shots-pre-merge/` (07 run); raw outputs `dw14/*.out`, `*.pre-merge.out`.

## Teardown
Chrome :9342, Vite :5175, uvicorn :8002 killed; `pg_ctl stop -m fast` → "server stopped"; `dw14/pg`, `dw14/chrome-profile`, pair files deleted. `lsof -iTCP:{9342,5175,8002,54342} -sTCP:LISTEN` → 0 each.

Status: validating PASS (cycles: 1 — the 07 CSS fixes) → docs-sync.
