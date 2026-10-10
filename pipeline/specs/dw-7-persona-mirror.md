# dw-7-persona-mirror — the character is your placement

## Goal

Venus speaks as the person's OWN Venus: a deterministic persona sheet (sign, house, aspects, dignity, retrograde) shapes her, a voice written once per placement is cached, and she can name the placement behind her style and her own bias. QUEUE.md `dw-7-persona-mirror`; epic `pipeline/epics/divination-web.md`.

## Non-goals

- The other five characters, the picker and handoff (dw-8). The sheet is generic over any of the ten planets, but only `venus` is a persona.
- Reply shape: bubbles, length, the depth rule, "go deeper" (dw-9). dw-7 does not edit `personas/venus.txt`, the `lang.*` fragments or the turn's event grammar.
- Current transits and timing (dw-11), and inline pills (dw-10).
- House rulerships, sect, speed, patterns and degrees in the sheet. The queue names five factors; the sheet carries those five.
- A device-side cache of the voice, a voice image, and a voice for anything but a persona planet.
- Pressing the placement line to light the wheel. The dw-4 chips already do that.
- Any change to `app-native/`.

## Decided defaults

1. **Where the sheet lives.** It lives in the new pure module `server/app/divination/persona.py`. The sheet joins Tier A facts (`natal_report`) to Tier B meanings (`app.dictionary`). Chart may not import dictionary and dictionary may not import chart (rule 10), so the join can only happen in a Tier C package. Divination may already import both. The module does no I/O, no LLM call, no prompt work and no storage. It takes a planet name and a `natal_report` result, so dw-8 reuses it unchanged.
2. **Sheet content.** Each sheet has these fields:
   - `planet`, `sign`, and `house` (null when the birth time is unknown);
   - `dignity`: the major state (`domicile`/`exaltation`/`detriment`/`fall`) or null;
   - `confidence`, from a fixed table: domicile or exaltation → `assured`, detriment or fall → `uneasy`, otherwise `steady`;
   - `retrograde`: a boolean. Retrograde reads as second-guessing;
   - `aspects`: up to 5 of the planet's chart aspects whose other end is one of the ten planets or the Ascendant (the chip catalogue's points), tightest orb first. Each is `{with, type, stance}`, where trine or sextile is an `ally`, square or opposition a `conflict`, and a conjunction is `fused`.

   Server-side only, the sheet also carries the dictionary meanings of the planet, sign, house, dignity, retrograde and each aspect type. The client never gets them.
3. **The voice is a job, cached by content.** A new prompt topic `divination_voice` (VERSION 1) writes three fields for one sheet in one language:
   - `intro`: one first-person line naming the planet and sign, and the house when known;
   - `bias`: one first-person sentence saying what this placement notices first, or gets wrong;
   - `style`: English voice notes for the system prompt (diction, tempo, what she notices, how dignity, retrograde and conflicts colour her). It must contain the sheet's sign name.

   The content key is sha256 over the topic (name, VERSION), the persona planet, the language and the sheet FACTS (never the meanings, never birth data). Two people who share a placement therefore share a voice. The FINGERPRINT is stored beside the row as `doctrine`, never used as key material (the 2026-08-13 ruling). If the dictionary wording changes, rewriting the stored voices is a deliberate VERSION bump. The voice is stored in a second table `divination_voice` in the existing divination store: SQLite in `data/divination.db`, Postgres via migration **012**. Like the summary table it has no identity column.
4. **The client asks, and the ask is the ensure.** `POST /api/divination/persona {persona, lang, birthData}` follows ordinary rule 14, with the event card's precedent (main.py:271-275) of facts riding along with a 202:
   - store hit → 200 `{schemaVersion, persona, lang, sheet, voice:{intro, bias}}`;
   - miss → the job is ensured and the answer is 202 `{status:"generating", sheet}`;
   - failed job → 502;
   - no provider on a miss → 503.

   The web app sends this request whenever birth data or the language changes, and polls through core's poll helpers.
5. **The turn only reads.** The streamed turn stays the rule-14 exception for the REPLY and nothing else. main.py reads the cached voice (a store read, no enqueue) and hands it to `turn_events`. With birth data, the system prompt always carries the sheet (base role + sheet facts) and adds the voice's `style` once the voice is cached. So the first turns sound like the placement, and the voice arrives on a later turn. `turn.py` and `render.py` import neither the store nor the voice module, and the turn request wire is unchanged.
6. **Mirror instructions** (C and D as decided defaults). With a sheet present, the prompt tells Venus four things:
   - she is THIS person's Venus, as placed in the sheet;
   - when asked why she sees things as she does, she names her sign, her house when known, and the one aspect behind it;
   - she knows her bias and says so when it colours a read ("I'm your Venus in Scorpio; I look for betrayal before tenderness, so weigh that");
   - she reads the person's pattern, the dynamic and the words, and never claims to know what another person feels.

   She never states a placement that is not in the sheet or the chart. The chart-less prompt stays byte-identical to dw-6, so D is added only with the mirror (dw-8 generalises it).
7. **No birth data.** She uses the base role only: no sheet, no voice, no persona request, and the header is the dw-2 header.
8. **What the person sees** (the frontend-design bar). The chat keeps its letter-and-seal register, and no new colour tokens are added.
   - **Header.** With a sheet, the title becomes "Your Venus". Under it an engraved placement line replaces the subtitle: the sign glyph, "in Taurus · 10th house · at home", plus " · ℞ retrograde" when retrograde. The dignity words are "at home", "exalted", "in exile" and "in fall"; zh uses 入庙, 入旺, 落陷 and 入弱. A time-unknown sheet omits the house.
   - **While generating.** A faint italic "finding her voice…" note sits under the placement line with a slow shimmer. Reduced motion shows it static.
   - **When the voice is ready.** The opening letter replaces the static greeting with the `intro` as prose, followed by the `bias` as an italic aside on a `--venus` hairline rule.
   - **When it fails.** The note disappears, the greeting stays and the placement line stays.
   - **Not a message.** The intro is never a transcript entry, so it never reaches the turn wire, the summary key or the session log.
9. **Language.** The `intro` and `bias` are written in the request language and `style` stays English. A zh session gets its own cached voice.

## Architecture

Cites `pipeline/epics/divination-web.md` (reuse map, dependency rules, event grammar). Only dw-7's delta is written here.

### Reuse (verified 2026-09-28)

| Need | Existing | Use |
|---|---|---|
| Chart + structure | `chart/natal/report.py:12` `natal_report`; `structure/planet_state.py:212` rows (`essential.dignities/debilities/peregrine`, `accidental.motion`); `planet_state.py:37` `_dignities` via `derive_structure` | Read `structure["dignities"]` for the major state; `chart["planets"][i]["retrograde"]`, `house`; `chart["aspects"]` (`orb`) |
| Meanings | `dictionary/symbols.py:14` PLANETS, `:27` SIGNS, `:42` HOUSES, `:57` ASPECTS; `dictionary/natal.py:15` DIGNITIES, `:135` RETROGRADE_NOTE (all via the `app.dictionary` barrel) | As-is |
| Points set | `divination/render.py:135` `_REF_POINTS` | `persona.SHEET_POINTS` is the same set; `render._REF_POINTS` becomes an alias of it (one definition) |
| Prompt topics | `app/prompts.py` `register_topic` :129, `.asset` :93, `.fingerprint` :118 | New topic `divination_voice`; new `self.*` fragments on topic `divination` |
| Job + store shape | `divination/summary.py` (key, prompt, validate, `generate_*`, `cached_*`, `to_wire`); `divination/store.py` (dual backend); `generation.py:207` `ensure_divination_summary` | Mirror exactly |
| Route shape | `main.py:446` summary route; facts-with-202 precedent `main.py:271-275` | Mirror |
| Turn composition | `render.py:170` `natal_context`, `:185` `system_prompt`, `:241` `turn_messages`; `turn.py:200` `turn_events` | Additive params |
| Poll client | core `divination/summary.ts` `pollSummary`; `platform` `postJson`, `pollDelay`, `isGenerating`, `MAX_POLLS` | Mirror |
| Birth-data feed | core `birth-data` `getBirthData`, `subscribe` | usePersona |
| Header | `ChatPanel.tsx:229-239` header, `:250-252` greeting letter; `chat.css:41-79`; i18n `signs`, `chat.houses`, `bodies` | Two edits in ChatPanel; new CSS file |

### Module map (created or changed only)

```
server/app/
├── divination/
│   ├── persona.py          NEW  pure sheet: SHEET_POINTS, persona_sheet, sheet_facts, PERSONA_PLANETS
│   ├── voice.py            NEW  topic divination_voice: voice_key, voice_prompt, VOICE_SCHEMA,
│   │                             generate_voice (job body), cached_voice, cached_for, to_wire
│   ├── voice_role.txt      NEW  the voice writer's role asset
│   ├── store.py            CHG  + table divination_voice: put_voice, get_voice, VOICE_COLUMNS
│   ├── render.py           CHG  + self.read/self.marker/self.voice fragments; NatalContext.sheet;
│   │                             natal_context(person, persona="venus"); system_prompt(..., voice=None)
│   └── turn.py             CHG  turn_events(request, person, voice=None) → render
├── db/migrations/012_divination_voice.sql   NEW
├── generation.py           CHG  + ensure_divination_voice, DIVINATION_VOICE_PRIORITY = 1
├── models.py               CHG  + DivinationPersonaRequest (EOF)
└── main.py                 CHG  + POST /api/divination/persona; turn route reads cached_for
server/tests/
├── test_divination_persona.py   NEW (sheet, key, route, store)
└── test_boundaries.py      CHG  pins below
packages/core/src/divination/
├── persona.ts              NEW  PersonaSheet/PersonaVoice/PersonaWire types, guards, fetchPersona
└── index.ts                CHG  one appended export block
web-divination/src/
├── chat/usePersona.ts      NEW  birth data + lang → persona state (abort on change)
├── chat/PersonaHeader.tsx  NEW  title + placement line + finding-voice note
├── chat/persona.css        NEW  placement line, aside, shimmer, reduced motion
├── chat/ChatPanel.tsx      CHG  header block → <PersonaHeader>; greeting letter → intro + bias when ready
└── i18n/en.ts, zh.ts       CHG  + `persona` namespace (appended)
```

### Module contracts

**`divination/persona.py`**: imports only `app.chart.natal` (`natal_report`), `app.chart.points` (`PLANET_NAMES`) and `app.dictionary`.
- `PERSONA_PLANETS = {"venus": "Venus"}`.
- `persona_sheet(planet, report) -> dict` returns the facts of Decided default 2, plus `meanings`. `planet` is any of `PLANET_NAMES`; any other value raises `ValueError`.
- `sheet_for(person, persona) -> dict` wraps `natal_report(person)`.
- `sheet_facts(sheet) -> dict` is the facts without `meanings`: the wire and key material.
- It is deterministic: equal input gives equal output. It never reads a clock, the network or a store.

**`divination/voice.py`**: imports `app.llm`, `app.prompts`, `.persona` and `.store`.
- `voice_key(facts, persona, lang)`: 64 hex characters.
- `voice_prompt(sheet, lang) -> (system, user)`: the system text is the role asset plus a lang line; the user text is the sheet JSON, meanings included.
- `generate_voice(sheet, persona, lang, *, db_path=None)` is the job body. It makes one `llm.generate_sections` call against `VOICE_SCHEMA`. It trims `intro` and `bias` to at most 200 characters and `style` to at most 900. It raises `AnalysisUnavailable` and stores nothing when a field is blank or `style` lacks the sheet's sign name.
- `cached_voice(facts, persona, lang)` is a store read.
- `cached_for(person, persona, lang) -> dict | None` computes the sheet, then reads the store. It is the turn route's one call and never enqueues.
- `to_wire(sheet, voice)` builds the 200 body. It drops `style`, `model` and `promptVersion`.

**`divination/store.py`**: `put_voice(key, result, *, doctrine, db_path=None)` and `get_voice(key, *, db_path=None)`. `VOICE_COLUMNS = ("voice_key", "voice", "persona", "lang", "model", "prompt_version", "created_at", "doctrine")`, where `voice` is JSON `{intro, bias, style}`. The backend choice per call is unchanged, and so are the conftest `DB_PATH` redirect (same file) and the module's status as the ONE stateful divination module.

**`divination/render.py`**:
- `NatalContext` gains `sheet: dict | None`.
- `natal_context(person, persona="venus")` builds the sheet with `persona.persona_sheet(PERSONA_PLANETS[persona], report)`.
- `system_prompt(persona, lang, ctx=None, cast=None, voice=None)` gives the order persona base → [`self.read` + `self.marker` + sheet JSON (facts + meanings) + (`self.voice` + `voice.style` when given)] → chart section → dice → lang.
- `turn_messages` passes `voice` through.
- With `ctx is None` the output is byte-identical to today.

**`divination/turn.py`**: `turn_events(request, person, voice=None)` only forwards `voice`. The events, deadline and side read are untouched.

**`generation.ensure_divination_voice(person, persona, lang, *, db_path=None) -> str`**: the key is `divination_voice:<voice_key>`. It is idempotent through the queue's dedup, and a failed job is held by the queue cooldown.

**main.py `divination_persona`**:
1. cached → 200;
2. keyless → 503 `{"detail":"divination unavailable"}`;
3. ensure, then re-read → 200;
4. job failed → 502 `{"detail":"persona voice unavailable"}`;
5. else 202 `{status:"generating", sheet}`.

The turn route gains `voice = persona_voice.cached_for(person, request.persona, request.lang) if person else None`.

**core `divination/persona.ts`**:
- `fetchPersona(req, signal, onSheet) -> Promise<PersonaWire | null>` POSTs, calls `onSheet` with the 202's sheet, and polls every `POLL_INTERVAL_MS` up to `MAX_POLLS`. It never throws.
- Guards `isPersonaSheet` and `isPersonaWire` check the closed sets (sign in core `SIGNS`, house 1–12 or null, the dignity enum, the stance enum).

**web `usePersona(persona)`** returns `{status:'none'|'generating'|'ready'|'failed', sheet?, voice?}`. It has no KV and no network outside core.

### Wire (additive)

`POST /api/divination/persona`
- Request: `{persona:"venus", lang:"en"|"zh", birthData: BirthData}`, where `birthData` is required and validated like `/api/chart`. Any breach is a 422.
- `sheet`: `{planet, sign, house|null, dignity|null, confidence, retrograde, aspects:[{with, type, stance}]}`.
- 200: `{schemaVersion:1, persona, lang, sheet, voice:{intro, bias}}`.
- 202: `{status:"generating", sheet}`.
- 502 and 503 as above.

The turn wire and the event grammar are unchanged.

### Dependency rules and forbidden edges

- ❌ `persona.py` imports nothing but chart, dictionary and the stdlib: no llm, prompts, store or db (a new pin).
- ❌ `turn.py` and `render.py` never import `voice` or `store`. The dw-6 regex widens from `summary|store` to `summary|store|voice`. `render.py` MAY import `persona` (it is pure).
- ❌ main.py names no generator: `GENERATE_ON_REQUEST_RE` gains `generate_voice`. The turn route names no `ensure_`.
- The divination importers stay `generation.py` and `main.py`. The db edge stays store.py's single line.
- The fence (epic rules) is unchanged. `voice.py` imports `.store`, as `summary.py` does.

### Guard and CLAUDE.md amendments (same commit)

- `test_boundaries.py`:
  - `test_divination_store_is_one_identity_free_table` becomes two tables, `{divination_summary, divination_voice}`, each with a pinned column list checked against its CREATE TABLE and its migration (011, 012);
  - the turn-state regex gains `voice`;
  - add `test_persona_sheet_is_pure`;
  - add `generate_voice` to the generator regex, with a self-check.
- CLAUDE.md:
  - Rule 9: the divination store gains the voice cache, keyed by topic (name, VERSION), persona, language and the placement's sheet facts, never identity or birth data.
  - Rule 10: divination's stateful exception covers both tables; `turn.py`/`render.py` never import `summary`, `store` or `voice`; `persona.py` is the pure sheet.
  - Rule 11: `divination/store` (migrations 011, 012).
- Epic file: at docs-sync.

### Shared files (landing-conflict surface with dw-9 and dw-12)

- **Likely overlap with dw-9:**
  - `render.py`: new fragments go after `dice.recall`; the new parameter defaults to None;
  - `turn.py`: one parameter and one pass-through;
  - `ChatPanel.tsx`: the header block and the greeting letter only;
  - `i18n/en.ts`/`zh.ts`: a new `persona` namespace appended.
- **Possible overlap with dw-12:** `main.py`, where the new route goes after the summary route, and `models.py`, where the new model goes at EOF.
- **Untouched by dw-7:** `personas/venus.txt`, `chat.css`, `useChat.ts`, `llm.py`, core `types.ts`, `turn.ts`, `theme/`.
- **Migration number:** 012 assumes neither wave member adds a migration. If one does, the later lander renumbers.

## Acceptance Criteria

Server tests use a monkeypatched `llm.generate_sections` and `llm.stream_turn` only. Charts are REAL (Swiss Ephemeris). `JOBS_SYNC=1` applies except where stated. Run `npm run server:test`, `npm test` and `npm run typecheck`.

- **Chart A**: 1990-06-15 08:30, 39.9042 / 116.4074, Asia/Shanghai, placidus (the dw-3 fixture).
- **Chart B**: 1986-10-20 06:15, 40.7128 / -74.0060, America/New_York, placidus.

**Server**
- **P1 (sheet A)**: The test first asserts chart A's Venus is Taurus, house 10, direct. `sheet_facts(persona_sheet("Venus", natal_report(A)))` then equals:
  - `planet:"Venus"`, `sign:"Taurus"`, `house:10`;
  - `dignity:"domicile"`, `confidence:"assured"`, `retrograde:false`;
  - `aspects` = Jupiter sextile ally, Pluto opposition conflict, Neptune trine ally, Saturn trine ally, Moon sextile ally, in that order (tightest orb first).

  Chiron is absent.
- **P2 (sheet B)**: The test first asserts chart B's Venus is Scorpio, house 2, retrograde. The facts are then:
  - `sign:"Scorpio"`, `house:2`;
  - `dignity:"detriment"`, `confidence:"uneasy"`, `retrograde:true`;
  - `aspects` = Mercury conjunction fused, Jupiter trine ally, Moon opposition conflict.

  The Midheaven is absent. P1 and P2's facts differ in sign, house, dignity, confidence, retrograde and aspects.
- **P3 (pure and generic)**:
  - Two calls on the same report are equal.
  - `persona_sheet("Mars", report A)` returns a sheet whose `planet` is `"Mars"`.
  - `persona_sheet("Chiron", …)` raises `ValueError`.
  - Chart A with `time:null` gives `house:null` and no Ascendant aspect.
  - `sheet_facts` carries no `meanings` key.
- **P4 (key)**:
  - `voice_key` is 64 lowercase hex characters and stable.
  - It changes with lang, persona planet, any fact, and a monkeypatched `voice.VERSION`.
  - It does NOT change with a monkeypatched `voice.FINGERPRINT`.
  - Two sheets with equal facts and different `meanings` give the same key, because the key reads `sheet_facts` only.
- **P5 (route, hit and miss)**: POST `/api/divination/persona` with chart A and lang `en`:
  - With a fake returning a valid voice, the first POST answers 200 with exactly `schemaVersion, persona, lang, sheet, voice`, where `voice` has exactly `intro, bias` and `sheet` equals P1's facts. The fake was called once.
  - A second POST answers an equal 200 without calling the fake.
- **P6 (202)**: With `JOBS_SYNC` removed and a fake that blocks on an event:
  - the first POST answers 202 `{status:"generating", sheet}` with P1's facts, and a second POST enqueues no second job;
  - once the event is released and the job has finished, the POST answers 200.
- **P7 (bad output)**:
  - A blank `intro`, or a `style` that lacks "Taurus", makes the POST answer 502 `{"detail":"persona voice unavailable"}` and stores no row.
  - A 400-character `bias` is served as its first 200 characters.
- **P8 (422 and 503)**:
  - These each answer 422 and call no fake: no `birthData`, persona `mars`, lang `fr`, a bad date.
  - With no key and no `ANALYSIS_LLM`, a miss answers 503 and no `divination_voice:` job is enqueued, while a stored hit still answers 200.
- **P9 (prompt)**: The voice fake receives:
  - a system text containing `voice_role.txt`, then the lang line;
  - a user text that parses to the sheet with `meanings`;
  - the schema `VOICE_SCHEMA` with `intro`, `bias` and `style` all required.
- **P10 (turn uses the sheet now, the voice later)**: With chart A:
  - A turn before any voice is stored has a system text with the order persona base < `self.read` < sheet JSON (containing `"Taurus"` and `"domicile"`) < `chart.read`, and it has no `self.voice`. No `divination_voice:` job is enqueued by the turn.
  - After a voice is stored for (A, venus, en), the next turn's system text also contains `self.voice` followed by that voice's `style`.
  - A turn without `birthData` has a system text that contains no `self.` fragment, and it equals the string HEAD b308a92's `render.system_prompt("venus", lang)` produces (recorded in the test as a golden for en and zh).
  - `self.read` contains the bias, name-your-placement and never-another's-feelings instructions (asserted by key phrases).
- **P11 (store)**:
  - The SQLite table `divination_voice` has exactly `VOICE_COLUMNS`, and the stored `doctrine` equals `voice.FINGERPRINT`.
  - `012_divination_voice.sql` exists, sorts last, and creates the same columns.
  - With `DATABASE_URL` set and a fake `db.connect`, `put_voice` issues `INSERT INTO divination_voice … ON CONFLICT (voice_key)`.
  - `server/data/divination.db` is untouched by the suite.
- **P12 (boundaries)**: `test_boundaries.py` passes with the amended pins, and each new self-check bites:
  - `from .voice import cached_voice` planted in `turn.py`;
  - `from app.llm import generate_sections` planted in `persona.py`;
  - `voice.generate_voice(` in main.py text;
  - an `email` column planted into the voice column list.

  `test_main_names_the_synchronous_exceptions` passes unchanged. The dw-2/3/5/6 divination suites pass, with at most mechanical call-site updates for the new keyword parameters.

**Core and web** (vitest, stubbed `fetch`, fake timers)
- **C1**: `fetchPersona` on responses 202 (with sheet), 202 and 200 makes 3 identical POSTs `POLL_INTERVAL_MS` apart. It calls `onSheet` with the sheet and resolves to the 200's body. A 502, a 503, a rejected fetch, a 200 whose `sheet.house` is 13, and `MAX_POLLS` + 1 consecutive 202s each resolve to null without throwing.
- **W1**: With no birth data, the header reads "Venus" and the dw-2 subtitle, the greeting letter is the static greeting, and no POST to `/api/divination/persona` is made.
- **W2**: With chart A's birth data and a mocked 202:
  - the title reads "Your Venus";
  - the placement line shows `SIGN_GLYPHS.Taurus`, "in Taurus · 10th house · at home" with no "℞";
  - "finding her voice…" is shown.

  After a mocked 200 the note is gone and the opening letter shows the `intro` prose and the `bias` aside in place of the greeting.
- **W3**: A mocked retrograde Scorpio house-2 sheet renders "in Scorpio · 2nd house · in exile · ℞ retrograde". A `house:null` sheet omits the house.
- **W4**: Switching the language to 中 re-POSTs with `lang:"zh"`, and the placement line reads the zh sign, house and dignity words (落陷 for detriment). Changing birth data aborts the in-flight poll and POSTs the new data.
- **W5**: After the voice is shown, sending a message POSTs a turn whose body has no intro and no voice field. The transcript's first entry is the user's line, not the intro.
- **W6**:
  - Every `persona` key exists in en and zh (the parity test).
  - `persona.css` has a `prefers-reduced-motion: reduce` block that sets `animation: none` on the shimmer.
  - The colour guard, the barrel guard and the network and arithmetic guards pass.
  - `chat.css`, `useChat.ts` and `theme/` are unchanged from b308a92.

**Real app** (backend with `ANALYSIS_LLM=claude-cli`, `DATABASE_URL` overridden to empty so SQLite is used, and CORS for the Vite origin; Vite with `VITE_API_BASE` set to that backend; any free ports)
- **A1**: Entering chart A shows "Your Venus", then the placement line "in Taurus · 10th house · at home". The network panel shows `POST /api/divination/persona` answering 202, then 200 within the poll budget. The opening letter then shows an intro that names Taurus, and a bias line.
- **A2**: In the same session, asking "Why do you talk the way you do?" gets a reply that names Taurus and the 10th house (or a named aspect from P1's list) as the source of her style.
- **A3 (two audibly different Venuses)**: The operator enters chart B in a fresh session (End, then change birth data), sees "in Scorpio · 2nd house · in exile · ℞ retrograde", and asks the SAME two questions as for chart A: "Should I tell him how I feel?" and "Why do you see it that way?". The log records both transcripts verbatim, and the pass condition is all of:
  - (a) chart B's intro, bias and second answer name Scorpio, and its second answer names a B-only factor (retrograde, detriment/exile, or the Mercury conjunction);
  - (b) chart A's second answer names Taurus or a P1 aspect and no Scorpio fact;
  - (c) the two first answers differ in advice or emphasis in a way the log quotes side by side;
  - (d) neither reply claims to know what "he" feels.
- **A4**: A reload shows the ready voice again from a single 200, with no 202. `sqlite3 server/data/divination.db '.schema divination_voice'` shows only the pinned columns, with one row per (placement, language) seen.
- **A5**: With 中, chart A's intro and bias are Chinese and the placement line reads 金牛座 · 第十宫 · 入庙 (the zh `signs` and `chat.houses` wording plus the new dignity word).
