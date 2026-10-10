# 09 validating — dw-5-astro-dice

Worker #2, worktree `/Users/kaimao/Projects/astrology-wt/dw-5-astro-dice`,
HEAD `ed66b62`. Cycle 0 (no trip back to implementing).

## Suites (final run, after the real-app session)

- server `conda run -n astrology pytest -q` → `1088 passed, 50 skipped, 1 warning in 105.06s (0:01:45)`
- root `npm test` → app-native `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`;
  web-divination `Test Files 14 passed (14)` / `Tests 100 passed (100)`
- root `npm run typecheck` → 0 errors (both workspaces)
- `grep -rn "Math.random" web-divination/src` → no output
- D10/C3 footprint: `git diff feature/divination_web...HEAD -- server/app/main.py server/tests/test_boundaries.py` → empty (0 lines);
  `git diff --stat feature/divination_web...HEAD` lists 23 files, none under
  `app-native/`, not `web-divination/src/app/App.tsx`, not `theme/tokens.ts`
  (CLAUDE.md, core chart/index + divination ×4, server divination ×5 + models
  + 2 tests, web chat ×8, i18n ×2).

D1–D11 (server, fakes + real fixture chart), C1–C3 (core), W1–W6 (web) are
covered by the tests listed in `08-implementing.md` and pass above. TESTS ONLY:
all D*, C*, W* criteria.

## Real app (A1–A8)

Backend `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5175 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8002`
(`/api/health` → `{"status":"ok","db":"ok","ephemeris":"ok"}`); web
`cd web-divination && VITE_API_BASE=http://localhost:8002 npx vite --port 5175`.
Driven through claude-in-chrome in my own tab (1503514341), plus one headless
Chrome run (fresh profile, CDP on :9335) for A1's timing. Fixture birth
seeded as `astrology.birthData.v1.traveler` = 1990-06-15 08:30 Beijing
(Asia/Shanghai) — the wheel and the Placements panel rendered from it
(Sun Gemini H11, Moon Pisces H8, Mercury Gemini H11, Venus Taurus H10, Mars
Aries H9, Jupiter Cancer H12, Saturn/Uranus/Neptune Capricorn H6, Pluto
Scorpio H4, Asc 28°05′ Cancer, MC 12°57′ Aries). Request bodies and raw SSE
were captured by a page-side `fetch` tee (the network tool shows no bodies).

**Environment note.** The shared Chrome reported `document.visibilityState ===
"hidden"` for my tab throughout (other workers share the window), so Chrome
throttled page timers. In that tab the card settled at ~3,049 ms, which says
nothing about the app. Timing was therefore measured on a visible headless
page (below).

- **A1 — PASS (real app).** Body of the first cast:
  `{"persona":"venus","transcript":[],"message":"Should I tell her how I feel?","lang":"en","birthData":{…1990-06-15 08:30 Beijing…},"action":"cast"}`.
  The rolling card (`[data-rolling]`) was in the log 49 ms after the fetch
  resolved, with no prose (`proseWhenCardSeen:false`); the first prose came at
  10,050 ms. Headless visible page (`vis:"visible"`): card at 10 ms, the three
  dice settled at 712 / 912 / 1,112 ms (`settledAt:1112`), first prose at
  9,421 ms, reply finished (`moodShown:true`), faces `Saturn, Cancer, 5th
  house`. Screenshot of the settled card (en):
  `/var/folders/k8/krp4szdj4dv1_9s_51qq52z00000gn/T/claude-chrome-screenshots-doWsbQ/screenshot-1790638231509-5.png`.
- **A2 — PASS (real app).** The raw SSE began
  `event: dice\ndata: {"planet": "Mercury", "sign": "Capricorn", "house": 1}\n\n: keepalive …`
  (dice first, before every keepalive and delta); the card's aria-label read
  `The dice: Mercury, Capricorn, 1st house`, with faces ☿ ♑︎ 1.
- **A3 — PASS (real app).** Reply 1 names "Mercury, Capricorn, the first
  house" in its first sentence and answers the question ("So yes, tell her …
  face to face"). Chart claims against the Placements panel: "your own
  Mercury sits in Gemini in your eleventh house" = Mercury ♊ Gemini H11 ✔;
  "Your Moon in Pisces in the eighth house" = Moon ♓ Pisces H8 ✔; "Your Venus
  in Taurus, at home in its own sign" = Venus ♉ Taurus H10 (domicile) ✔.
  `done.chartRefs` = Mercury, Moon, Venus, and each is spoken of as the user's
  OWN placement. Cast 2 (Mercury · Aries · 10, "Will she say yes if I ask her
  out?") is the die-only check: the reply names Mercury only as a die, and
  its chips are Mars ("Your own Mars sits in Aries, in its own sign" = Mars
  Aries H9 ✔) and Venus ("Your Venus in Taurus lives in the tenth house" ✔),
  with NO Mercury chip. No invented placement appeared in any reply.
- **A4 — PASS (real app).** Four casts gave Mercury/Capricorn/1,
  Mercury/Aries/10, Mercury/Capricorn/7 and Venus/Libra/3, so the rolls were
  not all identical. Cast 3's claims: Sun and Mercury in Gemini H11 ✔;
  Saturn, Uranus and Neptune in Capricorn ✔ (chips Sun, Mercury, Saturn,
  Uranus, Neptune, all own). Cast 4's claims: Venus Taurus H10 ✔; "Libra sits on the
  cusp of your fourth house", where IC = MC 12°57′ Aries + 180° = Libra ✔ (on
  the wheel; the panel lists no IC). After a reload, 4 cards all had
  `data-rolling` count 0 and `.dice__die--tumbling` count 0, their labels
  were identical to the stored dice, and there were 4 `· cast` marks.
- **A5 — PASS (real app).** The follow-up was a chat (Send), "What did the
  planet die mean for me?". Its body had `action:"chat"`, 4 persona wire
  entries carried `dice`, the last one being
  `{"role":"persona","text":…,"dice":{"planet":"Venus","sign":"Libra","house":3}}`,
  and the user wire entries carried only `role,text` (no `cast`). The reply
  named the earlier planet faces correctly: "Three of your four casts showed
  Mercury… The last cast… showed Venus". Its chips were Mercury ("Your own
  Mercury is in Gemini in your eleventh house" ✔) and Venus ("Your Venus in
  Taurus in the tenth house" ✔), both OWN.
- **A6 — PASS (real app).** In 中 the button read `掷星骰` and the body had
  `lang:"zh"` and `action:"cast"`. The card read `星骰落定 ♄ 土星 ♑︎ 摩羯座 6 第六宫`
  with aria `星骰：土星、摩羯座、第六宫`, and the reading was in Chinese. Its
  claims: 土星在摩羯座第六宫 ✔ (Saturn Capricorn H6), 天王星和海王星也在那里 ✔,
  第七宫宫头是摩羯座 (DC = 28°05′ Capricorn) ✔. Chips: Saturn, Uranus,
  Neptune. Screenshot:
  `/var/folders/k8/krp4szdj4dv1_9s_51qq52z00000gn/T/claude-chrome-screenshots-doWsbQ/screenshot-1790638448591-7.jpg`.
- **A7 — PASS (real app).** With the birth data cleared (store key removed,
  reload), the body had `birthData:null` and `action:"cast"`. The stream was
  `dice {Mercury, Cancer, 8}` then `done {"mood":"candid","chartRefs":[]}`.
  The card showed 水星、巨蟹座、第八宫. The reading (zh) reads the three faces
  against the question and names no natal placement.
- **A8 — PASS with a stated substitution (real app + tests).**
  claude-in-chrome has no DevTools emulation panel, so reduced motion was
  forced with a page-side `window.matchMedia` override that answers
  `(prefers-reduced-motion: reduce)` → true. That is the exact API DiceCard
  reads. On the A7 cast a MutationObserver saw NO `[data-rolling]` and NO
  `.dice__die--tumbling` at any time. A CSSOM read confirmed that the served
  sheet carries
  `@media (prefers-reduced-motion: reduce) { .dice__die--tumbling .dice__face, .dice__die--landed .dice__face { animation: … none; } }`.
  W4 (DiceCard.test.tsx and ChatPanel.test.tsx) pins the same behaviour.

## Teardown

My tab 1503514341 is closed. uvicorn PID 12879 and vite PID 12867 were
killed; the headless Chrome was killed by its script. `lsof -iTCP:8002` and
`lsof -iTCP:5175` both show nothing. I stopped nothing I did not start.

Transition: validating → docs-sync (cycles: 0).
