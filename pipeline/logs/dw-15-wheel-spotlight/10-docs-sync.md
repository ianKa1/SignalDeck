# 10 — docs-sync (dw-15-wheel-spotlight)

`/update-architecture-doc` on `docs/ARCHITECTURE.md` (baseline: last touched in
8da99b2; diff since = 416c3dd pipeline-rule commit, not doc-relevant, plus this
feature's 10 commits). Commit **2178965**. Sections edited:
- Repo tree (`web-divination/`): canvaskit-wasm dependency + `skipLibCheck`;
  `chart/focus.ts` and `chart/spotlight/{beams,engine,SpotlightLayer}`;
  `theme/rgb.ts`, `theme/motion.ts`.
- Guards paragraph: architecture.test.ts count 38 → 44 (38 was ALREADY stale —
  41 at 416c3dd, pre-existing drift; 44 after G14/G15/self-check);
  enumeration + the four spotlight symbols; G14 and G15 described; the
  self-check list names G12–G15.
- `core/chart-view` → `spotlight.ts` bullet: `spotlightUniformArray`,
  `spotlightChord`; loading/draw loop stays app-side per client.
- `web-divination/` section: `ChartWheel` `focus` prop; new bullet "Focus and
  the spotlight" (focusFor, CSS, toggle, beamsFor, SpotlightLayer, engine,
  `data-spotlight` states N1).
- Native Spotlight paragraph: `spotlightLineFor` delegates to `spotlightChord`.
- Data flow: the stage → focus/beams → layer → engine chain.
- Testing: web vitest 30/308 → 39/351, the node-environment CanvasKit file.
- Feature docs list: dw-15 entry.
Confirmed still accurate: dw-4 activation bullet (its SVG glow is now the
static/reduced-motion rendering, which the new bullet states). Not fixed
(pre-existing drift outside this diff): the native test count "988 tests across
87 suites as of ask-ring-pick" (now 1075 / 90).
Spot-checks: every path written exists (`ls` loop, no MISSING);
`npx jest src/architecture.test.ts` → 44 passed.

Also written:
- `docs/features/dw-15-wheel-spotlight.md` in the PRIMARY checkout
  (`docs/features/` is gitignored — `.gitignore:17` — so it exists only there,
  like the other dw-* feature docs; not committed). Describes what was built,
  N1–N3, deviations, R1–R5 evidence.
- `pipeline/epics/divination-web.md`: a dw-15 block after dw-13 (built so
  far), target modules (`core chart-view/spotlight.ts`, web `chart/` focus +
  `spotlight/`, `theme/` leaves), dependency rules (G14/G15, the canvaskit
  edge, new edges, leaves).
- CLAUDE.md rule 1 (landed in 785cdc4, step 7) re-checked against the code:
  names `engine.ts` as the sole `canvaskit-wasm` importer, `skia-env.js` as
  tests-only, the enumeration and G14 — matches the guard.
Plan step 14 ticked (14/14).

Status transition: docs-sync → accepting (coordinator).
