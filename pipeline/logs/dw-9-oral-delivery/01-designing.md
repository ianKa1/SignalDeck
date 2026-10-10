# dw-9-oral-delivery — 01 designing

2026-09-28 · stage worker (coordinator dispatch) · base b308a92, wave-2 member 2 of 3 (dw-7, dw-9, dw-12)

## Reads
- CLAUDE.md from disk (rules 3, 10 incl. the divination paragraph at :313-335, 14's streamed-turn exception at :421).
- PIPELINE.md: Skills per stage, the pipeline-mode overrides, Epic files, Spec requirements, Auto spec review, Parallel waves.
- QUEUE.md: the ROUND 2 comment and the dw-9 entry (plus the dw-10 entry, to stay off call B).
- The epic `pipeline/epics/divination-web.md` in full.
- DECISIONS.md: 3105 (streamed-turn ruling), 3228/3242 (dw-2: the three-paragraph limit, the 4-paragraph A2 failure, D9 `lang.zh`), 3405-3424 (round 2, dw-7 spec and plan: chart-less golden fixtures, the risk that a dw-9 `venus.txt`/`lang.*` edit forces a re-record).
- The dw-7 spec (its shared-file footprint).
- The memory note `reading-quality-bar.md` (the leak lesson: no quotable sample nouns in prompts).
- Code:
  - server: `divination/turn.py` (whole), `render.py` (whole), `personas/venus.txt`, `venus-dice.txt`, `llm.py` `stream_turn` :889 and the CLI stream argv :744; `models.py` :323-435; `main.py` turn route :421; `test_boundaries.py` (divination pins); `test_divination_turn.py` (fakes, S1); `test_divination_render.py` (the `_chart_json` tail helper).
  - core: `types.ts`, `turn.ts`, `transcript.ts`, `index.ts`, `session-log.ts` :40-114.
  - web: `useChat.ts`, `ChatPanel.tsx`, `chat.css` (the header, the log, reduced motion), the `chat` i18n namespace in en.ts, `log/SessionTranscript.tsx`.

## Skills (in order)
1. `frontend-design`: the slip register (paper slips under one ♀ eyebrow, a `--venus` left rule, no new tokens or fonts), a ghost slip with the existing ✦ stars for the typing pause, and a quiet small-caps "go deeper ⌄" chip.
2. `feature-spec` (pipeline mode): Goal, Non-goals, Decided defaults (10), Acceptance Criteria.
3. `architecture-designer` (pipeline mode): reuse table, module map, contracts, wire delta, forbidden edges, guard and CLAUDE.md amendments, shared files. No Migration Steps.

## Choices
- **Structural length:** the new pure `divination/bubbles.py` segmenter.
  - A line break ends a bubble. A sentence cap re-bubbles, and a bubble cap stops the turn and cancels the provider.
  - Budgets: chat/cast 4×3, deeper 6×4.
  - Justified against the ruling: the segmenter reads typography only and yields no field.
  - A model-emitted delimiter was rejected, because it is protocol inside the prose channel, which is call-B territory.
  - There is no minimum on the server; the prompt asks for 2–4 bubbles.
- **Event:** `bubble {index≥1}` sent only between bubbles, so single-paragraph streams (and the dw-2/3/5 tests) are byte-identical. `delta` never carries `\n`.
- **Storage:** one persona entry per turn, with `text` = bubbles joined by `\n\n`, a lossless encoding since bubbles hold no newline. Chips, activation, dice, the summary and the log reader need no change. There is no new persona-entry field.
- **Whitespace:** passed through (so existing tests stay unchanged), except whitespace held at a filled sentence cap.
- **Depth:** the `depth.chart`/`depth.none` fragments plus `shape.chat`/`shape.deeper`. The old length lines come out of `venus.txt`, `venus-dice.txt` and `lang.zh`. The fragments go directly after the persona base, which keeps the dw-3 `_chart_json` tail helper valid and composes with dw-7's `self.*`.
  - Honest split: tests prove presence, order and caps. Depth is judged on the real app with a rubric, plus the structural proxy that `done.chartRefs` is non-empty.
- **Go deeper:** `action:"deeper"` on the existing route. The transcript must end on a persona entry (else 422). The client's localized ask is the message. The user entry carries device-only `deeper:true`; Retry re-sends it. No dice roll. The chip is hidden under a deeper answer.
- **Pause:** `clamp(8 ms × chars of the finished bubble, 450, 1100)`, queued per bubble. `done` is applied after the drain; Stop and error flush. Reduced motion keeps the pause, with static stars and no rise. The pacer is a pure web module with an injected timer.
- **main.py and llm.py untouched:** the streamed-turn exception pin is unchanged.

## Word counts (wc -w)
- Goal + Non-goals + Decided defaults (with the title): 1,531 (~1,500 budget; trimmed from 1,583)
- Architecture: 1,510
- Acceptance Criteria: 1,152 (budget-exempt)

## Shared files touched (landing surface; dw-9 lands after dw-7)
- `render.py`: the `system_prompt` insertion point after the persona base (dw-7 too), the new kwarg, and the fragments after dw-7's.
- `turn.py`: separate hunks.
- `ChatPanel.tsx`: dw-9 owns Prose/Entry, pending and the chip; dw-7 owns the header and greeting.
- `i18n/en.ts` and `zh.ts`: dw-9 adds keys inside `chat`; dw-7 adds a `persona` namespace.
- `models.py`: an in-place `DivinationTurnRequest` edit, while the others append at EOF.
- dw-7's chart-less golden fixtures MUST be re-recorded at dw-9's landing.
- Not touched: main.py, llm.py, store, summary, generation, migrations, log/, theme/.

## Transition
designing → spec-review
