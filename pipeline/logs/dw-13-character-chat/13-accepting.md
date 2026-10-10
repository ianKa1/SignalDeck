# dw-13-character-chat — rework acceptance (13-accepting)

Checker: fresh-context acceptance agent, 2026-09-29.
Code under test: primary checkout, branch `fix/dw-13-character-chat`, HEAD `0c792d0` (tree clean before and after).
Criteria: scratchpad `dw-13-rework-criteria.md` (RK1–RK3, RW1–RW3, RG1, RR1).

| ID | Verdict | Evidence |
|----|---------|----------|
| RK1 | PASS | Independent probe (`scratchpad/rk1_probe.py`, fake `llm.generate_sections`, real chart A Venus sheet, temp SQLite): `card4150 calls= 1 lens= (4150, 18) stored= True`; `card40 calls= 1 lens= (39, 18) stored= True`; `greet320 calls= 1 lens= (2999, 320) stored= True`; `taurus-then-clean calls= 2 stored= True retry mentions Taurus: True`; `3x dirty calls= 3 stored= False err= AnalysisUnavailable('character card rejected after every attempt')`; `blank card -> calls= 2 stored= True`; `blank greeting -> calls= 2 stored= True`. Also covered by `test_k1_length_is_a_target_never_a_rejection` (3 params) and `test_k1_three_dirty_attempts_raise_and_store_nothing`. |
| RK2 | PASS | `voice.py` `_problems`: only non-dict, blank card, blank greeting, `astro_terms(card)`, `greeting_terms(...)`; no `len(` check anywhere in acceptance. `CARD_TARGET_MIN/MAX`, `GREETING_TARGET` are unused by `_problems`/`generate_voice`. Retry text observed: `Your previous answer was rejected: the card was empty. Write both fields again from scratch.` — no length. `voice_role.txt`: `card — … aiming for about 2,800 to 3,800 characters (roughly 480 to 650 words)`; `greeting — … short: about 200 characters or fewer.`; `grep -niE "must\|at most"` → no hit. |
| RK3 | PASS | `divination_chat_metrics.py::card_check`: `ok = hits == []` (CARD_MIN/CARD_MAX removed; chars reported only). Unit test `test_divination_chat_metrics.py`: `m.evaluate(_good_run("x" * 100), lambda t: [])["criteria"]["L6"] is True`; a hit still fails L6. Passes in the server suite. |
| RW1 | PASS | `PersonaHeader.tsx`: `<h2 class="chat__title">{fill(dict.chat.title,{name})}</h2>` with `chat.title` = `'{name}'` (en) / `'{name}'` (zh); `persona.title` ("Your {name}"/"你的{name}") deleted from both dictionaries. No placement render in the header (placementText only used by RosterPicker). States: ready → `.persona__greeting` (greeting text), no subtitle, no finding; generating → domain subtitle + `.persona__finding` "{name} is finding a voice…"; failed/none → domain subtitle, no finding. PersonaHeader.test.tsx `expectNoPlacement()` (no `Your `/sign/house/glyph ♈-♓) passes. Live: header innerText `"♃\nJupiter\n\nThere you are. Tell me what’s really going on—not the polished version. …\n\nThe six"`, `placementEl:false`, `subtitle:null`, `finding:null`. |
| RW2 | PASS | `ChatPanel.tsx`: `{persona.status !== 'ready' && (<Letter …><Prose text={who.greeting} …/></Letter>)}` — the ready-branch letter is gone. Greeting is not referenced by ChatPanel's turn/transcript code (`grep voice ChatPanel.tsx` → none); core `PersonaVoice = { greeting }` is only parsed in `persona.ts`. Live: chat panel innerText = header + composer only (`…\n\nThe six\nAsk Jupiter…\nEnter to send …`), no static Jupiter letter. PersonaHeader tests for "greeting never reaching the turn wire" pass. |
| RW3 | PASS | `RosterPicker.tsx:122` `<span className="roster__words">{placementText(sheet, dict)}</span>` unchanged; `RosterPicker.test.tsx` passes (272/272 vitest). |
| RG1 | PASS | `npm test` (root): jest `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`; vitest `Test Files 26 passed (26)` / `Tests 272 passed (272)`; exit 0. `npm run typecheck`: app-native + web-divination `tsc --noEmit`, exit 0. Server: `cd server && DATABASE_URL= conda run -n astrology pytest -q` → `1358 passed, 50 skipped, 1 warning in 149.69s`. `git diff b483a89 -- server/app/divination/bubbles.py server/app/divination/turn.py \| wc -l` → `0`. |
| RR1 | PASS | Backend: `DATABASE_URL= CORS_ALLOW_ORIGINS=http://localhost:5181 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8011`. Process env (`ps eww`): `DATABASE_URL=` (empty), `CORS_ALLOW_ORIGINS=http://localhost:5181`. `/api/health` → `{"status":"ok","db":"unconfigured","ephemeris":"ok"}`. Pre-state `divination_voice`: only moon/en, mars/en (jupiter not cached). POST /api/divination/persona {jupiter, en, 1990-06-15 08:30 Beijing}: `t=5s 202 … t=20s 202, t=25s 200` — no 502; body `voice.greeting` = "There you are. Tell me what’s really going on—not the polished version. I’ve got time, tea, and a little faith in whatever comes next." Stored card length 3,716 chars; no rejection lines in the server log. Vite `VITE_API_BASE=http://localhost:8011 npx vite --port 5181 --strictPort`; headless Chrome 154 over CDP (fresh profile), localStorage seeded as specified (active = `jupiter`, lang `en`), reload: header title `Jupiter`, greeting under it, no placement line, no finding note (screenshot `scratchpad/rr1-header.png`). One live LLM card generated (jupiter/en). |

## Suite totals
- jest (app-native): 90 suites, 1069 tests, all passed
- vitest (web-divination): 26 files, 272 tests, all passed
- typecheck: both workspaces clean
- pytest (server, DATABASE_URL empty): 1358 passed, 50 skipped

## Setup and cleanup
- Ports used: 8011 (uvicorn), 5181 (Vite), 9333 (headless Chrome CDP). User's 8000/5173 untouched (still listening afterwards).
- All three processes killed; `lsof` shows no listener on 8011/5181/9333 afterwards.
- No code edits made; `git status --short` clean. Side effect: one new cached row `jupiter|en` in `server/data/divination.db` (gitignored, content-keyed cache — expected by RR1).
- Probe/driver scripts and screenshots live in the session scratchpad only.

ACCEPTANCE: PASS
