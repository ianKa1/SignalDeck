# 05 planning — dw-20-rename-web-workspace (2026-09-29)

/imple-plan (pipeline mode) wrote pipeline/plans/dw-20-rename-web-workspace.md:
five steps (move + lockfile, guards + allowlist, comments, docs, commit),
acceptance map R1–R10, three risks (npm eats --port through the root script,
dangling node_modules link, slug/epic-path collisions). Baselines recorded in
the plan from runs on the untouched worktree:
- jest: Test Suites 91 passed; Tests 1080 passed
- vitest: Test Files 47 passed; Tests 445 passed
- typecheck OK
- pytest (DATABASE_URL/WEB_DATABASE_URL unset): 1446 passed, 99 skipped
Transition: spec-approved → implementing.
