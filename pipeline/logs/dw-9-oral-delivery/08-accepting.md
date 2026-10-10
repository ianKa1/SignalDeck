# 08 accepting — fresh-context acceptance check

Checker: fresh context; no source edits; one temporary planted edit (T7), reverted.
Code under test: worktree `astrology-wt/dw-9-oral-delivery`, HEAD `8881478` (dw-9 plus the merged dw-7).
dw-9's own changes were judged with `git diff feature/divination_web...HEAD`, which touches 28 files and includes neither `main.py` nor `llm.py`.
The real app ran on uvicorn :8002 with `ANALYSIS_LLM=claude-cli` and `DATABASE_URL=` (empty) from a scratch `.env` copy that had no DATABASE_URL line. `/api/health` returned `{"db":"unconfigured"}` before any other request.
Vite ran on :5175 with `VITE_API_BASE=http://localhost:8002`. The browser was headless Chrome 154 driven over CDP with a fresh profile.
SSE was captured by a fetch tee injected into the page (content-type `text/event-stream; charset=utf-8`). DOM slip and ghost timing was captured with a MutationObserver.
Chart A (1990-06-15 08:30, Beijing, Asia/Shanghai) was entered through the form. The chart was checked against `POST /api/chart`:
- Sun Gem 23°38′ H11, Moon Pis 8°27′ H8, Mer Gem H11, Venus Tau 18°10′ H10, Mars Ari 10°40′ H9, Jup Cnc H12, Sat Cap 24°04′ H6 R, Ura Cap H6, Nep Cap H6, Plu Sco H4.
- ASC Cnc 28°05′, MC Ari 12°57′. The 7th cusp is in Capricorn and the 11th cusp in Taurus.
- Aspects: Venus opp Pluto 2.75°, Saturn opp ASC 4.01°, Mars conj MC 2.28°, Mars sq Jupiter/Neptune, Moon sextile Venus, Moon trine Pluto, Jupiter sextile Venus, Jupiter trine Pluto.

Suites: `npm run server:test` → 1202 passed, 50 skipped. `npm test` → app-native 1069/1069 and web-divination 212/212 (22 files). `npm run typecheck` → exit 0 for both workspaces.

| ID | Verdict | Evidence | Mode |
|---|---|---|---|
| B1 | PASS | `test_b1_*` is green. I also ran it myself: chunks `["Hi.\nThe","re.\n\n\nLast"]` give `delta Hi. / bubble 1 / delta The / delta re. / bubble 2 / delta Last`, and no delta contains `\n`. | TESTS/CODE |
| B2 | PASS | Own run gives `"One. Two. Three."`, then bubble 1, then `"Four. Five."`. With `Budget(4,1)`, `"Pi is 3.5 here. Next"` breaks only after "here." (one sentence end). The test also covers every two-way chunk split. | TESTS/CODE |
| B3 | PASS | `一。二！三？四。` gives `一。二！三？`, then bubble, then `四。`. `他说："好。"然后` under a cap of 1 gives `他说："好。"` then `然后`, so it counts one sentence ending after the `"`. | TESTS/CODE |
| B4 | PASS | Five one-line paragraphs under CHAT give 4 bubbles and `stopped=True`, with no "L5" sent. Seven paragraphs under DEEPER give 6 bubbles and stop. Twenty sentences give `S1–3 / S4–6 / S7–9 / S10–12` and stop. | TESTS/CODE |
| B5 | PASS | `["\n\n  ","Hello."]` gives only `delta "Hello."`. An all-whitespace stream gives `[]`. | TESTS/CODE |
| T1 | PASS | The dw-9 diff to `server/tests/` deletes no line apart from the old `lang.zh` fixture line, which T6 requires to go. The dw-2/3/5 turn tests are unchanged and green. | TESTS/CODE |
| T2 | PASS | `test_dw9_t2_two_bubbles_and_the_side_read_reply` asserts the exact event list and side-read `reply == "A.\n\nB."`. It is green. | TESTS/CODE |
| T3 | PASS | `test_dw9_t3_cut_at_the_cap_does_not_wait_for_the_provider` covers five paragraphs followed by a 5 s block. It asserts bubbles `[1,2,3]`, no "Paragraph 5" text, `elapsed < 2` s, a reply of 4 paragraphs, and that the `finally` ran. Caveat: a thread that is blocked cannot be closed from outside, so the fake is released and then closes at its next chunk (`cancel`). That is plan N1, and I accept it. | TESTS/CODE |
| T4 | PASS | `test_dw9_t4_cast_rolls_first_then_bubbles` produces `dice, delta, bubble, delta, done`. | TESTS/CODE |
| T5 | PASS | Deeper with seven paragraphs gives bubbles `[1..5]` and no `dice`. The system prompt holds `shape.deeper` and not `shape.chat`. An empty transcript, a transcript ending on a user entry, and `action:"roll"` each give 422 with no stream call (`model_validator` in `models.py`). | TESTS/CODE |
| T6 | PASS | Order tests are green: persona < shape.chat < depth.none/depth.chart < (dw-7 mirror) < chart < lang. `venus.txt` contains neither "60 to 180" nor "three". `venus-dice.txt` does not contain "180". `lang.zh` does not contain 三段. `depth.chart` contains "because", "consequence", "one question" and "true of anyone". FINGERPRINT: I computed b308a92's from a `git archive` = `e482d4f819a3ce7b`. HEAD = `4af28014d87bec41`, which differs. Note: the HEAD value also includes dw-7's merged prompt changes. | TESTS/CODE |
| T7 | PASS | `test_bubbles_is_pure` is green. I planted `from app import llm` in `bubbles.py`: `test_bubbles_is_pure` failed, then I reverted it (`git checkout`). `test_main_names_the_synchronous_exceptions` and the divination fence, no-state and importer tests are unchanged and green. `main.py` and `llm.py` are not in the dw-9 diff (`feature/divination_web...HEAD`). Against b308a92 literally, `main.py` differs by +43 lines, all from dw-7's merge. | TESTS/CODE |
| C1 | PASS | core-divination.test.ts "streamTurn bubbles (dw-9 C1)" covers: bubbles 1 and 2 between deltas; a leading, repeated, skipped, `1.5`, `'1'` or missing index is dropped; `TurnAction='deeper'` is sent. | TESTS/CODE |
| C2 | PASS | `deeper:true` survives a fresh KV read, and a non-true value is dropped. `toWire` and `summaryWire` send `A.\n\nB.` with no `deeper`. | TESTS/CODE |
| W1 | PASS | ChatPanel test W1: one slip "A.", then a ghost with role=status and "Venus is writing", with "B." absent. Nothing is stored and no chips or activation appear until at least 430 ms, then two slips, stored `A.\n\nB.`, and chips after the last slip. `pacer.ts` minimum is 450 ms. | TESTS/CODE |
| W2 | PASS | `bubblePause(100)=800` and `bubblePause(300)=1100` (pacer.test). W2 shows two sequential pauses of at least 880 ms total. In the real app, gaps between slips were about 1100 ms for 205- and 248-character slips. | TESTS/CODE (+ real-app timing) |
| W3 | PASS | Stop during a pause stores `{text:'A.\n\nB.', stopped:true}` with no chips and no chip button. Stop mid-stream flushes the held bubble. An error mid-pause shows both slips as the partial. | TESTS/CODE |
| W4 | PASS | The chip shows under the last finished persona entry only. It is hidden while pending, under a stopped entry, and under a reply to a deeper ask. Pressing it sends `action:'deeper'` with the `deeperAsk` message and marks the user line "· deeper". Retry re-sends deeper. zh variant covered. | TESTS/CODE |
| W5 | PASS | An old three-paragraph entry renders as 3 slips under 1 eyebrow, with chips after the last slip. SessionTranscript renders two `<p>`. Log tests are untouched and green. | TESTS/CODE |
| W6 | PASS | en and zh both have `deeper`, `deeperAsk`, `deeperMark` and `writing`; the parity test and the `Dict` type are green. `chat.css` has `@media (prefers-reduced-motion: reduce){ .chat__slip, .chat__deeper, .chat__slip--ghost .chat__stars span {animation:none…} }`. The guards are green, and `theme/tokens.ts` is not in the diff. | TESTS/CODE |
| A1 | PASS | Two full runs of the three questions (quoted under A2) plus a zh run. Every reply rendered as 4 slips, each of at most 3 sentences. The captured SSE shows `event: bubble {"index":1..3}` between deltas every time. The ghost slip with stars was visible between slips on every reply; DOM timeline pattern `(1,ghost)(2,ghost)(3,ghost)(4,no ghost)`. Screenshot: `scratchpad/accept-dw9/shots/ghost-q2.png` shows the first slip with the ✦✦✦ ghost below it. | REAL APP |
| A2 | **FAIL** | Five of the six English replies pass (a)–(e). Run 1 Q3 fails (c), and (d) is borderline. See the quotes below. | REAL APP |
| A3 | PASS | Run 2: I pressed "go deeper" under Q1's reply. POST body `action:"deeper"`, message "Go deeper — tell me more about that."; the user line reads "Go deeper — tell me more about that. · deeper". Result: 6 slips of at most 3 sentences each; 16 sentences against 7 in the reply it deepens. Verified claims: Venus Tau H10 opposite Pluto Sco H4; Moon Pis and Jupiter Cnc "both reach toward it easily" (Moon sextile Venus, Moon trine Pluto, Jupiter sextile Venus, Jupiter trine Pluto); Moon Pis H8; Mars Ari "on your Midheaven, pulled at by Jupiter and Neptune" (Mars conj MC 2.28°, sq Jup, sq Nep). It says how they bear on each other ("that opposition doesn't sit alone … so the strain always has a soft way out"). The chip was absent under the deeper reply and returned under the next ordinary reply (Q2). | REAL APP |
| A4 | PASS | After a reload, all slips and chips of the three replies were byte-identical, still one eyebrow per reply. Pressing "Venus opposition Pluto" set `svg[data-active]` and lit Venus, Pluto and the opposition, with the chip `aria-pressed`. End session produced a summary card: question, seals, "Tone: uneasy", and a note. In Sessions, the reopened transcript showed each bubble as its own `<p>` (4, 4 and 4). | REAL APP |
| A5 | PASS | 中, question "我应该告诉他我的感受吗？" (lang zh). Result: 4 Chinese slips, ending 。 。 。 ？, with 2, 2, 2 and 1 sentences. Slips: "我是你的金星，落在金牛座、第十宫，和冥王星相对。我天生喜欢稳当，总想等脚下的地踩实了再开口，所以我要是劝你慢一点，你得打个折扣再听。" / "但这个相对，让你的感受很难只说一点、留一点。你习惯把它压在很深、很私密的地方，压得越久，说出口的时候就越不像告白，越像摊牌。" / "所以我的意思是：说，但趁它还小的时候说。用一句简单、具体的话就好，比如“我喜欢和你待在一起，想多见见你”，别等攒了几个月，再把一整片海一次倒给他。" / "你希望他听完之后，具体做什么？" | REAL APP |

## A2 — replies quoted verbatim (slips separated by " / ")

The run 1 sequence was Q1, Q2, Q3, reload, chip, end session. The run 2 sequence was Q1, deeper, Q2, Q3.

**Run 1 Q1.** "Yes, I think you should, but plainly and without a speech. I'm your Venus in Taurus in the tenth house, and I trust what is said simply and meant steadily, so weigh my bias toward the direct and the solid." / "Because I sit opposite your Pluto in Scorpio, you tend to keep a feeling private for so long that by the time you say it, it has quietly become a test he has to pass. Tell him while it's still a warm, simple fact about you and not a verdict on him." / "Your Moon in Pisces in the eighth house will want to guess his answer from his face before he's said a word. Don't let it; the only answer you have is what he actually says." / "If he said nothing more than "thank you for telling me," would you still be glad you'd said it?"
- (a) Venus Tau 10th ✓, Venus opp Pluto ✓, Pluto Sco ✓, Moon Pis 8th ✓.
- (b) A feeling kept too long becomes a test for him ✓.
- (c) One question, in the last slip ✓.
- (d) 0 unanchored sentences ✓.
- (e) refs: Venus, Venus opp Pluto, Pluto, Moon ✓.
- Verdict: PASS.

**Run 1 Q2.** "I'm your Venus in Taurus, and I love what stays, so I notice the leaving before anything else. Weigh that bias. Still, I've watched this pattern in you long enough to believe it's real." / "Your Saturn in Capricorn sits on the edge of your partnership angle and rules your seventh house. Because of that, you read reserve as seriousness and a man holding back as a man worth earning. Someone who withholds looks solid to you, as though his care must be the real thing because it's so hard to get." / "Then I, sitting opposite your Pluto in Scorpio, make the wanting itself feel like depth. The not-quite-having is what feels like love to you, so the ones who come toward you plainly and easily seem thin, and you walk past them like a rose you assumed was plastic." / "When a man last showed up easily and stayed easy, what did you tell yourself was missing?"
- (a) Saturn Cap, opp ASC 4.01° (so near the DSC) ✓; 7th cusp in Cap, so Saturn rules it ✓; Venus opp Pluto ✓.
- (b) Reserve is read as worth, so easy partners are passed by ✓.
- (c) ✓.
- (d) At most 1 ("Weigh that bias.") ✓.
- (e) ✓.
- Verdict: PASS.

**Run 1 Q3.** "I'm your Venus in Taurus, and I also rule your eleventh house, the house of friends, so I'm the one who decides who you keep. I judge a friendship by whether it has been reliable, not by whether it has felt good lately, so keep that bias in mind." / "Because I sit opposite your Pluto in Scorpio, you don't let a hurt friendship drift. You either hold on too hard or cut it off completely. That's why this feels like a choice between saving it and losing it, when it may only need one honest conversation." / "For me, "worth saving" comes down to one thing: when it counted, did they show up? One bad season doesn't erase years of being there. A pattern of only showing up when it suits them is different, and no amount of love from you will fix it." / "Leave aside how it went wrong: in the last year, what has this friend actually done for you, not just said?"
- (a) Venus rules the 11th (cusp Tau 19°) ✓; Venus opp Pluto ✓.
- (b) "may only need one honest conversation" ✓.
- **(c) ✗:** there are two questions to the person. Slip 3 asks "when it counted, did they show up?" and the last slip asks another. The depth rule itself says "no other question".
- (d) Borderline. "One bad season doesn't erase years of being there." names neither a chart fact nor a detail of the question, and "A pattern of only showing up when it suits them…" is close to a general maxim.
- (e) ✓.
- **Verdict: FAIL.**

**Run 2 Q1.** "I'm your Venus in Taurus, so I'll admit my bias first. I want to know what he has already shown you in things he's done, not things he's hinted, and I would happily wait for proof forever if you let me." / "The catch is that I sit opposite your Pluto. As long as this feeling stays unspoken, it's yours to hold and control, and a rose you keep closed in your hand never gets to open." / "Your Mars in Aries doesn't wait well either. If you hold this back too long, it's likely to come out all at once at the worst possible moment, so tell him plainly while you can still choose how, and let his answer be his." / "What are you really protecting by keeping quiet: your chance with him, or the version of him you get to keep in your head?"
- (a) Venus Tau ✓, Venus opp Pluto ✓, Mars Ari ✓.
- (b) Held back too long, it comes out at the worst moment ✓.
- (c) ✓. (d) 0 ✓. (e) ✓.
- Verdict: PASS.

**Run 2 Q2.** "Your seventh house, the door partners walk through, opens in Capricorn, and its ruler Saturn sits right on your descendant. So you're drawn to people who show up already guarded, and part of you takes their reserve as a sign of depth, because love you have to earn feels worth more to you." / "I'm your Venus in Taurus, so I'll own my share of this. I trust what stays still, and to me someone who pulls back looks like someone worth waiting out. Add my opposition to your Pluto and the distance itself becomes the draw, because someone who never fully arrives is someone you never fully risk losing." / "So this isn't bad luck, and you can use it. The next time you feel that familiar pull toward someone cool and hard to reach, treat it as a signal to slow down, and look twice at the person who is simply there." / "When someone has stayed close and easy with you, what did you feel, safe or bored?"
- (a) 7th cusp Cap ✓; Saturn on the DSC is Saturn opp ASC at 4.01° ✓; Venus Tau opp Pluto ✓.
- (b) Treat the pull as a signal and look twice ✓.
- (c) ✓. (d) At most 1 ✓. (e) ✓.
- Verdict: PASS.

**Run 2 Q3.** "I rule your eleventh house, the house of friends, so this question is partly about me. I'm your Venus in Taurus opposite Pluto, so my bias is to keep hold of people long after a friendship has stopped feeding either of you, and I tend to call that loyalty." / "Your Sun and Mercury in Gemini sit in that same eleventh house, which means your friendships live on talk. If the two of you still have real conversations, even awkward ones, there's something left to save, but if it has gone quiet or only you are reaching out, the friendship may already be over." / "Look at how things are between you now, not at the history you share, because I'll always vote for the history." / "Leave aside who hurt whom: if you met this person today, would you choose them as a friend?"
- (a) Venus rules the 11th ✓; Sun and Mercury in Gemini in H11 ✓; Venus opp Pluto ✓.
- (b) Quiet or one-sided means it may be over ✓.
- (c) ✓. (d) 0 ✓. (e) ✓.
- Verdict: PASS.

**Why A2 fails:** the criterion holds "for each A1 reply", applied strictly. Run 1 was a complete, valid execution of A1 (three questions in turn), and one of its replies broke (c). A2 therefore does not hold reliably, even though every run 2 reply passes. Every chart claim across all 7 English replies (the deeper reply included) was verified against `/api/chart`; no invented placement or aspect was found.

## Hygiene
- The remote Postgres was never contacted. The server ran from a scratch env copy with no DATABASE_URL line and `DATABASE_URL=` on the command line. Health reported `db: unconfigured`, and the server log has 0 postgres or psycopg mentions. The pytest run also used `DATABASE_URL=`.
- The planted T7 edit was reverted, and `git status --short` in the worktree is clean.
- uvicorn :8002, vite :5175 and Chrome :9333 were stopped; `lsof` shows all three ports free. The scratch env copy was deleted.
- Evidence (turn JSON with raw SSE and DOM timelines, screenshots) is in `scratchpad/accept-dw9/`.

ACCEPTANCE: FAIL — A2
