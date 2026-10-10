# 02 · spec-review (2026-09-30)

Fresh-context subagent (general-purpose), inputs: QUEUE entry, spec, CLAUDE.md,
PIPELINE.md Spec requirements / Auto spec review / Decision precedence;
targeted code reads allowed.

## Verdict (verbatim summary of the returned report)

**Verdict: PASS**

1. Serves the notes, right-sized: yes — every note maps to a decision (D1–D9,
   AC1–AC6, AC10, AC19, AC24); extras (resume key D5, pull-failed fallback D4,
   validation-only harness 14) justified, not invented scope.
2. Acceptance criteria checkable: yes — all 24 name a test id, store value, HTTP
   call or idb/pixel observation; relied-on test ids exist today.
3. Architecture Contract: no violation — barrel-only core surface, no React in
   core, getKV from the platform barrel (platform/index.ts:21), no fetch outside
   platform, GROUND_TOKENS/PAINT/Txt only; tier-3 revisions correctly handled.
   Composer logic checked against service.ts:56–58 and sync.ts (adopt before
   `ready`; failed pull returns inside try/finally).
4. Non-goals and defaults: yes.

Non-blocking observations:
- setLanguage cited at :95, real :81.
- Cancel button placement undecided (keep `sheet-cancel` sheet-side; map onSaved→onClose).
- AC13 needs the light ground applied before App's modules evaluate (isolateModules).
- Reload into a dead session with the progress key: words at once, then buttons (harmless).
- Reduce Motion: `wordsDone` waits for OPENING_HOLD_MS; pass `revealed={wordsDone || reduced}` or AC3 fails.
- AC20: any raw tag in setup is a deliberate census change.
- Guard additions (setup in raw-literal and paid-channel walks) strengthen guards — correct.

## Coordinator follow-up
Spec amended for three observations (no criterion changed): the :81 citation;
BirthForm contract states the sheet keeps cancel/scrim/grip and maps onSaved→onClose;
SignInGate contract states App passes `wordsDone || reduced`.

Transition: spec-review → spec-approved (→ planning)
