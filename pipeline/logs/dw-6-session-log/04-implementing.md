# 04 implementing — dw-6-session-log (worker #3)

Worktree `/Users/kaimao/Projects/astrology-wt/dw-6-session-log`, branch `feature/dw-6-session-log`. Skills: `/git-commit` per step (autonomous overrides), `/frontend-design` before step 6.

## Step 0 — worktree prep (checked)
- `git branch --show-current` → `feature/dw-6-session-log`.
- `.env -> /Users/kaimao/Projects/astrology/.env`; `server/data/{seas,semo,sepl}_18.se1` symlinks; no `server/data/*.db` at all (none shared). `node_modules/@astrace/core` resolves.
- NOTE: the shared `.env` sets `DATABASE_URL` (a Neon Postgres). pytest does not read .env (conftest keeps the shell's DATABASE_URL, unset here). For validating, uvicorn must run with `DATABASE_URL=` overridden empty.
- Baseline server: `1035 passed, 50 skipped, 1 warning in 343.81s`.
- Baseline root `npm test`: app-native `Test Suites: 5 failed, 85 passed, 90 total` — timeouts under parallel-wave load (ring-pick 103 s, ring-roll 118 s, ask 123 s, city-picker). Rerun in isolation: `ring-pick + city-picker: Tests: 16 passed`, `ring-roll + ask: Tests: 66 passed`. web-divination: `Test Files 13 passed (13) / Tests 72 passed (72)`. Typecheck clean. Load flake, not a code failure.

## Step 1 — store, migration 011, evolved state pins
Files: `server/app/divination/store.py` (new), `server/app/db/migrations/011_divination_summary.sql` (new), `server/app/divination/__init__.py` (docstring), `server/tests/conftest.py` (DB_PATH redirect), `server/tests/test_boundaries.py`, `server/tests/test_divination_summary.py` (new, store cases), `CLAUDE.md` rules 9/10/11.
- Fence: `_DIVINATION_FENCE_EXEMPT_LINES` strips `from .. import db` from `divination/store.py` only (same mechanism as the restate borrow); self-check plants it in turn.py → caught.
- `test_divination_keeps_no_state` now exempts store.py only; self-check plants `INSERT INTO turns` in render.py → caught.
- New `test_divination_store_is_one_identity_free_table`: store.py SQL tables == {divination_summary}; CREATE TABLE columns == pinned list; `store.COLUMNS` and migration 011 == same list; planted `email` column caught.
- New `test_streamed_turn_never_imports_summary_or_store`: planted `from .store import get` in turn.py caught.
- Results: `pytest tests/test_boundaries.py -q` → `23 passed`; `tests/test_divination_summary.py` → `5 passed`; full server suite → `1042 passed, 50 skipped, 1 warning in 119.10s`.
- Commit: `2dcc64b (feat): dw-6-session-log — add the content-keyed divination summary store, migration 011 and its identity-free pins`.

## Step 2 — summary topic + request model
Files: `server/app/divination/summary.py`, `summary_role.txt` (new), `server/app/models.py` (`DivinationSummaryRequest` appended at EOF, with its own `from pydantic import model_validator` inside the appended block so the top-of-file import line is untouched — smaller landing-conflict surface with dw-5), tests appended to `test_divination_summary.py`.
- Topic registered (`role` asset, `lang.en`, `lang.zh`) before `FINGERPRINT`. Key = sha256 of the sorted compact dump of {topic, version, persona, lang, transcript(model_dump exclude_none)}. Truncation after strip, before emptiness check (question 200, toneNote 240). `generatedAtUtc` stamped by `generate_summary` (`…Z`), stored in `created_at`.
- Results: `tests/test_divination_summary.py tests/test_boundaries.py` → `46 passed`; full server → `1060 passed, 50 skipped, 1 warning in 110.34s`.
- Commit: `7e4f767 (feat): dw-6-session-log — add the divination_summary prompt topic and DivinationSummaryRequest`.

## Step 3 — job + route
Files: `server/app/generation.py` (`DIVINATION_SUMMARY_PRIORITY = 1`, `ensure_divination_summary`, docstring half-clause), `server/app/main.py` (`POST /api/divination/summary`, function `divination_summary`; the module is imported as `summary_topic` so the route keeps the spec's name), `server/tests/test_boundaries.py` (importers exactly `["generation.py","main.py"]` with a planted third importer in interpretation/service.py caught; `GENERATE_ON_REQUEST_RE` gains `generate_summary` + self-check), route tests (S2, S3 threaded with JOBS_SYNC removed + event-blocked fake + enqueue spy showing the second POST's ensure deduped, S5 502/no row + 200-char cut, S6 seven 422s with no fake call, S7 503 + no job + stored hit served), `CLAUDE.md` rule 10 (generation.py may import divination for the summary job) and rule 14 half-clause.
- S10: `git diff 2f45dfb --stat -- server/app/divination/turn.py server/app/divination/render.py server/app/llm.py` → empty.
- Results: `tests/test_divination_summary.py` → `37 passed`; `tests/test_boundaries.py` → `23 passed`; full server → `1074 passed, 50 skipped, 1 warning in 126.42s`.
- Commit: `d8857b0 (feat): dw-6-session-log — add the summary job and POST /api/divination/summary (200 hit, 202 ensure, 502 failed, 503 keyless)`.

## Step 4 — core summary client + clearTranscript
Files: `packages/core/src/divination/summary.ts` (new: TONES/isTone, SummaryRequest/SummaryWire, summaryWire, fetchSummary on postJson/pollDelay/MAX_POLLS), `transcript.ts` (`clearTranscript` appended at EOF), `index.ts` (one appended export block), `web-divination/src/log/core-session-log.test.ts` (new).
- Deviation: `clearTranscript` is NOT re-exported from the barrel. The app-native public-api guard ("every core barrel export is consumed somewhere or carries a declared intent") failed with `+ "divination/clearTranscript"`: only core's own session-log calls it (via `./transcript`), so a barrel export would be an orphan. Not weakened — the export was dropped.
- Results: `npx vitest run src/log/core-session-log.test.ts` → `Tests 9 passed (9)` (C3, C4 spacing = POLL_INTERVAL_MS, C5 502/503/rejected/invalid tone/MAX_POLLS+1 202s); root app-native jest: `Tests: 1068 passed` + architecture.test.ts rerun `38 passed` after the fix; web vitest `Test Files 14 passed (14) / Tests 81 passed (81)`; `npm run typecheck` → 0 errors.
- Commit: `355d212 (feat): dw-6-session-log — add core's summary poll client and clearTranscript`.

## Step 5 — core session log
Files: `packages/core/src/divination/session-log.ts` (new), `index.ts` (appended export block), `web-divination/src/log/core-session-log.test.ts` (C1–C8 added).
- KV key `astrology.divination.sessions.v1`, cap 50 newest-first, corrupt → `[]`, snapshot cached by raw string, listeners; `s-<ms>` id bumped by 1 ms when taken (Date only, no randomness); in-flight Set registered synchronously before the first await; parse keeps valid entries verbatim (dice survive). `SessionDie`/`sessionFacts` read `dice` structurally (BODIES, SIGNS via `../chart/types` per the `chart-view/frame.ts` precedent, integer house 1–12).
- `grep -nE "fetch\(|window|localStorage|Math.random" packages/core/src/divination/{summary,session-log}.ts` → nothing.
- Results: `core-session-log.test.ts` → `Tests 25 passed (25)`; root `npm test`: app-native `Test Suites: 90 passed, 90 total / Tests: 1069 passed, 1069 total`, web `Test Files 14 passed (14) / Tests 97 passed (97)`; typecheck 0 errors.
- Commit: `b0d2155 (feat): dw-6-session-log — add core's device session log: end, resume, retry and session facts`.

## Step 6 — card, i18n, styles (`/frontend-design` loaded first)
Files: `web-divination/src/i18n/{en,zh}.ts` (`log` namespace inserted before `chat`: End, Sessions · {n}, backs, empty text, sealing/failed, six tones — zh 期盼/不安/温柔/两难/释然/怅惘 — and the house template `{planet} · {sign} · house {house}` / `第{house}宫`), `src/i18n.test.ts` (Record<Tone,string> binding + tone test), `src/log/SummaryCard.tsx`, `src/log/log.css`, `src/log/SummaryCard.test.tsx` (new).
- D12 "sealed plate": ♀ wax seal (press 1.15→1, 420 ms, only on a pending→ready transition watched by the card), small-caps eyebrow persona · date, display-serif italic question in curly quotes, hairline, glyph-only chart seals with the chat chips' accessible names, dashed dice chips glyph · sign glyph · house, tone word in venus small caps + dim italic toneNote. Pending: shimmering opening line + three-star "sealing" status. Failed: opening line, error, Retry. `onOpen` renders the card as ONE button (spans inside, aria-label = question/opening line — date). Colours only `var(--…)`.
- Deviation: `web-divination/vite.config.ts` gains `test.css: { include: [/log\.css/] }`. Vitest blanks CSS by default and that also empties `?raw` imports (probe: `GLOB 0`; with the include: `RAW 9947`), so W8 could not read the stylesheet otherwise; no node types were added to the browser tsconfig instead.
- Results: `npx vitest run src/log src/i18n.test.ts` → `Tests 40 passed (40)`; root `npm test`: app-native `90 passed / 1069 passed` (colour guard incl.), web `Test Files 15 passed (15) / Tests 107 passed (107)`; typecheck 0 errors.
- Commit: `913d473 (feat): dw-6-session-log — add the sealed-plate summary card, its styles and the log i18n namespace`.

## Step 7 — hook, bar, screen, App swap
Files: `web-divination/src/log/{useSessions.ts,SessionBar.tsx,SessionsScreen.tsx,SessionTranscript.tsx}` (new), `SessionBar.test.tsx`, `SessionsScreen.test.tsx` (new, App-level integration with `vi.resetModules` + dynamic imports as in app/App.test.tsx), `app/App.tsx` (`view` state; SessionBar above ChatPanel; the swap), `log.css` (`.layout.layout--sessions` single column), `SummaryCard.tsx` (exports `RefGlyphs`, shared with the reader's seals).
- Formatting: new/edited TS files run through prettier with the repo's style (`--single-quote --no-semi --print-width 100`); this also re-wrapped a few long lines in the step-4..6 files.
- Done-when: `grep -rnE "fetch\(|apiUrl|#[0-9a-fA-F]{3,8}\b|rgb\(" web-divination/src/log` → nothing; `git diff 2f45dfb --stat -- web-divination/src/chat web-divination/src/chart web-divination/src/theme packages/core/src/divination/types.ts` → empty (W9).
- Results: `npx vitest run src/log` → `Tests 41 passed (41)` (W1, W2, W4, W5 ×2, W6, W7 relabel); root `npm test`: app-native `Test Suites: 90 passed, 90 total / Tests: 1069 passed, 1069 total` (G1–G9, colour, barrel-consumer guards), web `Test Files 17 passed (17) / Tests 114 passed (114)`; typecheck 0 errors.
- Commit: `6c40436 (feat): dw-6-session-log — add End session, the Sessions screen and the read-only transcript reader`.

Transition: implementing → validating.
