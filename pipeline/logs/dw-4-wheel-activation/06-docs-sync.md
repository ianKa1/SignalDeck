# 06 — docs-sync (worker #1)

- `/update-architecture-doc`: baseline `2f45dfb` (last touch of
  docs/ARCHITECTURE.md). Diff triage: `web-divination/src/chart/*`,
  `chat/*`, `app/App.test.tsx` — local-to-structural (new module
  `chart/wheel-activation.ts`, new edge `chat → chart/wheel-activation`).
  Sections edited in place: repo-tree block (chart/, chat/ lines); "web-divination
  — as built" Chart bullet (activation prop, `data-planet-node`) + NEW
  "Wheel activation" bullet (store, `activationFor`, tiers, CSS, motion,
  edge); Chat bullet (useChat clear/show/shrink-clear; chips as press
  buttons); runtime-flow paragraph (showRefs → lit wheel); Testing count
  (was "9 files / 25 tests as of dw-1", now 14 / 87 as of dw-4 — pre-existing
  drift fixed); feature index + dw-4 line. Confirmed unchanged: guards
  section (no guard change), core chart-view section.
  Pre-existing drift noticed, NOT fixed: the feature index has no
  dw-3-chart-grounded-reply line.
- `docs/features/dw-4-wheel-activation.md` written in the worktree
  (gitignored, not committed — the coordinator should copy it to the primary
  checkout's `docs/features/` before removing the worktree).
- Epic file NOT edited (coordinator is its single writer); the text is in the
  worker's report.
- Spot-check: `wheel-activation.ts`, `activationFor`, `showRefs`,
  `clearActivation`, `useActivation`, `data-planet-node`, `chat__ref-button`
  all grep-present in `web-divination/src`.

Status: docs-sync done → accepting (coordinator).
