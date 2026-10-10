# dw-1-birth-chart-web · 01 · designing — 2026-09-28

- Coordinator committed the pending PIPELINE.md parallel-waves rule edit alone on
  feature/divination_web first: e157aed.
- Branch `feature/dw-1-birth-chart-web` cut from `feature/divination_web` (Git granularity rule 0/1).
- Spec written by a designing subagent (skills loaded: frontend-design, then feature-spec)
  to `pipeline/specs/dw-1-birth-chart-web.md` (573 lines). Nothing committed (pipeline/ is gitignored).

## Designer's report (verbatim summary of decided defaults)
1. API reach: absolute base from VITE_API_BASE (default http://localhost:8000), CORS for :5173, no Vite /api proxy; root script `web:server` injects CORS_ALLOW_ORIGINS.
2. Guards' home: app-native architecture.test.ts + color-guard.test.ts gain a third walked tree web-divination/src.
3. Existing rules extended to web tree (barrels, chart-view one-definition, network only in src/platform/, no astro arithmetic, chart via subscription, i18n/theme leaf, key-leak/astronomy-engine bans).
4. New guard rules: stricter longitude-arithmetic check (web tree only), workspace isolation (web-divination <-> app-native never import each other), public-API guard counts web consumers.
5. houseSpan/houseMidLongitude NOT restored; `midLongitude(a,b)` in core/chart-view/geometry.ts + `SIGN_SECTORS` in frame.ts, enumerated in the one-definition guard.
6. session.ts pins 'traveler' profile as native does -> localStorage key astrology.birthData.v1.traveler.
7. Colours: native ink-ground values copied into web-divination/src/theme/tokens.ts, exposed as CSS variables; CSS uses var(--…) only; colour guard walks .css + index.html.
8. Visual: "candlelit observatory" — Fraunces + Source Serif 4 via @fontsource, gold single accent, CSS staged reveal, reduced-motion off.
9. Wheel static in dw-1; data-planet / data-aspect-key hooks for dw-4.
10. React pinned 19.2.3 (dedupe with root hoist).
11. vitest + jsdom in web workspace; root npm test/typecheck run both workspaces.
12. en/zh; saved -> browser -> en; persisted through core storage port.
13. Country select + offline city search; no manual coordinates.
14. Vite port 5173 strictPort.

Architecture-affecting (to journal): rule 13 back to two token homes; guards' single home walks a third tree;
chart-view gains midLongitude + SIGN_SECTORS; workspace-isolation guard; web-only stricter arithmetic guard;
CLAUDE.md amended in the implementing commit (web-deletion paragraph + rules 1,2,5,8,13 + commands);
root test/typecheck gate both workspaces; React pin.
Open gap (non-goal): packages/core/src/**/*.test.ts still runs under no runner.

Transition: designing -> spec-review.
