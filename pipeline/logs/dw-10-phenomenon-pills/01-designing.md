# dw-10-phenomenon-pills — 01 designing (2026-09-29)

Branch: `feature/dw-10-phenomenon-pills` cut from `feature/divination_web` @ bfcd0f7 (serial: the only actionable entry; dw-12 blocked).

Skills invoked: /frontend-design (visual bar: inline seals in paper slips, per-source styles), /feature-spec (pipeline mode: Goal, Non-goals, Decided defaults, Acceptance Criteria), /architecture-designer (pipeline mode: Architecture section only, cites the epic).

Targeted reads: divination/turn.py, bubbles.py, render.py, sky.py, dice.py, persona.py; core divination/types.ts, turn.ts, transcript.ts, summary.ts, index.ts; chart-view/glyphs.ts; web chat/useChat.ts, ChatPanel.tsx, pacer.ts, chart/wheel-activation.ts, log/SessionTranscript.tsx, i18n/en.ts, theme/tokens.ts; server/tests/test_boundaries.py (handoff guard, purity tests); chart/transit/instant.py `_natal_targets`.

Fixture chart facts (for criteria) printed via `natal_report` on 1990-06-15 08:30 Asia/Shanghai: Venus Taurus 10, Moon Pisces 8, Mars Aries 9, Asc Cancer; aspects Venus|trine|Saturn, Moon|sextile|Venus, Venus|opposition|Pluto; no Venus–Mars aspect.

Main decisions (spec "Decided defaults"): scanner AFTER the unchanged segmenter; four tag kinds; failed tag → English fallback text + WARNING; `pill` SSE event; pills replace side-read chartRefs as the single source (supersedes dw-3's side-read refs and side.dice/side.sky); tokens stored in the reply text; web `lore` namespace for meanings; `ASPECT_TONES` in chart-view; legacy-only chip row.

Result: spec written → status `spec-review`.
