# dw-10-phenomenon-pills — 07 accepting (fresh-context acceptance check)

Branch `feature/dw-10-phenomenon-pills` @ 8ce604c, clean tree. Checked the
criteria list (S1–S8, T1–T9, C1–C3, W1–W7, R1–R5) only. No source files
modified; the one temporary test file used for independent turn checks was
created under server/tests and deleted in the same command.

OVERALL: PASS

## Suites run

- `cd server && conda run -n astrology pytest -q` → **1339 passed, 50 skipped** (112 s).
- `conda run -n astrology pytest tests/test_divination_tags.py tests/test_divination_turn.py tests/test_divination_render.py tests/test_boundaries.py -v` → 172 passed, 0 failed.
- `npm test` (root) → app-native jest **1069/1069 passed** (architecture, color-guard,
  text-variant-guard, text-variants, text-variant-rulings all PASS); web-divination vitest
  **26 files / 270 tests passed**. EXIT 0.
- `npm run typecheck` → EXIT 0.

## Server — tags

Independent script (scratchpad `indep_tags.py`, real Swiss-Ephemeris chart for F via `natal_report`):

- **S1 PASS** — `⟦aspect:Venus|trine|Saturn⟧` → `[pill {aspect, Venus, trine, Saturn}]`, no failures; `⟦aspect:venus|sextile|moon⟧` → `{bodyA:"Moon", type:"sextile", bodyB:"Venus"}` (chart order, canonical case).
- **S2 PASS** — `⟦aspect:Venus|trine|Mars⟧` → `[text "Venus trine Mars"]`, failures `[('aspect','not-in-chart')]`.
- **S3 PASS** — Venus|Taurus|10 → pill house 10; Venus|Taurus → house None; Venus|Gemini → not-in-chart; Venus|Taurus|7 → not-in-chart; Ascendant|Cancer → pill. Time unknown: Venus|Taurus|10 → time-unknown, Ascendant|Cancer → time-unknown, Venus|Taurus → pill.
- **S4 PASS** — `transit:Saturn|square|Mars` with packet → transit pill; without packet → `no-sky`; `transit:Saturn|trine|Midheaven` (angle target) → `not-in-sky`.
- **S5 PASS** — roll {Pluto, Leo, 7}: planet|Pluto → `Pluto`, sign|leo → `Leo`, house|7 → int 7; planet|Mars → not-rolled; with no roll all three → `no-roll`.
- **S6 PASS** — unclosed at close → `a aspect:Venus|tri`; line break → inner chars incl. newline, no bracket; >64 chars → inner text; `⟦mood:tender⟧` → `mood:tender`; `⟦aspect:Venus|trine⟧` → `aspect:Venus|trine`; nested opener → `aspect:Ve` then the inner valid tag; stray `⟧` in `x ⟧ y` dropped → `x  y`.
- **S7 PASS** — 2 mixed corpora (valid/failed/malformed/stray/zh/newline) × 3000 random splits each + per-character split: 0 mismatches, no `⟦`/`⟧` in any text item. (Suite's own `test_s7_*` also pass.)
- **S8 PASS** — tags.py imports: `dataclasses`, `app.chart.points`, `.persona` only. `test_tags_is_pure` has planted self-checks (logging, re, datetime, `from app import llm`, `.sky`, `from . import render`, `time.time`) and passes; `test_only_phenomenon_tags_are_read_from_the_reply` pins `tags.KINDS == ("placement","aspect","transit","dice")`; confirmed value at runtime.

## Server — turn

Tests read and run; plus an independent temp test (5 fake-provider replies over TestClient):

- **T1 PASS** — single-chunk `Your ⟦aspect:Venus|trine|Saturn⟧ steadies you.` → exactly `delta "Your "`, `pill {aspect Venus trine Saturn}`, `delta " steadies you."`, `done{chartRefs:[{kind:aspect,Venus,trine,Saturn}]}` (independent) and the split-chunk suite test passes.
- **T2 PASS** — `test_dw10_t2_text_before_an_open_tag_is_sent_at_once`: provider yields `Your ⟦asp` then blocks on an Event; first non-comment frame == `delta "Your "` asserted while `release` not set.
- **T3 PASS** — `test_dw10_t3_…`: no pill frame, delta has `Venus trine Mars`, exactly one WARNING from `app.divination.turn` containing `aspect` and `not-in-chart`, and none of 1990/06-15/39.9/116.4/Beijing/Shanghai in message or args. Independent run shows `delta "Venus trine Mars pulls."`.
- **T4 PASS** — `_no_bracket_in_deltas` asserted in T1/T3/T4/T5 tests; independent run of 5 replies (incl. failed transit/dice without ground, unknown kind, unclosed tag) — no delta contains a bracket.
- **T5 PASS** — `A.\n\n⟦aspect…⟧ b.` → `delta, bubble{index:1}, pill, delta, done`; tag-only reply → `pill, done`.
- **T6 PASS** — `test_dw10_t6_refs_are_the_natal_pills_capped` (8 placements → 6 refs in order), `…_dedupe_in_order_and_skip_non_natal` (aspect + Venus planet; Ascendant skipped, duplicates removed), `…_side_read_refs_are_ignored` ([] despite side read S3_IDS). Independent: placement Venus + Ascendant → `[{planet Venus}]`; no pills with side chartRefs → `[]`; transit/dice pills add nothing (dice test chartRefs == []).
- **T7 PASS** — `test_dw10_t7_side_read_has_no_refs_and_no_catalogue`: schema lacks `chartRefs`, required == [mood, handoff], payload lacks `catalogue`, `side.refs/side.dice/side.sky` not in fragments. Existing dw-2/dw-8 mood/handoff tests pass (full suite green).
- **T8 PASS** — `test_dw10_t8_tag_block_by_ground` (rules+natal with chart; tags.sky in Saturn+sky only, not Venus; tags.dice in cast); `test_dw10_t8_chartless_chat_prompts_match_the_goldens` × 6 personas × en/zh. Goldens `server/tests/fixtures/divination_chartless_*.txt` were last changed in dw-8 (fc38893), not in dw-10.
- **T9 PASS** — `test_handoff_is_never_parsed_from_the_reply` body is byte-identical between bfcd0f7 (pre-dw-10) and HEAD (AST-free regex extraction compare → True); passes; full server suite passes.

## Core

- **C1 PASS** — `web-divination/src/chat/core-pills.test.ts` "streamTurn pill frames (C1)": pill yielded at position; malformed (unknown kind, bad name Chiron, house 13/0, Ascendant with house, dice house as string, quincunx) dropped; bubble after pill accepted. Passing.
- **C2 PASS** — same file (C2): round-trip for placement ±house, Ascendant, aspect, transit, dice planet/sign/house; `splitPills("a ⟦aspect:Venus|trine|Mars⟧ b")` → `["a ", pill, " b"]`; `⟦mood:tender⟧`, `⟦aspect:Venus|trine⟧` stay text. Passing.
- **C3 PASS** — `chart-view-additions.test.ts` asserts the exact table; `grep` finds the only definition at `packages/core/src/chart-view/glyphs.ts:51` (other hits are the barrel export and one consumer); `app-native/src/architecture.test.ts` enumeration gains `'ASPECT_TONES'` (diff vs bfcd0f7) and passes.

## Web

All in `web-divination/src/chat/Pill.test.tsx` (read; all pass):

- **W1 PASS** — one `.chat__slip`, `[data-pill]` with prev sibling `Your ` / next ` steadies you.`, contains ♀ △ ♄, label `Venus trine Saturn`; zh label `金星三分土星`.
- **W2 PASS** — data-source natal/natal/natal/natal/sky/dice, data-tone null/harmonious/tense/fused/tense/null; CSS contains `.chat__pill[data-source='natal|sky|dice']` and `.chat__pill[data-tone='harmonious|tense|fused']`; color-guard PASS.
- **W3 PASS** — button aria-pressed false→true, activation `{refs:[aspect], chip:'1:p0'}`, Venus & Saturn `data-lit`, `role=note` contains `en.lore.aspects.trine`; second pill switches (`1:p1`), pressing again clears activation and note.
- **W4 PASS** — dice sign pill: pressed, activation refs [], note has Leo lore, svg lacks `data-active`; transit Saturn|square|Mars → refs `[{planet Mars}]`, Mars `data-lit`.
- **W5 PASS** — after reload KV contains `⟦aspect:Venus|trine|Saturn⟧`, button pill rendered, no `⟦`/`⟧` in text.
- **W6 PASS** — legacy entry keeps `.chat__refs-list`, pill entry has none; SessionTranscript pill is a SPAN, no button; SummaryCard question renders a SPAN pill `Venus opposite Pluto`.
- **W7 PASS** — `web-divination/src/i18n.test.ts` parity + new pills/lore namespace test pass; `npm test` and `npm run typecheck` EXIT 0 incl. architecture/colour/text-variant guards.

## Real app

Backend: `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5173 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8000` (log in scratchpad `server.log`); `npm run web`. Driven with Chrome (claude-in-chrome). The browser profile already held birth data F from the geocoder: `{"date":"1990-06-15","time":"08:30","location":{"name":"Beijing","latitude":39.9075,"longitude":116.3972},"timezone":"Asia/Shanghai"}` (card shows "1990-06-15 · 08:30 · Beijing (Asia/Shanghai)"); I cleared the old divination transcripts before asking so every reply below is fresh.

Chart for F: `curl -s -X POST localhost:8000/api/chart -d '<the birth data above>'` → Venus Taurus H10, Mars Aries H9, Saturn Capricorn H6, AC Cancer; aspects include Venus opposition Pluto, Saturn opposition Ascendant, Venus trine Saturn.

- **R1 PASS** — Venus, en, "Why do I keep choosing people who pull away?". Rendered 3 slips, 3 natal button pills: `Venus in Taurus, 10th house`, `Venus opposite Pluto` (tone tense), `Saturn opposite Ascendant` (tone tense). All three are in /api/chart (Venus Taurus 10; `Venus|opposition|Pluto`; `Saturn|opposition|Ascendant`). No bracket visible.
- **R2 PASS** — switched to 中, same question (fresh Venus transcript). Labels: `金星落金牛座第十宫`, `土星对分上升点`, `金星对分冥王星`. Clicked (real mouse click) `金星对分冥王星`: aria-pressed true, wheel `[data-planet][data-lit]` = Venus, Pluto (screenshot showed the red chord), note `金星对分冥王星：两极——两种需求对峙，寻求平衡`. Also pressing `土星对分上升点` lit Saturn + the aspect path with note `土星对分上升点：两极——…`.
- **R3 PASS** — Saturn, en, "When will this heavy stretch end?". Sky pills: `Saturn conjunct your Mars` (fused), `Saturn square your Neptune` (tense); natal pills `Mars in Aries, 9th house`, `Saturn in Capricorn, 6th house`. Sky packet recomputed with `sky.sky_context(person,"saturn",transit_instant("America/New_York","Asia/Shanghai",now),"America/New_York")` (browser zone America/New_York is sent as currentTimezone by core `deviceTimezone()`; instant 2026-09-29 16:00 UTC): episodes Saturn conjunction MC (angle), **Saturn conjunction Mars (planet, 2026-04-18→2027-03-05)**, Saturn opposition IC (angle), **Saturn square Neptune (planet, 2026-05-15→2027-03-31)**, Saturn quincunx house-3-cusp. Both sky pills match planet episodes, and the reply's dates (lets go March 5, 2027; ends March 31, 2027) agree with the windows.
- **R4 PASS** — scanned the three stored replies with pill tokens replaced: zero body names (en list + 太阳…冥王星/上升) outside pills, so no clause pairs a body with a sign/house/aspect word; persona self-references ("I'm your ⟦placement:Venus|Taurus|10⟧", "我是你的⟦placement:Venus|Taurus|10⟧", "I'm your ⟦placement:Saturn|Capricorn|6⟧") are inside pills. No failed tags occurred and `server.log` has no WARNING lines (3 × `POST /api/divination/turn 200`). Rendered text of all three replies:

  R1 (Venus, en): I'm your [Venus in Taurus, 10th house], so I love slowly and I hold on for good. Someone who stays a little out of reach gives me something to keep reaching for, and I can confuse that reaching with devotion. / Your [Venus opposite Pluto] is behind the pull. When someone withdraws, your wanting turns all-or-nothing, and that intensity feels like depth to you. Someone who stays close gives that grip nothing to do, so they can seem flat to you even when they're offering more. / Your [Saturn opposite Ascendant] puts a cool, guarded figure exactly where you look for a partner, so reserved people strike you as serious and worth earning. The price is that you keep trying out for love instead of letting yourself be met, so tell me honestly: the last time one of them finally turned toward you, did you stay, or did you lose interest?

  R2 (Venus, zh): 我是你的[金星落金牛座第十宫]，天生先看什么东西值得长久留住。所以你问为什么总选会退开的人，我会先把它当成你在给什么东西定价，这是我的偏向，你自己掂量。/ 你的[土星对分上升点]让你在对面那个人身上找一种克制、难靠近、得慢慢赢来的分量。对方往后退一步，在你眼里先看到的往往不是冷淡，而是稳重和值得。/ 我自己身上的[金星对分冥王星]，会在对方退开的那一刻把你往里拽，让你想弄清楚、想抓牢、想留住。于是对方的退开，反倒被你当成了这份感情够深的证据。/ 想想最近让你放不下的那个人，你第一次真正心动，是在对方靠近你的时候，还是在对方第一次退开的时候？

  R3 (Saturn, en): Not soon, but there is a date. The heaviest part is [Saturn conjunct your Mars], and it isn't over: it was first exact on May 14, returns on October 12, and comes a last time on February 5, 2027, and the whole stretch lets go on March 5, 2027. / Running beside it is [Saturn square your Neptune], which was exact on June 21 and August 30, comes once more on March 6, 2027, and ends on March 31, 2027. So the end of March is your real release, not the end of this year. / Your [Mars in Aries, 9th house] wants to break through by force, and that is exactly where this weight lands. If you push harder before the October 12 pass, you will wear yourself down rather than move the wall. / I'm your [Saturn in Capricorn, 6th house], so I read this through daily work first, and I admit that bias. What decides how you come out in March is the one routine you can keep every week until then, not how much you can bear this month. Which commitment are you carrying now that you would still choose if you knew it had to hold until the end of March?

- **R5 PASS** — `grep` CLAUDE.md: rule 10 (lines 369–380) names `divination/tags.py`, "A passing tag becomes a `pill` event", and "the ONE exception to 'side fields are never parsed from the prose'"; rule 8 (lines 267–272) names the web-divination `lore` namespace; rule 1 (lines 186–188) enumeration names `ASPECT_TONES`.

Servers stopped (ports 8000/5173 free) and the Chrome tab closed.
