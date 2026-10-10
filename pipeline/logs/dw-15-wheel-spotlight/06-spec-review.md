# dw-15-wheel-spotlight — auto spec review, round 3 (fresh context, 2026-09-29)

Inputs: QUEUE.md `## dw-15-wheel-spotlight`, specs/dw-15-wheel-spotlight.md,
epics/divination-web.md, CLAUDE.md, PIPELINE.md (Spec requirements,
pipeline-mode overrides, decision precedence), earlier reviews
02-spec-review.md and 04-spec-review.md (plus revision logs 03/05), and
targeted code reads at HEAD 416c3dd.

Claims re-verified this round:
- `app-native/jest/skia-env.js:27` is
  `require('canvaskit-wasm/bin/full/canvaskit')`, outside `app-native/src`.
  The spec now names it exactly as such.
- In the three walked trees, `canvaskit` appears only in a doc comment at
  `app-native/src/chart/skia-surface.test.tsx:27`. G15 works on
  comment-stripped code, so it passes at HEAD.
- `architecture.test.ts` labels G11 (:861), G12 (:1008) and G13 (:1033), so
  G14 and G15 are free.
- DECISIONS.md holds no user ruling on the web wheel glow, CanvasKit or the
  shader. dw-4's SVG glow and dw-1's "no CanvasKit" strip are tier-3 loop
  decisions, and D14 revises them correctly under Decision precedence. The
  epic's user rulings (local-only, streamed turns) do not conflict.
- Rounds 1 and 2 already verified the other factual claims: line refs,
  fixture counts, the node compile, K2 geometry, and the precedent in
  d0e36b1. They are not redone here.

Earlier required changes:
- 02 #1 (the G11b vs K1/K2 importer conflict): RESOLVED in round 2 by
  `initCanvasKit(locateFile?)` plus type re-exports from `engine.ts`.
- 02 #2 (guard label collision): RESOLVED (G14/G15).
- 02 #3 (R1 flakiness): RESOLVED. Writes happen about every 250 ms, and R1
  needs growth of at least 60 over reads at least 2.5 s apart.
- 02 #4 (Goal length): RESOLVED. The Goal is 3 lines and cites the queue
  entry.
- 04 #1 (false "sole importer" claim): RESOLVED. Both the Dependency-rules
  bullet and the proposed CLAUDE.md rule-1 text now say "within the three
  walked source trees". Both name `app-native/jest/skia-env.js` as the
  pre-existing test-harness importer outside G15's walk. The statement is
  now true.
- 04 #2 (G1 wording contradicted Risks): RESOLVED. G1 now says the K1/K2
  test gets CanvasKit only through `engine.ts`'s `initCanvasKit` and has no
  import specifier. Its locate path is a plain string, which agrees with the
  Risks bullet.
- 04 optional notes: taken up. The `.pathname` locateFile is used, and K2
  fixes glow = 1.0 and a named `u_time`.

## 1. Serves the user's notes, right-sized — PASS

Each clause of the notes maps to a decision and a criterion:

| Note clause | Decision | Criteria |
|---|---|---|
| Same `SPOTLIGHT_SKSL` via CanvasKit-WASM, no GLSL twin, no second copy | D1, non-goals | C1, G1, K1, K2 |
| Replaces dw-4's SVG glow for pills, chips and focus | D3, D4, D11, D14 | B1–B3, R1, R3 |
| Reduced-motion static fallback | D10 | L2, R4 |
| Colours from web tokens | D3, `rgb01` | G2 colour guard |
| Picked character shows only its planet, aspects and partners, the rest hidden or dimmed | D6 | F1, R1 |
| Visible full-chart control | D8 | F2, R2 |
| Pills outside the focus still work | D7 | F4, R3 |
| Loop closed | — | R5 |

D13 is the only extra. It moves the chord helper to core, which also fixes
the native 0° Aries midpoint. It is a direct consequence of the
one-definition rule, it is small, and it is declared in the non-goals.

## 2. Acceptance criteria concretely checkable, not flaky — PASS

Every criterion names a selector, a count, a value, a hash or an
environment:
- C1–C4
- G1–G2
- K1–K2 (deterministic CPU surface, fixed t and glow)
- B1–B5 (pure)
- F1–F6 (jsdom, scoped to the wheel svg)
- L1–L3 (stubbed engine / spied loader)
- R1–R5

R1's timing check now samples well beyond the write period, and it asks for
a foreground tab. R4 uses the established CDP-emulation precedent.

## 3. Architecture Contract, guards, CLAUDE.md, epic — PASS

- **Rule 1.** `spotlightChord` and `spotlightUniformArray` are pure TS in
  core, with no DOM, CanvasKit or rAF. The SkSL stays a single definition
  and is byte-pinned (C1). Colour values stay app-side.
- **Rule 2.** Barrel-only edges, including `PERSONA_BODIES` through
  `@astrace/core/divination`. `chart/` still imports neither `chat/` nor
  `roster/`, because the persona arrives as a prop. `theme/rgb.ts` and
  `theme/motion.ts` stay leaves, and nothing imports across workspaces.
- **Rule 5 / G4.** There is no web longitude arithmetic. Midpoints come from
  core `midLongitude`, and `toBoxPx` is linear px scaling. The wasm loads
  through the library loader, not `fetch`/XHR.
- **Rule 13.** Hex values come only from `webTokens`, and `rgb01` does not
  match the colour guard.
- **Guard amendments tighten only:**
  - four new one-definition symbols;
  - G14 (raw-text shader markers, with the broken `half4 main(` fixture
    correctly left out of the marker set);
  - G15 (comment-stripped, single importer, no exemption);
  - self-checks for both.
- **CLAUDE.md rule-1 replacement text.** It is now accurate:
  - both clients compile the one core string;
  - engine.ts is the sole importer within the walked trees;
  - the jest harness is acknowledged.

  It does not claim identical rendered output.
- **Epic consistency.** The spec cites "Built so far" and the dependency
  rules and writes only the delta. The epic and ARCHITECTURE.md updates are
  deferred to docs-sync, as PIPELINE.md prescribes.

## 4. Non-goals, decided points, pipeline-mode shape — PASS

- There are 8 explicit non-goals.
- D1–D14 settle every open point, with no open-questions section. That
  includes the reset and reload rules, the WebGL→SW fallback, the dpr clamp,
  the beam cap and order, the status states and the Vite contingency.
- The sections run Goal / Non-goals / Decided defaults / Architecture /
  Acceptance Criteria.
- The Goal is at most 3 lines and cites the queue entry.
- Both word budgets are roughly within the ~1,500 targets.

## Optional notes (non-blocking)

- D11 lists `data-spotlight` states for "loading", "live" and "static", but
  it does not say what the attribute reads when there are no beams (full
  chart at rest, D5). Any consistent choice works; the plan should just pick
  one, e.g. `static` or absent.
- F4 says it "removes `data-focus-out` from … Jupiter", but Jupiter is in
  Venus's family and never carried it. The assertion (Jupiter lacks the
  attribute) still holds; only the verb is loose.
- K2's midpoint alpha floor (≈0.32 vs the 0.3 threshold) is deterministic.
  The named `u_time` near the breathing peak gives the margin; the plan
  should record the chosen value.

VERDICT: PASS
