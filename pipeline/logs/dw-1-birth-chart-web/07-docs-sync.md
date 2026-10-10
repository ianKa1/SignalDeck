# 07 — docs-sync (worker, 2026-09-28)

Skill: update-architecture-doc (diff-driven). Baseline: docs/ARCHITECTURE.md last touched fb5a907.
SCOPE: this feature's commits bf1ef55..766ee30 only. The 11 commits between fb5a907 and e157aed
(transit/sign-post work that predates this branch) were NOT re-audited here — they are outside
dw-1's diff; flagged for the coordinator.

## docs/ARCHITECTURE.md sections updated
- Overview: three workspaces, two client workspaces; new web-divination bullet; run/test lines.
- Layering tree: workspaces line; new `web-divination/` subtree.
- Guards paragraph: three trees, web twins G3–G7, G9, public-API consumers; count 24 → 36 tests.
- Colour guard: two token homes, the web walk.
- core/chart-view: `midLongitude`, `SIGN_SECTORS` (+ `angularDelta`, `pointScreenAngle`,
  `ONE_CIRCLE_VIEW`/`HUB_FORWARD_VIEW` which the section had omitted).
- core/birth-data: `ValidationErrorCode` type export.
- NEW section "`web-divination/` — the browser workspace (as built)".
- Data flow: the web chain. Deployment: web-divination is local-only. Testing: three suites.
- Feature docs list: dw-1 entry.
PRE-EXISTING DRIFT fixed (verified against code): chart-view section still listed
`houseSpan`/`houseMidLongitude` (deleted P17) and a `categories.ts` bullet (file deleted P17).
Sections confirmed still accurate: core/platform, core/chart, server, app-native (untouched by the diff).

## docs/features/dw-1-birth-chart-web.md
Written directly (gitignored): what was built, the 8 deviations, limitations.

## Extra commit during this stage
766ee30 — dropped the ineffective `'SOFT' 50` variation axis from app.css (the opsz Fraunces
build has no SOFT axis) rather than documenting it as a limitation. Guards 39/39, web 25/25 after.

## Transition
docs-sync done → (coordinator) accepting.
