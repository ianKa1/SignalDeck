# 01 — designing (2026-09-29)
- URGENT per user (pre-deploy LLM-spend hole); ready once dw-16 landed (4a74364). Serial, run in worktree ../astrology-wt/dw-18-divination-auth (branch feature/dw-18-divination-auth) so the user's :8000/:5173 are untouched.
- Skills: /feature-spec, /architecture-designer and /frontend-design were loaded earlier in this coordinator session and applied under the pipeline-mode overrides (same practice as dw-17); no UI design needed beyond the gate reappearing.
- Reads: main.py divination routes (:447–:560), accounts/web/routes.py `_caller`, service.user_for, core platform/poll.ts postJson, platform/auth.ts, platform/stream.ts, divination/turn.ts, persona/summary/roster callers; grep of every /api path the web tree and core divination/web-account name (only /api/chart is shared; four /api/divination routes are web-only; native imports no core divination).
- Spec: pipeline/specs/dw-18-divination-auth.md. Status: backlog → spec-review.
