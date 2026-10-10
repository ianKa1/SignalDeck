# 03 planning — dw-12-google-sign-in

**Transition:** spec-approved → implementing (plan written; the coordinator creates the worktree `/Users/kaimao/Projects/astrology-wt/dw-12-google-sign-in` and dispatches worker #3, backend :8003, Vite :5176; dw-12 lands after dw-7 and dw-9).

**Skill:** `/imple-plan`, under PIPELINE.md's pipeline-mode override (Steps / Acceptance map / Risks only; no Code Structure, Calling Sequence, Data Flow or Test Plan). `/architecture-designer` not re-run: the structure is the spec's Architecture section.

**Reads:** CLAUDE.md; PIPELINE.md (Skills per stage, pipeline-mode overrides, Parallel waves, Blocked discipline); spec `specs/dw-12-google-sign-in.md`; review `logs/dw-12-google-sign-in/02-spec-review.md` (N1–N8); QUEUE entries dw-7/dw-9/dw-12 and their plans (shared-file overlap: i18n, test_boundaries.py, CLAUDE.md; neither touches vite.config.ts); precedent plan `plans/dw-6-session-log.md` and its planning log. Targeted code reads: `packages/core/src/platform/{auth,api,index}.ts` (apiFetch 401 → provider.refresh re-entry confirmed, N1), `packages/core/src/account/{index,types}.ts`, `packages/core/src/chart/service.ts` (chart start is lazy on subscribe), `packages/core/src/profile/store.ts` `login` (KV only), `web-divination/{vite.config.ts,package.json}`, `src/{main.tsx,session.ts,test-setup.ts}`, `src/platform/boot.ts`, `src/app/Header.tsx`, `src/i18n/en.ts` top-level keys, `app-native/src/architecture.test.ts` (G1–G11 incl. G10 public-API guard and G11 walk floor → new guards G12/G13), `server/app/accounts/service.py` (`_require_db`, `_upsert_user`, `_mint_bearer`, verify_native cleanup), `routes.py` route list, `server/tests/{conftest.py,test_auth_integration.py,test_boundaries.py}` (GENAI_RE), `server/app/main.py` lifespan (migrates whatever DATABASE_URL names; no dotenv in app/ outside examples), `server/requirements.txt`, `.env.example`, root `package.json`. Env checks: google-auth 2.56.2 + requests importable in conda `astrology`; `cachecontrol` absent (hence the hand-rolled cert cache, N7); `initdb/pg_ctl/postgres/createdb` present; root `.env` has no `GOOGLE_CLIENT_ID` key today (key names only inspected, no values).

**Output:** `pipeline/plans/dw-12-google-sign-in.md` — 8 steps (0 prep check; 1–5 implementing; 6 validating R1–R5 on a throwaway local Postgres, backend without `--env-file`, U1 recorded PENDING USER INPUT; 7 docs-sync, epic delta reported not edited). Acceptance map covers S1–S9, C1–C7, W1–W7, G1–G3, R1–R5, U1 (→ user input). `wc -w`: 1974.

**Review notes settled:** N1 plain-fetch refresh in web `platform/auth.ts` + C3 2 s settle assertion; N2 G13 source pin on vite.config.ts; N3 guard renamed G12; N4 R5 pair minted before no-db restart; N5 R1 checks script + slot; N6 U1 fresh cluster + `ANALYSIS_LLM=claude-cli`; N7 module-level 1 h cert-cache transport in google.py; N8 GIS `zh_CN`, css.include adds auth.css.

**Deviations (for the coordinator to journal):**
- G2 negative half replaced by the G13 vite.config.ts source pin (positive half kept).
- W6 asserts `locale:"zh_CN"` instead of `"zh"`.
- `webTokenStore.refresh` uses plain `fetch(apiUrl(...))`, not `apiFetch`.
- google.py gains a private cached cert transport plus one extra db-free test.
- R1/R5/U1 adjusted per N4–N6.
- Also to journal: native `app-native/src/account/tokenStore.ts` has the same latent refresh re-entry (out of scope).
