# Implementation Plan: dw-7-persona-mirror

Spec: `pipeline/specs/dw-7-persona-mirror.md` (WHAT + Architecture; PASS in
`logs/dw-7-persona-mirror/02-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Parallel wave with dw-9 (oral delivery)
and dw-12 (Google sign-in); dw-7 lands FIRST.

Worktree `/Users/kaimao/Projects/astrology-wt/dw-7-persona-mirror`, branch
`feature/dw-7-persona-mirror`, worker #1: backend :8001, Vite :5174. Every
command runs from the WORKTREE root; pipeline files by absolute path under
`/Users/kaimao/Projects/astrology/pipeline/`. Steps 0–7 are `implementing`,
8 is `validating`, 9 is `docs-sync`. Tick a box only after its done-when
passed and its `/git-commit` landed (`(<type>): dw-7-persona-mirror —
<summary>`). Load `/frontend-design` before step 7. Automated tests use
fakes only: monkeypatched `llm.generate_sections` / `llm.stream_turn`
(`JOBS_SYNC=1` from conftest; P6 removes it as `tests/test_jobs.py` does);
stubbed `fetch` and fake timers on the web. Server: `conda run -n astrology
pytest -q` from `server/` (one file: `… pytest
tests/test_divination_persona.py -q`). Web: `npx vitest run <file>` from
`web-divination/`. Root: `npm test`, `npm run typecheck`.

## Settled review notes

- **N1 — accept the second `natal_report`, knowingly.** The turn route calls
  `voice.cached_for` (sheet → store read) and `turn_events` then builds
  `natal_context` again. Passing facts in would change `turn_events`'
  contract and move chart work before the stream opens. One extra chart
  compute is tens of ms against a multi-second streamed reply, and a Tier A
  memo is out of scope. `cached_for` returns None on ANY exception (logged),
  so a bad chart still fails as today's SSE `error`, not a pre-stream 500.
- **N2.** `_create_table_columns(sql, table)` in `test_boundaries.py` finds
  the CREATE TABLE by NAME (the store source now holds two); every existing
  call passes `"divination_summary"`.
- **N3.** dw-3/dw-5 tests that pin the WITH-chart prompt (fragment set at
  `test_divination_render.py:33`, order lists, `_chart_json` splitting) may
  gain the `self.*` fragments and the sheet's position; that is allowed.
  The CHART-LESS golden stays strict (P10).
- **N4.** "Never claim another's feelings" rides with the sheet only; the
  coordinator journals it (dw-8 generalises).
- **N5 — zh strings.** `persona.title` 你的金星; `persona.finding`
  她正在寻找自己的声音…; dignity words 入庙/入旺/落陷/入弱; retrograde
  `℞ 逆行`. en placement template `in {sign}`, zh `{sign}` (A5 reads
  金牛座 · 第十宫 · 入庙). Houses reuse `chat.houses`.
- **N6.** A3's log quotes both first answers side by side, verbatim, under
  a heading per chart, before judging (c).

## Steps

- [x] **0. Verify worktree prep (coordinator did it; this only checks).**
  Branch `feature/dw-7-persona-mirror`; `node_modules/@astrace/core`
  resolves; `.env` and the three `server/data/*.se1` are symlinks into the
  primary checkout; no `server/data/*.db` is a symlink.
  Done when: `git branch --show-current` and `ls -l .env server/data/`
  agree, and root `npm test`, `npm run typecheck` and the server pytest are
  green BEFORE any edit (baseline).

- [x] **1. The pure sheet.**
  Files: `server/app/divination/persona.py` (new),
  `server/app/divination/render.py` (`_REF_POINTS` becomes an alias of
  `persona.SHEET_POINTS`, nothing else), `server/app/divination/__init__.py`
  (docstring bullet), `server/tests/test_divination_persona.py` (new, sheet
  cases), `server/tests/test_boundaries.py` (`test_persona_sheet_is_pure` +
  planted `from app.llm import generate_sections` self-check), `CLAUDE.md`
  (rule 10: `persona.py` is the pure sheet).
  Done when: P1, P2, P3 pass (each first asserts the fixture's Venus sign,
  house, motion); the purity pin and its self-check pass; full suite green.

- [x] **2. The voice table and migration 012.**
  Files: `server/app/divination/store.py` (`divination_voice` CREATE
  TABLE, `VOICE_COLUMNS`, `put_voice`, `get_voice`, both backends),
  `server/app/db/migrations/012_divination_voice.sql` (new, header comment
  shaped like 011's), `server/tests/test_boundaries.py` (N2 helper;
  two-table pin with per-table columns vs store + migration 011/012;
  planted `email` into the voice list), `test_divination_persona.py` (store
  cases), `CLAUDE.md` (rule 9 voice-cache sentence; rule 10 stateful
  exception covers both tables; rule 11 `divination/store` migrations 011,
  012).
  Done when: P11 passes (SQLite columns, fake `db.connect` INSERT … ON
  CONFLICT (voice_key), 012 sorts last, real `server/data/divination.db`
  untouched) and `pytest tests/test_boundaries.py -q` passes.

- [x] **3. The voice topic and the request model.**
  Files: `server/app/divination/voice.py` (new),
  `server/app/divination/voice_role.txt` (new), `server/app/models.py`
  (`DivinationPersonaRequest` APPENDED at EOF; persona literal `venus`,
  lang `en|zh`, `birthData` required), `test_divination_persona.py`.
  Register the topic (role asset + lang lines) before `FINGERPRINT`; key over
  `sheet_facts` only; validation, trims, `cached_voice`, `cached_for` (N1),
  `to_wire` per the contract. The role asks for first-person intro/bias in
  the request language and English `style` naming the sign.
  Done when: P4 and P9 pass; P7's blank-intro, missing-sign and 200-char cut
  pass at function level; full suite green.

- [x] **4. The job and the persona route.**
  Files: `server/app/generation.py` (`DIVINATION_VOICE_PRIORITY = 1`,
  `ensure_divination_voice`), `server/app/main.py` (`POST
  /api/divination/persona` placed right after the summary route),
  `server/tests/test_boundaries.py` (`GENERATE_ON_REQUEST_RE` gains
  `generate_voice` + planted `voice.generate_voice(` self-check),
  `test_divination_persona.py`.
  Done when: P5, P6 (JOBS_SYNC removed, event-blocked fake, one job, then
  200), P7 and P8 through the route pass;
  `test_main_names_the_synchronous_exceptions` passes unchanged; full suite
  green.

- [x] **5. The turn reads the sheet and the voice.**
  FIRST, before touching `render.py`, record the chart-less golden: the
  output of `render.system_prompt("venus", lang)` for en and zh from the
  unedited code, as `server/tests/fixtures/divination_chartless_{en,zh}.txt`.
  Files: `server/app/divination/render.py` (`self.read`, `self.marker`,
  `self.voice` fragments after `dice.recall`; `NatalContext.sheet`;
  `natal_context(person, persona="venus")`; `system_prompt(..., voice=None)`;
  `turn_messages` pass-through), `server/app/divination/turn.py` (`voice`
  param forwarded), `server/app/main.py` (turn route's one `cached_for`
  line), `server/tests/test_boundaries.py` (turn-state regex gains `voice`;
  planted `from .voice import cached_voice` in turn.py self-check; turn
  route names no `ensure_`), `test_divination_render.py` /
  `test_divination_turn.py` / `test_divination_dice.py` (N3 updates only),
  `test_divination_persona.py` (P10), `CLAUDE.md` (rule 10: turn/render
  never import `summary`, `store` or `voice`).
  Done when: P10 passes (order, no enqueue by the turn, voice style on the
  next turn, chart-less output equals both fixture files byte for byte, key
  phrases in `self.read`); P12 in full; full suite green.

- [x] **6. Core persona client.**
  Files: `packages/core/src/divination/persona.ts` (new),
  `packages/core/src/divination/index.ts` (one APPENDED export block),
  `web-divination/src/chat/core-persona.test.ts` (new).
  Types, `isPersonaSheet`/`isPersonaWire` over closed sets, `fetchPersona`
  on `postJson`/`pollDelay`/`isGenerating`/`MAX_POLLS`, shaped like
  `summary.ts`; `onSheet` on each 202; null on every failure; abortable.
  Done when: C1 passes; `grep -nE "fetch\(|window|localStorage"
  packages/core/src/divination/persona.ts` prints nothing; root `npm test`
  and `npm run typecheck` green.

- [x] **7. Header, voice letter, i18n, styles (load `/frontend-design`).**
  Files: `web-divination/src/i18n/{en,zh}.ts` (`persona` namespace
  APPENDED; N5 strings), `web-divination/src/chat/usePersona.ts`,
  `PersonaHeader.tsx`, `persona.css` (new), `ChatPanel.tsx` (header block
  → `<PersonaHeader>`; greeting letter → intro prose + bias aside on a
  `--venus` hairline when ready; nothing else),
  `web-divination/src/chat/PersonaHeader.test.tsx` (new; ChatPanel-level
  W cases live here). Colours only `var(--…)`; shimmer off under reduced
  motion.
  Done when: `npx vitest run src/chat` passes W1–W5 and
  `npx vitest run src/i18n.test.ts` passes W6 parity; root `npm test` and
  `npm run typecheck` green; `git diff feature/divination_web...HEAD --stat
  -- web-divination/src/chat/chat.css web-divination/src/chat/useChat.ts
  web-divination/src/theme server/app/divination/personas` is empty (W6).

- [x] **8. Validating: the real app (A1–A5).**
  :8000/:5173 belong to another checkout; leave 8002+/5175+ to dw-9/dw-12.
  The repo `.env` sets `DATABASE_URL` to a SHARED REMOTE Postgres: copy it
  to a scratch file OUTSIDE the repo with that line removed (never edit the
  symlinked `.env`). Backend from the worktree root:
  `DATABASE_URL= ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5174 conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file <scratch> --port 8001`;
  confirm `curl localhost:8001/api/health` reports db unconfigured BEFORE
  any POST. Web: `cd web-divination && VITE_API_BASE=http://localhost:8001 npx vite --port 5174`.
  Drive with claude-in-chrome (`read_network_requests` for 202→200,
  screenshots for A1/A5). Chart A then chart B (End, change birth data).
  Done when: `logs/dw-7-persona-mirror/`'s validating log records A1–A5
  with observed values: A2/A3 transcripts verbatim, A3(c) side-by-side
  quotes (N6), A4's `.schema divination_voice` and row count; both
  processes stopped.

- [x] **9. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (via `/update-architecture-doc`: persona
  sheet, voice topic, table + migration 012, job, route, turn read, core
  `persona`, web header), `docs/features/dw-7-persona-mirror.md` (new,
  dw-6's shape). Do NOT edit the epic: report its changes to the
  coordinator ("Built so far" dw-7; `persona.py`, `voice.py`, route, core
  and header targets marked built; the second store table).
  Done when: the docs name `persona_sheet`, `divination_voice`,
  `012_divination_voice.sql`, `ensure_divination_voice`, `fetchPersona` and
  `PersonaHeader`; the epic delta is in the handback report.

## Acceptance map

| Criterion | Step |
|---|---|
| P1 sheet A | 1 |
| P2 sheet B | 1 |
| P3 pure, generic, time-unknown, no meanings | 1 |
| P4 key (facts only, VERSION not FINGERPRINT) | 3 |
| P5 route 200 hit/miss, one fake call | 4 |
| P6 202, one job, then 200 | 4 |
| P7 bad output → 502, no row; 200-char cut | 3 (pure), 4 (route) |
| P8 422s; 503 keyless, hit still served | 3 (model), 4 (route) |
| P9 voice prompt and schema | 3 |
| P10 turn: sheet now, voice later, chart-less golden | 5 |
| P11 store columns, PG SQL, migration, redirect | 2 |
| P12 boundaries + self-checks; old suites pass | 1 (purity), 2 (columns), 4 (generator regex), 5 (turn-state regex; full) |
| C1 fetchPersona | 6 |
| W1 no birth data | 7 |
| W2 header, finding note, intro + bias | 7 |
| W3 retrograde Scorpio; house null | 7 |
| W4 zh re-POST; abort on birth-data change | 7 |
| W5 intro never in the turn wire or transcript | 7 |
| W6 parity, reduced motion, guards, untouched files | 7 |
| A1–A5 real app | 8 |

## Deviations (for journaling)

- None structural. Recorded for the journal: N1 accepted (double chart
  compute per turn; `cached_for` never raises), N4 (feelings rule only with
  a sheet), N5 zh strings, and the chart-less golden stored as fixture files
  recorded from the unedited `render.py` rather than inline strings.

## Risks for the implementer

- **dw-9 overlap.** dw-9 edits `render.py`, `turn.py`, `ChatPanel.tsx`,
  i18n, and likely `personas/venus.txt` / `lang.*`. dw-7 lands first, so
  dw-9 resolves; but keep dw-7's hunks small: fragments appended after
  `dice.recall`, keyword params defaulting to None, ChatPanel touched only
  in the header block and greeting letter, `persona` namespace appended at
  the END of each dictionary. Tell the coordinator: when dw-9 changes the
  persona or lang text, the chart-less golden fixtures must be RE-RECORDED
  in dw-9 (they pin "no `self.` fragment without a chart", not dw-6 prose).
- **dw-12 overlap.** `main.py` (route after the summary route; the turn
  route's one line) and `models.py` (EOF append). If dw-12 also adds a
  migration, whoever lands second renumbers; dw-7 keeps 012 as first lander,
  and the boundary pin names the file, so a renumber edits the pin too.
- **Registry freeze.** Both `divination_voice` and the new `self.*`
  fragments on `divination` must be declared before the module computes
  `FINGERPRINT`. `render.FINGERPRINT` moves; the summary topic's does not.
- **Import cycle.** `render.py` imports `persona`; `persona.py` must not
  import `render` (the `SHEET_POINTS` definition lives in persona).
- **Chart B fixture.** Its Midheaven trine is in the chart aspects; the
  filter is `SHEET_POINTS`, not the chart's aspect list. Chiron in A too.
- **Trim before validate.** Strip, cut to 200/900, THEN check blanks and the
  sign name; store the cut value (P7 reads the served 200 chars).
- **P6 scheduler.** Follow `test_jobs.py` for resetting the singleton and
  releasing the event in a `finally`, or a hung worker wedges later tests.
- **Failed-job cooldown.** A 502 key is held ~30 s; in A1–A5 a retry inside
  it answers 502 again. claude-cli voices can take tens of seconds;
  `MAX_POLLS` × interval is the budget.
- **Abort vs language switch.** `usePersona` must abort the prior poll on
  every birth-data OR lang change and ignore late `onSheet` calls from an
  aborted run, or W4 sees the old sheet flash back.
- **Empty `DATABASE_URL`.** If `/api/health` still reports a db, stop: the
  scratch env is wrong, and a boot would migrate the shared Postgres.
