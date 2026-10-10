# 03 planning: dw-4-wheel-activation

**Skill:** `imple-plan`, run under the pipeline-mode override (PIPELINE.md). Output is Steps, Acceptance map and Risks only, with no Code Structure, Calling Sequence, Data Flow or Test Plan sections.

**Reads:**
- `CLAUDE.md`
- PIPELINE.md: the overrides section, the imple-plan rules and Parallel waves
- the spec, the 02 review and the epic `divination-web.md`
- the dw-3 plan, used as precedent
- targeted code reads:
  - `web-divination/vite.config.ts` (it pins port 5173 with `strictPort`, so the plan uses `npx vite --port 5174`)
  - `chat/useChat.ts`, including `run` and the transcript subscription
  - `chat/ChatPanel.tsx`, including `ChartRefChips` and `Entry`
  - `chart/wheel.css`, including the keyframes, the reveal rules and the reduced-motion block
  - `chart/ChartWheel.tsx`, including the aspects, hub nodes and planet groups
  - `chart/ChartStage.tsx`
  - the test `describe` layout of `ChatPanel.test.tsx` and `App.test.tsx`
  - the `chat__ref` block in `chat.css`
  - the root `web` script

**Output:** `pipeline/plans/dw-4-wheel-activation.md` has 8 steps (0–7). Steps 0–5 are implementing, 6 is validating on :8001/:5174, and 7 is docs-sync. `wc -w` gives 1620.

**Review notes settled:**
1. G2 uses `git diff --stat feature/divination_web...HEAD`.
2. `data-planet-node` is emitted unconditionally. The contract now reads "identical to dw-1 apart from data-planet-node".
3. The wheel.css rationale is corrected: `wheel-draw` has `to { stroke-dashoffset: 0 }`, which is the resting value. No keyframe edits.
4. The activation is cleared whenever the transcript shrinks.

**Deviations:**
- **D1:** there is a shrink-clear effect in `useChat`. It is a third touch on the shared file, beyond the spec's "two calls".
- **D2:** the G2 baseline is the three-dot merge-base diff, not `2f45dfb`.

**Transition:** `spec-approved` → `implementing`. The coordinator updates QUEUE.md.
