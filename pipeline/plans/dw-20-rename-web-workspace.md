# dw-20-rename-web-workspace — plan

Spec: pipeline/specs/dw-20-rename-web-workspace.md. All work in the worktree
`/Users/kaimao/Projects/astrology-wt/dw-20-rename-web-workspace` (branch
`feature/dw-20-rename-web-workspace`, base 067ee47). Baseline recorded before
any change: jest 91 suites / 1080 tests, vitest 47 files / 445 tests,
typecheck OK, pytest 1446 passed / 99 skipped (db env unset). Guard counts:
architecture 136 test / 134 expect; color-guard 6 / 20; rename-guard.test.ts
7 / 10; test_rename_guard.py 2 defs / 10 asserts.

## Steps

- [ ] **S1 Move.** `git mv web-divination web-planet-chat`; set
  `web-planet-chat/package.json` name; root `package.json` workspaces and the
  `test`/`typecheck`/`web` scripts. Then `rm node_modules/web-divination`
  (stale link) and run `npm install` at the root to regenerate the lockfile.
  Done when: `git status` shows renames; lockfile has no `web-divination`;
  `node_modules/web-planet-chat -> ../web-planet-chat`; version diff script
  (base vs new lockfile, prefix rewritten) prints 0 differences.
- [ ] **S2 Guards.** `app-native/src/architecture.test.ts` (`WEB_DIR`, test
  names, planted paths, G9 specifier), `color-guard.test.ts` (`WEB_ROOT`,
  names, comments). `rename-allowlist.json`: drop the folder entry, re-point
  the two in-workspace path_globs, add the D6 migration entry.
  Both rename guards: re-point planted paths, change the exceptions sample,
  add the D5 "old folder name is red" self-check, update header comments.
  Done when: `npx jest src/architecture.test.ts src/color-guard.test.ts src/rename-guard.test.ts`
  and `pytest tests/test_rename_guard.py` pass, counts ≥ baseline.
- [ ] **S3 Comments and code-adjacent text.** Every remaining live hit in
  `.env.example`, `app-native/src/chart/Spotlight.tsx`, `packages/core/src/**`,
  `server/app/**` (not migrations), `server/tests/test_web_accounts.py`,
  and files inside `web-planet-chat/`. Done when: the R4 rg lists only the
  four spec'd files.
- [ ] **S4 Docs.** `CLAUDE.md` (D7), `docs/ARCHITECTURE.md`,
  `pipeline/PIPELINE.md` frontend-facing line. (Epic file at docs-sync.)
  Done when: rg over those three prints nothing; both rename guards pass.
- [ ] **S5 Commit** via /git-commit on the feature branch.
  Done when: `git log -1` shows the commit, `git status` clean.

## Acceptance map

| Criterion | Step |
|---|---|
| R1 moved with history | S1 (checked in validating) |
| R2 package/root wiring | S1 |
| R3 lockfile | S1 |
| R4 no live reference | S3, S4 (+ epic at docs-sync) |
| R5 sweep covers folder | S2 |
| R6 guards walk new tree | S2 |
| R7 root commands | S1–S4, checked in validating |
| R8 dev server | validating (5174), landing (5173) |
| R9 end to end | validating (local dbs, 8002/5174), landing (5173/8000) |
| R10 docs | S4 + docs-sync |

## Risks for the implementer

- Root `npm run web -- --port 5174` does not pass the port through (npm eats
  it); use `npm run dev --workspace web-planet-chat -- --port 5174`.
- `git mv` renames the directory on disk, so untracked `node_modules/` and
  `dist/` follow; the root `node_modules/web-divination` symlink dangles until
  removed.
- Replacement must not hit `dw-*-divination-*` slugs or the epic path
  `epics/divination-web.md`; only the literal `web-divination`.
- Prose that recorded the old folder as history must be reworded without the
  old name (it would trip the rename guard).
