# dw-13-character-chat — 10 final review (auto-finalization, 2026-09-29)

## What was built
- The dw-7 voice job now produces a CHARACTER CARD per placement (`divination_voice` VERSION 2, `{card, greeting}`).
  - The card is 2,800–3,800 characters with no astro vocabulary: `astro_terms` checks it, and a hit regenerates it, up to 3 attempts with the rejected terms fed back.
  - The greeting is in the request language.
  - The persona wire is v2 `{greeting}`, and the web opening letter shows the greeting with no bias aside.
- The turn prompt is: identity, then the card (or the base description as fallback), then `ground.rules` (6 lines, 496 characters), then `rhythm.chat`/`rhythm.deeper`, then the compressed data sections, then the tag block, then the language line.
  - Retired: `shape.*`, `depth.*`, `self.*`, `roster.*`, `focus.*` and `chart.none`.
  - Prompts are English-only and sample-free, pinned by tests. The chart-less goldens were re-recorded.
- `bubbles.py`: a total sentence ceiling (chat 12, deeper 20) with no per-bubble cap. A line with no terminator counts as a sentence.
- A multi-turn lab (`server/tests/prompt_lab/divination_chat_lab.py`, with unit-tested metrics). Transcripts are in logs/dw-13-character-chat/transcripts/{baseline, run-01..04}; the final run is run-03.
- CLAUDE.md rules 9 and 10 amended. ARCHITECTURE.md and the epic synced.

## Deviations
- The baseline log is in 06 rather than the plan's "05", because 05 was the planning log.
- The pre_dw8 fixtures and `NatalContext.sheet` were removed.

## Known limitations (for the user's audit)
- The 12-sentence ceiling cut 57 of 60 lab turns. Each reply ends on a sentence boundary, but most replies lose their tail, and some stop on a lead-in ("give the flat's noises names.").
- The Moon sometimes promises things it cannot do.
- One real-app greeting used an emoji.
- zh is untuned (a non-goal).

## Acceptance
OVERALL: PASS, 25/25 (logs/dw-13-character-chat/09-accepting.md).
