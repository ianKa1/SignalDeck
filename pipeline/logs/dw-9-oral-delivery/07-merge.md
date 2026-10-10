# 07 merge — dw-9-oral-delivery × feature/divination_web (dw-7 landed, d2aaf12)

In the worktree: `git merge feature/divination_web`. The conflicts were in
CLAUDE.md, docs/ARCHITECTURE.md (7 hunks), server/app/divination/render.py,
turn.py, server/tests/test_divination_render.py,
web-divination/src/chat/ChatPanel.tsx and web-divination/vite.config.ts.
models.py, test_boundaries.py, en.ts and zh.ts auto-merged.

## Resolutions (both features kept)
- `render.py`
  - Docstring: both paragraphs. dw-7's text now says "between the depth
    rule and the chart section".
  - Declarations: dw-9's shape/depth, then dw-7's self.*.
  - `system_prompt(persona, lang, ctx=None, cast=None, action="chat",
    voice=None)` builds persona → shape → depth → self section → chart →
    dice → lang.
  - `turn_messages(..., action="chat", voice=None)` passes both params by
    keyword.
  - Docstring fix: dw-7's "without a chart byte-identical to dw-6's" is no
    longer true once dw-9's fragments are in. It now reads "the chart-less
    prompt is pinned by the golden fixtures".
- `turn.py`: dw-7's `turn_events(request, person, voice=None)` plus dw-9's
  loop. It calls `turn_messages(..., ctx, cast, action, voice=voice)`.
- `test_divination_render.py`:
  - The fragment-set pin is the union (dw-9's four fragments + dw-7's
    self.read/self.marker/self.voice).
  - New `test_merged_order_shape_and_depth_before_the_mirror` asserts
    persona < shape.chat < depth.chart < self.read < self.marker <
    self.voice < chart.read < lang.en.
- `ChatPanel.tsx`: both header comments. `useChat` destructuring keeps
  `canDeepen`, and dw-7's `usePersona` is kept. dw-7's header/greeting and
  voice-intro letter are unchanged (letter prose). dw-9's slips, pacer and
  chip are unchanged.
- `vite.config.ts`: `css.include: [/log\.css/, /persona\.css/, /chat\.css/]`.
- CLAUDE.md rule 10: dw-7's persona.py sentence, then dw-9's bubbles
  sentence.
- ARCHITECTURE.md:
  - Every hunk merges both descriptions: the chat tree, the fragment list,
    `system_prompt`'s merged order, the css include, the i18n namespaces,
    and the dw-7 then dw-9 index entries.
  - The persona-header paragraph is kept.
  - The vitest count is updated to the merged 22 files / 212 tests.

## Golden fixtures re-recorded
The files `server/tests/fixtures/divination_chartless_{en,zh}.txt` were
written from the MERGED `render.system_prompt("venus", lang)`. Their diff
against feature/divination_web
(`07-merge-evidence/fixture.diff`) is EXACTLY:
- both files: `venus.txt`'s two removed lines (the 60–180-word line and the
  optional question-back line);
- both files: `shape.chat` and `depth.none` inserted after the persona
  base, before `chart.none`;
- zh only: `lang.zh` loses "用中文回答时同样最多三段…不要单独成段。".
Nothing else changed, so no merge error. Merge commit `8881478` (parents 68485b0, d2aaf12). The merged FINGERPRINT is
`4af28014d87bec41`.

## Suites (after resolution)
- Server `pytest -q`: `1202 passed, 50 skipped, 1 warning in 114.05s`.
- `npm run typecheck`: clean, 0 `error TS`.
- `npm test`: app-native `90 passed` suites / `1069 passed` tests;
  web-divination `22 passed` files / `212 passed` tests.
- Step 2/3 checks: the divination render/turn/bubbles/persona/dice/boundaries
  files gave 205 passed before the order test was added; render alone gives
  34 passed with it. `git diff feature/divination_web -- server/app/main.py
  server/app/llm.py` is empty.
- Step 6 checks: `npx vitest run src/chat src/log src/i18n.test.ts` gives
  `11 passed` files / `165 passed` tests. `git diff feature/divination_web
  --stat -- web-divination/src/theme web-divination/src/log` is empty.

## Real-app smoke (SQLite only)
- Scratch env under `scratchpad/dw9/` with no DATABASE_URL line (0 left).
  The backend ran with `DATABASE_URL=` on 8002 and `ANALYSIS_LLM=claude-cli`.
  `/api/health` came FIRST and returned
  `{"status":"ok","db":"unconfigured","ephemeris":"ok"}`.
- Vite on 5175, headless Chrome on 9232 with the profile at
  `scratchpad/dw9/chrome-profile`, chart A seeded.
- Header: "Your Venus", "♉︎ in Taurus · 10th house · at home", then
  "finding her voice…".
- "Should I tell him how I feel?"
  - The reply came as 4 slips, with bubble events at 11484/11983/12484 ms
    and done at 18328 ms.
  - A ghost slip showed for 3362 ms (`ghost-m1.png`).
  - The reply carries dw-7's mirror line ("I'm your Venus in Taurus in the
    tenth house, opposite Pluto, though, so weigh my advice…") and dw-9's
    one closing question.
  - Chips: Venus, Venus opposition Pluto, Moon.
- Pressing the "Venus opposition Pluto" chip set `aria-pressed=true` and put
  `data-lit` on 5 wheel elements.
- Go deeper sent `action:"deeper"`. The reply came as 6 slips (bubbles 1–5)
  with 6 refs, and no chip showed under the deeper reply
  (`smoke-deeper.png`).
- Stopped backend, Vite and Chrome. `lsof` on 8002/5175/9232 shows nothing.
  The scratch env and the Chrome profile are deleted. The remote Postgres
  was never contacted.
