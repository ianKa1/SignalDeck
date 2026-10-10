# 06 docs-sync — dw-12-google-sign-in (worker #3)

**Skill:** `/update-architecture-doc` (diff-driven). Baseline: `docs/ARCHITECTURE.md` last touched at `b308a92`; diff `b308a92..HEAD` = the five dw-12 commits.

**docs/ARCHITECTURE.md edits (surgical):**
- Overview "Data core": accounts optional EXCEPT web-divination's forced Google sign-in (needs `DATABASE_URL` + `GOOGLE_CLIENT_ID`).
- Repo tree: web-divination `vite.config.ts` (loadEnv/define, G13), `main.tsx` (`<AuthGate><App/></AuthGate>`), `platform/` (boot step 6, `auth.ts`, `google.ts`), new `auth/` row, Header gains AccountChip; server `accounts/` row gains `google.py`.
- Guards: server boundary paragraph gains the google-auth pin; web guard paragraph gains G12 and G13.
- `core/platform`: `auth.ts` bullet (web-divination installs `webTokenStore`), `storage.ts` bullet (the web bearer store reads KV directly).
- Server `app/accounts/`: a **Google sign-in** paragraph (google.py, `verified_email`, `sign_in_google`, the route's wire, no cookie/migration, client twin is `google-session.ts` not `service.ts`).
- web-divination section: boot chain gains step 6; new **Sign-in gate** bullet (AuthGate, core google-session state machine, webTokenStore keys and plain-fetch refresh, GIS loader/button, SignInScreen states, AccountChip, auth.css); i18n namespace list gains `auth`; Tests bullet gains the four dw-12 test files.
- Testing: vitest count `23 files / 199 tests as of dw-12-google-sign-in`.
- Feature docs list: dw-12 entry.
Confirmed still accurate: Deployment (web local-only), native `app-native/src/account/` section (untouched by dw-12), Data flow.
Spot-check: every path written exists (`test -e` loop, no MISSING).

**docs/features/dw-12-google-sign-in.md** written in the WORKTREE (gitignored; not force-added): what it does, what was built, tests, deviations, known limitations. Note: the primary checkout's `docs/features/` holds the other feature docs; the coordinator may copy this file there when landing.

Done-when: `grep -c "POST /api/auth/google|verified_email|webTokenStore|AuthGate|astrace.auth.access"` → ARCHITECTURE.md 16 lines, feature doc 8 lines. The plan's `git diff … -- docs` shows only ARCHITECTURE.md because `docs/features/` is gitignored (expected).

**Transition:** docs-sync → (coordinator) accepting.
