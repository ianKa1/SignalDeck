# dw-14-web-navigation — 05 planning

- Date: 2026-09-29. Skill: `/imple-plan` under the pipeline-mode overrides (no architecture re-run).
- Inputs: CLAUDE.md; PIPELINE.md "Skills per stage" + "Pipeline-mode overrides"; the approved spec; 04-spec-review.md optional notes; targeted reads (architecture.test.ts web block, test-setup.ts, App.test.tsx, session-log.ts write/snapshot, transcript.ts snapshot, useChat appendEntry call sites, dw-15 plan ports/guard ids).
- Output: `pipeline/plans/dw-14-web-navigation.md` — 17 steps (0–13 implementing, 14–15 validating, 16 docs-sync), acceptance map covering N1–N4, W1–W12, C1–C6, G1–G3, R1–R5, and risks.

## Review notes settled in the plan
- W1 counts DISTINCT `/chat/` hrefs in first-occurrence order (plus six name links) — S1.
- C1's entries are user, then persona, so C3's `canEndSession` holds — S2.
- N2's no-remount probe: `harnessMounts` counter in `nav/Link.test.tsx`; App twin asserts the same `banner` node before/after a push — S3.
- Forbidden-edges wording allows the existing `auth/AuthGate.tsx` → `app/Header` edge in every restatement; no guard added — S4.
- Gate wordmark push is harmless; W11 asserts paths only — S5.

## Ordering / coordination
- Guards G16/G17 + CLAUDE.md sentence land in ONE commit (step 4), after the router exists and after useChat stops calling `appendEntry` (step 2), so both guards are green on landing.
- dw-15 (parallel) owns G14/G15 and `<ChartStage persona={active}/>` in App.tsx; second to land moves the prop into `app/ChatScreen.tsx` and sets `/chat/venus` in dw-15's Venus-active App cases.
- Real app on backend :8002 / Vite :5175 (dw-15 uses :8001/:5174), throwaway initdb Postgres on 127.0.0.1, backend without `--env-file`, minted bearer pair.

## Spec gaps
- SG1: the `nav/history.ts` contract (getPath/subscribePath/navigate) gives App no way to tell a push from a popstate, yet D7/W3 require heading focus after a push only. Plan resolves it inside `nav/` with an exported read of the last change's kind (push|pop|initial); to be journaled as a deviation in DECISIONS.md at implementing. No new edge, no global use outside history.ts.
- (Minor, not a gap) The spec's "No feature folder … imports app/" bullet is false for AuthGate → Header; settled as wording (S4), no code change.
