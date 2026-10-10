# 05 validating — dw-9-oral-delivery (worker #2, cycle 0)

Branch `feature/dw-9-oral-delivery` @ 9ddd751. Evidence files (screenshots,
per-turn JSON with every SSE frame and its arrival time, `/api/chart` output)
are in `logs/dw-9-oral-delivery/05-validating-evidence/`.

## Suites (verbatim summary lines)

- server `conda run -n astrology pytest -q` → `1160 passed, 50 skipped, 1 warning in 108.58s (0:01:48)`
- root `npm run typecheck` → both workspaces `tsc --noEmit`, 0 `error TS`
- root `npm test` → app-native `Test Suites: 90 passed, 90 total` /
  `Tests: 1069 passed, 1069 total`; web-divination `Test Files 20 passed (20)` /
  `Tests 194 passed (194)`

Criteria covered by tests only: B1–B5, T1–T7, C1, C2, W1–W6 (see
04-implementing.md for each test). T7 extra: `git diff feature/divination_web
-- server/app/main.py server/app/llm.py | wc -l` → `0`.

## Real app setup (safety first)

- Scratch env: a copy of the repo `.env` with every `DATABASE_URL` line
  removed, OUTSIDE the repo (session scratchpad, `dw9.env`;
  `grep -c DATABASE_URL` → `0`). Deleted at the end.
- Backend from the worktree root:
  `DATABASE_URL= ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5175 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file <scratch>/dw9.env --port 8002`
- FIRST request after boot, before any other:
  `curl localhost:8002/api/health` → `{"status":"ok","db":"unconfigured","ephemeris":"ok"}`.
  The shared remote Postgres was never contacted (the summary store wrote
  `server/data/divination.db`, the worktree's own SQLite file).
- Web: `cd web-divination && VITE_API_BASE=http://localhost:8002 npx vite --port 5175`.
- Browser: headless Chrome (`--headless=new`, fresh `--user-data-dir`,
  CDP on 9232) driven by a node CDP script. The page's `fetch` was wrapped
  (init script) to tee the turn response and record every SSE frame with
  its arrival time — the network-panel equivalent; the DOM was polled every
  80 ms for slips / ghost slip, and a screenshot taken the first time a
  ghost slip appeared.
- Chart A (1990-06-15 08:30 Beijing, placidus) was entered by seeding the
  local profile's birth-data key (`astrology.birthData.v1.traveler`) and
  reloading — the form itself was not typed into (dw-1's surface, not
  dw-9's). The wheel and placements rendered it (Sun Gemini H11, Moon Pisces
  H8, Venus Taurus H10, Mars Aries H9, …).
- `/api/chart` for chart A (saved as `chartA.json`), used for every chart
  claim below: Venus Taurus H10, Pluto Scorpio H4, Mars Aries H9, Moon
  Pisces H8, Saturn Capricorn H6, Asc Cancer 28°, DC Capricorn 28°, MC Aries;
  11th cusp Taurus; 7th cusp Capricorn; aspects incl. Venus opposition
  Pluto, Mars conjunction Midheaven, Mars square Neptune, Moon square
  Mercury, Moon trine Pluto, Saturn opposition Ascendant.

## A1 — shape (REAL APP)

Three questions in one session, through the UI (textarea + Send).

| Q | bubble events (ms after response) | slips | sentences per slip | newline in any delta | ghost slip seen |
|---|---|---|---|---|---|
| Should I tell him how I feel? | 1 @10262, 2 @11414, 3 @12018; done @16920 | 4 | 2, 3, 2, 1 | no | yes (1033 ms, then 2231 ms) |
| Why do I always pick people who pull away? | 1 @12228, 2 @12731, 3 @13588; done @17664 | 4 | 2, 2, 3, 1 | no | yes (3303 ms: three queued pauses) |
| Is this friendship worth saving? | 1 @9312, 2 @9812, 3 @10415; done @15587 | 4 | 2, 2, 2, 1 | no | yes (3308 ms) |

Every frame list is `delta… bubble delta… bubble delta… bubble delta… done`
— `bubble` always between deltas. Screenshot of a ghost slip between slips
(✦ stars in a dashed frame under the first slip, Stop live):
`05-validating-evidence/ghost-q2.png`. Finished reply rendered as four slips
with seals, mood and the go-deeper chip: `q1-done.png`. **PASS.**

## A2 — depth (REAL APP; checker's rubric per reply)

### Reply 1 — "Should I tell him how I feel?" (verbatim, one line per slip)

> Yes, you should, though not because every feeling needs saying. I've watched a lot of people wait for the perfect evening to speak, and the evening star keeps setting without them.
>
> Your Venus in Taurus is in her own sign, so what you feel for him is steady and real, not a passing crush. But she stands opposite Pluto, which is why you'd rather keep this as a secret you control than give him something he could refuse. Keeping quiet feels safe, but the longer a feeling stays hidden, the heavier it gets.
>
> Your Mars in Aries is also at home, and it sits right on your Midheaven, so you're built to say things plainly. Tell him once, in clear words and not in hints he has to decode, and then let his answer belong to him.
>
> What frightens you more: that he'll say no, or that he'll say yes and you'll have to let him see you?

- (a) Venus in Taurus ✓, Venus opposite Pluto ✓, Mars in Aries ✓, Mars on
  the Midheaven ✓ (Mars conjunction Midheaven). PASS.
- (b) Consequence for this question: the opposition makes the person keep
  the feeling as a controlled secret → tell him once, plainly. PASS.
- (c) Exactly one "?" in the reply, in the last slip. PASS.
- (d) Sentences naming neither a chart fact nor the question: "I've watched
  a lot of people wait for the perfect evening to speak…" (1). "Keeping
  quiet feels safe…" is about the question (speaking up). PASS (1 ≤ 1).
- (e) `done.chartRefs` = planet Venus, aspect Venus opposition Pluto,
  planet Mars. PASS.

### Reply 2 — "Why do I always pick people who pull away?"

> Because distance looks like depth to you. Your Saturn in Capricorn sits right on your Descendant, facing your Cancer rising, so a man who holds something back feels serious and worth earning to you, like the real thing.
>
> Your Moon in Pisces in the eighth house is also very good at filling a silence with meaning. When he pulls away, you get room to imagine who he is, and the man you imagine is always kinder than the one who isn't texting back.
>
> I've watched this happen for a very long time: someone who comes toward you steadily can feel almost too easy to you, like a rose you forget to look at because it has no thorns. Saturn isn't asking you for coldness, though. It's asking for someone who keeps his word over time, and that's a very different man.
>
> The last time someone warm and plain showed up and stayed, what did you tell yourself was missing?

- (a) Saturn in Capricorn ✓, on the Descendant ✓ (Saturn 24° Cap, DC 28°
  Cap; Saturn opposition Ascendant), Cancer rising ✓, Moon in Pisces in the
  8th ✓. PASS.
- (b) Consequence: withholding reads as seriousness, silence gets filled
  with an imagined kinder man → why the person picks those who pull away.
  PASS.
- (c) One "?", last slip. PASS.
- (d) "I've watched this happen…" is about the question (who the person
  picks); no sentence is free of both chart and question. PASS.
- (e) chartRefs = Saturn, Saturn opposition Ascendant, Moon. PASS.

### Reply 3 — "Is this friendship worth saving?"

> I can't weigh this friendship without knowing what broke, but I can tell you how you tend to weigh your friendships. Your house of friends is ruled by your Venus in Taurus, so you keep people the way you'd keep a rose bush, and you'll go on watering one that stopped flowering years ago.
>
> Your Venus opposite Pluto adds a second habit. When a bond is threatened, you either hold it tighter or cut it off completely, and neither one actually saves it.
>
> Your Moon square Mercury means what you feel and what you say drift apart, so a friendship like yours usually dies of a conversation nobody had. Have that conversation once, plainly, and how they meet it will tell you more than I can.
>
> If they never apologised and never changed, would you still want them at your table?

- (a) 11th house (friends) cusp Taurus → ruled by Venus, Venus in Taurus ✓;
  Venus opposite Pluto ✓; Moon square Mercury ✓. PASS.
- (b) Consequence: have the one plain conversation; their response decides.
  PASS.
- (c) One "?", last slip. PASS.
- (d) None free of both. PASS.
- (e) chartRefs = Venus, Venus opposition Pluto, Moon square Mercury. PASS.

## A3 — go deeper (REAL APP)

The chip only exists under the LAST finished reply (W4 by design), so A3
ran in a fresh session (after A4 ended the first): the first question
again, then the chip.

Base reply (6 sentences, 3 slips; verbatim):

> Yes, I think you should, and sooner than feels comfortable. Your Venus in Taurus opposite Pluto tends to keep a feeling private for so long that when it finally comes out, it's heavy, and he gets handed all of it at once.
>
> You also have Mars in Aries, strong in its own sign and conjunct your Midheaven, so plain speaking suits you far better than hinting. Say one true sentence, something like "I like you as more than a friend," and then stop and let him answer.
>
> I've watched lovers wait a very long time for a sign from across the table, and the sign usually comes only after one of them speaks. Which are you really afraid of: that he doesn't feel the same, or that he does?

Pressed "go deeper ⌄": the request carried `action: "deeper"`, message
`Go deeper — tell me more about that.`, the 2-entry transcript. The user
line rendered "You: Go deeper — tell me more about that. · deeper". Frames:
bubbles 1–5 @12920/14322/15623/16928/17972, done @24139; four ghost
episodes. Deeper reply (verbatim):

> Your Venus is in Taurus, its own sign, in your tenth house, and it sits opposite your Pluto in Scorpio in your fourth. Your affection is steady and loyal, and people can see it. But the opposition pulls the actual feeling down into the most private part of you, where you guard it and test it and rarely let anyone see it. That's why it grows heavy before it ever reaches him.
>
> Your Moon in Pisces in the eighth house rules your chart, and it trines that same Pluto, so you read people's undercurrents very well. The cost is that you may think you already know his answer from his moods, his glances and his silences. Reading him closely is not the same as asking him, and your chart makes it easy to mistake one for the other.
>
> Then there's your Mars in Aries on your Midheaven, square Neptune. When you finally act, you act boldly. But Neptune blurs the edges, so the confession can come out as a joke, a hint or a half-sentence he's able to misread. That's why I told you to say one plain sentence and then stop, so he has nothing vague to hide behind or to misread.
>
> Put together, it works like this: Pluto keeps the feeling hidden, the Moon keeps reading him, and Mars keeps pushing to get it out. Left alone, that tends to end in a long silence and then a sudden, blurry outburst at a bad moment. So choose the moment yourself, somewhere quiet and unhurried, before the pressure chooses it for you.
>
> Saturn rules your seventh house and sits across from your rising sign, so you expect love to be slow, earned and a little serious. That works in both directions. If he goes quiet or asks for a day to think, it isn't a no, and you shouldn't treat it like a tide going out.
>
> If your Moon is right and you already know how he feels, what have you been waiting for?

- More sentences than the base: 18 vs 6. ✓
- 6 slips (≤ 6); sentences per slip 4, 3, 4, 3, 3, 1 (≤ 4 each). ✓
- Placements (all verified): Venus Taurus H10, Pluto Scorpio H4, Venus
  opposition Pluto, Moon Pisces H8 as chart ruler (Cancer rising), Moon
  trine Pluto, Mars Aries on the MC (conjunction), Mars square Neptune,
  Saturn ruling the 7th (Capricorn cusp) opposite the Ascendant. How they
  bear on each other: slip 4 ("Pluto keeps the feeling hidden, the Moon
  keeps reading him, and Mars keeps pushing…"). ✓
- chartRefs: Venus, Pluto, Venus opposition Pluto, Moon, Moon trine Pluto,
  Mars.
- Chip absent under the deeper reply (`button.chat__deeper` count 0). Next
  ordinary question "What if he says no?" → 4 slips, chip back under it
  (count 1). ✓ Screenshot: `a3-deeper-done.png`. **PASS.**

## A4 — continuity (REAL APP)

- Reload after A1: the persona letters before and after are identical
  (slip texts, chips, mood, chip placement) — `[0, 4, 4, 4]` slips
  (greeting + three replies). ✓
- Pressed the "Venus opposition Pluto" seal on reply 1: `aria-pressed=true`;
  the wheel gained `data-lit` on the opposition line, its two node circles,
  Venus and Pluto (none before). ✓
- End session → chat reset to the greeting; "Sessions · 1". Sessions screen:
  summary card sealed — question "“Should I speak up to him, why do I keep
  choosing people who pull away, and is this friendship worth saving?”",
  tone "uneasy". ✓
- Opened the card: the reader's `.letters__prose p` per persona entry =
  `[4, 4, 4]` paragraphs, exactly equal to the stored slips — each bubble
  its own paragraph. Screenshot `a4-reader.png`. **PASS.**

## A5 — zh (REAL APP)

Ended the A3 session, switched to 中 (placeholder "向金星提问…",
`html lang=zh-CN`), asked "我应该告诉他我的感受吗？". Frames: bubbles 1–3
@11741/12796/13141, done @16911; ghost slips seen (`ghost-a5.png`).
Verbatim:

> 我看过太多人把一句喜欢在心里养成一整片海，最后反倒开不了口。你的金星在金牛座、落在第十宫，又和天蝎座的冥王星对冲，所以你喜欢一个人，一旦认定就很沉、很久，而且习惯先把它藏到最深处，等到觉得万无一失才肯拿出来。
>
> 放到你这件事上就是：你拖得越久，这份感受在你心里就越重。重到最后，你想对他说的已经不是“我喜欢你”，而是“你得接住我的全部”。所以我的回答是说，但要趁它还轻的时候说，就用金牛座的方式说一句平实的话，不必把整颗心一次掏出来。
>
> 你的火星在白羊座，本来就是直来直去的，这份勇气你自己就有，不用向谁借。
>
> 你怕的到底是他不喜欢你，还是话一出口，你就再也没法假装自己没那么在乎？

- 4 Chinese slips; each ends in 。 or ？ ✓; sentences per slip 2, 3, 1, 1
  (≤ 3) ✓. Chart claims verified (Venus Taurus H10, Pluto Scorpio, Venus
  opposition Pluto, Mars Aries). Chips in zh: 金星, 金星冲冥王星, 冥王星,
  火星; mood 坦率. Screenshot `a5-done.png`. **PASS.**

## Teardown

Stopped my backend (8002), Vite (5175) and headless Chrome (9232) — only
processes I started. `lsof -nP -iTCP:8002 -iTCP:5175 -iTCP:9232 -sTCP:LISTEN`
→ nothing (exit 1). Scratch env and the Chrome profile deleted. Note: the
session scratchpad is shared with the other workers — another worker's
backend wrote its own `backend.log` (port 8001) over mine at the same path;
nothing of theirs was read or stopped, and my evidence was captured from
the browser, not that log.

Result: all A1–A5 PASS on the real app; no fix loop needed (cycles: 0).
Transition: validating → docs-sync.
