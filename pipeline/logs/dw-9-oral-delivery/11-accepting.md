# 11 accepting — fresh-context acceptance check (after cycle-1 fix)

Code under test: worktree `astrology-wt/dw-9-oral-delivery`, branch `feature/dw-9-oral-delivery` at `c0858ae`. It includes the merge of `feature/divination_web`, so the dw-7 persona mirror is present. Criteria: `scratchpad/dw-9-criteria.md`. Evidence (raw SSE, DOM timelines, screenshots) is in `scratchpad/accept2-dw9/`.

**How "unchanged since b308a92" was judged.** Every check that names b308a92 as the base was evaluated as `git diff feature/divination_web...HEAD`, because dw-7 landed on the base branch after b308a92 and was merged in. The fingerprint check compares against the real b308a92 value, which was computed from a `git archive` of b308a92. The current fingerprint also carries dw-7's prompt changes.

**Suites.**
- `pytest -q` (run with `DATABASE_URL=`): 1203 passed, 50 skipped.
- `npm test`: app-native 1069/1069 and web-divination 212/212 (22 files).
- `npm run typecheck`: exit 0.

## Verdicts

| ID | Verdict | Evidence | Basis |
|---|---|---|---|
| B1 | PASS | `test_b1_line_breaks_end_bubbles_and_never_reach_the_wire` asserts the exact op list. It also runs every two-way split and checks that no delta holds a newline. | TESTS/CODE |
| B2 | PASS | `test_b2_sentence_cap_never_splits_a_sentence`: the result is exactly `["One. Two. Three.", "Four. Five."]` with `bubble 1` between the two, and "Pi is 3.5 here. Next" counts one sentence end under `Budget(4,1)`. | TESTS/CODE |
| B3 | PASS | `test_b3_cjk_terminators_and_closing_quotes`: `一。二！三？` then a bubble, then `四。`. `他说："好。"` counts one sentence that ends after the closing `"`. | TESTS/CODE |
| B4 | PASS | `test_b4_bubble_cap_stops_both_budgets`: 5 lines give 4 bubbles and `stopped`; 7 paragraphs under DEEPER give 6 bubbles and `stopped`; 20 sentences give 4 bubbles of 3 and `stopped`. | TESTS/CODE |
| B5 | PASS | `test_b5_leading_and_all_whitespace`: the first op is `("delta","Hello there.")`, and an all-whitespace stream gives `ops == []`. | TESTS/CODE |
| T1 | PASS | The diff of `test_divination_turn.py` against the base has 0 removed lines, so it only adds tests. All dw-2/3/5 tests pass. | TESTS/CODE |
| T2 | PASS | `test_dw9_t2_two_bubbles_and_the_side_read_reply` pins the exact event list, and the side read's `reply == "A.\n\nB."`. | TESTS/CODE |
| T3 | PASS | `test_dw9_t3_cut_at_the_cap...`: bubbles are [1,2,3], there is no "Paragraph 5" text, `elapsed < 2`, the side-read reply has 4 paragraphs, and `closed.wait(1.0)` shows the generator's `finally` ran. | TESTS/CODE |
| T4 | PASS | `test_dw9_t4_cast_rolls_first_then_bubbles` gives `dice, delta, bubble, delta, done`. | TESTS/CODE |
| T5 | PASS | `test_dw9_t5_*`: the default transcript ends on a persona entry. A seven-paragraph fake gives bubbles 1–5 and no `dice`, with `shape.deeper` in the system prompt and `shape.chat` absent. An empty transcript or one ending on a user entry answers 422 with the fake uncalled, and `action:"roll"` answers 422. | TESTS/CODE |
| T6 | PASS | The order tests `test_t6_chat_prompt_order_*` (en/zh without a chart, and chart A) pass. `test_t6_old_length_rules_are_gone` and `test_t6_depth_rule_names_the_because...` pass. The FINGERPRINT is now `d73444557626a9d7`; I computed `e482d4f819a3ce7b` from the real b308a92 tree, so it differs. The current value includes dw-7's prompt changes too. | TESTS/CODE |
| T7 | PASS | `test_bubbles_is_pure` passes. I planted `from app import llm` in `bubbles.py`: the test failed, and after I reverted the plant it passed. The synchronous-exceptions, divination fence, keeps-no-state and importer tests pass, and the base diff of `test_boundaries.py` only adds. `git diff feature/divination_web...HEAD` touches neither `main.py` nor `llm.py`; against b308a92 itself, `main.py` differs only by dw-7's merged changes. | TESTS/CODE |
| C1 | PASS | `core-divination.test.ts` "streamTurn bubbles (dw-9 C1)": bubble 1 then 2 arrive between deltas. It drops a bubble before the first delta, and repeated, skipped, non-integer and missing indexes. It also sends `'deeper'` as a `TurnAction`. | TESTS/CODE |
| C2 | PASS | "transcript deeper (dw-9 C2)": `deeper:true` survives a fresh KV read. `toWire` and `summaryWire` drop `deeper` and send the `\n\n`-joined text. ChatPanel W1 checks that the stored text is `'A.\n\nB.'`. | TESTS/CODE |
| W1 | PASS | ChatPanel "W1": one slip `A.` shows, then a ghost slip with role status reading "Venus is writing", and `B.` is not yet in the DOM. Two slips follow after at least 430 ms. The store, chips and `showRefs` stay empty until after the pause. | TESTS/CODE |
| W2 | PASS | `pacer.test.ts` gives `bubblePause(100)=800` and `bubblePause(300)=1100`, and the fake-timer test shows two sequential pauses. ChatPanel W2 shows the same with real timers. | TESTS/CODE |
| W3 | PASS | ChatPanel W3 has three cases. Stop during a pause after `done` stores `{text:'A.\n\nB.', stopped:true}`. Stop mid-stream flushes the held bubble. An error mid-pause shows `['A.','B.']` in the failure partial. | TESTS/CODE |
| W4 | PASS | "ChatPanel go deeper (dw-9 W4)": the chip shows only under the last finished entry. It is hidden under a stopped entry, under a reply to a deeper ask, and while pending. Pressing it POSTs `action:'deeper'` with `message` set to `chat.deeperAsk`, and stores a user entry with `deeper:true` and the " · deeper" mark. Retry re-sends `deeper`. | TESTS/CODE |
| W5 | PASS | ChatPanel W5: three slips under one eyebrow, with the chips after the last slip. `SessionTranscript` renders two `<p>`. The `log/` tests are unchanged (no diff) and pass. | TESTS/CODE |
| W6 | PASS | `chat.deeper`, `deeperAsk`, `deeperMark` and `writing` exist in en and zh, and the i18n parity tests pass. `chat.css` lines 573–581 hold a `prefers-reduced-motion: reduce` block covering `.chat__slip`, `.chat__deeper` and `.chat__slip--ghost .chat__stars span` with `animation:none`. The colour and architecture guards pass. `web-divination/src/theme/tokens.ts` has no diff. | TESTS/CODE |
| A1 | PASS | I asked the 3 questions twice (runs r1 and r2). Slip counts were r1 4/4/4 and r2 4/4/3, and every slip had at most 3 sentences. The raw SSE of every turn shows `bubble` frames between deltas, e.g. r1q1 `d11 bubble d17 bubble d11 bubble d5 done`. DOM timelines show a ghost slip between slips on every reply. Screenshots: `shots/ghost-r1q1..r2q3.png`; in `ghost-r1q2.png` the ✦✦ ghost slip is visible under slip 1. | REAL APP |
| A2 | PASS | All 6 replies pass (a)–(e); the replies and per-check notes follow this table. | REAL APP |
| A3 | PASS | The deeper reply (r2deep) has 6 slips with 4/3/3/3/3/3 sentences, 19 in all against 8 in the reply it deepens. Every claim checks out: Venus in Taurus in H10 opposite Pluto in Scorpio in H4; Moon in Pisces in H8 trine Pluto; the Moon–Jupiter–Pluto grand trine; a kite with the Venus–Pluto spine (Venus sextile Jupiter at 2.4° and sextile the Moon at 9.7°); Mars in Aries conjunct the MC; 7th cusp in Capricorn with its ruler Saturn in H6 trine Venus. The reply says how they bear on each other. The chip is absent under it (`deeperChips: []`) and returns under the next ordinary reply (r2q2, `inLast: true`). | REAL APP |
| A4 | PASS | After a reload, the slips and chips are identical (`same: true`). Pressing the "Venus opposition Pluto" chip lit Venus, Pluto and the opposition (`svg[data-active]`, `aria-pressed`, `shots/04-chip-lit.png`). End session produced a summary card ("Tone: uneasy" plus a note). Reopening the session in Sessions shows each bubble as its own `<p>` (4/4/4). | REAL APP |
| A5 | PASS | With 中, I asked 「我应该告诉他我的感受吗？」 and got 4 Chinese slips, ending 。/。/。/？, with 2/2/2/1 sentences. `done.chartRefs` was non-empty and the chip read 展开说说. | REAL APP |

## A2 — verbatim replies and per-reply checks

All claims were checked against `POST /api/chart` for chart A. Chart A: Sun Gemini H11 (unaspected), Moon Pisces H8, Mercury Gemini H11, Venus Taurus H10, Mars Aries H9 conjunct the MC, Jupiter Cancer H12, Saturn Capricorn H6 opposite the ASC at 4.0°, Pluto Scorpio H4. Cusps: 7th Capricorn, 11th Taurus. Aspects: Venus opposition Pluto, Venus trine Saturn, Moon trine Pluto.

**r1q1** (Should I tell him how I feel?)
> "I'm your Venus in Taurus in the tenth house, and I lean toward yes, because I like what I value out in the open where it can be seen and named. Weigh that, since it's my bias." / "Your Venus opposite Pluto is the part that has kept this quiet until you can be sure of his answer before you risk yours. That kind of waiting starts to feel like safety when it's really control, and it can keep you circling him for months." / "Your Mars in Aries sits on your Midheaven, so when you speak, say it plainly and say it once. Use one sentence you could stand behind in daylight, not a hint hidden inside a joke." / "Which answer frightens you more: that he doesn't feel the same, or that he does?"

- (a) Venus in Taurus in H10 ✓; Venus opposition Pluto ✓; Mars in Aries on the MC ✓ (2.3°).
- (b) The waiting "can keep you circling him for months" ✓.
- (c) One `?`, in the last slip ✓.
- (d) One unanchored sentence ("Weigh that, since it's my bias."); the limit is 1 ✓.
- (e) chartRefs holds 3 ✓.

**PASS.**

**r1q2** (Why do I always pick people who pull away?)
> "Saturn sits on your Descendant, the point where you look for a partner, so you're drawn to people who are guarded, slow to give and hard to win. I'm your Venus in Taurus, trine that Saturn, and I'll admit their reserve attracts me too, because it looks like something solid that will last." / "Your Venus opposite Pluto makes a person who pulls back feel like something worth holding onto and working at. Reaching for him starts to feel like depth, and it gives you a kind of control, because the effort is yours to make." / "Your Moon in Pisces in the eighth house fills his silence with your own feeling. So the one you fall for is partly the man you imagine behind the distance, not the man who is leaving." / "When someone comes toward you openly and stays, what is the first thing about him that makes you lose interest?"

- (a) Saturn on the DSC ✓; Venus trine Saturn ✓; Venus opposition Pluto ✓; Moon in Pisces in H8 ✓.
- (b) You fall for an imagined man, not the one leaving ✓.
- (c) One question, in the last slip ✓.
- (d) 0 unanchored sentences ✓.
- (e) chartRefs holds 5 ✓.

**PASS.**

**r1q3** (Is this friendship worth saving?)
> "I'm your Venus in Taurus, and I also rule your eleventh house, the house of friends. That means I judge a friendship by how many years it has lasted and whether it has held up, and I'm very slow to let one go. Weigh my yes with that in mind." / "Your Sun and Mercury in Gemini sit in that eleventh house. Friendship is where you feel most like yourself and where you talk most freely. A friendship where the easy talk has dried up costs you more than it would cost most people." / "Your Venus opposite Pluto is the same pull we talked about with men who pull away. Wanting to \"save\" this friendship can turn into you doing all the repair work alone, because the effort is at least something you control." / "When did this friend last reach out to you first, without you having gone first?"

- (a) Venus rules the 11th (Taurus cusp) ✓; Sun and Mercury in Gemini in H11 ✓; Venus opposition Pluto ✓.
- (b) Saving it can mean doing all the repair work alone ✓.
- (c) ✓.
- (d) One unanchored sentence ("Weigh my yes with that in mind.") ✓.
- (e) chartRefs holds 4 ✓.

**PASS.**

**r2q1** (Should I tell him how I feel?)
> "I'm your Venus in Taurus, at home in my own sign, and I lean toward yes. You've carried this feeling steadily enough to ask me about it, and a feeling that has lasted that long deserves to be said out loud." / "Because I sit opposite your Pluto, the danger isn't in telling him. It's in telling him as a way to hold on to him, with your whole self hanging on what he says back. So say it as something true about you, not as a demand he has to meet." / "Your Moon in Pisces in the eighth house picks up everything he does and quietly builds a whole story out of it. Before you speak, separate what he has actually said to you from what you have only felt in the silences." / "When you picture telling him, which scares you more: that he says no, or that you lose the version of him you've been keeping?"

- (a) Venus in Taurus (domicile) ✓; Venus opposition Pluto ✓; Moon in Pisces in H8 ✓.
- (b) Telling him as a way to hold on leaves your whole self hanging on his answer ✓.
- (c) ✓.
- (d) 0 unanchored sentences ✓.
- (e) chartRefs holds 3 ✓.

**PASS.**

**r2q2** (Why do I always pick people who pull away?)
> "Saturn sits right on your descendant, opposite your Cancer rising, and that is the point in your chart that shows what you look for in a partner. Because of that, someone guarded and a little out of reach feels serious to you, as if his distance shows he's worth the effort." / "I'm your Venus in Taurus, opposite your Pluto in Scorpio, and I'll admit my bias: I like to hold on, and Pluto likes to dig. A man who pulls away gives both of us something to work at, while a man who simply stays leaves us nothing to win, so he can seem strangely flat to you." / "Your Moon in Pisces in the eighth house fills whatever gap he leaves with a story of your own, just as it did with the silences you told me about. The more he withdraws, the more room your Moon has to imagine him, and the imagined him is usually kinder than the real one." / "Think of the last man who stayed close and showed up without being chased: what did you tell yourself about why he didn't interest you?"

- (a) Saturn opposite the Cancer ASC ✓; Venus in Taurus opposite Pluto in Scorpio ✓; Moon in Pisces in H8 ✓.
- (b) A man who stays seems flat to you ✓.
- (c) ✓.
- (d) 0 unanchored sentences ✓.
- (e) chartRefs holds 6 ✓.

**PASS.**

**r2q3** (Is this friendship worth saving?)
> "I rule your eleventh house, the house of friends, and I sit at home in Taurus in your tenth. Because of that, a friendship proves its worth to you by lasting and by standing up in plain view, not just by feeling close." / "Your Sun and Mercury in Gemini sit in that eleventh house, and your Sun makes no aspect to anything else in your chart. So friendship is where you feel most yourself, all or nothing. That means you can keep one alive with talk long after the giving has stopped on one side." / "I sit opposite your Pluto, and that makes me want to hold on and call it loyalty, so I lean toward saving this one more readily than you might need to. Your Saturn trines me, and it gives you a plainer test: count what this friend has actually done for you in the last few months, not what the two of you used to be. If you set aside the years you've already put in, would you choose this person as a friend today?"

- (a) Venus rules the 11th and sits in Taurus in H10 ✓; Sun and Mercury in Gemini in H11 ✓; the Sun is unaspected ✓ (the aspect list has no Sun entry); Venus opposition Pluto ✓; Saturn trine Venus ✓.
- (b) You can keep it alive with talk after the giving stopped ✓.
- (c) One `?`, in the last slip ✓.
- (d) 0 unanchored sentences ✓.
- (e) chartRefs holds 5 ✓.
- Shape: 3 slips of 2/3/3 sentences ✓.

**PASS.**

## Hygiene

- **Remote Postgres never contacted.** uvicorn ran from a scratch env copy with the DATABASE_URL line removed, plus `DATABASE_URL=` on the command line. The first request, `/api/health`, returned `"db":"unconfigured"`. The server log has 0 postgres or psycopg mentions, and pytest also ran with `DATABASE_URL=`.
- **Planted edit reverted.** The T7 plant was reverted with `git checkout`, and `git status --short` is clean.
- **Processes stopped.** uvicorn :8002, vite :5175 and Chrome CDP :9334 were stopped, and `lsof` shows none listening. The scratch env copy and the b308a92 archive were deleted.

ACCEPTANCE: PASS
