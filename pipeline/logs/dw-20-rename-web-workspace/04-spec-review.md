# 04 spec-review (round 2) — dw-20-rename-web-workspace (fresh-context reviewer)

VERDICT: PASS

The round-1 defect is fixed. R4 now names the four files the sweep must print: the D6 migration, the allowlist's D6 entry, and the two rename guards' planted RED self-check. It also gives each file its one allowed reason, which matches D5 and D6. I found no new real defect.

## Checklist

**1. Serves the user's notes, right-sized: yes.**
Every item in the QUEUE notes maps to a default:
- `git mv` → D1
- package name and root scripts → D2
- lockfile regenerated, never hand-edited → D3
- guards change path only → D4 plus Non-goals
- allowlist entry removed → D5
- docs, epic, server tests, `.env.example` → D4 and D7
- history frozen → Non-goals
- loop closed → R4 and R7–R9

I re-ran the live sweep (`rg -i web-divination` outside `.git`, `node_modules`, `pipeline/` and `docs/features/`). Every hit falls inside D4's list:
- root `package.json`, `package-lock.json`, `.env.example`, `CLAUDE.md` (31), `docs/ARCHITECTURE.md` (45)
- the three app-native guards and `Spotlight.tsx`
- six `packages/core/src` files
- `server/app/{main.py, db/__init__.py, accounts/web/*}`, `server/tests/test_web_accounts.py`, `test_rename_guard.py`
- the migration
- the workspace's own files

`.gitignore`, the tsconfig files and `scripts/` hold no occurrence, so leaving them out of D4 is correct. D9 and D10 are process safeguards for the user's live Vite, not product scope.

**2. Criteria concretely checkable: yes.**
- **R1–R3:** runnable commands and comparisons. `f02e88b` follows `boot.ts`. Today the lockfile has nested `web-divination/node_modules/*` keys and a `node_modules/web-divination` symlink, so R3's checks rest on real facts.
- **R4:** now consistent with D5/D6. The migration's line 1 is its only `divination` hit, so the D6 entry scoped to that file and the pattern `web-divination` covers it fully. The allowlist line for D6 is the only `rename-allowlist.json` hit once `[Ww]eb-divination` is removed. The guards' current hits are:
  - header line 6: dropped per D5
  - the App.tsx offender fixture: re-pointed
  - the "stays green" sample: re-pointed

  That leaves only the new RED plant.
- **R5:** checkable. The rename guards scan tracked and untracked-not-ignored files, so a line appended to the tracked `boot.ts` is seen. The two re-pointed `path_glob` entries name files that exist (`chat/core-planet-chat-legacy-keys.test.ts`, `auth/core-web-account.test.ts`), so the "every entry used" rule keeps holding.
- **R6:** checkable. The only location constants are `WEB_DIR` at `architecture.test.ts:46` and `WEB_ROOT` at `color-guard.test.ts:112` (confirmed). The non-decreasing `test(`/`expect(` count and the planted `fetch(` probe are concrete.
- **R7–R10:** executable. R7 compares against 067ee47, R8 and R9 make HTTP 200 checks and a real-browser run, R10 is a doc grep.

**3. Architecture Contract and epic consistency: no violation.**
- Rules 1, 2, 5, 8 and 13 only get their path substituted.
- G9's workspace-name specifier check moves to the new name.
- `web-planet-chat/src/theme/tokens.ts` stays the sole web colour home.
- No guard assertion is loosened. The rename guard gets stricter, because a blanket `**` allowance becomes one file-scoped entry.
- Applied migration `001_web_accounts.sql` stays byte-frozen, the same convention as 011/012.
- The Architecture section states its delta against the epic: one module's home moves, nothing is created, split or merged. The epic's present-tense paths are updated, and it says why.
- The Forbidden list (no symlink, no package alias, no migration edit) fits the contract.

**4. Non-goals and decided defaults: yes.**
Non-goals are explicit. D1–D10 decide every choice, and no open question is left.

## Minor (non-blocking, for the plan/implementation)

- **R8's literal `npm run web -- --port 5174` does not forward `--port`.** The root `web` script is itself `npm run dev --workspace …`. Args after `--` get appended to that inner `npm run` command line before its own `--`, so npm reads `--port 5174` as an npm config flag, not a Vite argument. With `strictPort` and the user's Vite holding 5173, Vite would then fail to bind. R8's parenthetical "(or the equivalent Vite invocation from the root through the workspace)" already allows the working form, `npm run dev --workspace web-planet-chat -- --port 5174`, so the criterion is still satisfiable. The implementer should use that form rather than debug the literal one. Plain `npm run web` is still proven at landing on 5173.
- **Epic prose rewording.** The epic's line 37 (dw-1 history) and line 559 (dw-19's "the `web-divination/` folder and package keep …") must be reworded as history without spelling the old name, or R4's second clause fails. Revision note 03 already records this.
