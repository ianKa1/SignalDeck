# 09 — validating (dw-3-chart-grounded-reply)

Date: 2026-09-28. Branch `feature/dw-3-chart-grounded-reply` @ `8c0c5fa`. Cycles used: 0.

## Suites (on 8c0c5fa; no code change after them)
- `npm run server:test` → `1035 passed, 50 skipped, 1 warning in 102.66s (0:01:42)`
- root `npm test` → app-native jest `Tests: 1069 passed, 1069 total` (plus the pre-existing "A worker process has failed to exit gracefully" notice); web-divination vitest `Tests 72 passed (72)` (13 files)
- root `npm run typecheck` → 0 `error TS` (both workspaces)
- Boundary plants (step 1, by hand, reverted): a second interpretation import in render.py and the `_restate` import in turn.py each turned `test_divination_borrows_only_the_restate_helper` red (`1 failed`).

## Real app
Setup: backend from the repo root, `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5173 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001` (health `{"status":"ok","db":"ok","ephemeris":"ok"}`); `VITE_API_BASE=http://localhost:8001 npm run web` on :5173; driven with claude-in-chrome. The origin's localStorage was cleared first (it held a dw-2 run's state). Birth entered through the form: 1990-06-15, 08:30, China → Beijing (the city index gives 39.9075 / 116.3972, GeoNames, not the spec's 39.9042 / 116.4074; the chart is the same where it matters). Placements panel: Sun Gemini H11, Moon Pisces H8, Mercury Gemini H11, Venus Taurus H10, Mars Aries H9, Jupiter Cancer H12, Saturn Capricorn 24° H6; rising Cancer (28°05′).

`read_network_requests` lists URLs and statuses only (no bodies), so request bodies were captured by wrapping `window.fetch` in the page. Core's chart service and the web StreamPost adapter both call the global `fetch` at call time.

- **A1 — PASS.** The captured `POST /api/divination/turn` body had keys `persona, transcript, message, lang, birthData`, with `birthData` = `{"date":"1990-06-15","time":"08:30","location":{"name":"Beijing","latitude":39.9075,"longitude":116.3972},"timezone":"Asia/Shanghai","schemaVersion":1}`. `JSON.stringify` of it equals the captured `POST /api/chart` body byte for byte (`equalToChartBody: true`). The backend log shows every turn answered `200`.
- **A2 — PASS.** "Why do I keep falling for people who are hard to reach?" Samples every 500 ms: listening from 1.0 s, caret with text length 74 at 9.0 s, then 412 → 723 → 957 at 12.0 s, then done at about 17 s (mood "candid"). Claims checked against the chart:
  - "Saturn sits almost on your descendant": Saturn is at Capricorn 24°04′ and the Descendant is at Capricorn 28°05′ (opposite the Cancer 28°05′ Ascendant). The chart has `Saturn|opposition|Ascendant`. ✓
  - "that descendant is in Capricorn" ✓ (rising Cancer).
  - "Your Venus also stands opposite Pluto" ✓ (`Venus|opposition|Pluto`).
  - Why it bears on the question: Saturn on the descendant means "drawn to people who seem guarded, serious and a little out of reach", and Venus–Pluto "makes distance feel like depth". ✓
  - No invented placement. 2 paragraphs, no markdown.
- **A3 — PASS.** The chips were absent in every sample while the caret showed (`chips: 0`) and present only after done (`chips: 1` list). The list's aria-label and eyebrow both read "read in your chart". Chips, in order: `♄ Saturn` / `♄ ☍ ↑ Saturn–Ascendant` (aria "Saturn opposition Ascendant") / `♀ ☍ ♇ Venus–Pluto` (aria "Venus opposition Pluto").
  - DOM lookups: `[data-planet="Saturn"]` true, `[data-aspect-key="Saturn|opposition|Ascendant"]` true, `[data-aspect-key="Venus|opposition|Pluto"]` true.
  - Saturn and Venus–Pluto are both named in the reply.
  - Chip `borderTopColor` is `rgba(211, 169, 79, 0.28)`, which equals `--line`; the border is 1px with a 2px radius.
  - Letter children, in order: `chat__eyebrow, chat__prose, chat__refs, chat__mood`.
- **A4 — PASS.** After a reload, the same reply showed with the same three chips (`♄ Saturn / ♄ ☍ ↑ Saturn–Ascendant / ♀ ☍ ♇ Venus–Pluto`) and the mood "candid".
- **A5 — PASS.** Switched to 中 and asked 「我在感情里为什么总是想要安全感，又会被强烈的人吸引？」. The request had `lang: "zh"`, carried birthData, and had 2 transcript entries. The reply came back in Chinese, 2 paragraphs, mood 坦率. Claims: 金星在金牛座、第十宫、"在自己的家里" (domicile ✓), 金星和冥王星对冲 ✓, 月亮在双鱼座第八宫 ✓, 月亮和冥王星三分相 ✓ (`Moon|trine|Pluto`). Chips, labelled 星盘所见: `♀ 金星 / ♀ ☍ ♇ 金星–冥王星 [aria 金星冲冥王星] / ♇ 冥王星 / ☽ 月亮 / ☽ △ ♇ 月亮–冥王星 [aria 月亮拱冥王星]`. I looked at a screenshot: the seals wrap onto two rows under the prose, above "— 坦率".
- **A6 — PASS.** Fresh profile (all localStorage cleared, no birth data), EN, asked "What does my Venus sign say about me?". The request body had `birthData: null` (key present) and an empty transcript. The reply opens "I should tell you plainly that I haven't read your chart…", names no sign, and has no chips (`lists=0`).
- **A7 — PASS.** Entered the fixture with "I don't know my birth time" checked (saved `time: null`; the Big Three shows only ☉ Gemini · ☽ Pisces). Asked "What kind of partnership suits me, and what should I look for in a partner?". The request `birthData.time` was null. The reply says "Your birth time is unknown, so I can't read your house of partnership", then uses Venus in Taurus ("my own sign"), Venus opposite Pluto, and Moon in Pisces, all correct. A regex for an ordinal house, rising, ascendant or descendant found none (`null`). Chips: `♀ Venus / ♀ ☍ ♇ Venus–Pluto / ☽ Moon`, and every one has a matching `data-planet` / `data-aspect-key` element.

## Exercised on the real app vs tests only
- Real app: A1, A2, A3, A4, A5, A6, A7 (all seven).
- Tests only: S1–S11 (pytest with fake `stream_turn`/`generate_sections` and a real Swiss Ephemeris chart), C1–C3 (vitest through the core barrels, plus jest guards), W1–W4 (vitest with a fake StreamPost). Several of these also showed up on the real app: S1/S5 grounding (the replies cite real placements, and every returned ref was in the catalogue); S8 time unknown; S2 no-chart; W2 zh chips; W3 remount.
- Not exercised against a paid provider: whether it enforces the `chartRefs` enum. This run used claude-cli only, by design.

## Observations
- Every real ref returned by the claude-cli side read was a valid catalogue id, and every chip resolved to a wheel element. `to_wire_refs` never had to drop anything that was visible.
- The form's Beijing coordinates come from the GeoNames city index (39.9075/116.3972), not the spec's rounded fixture. S-tests use the spec's values, and the placements agree.

## Servers stopped
Backend :8001 and Vite :5173 were killed (exit 143) and the Chrome tab was closed (group auto-removed). `lsof` shows 8001 and 5173 free, and 8000 still pid 34607 (the other checkout). An unrelated Vite on :5180 from `/Users/kaimao/Projects/astrology-run` was left untouched.

## Transition
validating → docs-sync.
