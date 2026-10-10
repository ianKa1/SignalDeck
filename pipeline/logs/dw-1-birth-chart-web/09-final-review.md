# dw-1-birth-chart-web · 09 · final-review (auto-finalization) — 2026-09-28

Acceptance: fresh-context checker → ACCEPTANCE: PASS on all of T1–T8, G-a…G-i, A1–A9 (08-accepting.md, run independently at 779cd3d).

## What was built
- New npm workspace `web-divination/` (Vite + React 19.2.3, vitest/jsdom): boot → configureApiBase(VITE_API_BASE, default http://localhost:8000),
  theme/tokens.ts as the web's sole chromatic-literal home (CSS vars; CSS uses var(--…) only), en/zh i18n leaf (Dict = typeof en),
  birth form + country select/city search over core/birth-data (profile 'traveler'), chart seam useChart.ts (sole core/chart value importer),
  pure SVG natal wheel over core/chart-view with data-planet / data-aspect-key hooks, placements list + big three, chart stage with
  empty/loading/ready/error states and in-place Retry.
- Core: chart-view gains midLongitude(a,b) + SIGN_SECTORS; birth-data barrel exports type ValidationErrorCode; dead import removed from frame.ts.
- Guards: app-native architecture.test.ts + color-guard.test.ts walk web-divination/src as a third tree (G1–G11, incl. workspace isolation and
  stricter longitude arithmetic); CLAUDE.md amended (rules 1, 2, 5, 8, 13 + commands + web-deletion paragraph).
- Root npm test / typecheck gate both workspaces; root `web:server` script injects CORS_ALLOW_ORIGINS=http://localhost:5173.
- docs/ARCHITECTURE.md synced (incl. pre-existing chart-view drift fix); docs/features/dw-1-birth-chart-web.md written (gitignored).

## Deviations from spec
Plan D1/D6/D7/D10 and worker choices — see DECISIONS.md "dw-1-birth-chart-web · planning" and "· implementing/validating/docs-sync".

## Known limitations
- Real-app runs used backend :8001 (another checkout's uvicorn holds :8000); the :8000 default is covered only by T5 (unit).
- Keyboard/focus navigation and prefers-reduced-motion not exercised.
- packages/core/src/**/*.test.ts still run under no runner (spec non-goal); new core helpers tested from the web suite.
- Production build warns about a large chunk (T6 still passes).

## Landing
Squash of feature/dw-1-birth-chart-web (bf1ef55…779cd3d, 9 commits) onto feature/divination_web.
