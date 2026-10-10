# 07 planning — dw-5-astro-dice

Skill: `/imple-plan`, pipeline-mode override (Steps / Acceptance map /
Risks; no Code Structure, Calling Sequence, Data Flow or Test Plan).
architecture-designer not re-run.

Reads: CLAUDE.md; pipeline/PIPELINE.md (Skills per stage, pipeline-mode
overrides, Parallel waves); specs/dw-5-astro-dice.md;
logs/dw-5-astro-dice/06-spec-review.md; plans/dw-4-wheel-activation.md
(precedent, Vite recipe). Targeted code: server/app/divination/turn.py
(`turn_events`, `_wait`, `_side_read`), render.py (registry lines,
`FINGERPRINT` at :95, `system_prompt`/`turn_messages`/`side_prompt`),
packages/core/src/divination/turn.ts, packages/core/src/chart/index.ts
(`SIGNS` not exported), web-divination/src/chat/useChat.ts (`Pending`,
`setPending` replacement per delta), package.json scripts.

Output: `pipeline/plans/dw-5-astro-dice.md` — 10 steps (0 prep check;
1–7 implementing; 8 validating on :8002/:5175; 9 docs-sync). `wc -w`: 1,724.
CLAUDE.md rule 10 sentence lands in step 3 with turn.py.

Deviations (for journaling):
- D1: roll + `dice` yield come after the existing `deadline` line and
  before `natal_context` (settles review note 1).
- D2: core `streamTurn` yields `dice` regardless of request action; gates
  are `isDice`, no prior delta, no prior dice (settles review note 2).

Transition: spec-approved → implementing.
