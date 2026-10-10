# dw-13-character-chat — 07 validating (2026-09-29)

Branch feature/dw-13-character-chat @ 3ac23ab. Cycles: 0 (no trip back to implementing).

## Suites
- `cd server && conda run -n astrology pytest -q` → 1361 passed, 50 skipped, 1 warning in 117.37s.
- `npm test` (root) → jest: Tests 1069 passed, 1069 total (plus the pre-existing jest note "A worker process has failed to exit gracefully…"); vitest: 272 passed (272).
- `npm run typecheck` → app-native and web-divination clean.
- `git diff c5b1c7e --stat -- server/tests/test_boundaries.py` → empty: test_handoff_is_never_parsed_from_the_reply and the dw-10 fences are untouched (G1).
- G2 greps: CLAUDE.md rule 9 "persona CHARACTER CARD cache (`divination_voice`, VERSION 2 …)"; rule 10 "reads the cached character card and hands it in" and "a total sentence ceiling per action — chat 12, deeper 20"; the `roster.timing` exclusivity sentence is gone.

## Real app (claude-cli)
Backend: `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5173 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8000` → `/api/health` {"status":"ok","db":"ok","ephemeris":"ok"}. Web: `npm run web` → 200 on :5173. Driven in Chrome (birth data F already saved: 1990-06-15 08:30 Beijing).
- Picker → Moon: header "Your Moon", placement "in Pisces · 8th house", the "finding a voice" note while the card job ran (persona POST: 202 ×8, then 200 — ~40 s on claude-cli).
- Opening letter after the 200: prose = the greeting "hey you. I was just thinking about you. how's tonight treating you? tell me the real version, not the polite one 🌊". `.persona__aside` count 0; no `aside` inside `.chat` (the one page `aside` is the birth sidebar).
- Turn 1 "can't sleep again. everything feels loud lately" → 6 slips, mood tender; pills "Moon in Pisces, 8th house" and transit "Uranus square your Moon · now"; one long slip carries the chart + transit, the rest are short.
- Turn 2 "the inside kind. i moved here 3 months ago and i still cry at random stuff" → 5 slips ("oh, love." / "three months is nothing…" / …); pills "Rising in Cancer", "Pluto in Scorpio, 4th house", transit "Venus trine your Moon · now" (exact on the 1st and the 4th — New York currentTimezone; the lab's Shanghai-zone dates are a day later, consistent). No raw ⟦ in the page. Both turns logged "sentence ceiling reached (12 sentences)".
- Screenshots: /var/folders/k8/krp4szdj4dv1_9s_51qq52z00000gn/T/claude-chrome-screenshots-doWsbQ/screenshot-1790700195728-11.jpg (greeting), …/screenshot-1790700267506-12.jpg (turn 2 with pills).
Servers stopped, tab closed.

## Lab — final run = transcripts/run-03 (metrics.json): L1–L6 all true
L1 6×10 completed, 0 errors. L2 median 19 (≤22), ≤30-word share 0.784 (≥0.70). L3 >40-word share 0.088 (2–20%), in 6/6 conversations. L4 pills per conv venus 9, moon 8, mars 8, jupiter 11, saturn 4, mercury 4 (≥3); transit pills moon 3, saturn 2, jupiter 2 (no waiver — each packet had 5 planet-target episodes); failed tags 1/45 = 0.022 (≤0.10). L5 ?-ending share max 0.2 (≤0.60); 0 self-intro matches. L6 six cards 3,451–3,726 chars, 0 astro_terms hits; transcripts/baseline/ exists beside run-03.
Baseline → final: median 43 → 19; ≤30 share 0.227 → 0.784; >40 share 0.605 → 0.088; ?-ending 0.8–1.0 → 0.0–0.2; self-intros "I'm your <planet>" in 6/6 → 0; pills 161 → 44 (fewer, all still checked).

## L7 — the loop's judgement (Moon, run-03, turns 5–7 quoted verbatim, pills as labels)

**You:** reggie. he's reggie. ok but what's the hard part then
> reggie. perfect. he sounds like he's worn a cardigan since 1974
> hi reggie
> okay, the hard part
> gary and reggie make noise because that's what they do. your head is different. when a head won't quiet down at 3am, it's usually because it's holding onto something and it's scared to put it down before morning
> you've got Moon square Mercury. the part of you that feels things and the part that puts them into words don't always move at the same speed. sometimes the feeling is already here, and your mind keeps circling it, trying to find the right words so it can file it away
> so the hard part isn't making it stop

**You:** then what is it. i've been circling since i moved honestly. mom called again tonight and i cried after hanging up
> oh
> there it is
> that's the hard part. it's not the noise. you've been carrying something since the move, and tonight it spilled over
> you don't have to make it stop. you let it be as big as it actually is, without turning it into something to fix before morning
> your mind keeps circling because it's looking for words. maybe the feeling doesn't need words yet. maybe it just needs someone to sit with it for a bit
> that crying after the call wasn't you falling apart. it sounds more like water that had been sitting too long finally moving, the way it does in reggie's pipes

**You:** maybe. i don't even know what i'm sad about. she just asked if i'm eating and i lost it
> mm
> sometimes the smallest question lands the hardest
> "are you eating" isn't really about food, is it. it's the kind of thing someone asks when they can't reach over and make you a plate themselves
> and you're in a new flat, with gary and reggie, and she's far from your kitchen
> i can't know what she was feeling when she asked. but i wonder whether some part of you heard someone still keeping track of you, and it made you notice how long you've been doing it all alone
> you've got Ascendant in Cancer. home and being looked after sit right at your front door. a move doesn't only change your address. it takes away all the little ways you were held
> you don't have to know what the sadness is called yet.

Judgement: PASS. This reads like texting a friend who knows your chart. The messages are short ("oh" / "there it is" / "mm"), with one longer message per turn carrying the chart reading. The personality is distinct: quiet, playful with the named radiator, tender without flattery. The phenomena are real and checked (Moon square Mercury, Ascendant in Cancer; earlier Moon in Pisces, Uranus square Moon with the packet's dates, Moon sextile Uranus, Jupiter in Cancer house 12). No stock ban shows: no forced closing question (a question comes when it's wanted, "what did she used to leave?"), comfort is plain comfort, and there is no placement self-introduction. Ground rule 1 shows naturally ("i can't know what she was feeling"). Two limitations are recorded honestly:
(1) The model's turns run long. On 57/60 lab turns (and both real-app turns) the 12-sentence ceiling cut the tail; the cut lands on a sentence end, so what arrives reads complete. Occasionally it leaves a hook, as in turn 5's "so the hard part isn't making it stop", which the user picked up. Prompt tuning did not fix it (run-02 and run-04 rejected, 06-implementing.md).
(2) The character sometimes offers what it cannot do (run-01 moon: "i'll send [a playlist] tomorrow"), and the real-app greeting used an emoji; neither is banned by the rulings.

Status: validating → docs-sync.
