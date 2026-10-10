# 07 merge — dw-12-google-sign-in (worker #3, coordinator request after dw-7 + dw-9 landed)

`git merge feature/divination_web` (at `c4342d6`) inside the worktree → merge commit `05fd511` `(chore): dw-12-google-sign-in — merge feature/divination_web (dw-7, dw-9) and resolve conflicts` (parents `31d5b3a`, `c4342d6`).

## Conflicts and resolutions
- `web-divination/src/i18n/en.ts`, `zh.ts`: both appended a namespace after `bodies`. Kept dw-7's `persona` block, then dw-12's `auth` — `auth` stays LAST (en: bodies :183, persona :198, auth :212; zh: bodies :172, persona :187, auth :201). dw-9's `chat` keys auto-merged.
- `web-divination/vite.config.ts`: kept dw-12's function form with `loadEnv(mode, repoRoot, 'GOOGLE_CLIENT_ID')` and the single `define` UNCHANGED (G13's pinned shape), and merged the css list to `[/log\.css/, /persona\.css/, /chat\.css/, /auth\.css/]` with the combined comment.
- `docs/ARCHITECTURE.md` (4 hunks): i18n namespace list = theirs (`persona` (dw-7), dw-9 chat keys) + `auth` (dw-12); vitest Tests bullet = theirs + the dw-12 test-file sentence; Testing count re-derived from the merged run: `26 files / 248 tests as of the dw-12-google-sign-in merge`; Feature docs list = dw-7, dw-9, then dw-12.
- Auto-merged, checked: CLAUDE.md (4 dw-12 hits: backend paragraph, Commands, rules 3 and 12; dw-7/dw-9 rule sentences intact), `server/tests/test_boundaries.py` (`test_only_google_module_imports_google_auth` :730, bite :734), `app-native/src/architecture.test.ts` (G10 :935, G11 :858, G12 :1005, G13 :1030 — no numbering collision; dw-7/dw-9 added no G-numbers). No test weakened.

## Suites (post-merge)
- `npm test` → jest `Test Suites: 90 passed, 90 total` / `Tests: 1072 passed, 1072 total`; vitest `Test Files 26 passed (26)` / `Tests 248 passed (248)`.
- `npm run typecheck` → 0 errors.
- `cd server && conda run -n astrology pytest -q` → `1225 passed, 55 skipped, 1 warning in 107.18s`.
- Fresh throwaway cluster `/tmp/dw12-pg.n4j4` (127.0.0.1:54312): `DATABASE_URL=postgresql://astrace@127.0.0.1:54312/astrace_dw12 conda run -n astrology pytest tests/test_google_auth.py tests/test_auth_integration.py -q -rs` → `31 passed, 1 warning in 0.70s` (zero skips).

## Real-app smoke (ran for real)
Backend without `--env-file`; live env via `ps eww`: `DATABASE_URL=postgresql://astrace@127.0.0.1:54312/astrace_dw12`, `CORS_ALLOW_ORIGINS=http://localhost:5176`, `ANALYSIS_LLM=claude-cli`, `GOOGLE_CLIENT_ID=dw12-placeholder.apps.googleusercontent.com`; health `{"status":"ok","db":"ok","ephemeris":"ok"}`. Vite :5176 with the placeholder id; headless Chrome (:9333, fresh `/tmp/dw12-chrome.*` profile) via `scratchpad/dw12/cdp.mjs`; pair minted by `scratchpad/dw12/mint.py` for `dw12.merge@example.com` (user `89a0264e-…`).
- Gate before sign-in: title "Sign in to meet your planets", button slot present, no stage, no chat; :8003 requests `[]`.
- Minted pair + Beijing birth record in KV, reload → app: email `dw12.merge@example.com`, chat header "Your Venus", placement "♉︎in Taurus · 10th house · at home". Sent "What do I most need to hear about love right now?" → 4 slips (`.chat__slip`), first "I'm your Venus in Taurus in the tenth house, at home in my own sign, so I love s…" (claude-cli). Screenshot `scratchpad/dw12/merge-app.png`.
- Sign out → gate; auth keys `[null,null,null]`; birth record unchanged `true`; reload stays on the gate `true`.

## Teardown
uvicorn, Vite, Chrome killed; cluster stopped; `/tmp/dw12-pg.n4j4` and the Chrome profile deleted; `lsof` on 8003/5176/54312/9333 → 0 each. All scratch files under `scratchpad/dw12/`. The `.env` remote Postgres was never contacted.
