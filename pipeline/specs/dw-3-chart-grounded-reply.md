# Feature Specification: dw-3-chart-grounded-reply

DIVINATION WEB EPIC, entry 3 of 6. Epic architecture:
`pipeline/epics/divination-web.md` (cited, not restated). The event grammar
it extends is fixed by `pipeline/specs/dw-2-venus-chat.md` (Wire).

## Goal

Implement QUEUE.md `dw-3-chart-grounded-reply`: Venus reads the user's natal chart, sent with each turn, and answers
from their real placements, saying why they bear on the question. The `done` event carries `chartRefs[]`, the
planets and aspects she relied on, taken from a structured side read and checked against the chart. They show as chips under the reply.

## Non-goals

- No wheel highlighting, dimming or chip taps (dw-4). In dw-3 the chips are
  static labels.
- No dice (dw-5). No summaries, "end session" or history (dw-6).
- No server state. The chart is computed per turn from the birth data in the
  request and dropped when the turn ends: no cache, table, session or
  journal row. The server stays identity-free (rules 6, 9 and 12).
- No new route, no new persona, no change to the `delta`/`error` events or
  to the 422/503 answers.
- No houses, signs or angles as chip kinds. Chips are planets and aspects
  only, as the queue notes say.
- No parsing of the reply prose, on the server or the client, to find refs.
- No transit or synastry context. Natal chart only.
- No native (app-native) change and no deploy work.
- No paid key in any automated test.

## Decided defaults

**Birth data on the turn**
- The request gains an optional `birthData` field. It has the same shape
  and validation as `POST /api/chart`'s body. A bad value is a 422 before
  any stream opens.
- The web sends the saved birth data (core's birth-data store) on every
  turn, including Retry. With none saved it sends `null`.
- The transcript is not tied to the chart. Editing birth data keeps the
  conversation, and the next turn is read against the new chart.
- A request without `birthData`, or with `null`, behaves exactly as in dw-2:
  Venus says she has not read the chart, invents no placements, and
  `done.chartRefs` is `[]`.

**What Venus is given**
- The chart context is built the way the natal reading builds its own: the
  same prompt restatement of chart plus structure (salience order, element,
  modality, dignity, house, angularity, aspects by tightest orb), plus the
  glossary for this chart (`relevant_meanings`). It sits in the system
  prompt under a labelled marker, after the persona and before the language
  line.
- The persona text drops its "I have not read your chart" paragraph. It
  moves into a separate `chart.none` fragment, used only without birth
  data. A new `chart.read` fragment is used with birth data. It tells Venus
  to:
  - ground the answer in the 1–3 placements or aspects that bear most on
    the question (for love and friendship, usually Venus, the Moon, Mars,
    the 5th and 7th houses and their rulers, and aspects to these);
  - name each one plainly (for example "your Venus in Taurus in the tenth
    house", "your Venus opposite Pluto") and say in a sentence why it bears
    on what they asked;
  - never state a sign, house, aspect or dignity that is not in the chart
    data, and never recite the whole chart;
  - leave out degrees and orbs unless asked;
  - when the chart says the birth time is unknown, name no house, rising
    sign or angle, and say so once if the question needs one.
- Voice and length rules are unchanged: 60–180 words, 1–3 plain
  paragraphs, no markdown. Both new fragments are registered on the
  `divination` topic, so the fingerprint moves.

**chartRefs: where they come from**
- They come from the post-stream side read that already names the mood.
  One call now returns both `{mood, chartRefs}`. No second model call is
  added.
- The side read gets the question, the finished reply and a catalogue of
  the refs this chart allows. Each catalogue item is an id plus a readable
  label, for example `planet:Venus` "Venus in Taurus, house 10" or
  `aspect:Venus|opposition|Pluto` "Venus opposition Pluto". It returns the
  ids the reply named or relied on, in the order the reply uses them. The
  schema lists the catalogue ids as an enum.
- The catalogue holds the ten planets, plus every aspect in the chart whose
  two ends are planets or the Ascendant. These are exactly the points the
  wheel draws. Aspects to Chiron, the nodes or the Midheaven are not
  chip-able.
- The server keeps only ids that are in the catalogue. It drops duplicates
  and anything unknown, and keeps the first 6. So a ref can never name
  something the chart does not have, whatever the model returns.
- If the side read fails, is refused, or runs past the turn deadline, the
  result is `done {mood:null, chartRefs:[]}`. The reply stands. A reply that
  names no placement gives `[]`.
- Without birth data, the side read is the dw-2 mood-only read, unchanged.

**Wire shape** (fixed here for dw-4; exact shapes in Architecture)
- A planet ref names a body. An aspect ref names `bodyA`, `type` and
  `bodyB` in the chart's own order, so `aspectKey` of the matching chart
  aspect equals `bodyA|type|bodyB`. That value is what the wheel's
  `data-aspect-key` holds.

**Client**
- `streamTurn` passes `chartRefs` through on `done`. It drops malformed
  items (unknown kind, body or aspect type) and treats a missing field as
  `[]`.
- A finished persona entry stores its `chartRefs` in the KV transcript,
  only when the list is non-empty. They are never sent back on the wire
  (`toWire` keeps `{role, text}`). Stopped or failed replies have no refs.
  Entries saved by dw-2 render with no chips.

**Chips (look)**
- Placement: under the finished reply's prose, before the mood tag. A row
  that wraps, headed by a small-caps eyebrow, "read in your chart" /
  "星盘所见", in `textFaint`.
- Each chip looks like an engraved seal, not a pill:
  - a 1px `line` hairline border with a 2px radius and tight padding;
  - `--font-body` at 0.82rem.
- Planet chip: the planet glyph in `venus`, then the translated planet name
  in `textDim` ("♀ Venus" / "♀ 金星").
- Aspect chip: glyph A, the aspect glyph in that aspect's `aspect[type]`
  token colour, glyph B, then the names ("♀ ☍ ♇ Venus–Pluto"). Its
  `aria-label` is the full phrase ("Venus opposition Pluto" / "金星冲冥王星").
  The Ascendant uses its glyph and the `bodies.Ascendant` name.
- The row is a list (`ul`, `aria-label` = the eyebrow). Chips are not
  buttons, have no hover affordance and are not focusable; dw-4 makes them
  interactive.
- Motion: when `done` lands, the chips fade up 4px in sequence, 60ms apart.
  Under `prefers-reduced-motion` they appear at once.
- No new colour tokens: `line`, `venus`, `textDim`, `textFaint` and `aspect`
  exist. i18n adds `chat.refsLabel` and `chat.aspects` (the five aspect
  names) in en and zh, with parity.

**Local runs** (as in dw-2)
- Backend:
  `CORS_ALLOW_ORIGINS=http://localhost:5173 ANALYSIS_LLM=claude-cli conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001`.
- Web: `VITE_API_BASE=http://localhost:8001 npm run web`.
- Port :8000 belongs to another checkout. The fixture birth used below is
  1990-06-15 08:30, Beijing (Asia/Shanghai). Its chart has Venus in
  Taurus in house 10, Moon in Pisces in house 8, Mars in Aries in house 9,
  Venus opposition Pluto, and Cancer rising.

## Architecture

Cites the epic's Reuse map, Target modules, Turn event grammar and
Dependency rules. Only dw-3's delta is written here.

### Reuse (verified 2026-09-28)

| Need | Existing | Use |
|---|---|---|
| Chart plus structure from birth kwargs | `chart/natal/report.py:12` `natal_report` (exported by `app.chart.natal`) | As is: one call per grounded turn. |
| Birth-data validation | `models.py:43` `BirthData` (with its validators) | As the type of the new request field. |
| Request to kwargs mapping | `main.py:143` `_person` | main.py passes `_person(request.birthData)` to the turn, so the mapping keeps one home. |
| Glossary | `dictionary/natal.py:146` `relevant_meanings` (via `app.dictionary`) | As is. |
| Prompt restatement | `interpretation/prompt.py:46` `_restate` (byte-frozen, pinned by `tests/test_synastry_prompt.py`; the module imports only `..chart.natal`) | Borrowed. This is the epic's one allowed exception (see below). |
| Side read | `divination/turn.py:157` `_side_read`, `render.py:46` `MOOD_SCHEMA`, `:90` `side_prompt`; `llm.generate_sections` `llm.py:857` (checks required keys only, so a per-turn schema works) | Widened to `{mood, chartRefs}`. |
| System prompt | `render.py:54` `system_prompt`, `:63` `turn_messages` | Gains the chart argument. |
| Turn generator | `turn.py:177` `turn_events(request)`, route `main.py:420` | Gains the `person` argument. |
| Client turn | core `divination/turn.ts` `streamTurn` (`done` mapping at :64), `types.ts` `TurnEvent`/`TranscriptEntry` | Extended. |
| Aspect identity | core `chart-view/aspect-set.ts:17` `aspectKey` = `${bodyA}\|${type}\|${bodyB}` | The contract the refs satisfy; not redefined. |
| Glyphs | core `chart-view` `PLANET_GLYPHS`, `ASPECT_GLYPHS`, `ASCENDANT_GLYPH` | Chip glyphs. |
| Saved birth data | core `birth-data` `getBirthData` (web reads it in `birth-input/useBirthData.ts`) | Read in `useChat` at send time. |
| Chip colours | web `theme/tokens.ts` `line`, `venus`, `textDim`, `textFaint`, `aspect` | No new token. |

### Borrow vs move vs duplicate (the restate helper)

`_restate` is borrowed through a single pinned import in
`divination/render.py`: `from app.interpretation.prompt import _restate`.

- **Why not move it?** Its home and its byte-freeze are deliberate (see the
  `interpretation/prompt.py` docstring). Moving it would edit interpretation
  and the synastry and natal render modules, which is out of this feature's
  scope.
- **Why not duplicate it?** Two prompt restatements would drift. That breaks
  one-home-per-fact, and Venus would see a different chart view from the
  natal reading's.
- **Why the borrow is safe.** `interpretation/prompt.py` imports only
  `..chart.natal`, and `app/interpretation/__init__.py` is empty. So the
  borrow pulls in no store, job or LLM code. A test pins this so it cannot
  change silently.

### Module map (changed only)

```
server/app/
├── models.py                  DivinationTurnRequest + birthData: BirthData | None = None
├── main.py                    divination_turn_stream passes person=_person(birthData) or None
├── divination/
│   ├── personas/venus.txt     "not read your chart" paragraph removed
│   ├── render.py              + chart.none / chart.read / chart.marker / side.refs fragments,
│   │                            natal_context(), ref_catalogue(), side_schema(); system_prompt,
│   │                            turn_messages, side_prompt take the context
│   └── turn.py                turn_events(request, person); side read returns (mood, refs)
server/tests/  test_divination_turn.py (+grounding), test_boundaries.py (borrow pin)
packages/core/src/divination/  types.ts (ChartRef, done.chartRefs, TurnRequest.birthData,
                               TranscriptEntry.chartRefs), turn.ts (isChartRef filter),
                               transcript.ts (sanitize keeps chartRefs), index.ts
web-divination/src/
├── chat/useChat.ts            sends getBirthData(); stores refs on the persona entry
├── chat/ChatPanel.tsx         + chips row (small ChartRefChips component)
├── chat/chat.css              chip styles
└── i18n/{en,zh}.ts            chat.refsLabel, chat.aspects
```

### Module contracts

**`divination/render.py`** (pure, no I/O)
- `natal_context(person: dict) -> NatalContext | None` computes
  `r = natal_report(person)`, a dict `{"chart", "structure"}`, and returns:
  - `chart`, which is `r["chart"]`;
  - `restated`, which is `_restate(r["chart"], r["structure"])`;
  - `meanings`, which is `relevant_meanings(r["chart"], r["structure"])`;
  - `catalogue`, an ordered `{id: label}`.
- Ids are `planet:<Body>` for the ten `chart["planets"]` bodies, and
  `aspect:<bodyA>|<type>|<bodyB>` for each `chart["aspects"]` entry whose
  two ends are in the ten bodies or `Ascendant`. The aspect id keeps the
  chart's own a/b order.
- `system_prompt(persona, lang, ctx)` is built in this order:
  1. the persona;
  2. `chart.read` plus the marker, then the JSON of `{chart: restated,
     meanings}` (`sort_keys`, `ensure_ascii=False`), or `chart.none` when
     `ctx` is None;
  3. the lang line.
- `side_prompt(message, reply, lang, catalogue)`. With a catalogue, the
  user JSON gains `catalogue` and the system text appends `side.refs`.
- `side_schema(catalogue)` returns `MOOD_SCHEMA` when the catalogue is
  empty. Otherwise it returns `{mood: enum, chartRefs: array of enum(ids)}`,
  with both keys required.
- `to_wire_refs(ids, catalogue) -> list[dict]` does the dropping, deduping
  and capping at 6. It maps ids to wire objects and is the only place a ref
  is shaped.

**`divination/turn.py`**
- `turn_events(request, person: dict | None) -> Iterator[bytes]`.
  - The context is built at the top of the generator, before the worker is
    submitted. A failure there emits `error{unavailable}` and logs; no text
    has been sent.
  - The side read yields `(mood, refs)`. Any failure or deadline overrun
    gives `(None, [])`.
  - `done` is sent as `{"mood": …, "chartRefs": [...]}`, always with both
    keys.
- The deadline, keepalives, cancel flag and executor are unchanged.

**`main.py`** keeps a single `turn_events(` call, now with the second
argument. Its docstring changes from "birth-data-free" to "birth data rides
each turn; nothing kept".

**core `divination`**
- `ChartRef` is `{kind:'planet'; body: Body}` or `{kind:'aspect'; bodyA:
  AspectPoint; type: AspectType; bodyB: AspectPoint}`. It uses type-only
  imports from `../chart`.
- `TurnRequest.birthData: BirthData | null`, with a type-only import from
  `../birth-data`.
- `TurnEvent` `done` becomes `{type:'done'; mood; chartRefs: ChartRef[]}`.
- `TranscriptEntry.chartRefs?: ChartRef[]`.
- `isChartRef(v)` lives in `divination/types.ts` and is exported from the
  barrel. It checks the members of `BODIES`, the five aspect types and
  `Ascendant`. `BODIES` is a value import from the `../chart` barrel (it is
  exported there), not a type-only import. `streamTurn` filters with it. There is no
  chart lookup and no arithmetic.
- `transcript.ts` `sanitize` (the KV read path) keeps `chartRefs` on an
  entry only when it is an array that is still non-empty after filtering
  through `isChartRef`. Otherwise it omits the key. Without this, stored
  refs would be lost on reload.

**web `chat/`**
- `useChat` reads `getBirthData()` when `run` starts and puts it in the
  request.
- On `done` it appends `{role:'persona', text, mood, chartRefs?}`.
- The chips component takes `ChartRef[]` plus the dictionary and renders
  glyphs and names. It does not look up the chart.

### Wire delta (dw-2's Wire stands; only these change)

Request adds `"birthData": {date, time, location:{name, latitude,
longitude}, timezone, schemaVersion, houseSystem?} | null`. It is optional,
and when absent it means `null`.

`done` becomes:

```
{"mood": Mood|null,
 "chartRefs": [ {"kind":"planet","body":"Venus"},
                {"kind":"aspect","bodyA":"Venus","type":"opposition","bodyB":"Pluto"} ]}
```

- `chartRefs` is always present, holds 0–6 items and has no duplicates.
- Every item exists in the chart computed from the request's `birthData`.
- dw-4 mapping, with no parsing:
  - planet → `[data-planet="<body>"]`;
  - aspect → find the `chart.aspects` entry with equal `bodyA/type/bodyB`,
    then `aspectKey(it)` → `[data-aspect-key]`.
  - `planetFamily(chart.aspects, body)` stays available for family glow.
  The chart the web shows is `POST /api/chart` of the same birth data, so
  the aspect order is identical.

### Dependency rules and forbidden edges

- `divination` may now use `app.chart.natal` (`natal_report`) and
  `app.dictionary` (`relevant_meanings`). Both are already allowed.
- ❌ `divination` still may not import interpretation. The ONE exception is
  the exact line `from app.interpretation.prompt import _restate`, in
  `divination/render.py` only.
  - This is pinned by
    `test_divination_borrows_only_the_restate_helper`. It strips that exact
    line from render.py, then requires the fence to find nothing in any
    divination file. It asserts the line occurs exactly once across
    divination.
  - A self-check shows that `from app.interpretation.prompt import
    _LANG_INSTRUCTIONS`, and the same `_restate` import in `turn.py`, are
    both caught.
  - It also asserts that `interpretation/prompt.py`'s only app import is
    `..chart.natal`, and that `interpretation/__init__.py` has no imports.
    That keeps the borrow shallow.
- ❌ interpretation, cards and every other tier still never import divination
  (existing `test_no_tier_imports_divination`).
- ❌ Refs are never derived from reply text. `turn.py` builds `chartRefs`
  only from the side-read result through `render.to_wire_refs`, which a
  unit test pins.
- ❌ No state: `test_divination_keeps_no_state` is unchanged and still
  passes. Nothing caches the natal context between turns.
- Web: chat imports core only through the barrels (`/divination`,
  `/birth-data`, `/chart-view`). No network outside `platform/`, no
  arithmetic, and colours only via the token CSS variables. These are the
  existing guards, unchanged.

### Amendments (same commit as the code)

- **CLAUDE.md rule 10**, divination paragraph: "…never interpretation (ONE
  pinned exception, dw-3: `divination/render.py` borrows
  `interpretation.prompt._restate`, the shared byte-frozen chart
  restatement, so Venus reads the chart exactly as the natal reading does;
  pinned by `test_divination_borrows_only_the_restate_helper`), cards,
  ask…". Also add: "birth data rides each turn and the chart is recomputed
  per turn, never stored."
- **`test_boundaries.py`**:
  - `test_divination_imports_only_llm_prompts_chart_dictionary` is RETIRED:
    as written, the borrow line would turn it red.
  - It is folded into `test_divination_borrows_only_the_restate_helper`,
    which runs the same `DIVINATION_FORBIDDEN_RE` check over every
    divination file. The only thing stripped first is the one exact borrow
    line in render.py, and that line must appear exactly once.
  - The new test keeps all six existing self-checks: interpretation,
    `from .. import jobs` and cards are caught; llm, prompts and chart pass.
  - It also adds the borrow self-checks and the shallow-import asserts above.
  - `DIVINATION_FORBIDDEN_RE` is NOT widened.
- **Epic file**: nothing now. docs-sync records the `done` shape and the
  borrow.

## Acceptance Criteria

Server tests use fake providers only: a monkeypatched `llm.stream_turn` and
`llm.generate_sections`. The chart is REAL, computed by Swiss Ephemeris from
the fixture birth (1990-06-15 08:30 Beijing, 39.9042 / 116.4074,
Asia/Shanghai, placidus). Run `npm run server:test`, `npm test` and
`npm run typecheck`.

**Server**
- **S1 (grounded prompt)**: A turn with the fixture `birthData` hands the
  fake `stream_turn` a system prompt containing, in order: the `venus.txt`
  text, the `chart.read` fragment, the marker, the chart JSON and the lang
  line. The JSON after the marker parses. With `r = natal_report(person)`
  for the fixture (a dict `{"chart","structure"}`), its `chart` equals
  `_restate(r["chart"], r["structure"])` and includes
  `{"body":"Venus","sign":"Taurus","house":10,…}` and the aspect
  `{"a":"Venus","b":"Pluto","type":"opposition",…}`. Its `meanings` equals
  `relevant_meanings(r["chart"], r["structure"])`. The prompt does not
  contain the `chart.none` text.
- **S2 (no chart)**: A turn with `birthData` absent, and one with it
  `null`, send a system prompt with `chart.none` and no marker. The side
  read gets `MOOD_SCHEMA`. `done` is `{"mood":…, "chartRefs":[]}`.
- **S3 (refs validated)**: With the fixture birth, the fake side read
  returns `{"mood":"candid","chartRefs":["planet:Venus",
  "aspect:Venus|opposition|Pluto","planet:Venus","planet:Chiron",
  "aspect:Venus|square|Mars","aspect:Jupiter|conjunction|Chiron","house:7"]}`.
  `done` is then exactly `{"mood":"candid","chartRefs":[{"kind":"planet",
  "body":"Venus"},{"kind":"aspect","bodyA":"Venus","type":"opposition",
  "bodyB":"Pluto"}]}`. The test first asserts that the fixture chart has
  no Venus–Mars square (in either order), so `aspect:Venus|square|Mars` is
  a genuinely unknown id.
- **S4 (cap)**: Eight distinct valid ids give the first 6, in order.
- **S5 (side read gets the catalogue)**: With the fixture, the fake
  `generate_sections` receives:
  - a schema whose `chartRefs.items.enum` equals the catalogue ids;
  - the ten `planet:` ids, and every chart aspect whose ends are planets or
    `Ascendant`;
  - no id naming Chiron, NorthNode or Midheaven;
  - a user JSON holding `question`, `reply` and a `catalogue`.
- **S6 (degradation)**: A side read that raises `AnalysisUnavailable`, and
  one that runs past `DIVINATION_TURN_TIMEOUT_S`, each give exactly
  `done {"mood":null,"chartRefs":[]}` with the deltas unchanged. A side read
  returning `{"mood":"tender","chartRefs":"planet:Venus"}` (a non-list)
  gives `done {"mood":"tender","chartRefs":[]}`.
- **S7 (validation)**: `birthData` with `date:"1990-13-40"`, with
  `timezone:"Mars/Base"`, or with a missing `location` each answer 422, and
  the fakes are never called.
- **S8 (time unknown)**: The fixture with `time:null` gives a prompt whose
  chart JSON has `"time_unknown": true`, every placement `house` null and
  `rising_sign` null. The catalogue has no `Ascendant` aspect.
- **S9 (every ref is real)**: For S3's `done`, every planet ref's body is in
  `POST /api/chart`'s `planets` for the same birth (TestClient). Every
  aspect ref matches exactly one `aspects` entry with the same
  `bodyA`/`type`/`bodyB`.
- **S10 (boundaries)**: `test_boundaries.py` passes with
  `test_divination_borrows_only_the_restate_helper`.
  - `test_divination_imports_only_llm_prompts_chart_dictionary` no longer
    exists (grep finds no definition): it is retired into the new test.
  - The new test keeps the six old self-checks: interpretation,
    `from .. import jobs` and cards are caught; llm, prompts and chart pass.
  - `DIVINATION_FORBIDDEN_RE` is byte-identical to dw-2's.
  - Its borrow self-checks catch
  a second interpretation import (`from app.interpretation.prompt import
  _LANG_INSTRUCTIONS` in render.py) and the `_restate` import placed in
  `turn.py`. Planting either one really turns the test red.
  `test_divination_keeps_no_state`, `test_no_tier_imports_divination` and
  `test_main_names_the_synchronous_exceptions` still pass.
- **S11**: `divination.render.FINGERPRINT` differs from dw-2's value
  (`chart.read`/`chart.none`/`side.refs` are registered), and a test pins
  that `venus.txt` no longer contains "have not read".

**Core and guards**
- **C1**: `streamTurn` with a fake `StreamPost`:
  - `done {"mood":"tender","chartRefs":[planet Venus, aspect
    Venus|opposition|Pluto]}` gives a `done` event with both refs;
  - a `done` with no `chartRefs` gives `chartRefs: []`;
  - items `{kind:"house",…}`, `{kind:"planet",body:"Chiron"}` and
    `{kind:"aspect",type:"quincunx",…}` are dropped;
  - the request body carries the `birthData` it was given (or `null`).
- **C2**: The transcript store round-trips a persona entry with
  `chartRefs`, surviving a fresh read from KV. A stored entry whose
  `chartRefs` is `[{kind:"house"}]` or `"x"` reads back with no `chartRefs`
  key. `toWire` output has no `chartRefs` key.
- **C3**: Existing guards stay green (barrels only, no network outside
  `web-divination/src/platform`, no arithmetic, colours only in tokens,
  en/zh parity including `chat.refsLabel` and `chat.aspects`). Root
  `npm test` and `npm run typecheck` pass.

**Web (vitest, fake StreamPost)**
- **W1**: With birth data saved in the KV store, sending a message makes
  the fake receive a body whose `birthData` deep-equals the saved record.
  With none saved it receives `birthData: null`.
- **W2**: After `done` with `[planet Venus, aspect Venus|opposition|Pluto]`,
  the finished reply shows, below its prose, a list labelled with
  `chat.refsLabel`:
  - two items in order;
  - the first shows `♀` and "Venus";
  - the second has `aria-label` "Venus opposition Pluto" and contains `♀`,
    `☍` and `♇`.
  In zh the first chip shows the zh dictionary's `bodies.Venus` (金星) and
  the second's `aria-label` is built from the zh `bodies` and
  `chat.aspects` strings (金星冲冥王星).
- **W3**: `done` with `chartRefs: []` renders no list. A stopped reply
  renders no list. A remount with a KV transcript whose persona entry has
  `chartRefs` renders the same chips. An entry without the field renders
  none.
- **W4**: The chips are not buttons and are not in the tab order (no
  `button` and no `tabindex` inside the list).

**Real app** (backend on :8001 with `ANALYSIS_LLM=claude-cli` and CORS for
:5173; `VITE_API_BASE=http://localhost:8001 npm run web`; fixture birth
entered in the form)
- **A1**: The network panel shows the `POST /api/divination/turn` request
  body with a `birthData` equal to the entered birth (same date, time,
  timezone and coordinates as the `/api/chart` request).
- **A2**: Asking "Why do I keep falling for people who are hard to reach?"
  streams a reply (as dw-2 A2) that names at least one of the user's
  placements.
  - Every sign, house or aspect the reply gives for a named planet matches
    the Placements panel and the wheel for that chart. The checker lists
    each claim beside the chart value.
  - The reply says why at least one named placement bears on the question.
  - It invents no placement.
- **A3**: Chips appear under that reply once it finishes, not while it
  streams.
  - Each planet chip's body names an element for which
    `document.querySelector('[data-planet="<body>"]')` is non-null.
  - Each aspect chip matches a `[data-aspect-key="<bodyA>|<type>|<bodyB>"]`
    element.
  - At least one chip names a placement the reply text names.
  - The chip border's computed colour equals the `line` token.
- **A4**: Reload shows the same reply with the same chips.
- **A5**: With the language set to 中, a new question gets a Chinese reply
  citing a real placement, with chips labelled in Chinese.
- **A6**: Clearing the birth data (or a fresh profile with none) and asking
  "What does my Venus sign say about me?" gives a reply saying she has not
  read the chart, naming no sign, and no chips. The request body has
  `birthData: null`.
- **A7**: Entering the fixture with time unknown and asking about
  partnership gives a reply that names no house and no rising sign.
