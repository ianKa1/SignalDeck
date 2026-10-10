# 04 — implementing (worker #1, parallel wave; worktree astrology-wt/dw-7-persona-mirror)

Stage: implementing. Branch `feature/dw-7-persona-mirror` from
`feature/divination_web` @ b308a92.

## Step 0 — worktree prep (verify only)

- `git branch --show-current` → `feature/dw-7-persona-mirror`
- `.env` → symlink to `/Users/kaimao/Projects/astrology/.env`;
  `server/data/` holds exactly three symlinks (`seas_18.se1`, `semo_18.se1`,
  `sepl_18.se1`); no `*.db` (none, symlinked or not).
- `node_modules/@astrace/core -> ../../packages/core`.
- Baseline BEFORE any edit:
  - root `npm test`: app-native `Test Suites: 90 passed, 90 total` /
    `Tests: 1069 passed, 1069 total`; web-divination `Test Files 19 passed
    (19)` / `Tests 163 passed (163)`.
  - root `npm run typecheck`: clean (both workspaces).
  - server `conda run -n astrology pytest -q`: `1129 passed, 50 skipped,
    1 warning in 174.94s`.

## Step 1 — the pure sheet

- New `server/app/divination/persona.py` (`PERSONA_PLANETS`, `SHEET_POINTS`,
  `persona_sheet`, `sheet_for`, `sheet_facts`); `render._REF_POINTS` is now
  `_persona.SHEET_POINTS` (one definition); package docstring bullet;
  CLAUDE.md rule 10 sentence; `test_boundaries.py::test_persona_sheet_is_pure`
  (allow-list: `app.chart*`, `app.dictionary`, a few stdlib; self-checks
  planted `from app.llm import generate_sections`, `from . import store`,
  `from app.prompts import x`, `import sqlite3`).
- Real-chart facts confirmed by a probe before writing the tests:
  A Venus Taurus h10 direct, aspects by orb Chiron 2.16 (filtered), Jupiter
  2.39, Pluto 2.75, Neptune 4.44, Saturn 5.90, Moon 9.72; B Venus Scorpio
  h2 retrograde (speed -0.19), Mercury conj 1.04, Midheaven trine 3.05
  (filtered), Jupiter trine 6.37, Moon opp 6.53.
- `pytest tests/test_divination_persona.py tests/test_boundaries.py -q` →
  `29 passed in 0.67s` (P1, P2, P3 + purity pin).
- Full server suite: `1135 passed, 50 skipped, 1 warning in 121.38s`. Steps 0, 1 ticked.

## Step 2 — the voice table and migration 012

- `store.py`: `VOICE_TABLE`, `VOICE_COLUMNS`, `_VOICE_SCHEMA` (created
  beside the summary table on every SQLite connect), `put_voice`,
  `get_voice` (Postgres `INSERT … ON CONFLICT (voice_key) DO UPDATE`).
- `db/migrations/012_divination_voice.sql` (011's header shape).
- `test_boundaries.py`: `_create_table_columns(sql, table)` finds the
  CREATE TABLE by name (N2); `test_divination_store_is_one_identity_free_table`
  → `test_divination_store_is_two_identity_free_tables` (per-table columns
  vs store tuple + migration 011/012; self-checks: `email` planted into each
  list, and a third table name).
- Mechanical: dw-6's `test_migration_011_sorts_last_with_the_same_columns`
  → `test_migration_011_has_the_same_columns` (012 now sorts last; the
  column check is unchanged).
- CLAUDE.md rules 9 (voice cache sentence), 10 (both tables; turn/render
  never import summary/store/voice), 11 (migration 012).
- `pytest tests/test_divination_persona.py tests/test_boundaries.py
  tests/test_divination_summary.py -q` → `73 passed`; full suite
  `1140 passed, 50 skipped, 1 warning in 112.68s`.

## Step 3 — the voice topic and the request model

- New `divination/voice.py` (topic `divination_voice` VERSION 1: role asset
  + `lang.en`/`lang.zh` declared before FINGERPRINT; `voice_key` over
  `sheet_facts` only; `voice_prompt`; `VOICE_SCHEMA`; `generate_voice`
  strip→cut (200/200/900)→blank + sign-name check→store; `cached_voice`;
  `cached_for` (N1: any exception logged → None); `to_wire`).
- New `divination/voice_role.txt`.
- `models.py`: `DivinationPersonaRequest` appended at EOF.
- Tests (function level): P4, P9 (en+zh), P7 (blank intro/bias, style
  without "Taurus", non-string → raise + no row; bias 400→200, style cut to
  900), doctrine = FINGERPRINT, `cached_for` read/None paths.
- `pytest tests/test_divination_persona.py -q` → `20 passed`; full suite
  `1150 passed, 50 skipped, 1 warning in 127.46s`.

## Step 4 — the job and the persona route

- `generation.py`: `DIVINATION_VOICE_PRIORITY = 1`,
  `ensure_divination_voice(person, persona, lang, *, db_path=None)` (key
  `divination_voice:<voice_key(facts)>`; the job closes over the sheet).
- `main.py`: `POST /api/divination/persona` (`divination_persona_voice`)
  right after the summary route: hit → 200; keyless → 503; ensure →
  re-read → 200; failed → 502 `persona voice unavailable`; else 202
  `{status:"generating", sheet}`.
- `test_boundaries.py`: `GENERATE_ON_REQUEST_RE` gains `generate_voice`,
  self-check `voice.generate_voice(sheet, 'venus', 'en')`.
  `test_main_names_the_synchronous_exceptions` untouched and passing.
- Route tests P5, P6 (JOBS_SYNC removed, event-blocked fake, `enqueued ==
  [key, key]`, then 200, one call), P7 route (502 + no row; bias cut 200),
  P8 (4×422 no fake call; keyless 503 + no job, stored hit 200), ensure
  idempotence.
- `pytest tests/test_divination_persona.py tests/test_boundaries.py -q` →
  `56 passed`; full suite `1162 passed, 50 skipped, 1 warning in 115.29s`.

## Step 5 — the turn reads the sheet and the voice

- FIRST recorded the chart-less goldens `server/tests/fixtures/
  divination_chartless_{en,zh}.txt` (2164 / 2414 bytes) from render.py at
  638a1db, whose only diff vs b308a92 is the step-1 `_REF_POINTS` alias
  (`git diff b308a92 638a1db --stat -- render.py personas` → `render.py | 5
  +++--`, no prompt text) — so they equal b308a92's output.
- `render.py`: fragments `self.read`, `self.marker`, `self.voice` after
  `dice.recall` (before FINGERPRINT); `NatalContext.sheet` (default None);
  `natal_context(person, persona="venus")`; `_self_section`;
  `system_prompt(..., voice=None)` order base → mirror → chart → dice →
  lang; `turn_messages(..., voice=None)`; module docstring paragraph.
- `turn.py`: `turn_events(request, person, voice=None)` → natal_context with
  `request.persona`, voice forwarded.
- `main.py` turn route: `voice = persona_voice.cached_for(...) if person
  else None` (store read only).
- `test_boundaries.py`: turn-state regex gains `voice` (self-checks: planted
  `from .voice import cached_voice` in turn.py, `from . import dice, voice`
  in render.py; `from . import persona as _persona` not caught); new
  `test_turn_route_reads_the_voice_and_never_ensures`.
- N3 update: `test_divination_render.py::test_topic_is_registered` fragment
  set gains the three `self.*` names. No other dw-2/3/5/6 test needed a
  change.
- P10 tests: order + sheet JSON == sheet (with meanings) + no `self.voice` +
  no `divination_voice:` enqueue; cached voice → `self.voice` then style
  (zh turn doesn't borrow en voice); chart-less en/zh == goldens both from
  `render.system_prompt` and through the turn route; `self.read` key phrases.
- `pytest tests/test_divination_persona.py -q` → `37 passed`; divination +
  boundaries `135 passed`; full suite `1168 passed, 50 skipped, 1 warning
  in 107.25s`. P12 complete.

## Step 6 — core persona client

- New `packages/core/src/divination/persona.ts` (types, `isPersonaSheet` /
  `isPersonaWire` over closed sets — BODIES/'Ascendant', SIGNS, house 1–12
  or null, dignity/confidence/stance enums, non-blank intro/bias —
  `fetchPersona(req, signal, onSheet?)` on postJson/pollDelay/isGenerating/
  MAX_POLLS; null on every failure; never throws); one appended barrel block.
- First run: app-native `architecture.test.ts` "every core barrel export is
  consumed" flagged `divination/CONFIDENCES|DIGNITIES|STANCES` → dropped
  them from the barrel (kept module-internal). Test fixture had a stray
  `houseSystem` (not in core `BirthData`) → removed.
- `npx vitest run src/chat/core-persona.test.ts` → `9 passed` (C1: 202-with-
  sheet/202/200 → 3 identical POSTs 5000 ms apart + onSheet; 502, 503,
  rejected fetch, house 13, blank intro → null; MAX_POLLS+1 202s → null;
  abort → null, 1 POST; guards).
- `grep -nE "fetch\(|window|localStorage" packages/core/src/divination/persona.ts`
  → no output.
- Root `npm test`: app-native `90 passed / 1069 passed`; web `Test Files 20
  passed / Tests 172 passed`. `npm run typecheck` clean.

## Step 7 — header, voice letter, i18n, styles (`/frontend-design` loaded)

- i18n `persona` namespace appended to en/zh (N5 strings; plus
  `placementLabel`, `biasLabel` for aria); `i18n.test.ts` binds
  `persona.dignities` to core `PersonaDignity` and asserts the words.
- New `chat/usePersona.ts` (birth data via `useSyncExternalStore` over core
  `getBirthData`/`subscribe`, `useLang`; abort on every birth-data/lang
  change; late `onSheet`/answers from an aborted run ignored; the sheet is
  kept across a lang switch for the same birth data; failed keeps the sheet).
- New `chat/PersonaHeader.tsx` (`PersonaHeader`, `VoiceAside`,
  `placementText`), `chat/persona.css` (engraved small-caps placement line
  over a hairline, Venus sign glyph, shimmering italic "finding her voice…",
  bias aside on a `--venus` border-left; reduced motion → `animation: none`;
  colours only `var(--…)`).
- `ChatPanel.tsx`: header block → `<PersonaHeader state={persona} />`;
  greeting letter → intro prose + `VoiceAside` when ready. Nothing else.
- Mechanical updates (the App now makes a second fetch):
  `chart/ChartStage.test.tsx` retry test routes its fetch stub by URL (chart
  sequence still pinned: `chartFetch` called twice); `vite.config.ts`
  `test.css.include` gains `/persona\.css/` (vitest blanks CSS, emptying
  `?raw`, as dw-6 found for log.css).
- New `chat/PersonaHeader.test.tsx`: W1, W2 (+ failed-voice case), W3, W4
  (zh re-POST, zh words 天蝎座 · 第二宫 · 落陷 · ℞ 逆行; the en run makes no
  further POST; birth-data change → new POST, old run silent; 金牛座 · 第十宫 ·
  入庙), W5 (turn body keys exactly action/birthData/lang/message/persona/
  transcript, no intro/bias text; transcript[0] is the user line), W6 css
  (reduced-motion block, no raw colour).
- `npx vitest run src/chat src/i18n.test.ts` green; root `npm test`:
  app-native `90 passed / 1069 passed` (colour, barrel, network, arithmetic
  guards included), web `Test Files 21 passed / Tests 181 passed`;
  `npm run typecheck` clean; `git diff b308a92 --stat -- chat.css useChat.ts
  theme personas` → empty.
