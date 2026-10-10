# dw-15-wheel-spotlight — planning (2026-09-29)

Skill: `/imple-plan` under the PIPELINE.md pipeline-mode override (steps with
done-when checks + acceptance map + risks; no architecture re-run).
Inputs: CLAUDE.md, PIPELINE.md (Skills per stage, pipeline-mode overrides),
specs/dw-15-wheel-spotlight.md (PASS), logs 06-spec-review.md optional notes,
precedent plans dw-11 / dw-12 (real-app gate recipe), targeted reads at HEAD
416c3dd: `chart-view/spotlight.ts` (shader body, for K2's u_time),
`web-divination/{package.json,vite.config.ts,tsconfig.json,src/test-setup.ts}`,
`ChartStage.tsx`, `App.tsx:76`, `Spotlight.tsx:129`, `accounts/service.py`
(`_upsert_user`, `_mint_bearer`), root `node_modules/canvaskit-wasm` = 0.41.0.

Output: `pipeline/plans/dw-15-wheel-spotlight.md`, 14 steps (1–11
implementing, 12–13 validating, 14 docs-sync).

## Review notes settled in the plan
- N1 `data-spotlight` at rest: always present on `.chart-stage`; zero beams →
  `static` (no layer mounted); otherwise the layer's status, `loading` until
  its first report.
- N2 K2 `u_time = π/4.8 ≈ 0.654498` — the first breathing peak (breathe = 1.0);
  comet at pulsePos ≈ 0.144 with full envelope; midpoint alpha ≈ 0.95+ vs the
  0.3 floor, far point ≈ 0.
- N3 F4's "removes … Jupiter" read as "Jupiter lacks `data-focus-out`".

## Ordering choices (not structural)
- Guard G14/G15 + CLAUDE.md rule-1 amendment land together in step 7, AFTER
  engine.ts exists (step 6), so the rule text names a real file in the same
  commit as the guard.
- The dependency install is step 1, run at the root with `--workspace` so it
  dedupes with native's copy.

## Findings for the implementer (recorded as risks, not decisions)
- `src/test-setup.ts` calls `localStorage.clear()` in `afterEach`; under the
  K-test's node environment that throws. The plan's step 6 guards it with a
  `typeof` check — a test-harness fix, not a structural change.
- Layer/stage tests must mock `./engine`, never `canvaskit-wasm`, or G15 bites.

## Spec gaps
None. Every step maps to a module and contract the spec's Architecture
section already names; the Vite `optimizeDeps` exclusion stays the spec's
own contingency (step 13).
