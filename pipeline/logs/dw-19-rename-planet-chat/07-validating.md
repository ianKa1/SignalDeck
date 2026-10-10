# 07 — validating (2026-09-29, worker, worktree @ cbd1fa2)

Suites (from step 5, code unchanged since): server 1495 passed / 50 skipped (pre-existing DATABASE_URL/LLM-live skips;
0 planet_chat skips; TEST_WEB_DATABASE_URL/TEST_DATABASE_URL → 127.0.0.1:54316 dw19_web/dw19_main); npm test jest 1080/1080,
vitest 445/445; typecheck clean.

## R1 — PASS (real app, on a COPY of astrace_dev)
Setup:
- Dev cluster :54320 before: astrace_dev at 012_divination_voice, divination_summary 4 rows, divination_voice 9 rows;
  astrace_web 7 users. `createdb -T astrace_dev astrace_dev_dw19` (first try). Precomputed with the worktree code:
  voice_key for the Beijing 1990-06-15 08:30 birth data → venus/en 5c11b662dacc… (plus moon en/zh, saturn/en,
  jupiter/en) ARE rows of the copy — i.e. cached before my backend started, under the pre-rename key.
- Test user minted in astrace_web with accounts/web/service._mint (scratchpad dw19_mint.py):
  dw19+837bcc2d@example.com (id 602958db-…).
- :8001 from the worktree: DATABASE_URL=…54320/astrace_dev_dw19, WEB_DATABASE_URL=…54320/astrace_web,
  CORS_ALLOW_ORIGINS=http://localhost:5174, ANALYSIS_LLM=claude-cli (normal shell env; confirmed with `ps eww`).
  /api/health → {"status":"ok","db":"ok","webDb":"ok","ephemeris":"ok"}. Startup applied 013: copy at
  013_planet_chat_rename, planet_chat_summary 4 / planet_chat_voice 9, constraints all `planet_chat_*` (pkey + the PG18
  NOT NULLs). astrace_dev itself untouched (still 012, 4/9).
- Vite :5174 (VITE_API_BASE=http://localhost:8001); headless Chrome CDP 9324, profile scratchpad/dw19-chrome;
  driver scratchpad/dw19-drive.mjs; output scratchpad/dw19-r1.out.
- Browser seeded with ONLY pre-rename keys: astrology.divination.sessions.v1 (an open Venus header + a sealed, ready Moon
  record), astrology.divination.transcript.v1.venus (2 entries), astrology.divination.active.v1 = venus, the birth data,
  and the minted pair in astrace.auth.{access,refresh,expiresAt}; no owner key.
Results (verbatim from the driver):
```
import body: This browser holds 2 conversations and a birth chart from before you signed in to dw19+837bcc2d@example.com.
keys after boot: [...,"astrology.planet_chat.active.v1","astrology.planet_chat.sessions.v1","astrology.planet_chat.transcript.v1.venus",...]  (no astrology.divination.*)
Import → PUT /api/web/profile 204, PUT /api/web/sessions/dw19-open-venus 204, PUT /api/web/sessions/dw19-sealed-moon 204
sessions list text: ♀ Venus·begun 27 Sept 2026 Before the rename: does he still think of me? In progress ☽ Moon·26 Sept 2026 “Why do Sundays feel so heavy?” Tone: wistful A quiet ache, named gently.
chat text has old entries: true
POST /api/planet_chat/persona 200   (server log: exactly ONE persona request, 200; the client-side 0/null row is React StrictMode's aborted duplicate that never reached the server)
ok (10.6s): reply streamed and saved — POST /api/planet_chat/turn 200; venus transcript length (new key): 4
End session → summary 202, 202, 200 → seal-card--ready “Does he still think of me, and are you still the same after the change?”
any /api/divination request: false
```
- Cached card hit: planet_chat_voice stayed 9 rows; no voice job in the backend log (the only job line is
  `job planet_chat_summary: running …`); planet_chat_summary 4 → 5 (the new session's summary).
- Screenshots: scratchpad/dw19-r1-{import,sessions,venus-old,reply,summary}.png.

Teardown: Chrome, Vite and the :8001 backend stopped (a stray uvicorn child on 8001 killed by pid); ports 8001/5174/9324
free; the user's :8000 (pid 6038) and :5173 (pid 6029) untouched. Test user deleted (DELETE 1; its web_sessions and tokens
cascaded to 0); astrace_web back to 7 users. astrace_dev_dw19 dropped after recording. Clusters left running; throwaway
dbs dw19_web/dw19_main left on :54316 for acceptance.

LANDING NOTE (for the coordinator/user): once this lands and the user's :8000 backend restarts on the new code, migration
013 renames astrace_dev's tables; the still-running OLD backend would miss its caches (and fail the summary/voice store
writes) until restarted — restart it right after landing. The browser's old keys migrate on first load.

Status: validating → docs-sync.
