# Implementation Plan: dw-12-google-sign-in

Spec: `pipeline/specs/dw-12-google-sign-in.md` (WHAT + Architecture, PASS in
`logs/dw-12-google-sign-in/02-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Parallel wave with dw-7 (worker 1) and
dw-9 (worker 2); dw-12 lands LAST.

Worktree `/Users/kaimao/Projects/astrology-wt/dw-12-google-sign-in`, branch
`feature/dw-12-google-sign-in`, worker #3: backend :8003, Vite :5176. Every
command runs from the WORKTREE root; pipeline files by absolute path under
`/Users/kaimao/Projects/astrology/pipeline/`. Steps 0–5 are `implementing`,
6 is `validating`, 7 is `docs-sync`. Tick a box only after its done-when
passed and its `/git-commit` landed (`(<type>): dw-12-google-sign-in —
<summary>`). Load `/frontend-design` before step 5. Automated tests use
fakes only: a monkeypatched `app.accounts.google._verify_token` (never
Google), stubbed `fetch` and a stubbed `platform/google` on the web.
Server: `conda run -n astrology pytest -q` from `server/`. Web:
`npx vitest run <file>` from `web-divination/`. Root: `npm test`,
`npm run typecheck`.

**THE SHARED DATABASE.** The repo `.env` (a symlink here) sets
`DATABASE_URL` to a SHARED remote Postgres. Never use it: never start the
backend with `--env-file .env` in this feature, and never export `.env`.
Every live-PG test and real-app run uses a THROWAWAY local cluster:
`initdb`/`pg_ctl`/`createdb` from the conda env, data dir in a scratch dir
OUTSIDE the repo (`mktemp -d /tmp/dw12-pg.XXXX`), a free port (check with
`lsof -i :54312`; use 54312 unless taken), the recipe in
`server/tests/test_auth_integration.py:1-12`. Stop it (`pg_ctl stop`) and
delete the dir after each use; record host `127.0.0.1` in the log.

## Settled review notes

- **N1 (refresh deadlock).** `webTokenStore.refresh` sends its POST with a
  plain `fetch(apiUrl('/api/auth/token/refresh'))` (G3 allows it in
  `platform/`), never `apiFetch`, so a refresh-401 cannot re-enter the
  provider. No refresh token → resolve `false` with no request. C3's
  refresh-401 case asserts `restoreGoogleSession()` settles within 2 s.
  Native `tokenStore.ts` has the same latent re-entry; reported, not fixed.
- **N2.** G2's sentinel half cannot fail, so the mechanism is pinned by a
  source check on `web-divination/vite.config.ts` (new guard G13): no
  `envDir`, no `envPrefix`, `loadEnv`'s third argument exactly
  `'GOOGLE_CLIENT_ID'`, exactly one `define` key
  (`import.meta.env.VITE_GOOGLE_CLIENT_ID`) built from
  `env.GOOGLE_CLIENT_ID` (shell `VITE_GOOGLE_CLIENT_ID` first), no spread
  of `env`. The G2 build still runs for the positive half.
- **N3.** The new web guard is **G12** (G10/G11 exist).
- **N4.** R5's unavailable check starts from a pair minted BEFORE the
  no-db restart and present in KV.
- **N5.** R1 checks the injected `gsi/client` script plus the button slot,
  not a rendered iframe (a placeholder id may render nothing).
- **N6.** U1 runs on a FRESH throwaway cluster with `ANALYSIS_LLM=claude-cli`
  exported to the backend; "exactly one `users` row for that email".
- **N7.** `google.py` keeps ONE module-level transport: a small
  `google.auth.transport.Request` wrapper over one
  `google.auth.transport.requests.Request(session=requests.Session())` that
  memoizes GET responses to Google's certs URL for 1 h. `_verify_token`
  stays the only google-auth call; the wrapper gets a db-free test with a
  counting fake inner request.
- **N8.** `renderGoogleButton` maps app `zh` → GIS `locale:"zh_CN"`, `en`
  → `"en"`; W6 asserts `zh_CN`. `vite.config.ts` `css.include` becomes
  `[/log\.css/, /auth\.css/]`.

## Steps

- [x] **0. Verify worktree prep (coordinator did it; this step only checks).**
  Branch is `feature/dw-12-google-sign-in`; `node_modules/@astrace/core`
  resolves; `.env` and the three `server/data/*.se1` are symlinks; no
  `server/data/*.db` is a symlink; `env | grep DATABASE_URL` prints nothing.
  Done when: those `ls -l`/`git branch` checks agree; `conda run -n astrology
  python -c "import google.auth, google.oauth2.id_token, requests"` works;
  `ls ~/miniconda3/envs/astrology/bin/{initdb,pg_ctl,postgres,createdb}`
  lists four; root `npm test`, `npm run typecheck` and server pytest are
  green BEFORE any edit.

- [x] **1. The verifier and its single-importer pin.**
  Files: `server/app/accounts/google.py` (new), `server/requirements.txt`
  (`google-auth[requests]>=2.30`), `server/tests/test_google_auth.py` (new,
  db-free half), `server/tests/test_boundaries.py`
  (`test_only_google_module_imports_google_auth` APPENDED + planted-import
  self-check), `CLAUDE.md` (rule 3 sentence).
  `GoogleUnconfigured`/`GoogleUnavailable`, `_verify_token`,
  `verified_email`, the cached cert transport (N7).
  Done when: S2 and S9 pass, the transport test shows one inner fetch for
  two verifications, `grep -n google-auth server/requirements.txt` hits, and
  the full server suite is green.

- [x] **2. Service and route.**
  Files: `server/app/accounts/service.py` (`sign_in_google`),
  `server/app/accounts/routes.py` (`GoogleBody`, `POST /google`),
  `server/tests/test_google_auth.py` (route + static S8 + env-guarded
  live-PG class), `CLAUDE.md` (rule 12 Google paragraph, server bullets).
  `_require_db` first; expired-row cleanup, `_upsert_user`, `_mint_bearer`
  on one connection; native body; no cookie.
  Done when: without `DATABASE_URL`, S1, S3 and S8's source scan pass (live
  class SKIPS); then, on a throwaway cluster,
  `DATABASE_URL=postgresql://astrace@127.0.0.1:54312/astrace_dw12 conda run
  -n astrology pytest tests/test_google_auth.py tests/test_auth_integration.py
  -q` shows S4–S7 and S8's caplog case PASSED, zero skips; cluster stopped
  and deleted; full suite green.

- [x] **3. Core session and the web token store.**
  Files: `packages/core/src/account/google-session.ts` (new),
  `packages/core/src/account/index.ts` (one APPENDED export block),
  `packages/core/src/platform/{auth,api}.ts` (comments only),
  `web-divination/src/platform/auth.ts` (new `webTokenStore`, N1),
  `web-divination/src/platform/boot.ts` (step 6 + header comment),
  `web-divination/src/auth/core-google-session.test.ts` (new).
  Idempotent `restoreGoogleSession` (one in-flight promise), the status
  channel with a stable snapshot, sign-in/out per DD6/DD7.
  Done when: C1–C7 pass (C3 incl. the 2 s settle; C7's source check and
  one refresh POST for two concurrent 401s); `grep -nE
  "service|sync|profile|identity-lifecycle"
  packages/core/src/account/google-session.ts` finds no import; root
  `npm test` (the app-native guards walk core; the public-API guard sees
  the web consumer) and `npm run typecheck` are green.

- [x] **4. GIS loader, client-id plumbing and the guards.**
  Files: `web-divination/src/platform/google.ts` (new),
  `web-divination/src/platform/google.test.ts` (new, W7),
  `web-divination/vite.config.ts` (`loadEnv(mode, <repo root>,
  'GOOGLE_CLIENT_ID')`, one `define`, `css.include` + auth.css; config
  becomes the function form), `web-divination/src/vite-env.d.ts` (type for
  the key, if the tree has none), `.env.example` (key + origins comment),
  `app-native/src/architecture.test.ts` (G12 + G13 with self-check bites,
  appended), `CLAUDE.md` (Commands paragraph).
  Done when: W7 passes; G12 and G13 pass and bite (synthetic
  `accounts.google.com` in `auth/SignInScreen.tsx`; a planted `envPrefix`);
  `GOOGLE_CLIENT_ID=dw12-test.apps.googleusercontent.com
  TOKENROUTER_API_KEY=dw12-sentinel-secret npm --workspace web-divination
  run build` then `grep -rl dw12-test web-divination/dist` hits and
  `grep -rl dw12-sentinel web-divination/dist` is empty; root suites green.

- [x] **5. Gate, chip, i18n, styles, mount (load `/frontend-design` first).**
  Files: `web-divination/src/i18n/{en,zh}.ts` (`auth` namespace APPENDED
  after `bodies`), `web-divination/src/auth/{AuthGate,SignInScreen,
  AccountChip}.tsx`, `useGoogleSession.ts`, `auth.css` (new),
  `AuthGate.test.tsx`, `SignInScreen.test.tsx` (new; W1–W6),
  `web-divination/src/app/Header.tsx` (`<AccountChip/>` left of the
  toggle), `web-divination/src/main.tsx` (`<AuthGate><App/></AuthGate>`),
  `CLAUDE.md` (backend paragraph; rule 12 web sentence).
  DD11/DD12 exactly; colours only `var(--…)`; reduced-motion block; the
  decorative ring is static SVG, `aria-hidden`, computes nothing.
  Done when: `npx vitest run src/auth src/i18n.test.ts` passes W1–W6 (W6:
  `locale:"zh_CN"`); root `npm test` (G1, G3, G4, G9, G12, G13, colour and
  text guards) and `npm run typecheck` are green; `grep -rnE
  "#[0-9a-fA-F]{3,8}\b|rgb\(" web-divination/src/auth` prints nothing;
  `grep -n "dw-12" CLAUDE.md` shows the backend paragraph, Commands, rules 3
  and 12 (G3 criterion); `git diff feature/divination_web --stat` touches
  no `app-native/src` file but `architecture.test.ts`, and nothing under
  `web-divination/src/{chat,log,chart}` or `server/app/{divination,main.py,
  models.py,db}`.

- [x] **6. Validating: the real app (R1–R5; U1 pending user input).**
  Leave :8000/:5173 and dw-7/dw-9's 8001–8002/5174–5175 alone. Start a
  throwaway cluster (preamble). Backend, WITHOUT `--env-file`, explicit env
  only: `DATABASE_URL=postgresql://astrace@127.0.0.1:54312/astrace_dw12
  CORS_ALLOW_ORIGINS=http://localhost:5176 ANALYSIS_LLM=claude-cli
  GOOGLE_CLIENT_ID=dw12-placeholder.apps.googleusercontent.com conda run
  --no-capture-output -n astrology uvicorn app.main:app --app-dir server
  --port 8003`. Web: `cd web-divination && VITE_API_BASE=http://localhost:8003
  GOOGLE_CLIENT_ID=dw12-placeholder.apps.googleusercontent.com npx vite
  --port 5176`. Drive with claude-in-chrome (`read_network_requests`,
  `javascript_tool` for KV writes, screenshots of gate and chip).
  Mint pairs with a scratch-dir script (`_upsert_user` + `_mint_bearer` on
  the throwaway db, `PYTHONPATH=server`), its text and output pasted into
  the log; never committed. R3 deletes the access row with `psql`. R5:
  mint + place a pair, restart the backend with `DATABASE_URL` unset,
  reload → unavailable; then Vite with `GOOGLE_CLIENT_ID=` and
  `VITE_GOOGLE_CLIENT_ID=` empty → unconfigured.
  Done when: R1–R5 are recorded with observed values in
  `logs/dw-12-google-sign-in/NN-validating.md`, U1 is recorded as
  **PENDING USER INPUT** (needs a real `GOOGLE_CLIENT_ID` with origins
  :5173/:5180 and a Google account — not runnable by the worker, never
  faked, no status held back for it), and uvicorn, Vite and the cluster are
  stopped and its dir deleted.

- [x] **7. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (via `/update-architecture-doc`: the
  Google route, `accounts/google.py`, core `google-session`, web
  `platform/{auth,google}.ts` and `auth/`, the forced gate),
  `docs/features/dw-12-google-sign-in.md` (new, same shape as dw-6's).
  Do NOT edit the epic: report its delta to the coordinator in the
  handback (a "Built so far" line; the new accounts section: forced web
  gate, UI gate not access control, Postgres now required to open the web
  app; the native refresh re-entry note from N1; U1 pending).
  Done when: the docs name `POST /api/auth/google`, `verified_email`,
  `webTokenStore`, `AuthGate` and `astrace.auth.access`; `git diff
  feature/divination_web...HEAD --stat -- docs` shows both files.

## Acceptance map

| Criterion | Step |
|---|---|
| S1 dormant 503, verifier not called | 2 |
| S2 claim policy | 1 |
| S3 422s, 401, no Set-Cookie | 2 |
| S4 live-PG happy path | 2 |
| S5 upsert by email | 2 |
| S6 nothing but email | 2 |
| S7 logout revokes | 2 |
| S8 no secret logging | 2 |
| S9 single importer, requirements | 1 |
| C1–C7 core session, single-flight | 3 |
| W1 gate, auth-only fetches | 5 |
| W2 sign-in → app + chip | 5 |
| W3 invalid/unavailable/checking/offline | 5 |
| W4 unconfigured, no GIS calls | 5 |
| W5 sign-out, birth data kept | 5 |
| W6 zh copy, `zh_CN`, parity, reduced motion | 5 |
| W7 loader, button options | 4 |
| G1 G12 + existing guards green | 4 (G12), 5 (all) |
| G2 client id in bundle; G13 source pin | 4 |
| G3 CLAUDE.md amendments | 1, 2, 4, 5 (checked at 5) |
| R1–R5 real app | 6 |
| U1 live Google popup | **user input** (recorded pending at 6) |

## Deviations (for journaling)

- G2's negative (sentinel) half is replaced by the G13 `vite.config.ts`
  source pin; the build's positive half stays (N2).
- W6 asserts `locale:"zh_CN"`, not `"zh"` (N8).
- `webTokenStore.refresh` uses plain `fetch(apiUrl(…))`, not `apiFetch`
  as the contract said (N1).
- `google.py` gains a module-private cached cert transport and one test
  outside the criteria (N7).
- R5 precondition (pair minted before restart), R1's button check, U1's
  fresh cluster and row wording follow N4–N6.

## Risks for the implementer

- **Landing last.** dw-7 and dw-9 land first. Expect conflicts in
  `i18n/{en,zh}.ts` (keep their `persona`/`chat` hunks; `auth` stays
  last), `test_boundaries.py` (append after theirs), `architecture.test.ts`
  (they may add guards: renumber to the next free G-numbers if G12/G13 are
  taken, and fix the criterion names in the log), CLAUDE.md (they touch
  rules 9–11; dw-12 the backend paragraph, Commands, rules 3 and 12), and
  `vite.config.ts` `css.include` if either adds a stylesheet test. The
  coordinator merges `feature/divination_web` INTO this worktree; re-run
  steps 3–5's done-when there.
- **Sign-in rides `apiFetch`.** A 401 from `/api/auth/google` triggers
  `provider.refresh()`. It must return `false` with no request when there
  is no refresh token, or C5's 401 case records a stray refresh. With kept
  tokens (`unavailable`/`offline`), a sign-in 401 would first try a
  refresh; that is acceptable, but assert the final outcome, not the
  request count, in any such case.
- **StrictMode double mount.** `AuthGate`'s mount effect runs twice in dev;
  share one in-flight restore or W1/R1 see two `whoami` calls.
- **Module-level hydration vs test-setup.** `test-setup.ts` clears
  localStorage after every test, but `webTokenStore` hydrates at import.
  Give tests a way to re-hydrate (or `vi.resetModules`) and reset the core
  channel between tests; seed KV before the import where a case needs it.
- **The gate must precede every fetching mount.** `session.ts` stays (it
  only writes the local profile); nothing that calls `subscribeChart`,
  `resumeSummaries` or the chat store may mount outside `AuthGate`'s
  signed-in branch. W1's "no fetch with empty KV" catches a leak.
- **`loadEnv` prefix match.** Its third argument is a PREFIX:
  `GOOGLE_CLIENT_ID_SECRET` would also load. Read only
  `env.GOOGLE_CLIENT_ID`; never spread `env` into `define`. Shell vars with
  the prefix override `.env`, which is how R5 and G2 set or blank the id
  without touching the shared `.env` symlink.
- **Live-PG tests are env-guarded.** Without `DATABASE_URL` they skip and
  the suite is "green"; a skip is not a pass. Check the pytest summary for
  zero skips in `test_google_auth.py` on the throwaway run. `app.main`'s
  lifespan migrates whatever `DATABASE_URL` points at — one more reason
  the shell must never carry the shared URL.
- **`email_verified` type.** Accept only boolean `True`; the string
  `"true"` is a rejection (S2). `TransportError` must be caught before the
  generic `ValueError`/`Exception` branch.
- **Vite port.** `vite.config.ts` pins 5173 with `strictPort`; keep that,
  and pass `--port 5176` on the command line. U1's origins are 5173/5180
  only, so a live popup on :5176 would fail by design.
