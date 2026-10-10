# 09 — accepting

Fresh-context acceptance checker, 2026-09-29. Worktree `/Users/kaimao/Projects/astrology-wt/dw-19-rename-planet-chat`
(branch feature/dw-19-rename-planet-chat, HEAD 461ea8e, tree clean before and after). Criteria from the spec's
Acceptance Criteria (N1–N10, R1); exceptions judged against Decided defaults D3–D8, D11.

Suites (run by me):
- `pytest` (server/) with `DATABASE_URL= WEB_DATABASE_URL=` and `TEST_DATABASE_URL`/`TEST_WEB_DATABASE_URL` →
  fresh throwaway dbs `acc19_main`/`acc19_web` on 127.0.0.1:54316: **1495 passed, 50 skipped** (skips are pre-existing:
  DATABASE_URL-only OTP/profiles integration, synastry disabled, one fixture moon day; zero planet_chat/rename/web skips).
  Focused re-run `test_planet_chat_rename.py test_rename_guard.py test_planet_chat_auth.py`: 63 passed, 0 skipped.
- `npm test`: jest 91 suites / 1080 tests passed; vitest 47 files / 445 tests passed.
- `npm run typecheck`: clean (app-native and web-divination).

| # | Verdict | Evidence |
|---|---|---|
| N1 | PASS | See "N1 detail" below. Every remaining occurrence is a recorded exception; nothing the allowlist admits lacks a spec justification. |
| N2 | PASS | Planted `divination_planted = True` in `server/app/planet_chat/tags.py`: pytest `test_rename_guard.py` → 1 failed (`'server/app/planet_chat/tags.py:280: divination_planted = True'`); jest `src/rename-guard.test.ts` → 1 failed (same offender line). Reverted with `git checkout`; `git diff --quiet` clean. Both pass unplanted (full suites). Guards renamed, not weakened: `git diff bd158b2` — test_boundaries.py 40→40 tests, assert count 152→155; architecture.test.ts 47→47 tests, 134→134 expect calls, its only change is `divination`→`planet_chat` in `BARREL_DEEP_IMPORT_RE`. Every removed test_boundaries line maps 1:1 to a renamed added line except prose comments (reworded "planet chat") and `PLANET_CHAT_TABLES`, which gained a created-as field so the 011/012 column check still runs against the legacy CREATE TABLE, plus new ALTER-rename pins with a planted self-check. No assertion or self-check removed. Both guards read the single `rename-allowlist.json`; every entry must be used (anti-rot check). |
| N3 | PASS | Routes live at `/api/planet_chat/{turn,summary,persona,sheets}` (main.py; core `TURN_PATH`/`PERSONA_PATH`/`SHEETS_PATH`/`SUMMARY_PATH`). Moved tests `test_planet_chat_{turn,summary,persona,roster,auth,...}.py` all green. dw-18 gate pinned on the new prefix: `test_boundaries.py::test_s5_every_planet_chat_route_requires_a_web_account` (`PLANET_CHAT_PREFIX = "/api/planet_chat/"`, planted-route self-checks) and `test_planet_chat_auth.py` over the four new paths. `test_n3_pre_rename_routes_are_404` ×4 green; live on :8003 `POST /api/divination/turn` → 404, unauthenticated `/api/planet_chat/sheets` → 401. |
| N4 | PASS | Golden hex in `test_planet_chat_rename.py` (summary `41f0a83e…c6cf`, voice `e370a201…bcbc`) independently recomputed by me from a `git archive bd158b2` copy of the pre-rename server (old `app.divination`, `DivinationSummaryRequest`): identical. Tests assert the new code returns them and that swapping the topic changes the hex (self-check). |
| N5 | PASS | `test_n5_migration_013_renames_tables_and_keeps_rows` ran LIVE (not skipped) on a fresh db on :54316: migrate to 012, insert one row each, apply 013 → same columns, old names gone, `<table>_pkey` present and every constraint prefixed with the new table name, index = pkey only, both rows present, second pass applies nothing; `POST /api/planet_chat/summary` for that content → 200 with no job and no `generate_sections` call. Also seen on the real dev-copy in R1 (constraints listed there). |
| N6 | PASS | `test_n6_legacy_file_is_moved_renamed_and_served` (legacy file moved, no `divination.db` left, tables = `planet_chat_summary`/`planet_chat_voice`, both rows served), `test_n6_second_start_does_nothing` (target bytes unchanged, stray legacy file not adopted), `test_n6_no_legacy_file_creates_a_fresh_store`, `test_n6_only_the_default_file_name_is_bridged` — all green. Read `store.py`: bridge constants `_LEGACY_FILE_NAME`/`_LEGACY_RENAMES` only. |
| N7 | PASS | `test_n7_new_name` (5.0, no warning), `test_n7_legacy_name_is_a_fallback_with_one_warning` (7.0 twice, exactly one WARNING naming the old var), `test_n7_both_set_the_new_name_wins` (5.0, no warning) — green; `turn.turn_timeout_s()` code read and matches D4. |
| N8 | PASS | `web-divination/src/chat/core-planet-chat-legacy-keys.test.ts`: first read returns data under the new keys with old keys gone; any one reader migrates all three; second read in-process is a no-op (a re-planted old key is left alone); an existing new key is never overwritten (old still removed); no old keys → nothing written. `migrateLegacyKeys()` is called from `roster.ts`, `transcript.ts`, `session-log.ts`. Confirmed live in R1. |
| N9 | PASS | `rg -i 'divination|占卜'` over `web-divination/src/i18n/` and `web-divination/index.html`: no match, and none at bd158b2 either (`git grep` rc=1) — no such string existed, so none changed (D2: no new tagline text). `<title>` is `Astrace — the natal sky`. |
| N10 | PASS | CLAUDE.md names `app/planet_chat`, `/api/planet_chat/turn`, `planet_chat_summary`/`planet_chat_voice`, `PLANET_CHAT_TURN_TIMEOUT_S`, "PLANET CHAT WEB EPIC" (the one "formerly the DIVINATION WEB EPIC" parenthetical kept); remaining "divination" in it = `web-divination` paths, `dw-*-divination-*` slugs, the epic path. `server/app/ARCHITECTURE.md`: 0 "divination", names planet_chat. `docs/ARCHITECTURE.md`: planet_chat throughout; remaining hits are D3/D11/migration-file exceptions (N1 guard covers it). `.env.example`: its only 3 hits are `web-divination` workspace references + a dw-* slug; it never named the feature or `DIVINATION_TURN_TIMEOUT_S` at bd158b2, so D4 adds nothing — nothing to rename. Epic (`pipeline/epics/divination-web.md`, gitignored, primary checkout): Built so far, Target modules, Dependency rules and a dw-19 section use planet_chat; only the historical H1 keeps "divination web". Guards named in CLAUDE.md exist: `server/tests/test_rename_guard.py`, `app-native/src/rename-guard.test.ts`, and every `test_*planet_chat*` name CLAUDE.md cites resolves to a `def` in server/tests. |
| R1 | PASS | See "R1 detail". |

## N1 detail

`rg -i -n --hidden divination` over the worktree excluding `.git`, `node_modules`, `dist`, `pipeline/`, `docs/features/`
(320 lines outside `web-divination/` paths + all `web-divination` hits). After removing matches of the four global
patterns — `[Ww]eb-divination` (D3: path/package; `Web-divination` appears only as two docs/ARCHITECTURE.md headings),
`dw-\d+-…divination…` (D11; the only slug that occurs is `dw-18-divination-auth`, a real spec), `epics/divination-web.md`
(D11) and `01[12]_divination_(summary|voice)(.sql)?` (applied migration file names) — the complete remaining list is:

- `CLAUDE.md:23` — `(formerly the DIVINATION WEB EPIC, …)` — D11 one parenthetical.
- `server/app/db/migrations/011_divination_summary.sql`, `012_divination_voice.sql` — applied, byte-frozen migrations.
- `server/app/db/migrations/013_planet_chat_rename.sql:6,7,20,21` — D6 (the tables it renames; constraint loop).
- `server/app/planet_chat/store.py:56,58,59` — D7 legacy file name + two ALTER renames.
- `server/app/planet_chat/summary.py:37` `SUMMARY_KEY_TOPIC = "divination_summary"`; `voice.py:61`
  `VOICE_KEY_TOPIC = "divination_voice"` — D5 frozen key literals.
- `server/app/planet_chat/turn.py:102` `_LEGACY_TIMEOUT_ENV = "DIVINATION_TURN_TIMEOUT_S"` — D4.
- `packages/core/src/planet_chat/legacy-keys.ts:4,18` — D8 (`LEGACY_PREFIX` and its comment).
- Tests of those bridges: `server/tests/test_planet_chat_rename.py` (D4–D7/N3 inputs), `test_planet_chat_summary.py:66`
  / `test_planet_chat_persona.py:201` (011/012's CREATE TABLE text), `test_planet_chat_turn.py:25` (legacy env scrubbed),
  `test_boundaries.py:563,566` (011/012 created-as names, D6) and `:614` (planted `divination_log` self-check),
  `web-divination/src/chat/core-planet-chat-legacy-keys.test.ts:8-10` and `web-divination/src/auth/core-web-account.test.ts:590-592`
  (D8: seeds / the wipe clears leftover legacy keys).
- The rename guard itself: `server/tests/test_rename_guard.py`, `app-native/src/rename-guard.test.ts`, `rename-allowlist.json`.

Judgement: every item traces to D3–D8, D11, the applied migrations, or the guard's own allowlist/self-check. The
allowlist's test-file entries are not named verbatim in the spec, but each admits only the literal pre-rename inputs a
recorded bridge's test must use (path-scoped, narrow patterns), which is the minimum needed to test D4–D8 — not an
unjustified hole. No live identifier, route, log message, UI string, or doc prose outside these survives.

## R1 detail

- Dev cluster :54320 before: `astrace_dev` at `012_divination_voice`, divination_summary 4 / divination_voice 9;
  `astrace_web` 7 users. `createdb -T astrace_dev astrace_dev_acc19` (the copy; `astrace_dev` itself never pointed at).
- Pre-cached card check: with the BASE-commit code (bd158b2 archive) the Beijing 1990-06-15 08:30 venus/en voice key is
  `5c11b662…`, which is a row of the copy before my backend started (cached before the rename).
- Test user minted in astrace_web via `accounts/web/service._mint` (scratchpad `dw19acc_mint.py`):
  `dw19acc+96ca9f75@example.com` (id 6be51f36-…).
- Backend from the worktree on :8003: `DATABASE_URL=…54320/astrace_dev_acc19 WEB_DATABASE_URL=…54320/astrace_web
  CORS_ALLOW_ORIGINS=http://localhost:5176 ANALYSIS_LLM=claude-cli` (no `--env-file`). `/api/health` →
  `{"status":"ok","db":"ok","webDb":"ok","ephemeris":"ok"}`. Startup applied 013 on the copy: version
  `013_planet_chat_rename`, planet_chat_summary 4 / planet_chat_voice 9, constraints `planet_chat_summary_pkey`,
  `planet_chat_voice_pkey` + PG18 NOT NULLs all `planet_chat_*`. `astrace_dev` still at 012 with 4/9 afterwards.
- Vite :5176 (`VITE_API_BASE=http://localhost:8003`, strictPort); headless Chrome CDP 9325, profile `scratchpad/dw19acc-chrome`;
  driver `scratchpad/dw19acc-drive.mjs`, output `scratchpad/dw19acc-r1.out`.
- Seeded ONLY `astrology.divination.{sessions.v1, transcript.v1.venus, active.v1}` + birth data + the minted pair in
  `astrace.auth.{access,refresh,expiresAt}`.

Driver output (verbatim excerpts):
```
seeded keys: ["astrology.birthData.v1.traveler","astrology.divination.active.v1","astrology.divination.sessions.v1","astrology.divination.transcript.v1.venus"]
import body: This browser holds 2 conversations and a birth chart from before you signed in to dw19acc+96ca9f75@example.com.
keys after boot: ["astrology.birthData.v1.traveler","astrology.planet_chat.active.v1","astrology.planet_chat.sessions.v1","astrology.planet_chat.transcript.v1.venus","astrology.profile.v1"]
sessions list text: ♀ Venus·begun 27 Sept 2026 Acc: before the rename, is he near? In progress ☽ Moon·26 Sept 2026 “Why do Sundays feel so heavy?” Tone: wistful A quiet ache, named gently.
persona statuses: [0,200]
chat text has old entries: true
ok (9.6s): reply streamed and saved
venus transcript length (new key): 4
summary card: seal-card persona-scope seal-card--ready | “Is he near, and is it still you answering after the rename?”
  POST /api/planet_chat/persona 200
  POST /api/planet_chat/turn 200
  POST /api/planet_chat/summary 202 … 202 … 200
any /api/divination request: false
```
- Cached card hit: backend log shows exactly one `POST /api/planet_chat/persona` → 200 (the client's `0` is the aborted
  StrictMode duplicate that never reached the server); the only job line is `job planet_chat_summary: running …` — no
  voice job; planet_chat_voice stayed 9 rows (newest created_at unchanged); planet_chat_summary 4 → 5 (the new session).
- Screenshot `scratchpad/dw19acc-r1-reply.png`: Venus chat with the new streamed bubbles on the two-pane layout.

Teardown: Chrome, Vite, :8003 backend stopped; ports 8003/5176/9325 free; the user's :8000 (pid 6038) and :5173 (pid 6029)
untouched. Test user deleted (DELETE 1; web_access_tokens / web_refresh_tokens / web_birth_profiles / web_sessions rows
for it = 0); astrace_web back to 7 users. Dropped `astrace_dev_acc19`, `acc19_web`, `acc19_main`. Clusters left running.
Worktree `git status` clean.

**Overall: ACCEPTED — N1–N10 and R1 all PASS.**
