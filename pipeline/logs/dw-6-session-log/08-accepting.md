# 08 accepting — fresh-context acceptance check

Worktree `/Users/kaimao/Projects/astrology-wt/dw-6-session-log` at `3c86e58`
(feature/dw-6-session-log with feature/divination_web, which includes dw-4 and dw-5, merged in). The grader had not seen the implementation.

Runs:
- `server/`: `conda run -n astrology pytest -q` gave **1129 passed, 50 skipped**.
- Root `npm test`: app-native 90 suites / **1069 passed**; web-divination 19 files / **159 passed**.
- Root `npm run typecheck`: clean.

Real app setup:
- Backend `uvicorn` on :8003 with `ANALYSIS_LLM=claude-cli` and CORS for :5176. The repo `.env` DOES set `DATABASE_URL` (a Neon URL). To guarantee SQLite, the server ran with `DATABASE_URL=` AND a scratch copy of `.env` with the `DATABASE_URL` line removed. `/api/health` answered `"db":"unconfigured"`.
- Vite on :5176 with `VITE_API_BASE=http://localhost:8003`.
- Headless Chrome over CDP on a fresh profile, with network capture.
- Birth 1990-06-15 08:30 Beijing, entered through the form.
- The existing gitignored `server/data/divination.db` (5 rows from the maker) was moved aside for the run, so A6 counted only this run's rows. It was restored afterwards.

Fixed-base note: S10 and W9 name `git diff 2f45dfb`. That base predates dw-4 and dw-5, which were merged in afterwards, so a literal diff lists their files (for example `web-divination/src/chat/*`, `chart/*`, `packages/core/src/divination/types.ts`, and `render.py`). Those criteria were graded on intent, using dw-6's own changes: `git diff feature/divination_web...HEAD`.

| ID | Verdict | Evidence | Source |
|---|---|---|---|
| S1 | PASS | `test_s1_key_is_stable_hex_and_content_sensitive` covers 64-hex, stable, text/order/lang/VERSION change the key, FINGERPRINT does not. `test_s1_entries_carry_only_role_and_text_and_no_birth_data` covers the `{role,text}` dumps, no `birthData` field, and the same key with birthData in the body. | TESTS/CODE |
| S2 | PASS | `test_s2_miss_then_hit`: 200 with exactly the 7 keys and fake called once; the second POST gives an equal body with no further call. | TESTS/CODE |
| S3 | PASS | `test_s3_threaded_202_one_job_then_200`: JOBS_SYNC removed, blocking fake, two 202 `{"status":"generating"}`. The queue dedupes the one job key and the generator is called once total. After release the POST answers 200. | TESTS/CODE |
| S4 | PASS | `test_s4_prompt_and_schema[en/zh]`: the system text starts with `summary_role.txt` and ends with the `lang.<lang>` fragment. The schema is `SUMMARY_SCHEMA`, its `tone.enum == TONES`, and the user JSON is `{persona, transcript}` equal to T in order. | TESTS/CODE |
| S5 | PASS | `test_s5_bad_output_is_a_502_and_no_row` (ecstatic, blank question) gives 502 `summary unavailable` and no row. `test_s5_long_question_is_served_cut` stores and serves 200 chars. | TESTS/CODE |
| S6 | PASS | `test_s6_route_422_calls_no_fake`: all 7 cases give 422 with no fake call. | TESTS/CODE |
| S7 | PASS | `test_s7_no_provider_is_503_but_a_stored_hit_is_served`: 503 `divination unavailable`, no `divination_summary:` job, and a stored row is still 200. | TESTS/CODE |
| S8 | PASS | The column test, the doctrine==fingerprint check, migration 011 sorting last with the same columns, and the fake `db.connect` SQL (INSERT … ON CONFLICT (summary_key) / SELECT … FROM divination_summary WHERE summary_key) are all covered. The real `server/data/divination.db` mtime was unchanged across the full suite (1790640217 before and after). | TESTS/CODE |
| S9 | PASS | `test_boundaries.py` passes. I planted each offender in the real source, ran the file, and reverted. Every plant was caught: (1) `from .. import db` in turn.py failed the fence plus the no-state test; (2) `INSERT INTO turns` in render.py failed `test_divination_keeps_no_state`; (3) `from .store import get` in turn.py failed `test_streamed_turn_never_imports_summary_or_store`; (4) an `email TEXT` column in store.py failed `test_divination_store_is_one_identity_free_table`; (5) a third importer (app/jobs/__init__.py) failed `test_no_tier_imports_divination`; (6) `summary_topic.generate_summary(` in main.py failed `test_delivery_never_generates_on_the_request_path`. The three named tests pass. | TESTS/CODE (planted) |
| S10 | PASS (intent) | `git diff feature/divination_web...HEAD -- turn.py render.py llm.py` is empty. The literal `2f45dfb` diff is non-empty only because of dw-4/dw-5's merged changes. No turn/render test file is in dw-6's diff, and those suites pass (114 selected tests pass). | TESTS/CODE |
| C1 | PASS | `canEndSession (C1)` covers exactly the five listed cases. | TESTS/CODE |
| C2 | PASS | `C2: archives a pending record…` checks the record fields, first in the list, transcript `[]`, the subscriber notified, and one POST with `{persona, lang:'zh', transcript: toWire(entries)}`. The null / no-write case is covered too. | TESTS/CODE |
| C3 | PASS | `summaryWire (C3)`: 45 entries give 40, numbered 1–2 then 8–45. | TESTS/CODE |
| C4 | PASS | fetchSummary makes 3 identical POSTs spaced `POLL_INTERVAL_MS` apart. The record goes `ready` with the 200's fields and subscribers are notified. | TESTS/CODE |
| C5 | PASS | 502, 503, rejected fetch, ecstatic 200 and MAX_POLLS+1 202s each leave the record `failed`. Retry sets `pending`, re-POSTs, and a 200 makes it `ready`. | TESTS/CODE |
| C6 | PASS | `resumeSummaries (C6)`: one POST, and none on the second call while it is in flight. | TESTS/CODE |
| C7 | PASS | Refs are unioned first-seen, deduplicated and capped at 8. Pluto/Scorpio/8 dice are kept; house 13, Ophiuchus and user-entry dice are dropped. Dice entries survive a reload verbatim. | TESTS/CODE |
| C8 | PASS | The 51st session gives 50 records and the oldest is evicted. `"{"` lists `[]` without throwing. | TESTS/CODE |
| W1 | PASS | SessionBar W1 test. Real app agrees: End was disabled right after Send and enabled after the stored reply. | TESTS + REAL APP |
| W2 | PASS | SessionBar W2 test: greeting only, a pending card with the opening line and "Venus is sealing this session", then the quoted question, tone, toneNote, ♀ and seals named as the chips. No dice row. | TESTS/CODE |
| W3 | PASS | SummaryCard W3 en/zh tests check the glyphs, `8` and the accessible names. | TESTS/CODE |
| W4 | PASS | SessionBar W4 test. Real app agrees: a failed card showed "Venus could not seal this one" plus Retry. | TESTS + REAL APP |
| W5 | PASS | SessionsScreen W5 tests. Real app: `[data-slot=stage]` was absent on the Sessions screen and restored by "← The chart". | TESTS + REAL APP |
| W6 | PASS | SessionsScreen W6 test. Real app reader: both exchanges in order with moods and seals, 0 textareas, no Send. | TESTS + REAL APP |
| W7 | PASS | The i18n parity test plus the dw-6 six-tone zh test. The W7 relabel test passes. Real app: the zh chrome relabeled and the English card text stayed English. | TESTS + REAL APP |
| W8 | PASS | The `log.css (W8)` test reads the real stylesheet: the reduced-motion block sets `animation: none` on `.seal-card__seal--press` and `.seal-card--pending .seal-card__opening`. | TESTS/CODE |
| W9 | PASS (intent) | `architecture.test.ts` (G1–G9 and the barrel-consumer guard) and `color-guard.test.ts` pass (41/41). grep finds no `fetch`, `apiUrl`, hex or `rgb(` in non-test `log/` files. dw-6's own diff touches nothing under `web-divination/src/chat/`, `chart/`, `theme/` or `core/src/divination/types.ts`. The literal `2f45dfb` stat lists dw-4/dw-5 files only. | TESTS/CODE |
| A1 | PASS | After two exchanges End was enabled. Clicking it left the chat log as the greeting alone (1 article). The network log shows `POST /api/divination/summary` returning 202 then 200. Both bodies were identical, with keys `persona, lang, transcript`, 4 entries each of `role,text` only, no `birthData` and no id. The card was ready in 6.5 s with question "Should I let go of a man who never quite commits, and why does being chosen by him matter so much?", tone `torn`, and an English toneNote. | REAL APP |
| A2 | PASS | Chips under the replies were Venus, Venus–Pluto (opp), Venus–Saturn (trine), then Saturn–Ascendant (opp), Moon, Venus. The card's seal list `Read in the chart` was Venus, Venus opposition Pluto, Venus trine Saturn, Saturn opposition Ascendant, Moon, which is exactly that union. | REAL APP |
| A3 | PASS | After a reload the button read "Sessions · 1" and the list card showed the same question. The reader showed both exchanges verbatim. Back on the chart, the chat still held only the greeting. | REAL APP |
| A4 | **FAIL** | New one-exchange session, then End (first POST 202), then uvicorn SIGKILLed about 1 s later. The restart was healthy 12 s after End. Before any reload the record was already `{"status":"failed"}`: the 5 s poll hit a refused connection, and `fetchSummary` treats a rejected fetch as terminal. After a reload (waited 30 s) it stayed `failed` and no summary POST was sent, because `resumeSummaries()` only resumes `pending` records. The card needs a manual Retry. A4 can pass only if restart and reload both land inside `POLL_INTERVAL_MS` (5 s), which a real restart (about 12 s here) does not. | REAL APP |
| A5 | PASS | With 中 selected, a new session POSTed `lang:"zh"`. The card showed question "分手半年了还是忍不住看他的朋友圈，我该怎么放下？", tone 怅惘 (wistful) and a Chinese toneNote. The earlier English card still showed its English question and note under the zh chrome (基调: 两难). | REAL APP |
| A6 | PASS | `.schema divination_summary` shows exactly summary_key, summary, persona, lang, model, prompt_version, created_at, doctrine. `count(*)` = 2 = the sessions sealed (1 en + 1 zh; the A4 session was never sealed). | REAL APP |

Cleanup:
- Every planted edit was reverted; `git status --short` in the worktree is clean.
- Ports 8003, 5176 and 9333 are free. I stopped only the uvicorn, Vite and headless Chrome processes I started.
- The original `server/data/divination.db` (5 rows) is restored. This run's db is kept in the scratchpad.

ACCEPTANCE: FAIL (A4)
