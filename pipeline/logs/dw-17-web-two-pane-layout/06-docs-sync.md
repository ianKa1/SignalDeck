# 06 — docs-sync (2026-09-29, parallel-wave worker)

- `/update-architecture-doc` over `2e6cfe8..HEAD` (baseline = the doc's last commit, 2e6cfe8). Diff triage: web-divination
  app/, birth-input/, chart/, chat/, i18n/, roster.css — local/structural for the web client sections only.
  Edited in place in `docs/ARCHITECTURE.md`: the repo-tree comments for `app/`, `birth-input/`, `chart/` (Placements gone,
  BirthChip added); the App/routes paragraph (ChatScreen two panes, `shell--chat`, ≥/<960 behaviour, jump buttons); the Birth
  input paragraph (BirthSummary + Edit → BirthChip + popover contract); the Chart paragraph (no placements list); the chat log
  sentence (≤ 60vh box → flex-filled, composer wrap < 520 px); the web data-flow line (`ChartWheel + Placements` → `ChartWheel`);
  + one feature-index entry (the doc's own index convention). Confirmed accurate: dw-15 focus/spotlight section, nav/ section.
  Left as history: the dw-1 index entry's "placements". Spot-checked every path/selector written (BirthChip.tsx, BirthCard.tsx,
  `#chart-pane`/`#chat-pane`, `data-birth-chip`, `birth-popover`, `shell--chat`, `pane__jump`). CLAUDE.md names neither
  Placements nor BirthSummary — no amendment. Commit 9403218.
- `docs/features/dw-17-web-two-pane-layout.md` written in the primary checkout (docs/features/ is gitignored): what was built,
  tests, deviations, known limitations.
- Epic `pipeline/epics/divination-web.md`: additive only — a "dw-17 … landing pending" block before the request-shape lines in
  Built so far, and two `dw-17 ✔` lines in the web-divination Target modules tree (no existing line rewritten, in case dw-16
  edits the same file).
- Status: docs-sync → (coordinator) accepting.
