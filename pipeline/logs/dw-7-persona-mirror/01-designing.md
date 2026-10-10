# dw-7-persona-mirror · 01 designing (2026-09-28)

Stage worker for the coordinator (wave dw-7 / dw-9 / dw-12, gates serial in the primary checkout). No code edited, nothing committed, QUEUE.md / DECISIONS.md untouched.

## Reads
- CLAUDE.md (disk): rules 9, 10 (divination paragraph), 11, 14.
- PIPELINE.md: Skills per stage, pipeline-mode overrides, Epic files, Spec requirements, Auto spec review, Parallel waves.
- QUEUE.md: the ROUND 2 comment, dw-7, and dw-8/9/10/11/12 (to avoid overlap).
- DECISIONS.md from "2026-09-28 · divination-web round 2" (A/C/D taken as decided defaults).
- epics/divination-web.md, in full.
- Targeted server reads:
  - `divination/render.py`, `turn.py`, `personas/venus.txt`, `summary.py`, `store.py`;
  - `generation.py`;
  - main.py `_person` :145, the turn route :421, the summary route :446, and the 202-with-facts precedent :271-275;
  - models.py divination models :328-437;
  - migrations up to `011_divination_summary.sql`;
  - `chart/natal/report.py`, `structure/__init__.py`, `planet_state.py`;
  - `dictionary/symbols.py`, `natal.py`, `__init__`;
  - test_boundaries.py :102-164 and :310-564;
  - the prompt-order tests in `test_divination_render.py`;
  - conftest `DB_PATH` redirects.
- Targeted core and web reads:
  - core `divination/index.ts`, `summary.ts`, `birth-data/index.ts`, `platform/poll.ts` exports;
  - web `chat/ChatPanel.tsx`, `chat.css` header, `useChat.ts`, `i18n/en.ts` / `zh.ts` shape.
- Computed the Venus facts for the two acceptance charts (conda env `astrology`, `natal_report`):
  - A (1990-06-15 08:30 Beijing): Taurus, house 10, direct, domicile + triplicity; aspects Moon sextile 9.72, Jupiter sextile 2.39, Saturn trine 5.90, Neptune trine 4.44, Pluto opposition 2.75, Chiron sextile 2.16.
  - B (1986-10-20 06:15 New York): Scorpio, house 2, retrograde, detriment, peregrine; aspects Moon opposition 6.53, Mercury conjunction 1.04, Jupiter trine 6.37, MC trine 3.05.

## Skills (in order, pipeline mode)
1. `frontend-design`. It set the header and placement line, the finding-voice note, and the intro and bias letter in the existing letter-and-seal register. No new tokens; reduced motion is covered.
2. `feature-spec`. It wrote Goal, Non-goals, Decided defaults and Acceptance Criteria, with no questions.
3. `architecture-designer`. It wrote the Architecture section: reuse, module map, contracts, wire, forbidden edges, amendments and shared files. Migration Steps were skipped.

## Choices (the Decided defaults)
- **Sheet.** It lives in the new pure `divination/persona.py`. Tier C is the only place allowed to join Tier A facts with Tier B meanings, because chart and dictionary cannot import each other. It is generic over the ten planets. Its facts are sign, house, dignity (major), confidence (a fixed table), retrograde, and up to 5 aspects (to planets or the Ascendant, tightest orb first, with a stance).
- **Voice.** A new topic `divination_voice` VERSION 1 writes `{intro, bias, style}` as a job (`generation.ensure_divination_voice`, priority 1). The key is topic + VERSION + persona planet + lang + sheet FACTS, so it holds no identity and no birth data, and equal placements share a voice. The FINGERPRINT is stored as `doctrine`. The voice sits in a second table in `divination/store.py`, with migration **012_divination_voice.sql**.
- **Route.** `POST /api/divination/persona` answers:
  - a hit → 200;
  - a miss → ensure, then 202 `{status:"generating", sheet}` (the event-card precedent);
  - a failed job → 502;
  - keyless → 503.
- **Turn.** The turn only reads: main.py calls `voice.cached_for` (a store read, no enqueue) and passes the result to `turn_events(…, voice=None)`. The sheet is always in the prompt when birth data is present, and the `style` is added once cached. The turn wire is unchanged. `turn.py` and `render.py` never import voice or store.
- **Mirror and D.** C (self-aware bias) and D (never another person's feelings) are in the `self.read` fragment, which appears only with a sheet. The chart-less prompt stays byte-identical, and `venus.txt` is untouched (it belongs to dw-9).
- **No birth data.** Venus uses the base role only, and no persona request is made.
- **Client.** New files: core `persona.ts`, web `usePersona.ts`, `PersonaHeader.tsx`, `persona.css`, and an i18n `persona` namespace. ChatPanel gets two edits. The intro is never a transcript entry.

## Word counts (`wc -w`)
- Goal + Non-goals + Decided defaults: 1108 (budget ~1,500).
- Architecture: 1276 (budget ~1,500).
- Acceptance Criteria: 1362 (budget-exempt).

## Shared files touched (the landing-conflict surface)
- **dw-9:** `divination/render.py` (additive fragments and a new param), `divination/turn.py` (one param), `web-divination/src/chat/ChatPanel.tsx` (header block and greeting letter), `web-divination/src/i18n/en.ts` / `zh.ts` (appended namespace).
- **dw-12:** `main.py` (a new route after the summary route) and `models.py` (a model at EOF).
- **Also changed:** `generation.py`, `divination/store.py`, `test_boundaries.py`, CLAUDE.md rules 9, 10 and 11, and core `divination/index.ts`.
- **Deliberately untouched:** `venus.txt`, `chat.css`, `useChat.ts`, `llm.py`, core `types.ts` / `turn.ts`, `theme/`.

## Transition
designing → spec-review. Spec: `pipeline/specs/dw-7-persona-mirror.md`.
