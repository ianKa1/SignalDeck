# Implementation Plan: dw-8-planet-cast

Spec: `pipeline/specs/dw-8-planet-cast.md` (WHAT + Architecture; PASS in
`logs/dw-8-planet-cast/04-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Precedent: `plans/dw-7-persona-mirror.md`.

Worktree `/Users/kaimao/Projects/astrology-wt/dw-8-planet-cast`, branch
`feature/dw-8-planet-cast`, worker #1: backend :8001, Vite :5174. Commands
run from the WORKTREE root; pipeline files by absolute path under
`/Users/kaimao/Projects/astrology/pipeline/`. Steps 0–9 are `implementing`,
10 is `validating`, 11 is `docs-sync`. Tick a box only after its done-when
passed and its `/git-commit` landed (`(<type>): dw-8-planet-cast —
<summary>`). Load `/frontend-design` before step 7. Automated tests use
fakes only (monkeypatched `llm.generate_sections` / `llm.stream_turn`,
real charts; stubbed `fetch` on the web). Server: `conda run -n astrology
pytest -q` from `server/`. Web: `npx vitest run <path>` from
`web-divination/`. Root: `npm test`, `npm run typecheck`.

## Settled review notes

- **N1 — every ♀ follows the persona.** The reply eyebrow and streaming
  caret in `ChatPanel.tsx` and the eyebrow in `log/SessionTranscript.tsx`
  take the glyph from the persona. SessionTranscript joins the scope
  (step 9). W5 gains: a Moon reply's eyebrow and caret, and a reopened Moon
  transcript, show ☽.
- **N2 — pronoun-free persona strings.** `persona.finding` becomes en
  "{name} is finding a voice…", zh "{name}正在寻找自己的声音…";
  `persona.biasLabel` becomes en "{name}'s bias", zh "{name}的偏见". No
  she/her/他/她 remains in `chat`, `log`, `persona` or `roster`.
- **N3 — neutral `side.role`.** It names "{name}, one of six planet
  characters" and describes no temperament; "Venus's reply" becomes
  "the reply".
- **N4 — `roster.list` governs; `venus.txt` is untouched.** Editing
  `venus.txt` would break S5's "fixtures differ only by the roster block".
  `roster.list` says explicitly that even a character who meets every
  question from its own domain gives its own angle briefly and names who
  reads it better. The five new texts do not carry the "even when it
  arrives dressed as something else" clause.
- **N5 — Esc/Back on first use does nothing.** With no active persona the
  picker has no close control, and Esc/Back is a no-op there.
- `chart.read` keeps its Venus examples for every persona (harmless; they
  are ref-format examples, not a domain claim).

## Steps

- [x] **0. Verify worktree prep; note the base.**
  Branch `feature/dw-8-planet-cast`; `node_modules/@astrace/core`
  resolves; `.env` and the three `server/data/*.se1` are symlinks into the
  primary checkout; no `server/data/*.db` is a symlink. Record in the
  implementing log whether dw-9 (`git log --oneline | grep dw-9`) and dw-12
  are in the base. If dw-9 is NOT, merge the working branch in once it
  lands, before step 2 when possible.
  Done when: `git branch --show-current`, `ls -l .env server/data/` agree;
  root `npm test`, `npm run typecheck` and server pytest green before any
  edit.

- [x] **1. One persona list, three mirrors on the server.**
  Files: `server/app/divination/persona.py` (six entries, fixed order),
  `server/app/models.py` (`DivinationPersona` alias replaces the three
  `Literal["venus"]`), `server/tests/test_boundaries.py`
  (`test_persona_lists_agree` + planted seventh literal self-check),
  existing divination tests (`"mars"` 422 cases → `"pluto"`), `CLAUDE.md`
  rule 10 (clause: `PERSONA_PLANETS` is the one list; models/core mirror it
  under pins).
  Done when: S1 passes, S2's model-level 422s pass; full suite green.

- [x] **2. Record the pre-dw-8 references, then compose per character.**
  FIRST, from the unedited base (with dw-9 in it), save under
  `server/tests/fixtures/divination_pre_dw8/`: chart-less en/zh, Venus
  with-chart-A chart section (en), Venus cast dice section (en).
  Files: `personas/{moon,mars,jupiter,saturn,mercury}.txt` (new, built like
  post-dw-9 `venus.txt`, no length lines; Jupiter's "risk", Mercury's
  "paste"), `git mv personas/venus-dice.txt personas/dice.txt`,
  `render.py` (`PERSONAS = tuple(PERSONA_PLANETS)`, `persona.<id>`,
  `dice.brief`, `focus.<id>`, `roster.rules/list/timing` after dw-9's
  `depth.*`, `chart.read` `{focus}`, `self.read` `{planet}` with the D
  bullet moved to `roster.rules`), re-recorded
  `fixtures/divination_chartless_{en,zh}.txt`, new
  `tests/test_divination_roster.py`.
  Done when: S4, S5 (fixtures minus the roster block equal the pre-dw-8
  copies; chart section and dice section byte-equal), S6 pass; full suite
  green.

- [x] **3. The pure sheets route.**
  Files: `server/app/models.py` (`DivinationSheetsRequest` appended at
  EOF), `server/app/main.py` (`POST /api/divination/sheets` right after the
  persona route, `_person` validation, one `natal_report`),
  `test_boundaries.py` (`test_sheets_route_is_pure` + planted
  `generation.ensure_divination_voice(` bite), `test_divination_roster.py`,
  `CLAUDE.md` rule 10 (clause: the sheets route is a pure facts read).
  Done when: S3 passes (no provider env, no LLM fake call, no job, no store
  row); `test_main_names_the_synchronous_exceptions` passes unchanged.

- [x] **4. Summary and voice for any character.**
  Files: `server/app/divination/summary_role.txt`, `voice_role.txt`
  (planet-neutral, `<planet>`; VERSIONs unchanged),
  `test_divination_summary.py`, `test_divination_persona.py`,
  `test_divination_roster.py` (route-level S2 across `/turn`, `/summary`,
  `/persona`).
  Done when: S2, S8, S9 pass; full suite green.

- [x] **5. The handoff side field.**
  Files: `render.py` (`side.role` neutral per N3 and `{name}`-formatted,
  `side.handoff`, `side_schema(catalogue, handoff_ids)` on both branches,
  `to_wire_handoff`), `turn.py` (`_side_read` triple, only on
  `action == "chat"`; `done` gains `handoff`), `test_divination_turn.py`
  (mechanical `done`-shape updates), `test_divination_roster.py`,
  `test_boundaries.py` (no regex over the reply in `turn.py`/`render.py`),
  `CLAUDE.md` rule 10 (clause: the handoff is a validated side-read field,
  never parsed from prose).
  Done when: S7 and S10 pass; full suite green.

- [x] **6. Core roster.**
  Files: `packages/core/src/divination/roster.ts` (new), `types.ts`,
  `turn.ts`, `transcript.ts`, `session-log.ts`, `index.ts` (one appended
  block), `web-divination/src/roster/core-roster.test.ts` (new; the
  golden id string with a comment naming `persona.py`).
  Done when: C1–C3 pass; `grep -nE "fetch\(|window|localStorage"
  packages/core/src/divination/roster.ts` prints nothing; root `npm test`,
  `npm run typecheck` green.

- [x] **7. Tokens, `--char`, strings (load `/frontend-design`).**
  Files: `web-divination/src/theme/tokens.ts` (`persona`/`personaGhost`
  records; `venus`/`venusGhost` removed), `roster/roster.css` (new:
  `[data-persona]` → `--char`/`--char-ghost`, reduced-motion block),
  `chat/*.css`, `log/log.css`, `chart/wheel.css` (`var(--venus…)` →
  `var(--char…)`), `i18n/{en,zh}.ts` (`roster` namespace before dw-12's
  `auth`; `{name}` templates; N2), their call sites, `i18n.test.ts`
  (Venus/金星 leaf walk).
  Done when: `grep -rn -- "--venus" web-divination/src` prints nothing;
  W6 and the token half of W5 pass; root suites green.

- [x] **8. Picker, active persona, ChatPanel per character.**
  Files: `roster/useRoster.ts`, `roster/RosterPicker.tsx` (new),
  `app/App.tsx` (active persona, overlay picker, shell `data-persona`,
  `seed {text, nonce}`), `chat/ChatPanel.tsx` (props `persona`, `seed`,
  `onHandoff`, `onOpenRoster`; keyed by persona; eyebrow and caret glyph
  per N1), `chat/PersonaHeader.tsx` (glyph, name, domain, "The six"),
  `chat/useChat.ts`, `roster/RosterPicker.test.tsx` (new).
  Done when: W1, W2, W3 and N5 (Esc no-op on first use) pass; root suites
  green.

- [x] **9. Handoff slip and per-character log.**
  Files: `chat/ChatPanel.tsx` (`HandoffSlip` after dw-9's slips, stored
  entries only), `chat/useChat.ts` (store `done.handoff`),
  `log/SessionBar.tsx`, `SummaryCard.tsx`, `SessionsScreen.tsx`,
  `SessionTranscript.tsx` (persona from props/record, card
  `data-persona`), their tests.
  Done when: W4 and W5 (incl. N1's ☽ eyebrow, caret, reopened transcript;
  End with Mars archives `mars`) pass; root `npm test`, `npm run
  typecheck`, server pytest all green.

- [x] **10. Validating: the real app (A1–A5).**
  Never use the repo `.env`'s `DATABASE_URL` (shared remote Postgres);
  never `--env-file .env`. :8000/:5173 belong to another checkout. Scratch
  files only under `<session scratchpad>/dw8/` (shared with other workers:
  touch nothing else there).
  - **dw-12 gate in the base:** `initdb -U astrace --auth=trust` into
    `scratchpad/dw8/pg`, `pg_ctl` on a free port (check `lsof`) with
    `listen_addresses=127.0.0.1`, `createdb astrace_dw8`. Backend with
    explicit env only: `DATABASE_URL=postgresql://astrace@127.0.0.1:<port>/astrace_dw8
    ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5174
    GOOGLE_CLIENT_ID=dw8-placeholder.apps.googleusercontent.com conda run
    --no-capture-output -n astrology uvicorn app.main:app --app-dir server
    --port 8001`. Mint a pair with dw-12's `mint.py` recipe (assert the
    throwaway URL) and write `astrace.auth.access/refresh/expiresAt`.
  - **Gate absent:** scratch copy of `.env` minus `DATABASE_URL`, backend
    with `DATABASE_URL= --env-file <scratch>`.
  - Confirm `curl localhost:8001/api/health` shows the local db (or
    `unconfigured`) BEFORE any POST. Web: `cd web-divination &&
    VITE_API_BASE=http://localhost:8001 npx vite --port 5174`. Drive with
    claude-in-chrome; chart A.
  Done when: `logs/dw-8-planet-cast/07-validating.md` (06 is implementing) records A1–A5 with
  verbatim quotes, `done.handoff` values from the network panel, and
  screenshots; processes stopped, cluster deleted, `lsof` on each port
  empty.

- [x] **11. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (via `/update-architecture-doc`: six
  personas, roster fragments, handoff field, sheets route, core `roster`,
  picker, `--char`), `docs/features/dw-8-planet-cast.md` (new, dw-7's
  shape). Do NOT edit the epic: report its delta to the coordinator
  ("Built so far" dw-8; roster/picker/sheets targets built; the
  `roster.timing` hand-off to dw-11).
  Done when: the docs name `PERSONA_PLANETS`, `roster.timing`,
  `to_wire_handoff`, `/api/divination/sheets`, `fetchSheets` and
  `RosterPicker`; the epic delta is in the handback report.

## Acceptance map

| Criterion | Step |
|---|---|
| S1 list + pin | 1 |
| S2 422s / saturn accepted | 1 (model), 4 (routes) |
| S3 sheets | 3 |
| S4 prompts per character | 2 |
| S5 Venus stability | 2 |
| S6 dice for all | 2 |
| S7 handoff | 5 |
| S8 summary per character | 4 |
| S9 voice per character | 4 |
| S10 boundaries | 1, 3, 5 (full by 5) |
| C1 ids, done.handoff parse | 6 |
| C2 active persona, per-id transcripts | 6 |
| C3 sanitize, parseRecord, fetchSheets | 6 |
| W1 picker | 8 |
| W2 pick and prefill | 8 |
| W3 own transcripts, switch/stop, overlay | 8 |
| W4 handoff slip | 9 |
| W5 chrome (+N1 ☽) | 7 (tokens, css), 8 (shell, glyphs), 9 (cards, End) |
| W6 strings and guards | 7 |
| A1–A5 real app | 10 |

## Deviations (for journaling)

- S5's references are stored as fixture files recorded from the unedited
  base (`fixtures/divination_pre_dw8/`) rather than read from git at test
  time; dw-11 may delete them when it re-records.
- N1–N5 settled as above (SessionTranscript added to scope; N4 keeps
  `venus.txt` byte-identical and lets `roster.list` govern).

## Risks for the implementer

- **dw-9 first.** Record the pre-dw-8 references and re-record goldens
  only on a base that contains dw-9; recorded pre-dw-9, they will
  conflict and lie. `roster.*` sit after `depth.*`; `deeper` turns ask no
  handoff. dw-9 edited `venus-dice.txt` line 11 — do the rename with `git
  mv` after merging so the edit rides along.
- **dw-12.** i18n: `roster` goes BEFORE `auth`. The gate wraps `<App/>`;
  keep `useRoster`'s KV read and sheets fetch inside App so nothing runs
  before sign-in. Both branches append to `test_boundaries.py`: resolve by
  keeping both.
- **dw-11 hand-off contract.** dw-8 lands first. Keep `roster.timing` its
  own named fragment and the `system_prompt` return expression one ordered
  list, so dw-11 can suppress the fragment and slot sky after chart. Say so
  in the docs-sync report.
- **Registry freeze.** Every new fragment and asset is declared before
  `FINGERPRINT` is computed; the summary topic's fingerprint must not move.
- **`side_schema` with an empty catalogue** returns `{mood, handoff}`,
  both required, only when handoff ids are given; a cast keeps
  `MOOD_SCHEMA`.
- **Unmount-abort ordering.** Switching character remounts ChatPanel; the
  stopped partial must be written to the OLD persona's key (capture the id
  in the hook's closure, not from props at cleanup). The picker is an
  overlay, so opening it must not unmount.
- **Seed nonce.** Same-character prefill reapplies on nonce change only;
  never key ChatPanel on the seed.
- **Colour guard.** `roster.css` maps variables only; the planet colours
  live in `tokens.ts`, flattened by `tokenVars` to `--persona-<id>` and
  `--persona-ghost-<id>`.
- **Scratchpad is shared.** dw-12's validator deleted another worker's
  Chrome profile; use only `scratchpad/dw8/`.
- **A3 depends on the LLM.** One rephrase/retry is allowed; log both
  attempts and their `done.handoff`.
