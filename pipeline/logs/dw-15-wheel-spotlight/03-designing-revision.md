# dw-15-wheel-spotlight — 03 designing revision (2026-09-29)

Input: `02-spec-review.md` (round 1 FAIL) and the coordinator's list of
required changes. I edited the spec in place: `pipeline/specs/dw-15-wheel-spotlight.md`.
HEAD is 8da99b2 (dw-12 landed).

## Required changes, applied

1. **The single-importer guard vs K1/K2** (review option b).
   - `engine.ts` exports `initCanvasKit(locateFile?)`. It is the one dynamic
     `import('canvaskit-wasm')`. In the browser it defaults to the `?url`
     wasm, and in node the caller passes `locateFile`.
   - `engine.ts` re-exports the `CanvasKit`, `RuntimeEffect` and `Surface`
     types.
   - K1 now gets CanvasKit through `initCanvasKit`. The node test imports
     only `./engine`.
   - The G1 criterion now states that the importer guard matches
     COMMENT-STRIPPED code and walks all three trees, tests included, with no
     exemption. The shader-text guard stays on raw text and skips only its
     own guard file.
2. **Guard numbering.** At HEAD, `architecture.test.ts` has G11 (the
   walked-tree floor, :861) and dw-12's G12/G13 (:1008–1062). The new guards
   are **G14** ("one shader text") and **G15** ("one canvaskit importer"). I
   updated the module map, forbidden edges, guard section, CLAUDE.md wording
   and criterion G1. A grep of the spec shows no G11 left.
3. **R1 frame check.**
   - `data-frames` is now written about every 250 ms (contract updated).
   - R1 takes two reads at least 2.5 s apart and needs growth of at least 60.
   - The Claude-in-Chrome tab stays in the foreground.
   - R4 now runs in headless Chrome with CDP
     `Emulation.setEmulatedMedia` prefers-reduced-motion=reduce (the dw-4 A5
     / dw-5 A8 precedent).
4. **Goal** cut to three lines, citing the QUEUE entry.

## Optional notes, applied

- `spotlightChord(aspect, chart, rHub)` now takes only the hub radius.
  `wheelPoint` centres on `WHEEL_VIEW`, and all three views share that
  centre, so no caller can pass a centre that disagrees with the endpoints.
  Native calls it with `ACTIVE_WHEEL_VIEW.rHub`.
- `quadControl` is written with its real signature,
  `(ax, ay, bx, by, cx, cy, k) → {qx, qy}`. The signature is unchanged. C3
  matches it.
- F1's counts are scoped to the wheel `svg`.
- Risk added: sort beams with `x.orb - y.orb`, never with an `orb =`
  assignment (COMPUTATION_RE).

## HEAD re-check

- `web-divination/src/app/App.tsx:76` is still `<ChartStage />`.
- dw-12's `AuthGate` wraps App in `main.tsx:25`, not in App.tsx.
- `web-divination/src/chart/` is unchanged between f710c2b and 8da99b2.
- No other line references changed.

Status: the spec is revised and ready for spec-review round 2.
