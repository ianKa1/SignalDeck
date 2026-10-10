# 10 validating — dw-9-oral-delivery, after acceptance cycle 1 fix (c0858ae)

Scope, per the coordinator: re-validate A2 on the real app, running the
three A1 questions at least twice (6 English replies). Every reply is
quoted verbatim, (a)–(e) are checked per reply, and every chart claim is
checked against `/api/chart` (chart A, `05-validating-evidence/chartA.json`).
A5 (zh) was re-checked once. Evidence (per-turn SSE frames + final DOM) is
in `10-validating-evidence/`.

## Setup
- Scratch env `scratchpad/dw9/dw9.env` is a copy of `.env` with 0
  DATABASE_URL lines. The backend ran from the worktree root with
  `DATABASE_URL= ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5175 … --port 8002`.
  The FIRST request was `/api/health`, which returned
  `{"status":"ok","db":"unconfigured","ephemeris":"ok"}`.
- Vite ran on 5175 (`VITE_API_BASE=http://localhost:8002`).
- Headless Chrome ran on 9232 with its profile at
  `scratchpad/dw9/chrome-profile`, and chart A was seeded.
- A run is: the three A1 questions asked through the UI in one session,
  then End session.
- One tuning attempt was enough: the first rerun after the fix passed, so
  no further tuning was done.

## Suites (from 09-implementing)
- Server: `1203 passed, 50 skipped`.
- Typecheck: clean.
- `npm test`: app-native 1069 passed; web-divination 22 files / 212 tests.

## A2 per reply (REAL APP)

### Run 1 · Q1 — "Should I tell him how I feel?"

Frames: bubble@8424, bubble@9060, bubble@9511, done@14739; no delta holds a newline: True. Slips 4, sentences per slip [2, 2, 2, 1].

> I'm your Venus in Taurus in the tenth house, at home and unhurried, and I don't hand my heart over until I know the ground will hold, so I lean toward waiting. Weigh that bias, because you're here asking, and that tells me you've already held this longer than is comfortable.
>
> My opposition to your Pluto in Scorpio is the real risk here, because it makes you want to speak only once you can control how he'll answer. If you wait for that guarantee, what you feel for him turns into quiet watching and managing.
>
> Your Mars in Aries sits right on your Midheaven, so when you do say it, say it plainly and in the open. Give him one clear sentence, not a hint he has to decode.
>
> What has he actually done, not said, that makes you believe the ground between you is steady enough to hold it?

- (a) Venus Taurus H10 at home ✓ (domicile); Venus opposition Pluto ✓; Pluto Scorpio ✓; Mars Aries on the Midheaven ✓ (Mars conjunction MC). PASS
- (b) waiting for a guarantee turns the feeling into watching and managing → say it in one clear sentence. PASS
- (c) '?' positions (slip index) [3], last slip 3: exactly one question, in the last slip. PASS
- (d) unanchored sentences: 0 — every sentence carries a chart fact or the question ("Give him one clear sentence…" is about telling him). PASS
- (e) done.chartRefs = [{"kind": "planet", "body": "Venus"}, {"kind": "aspect", "bodyA": "Venus", "type": "opposition", "bodyB": "Pluto"}, {"kind": "planet", "body": "Pluto"}, {"kind": "planet", "body": "Mars"}]. PASS

### Run 1 · Q2 — "Why do I always pick people who pull away?"

Frames: bubble@6722, bubble@7620, bubble@8470, done@16171; no delta holds a newline: True. Slips 4, sentences per slip [3, 2, 2, 1].

> I'm your Venus in Taurus, and I read a closed-off person as a solid one, so weigh my taste here. Your Saturn in Capricorn sits on your Descendant and rules your seventh house, so the people who draw you are reserved and make you earn every inch of closeness. To both of us, that reserve looks like something built to last.
>
> Your Moon in Pisces in the eighth house, sextile Uranus, feels intimacy most strongly when there's a gap to reach across. So when someone starts drifting away, that pull feels like depth to you, and someone who stays close and easy can feel flat by comparison.
>
> My opposition to your Pluto is the part you might not want to hear. Someone who keeps pulling away gives you something to hold onto and hold tight to, and it keeps you from being fully seen, because the chase fills the room where closeness would go.
>
> When someone steady and warm has shown up for you, what did you tell yourself about why he wasn't enough?

- (a) Venus Taurus ✓; Saturn Capricorn on the Descendant ✓ (24° Cap vs DC 28° Cap; Saturn opposition Ascendant) and ruling the 7th ✓ (7th cusp Capricorn); Moon Pisces H8 ✓; Moon sextile Uranus ✓; Venus opposition Pluto ✓. PASS
- (b) reserve reads as lasting, distance as depth, the chase fills the room closeness would take → why they pick people who pull away. PASS
- (c) '?' positions (slip index) [3], last slip 3: exactly one question, in the last slip. PASS
- (d) unanchored sentences: 0. PASS
- (e) done.chartRefs = [{"kind": "planet", "body": "Venus"}, {"kind": "planet", "body": "Saturn"}, {"kind": "aspect", "bodyA": "Saturn", "type": "opposition", "bodyB": "Ascendant"}, {"kind": "planet", "body": "Moon"}, {"kind": "aspect", "bodyA": "Moon", "type": "sextile", "bodyB": "Uranus"}, {"kind": "aspect", "bodyA": "Venus", "type": "opposition", "bodyB": "Pluto"}]. PASS

### Run 1 · Q3 — "Is this friendship worth saving?"

Frames: bubble@8043, bubble@9043, bubble@9917, done@14508; no delta holds a newline: True. Slips 4, sentences per slip [2, 2, 2, 1].

> I rule your eleventh house of friends from where I sit in Taurus in your tenth. That means I judge a friend by whether they show up when it counts, and I hate letting go of anything I've put years into, so weigh my lean toward keeping it.
>
> My trine to your Saturn is why you can mend a friendship that's gone slow or neglected. If the only thing wrong is distance and silence, a steady, repeated effort from you, like a standing call or a regular meal, is exactly what you're built for.
>
> My opposition to your Pluto is the part that decides this. If the friendship is hurting because one of you keeps score or wants to control the other, then patience only keeps a grudge alive, and holding on would be possession, not loyalty.
>
> Tell me what actually broke between you: did one of you drift, or did one of you betray the other?

- (a) Venus rules the 11th ✓ (11th cusp Taurus); Venus Taurus H10 ✓; Venus trine Saturn ✓; Venus opposition Pluto ✓. PASS
- (b) if the problem is distance, steady repeated effort mends it; if it is score-keeping or control, holding on is possession → decides whether it is worth saving. PASS
- (c) '?' positions (slip index) [3], last slip 3: exactly one question, in the last slip. PASS
- (d) unanchored sentences: 0 (the "standing call or a regular meal" sentence answers the question: how to mend it). PASS
- (e) done.chartRefs = [{"kind": "planet", "body": "Venus"}, {"kind": "aspect", "bodyA": "Venus", "type": "trine", "bodyB": "Saturn"}, {"kind": "aspect", "bodyA": "Venus", "type": "opposition", "bodyB": "Pluto"}]. PASS

### Run 2 · Q1 — "Should I tell him how I feel?"

Frames: bubble@9906, bubble@10455, bubble@10958, done@15715; no delta holds a newline: True. Slips 4, sentences per slip [2, 2, 2, 2].

> I'm your Venus in Taurus in the tenth house, and I lean towards yes, because I trust feelings that are said out loud more than ones kept quiet. Weigh that, since I would always rather you be known than left waiting.
>
> Your Venus opposite Pluto is what makes this hard, because it wants to be sure of his answer before you risk anything. That is control passing itself off as caution, and it can keep you going round in circles for months.
>
> Your Mars in Aries sits on your Midheaven, so when you finally speak, you tend to say everything plainly and all at once. Say one true, specific thing, and then give him room to answer at his own pace.
>
> Your Moon in Pisces in the eighth house will fill his silences with meanings he may never have put there. So tell me, what has he actually done, not just said, that makes you think he'd want to hear it?

- (a) Venus Taurus H10 ✓; Venus opposite Pluto ✓; Mars Aries on the Midheaven ✓; Moon Pisces H8 ✓. PASS
- (b) the need to be sure first keeps them circling for months → say one true, specific thing and give him room. PASS
- (c) '?' positions (slip index) [3], last slip 3: exactly one question, in the last slip. PASS
- (d) unanchored sentences: 0. PASS
- (e) done.chartRefs = [{"kind": "planet", "body": "Venus"}, {"kind": "aspect", "bodyA": "Venus", "type": "opposition", "bodyB": "Pluto"}, {"kind": "planet", "body": "Mars"}, {"kind": "planet", "body": "Moon"}]. PASS

### Run 2 · Q2 — "Why do I always pick people who pull away?"

Frames: bubble@9737, bubble@10649, bubble@11171, done@16962; no delta holds a newline: True. Slips 4, sentences per slip [2, 2, 2, 1].

> Your Saturn in Capricorn sits on your descendant, the point that shows what you look for in a partner. That's why guarded, self-contained people strike you as serious and worth earning, while warm, easy ones can seem too light to trust.
>
> Your Venus opposite Pluto is the hook, because someone who pulls away gives you something to hold on to and win back. I'm your Venus in Taurus, and I confess I can mistake how hard I'm gripping for how much I care, so weigh that in my reading too.
>
> Your Moon in Pisces in the eighth house fills the gap he leaves with your own longing. That's how his distance ends up feeling more intimate to you than closeness would.
>
> When someone last turned toward you steadily and without any struggle, what did you feel in your body, relief or boredom?

- (a) Saturn Capricorn on the Descendant ✓; Venus opposite Pluto ✓; Venus Taurus ✓; Moon Pisces H8 ✓. PASS
- (b) guarded people read as serious, warm ones as too light; his distance feels more intimate than closeness → why they pick them. PASS
- (c) '?' positions (slip index) [3], last slip 3: exactly one question, in the last slip. PASS
- (d) unanchored sentences: 0. PASS
- (e) done.chartRefs = [{"kind": "planet", "body": "Saturn"}, {"kind": "aspect", "bodyA": "Saturn", "type": "opposition", "bodyB": "Ascendant"}, {"kind": "aspect", "bodyA": "Venus", "type": "opposition", "bodyB": "Pluto"}, {"kind": "planet", "body": "Venus"}, {"kind": "planet", "body": "Moon"}]. PASS

### Run 2 · Q3 — "Is this friendship worth saving?"

Frames: bubble@9230, bubble@10082, bubble@10733, done@15411; no delta holds a newline: True. Slips 4, sentences per slip [2, 2, 2, 1].

> Your house of friends opens in Taurus, and I rule it: your Venus in Taurus in the tenth house. So friendships are my territory, and I judge them by whether they have held weight over the years, which gives me a bias toward keeping old things.
>
> Your Sun and Mercury in Gemini sit in that house of friends, because for you a friendship lives on talk. When the talk thins, the whole bond feels like it's fading, even when it has only gone quiet.
>
> Your Venus opposite Pluto can turn saving into gripping, because letting a bond change feels to me like losing it. Here saving it may mean letting it become smaller or different, and not trying to get back exactly what it was.
>
> What happened between you: did one of you hurt the other, or did you both just stop reaching out?

- (a) 11th cusp Taurus ruled by Venus ✓; Venus Taurus H10 ✓; Sun and Mercury Gemini in the 11th ✓ (both H11); Venus opposite Pluto ✓. PASS
- (b) the bond may only have gone quiet (talk thinned), and saving it may mean letting it become smaller → whether it is worth saving. PASS
- (c) '?' positions (slip index) [3], last slip 3: exactly one question, in the last slip. PASS
- (d) unanchored sentences: 0. PASS
- (e) done.chartRefs = [{"kind": "planet", "body": "Venus"}, {"kind": "planet", "body": "Sun"}, {"kind": "planet", "body": "Mercury"}, {"kind": "aspect", "bodyA": "Venus", "type": "opposition", "bodyB": "Pluto"}]. PASS

## A5 — zh (REAL APP)

Switched to 中 (`html lang=zh-CN`), asked "我应该告诉他我的感受吗？". Frames: bubble@9351, bubble@10052, bubble@11253, done@16458.

> 我是你的金星，在金牛座第十宫，住在自己家里。所以我先看的是这份心意稳不稳，敢不敢摆到明处；你会问这句话，说明它已经在你心里放了一阵子了。
>
> 我和你的冥王星对冲，所以我也得说出自己的偏向：你喜欢一个人时容易攥得太紧，想先确定自己不会输才开口。一直拖着不说，其实也是想把结局握在手里。
>
> 你的双鱼月亮在第八宫，和我六合，感受深，也藏不住，憋久了会漏出来，变成试探或者忽冷忽热，而不是一句清楚的话。所以我倾向于让你说，用金牛的方式说：简单，具体，不逼他当场回答。
>
> 你想告诉他的，是“我喜欢你”，还是“你得给我一个答案”？

- 4 Chinese slips, each ending in 。 or ？ (。 。 。 ？); sentences per slip 2, 2, 2, 1 (≤ 3). One question, in the last slip.
- Chart claims: Venus Taurus H10 at home ✓; Venus opposition Pluto ✓; Moon Pisces H8 ✓; Moon sextile Venus ✓. Chips 金星 · 金星冲冥王星 · 月亮 · 月亮六合金星. PASS.

## Result
All 6 English replies pass (a)–(e) and every chart claim was verified. A5
passes. A2 is now PASS on the real app. The mechanical '?' count put
exactly one question in each reply, always in the last slip, in 6/6
English replies and 1/1 zh reply.

## Teardown
Stopped my backend (8002), Vite (5175) and Chrome (9232). `lsof` on the
three ports shows nothing. The scratch env and the Chrome profile are
deleted, and all scratch stayed under `scratchpad/dw9/`. The remote
Postgres was never contacted.

Transition: implementing (cycle 1) → validating PASS → the coordinator
re-runs accepting.
