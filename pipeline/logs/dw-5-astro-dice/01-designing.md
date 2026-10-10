# dw-5-astro-dice — 01 designing

Stage worker for the coordinator (parallel wave dw-4/dw-5/dw-6, worker #2).
Primary checkout, branch feature/divination_web; nothing committed, no code edited.

## Reads
- CLAUDE.md (rules 10, 14; divination paragraph), pipeline/PIPELINE.md (skills
  per stage, pipeline-mode overrides, epic files, spec requirements, auto spec
  review, parallel waves), QUEUE.md dw-5 entry + epic comment,
  pipeline/epics/divination-web.md (cited; turn grammar already reserves `dice`).
- specs/dw-3-chart-grounded-reply.md (wire), specs/dw-4-wheel-activation.md
  (shared-file surface only).
- Targeted: server/app/divination/{__init__,render,turn}.py, personas/venus.txt,
  models.py (:332–364), main.py turn route (:419–442), dictionary/symbols.py
  (PLANETS :14, SIGNS :27, HOUSES :42), dictionary/__init__.py, prompts.py
  (fingerprint freezes the registry :118), tests/test_boundaries.py
  (divination fence, restate borrow, no-state, synchronous-exception pin),
  tests/test_divination_turn.py (fakes), core divination/{types,turn,transcript,index}.ts,
  core chart/index.ts (SIGNS not on the barrel), chart-view glyphs,
  web chat/{useChat.ts,ChatPanel.tsx,chat.css}, theme/tokens.ts, i18n/en.ts,
  app/App.tsx, app-native/src/architecture.test.ts (G4/G5, barrel liveness).

## Skills (in order)
1. frontend-design — cast button, d12-pentagon dice card inside Venus's letter,
   deterministic face-stepping roll settling 700/900/1100 ms, reduced motion,
   no new token.
2. feature-spec (pipeline mode) — Goal / Non-goals / Decided defaults /
   Acceptance Criteria.
3. architecture-designer (pipeline mode) — Architecture delta only; no
   Migration Steps.

## Key choices
- Cast = `action:"cast"` on the existing turn (default "chat"); roll inside the
  generator after validation; `dice` is the first frame, before keepalives,
  context build and worker; failures after it = `dice`, `error`.
- dice.py: `_RNG = random.SystemRandom()`, `roll()` reads `_RNG` at call time;
  tests monkeypatch `_RNG` with a scripted stub; pin test asserts the unpatched
  type, source-scans for seed/Random(/module-level random calls, 3,600-roll
  coverage. Pin lives in new test_divination_dice.py, not test_boundaries.py.
- Grounding: dice brief asset `personas/venus-dice.txt` (fingerprinted, registered
  in render.py before FINGERPRINT) + dice JSON with dictionary meanings and
  `inYourChart` lookups (natal position of rolled planet, natal planets in the
  rolled sign/house; inHouse null when time unknown).
- Persistence: persona entry stores `dice`, user entry `cast:true`. Dice ARE
  re-sent on persona wire entries; server re-validates (models.py against the
  dictionary keys) and folds a `dice.recall` note into the preceding user
  message. Retry of a failed cast re-rolls.
- Planet die = the ten dictionary PLANETS (no nodes).
- main.py, test_boundaries.py, App.tsx, tokens.ts untouched. Core chart barrel
  gains a SIGNS value export.

## Word counts (wc -w)
- Goal + Non-goals + Decided defaults (incl. header): 1,383
- Architecture: 1,443
- Acceptance Criteria: 1,076 (budget-exempt)

## Shared files touched (wave landing surface)
- with dw-4: web chat/useChat.ts, chat/ChatPanel.tsx, chat/chat.css, ChatPanel.test.tsx.
- with dw-6 (likely): server models.py, divination/render.py, divination/__init__.py,
  core divination/types.ts + index.ts, web i18n/{en,zh}.ts, CLAUDE.md rule 10.
- Not touched: App.tsx, theme/tokens.ts, main.py, test_boundaries.py, llm.py, chart/.

## Transition
designing → spec-review (coordinator writes QUEUE.md / DECISIONS.md).
