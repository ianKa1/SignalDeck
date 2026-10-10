# Implementation Plan: dw-6-session-log

Spec: `pipeline/specs/dw-6-session-log.md` (WHAT + Architecture, PASS in
`logs/dw-6-session-log/02-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Parallel wave with dw-4 and dw-5; dw-6
lands LAST.

Worktree `/Users/kaimao/Projects/astrology-wt/dw-6-session-log`, branch
`feature/dw-6-session-log`, worker #3: backend :8003, Vite :5176. Every
command runs from the WORKTREE root; pipeline files are read and written by
absolute path under `/Users/kaimao/Projects/astrology/pipeline/`. Steps 0–7
are `implementing`, 8 is `validating`, 9 is `docs-sync`. Tick a box only
after its done-when passed and its `/git-commit` landed
(`(<type>): dw-6-session-log — <summary>`). Load `/frontend-design` before
step 6. Automated tests use fakes only: a monkeypatched
`llm.generate_sections` on the server (`JOBS_SYNC=1` from conftest; S3
removes it the way `tests/test_jobs.py` does), and an in-memory KV, stubbed
`fetch` and fake timers on the web (the setup `chat/core-divination.test.ts`
already uses). Server: `conda run -n astrology pytest -q` from `server/`
(one file: `… pytest tests/test_divination_summary.py -q`). Web:
`npx vitest run <file>` from `web-divination/`. Root: `npm test`,
`npm run typecheck`.

## Settled review notes

- **Rule 14 half-clause.** The sentence "may import interpretation AND
  cards" gains "and divination (the summary job)", in the same commit as
  generation.py's import (step 3).
- **`generatedAtUtc` round-trips via `created_at`.** `generate_summary`
  stamps `generatedAtUtc` (UTC ISO `…Z`) on the result; `store.put` writes
  it to `created_at`; `store.get` returns it as `generatedAtUtc`, exactly
  as `interpretation/store.py:78/91`. The store never reads a clock. That
  makes S2's second POST byte-equal.
- **>40-entry key collision accepted.** Two long sessions that differ only
  in dropped middle entries (D6) share one key and one summary. No test
  pins against it.
- **Failed-job cooldown.** `jobs/queue.py` holds a failed key for
  `FAILED_COOLDOWN_SECONDS` (30 s); a Retry inside that window gets 502 and
  the card goes `failed` again. This is expected, not a bug (W4 only checks
  the re-POST).

## Steps

- [x] **0. Verify worktree prep (the coordinator did it; this step only checks).**
  Branch is `feature/dw-6-session-log`; `node_modules/@astrace/core`
  resolves; `.env` and the three `server/data/*.se1` are symlinks into the
  primary checkout; no `server/data/*.db` is a symlink.
  Done when: `git branch --show-current`, `ls -l .env server/data/*.se1
  server/data/*.db` agree, and root `npm test`, `npm run typecheck` and the
  server pytest are green BEFORE any edit (the baseline).

- [x] **1. The store, its migration and the evolved state pins.**
  Files: `server/app/divination/store.py` (new),
  `server/app/db/migrations/011_divination_summary.sql` (new),
  `server/app/divination/__init__.py` (docstring),
  `server/tests/conftest.py` (redirect `divination.store.DB_PATH`),
  `server/tests/test_boundaries.py`, `server/tests/test_divination_summary.py`
  (new, store cases), `CLAUDE.md` (rule 9 sentence; rule 10 "stateless
  except `store.py`"; rule 11 importers + `divination/store`).
  Fence strip for `store.py`'s one db line with the `turn.py` self-check;
  `test_divination_keeps_no_state` split per the spec; column-list pins on
  store and migration; the new "turn/render never import summary or store"
  pin.
  Done when: S8 passes (SQLite columns, fake `db.connect` SQL, migration
  sorts last, real `server/data/divination.db` untouched) and
  `pytest tests/test_boundaries.py -q` passes with S9's store-side
  self-checks (db line in turn.py, INSERT in render.py, `from .store import
  get` in turn.py, planted `email` column).

- [x] **2. The summary topic and the request model.**
  Files: `server/app/divination/summary.py` (new),
  `server/app/divination/summary_role.txt` (new),
  `server/app/models.py` (`DivinationSummaryRequest` APPENDED at EOF),
  `server/tests/test_divination_summary.py`.
  Register the topic (role asset, `lang.en`, `lang.zh`) before
  `FINGERPRINT`; key, prompt, validation/truncation, `cached_summary`,
  `to_wire` per the contract. The role asks for a one-line central
  question, one of the six tones, one arc sentence, in the given language.
  Done when: S1 and S4 pass on pure calls; S5's validation and 200-char cut
  and S6's cases pass at model/function level; the full server suite stays
  green.

- [x] **3. The job and the route.**
  Files: `server/app/generation.py` (`DIVINATION_SUMMARY_PRIORITY`,
  `ensure_divination_summary`), `server/app/main.py`
  (`POST /api/divination/summary`), `server/tests/test_boundaries.py`
  (importers exactly `{main.py, generation.py}` + third-importer
  self-check; `GENERATE_ON_REQUEST_RE` gains `generate_summary` +
  self-check), `server/tests/test_divination_summary.py`, `CLAUDE.md`
  (rule 10 "generation.py may import divination for the summary job";
  rule 14 half-clause).
  Done when: S2, S3 (JOBS_SYNC removed, event-blocked fake, one job), S5
  and S6 through the route (502/422, no row, no fake call), S7 and all of
  S9 pass; `git diff 2f45dfb -- server/app/divination/turn.py
  server/app/divination/render.py server/app/llm.py` is empty (S10); the
  full server suite is green.

- [x] **4. Core summary client and `clearTranscript`.**
  Files: `packages/core/src/divination/summary.ts` (new),
  `packages/core/src/divination/transcript.ts` (`clearTranscript` APPENDED
  at EOF), `packages/core/src/divination/index.ts` (one APPENDED export
  block), `web-divination/src/log/core-session-log.test.ts` (new).
  `TONES`/`isTone`, the wire types, `summaryWire` (first 2 + last 38 via
  `toWire`) and `fetchSummary` on `postJson`/`pollDelay`/`MAX_POLLS`,
  shaped like `analysis/service.ts:93-120`; null on every failure.
  Done when: the test passes C3 and the `fetchSummary` halves of C4/C5
  (202→202→200 spacing, invalid tone, budget exhaustion); root
  `npm run typecheck` is green.

- [x] **5. Core session log.**
  Files: `packages/core/src/divination/session-log.ts` (new),
  `packages/core/src/divination/index.ts`,
  `web-divination/src/log/core-session-log.test.ts`.
  The KV log (key, cap 50, corrupt → `[]`, stable snapshot, listeners),
  `canEndSession`, `endSession`, `retrySummary`, `resumeSummaries` (one
  in-flight loop per id), `sessionFacts`, `SESSION_LIMITS`, the `s-<ms>` id.
  Parse keeps entries verbatim.
  Done when: C1–C8 pass; `grep -nE "fetch\(|window|localStorage|Math.random"
  packages/core/src/divination/{summary,session-log}.ts` prints nothing;
  root `npm test` and `npm run typecheck` are green (the app-native guards
  walk core).

- [x] **6. Card, i18n and styles (load `/frontend-design` first).**
  Files: `web-divination/src/i18n/{en,zh}.ts` (the `log` namespace
  INSERTED before `chat`, incl. six tone labels and the house template),
  `web-divination/src/log/SummaryCard.tsx` (new),
  `web-divination/src/log/log.css` (new),
  `web-divination/src/log/SummaryCard.test.tsx` (new).
  The sealed plate per D12: pending/failed/ready states, seal press, chart
  and dice seals via `chart-view` glyphs with screen-reader names, tone
  footer; colours only `var(--…)`; reduced-motion block.
  Done when: `npx vitest run src/log/SummaryCard.test.tsx` passes W3 (en
  and zh) and W8; `npx vitest run src/i18n.test.ts` passes W7's parity.

- [x] **7. Hook, bar, screen and the App swap.**
  Files: `web-divination/src/log/{useSessions.ts,SessionBar.tsx,
  SessionsScreen.tsx,SessionTranscript.tsx}` (new),
  `web-divination/src/app/App.tsx` (view state; SessionBar above
  ChatPanel; the swap), `web-divination/src/log/{SessionBar,SessionsScreen}.test.tsx`
  (new; App-level integration lives here, NOT in `app/App.test.tsx`).
  `useSessions` resumes pending summaries once on mount; End reads the
  transcript through `useSyncExternalStore`.
  Done when: `npx vitest run src/log` passes W1, W2, W4, W5, W6 and W7's
  relabel; root `npm test` (G1–G9, colour and barrel guards) and
  `npm run typecheck` are green; `grep -rnE "fetch\(|apiUrl|#[0-9a-fA-F]{3,8}\b|rgb\("
  web-divination/src/log` prints nothing; `git diff 2f45dfb --stat` shows
  nothing under `web-divination/src/{chat,chart,theme}/` nor
  `packages/core/src/divination/types.ts` (W9).

- [x] **8. Validating: the real app (A1–A6).**
  Leave :8000/:5173 (other checkouts) and dw-4/dw-5's 8001–8002/5174–5175
  alone. Backend from the worktree root:
  `ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5176 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8003`
  (no `DATABASE_URL` → SQLite in this worktree's `server/data`). Web:
  `cd web-divination && VITE_API_BASE=http://localhost:8003 npx vite --port 5176`
  (vite.config pins 5173 with `strictPort`; the flag overrides it; not
  `npm run web`). Enter the fixture birth (1990-06-15 08:30, Beijing).
  Drive with claude-in-chrome: `read_network_requests` for the summary
  body and statuses, screenshots for A1/A3/A5.
  Done when: A1–A6 are recorded with observed values in
  `logs/dw-6-session-log/`'s validating log (A2: each seal beside the chips
  it came from; A6: the `.schema` output and `select count(*)`), and both
  processes are stopped.

- [x] **9. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (via `/update-architecture-doc`: the
  summary topic, the store + migration 011, the job, the route, core
  `summary`/`session-log`, web `log/`),
  `docs/features/dw-6-session-log.md` (new, same shape as dw-3's),
  `/Users/kaimao/Projects/astrology/pipeline/epics/divination-web.md`
  ("Built so far"; `summary.py`, `store.py`, `generation.py`, `main.py`,
  core and `log/` targets marked ✔; the dependency-rules line "a persona
  edit changes the cache key" rewritten per D8: fingerprint is provenance
  in `doctrine`, a rewrite is a VERSION bump).
  Done when: the docs name `divination_summary`, `011_divination_summary.sql`,
  `ensure_divination_summary`, `astrology.divination.sessions.v1` and
  `SummaryCard`; `grep -n "changes the cache" pipeline/epics/divination-web.md`
  prints nothing; `git diff --stat feature/divination_web...HEAD -- docs`
  shows the edits.

## Acceptance map

| Criterion | Step |
|---|---|
| S1 key stability, no fingerprint/birth data | 2 |
| S2 200 hit/miss, one fake call | 3 |
| S3 202, one job, then 200 | 3 |
| S4 prompt and schema | 2 |
| S5 bad output → 502, no row; 200-char cut | 2 (pure), 3 (route) |
| S6 422s, no fake call | 2 (model), 3 (route) |
| S7 no provider → 503, stored hit served | 3 |
| S8 store columns, PG SQL, migration, redirect | 1 |
| S9 boundaries + self-checks | 1 (store/state pins), 3 (importers, generator regex) |
| S10 turn/render/llm untouched | 3 (re-checked at 8) |
| C1 canEndSession | 5 |
| C2 endSession record, clear, POST body | 5 |
| C3 45 → 40 entries | 4 |
| C4 202,202,200 → ready | 4 (loop), 5 (record) |
| C5 failures → failed; Retry | 4 (loop), 5 (record) |
| C6 resume once | 5 |
| C7 sessionFacts, dice survive reload | 5 |
| C8 cap 50, corrupt → [] | 5 |
| W1 End enabled/disabled | 7 |
| W2 End → greeting, pending, ready card | 7 |
| W3 dice row glyphs + names (en/zh) | 6 |
| W4 failed card, Retry | 7 |
| W5 Sessions screen, empty text, back | 7 |
| W6 reader, read-only, narrow back | 7 |
| W7 parity, zh tones, relabel | 6 (parity), 7 (relabel) |
| W8 reduced motion | 6 |
| W9 guards, no network/colour, footprint | 7 |
| A1–A6 real app | 8 |

## Deviations (for journaling)

- **Diff baselines after the landing merge.** S10 and W9 diff against
  `2f45dfb`, but dw-5 edits `turn.py`, `render.py` and `chat/` and lands
  first. Before the landing merge the checks run as written; after merging
  `feature/divination_web` in, they run as
  `git diff feature/divination_web...HEAD` (dw-6's own delta) over the
  same paths.

## Risks for the implementer

- **Wave landing conflicts.** dw-4 and dw-5 land first. Expect textual
  conflicts in `models.py` (both append; keep dw-5's `DivinationDice` and
  entry `dice` ABOVE `DivinationSummaryRequest`), `divination/__init__.py`
  bullets, core `divination/index.ts` (keep both appended blocks),
  `i18n/{en,zh}.ts` (dw-5 appends inside `chat`, dw-6 inserts `log` before
  it) and CLAUDE.md rule 10 (keep dw-5's dice sentence and dw-6's two
  halves). The coordinator merges `feature/divination_web` INTO this
  worktree; re-run steps 3, 5 and 7's done-when there, and confirm S1's
  "exactly role and text" still holds (dw-5's `cast` never reaches
  `toWire`). No hash is pinned, so the fingerprint move is text-only.
- **The fence forbids `db`.** `store.py`'s `from .. import db` is legal
  only because the stripper removes exactly that line in `store.py`; any
  other spelling (`from app import db`, `import app.db`) fails the fence.
  The state pin's regex also bites on docstrings in files other than
  `store.py` only after its comment/docstring strip; keep `CREATE TABLE`
  prose out of `summary.py`.
- **Registry freeze.** `prompts` freezes a topic once `FINGERPRINT` is
  computed; register all three fragments above it in `summary.py`.
- **Truncation vs the schema.** Cut `question`/`toneNote` AFTER stripping
  and BEFORE the emptiness check, and store the cut value (S5 reads the
  served 200 chars).
- **S3 needs a clean scheduler.** The scheduler is a process singleton;
  follow `test_jobs.py` for removing `JOBS_SYNC`, resetting the scheduler
  and releasing the event in a `finally`, or a hung worker thread wedges
  later tests.
- **Resume vs End race.** `endSession` starts its own loop; `useSessions`'
  mount-time `resumeSummaries` must see that id as in flight (register the
  loop before the first `await`), or C6/A4 double-POST.
- **Snapshot stability.** `useSyncExternalStore` loops forever if
  `listSessions()` returns a new array per call; cache the parsed snapshot
  and replace it only on write.
- **Wide/narrow without `matchMedia`.** jsdom has none. Drive the reader
  layout from state (`selectedId`) plus a CSS media query at 900 px, and
  always render "← All sessions" (CSS hides it on wide), so W6 needs no
  media stub.
- **Session language.** `endSession` takes the UI language at End from the
  i18n store; the card's chrome relabels on switch but `question`/`toneNote`
  are stored text (W7, A5).
- **claude-cli latency and cooldown in A1/A4.** A summary can take tens of
  seconds; `MAX_POLLS` × 5 s is ample. If one fails, wait out the 30 s
  cooldown before Retry. Do not edit `.env` (a symlink shared with the
  primary checkout). For A4, stop uvicorn within a second of End so the
  in-memory job dies with it.
- **A6 row count.** A Retry that later succeeds, or two identical
  sessions, add no row; count distinct sealed sessions accordingly.
