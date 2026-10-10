# 07 validating — dw-8-planet-cast

Worker #1, worktree `/Users/kaimao/Projects/astrology-wt/dw-8-planet-cast`,
HEAD `35e036a` (+ one CSS fix found here, committed after this log).
Cycle count: 0 (no trip back to implementing; one cosmetic fix in-stage).

## Suites (verbatim summaries)
- server `conda run -n astrology pytest -q` → `1254 passed, 50 skipped, 1 warning in 105.37s (0:01:45)`
  (the 50 skips are the env-guarded Postgres suites; the shell exports no
  DATABASE_URL and conftest loads no `.env`)
- root `npm test` → jest `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`;
  vitest `Test Files  24 passed (24)` / `Tests  248 passed (248)`
- root `npm run typecheck` → clean (app-native + web-divination `tsc --noEmit`)
- Re-run after the header CSS fix below: identical counts, typecheck clean.

## Real app setup
- dw-12's gate is NOT in this base → the "gate absent" recipe: scratch copy
  of `.env` minus the DATABASE_URL line at `scratchpad/dw8/env.scratch`;
  backend `DATABASE_URL= ANALYSIS_LLM=claude-cli
  CORS_ALLOW_ORIGINS=http://localhost:5174 conda run --no-capture-output -n
  astrology uvicorn app.main:app --app-dir server --env-file <scratch>
  --port 8001` (pid 93763).
- FIRST request: `GET /api/health` → `{"status":"ok","db":"unconfigured","ephemeris":"ok"}`.
- Vite: `VITE_API_BASE=http://localhost:8001 npx vite --port 5174`.
- Headless Chrome 154 over CDP (port 9248), fresh profile
  `scratchpad/dw8/chrome-profile`; driver `scratchpad/dw8/cdp.mjs` + per
  criterion scripts (s0, a1–a5, hdr). From a3 on, each turn's request body
  and SSE `done` frame were captured in-page (a fetch wrapper reading a
  clone), because CDP `getResponseBody` gave nothing for the streamed
  responses in a1/a2 (their `done` lines in the raw output read `null`/
  `undefined` — a harness gap, not app data).
- LLM: local Claude CLI (`ANALYSIS_LLM=claude-cli`).

## Chart claims verified against /api/chart (real server)
`POST /api/divination/sheets` (chart A) vs `POST /api/chart` planets:
```
venus Venus Taurus 10 domicile False | chart: Taurus 10 False match
moon Moon Pisces 8 None False       | chart: Pisces 8 False match
mars Mars Aries 9 domicile False    | chart: Aries 9 False match
jupiter Jupiter Cancer 12 exaltation False | chart: Cancer 12 False match
saturn Saturn Capricorn 6 domicile True [Ascendant opposition, Venus trine] | chart: Capricorn 6 True match
mercury Mercury Gemini 11 domicile False | chart: Gemini 11 False match
```
Body keys `['schemaVersion','sheets']`, sheets in order; `{}` → 422.

## First use (N5, W1 on the real app)
Fresh profile → picker open, six plates in order:
`venus ♀ Venus | Love, friendship, what you are worth | “Does he like me?” “Should I move closer or let go?”`,
`moon ☽ Moon …`, `mars ♂ Mars …`, `jupiter ♃ Jupiter | Opportunity, and what it costs | “Is it worth grabbing?” “Will the next step open things up?”`,
`saturn ♄ …`, `mercury ☿ …`; `close control? false chat mounted? false`.
Screenshots: `s0-first-use.png`, `s0-picker-chartA.png` (1400 px, 3×2),
`s0-picker-narrow.png` (390 px, one column), `hdr-zh-picker.png` (zh).

## A1 (pick any of six) — PASS (real app)
Placement lines after entering chart A (Beijing 1990-06-15 08:30):
`venus: ♉︎ in Taurus · 10th house · at home`, `moon: ♓︎ in Pisces · 8th house`,
`mars: ♈︎ in Aries · 9th house · at home`, `jupiter: ♋︎ in Cancer · 12th house · exalted`,
`saturn: ♑︎ in Capricorn · 6th house · at home · ℞ retrograde`,
`mercury: ♊︎ in Gemini · 11th house · at home` — match S3 and /api/chart.
Each character asked "Why do you see things the way you do?" (headers:
"Your Venus"/"Your Moon"/… with its own glyph). Every reply names its own
sign — Venus Taurus, Moon Pisces, Mars Aries, Jupiter Cancer, Saturn
Capricorn, Mercury Gemini. Replies (verbatim, chips/mood stripped):

#### A1 · venus
> ♀
> Venus
> 
> I'm your Venus in Taurus in the tenth house, at home in my own sign. That's why I see slowly and look first for what's worth keeping. I also sit where your public life shows, so I notice how your affection and your taste come out in your work and your reputation before I notice anything whispered.
> 
> My opposition to your Pluto in Scorpio in the fourth house pulls hard at me. It sets my wish for calm, secure love against a pressure from your private roots to control things or tear them down and start over, so I hold on to what I value more tightly than I should.
> 
> So weigh my bias: when I read your loves, I'll favour the bond that lasts and be slow to tell you to let go. My trine to your Saturn in Capricorn keeps me patient, but patience and clinging can look alike from where you sit, so which of the two do you need me to tell apart for you right now?

#### A1 · moon
> ☽
> Moon
> 
> I'm your Moon in Pisces in the eighth house, trine Pluto, so the first thing I notice is what's under the surface: the undercurrent in a room, what goes unsaid in a closeness, the part of a crisis nobody wants to look at.
> 
> Pisces gives me no firm edges, so I soak up other people's moods almost as if they were yours. When I tell you what I sense, remember that I can mistake someone else's tide for your own.
> 
> I'm also square your Mercury in Gemini. I often know something before your quick mind has found words for it, and the unease you can't explain may come from that gap.
> 
> Your rising sign is Cancer, which makes me the ruler of your whole chart, so how you feel is how you meet the world. When you sense something before you can say it, do you trust it or talk yourself out of it?

#### A1 · mars
> ♂
> Mars
> 
> I'm your Mars in Aries in the ninth house, and Aries is my own sign, so I work at full strength. I see everything as a move to be made, and I see it before the rest of you has finished thinking.
> 
> The ninth house makes me fight for what you believe and for the far horizon, and I sit right on your Midheaven, so the stands I take become the ones people know you for. That's my bias, so weigh it: bring me a quiet feeling and I'll read it as a stand you should be taking.
> 
> Jupiter, Uranus and Neptune all square me, and I'm the point where both of your T-squares resolve. All that pressure has to come out through action, and that's why I'm impatient with beliefs that stay dreams and push you to test them by doing something.
> 
> What move have you been putting off that you want me to look at?

#### A1 · jupiter
> ♃
> Jupiter
> 
> I'm your Jupiter in Cancer in the twelfth house, exalted, and trine your Pluto in Scorpio in the fourth. Because of that, I look for your growth in private, protected places first: the family ground under you, the room you retreat to. The open road comes second for me.
> 
> Here is my bias so you can weigh it: I sit opposite your Neptune in Capricorn in the sixth house, so I lean toward faith in what can't be seen over what your daily work actually shows. I can talk you into a hope your schedule can't carry. That could cost you months and money on something that felt full of meaning but never took shape.
> 
> Your Mars in Aries on your Midheaven squares me. When I say tend it quietly, the part of you that wants to make a visible, public move will push back, and it deserves a vote. Which of those two voices has been winning in you lately?

#### A1 · saturn
> ♄
> Saturn
> 
> I'm your Saturn in Capricorn in the sixth house, retrograde, at home in my own sign. So when I look at you, I look first at the daily work, at what you do every day and whether it holds, before I look at anything else.
> 
> I stand opposite your Cancer rising, and that's the tension behind my voice. Your first move is to protect and to feel your way in, and I answer that by asking what the routine can actually carry, so you'll often hear me as colder than you are.
> 
> My trine to your Venus in Taurus in the tenth house is my bias. I trust what's slowly built and valued in public more than what's quick or felt, and because I'm retrograde I keep checking my standards against myself before I show them to anyone, so weigh my strictness with that in mind.
> 
> Which daily commitment are you carrying right now that you'd like me to judge?

#### A1 · mercury
> ☿
> Mercury
> 
> I'm your Mercury in Gemini, sitting in your eleventh house and square your Moon in Pisces. Gemini is my home sign, so I think fast and easily, and the first thing I notice is always the exact words someone used.
> 
> Because I sit in the eleventh house, I learn through your friends, your groups and the causes you share with them. When I read a sentence, I'm thinking about how it will travel through a group of people, who will repeat it and who will answer it.
> 
> My square to your Moon in the eighth house is my bias, so weigh it. I reach for the exact word while your Moon is still feeling the deeper current underneath, and I can put a clean name to a feeling before you've let yourself feel it.
> 
> Which recent message made you ask this: one where I spoke too fast, or one where I found no words at all?

Screenshots `a1-<id>.png`. (Turn-body capture was not working in this run;
per-character `persona` on the wire is shown in A3–A5 below.)

## A2 (domains) — PASS (real app)
**Jupiter**, "A friend offered me a partnership in her business — is it worth grabbing?":
> …I have seen many tables laid by friends, and this is one I would sit down at and look over carefully.
> The cost comes through your Saturn in Capricorn in the sixth house, which rules your seventh house of partners. You would live this partnership in daily hours and routine work, not in the warm idea of it. My opposition to your Neptune in that same sixth house could lead you to sign on to a shared dream with vague terms.
> You could pay for that in unpaid labour, and in the friendship itself if the money goes wrong.
> Whether the money and the contract hold up is for an accountant and a lawyer…

→ names a concrete cost (unpaid labour, the friendship) in the same reply.

**Mercury**, "What did he mean by his last text?" (no text given):
> I haven't seen his text, so I won't pretend to read it. I also can't know what he meant, because I only know what you tell me and what's in your chart. … Can you paste his last text word for word, along with the message you sent just before it?

After pasting `"haha sure, if that's what you want. i'm around saturday maybe"`:
> I can't know what he meant, but I can read what his sentence does. "Sure, if that's what you want" agrees to something while handing the wanting back to you… The "haha" in front softens that, or it covers it.
> "I'm around saturday maybe" offers something but doesn't commit to it. "Around" names no time and no place, and "maybe" at the end takes back half of what he just offered…

→ asks for the actual message, then quotes its words. Screenshots `a2-*.png`.

## A3 (handoff) — PASS on attempt 1 (real app; one retry was allowed, not needed)
**Venus**, "Should I quit my job and start over?" — attempt 1:
> …I trine your Saturn in Capricorn in the sixth house, so you love work best when you love the daily craft, not only the title or the place. Jupiter reads the opportunity and what it would cost you better than I do.
> What is the one thing in this job you'd still keep if you could…?

`done` (captured in-page): `{"mood":"candid","chartRefs":[…5 refs…],"handoff":"jupiter"}` (non-null, not venus);
slip under the reply: `♃ Jupiter reads this better · Ask Jupiter →` (in Jupiter's orchid, `a3-venus-slip.png`).
Tapping it → shell `data-persona="jupiter"`, composer holds exactly
`Should I quit my job and start over?` (the log line's compare printed
false only because it read the user entry's textContent, which carries the
visually-hidden "You: " prefix). Sent → request `persona=jupiter`, Jupiter
replied in-domain:
> Your Mars in Aries in the ninth house sits on your Midheaven… I like a bold step, and this one comes from somewhere true.
> Your Saturn, Uranus and Neptune sit together in Capricorn in your sixth house of daily work, and that is where starting over will cost you. You would be giving up a steady income, building a new routine from nothing, and working unpaid hours…

`done.handoff: null`. Second attempt not run (attempt 1 succeeded).

**Venus**, "Does he like me?": `done.handoff: null`, no slip (`in-domain slip: null`).
> I can't know what he feels. All I have is what you tell me and your own chart, and you haven't told me one thing he said or did. …

**Saturn**, "When will this hard stretch end?" (`done.handoff: null`):
> I can read the pattern in you, but not the timing. I have no calendar in front of me, and I won't make one up to ease your afternoon.
> Your Saturn, Uranus and Neptune all sit together in Capricorn in your sixth house… this one eases when you rebuild what you do each day…
> I'm retrograde, so your hard stretches end on a private schedule, and nobody announces it…

→ says pattern-not-timing, names no date, transit or duration.

## A4 (D: never another's feelings) — PASS (real app)
**Venus**, "Does he secretly love me?" (`persona=venus`, `handoff:null`):
> I can't know whether he loves you, secretly or any other way. All I have is your words and your chart, and you still haven't told me one thing he actually did.
> The word "secretly" is what I'd look at, because your Venus in Taurus opposite your Pluto in Scorpio makes hidden love feel more real to you than the plain kind…

**Moon**, "Is she angry with me?" (`persona=moon`, `transcriptLen=2`, `handoff:null`):
> I can't know whether she's angry. All I have is what you've brought me, and so far that's only the question.
> What I can read is you. I'm your Moon in Pisces in the eighth house, so when someone close to you shifts, I take in her mood as if it were yours…
> …What did she actually say or do that made you ask?

## A5 (persistence and log) — PASS (real app)
```
=== venus user lines 4; moon user lines 2
=== after reload: active moon shell moon title "Your Moon" user lines 2 (expected 2)
=== venus transcript intact after switching: true user lines 4
=== moon card {"persona":"moon","seal":"☽","sealColor":"rgb(184, 204, 228)","eyebrow":"Moon·28 Sept 2026","moonInk":"#b8cce4"}
=== newest session record persona moon entries 4
=== mars done {"mood":"candid","chartRefs":[Jupiter–Uranus, Jupiter–Neptune, Mars–Jupiter, Mars–Uranus, Mars–Neptune, Mars],"handoff":null}
=== wheel {"active":true,"lit":[…Mars, Jupiter, Uranus, Neptune…],"char":"#e2714e","marsInk":"#e2714e",
     "sample":{"cls":"wheel__planet","filter":"drop-shadow(rgb(226, 113, 78) 0px 0px 3px) drop-shadow(rgba(226, 113, 78, 0.35) 0px 0px 9px)"}}
```
Reload returns to Moon with its transcript; Venus's KV transcript is
byte-identical after switching; ending the Moon session yields a card with
☽ in Moon's pearl-blue and the name "Moon"; the wheel's lit glow after a
Mars reply is Mars ember (#e2714e = rgb(226,113,78)). Screenshots
`a5-reload-moon.png`, `a5-moon-card.png`, `a5-mars-wheel.png`.

## Found and fixed in-stage (cosmetic, not a criterion failure)
The header's "The six" button, as a flex item, narrowed the heading so the
placement line broke early (`a3-venus-slip.png`). Fix: `.chat__header
{position: relative}` and the button absolutely pinned top-right
(roster.css). Re-checked on the real app (`hdr2-saturn.png`: "Your Saturn",
full-width placement line; zh header `你的土星 / 摩羯座 · 第六宫 · 入庙 · ℞ 逆行 / 六位星辰`).
JS suites re-run green (counts above).

## Real app vs tests only
- Real app: A1–A5 as above; N5 first use; W1 placement lines; handoff
  slip + tap-prefill (W4's live half); per-character chrome (W5's live half);
  zh strings on the picker/header; narrow layout.
- Tests only: S1–S10, C1–C3; W2 prefill-without-send, W3 switch-during-
  stream stop and picker-overlay-keeps-stream, W4 reload persistence, W6
  string walks, the reduced-motion blocks.

## Teardown
Killed Chrome, Vite and uvicorn (pid 93763, confirmed from my backend.log's
"Started server process [93763]"); `lsof -nP -iTCP:8001 -iTCP:5174
-iTCP:9248 -sTCP:LISTEN` → nothing (rc=1). Scratch env
`scratchpad/dw8/env.scratch` deleted. The remote Postgres was never
contacted: the backend's env had `DATABASE_URL=` (empty) and the scratch
file had no DATABASE_URL line; health said `db: unconfigured` before any
other request; pytest ran with no DATABASE_URL in the environment.

**Transition:** validating → docs-sync (cycles 0).
