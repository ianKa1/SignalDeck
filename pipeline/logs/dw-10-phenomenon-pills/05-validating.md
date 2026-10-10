# dw-10-phenomenon-pills — 05 validating (2026-09-29)

Plan step 10. Branch `feature/dw-10-phenomenon-pills` at `2068e5e`. Cycles used: 0 (no trip back to implementing).

## Suites
- `npm run server:test` → `1339 passed, 50 skipped, 1 warning in 112.68s`.
- `npm test` → app-native `Test Suites: 90 passed, 90 total; Tests: 1069 passed` (architecture, colour, text-variant guards included); web-divination `Test Files 26 passed; Tests 270 passed`.
- `npm run typecheck` → `tsc --noEmit` clean in app-native and web-divination.

## Real app
- Backend: `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5173 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8000` (background); `/api/health` → `{"status":"ok","db":"ok","ephemeris":"ok"}`.
- Web: `npm run web` → :5173 → 200.
- Driven with the Claude-in-Chrome tools. The browser held an old profile with `time: null` and an old Venus transcript; both were removed from localStorage (divination + birthData keys only), then birth data F was entered through the form: 1990-06-15, 08:30, China, Beijing → "Cast the chart". Placements table showed Venus Taurus H10, Moon Pisces H8, Mars Aries H9, AC Cancer.
- Browser zone: `America/New_York` (the device zone core sends as `currentTimezone`).

`POST /api/chart` for F (the curl used for fact checks): Venus Taurus 10, Mars Aries 9, Saturn Capricorn 6, Pluto Scorpio 4, AC Cancer; aspects include Moon sextile Venus, Venus trine Saturn, Venus opposition Pluto, Saturn opposition Ascendant.

### R1 — Venus, en, "Why do I keep choosing people who pull away?"
Stored text (KV `astrology.divination.transcript.v1.venus`):
> I'm your ⟦placement:Venus|Taurus|10⟧: I love slowly and I hold on hard, so someone who drifts away gives me something to keep reaching for.
>
> Your ⟦aspect:Venus|opposition|Pluto⟧ is behind that grip, because a person who stays gives you nothing to win back, while a person who pulls away makes the wanting all-or-nothing, and you take that intensity as proof it's real.
>
> Your ⟦aspect:Saturn|opposition|Ascendant⟧ adds a taste for guarded, hard-to-reach partners, because their reserve looks like seriousness to you. You end up valuing people for what they make you earn instead of what they freely give.
>
> When someone shows up for you easily and stays, what's the first thing you feel, relief or boredom?

Rendered pills (all `BUTTON`, `aria-pressed="false"`, `data-source="natal"`): `♀♉︎10 Venus in Taurus, 10th house`; `♀☍♇ Venus opposite Pluto` (`data-tone="tense"`); `♄☍↑ Saturn opposite Ascendant` (tense). No `⟦` in the letter's textContent; no chip row. `done.chartRefs` = Venus, Venus|opposition|Pluto, Saturn|opposition|Ascendant; the wheel lit them (screenshot shows the two red opposition chords). Every pill fact is in `POST /api/chart` for F. **R1 pass.**

### R2 — Venus, zh, 为什么我总是选择那些会抽身离开的人？
Stored text:
> 我是你的⟦placement:Venus|Taurus|10⟧，爱得慢，也抓得紧。所以一个正在往后退的人，正好给了我一样可以一直伸手去够的东西。
>
> 你的⟦aspect:Venus|opposition|Pluto⟧让这份抓紧变得要么全有、要么全无。因为留下来的人没给你留下什么要赢回来的，抽身的人却把渴望烧到最旺，你就把这份强烈当成了真心的证据。
>
> 你的⟦aspect:Saturn|opposition|Ascendant⟧又让你偏爱那些有所保留、不容易靠近的人，你把他们的距离看成了认真。于是你衡量一个人值多少，看的是他让你付出了多少，而不是他愿意白白给你多少。
>
> 当一个人轻轻松松地出现，又稳稳地留下来，你心里最先冒出来的，是松了一口气，还是觉得无聊？

Labels: `金星落金牛座第十宫`, `金星对分冥王星`, `土星对分上升点`. Tapping the second pill: `aria-pressed="true"`, `svg[data-active]` present, `data-lit` on `Venus|opposition|Pluto`, Venus, Pluto; note (`role="note"`): `金星对分冥王星：两极——两种需求对峙，寻求平衡`. No bracket visible. **R2 pass.**

### Incidental turn (not an R criterion)
A selector miss sent "When will this heavy stretch end?" to Venus instead of Saturn. Venus answered with `roster.timing` behaviour ("I can read your pattern but not its timing … Saturn reads this better") and pills `⟦aspect:Venus|opposition|Pluto⟧`, `⟦aspect:Venus|trine|Saturn⟧`, `⟦aspect:Moon|sextile|Venus⟧` (all in chart), plus a handoff to Saturn. Its "Ask Saturn →" button was then used to move to Saturn.

### R3 — Saturn, en, "When will this heavy stretch end?"
Stored text (KV `…transcript.v1.saturn`):
> The weight you feel is me: ⟦transit:Saturn|conjunction|Mars⟧ runs from April 18 of this year to March 5, 2027. One exact pass is already behind you, on May 14, and two are still ahead, on October 12 and February 5, 2027, so this is still building and not yet easing.
>
> Your ⟦placement:Mars|Aries|9⟧ wants to charge ahead and start things, so this pressure lands on your drive itself. Whatever you push in the next few weeks will move slower than you want, and the days around October 12 will press hardest.
>
> A second weight, ⟦transit:Saturn|square|Neptune⟧, lasts until March 31, 2027, with its last exact pass on March 6. It bears down on the parts of your daily work you have left vague, so by early April 2027 both have let you go, and not before.
>
> Which of your commitments are you pushing hardest right now, and would you still choose it if it took until March?

Rendered: `♄☌♂ Saturn conjunct your Mars · now` (sky, fused), `♂♈︎9 Mars in Aries, 9th house` (natal), `♄□♆ Saturn square your Neptune · now` (sky, tense). Tapping the first: note `Saturn conjunct your Mars: fusion — two drives act as one, amplifying each other`, `data-lit` on Mars.

Check against the sky packet at the route's instant (`service.transit_instant("America/New_York", "Asia/Shanghai", now)` = 2026-09-29 16:00 UTC, `sky.sky_context(F, "saturn", …)`):
```
Saturn conjunction MC angle {'from': '2026-05-08', 'to': '2027-03-24'} …
Saturn conjunction Mars planet {'from': '2026-04-18', 'to': '2027-03-05'} ['2026-05-14', '2026-10-12', '2027-02-05']
Saturn opposition IC angle …
Saturn square Neptune planet {'from': '2026-05-15', 'to': '2027-03-31'} ['2026-06-21', '2026-08-30', '2027-03-06']
Saturn quincunx house-3-cusp cusp …
```
Both sky pills name planet-target episodes in the packet (dates in the prose match too). The angle/cusp/quincunx episodes were not tagged. **R3 pass.**

### R4 — no untagged phenomenon clauses
Across R1–R3 (text above) no clause outside a pill puts a body name (en, or zh 太阳…冥王星/上升) with a sign, a house number/ordinal or an aspect word. Body names alone appear outside pills only as characters ("Saturn reads this better" in the incidental turn; "is me" in Saturn's). No failed tag occurred, so no fallback text appears and the backend log has no `tag … failed` WARNING (`grep -n "tag \|WARNING" backend.log` → empty). The failed-tag path (plain text + WARNING) is covered by `test_dw10_t3_a_planted_tag_is_plain_text_and_a_warning`. **R4 pass.**

### R5
`grep -n "divination/tags.py\|lore. namespace\|ASPECT_TONES" CLAUDE.md` → 187 (rule 1), 269 (rule 8), 370 (rule 10, also naming the `pill` event and the exception). **R5 pass.**

Observation (not a failure): in a narrow slip a long pill such as `♄□♆ Saturn square your Neptune · now` wraps onto its own line, because a pill never breaks inside (spec default 7).

Screenshots: `/var/folders/k8/krp4szdj4dv1_9s_51qq52z00000gn/T/claude-chrome-screenshots-doWsbQ/screenshot-1790694984889-9.jpg` (zh, pressed pill), `…/screenshot-1790695119763-10.jpg` (Saturn, sky pills).

Both servers stopped (`lsof` on :8000/:5173 → none); browser tab closed.

Transition: validating → docs-sync.
