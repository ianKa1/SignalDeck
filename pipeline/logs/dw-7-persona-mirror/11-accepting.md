# 11 accepting — fresh-context acceptance check

Worktree `/Users/kaimao/Projects/astrology-wt/dw-7-persona-mirror` @ `aca2c5b` (branch feature/dw-7-persona-mirror, base feature/divination_web). Checker saw only the criteria file; no source edits kept.

Suites (run by the checker):
- `pytest -q` in server/, run with `DATABASE_URL=` so no Postgres is used: **1170 passed, 50 skipped**, exit 0 (140 s).
- `npm test`: app-native **1069/1069**, web-divination vitest **21 files / 181 tests**, exit 0. Jest printed its usual "worker failed to exit gracefully" warning, but nothing failed.
- `npm run typecheck`: exit 0, 0 TS errors.

Real app: uvicorn on :8001, run with `DATABASE_URL=` and `ANALYSIS_LLM=claude-cli`, using a scratch .env copy that had the DATABASE_URL line removed. `/api/health` returned `{"status":"ok","db":"unconfigured","ephemeris":"ok"}` before any other request. Vite ran on :5174 with `VITE_API_BASE=http://localhost:8001`, driven through headless Chrome over CDP with a fresh profile and a CDP Network logger. Birth data was entered through the form: Beijing, China for chart A and New York City, United States for chart B. The picker supplies GeoNames coordinates (39.9075/116.3972 and 40.7143/-74.006), and both produce the pinned sheets. I moved the pre-existing `server/data/divination.db`, which already held 3 maker voice rows, aside so the voice would genuinely miss, then restored it byte-for-byte after the run.

| ID | Verdict | Evidence | Kind |
|---|---|---|---|
| P1 | PASS | `test_p1_sheet_a` first asserts that Venus is (Taurus, 10, direct), then checks the facts against FACTS_A: domicile, assured, and aspects Jupiter sextile ally / Pluto opposition conflict / Neptune trine ally / Saturn trine ally / Moon sextile ally, in that order. It asserts Chiron is absent, and also that Chiron IS a chart aspect, which proves the filter is doing the work. The real-app 202 body carried exactly these facts. | TESTS + REAL APP |
| P2 | PASS | `test_p2_sheet_b` checks (Scorpio, 2, retrograde) and the facts: detriment, uneasy, retrograde true, and Mercury conjunction fused / Jupiter trine ally / Moon opposition conflict. It asserts the Midheaven is absent and loops over all six fields to confirm each differs from A. The real-app 200 for chart B carried the same sheet. | TESTS + REAL APP |
| P3 | PASS | `test_p3_pure_and_generic` checks that two equal calls give equal sheets, that Mars gives `planet:"Mars"`, that Chiron raises ValueError, that `time:None` gives house None and no Ascendant aspect, and that `sheet_facts` has no `meanings` key. | TESTS |
| P4 | PASS | `test_p4_key_reads_facts_version_not_fingerprint`: the key is 64-char lowercase hex and stable. It changes with lang, persona, planet and each fact field, and with a monkeypatched VERSION. It stays the same with a monkeypatched FINGERPRINT and when `meanings` differ. | TESTS |
| P5 | PASS | `test_p5_miss_then_hit`: the first POST answers 200 with exactly {schemaVersion, persona, lang, sheet, voice}, the voice holds exactly {intro, bias}, the sheet equals FACTS_A, and the fake is called once. The second POST returns an equal 200 and the fake is still at 1 call. | TESTS |
| P6 | PASS | `test_p6_threaded_202_one_job_then_200`: JOBS_SYNC is removed and a blocking fake is used. The first POST answers 202 `{status:"generating", sheet:FACTS_A}`. The second answers 202 with the same job key, is deduped, and the fake is called once. After release the POST answers 200. | TESTS |
| P7 | PASS | `test_p7_route_bad_output_is_a_502_and_no_row`: a blank intro and a style without "Taurus" each give 502 `{"detail":"persona voice unavailable"}` with no cached row. `test_p7_route_serves_the_cut_bias`: a 400-char bias comes back as `"B"*200`. | TESTS |
| P8 | PASS | `test_p8_route_422_calls_no_fake`: no birthData, `mars`, `fr` and date `1990-13-40` each give 422 with 0 fake calls. `test_p8_no_provider_is_503_but_a_stored_hit_is_served`: 503, with `scheduler.status(divination_voice:…)` None and 0 calls, and a stored voice is then served 200. | TESTS |
| P9 | PASS | `test_p9_prompt_and_schema[en,zh]`: the system prompt starts with `voice_role.txt` and ends with the lang line, the user text parses to the sheet including `meanings`, the schema `is VOICE_SCHEMA`, and required = {intro, bias, style}. | TESTS |
| P10 | PASS | The tests cover all four parts. Order is persona base < self.read < self.marker+sheet JSON (containing "Taurus"/"domicile") < chart.read, with no self.voice and no `divination_voice:` enqueue. After a stored voice, `self.voice` is followed by its style. The chartless prompt equals the golden and has no `self.` fragment. `self.read` carries the key phrases. **I verified the goldens independently** by extracting `git archive b308a92 server/app` and running b308a92's `render.system_prompt("venus", lang)`: both en and zh are byte-equal to `tests/fixtures/divination_chartless_{en,zh}.txt`. | TESTS + independent golden check |
| P11 | PASS | The tests check that the SQLite columns equal VOICE_COLUMNS, that doctrine equals FINGERPRINT, that 012 sorts last with the same columns, and that the fake Postgres path emits `INSERT INTO divination_voice … ON CONFLICT (voice_key)`. `server/data/divination.db` had mtime 1790647518 and size 20480 both before and after the full pytest run, so it was untouched. | TESTS + file stat |
| P12 | PASS | `test_boundaries.py` has 25 tests passing. I planted each check for real and reverted it with `git checkout`. (1) `from .voice import cached_voice` in turn.py fails `test_streamed_turn_never_imports_summary_or_store`. (2) `from app.llm import generate_sections` in persona.py fails `test_persona_sheet_is_pure`. (3) `persona_voice.generate_voice(` in main.py fails `test_delivery_never_generates_on_the_request_path`. (4) An `email TEXT` column in the store's voice CREATE TABLE, and separately `"email"` in the VOICE_COLUMNS tuple, each fail `test_divination_store_is_two_identity_free_tables`. `test_main_names_the_synchronous_exceptions` is unchanged in the diff and passes. The dw-2/3/5/6 changes are mechanical: render gains 3 new prompt names, and summary's "011 sorts last" became "011 has the same columns". | TESTS + planted edits |
| C1 | PASS | `core-persona.test.ts`: the 202(sheet)/202/200 sequence makes 3 identical POSTs exactly POLL_INTERVAL_MS apart, calls onSheet once with the sheet, and resolves to the 200 body. A 502, a 503, a rejected fetch, house 13, and MAX_POLLS+1 × 202 each resolve to null. | TESTS |
| W1 | PASS | Vitest W1 passes. Real app, before any birth data: the title was "Venus", the subtitle "Love, friendship, what you are worth", the static "Sit with me a while…" greeting was shown, and no persona POST appeared in the network log. | TESTS + REAL APP |
| W2 | PASS | Vitest W2 passes: glyph `SIGN_GLYPHS.Taurus`, "in Taurus · 10th house · at home" with no ℞, the finding note, then intro + `.persona__aside` bias replacing the greeting. The real app showed the same (see A1). | TESTS + REAL APP |
| W3 | PASS | Vitest W3 passes. Real app chart B: "♏︎ in Scorpio · 2nd house · in exile · ℞ retrograde". | TESTS + REAL APP |
| W4 | PASS | Vitest W4 passes: 中 re-POSTs with `lang:"zh"` and shows 天蝎座 · 第二宫 · 落陷 · ℞ 逆行, and new birth data aborts the old poll. In the real app, clicking 中 re-POSTed with `"lang":"zh"` (see A5). | TESTS + REAL APP |
| W5 | PASS | Vitest W5 passes: the turn body keys are exactly {action, birthData, lang, message, persona, transcript} with no intro or bias, and the transcript's first entry is the user line. In the real app the stored session transcript sent to /summary also began with `{"role":"user",…}`. | TESTS (+ real-app corroboration) |
| W6 | PASS | The i18n parity test passes. `persona.css` has `@media (prefers-reduced-motion: reduce) { .persona__finding { animation: none; … } }`. The colour, barrel, network and arithmetic guards pass. `git diff b308a92 -- web-divination/src/chat/chat.css web-divination/src/chat/useChat.ts web-divination/src/theme` is empty. | TESTS/CODE |
| A1 | PASS | After chart A was entered, the UI showed "Your Venus", "♉︎ in Taurus · 10th house · at home" and "finding her voice…". Network log: `POST /api/divination/persona` → 202 (02:20:22), 202 (02:20:27), 200 (02:20:32), about 10 s against a 120 × 5 s budget. The letter then showed intro *"I'm your Venus, in Taurus, in your 10th house. I love what lasts, and I'd like you to be known for the things you truly value."* and bias aside *"As your Venus in Taurus, I hold tight to what I already love, and with Pluto opposite I can mistake gripping for loyalty, so weigh that."* | REAL APP |
| A2 | PASS | Q: "Why do you talk the way you do?" A (excerpt): *"Because I'm at home where I sit. I'm your Venus in Taurus in the tenth house, in my own sign, so I don't hurry … My trines to your Saturn and Neptune give me patience … I'm opposite your Pluto, and that pull makes me want to hold on to what I love…"* The reply names Taurus, the 10th house and P1 aspects. | REAL APP |
| A3 | PASS (see note on b) | The transcripts are below, verbatim. (a) B's intro ("in Scorpio"), bias ("As your Venus in Scorpio") and second answer ("I'm your Venus in Scorpio in the second house, and I'm retrograde … Being retrograde…") all name Scorpio, and the second answer names B-only factors: retrograde, the Moon opposition, and the Jupiter trine. (b) A's second answer names Taurus, the 10th house and the Pluto opposition, and names no chart-B fact. **Note:** it does contain the word "Scorpio", in "your Pluto in Scorpio in the fourth". I checked with natal_report that this is a TRUE chart-A placement (Pluto Scorpio, house 4), not leakage from chart B. I graded (b) on its evident intent, which is that no chart-B Scorpio-Venus fact appears. A strictly literal reading of "no Scorpio fact" would fail it. (c) The two first answers differ, compared side by side below. (d) Neither reply claims to know his feelings. A says *"he may not be able to see what you're carrying"* and *"very often the other side was waiting too"*, which is general. B says *"don't try to guess his answer first."* | REAL APP |
| A4 | PASS | After a reload with chart B, the server log shows exactly one `POST /api/divination/persona` → **200** and no 202, and the voice was shown at once. A second POST appeared in the browser log, which is a StrictMode dev double-mount aborted before it reached the server; uvicorn logged one request. `sqlite3 … '.schema divination_voice'` shows `voice_key TEXT PRIMARY KEY, voice, persona, lang, model, prompt_version INTEGER, created_at, doctrine`, which are the pinned 8 columns only. There are 3 rows for the 3 (placement, lang) pairs seen: A/en, B/en, A/zh, all model `claude-cli/opus`, prompt_version 1, with a 16-char doctrine. | REAL APP |
| A5 | PASS | Switching to 中 with chart A showed the title 你的金星 and the placement line "♉︎ 金牛座 · 第十宫 · 入庙". The persona POST ran 202 → 202 → 200 with `lang:"zh"`. Intro: *"我是你的金星，落在金牛座，在你的第十宫。我喜欢慢慢把值得的东西，经营成别人看得见的样子。"* Bias: *"作为你金牛座的金星，我先看一样东西值不值得长久守着，一旦认定就容易抓得太紧，冥王星一拉扯更不肯放手，这点你要自己掂量。"* | REAL APP |

## A3 transcripts (verbatim)

**Chart A** (1990-06-15 08:30 Beijing). The session was started fresh after End, and the header read "in Taurus · 10th house · at home".

> Q: Should I tell him how I feel?
>
> A: Probably yes, but let me tell you what I notice first. I'm your Venus in Taurus, at home in my own sign, so when you care about someone you care steadily and for a long time. The part to watch is my opposition to Pluto. You can hold a feeling so tightly and so privately that it gets heavier than anything he has actually said or done. Feelings kept in the dark too long usually turn into waiting. Your Moon in Pisces in the eighth house also takes in a great deal and shows very little, so he may not be able to see what you're carrying.
>
> So tell him, but keep it plain and small. Say what you feel, not what you need him to do about it. That gives him room to answer honestly, and it lets you keep your own ground whatever he says. I have watched a great many people wait for a sign from the other side, and very often the other side was waiting too. So what has he given you so far, in words or in actions?
>
> (chips: Venus · Venus–Pluto · Moon; mood candid)

> Q: Why do you see it that way?
>
> A: Because of where I stand in you. I'm your Venus in Taurus in the tenth house, opposite your Pluto in Scorpio in the fourth. Taurus is my own sign, so I trust what is steady, spoken and built to last. The tenth house is the part of your chart that lives in plain view, so I like love that is said out loud rather than kept as a private weather system. Across from me sits Pluto, deep in your most private rooms, and it wants to hold the feeling close, guard it and make it bigger in the dark. That pull is what I notice first, because I feel it tugging on me.
>
> I also lean one way, so weigh this. I would take a clear answer, even a disappointing one, over a lovely uncertainty that goes on for months. Taurus hates waiting on unfinished ground. If there's something delicate here that you haven't told me, like a friendship at stake or someone else involved, then my urge for solid footing may be pushing you too hard. Which of those two pulls feels more like yours right now?
>
> (chips: Venus · Venus–Pluto · Pluto; mood candid)

**Chart B** (1986-10-20 06:15 New York). The session was ended, then birth data was edited. Header: "♏︎ in Scorpio · 2nd house · in exile · ℞ retrograde". Intro: *"I'm your Venus, in Scorpio, in your 2nd house. I love deeply, guard what's mine closely, and take my time deciding what's truly worth keeping."* Bias: *"As your Venus in Scorpio, I test whether love and worth are safe before I trust them, and I keep circling back to old doubts, so weigh that."*

> Q: Should I tell him how I feel?
>
> A: Probably, yes. But I'm your Venus in Scorpio, in the second house, moving retrograde, so let me own my bias first. I hold a feeling in the dark for a long time and turn it over until it feels safe to show. That habit protects you. It also keeps you waiting for a guarantee that nobody can give you.
>
> Your Moon in Taurus sits opposite me, and that's where the real pull is. One part of you wants to feel safe before you speak. The other wants to hold on to what you already have, even if all you have is the possibility of him. I sit right beside your Mercury, so you can put this into words better than you fear. Say it plainly and don't try to guess his answer first. Whatever he says back, your worth stays with you. It isn't something you're handing over.
>
> Before you do, tell me one thing: what are you most afraid of losing if you say it out loud?
>
> (chips: Venus · Moon · Moon–Venus · Mercury · Mercury–Venus; mood candid)

> Q: Why do you see it that way?
>
> A: Because of where I sit. I'm your Venus in Scorpio in the second house, and I'm retrograde. Scorpio makes me look first for what's hidden: who holds the power, and what could be lost. The second house ties love to your sense of your own worth, so to me confessing feels like putting something valuable on the table. Being retrograde, I tend to go back over old hurts before I trust a new feeling. So weigh my caution with that in mind. I'm guarded by nature, and I'm not always right about the danger.
>
> The opposition to your Moon in Taurus is the part I'm surest of. That's where your need to feel safe pulls against your wish to keep hold of him. And since your rising sign is Libra, I also rule your chart, so my hesitation tends to become yours.
>
> What makes me hopeful is my trine to your Jupiter. It means your worth can grow even when an answer doesn't go your way. I've watched a great many lovers wait for the water to go still first. It never does.
>
> (chips: Venus · Moon–Venus · Moon · Venus–Jupiter; mood candid)

### (c) First answers side by side

| | Chart A (Taurus, 10th, domicile) | Chart B (Scorpio, 2nd, detriment, ℞) |
|---|---|---|
| Danger it names | *"You can hold a feeling so tightly and so privately that it gets heavier than anything he has actually said or done"* (Pluto opposition: over-gripping) | *"keeps you waiting for a guarantee that nobody can give you"* (Scorpio/℞: needing safety first) |
| Advice | *"tell him, but keep it plain and small. Say what you feel, not what you need him to do about it"* | *"Say it plainly and don't try to guess his answer first. Whatever he says back, your worth stays with you"* (2nd-house worth) |
| Closing question | *"what has he given you so far, in words or in actions?"* (evidence outside) | *"what are you most afraid of losing if you say it out loud?"* (fear of loss inside) |

Both open with "Probably yes". The emphasis differs: A is about holding too tightly and keeping the feeling small and unburdened, while B is about waiting for a guarantee, fear of loss, and self-worth. That meets (c).

## Hygiene
- The remote Postgres was never contacted. Every server process ran with `DATABASE_URL=` and the scratch env copy had no DATABASE_URL line; health reported `db: unconfigured`; pytest also ran with `DATABASE_URL=`.
- All planted edits were reverted, and `git status --short` in the worktree is clean.
- `server/data/divination.db` was restored from the pre-run copy. The real-app DB is kept as scratch `accept-dw7/divination.db.accept`.
- uvicorn :8001, vite :5174, headless Chrome :9337 and the CDP logger were all stopped. lsof shows 8001/5174 free. The scratch env copy was deleted.

ACCEPTANCE: PASS
