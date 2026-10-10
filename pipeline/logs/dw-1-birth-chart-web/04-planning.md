# dw-1-birth-chart-web · 04 · planning — 2026-09-28

Planner subagent ran architecture-designer then imple-plan → pipeline/plans/dw-1-birth-chart-web.md (9 steps:
1 core additions; 2 workspace + guards G1–G11 + colour walk + CLAUDE.md §4.9 amendments in ONE commit; 3 birth input;
4 chart seam + placements; 5 SVG wheel; 6 stage/retry/App (floors → >15); 7 visual pass + T6–T8; 8 validating; 9 docs-sync).

Decisions (★ = deviates from spec wording → journaled):
- D1★ ValidationErrorCode becomes a type export of the @astrace/core/birth-data barrel (review suggestion 1).
- D2 alpha colours = named full-rgba() tokens in tokens.ts emitted as CSS vars; CSS uses var(--…) only.
- D3 Retry = retryChart() re-run, no reload; vitest (fail-once) + A7 same-tab marker.
- D4 SIGN_SECTORS imports SIGNS from ../chart/types (SIGNS stays non-public).
- D5 core additions first with temporary @public-intent markers removed in step 2.
- D6★ guard walked-file floors start >8/>10, rise to spec's >15 at step 6.
- D7★ web fixtures loaded by JSON import, no node:fs / @types/node.
- D8 vite.config.ts outside tsconfig include; explicit vitest imports; no jest-dom.
- D9 orphaned-domain check counts web prod files.
- D10★ G9 workspace isolation also reads import()/require() specifiers.
- D11 <html lang> synced from App.
- G5 intermediate: expects no core/chart importers until useChart.ts lands in step 4.
Found: @testing-library/dom ^10 needed explicitly; react-dom 19.2.3 added by web workspace.

Transition: spec-approved → implementing.
