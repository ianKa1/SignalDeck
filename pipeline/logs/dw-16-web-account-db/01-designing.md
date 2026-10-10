# 01 — designing (2026-09-29)

- Worktree `../astrology-wt/dw-16-web-account-db`, branch `feature/dw-16-web-account-db` from `feature/divination_web` @ 2e6cfe8. Serial feature (wave of one), but run in a worktree because the user's backend (:8000) and Vite (:5173, HMR) run from the primary checkout — switching the primary checkout's branch would hot-swap their running app. `.env` and the three `.se1` files symlinked; npm install ok.
- Coordinator notice mid-design: the root `.env` now carries a HOSTED Neon `WEB_DATABASE_URL` (user ruling: use only after dw-16 lands). Folded into spec D16: conftest pops `WEB_DATABASE_URL`; live tests use `TEST_WEB_DATABASE_URL` (local hosts only); every backend run sets both URLs explicitly in the shell.
- Skills invoked: /frontend-design (import card, sync state, delete controls — reuse dw-12 threshold card, no new tokens), /feature-spec (pipeline mode), /architecture-designer (pipeline mode, Architecture section).
- Reads: db/__init__.py, db/migrations.py, accounts/{service,routes,google,tokens}.py, migrations 001/006, main.py lifespan/health, models.BirthData, core account/google-session.ts, divination/{session-log,transcript,types,index}.ts, birth-data/store.ts, web platform/{auth,boot}.ts, auth/*, session.ts, useSessions, useBirthData, test_boundaries db/divination pins, test_auth_integration recipe.
- Spec written: pipeline/specs/dw-16-web-account-db.md (17 decided defaults, Architecture, 40 criteria incl. U1 [USER-INPUT]).
- Status: designing → spec-review.
