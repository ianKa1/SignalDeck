# dw-12-google-sign-in · 01 designing (2026-09-28)

Stage worker for the coordinator (wave 2: dw-7 / dw-9 / dw-12, gates serial in the primary checkout). No code edited, nothing committed, nothing installed, QUEUE.md and DECISIONS.md untouched.

## Reads
- CLAUDE.md (disk): the backend and accounts paragraph, Commands, rules 1, 3, 5, 11, 12 and 14.
- PIPELINE.md: Skills per stage, the pipeline-mode overrides, Epic files, Spec requirements, Auto spec review, Parallel waves, Blocked discipline.
- QUEUE.md: the ROUND 2 comment and the dw-12 entry, plus the dw-7 and dw-9 entries for overlap.
- DECISIONS.md :3375-3438: the dw-12 user ruling, the round-2 coordinator entry (its risk: no GOOGLE_CLIENT_ID, "no local Postgres"), and the dw-7 and dw-9 spec and plan entries.
- epics/divination-web.md, in full.
- specs dw-7 and dw-9: file mentions only, for shared-file overlap.
- Server:
  - `accounts/service.py` (full) and `accounts/routes.py` (full);
  - `tokens.new_token` (token_urlsafe(32));
  - `db/__init__` `is_configured`/`health`;
  - migration 001 (`users.email citext`);
  - main.py CORS :102-112 and health;
  - `test_boundaries.py` regexes :15-72 and :160-190;
  - `tests/conftest.py`, and the `test_auth_integration.py` and `test_otp_auth.py` headers (the skipif live-PG recipe);
  - `requirements.txt`;
  - uvicorn `config.py` (`load_dotenv` without override, so a shell `DATABASE_URL` wins).
- Core:
  - `platform/auth.ts`, `api.ts`, `storage.ts`, `index.ts`;
  - `account/service.ts`, `types.ts`, `index.ts`;
  - `chart/service.ts` :85-111 (the chart fetch starts only on subscribe).
- Web:
  - `index.html`, `package.json`, `vite.config.ts`;
  - `src/main.tsx`, `platform/boot.ts`, `app/App.tsx`, `app/Header.tsx`, `session.ts`;
  - `i18n/index.ts`, the `en.ts` namespaces, the `theme/tokens.ts` keys, and `app/app.css` (masthead).
- Native precedent: `app-native/src/account/tokenStore.ts`.
- Guards: `app-native/src/architecture.test.ts`, the web G1-G9 lines and G3 :586-606.
- Root `package.json` scripts; the variable names in `.env` (values not read).

## Environment checks (read-only)
- `conda run -n astrology python -c "import google.auth…"`: google-auth **2.56.2** and requests **2.34.2** are already installed, pulled in by google-genai. Nothing was installed.
- `~/miniconda3/envs/astrology/bin/`: **initdb, pg_ctl, postgres (PostgreSQL 18.4), createdb are present**. This CORRECTS the coordinator's journaled risk: a non-shared throwaway Postgres IS available now, via the recipe in `test_auth_integration.py`. It is not a user input.
- `.env` has no GOOGLE_CLIENT_ID (confirmed by name). DATABASE_URL is set there (the Neon database). dw-12 runs must never use it.

## Skills (in order)
1. `frontend-design`: the gate "threshold" card (eyebrow, display title, email-only line, button slot, a faint static twelve-tick ring), the state lines, the masthead email plus "Sign out", no new tokens, reduced-motion fade → Decided defaults 11-12.
2. `feature-spec` (pipeline mode): Goal, Non-goals, Decided defaults 1-14, Acceptance Criteria.
3. `architecture-designer` (pipeline mode): Architecture (reuse table with file:line, module map, contracts, wire, forbidden edges, CLAUDE.md and guard amendments, shared files). No Migration Steps.

## Key choices
- GIS button ID token → `POST /api/auth/google {credential}` → the `google.py` claim policy (`email_verified is True`) → `_upsert_user` + `_mint_bearer` → the native body shape. No migration.
- Honest scope note: GIS consent names the basic profile and cannot be narrowed; the "openid+email minimum" holds for what is read and kept. The redirect `scope=openid email` flow was rejected (it needs redirect URIs the user was not asked for).
- The gate is a UI gate that fails closed. Divination and chart routes stay unauthenticated (epic: no identity in divination; routes shared with native; local-only). The gate wraps `<App/>` in main.tsx, so nothing that fetches mounts before sign-in. App.tsx is untouched.
- Core account `service.ts` is NOT reused: its sign-in starts profile sync to `/api/profiles` and its logout wipes local data. A new `account/google-session.ts` does neither.
- Web tokens go in the KV port (localStorage), accepted and stated. Sign-out revokes on the server, then clears locally whatever the answer. Device data is kept.
- One home for the client id: the root `.env` GOOGLE_CLIENT_ID. vite.config loadEnv exposes only that key.
- Without a db, the web app is unusable (the gate shows unavailable). Stated in the spec.
- Validation: a fake verifier (monkeypatch `google._verify_token`), live-PG tests on a throwaway cluster, and real-app runs without `--env-file .env`. A signed-in state without Google comes from a log-recorded mint script.

## Word counts (`wc -w`)
- Goal + Non-goals + Decided defaults: 1324 (budget ~1,500)
- Architecture: 1380 (budget ~1,500)
- Acceptance Criteria: 1253 (exempt)

## Shared files dw-12 will touch (landing surface)
- `web-divination/src/i18n/en.ts`, `zh.ts`: `auth` appended last (dw-7 appends `persona`; dw-9 edits inside `chat`).
- `server/tests/test_boundaries.py`: one appended test.
- CLAUDE.md: the backend paragraph, Commands, rules 3 and 12 (dw-7/dw-9 touch rules 9, 10 and 11).
- Also changed, but not touched by dw-7/dw-9: `accounts/service.py`, `accounts/routes.py`, `requirements.txt`, `.env.example`, `vite.config.ts`, `main.tsx`, `Header.tsx`, `platform/boot.ts`, core `account/index.ts` and `platform/auth.ts`/`api.ts` comments, and `app-native/src/architecture.test.ts` (G10 appended).
- NOT touched: main.py, models.py, migrations, `divination/`, `chat/`, App.tsx. dw-7's migration 012 is unaffected.

## User-input criteria
- Only **U1**, which needs GOOGLE_CLIENT_ID (an OAuth web client with authorized JS origins http://localhost:5173 and :5180) and a Google account to click through. Everything else (S1-S9, C1-C7, W1-W7, G1-G3, R1-R5) is runnable now.

## Transition
designing → spec-review
