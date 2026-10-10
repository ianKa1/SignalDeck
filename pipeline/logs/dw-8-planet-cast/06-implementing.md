# 06 implementing — dw-8-planet-cast

Worker #1 of the parallel wave, worktree
`/Users/kaimao/Projects/astrology-wt/dw-8-planet-cast`, branch
`feature/dw-8-planet-cast`. Backend port 8001, Vite 5174.

## Step 0 — worktree prep, base
- `git branch --show-current` → `feature/dw-8-planet-cast`; HEAD `c4342d6`
  (dw-9-oral-delivery). dw-9 IS in the base; dw-12 is NOT (coordinator:
  it lands separately, merge on request at landing).
- `.env` → symlink to `/Users/kaimao/Projects/astrology/.env`;
  `server/data/` holds only the three `.se1` symlinks (no `.db` symlink).
  `node_modules/@astrace/core -> ../../packages/core`.
- Baseline before any edit:
  - server `conda run -n astrology pytest -q -x` → `1203 passed, 50 skipped, 1 warning in 115.43s`
  - root `npm test` → jest `Test Suites: 90 passed, 90 total` / `Tests: 1069 passed, 1069 total`; vitest `Test Files 22 passed (22)` / `Tests 212 passed (212)`
  - root `npm run typecheck` → clean (both workspaces).

## Step 1 — one persona list, three mirrors on the server
- `persona.PERSONA_PLANETS` → six entries in order; `render.PERSONAS =
  tuple(_persona.PERSONA_PLANETS)`; `models.DivinationPersona` alias
  replaces the three `Literal["venus"]`.
- `test_boundaries.py::test_persona_lists_agree` (get_args == dict keys ==
  render.PERSONAS; source-level literal parse; planted seventh literal
  `"pluto"` turns it red).
- New `tests/test_divination_roster.py` (S1; S2 model-level: pluto/sun/Venus
  fail validation on the three request models, all six validate).
- Existing `"mars"` 422 cases → `"pluto"` (turn, summary, persona tests).
- CLAUDE.md rule 10: one-list clause.
- Server suite: `1214 passed, 50 skipped, 1 warning in 106.80s`.
- Commit `1510766`.

## Step 2 — pre-dw-8 references, prompts per character
- FIRST recorded from the unedited (dw-9) render, before any prompt edit,
  under `server/tests/fixtures/divination_pre_dw8/`: `chartless_{en,zh}.txt`
  (cmp-identical to the then-current goldens), `venus_chart_section_en.txt`
  (26129 chars, `chart.read` through the chart JSON, chart A),
  `venus_cast_dice_section_en.txt` (1915 chars, Pluto·Scorpio·8, chart A).
  Recorder script kept at `scratchpad/dw8/record.py`.
- New `personas/{moon,mars,jupiter,saturn,mercury}.txt` (built like
  post-dw-9 venus.txt, no length lines, no "dressed as something else"
  clause per N4); `git mv personas/venus-dice.txt personas/dice.txt`
  (asset `dice.brief`); `venus.txt` untouched.
- render.py: `persona.<id>` registered in a loop over PERSONAS;
  `focus.<id>` ×6 (`focus.venus` = dw-3's exact sentence); `chart.read`
  `{focus}`; `roster.rules`/`roster.list`/`roster.timing` after `depth.*`
  (`ROSTER_FRAGMENTS`); `self.read` `{planet}` with the D bullet removed
  (examples now "your {planet} in Capricorn in the fourth house, square
  Pluto" / "in Scorpio; I look for the hidden motive…"). Two small public
  helpers `chart_read(persona)` / `self_read(planet)` are the one place the
  templates are formatted (tests reuse them).
- Goldens `divination_chartless_{en,zh}.txt` re-recorded: +6 lines each
  (the three roster fragments with their separators).
- Mechanical test updates: dice asset path/name, fragment set, template
  texts via `render.chart_read("venus")`/`render.self_read("Venus")`, the
  p10 self.read D assertion moved to roster.rules.
- `test_divination_roster.py`: S4 (six ids × chart-less/chart A, roster
  exactly once, focus + self.read per planet, sheet planet, Moon Pisces,
  Saturn Capricorn, order incl. dice, risk/paste, no length lines), S5
  (goldens minus roster block == pre copies; chart section byte-equal; D
  rule moved), S6 (venus-dice.txt gone, dice.txt is `dice.brief`, Venus
  dice section byte-equal, Mars cast streams `dice` first with the brief).
- Server suite: `1230 passed, 50 skipped, 1 warning in 105.36s`.
- Commit `1c786e2`.

## Step 3 — the pure sheets route
- `persona.sheets_for(person)` (pure: ONE `natal_report`, facts per id in
  order); `models.DivinationSheetsRequest` at EOF; `POST
  /api/divination/sheets` right after the persona route, body
  `{schemaVersion:1, sheets: sheets_for(_person(birthData))}`.
  Small deviation: the one-report loop lives in `persona.py`
  (`sheets_for`), not inline in main.py — same single report, keeps the
  route body one line and the purity pin trivially checkable.
- `test_boundaries.py::test_sheets_route_is_pure` (no
  `generate_|ensure_|store|cached_|voice` in the route body; planted
  `generation.ensure_divination_voice(` bites).
- S3 tests: chart A → exact keys/order; moon Pisces/8/None/steady/direct,
  mars Aries/9/domicile, jupiter Cancer/12/exaltation, saturn
  Capricorn/6/domicile/retrograde with `[Ascendant opposition conflict,
  Venus trine ally]`, mercury Gemini/11/domicile, venus == dw-7 facts; no
  provider env; LLM fakes uncalled; scheduler.enqueue uncalled; store
  put/put_voice uncalled. 422 on missing birthData and on a bad date.
- CLAUDE.md rule 10: sheets-route clause.
- `test_main_names_the_synchronous_exceptions` unchanged, passes.
- Server suite: `1234 passed, 50 skipped, 1 warning in 105.40s`.
- Commit `d9cdb68`.

## Step 4 — summary and voice for any character
- `voice_role.txt`: "Venus" → `<planet>` in the three templates; "a
  situation about love, friendship or self-worth" → "a situation from its
  own domain (the part of life this planet governs, as the sheet's meanings
  describe it)". `voice.VERSION` stays 1 (topic FINGERPRINT moves — it is
  provenance only). `voice.py`'s zh lang line still cites 金星/金牛座/第十宫
  as a translation example (not in `voice_role.txt`; S9 scopes the role).
- `summary_role.txt`: "one of six planet characters … which character it
  was is the persona id in the data"; "not the character's style"; "no
  mention of the character". Summary VERSION and key unchanged.
- Tests (`test_divination_roster.py`): S2 route-level (pluto/sun/Venus →
  422 on /turn, /summary, /persona with no fake called; saturn → turn
  streams `done`, summary 200, persona 200 via JOBS_SYNC); S8 (moon summary
  200 `persona:"moon"`, key differs from venus, role has no "Venus"); S9
  (saturn persona 202 with Saturn's facts while enqueue is stubbed, the job
  body run by hand stores the fake voice, next POST 200; voice user JSON
  `"planet":"Saturn"`; role names none of the ten planets, has `<planet>`,
  no "love, friendship or self-worth"; VERSION 1).
- Server suite: `1240 passed, 50 skipped, 1 warning in 105.55s`.
- Commit `7a2c2e5`.

## Step 5 — the handoff side field
- render.py: `side.role` neutral, `{name}` = the persona's planet ("…
  and {name}, one of six planet characters. Name the single mood the reply
  is written in…"; N3: no temperament, "the reply"); new `side.handoff`
  (the six ids with domains; never the turn's own; agree with the reply
  when it names one; else "none"); `side_prompt(…, persona, handoff)`;
  `handoff_ids(persona)` (five others + "none"); `side_schema(catalogue,
  handoff)` adds a required `handoff` enum on BOTH branches (empty
  catalogue → `{mood, handoff}`; no handoff → unchanged, MOOD_SCHEMA);
  `to_wire_handoff(value, persona)` the one shaper.
- turn.py: `_side_read` returns `(mood, refs, handoff)`, asks only when
  `action == "chat"`, any failure `(None, [], None)`; `done` =
  `{mood, chartRefs, handoff}`. main.py turn docstring updated.
- Mechanical test updates (turn/dice/render): `done` gains `"handoff":
  None`; `side.role` formatted with "Venus"; chat side system now ends with
  `side.handoff`; chat schemas `{mood, handoff}` / `[mood, chartRefs,
  handoff]`; fragment set + `side.handoff`.
- `test_boundaries.py::test_handoff_is_never_parsed_from_the_reply`
  (turn.py/render.py import no `re`; shaper body never names the reply;
  planted `import re` bites).
- S7 tests: schema enum = five others + none, `side.handoff` in system,
  saturn→saturn, none/venus/pluto/42/missing→null, raising→all nulls,
  chart-less `{mood, handoff}` both required with moon→"moon", cast and
  deeper ask no handoff and send null, `done` keys exactly
  `mood, chartRefs, handoff`.
- CLAUDE.md rule 10: handoff clause.
- Server suite: `1254 passed, 50 skipped, 1 warning in 105.36s`.
- Commit `a628d7f`.

## Step 6 — core roster
- New `packages/core/src/divination/roster.ts`: `PERSONA_IDS` (six, in
  order), `isPersonaId`, `ACTIVE_KEY = 'astrology.divination.active.v1'`,
  `getActivePersona`/`setActivePersona`/`subscribeActivePersona` (KV port;
  invalid → null), `fetchSheets(birthData, signal)` (one `postJson`; null
  on non-200, malformed body, any sheet failing `isPersonaSheet`, rejected
  fetch; never throws), type `PersonaSheets`.
- `types.ts`: `PersonaId = (typeof PERSONA_IDS)[number]` (type-only import,
  no runtime cycle); `TranscriptEntry.handoff?`; `done.handoff`.
- `turn.ts`: `handoff` = a valid id ≠ the request persona, else null.
- `transcript.ts` `sanitize` keeps a valid `handoff` on persona entries;
  `toWire` unchanged (never emits it). `session-log.ts` `parseRecord`:
  `isPersonaId`. `index.ts`: one appended export block.
- Mechanical: `core-divination.test.ts` `done` expectations gain
  `handoff: null` (13 sites).
- New `web-divination/src/roster/core-roster.test.ts` (golden
  `'venus,moon,mars,jupiter,saturn,mercury'` with a comment naming
  persona.py): C1 (ids; done.handoff saturn/null/missing/pluto/42/own id),
  C2 (active key, notify/unsubscribe, venus/moon transcripts separate), C3
  (sanitize keeps saturn / drops pluto / not on the wire; parseRecord moon
  ok, pluto rejected; fetchSheets 200 six in one POST, null on 422, house
  13, missing sheet, rejected fetch).
- `grep -nE "fetch\(|window|localStorage" packages/core/src/divination/roster.ts` → nothing.
- Root `npm test`: jest `90 passed` suites / `1069 passed`; vitest
  `23 passed (23)` files / `229 passed (229)`. `npm run typecheck` clean.
- Commit `d3d8b1f`.

## Steps 7–9 — tokens/--char/strings, picker + per-character panel, handoff slip + per-character log
Loaded `/frontend-design` first. Committed as ONE milestone (deviation from
the plan's per-step commits): the `{name}` templates (step 7) break every
call site until the components take a persona (step 8), and the per-record
log chrome (step 9) shares those files — splitting would leave red commits.
- **Tokens**: `webTokens.persona` / `personaGhost` (six keys each; Venus
  keeps #d9967c / rgba(217,150,124,0.35); Moon pearl-blue #b8cce4, Mars
  ember #e2714e, Jupiter orchid #c79bd9, Saturn lead-brass #b4a574,
  Mercury quicksilver-sage #a3c6ad; ghosts at 0.35); `venus`/`venusGhost`
  removed. The theme leaf may not import core (architecture G7 bit when I
  first imported `PersonaId`), so tokens.ts declares a local `PersonaKey`
  union and `RosterPicker.test.tsx` binds it to `Record<PersonaId,string>`
  (compile-time) + key order (runtime). Guard not weakened.
- **CSS**: every `var(--venus…)` in chat.css, persona.css, log.css,
  wheel.css → `var(--char…)`. New `roster/roster.css`: `.persona-scope`
  default + `.persona-scope[data-persona='<id>']` → `--char`/`--char-ghost`
  from `--persona-<id>`/`--persona-ghost-<id>` (class + attribute qualifier,
  as wheel.css's `.wheel[data-active]`); the picker; the "The six" header
  button; the handoff slip; a reduced-motion block. vite.config.ts test
  `css.include` widened to every `.css` (vitest blanks CSS otherwise, which
  emptied `roster.css?raw` and would make the "no --venus" walk vacuous).
- **i18n**: `roster` namespace (title/lede/open/openHint/close/resume/
  examplesLabel/handoff/handoffAsk + six {name, domain, greeting, example1,
  example2}; zh names 金星/月亮/火星/木星/土星/水星; Jupiter's examples
  verbatim from the spec). `chat.subtitle`/`chat.greeting` moved to
  `roster.<id>`; all character-named strings in chat/log/persona are
  `{name}` templates; N2 (`{name} is finding a voice…`, `{name}'s bias`,
  zh `{name}正在寻找自己的声音…`/`{name}的偏见`; log.empty now "one of the
  six"). `roster` is appended LAST (dw-12's `auth` is not in the base; at
  merge, keep `roster` before `auth`).
- **core**: `PERSONA_BODIES` (id → Body) added to roster.ts + barrel, the
  one place the web gets a character's planet (for its glyph).
- **web**: `roster/useRoster.ts` (`useRoster` {active, setActive (clears the
  wheel activation), sheets (fetched only with birth data, aborted on
  change)}, `personaGlyph`, `personaName`); `roster/RosterPicker.tsx`
  (dialog overlay, plates in PERSONA_IDS order with 60 ms stagger, seal +
  name pick, examples pick+prefill, placement line via dw-7
  `placementText`, resume mark, close "← Back to {name}" + Esc only when a
  character is active — N5); App.tsx (shell `persona-scope` +
  `data-persona`, picker when none active or opened, ChatPanel keyed by
  persona only, seed `{persona, text, nonce}`, `pick` shared by examples
  and handoff); ChatPanel (props persona/seed/onHandoff/onOpenRoster,
  glyph on eyebrow + caret + greeting letter — N1, `HandoffSlip` in the
  target's `persona-scope` after the chips on stored, unstopped entries,
  question = the user entry before); PersonaHeader (glyph sigil, `{name}`
  titles, domain subtitle, "The six" button); useChat (stores
  `done.handoff`); SessionBar (`persona` prop); SummaryCard (record's
  glyph/name, `persona-scope` + `data-persona`); SessionTranscript
  (`persona` prop — N1); SessionsScreen (reader wrapped in the record's
  scope).
- **Mechanical test updates**: App/SessionBar/SessionsScreen suites set
  `astrology.divination.active.v1 = venus` in beforeEach (they speak with
  Venus); apply.test nested-token count; `{name}`-filled string assertions
  in SummaryCard/SessionBar/PersonaHeader tests.
- **New tests**: `i18n.test.ts` roster block (six names both languages in
  order; Jupiter examples; "Venus"/"金星" only at `bodies.Venus` and
  `roster.venus.name`; templates carry `{name}`; no he/she/her/他/她 in
  chat/log/persona, no she/her/她 in roster); `roster/RosterPicker.test.tsx`
  (App-level): W1 first use (six plates in order, glyph/name/domain/two
  examples, no placement, no sheets POST, no close, Esc no-op, no chat
  behind — N5), W1 chart A (Moon "in Pisces · 8th house" + ♓, Saturn ends
  "· ℞ retrograde", one sheets POST), reduced-motion; W2 (Saturn example →
  active saturn, "Saturn"/"Your Saturn", ♄, composer prefilled, no turn);
  W3 (own transcripts both directions + turn bodies; switch mid-stream →
  stopped partial on venus, mars untouched, signal aborted; opening the
  picker does not abort and closing shows the reply still arriving;
  same-character example replaces the draft in the SAME textarea node, the
  nonce re-applies it); W4 (handoff saturn slip in saturn scope with
  "Saturn reads this better", survives a remount from KV, "Ask Saturn →"
  switches and prefills the answered question, no new turn; null → no
  slip); W5 (shell data-persona; roster.css mapping per id; no `--venus` in
  any src .css/.ts/.tsx; six-key token pairs, no venus/venusGhost; Moon
  caret/eyebrow ☽; End with Mars → `mars` record, card ♂ + data-persona
  mars); N1 reopened Moon card ☽ + transcript eyebrow "☽Moon" in moon scope.
- Root `npm test`: jest `Test Suites: 90 passed` / `Tests: 1069 passed`;
  vitest `Test Files 24 passed (24)` / `Tests 248 passed (248)`;
  `npm run typecheck` clean. Server suite last green at step 5 (no server
  file touched since).
