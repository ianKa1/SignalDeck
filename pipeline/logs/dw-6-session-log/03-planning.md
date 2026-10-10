# 03 planning — dw-6-session-log

**Transition:** spec-approved → implementing (plan written; the coordinator creates the worktree and dispatches worker #3).

**Skill:** `/imple-plan`, under PIPELINE.md's pipeline-mode override (Steps / Acceptance map / Risks only; no Code Structure, Calling Sequence, Data Flow or Test Plan). `/architecture-designer` not re-run: the structure is the spec's Architecture section.

**Reads:** CLAUDE.md; PIPELINE.md (Skills per stage, pipeline-mode overrides, Parallel waves); spec `specs/dw-6-session-log.md`; review `logs/dw-6-session-log/02-spec-review.md`; epic `epics/divination-web.md` (Target modules, Dependency rules — the fingerprint-in-key line at :229); precedent plan `plans/dw-5-astro-dice.md`. Targeted code reads: `server/tests/test_boundaries.py` (GENERATE_ON_REQUEST_RE, DIVINATION_FORBIDDEN_RE, `_divination_fence_offenders`, `test_no_tier_imports_divination`, `test_divination_keeps_no_state`, `test_main_names_the_synchronous_exceptions`), `server/tests/conftest.py` (DB_PATH redirects, JOBS_SYNC), `server/app/generation.py` (imports, `ensure_transit_reading`), `server/app/jobs/queue.py` (FAILED_COOLDOWN_SECONDS = 30), `server/app/interpretation/store.py` (created_at ↔ generatedAtUtc), `server/app/db/migrations/` (highest 010), `packages/core/src/divination/index.ts`, `packages/core/src/platform/poll.ts`, `web-divination/` layout + package.json, root package.json scripts, `app-native/src/architecture.test.ts` (G1/G2 walk web-divination).

**Output:** `pipeline/plans/dw-6-session-log.md` — 10 steps (0–9: 0 prep check, 1–7 implementing, 8 validating on :8003/:5176, 9 docs-sync), acceptance map covering S1–S10, C1–C8, W1–W9, A1–A6. `wc -w`: 1933.

**Review notes settled in the plan:** rule 14 half-clause "and divination (the summary job)" lands with generation.py's import (step 3); `generatedAtUtc` stamped by `generate_summary`, stored in `created_at`, returned by `get`; >40-entry key collision accepted; failed-job 30 s cooldown makes Retry 502 in the window (expected).

**Deviations:**
- S10/W9 diff baseline: `git diff 2f45dfb` as written before the landing merge; after merging `feature/divination_web` (dw-5 edits turn.py/render.py/chat/), the same checks run as `git diff feature/divination_web...HEAD`.
