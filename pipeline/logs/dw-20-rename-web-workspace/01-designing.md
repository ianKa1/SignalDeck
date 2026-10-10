# 01 designing — dw-20-rename-web-workspace (2026-09-29)

Branch/worktree: `feature/dw-20-rename-web-workspace` at
`../astrology-wt/dw-20-rename-web-workspace` (created from feature/divination_web
067ee47). A worktree even for a wave of one: the user's live Vite runs from
inside `web-divination/` in the primary checkout, and switching the primary
checkout to a branch where the folder is moved would break it before landing
(spec D9).

Skills: /feature-spec (pipeline mode) then /architecture-designer (pipeline
mode, delta against pipeline/epics/divination-web.md).

Survey commands:
- `rg -l --hidden -g '!.git' -g '!node_modules' 'web-divination'` → 45 live
  files (list reproduced in the spec's D4 by area); also `--no-ignore` sweep:
  only docs/features/* (history) added — no gitignored config names the folder.
- `rg -n 'sha|checksum' server/app/db/*.py` → migrations are not checksummed;
  001_web_accounts.sql is kept byte-frozen by convention anyway (D6).
- rename-allowlist.json read: entry `[Ww]eb-divination` (dw-19 D3) plus two
  path_globs inside the workspace.

Result: spec written at pipeline/specs/dw-20-rename-web-workspace.md
(Goal, Non-goals, D1–D10, Architecture, R1–R10).
Transition: backlog → spec-review.
