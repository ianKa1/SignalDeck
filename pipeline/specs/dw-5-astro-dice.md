# Feature Specification: dw-5-astro-dice

DIVINATION WEB EPIC, entry 5 of 6. Epic architecture:
`pipeline/epics/divination-web.md` (cited, not restated; its Turn event grammar
already reserves `dice` {planet, sign, house}, sent first). The turn wire it
extends is dw-3's (`pipeline/specs/dw-3-chart-grounded-reply.md`, Wire delta).

## Goal

Implement QUEUE.md `dw-5-astro-dice`: the user asks a question and presses Cast. The server rolls planet · sign · house
(`divination/dice.py`), sends a `dice` event before any text, and Venus interprets the three dice against the question
AND the user's chart. The web shows a rolling dice card inline in her letter while the interpretation types out.

## Non-goals

- No new route, no new store, no server state. A cast is a turn with
  `action:"cast"` on `POST /api/divination/turn`. The roll exists in the
  response stream and on the client, nowhere else on the server: no table, no
  log line with the faces, no cache (rules 6, 9 and 12; identity-free).
- The client never rolls, re-rolls, or chooses faces. It has no dice
  randomness at all (no `Math.random` in `web-divination/src`).
- No new persona, no dice for a persona other than Venus, and no second or
  bonus die. Exactly three dice: planet, sign, house.
- No nodes, Sun/Moon-only dice, or "wild" faces. The planet die has the ten
  faces of the dictionary's `PLANETS`.
- No change to `delta`, `done` or `error` shapes, and no side-read change
  for a chat turn whose transcript carries no dice. The dice are not chart
  refs and never light the wheel: every side read with dice in view is told
  so (Decided defaults).
- No wheel change (dw-4), no session log, summary or history (dw-6), no
  native (app-native) change, no deploy work.
- No keyboard shortcut for Cast. No cast with an empty composer.
- No paid key in any automated test.

## Decided defaults

**What a cast is**
- The request gains `action: "chat" | "cast"`. Absent means `"chat"`, so a
  dw-3 client is unchanged. Any other value is a 422.
- A cast needs a question: `message` keeps its dw-2 rules (1–2,000 chars
  after trimming). The web's Cast button is disabled while the composer is
  empty, exactly like Send.
- The server rolls once per cast request, only after the request validated
  (a 422 never rolls). A chat turn never rolls.

**The dice**
- Planet: one of the ten `PLANETS` keys. Sign: one of the twelve `SIGNS`
  keys. House: an integer 1–12 (`HOUSES` keys). Each die is uniform and
  independent. The source is `random.SystemRandom` (OS entropy). It is never
  seeded, in production or in tests. Tests replace the generator object
  instead (see Architecture).
- The `dice` event is the FIRST frame of a cast stream: before any keepalive,
  delta, done or error. It is sent exactly once per cast. A chat turn never
  sends it.
- If the turn later fails (timeout, unavailable, a natal-context failure),
  the stream is still `dice`, then `error`. The roll was shown and is simply
  not interpreted.

**How Venus reads them**
- A new persona asset, the dice brief (`personas/venus-dice.txt`), is
  registered on the `divination` topic, so `FINGERPRINT` moves. With it, a
  `dice.marker` line and the dice JSON go into the system prompt of a cast,
  after the chart section and before the language line.
- The dice JSON carries each face with its dictionary meaning, and with birth
  data an `inYourChart` block of plain lookups:
  - where the rolled planet sits in the natal chart (sign, and house if known);
  - which of the ten natal planets are in the rolled sign;
  - which are in the rolled house. This is `null` when the birth time is
    unknown.
- The brief tells Venus to:
  - read the three dice as one sentence: the planet is WHAT is moving, the
    sign HOW, the house WHERE in life;
  - answer the question with them, not recite dictionary meanings;
  - tie the reading to the chart through at least one `inYourChart` link
    when birth data exists (for example "the dice gave Pluto, and your own
    Pluto sits opposite your Venus"), stating only facts that are in the
    data;
  - name all three faces once, plainly, early in the reply;
  - never invent a different roll and never offer to roll again;
  - keep the dw-2 voice and length rules (60–180 words, 1–3 paragraphs, no
    markdown).
- Without birth data the dice are read against the question alone. The
  `chart.none` rule still holds, so Venus names no natal placement.
- **Dice are not refs.** Whenever dice are in view (a cast, OR any turn
  whose transcript carries a persona entry with `dice`), the side read's
  system text also gets a registered `side.dice` fragment. It says dice
  faces are not the person's placements, so a planet or aspect is cited
  only where the reply speaks of the person's OWN placement ("your Pluto
  opposite your Venus"), never for "the Pluto die". A dice-free turn's
  side read is unchanged. `side.dice` joins the fingerprint.
- The rolled house is a die face, not a natal house. With time unknown the
  brief still lets Venus speak of the rolled house's area of life, but she
  names no natal house (dw-3's rule).

**Dice on later turns**
- The finished persona entry of a cast stores its `dice` in the KV transcript.
  The user entry that asked it stores `cast: true` (device-only, used by
  Retry and by the user line's mark).
- The dice ARE re-sent: a persona wire entry may carry `dice`. So a follow-up
  such as "what did the Pluto die mean for me?" is answered with the roll in
  view. The server re-validates them (422 on an unknown face, or on `dice`
  on a user entry) and folds each into the conversation as a short
  `dice.recall` note on the user message that asked for the cast. It never
  re-rolls from them. The note is English in zh conversations too: it is
  model-facing only, like the chart marker, and is never shown.
- A stopped cast reply that has text keeps its dice. A cast stopped before
  its first delta stores nothing, so its card disappears (dw-2's stop rule).
  A failed cast stores nothing new. Retry of a cast user entry casts again (a fresh roll), because
  the failed roll was never interpreted.

**Look: the cast button**
- It sits in the composer's action row, left of Send. It is an outlined quiet
  button: a small pentagon mark (inline SVG, `aria-hidden`), then "Cast the
  dice" / "掷星骰". Border and text are `--venus`, the hover/focus background
  is `--venus-ghost`, and `:focus-visible` has a 1px `--voice` outline.
- It is disabled (opacity 0.4, no hover) when the composer is empty or a turn
  is pending; Stop replaces Send, never Cast.

**Look: the dice card** (candlelit observatory: three brass dodecahedron faces
laid on the letter)
- It sits inside Venus's letter, under her ♀ eyebrow and above the prose. A
  small-caps eyebrow in `textFaint` reads "the dice fall" / "星骰落定". Then
  come three dice in a row with 14px gaps.
- Each die is a 52px regular pentagon (an SVG polygon, the face of a d12):
  a 1px `--line` stroke, a `--panel` fill, and an inner hairline pentagon in
  `--line-soft`. The face shows:
  - the planet glyph in `--venus`;
  - the sign glyph in `--voice`;
  - the house as an Arabic numeral in `--text`, in `--font-body`.
  Glyphs come from core `chart-view`'s `PLANET_GLYPHS` and `SIGN_GLYPHS`.
- Under each die is its name in `textDim` at 0.78rem: "Pluto", "Scorpio",
  "8th house" / "冥王星", "天蝎座", "第八宫".
- The card is a `figure` whose `aria-label` names all three faces ("The
  dice: Pluto, Scorpio, 8th house" / "星骰：冥王星、天蝎座、第八宫"). The
  individual glyphs are `aria-hidden`.
- **Roll** (only on the live cast, while the reply is pending):
  - each die tumbles (a rotate and a 3px bounce) while its face steps through
    its table's glyphs in fixed table order every 70ms. The stepping is
    deterministic theatre, not a draw;
  - the dice settle on the real faces left to right, at 700ms, 900ms and
    1,100ms after the `dice` event;
  - each settle ends with one brief glow, `drop-shadow` in `--venus-ghost`;
  - the prose streams under the card meanwhile.
  Stored entries (reload, earlier casts) render settled and never roll.
  Under `prefers-reduced-motion: reduce` the card renders settled at once.
- The user line of a cast shows a small `textFaint` mark after the text:
  "· cast" / "· 掷骰".
- No new colour token. `venus`, `venusGhost`, `voice`, `line`, `lineSoft`,
  `panel`, `text`, `textDim` and `textFaint` exist. i18n adds `chat.cast`,
  `chat.diceLabel`, `chat.diceAria`, `chat.castMark` and `chat.houses`
  (keys "1"…"12", values the ordinal captions "1st house"…"12th house" /
  "第一宫"…"第十二宫") in en and zh, with parity.

**Local runs** (wave worker #2; port-agnostic criteria)
- Backend: `CORS_ALLOW_ORIGINS=<the Vite origin> ANALYSIS_LLM=claude-cli conda
  run --no-capture-output -n astrology uvicorn app.main:app --app-dir server
  --env-file .env --port <free port, not 8000>` (the wave worker uses 8002).
- Web: `VITE_API_BASE=http://localhost:<that port> npm run web -- --port <free
  port>` (the wave worker uses 5175).
- Fixture birth: dw-3's (1990-06-15 08:30, Beijing; Moon in house 8,
  Venus opposition Pluto).

## Architecture

Cites the epic's Built so far (dw-2/dw-3 hooks), Reuse map, Turn event grammar
and Dependency rules. Only dw-5's delta is written here.

### Reuse (verified 2026-09-28)

| Need | Existing | Use |
|---|---|---|
| Dice faces and meanings | `dictionary/symbols.py:14` `PLANETS`, `:27` `SIGNS`, `:42` `HOUSES` (via the `app.dictionary` barrel) | The ONLY face tables: dice.py rolls over their keys, the prompt quotes their values, models.py validates against their keys. |
| Prompt registry | `divination/render.py:36` `PROMPTS`, `:95` `FINGERPRINT` (reading it freezes the registry, `prompts.py:118`) | The dice fragments are registered in render.py BEFORE `FINGERPRINT`, never in dice.py. |
| Per-turn chart | `render.py:144` `natal_context` → `NatalContext.chart` | `inYourChart` lookups read `ctx.chart["planets"]`. There is no second chart computation. |
| System prompt | `render.py:159` `system_prompt`, `:189` `turn_messages` | Gain an optional dice argument and the recall fold. |
| Turn generator | `turn.py:185` `turn_events(request, person)`, `:112` `frame` | Rolls and yields `dice` first. |
| Request model | `models.py:332` `DivinationTranscriptEntry`, `:339` `DivinationTurnRequest` | Gain `dice` and `action`. |
| Client turn | core `divination/turn.ts:30` `streamTurn` (the unknown-event branch at :57–75), `types.ts:53` `TurnEvent`, `transcript.ts:24` `sanitize`, `:94` `toWire` | Extended. |
| Glyphs | core `chart-view/glyphs.ts:11` `SIGN_GLYPHS`, `:17` `PLANET_GLYPHS` | Dice faces. |
| Chat state | `chat/useChat.ts:56` `run`, `:100` `send`, `:112` `retry` | Carry the action and the dice. |

### Module map (created / changed only)

```
server/app/
├── divination/
│   ├── dice.py                  NEW  Roll, roll(), faces(), chart_links(), to_wire()
│   ├── personas/venus-dice.txt  NEW  the dice brief (asset "dice.venus")
│   ├── render.py                + dice.venus / dice.marker / dice.recall fragments;
│   │                              system_prompt(…, cast), turn_messages folds recalls
│   ├── turn.py                  cast → roll → `dice` frame first
│   └── __init__.py              docstring names dice
├── models.py                    DivinationDice; entry.dice; request.action
server/tests/
├── test_divination_dice.py      NEW  roll, randomness pin, links, wire, cast turns
└── test_divination_render.py / test_divination_turn.py   extended (fingerprint, recall)
packages/core/src/divination/    types.ts (Dice, isDice, TurnAction, dice event,
                                 entry.dice / cast, WireEntry.dice), turn.ts,
                                 transcript.ts, index.ts
packages/core/src/chart/index.ts + value export SIGNS (beside BODIES)
web-divination/src/
├── chat/DiceCard.tsx            NEW  the card + roll animation
├── chat/DiceCard.test.tsx       NEW
├── chat/useChat.ts              send(message, action); pending.dice; stores dice / cast
├── chat/ChatPanel.tsx           Cast button; DiceCard in Entry and pending; cast mark
├── chat/chat.css                cast button, dice card, keyframes, reduced motion
├── chat/core-divination.test.ts / ChatPanel.test.tsx   extended
└── i18n/{en,zh}.ts              chat.cast, diceLabel, diceAria, castMark, houses
```

**Shared-file footprint with the wave.** Untouched: `App.tsx`,
`theme/tokens.ts`, `main.py`, `test_boundaries.py`, `llm.py`, and every
`chart/` file. Touched and shared:
- with dw-4: `chat/useChat.ts` (`send`/`retry`/`run` signatures and event
  branch; dw-4 adds two lines inside `run`); `chat/ChatPanel.tsx` (the
  composer actions, the pending blocks, and the `Entry` body above
  `ChartRefChips`; dw-4 edits `ChartRefChips` and its call site);
  `chat/chat.css` (appended block); `ChatPanel.test.tsx` (appended
  `describe`).
- with dw-6 (likely): `models.py`, `divination/render.py` (appended
  fragments), `divination/__init__.py`, core `divination/types.ts` and
  `index.ts`, `i18n/{en,zh}.ts` (keys appended inside `chat`), possibly
  `chat/useChat.ts`, and `CLAUDE.md` rule 10 (one sentence).
- no wave conflict expected: `packages/core/src/chart/index.ts` (one
  export line).


### Module contracts

**`divination/dice.py`** (pure, except for the OS entropy read; imports
`random`, `dataclasses` and `app.dictionary` only)
- `_RNG = random.SystemRandom()`: the module's ONE generator. `roll()`
  reads it at call time (`_RNG.choice(...)`), so a test may replace the
  attribute.
- `Roll(planet: str, sign: str, house: int)`, a frozen dataclass.
- `roll() -> Roll`: three independent `_RNG.choice` calls over
  `tuple(PLANETS)`, `tuple(SIGNS)` and `tuple(HOUSES)`.
- `faces(r) -> dict` returns `{"planet": {"name", "means"}, "sign": {"name",
  "means"}, "house": {"number", "means"}}`, the dictionary rows verbatim.
- `chart_links(r, chart) -> dict` returns `{"planet": {"sign", "house"} |
  None, "inSign": [bodies], "inHouse": [bodies] | None}`. It uses the ten
  `PLANETS` bodies of `chart["planets"]` in chart order. `inHouse` is None
  when the chart's houses are null (time unknown). This is equality lookup
  only, with no arithmetic.
- `to_wire(r) -> {"planet", "sign", "house"}`, the ONE place the `dice`
  event is shaped.
- It does NOT: seed, log faces, store, import llm/prompts, or build prose.

**`divination/render.py`**
- `PROMPTS.asset("dice.venus", personas/venus-dice.txt)`, then
  `dice.marker` ("THE DICE (JSON):"), `side.dice` (the not-refs rule) and
  `dice.recall` (a model-only English template with
  `{planet}`, `{sign}` and `{house}`, for example "(I asked you to cast the
  Astro Dice for this. They showed {planet} · {sign} · house {house}.)").
  All four are registered before `FINGERPRINT`.
- `side_prompt(message, reply, lang, catalogue, dice_in_view=False)`: with
  `dice_in_view` and a non-empty catalogue it appends `side.dice` after
  `side.refs`. With `dice_in_view` false its output is byte-identical to
  dw-3's.
- `system_prompt(persona, lang, ctx=None, cast: Roll | None = None)`, in
  this order: persona; the chart section (dw-3); when `cast` is set,
  `dice.<persona>` + marker + JSON of `{**faces(cast), "inYourChart":
  chart_links(cast, ctx.chart)}` (the key is omitted when ctx is None;
  `sort_keys`, `ensure_ascii=False`); the lang line.
- `turn_messages(persona, transcript, message, lang, ctx=None, cast=None)`.
  A persona transcript entry with `dice` appends the formatted
  `dice.recall` line (blank-line joined) to the user message just before
  it, after the existing merge rules. A leading dropped persona entry drops
  its recall too.

**`divination/turn.py`** `turn_events(request, person)`. When
`request.action == "cast"`, the FIRST statement pair is `cast = dice.roll()`
then `yield frame("dice", dice.to_wire(cast))`. Both come before the
deadline wait, the context build and the worker. After that `cast` is
passed to `turn_messages`. The side read gets `dice_in_view = cast is not
None or any(e.dice for e in request.transcript)`. Everything else
(deadline, keepalives, `done`) is unchanged. The `transcript` mapping passes
`dice` through as a dict when present.

**`models.py`**
- `DivinationDice(planet: str, sign: str, house: StrictInt)` (so `"8"` is a
  422, agreeing with the client's `isDice`), validated against
  `PLANETS`/`SIGNS`/`HOUSES` keys imported from `.dictionary` (Tier B has no
  imports, so the edge is safe).
- `DivinationTranscriptEntry.dice: DivinationDice | None = None`. A model
  validator rejects `dice` on a `user` entry.
- `DivinationTurnRequest.action: Literal["chat", "cast"] = "chat"`.

**core `divination`**
- `Dice = { planet: Body; sign: ZodiacSign; house: number }` (type-only
  imports).
- `isDice(v)`: the body is in `BODIES`; the sign is in chart's `SIGNS`
  (`chart/types.ts:17`, today NOT on the barrel: dw-5 adds it as a value
  export beside `BODIES`, which types.ts already value-imports); the house
  is an integer 1–12.
- `TurnAction = 'chat' | 'cast'`; `TurnRequest.action: TurnAction`.
- `TurnEvent` adds `{ type: 'dice'; dice: Dice }`.
- `TranscriptEntry` adds `dice?: Dice` (persona) and `cast?: true` (user).
  `WireEntry` adds `dice?: Dice`.
- `streamTurn`: a `dice` frame whose data passes `isDice` yields the event
  only if no delta has been yielded yet and no dice event was yielded
  before. Otherwise it is ignored.
- `sanitize` keeps `dice` on persona entries (via `isDice`) and `cast` on
  user entries (`=== true`).
- `toWire` emits `{role, text, dice}` for a persona entry that has dice and
  `{role, text}` otherwise. `cast`, `mood`, `chartRefs` and `stopped` never
  go on the wire.

**web `chat/`**
- `useChat.send(message, action = 'chat')`. On a cast the user entry is
  `{role:'user', text, cast:true}`. `run(message, before, action)` sets
  `pending.dice` on the `dice` event. The finished or stopped persona entry
  carries `dice`. `retry` re-sends `action:'cast'` when the last user entry
  has `cast`.
- `Pending` gains `dice?: Dice`, which also shows while `awaiting` (the
  card rolls above the listening line). `Failure` gains `dice?` so the
  failed cast's card stays visible, settled, above the error.
- `DiceCard({ dice, rolling, dict })` is pure presentation. `rolling` is
  true only for `pending.dice`. It uses `useSyncExternalStore` or
  `matchMedia` for reduced motion and timers for the face stepping, and
  holds no randomness.

### Wire delta (dw-3's Wire stands; only these change)

Request: `"action": "chat" | "cast"` (optional, default `"chat"`); each
transcript entry may carry `"dice": {"planet","sign","house"}`, on persona
entries only.

Cast stream:

```
event: dice   data: {"planet":"Pluto","sign":"Scorpio","house":8}   ← first frame, once
: keepalive                                                        (as before)
event: delta  data: {"text":…}  … 
event: done   data: {"mood":…, "chartRefs":[…]}   | event: error data: {"code":…}
```

A chat stream is byte-identical to dw-3's.

### Dependency rules and forbidden edges

- `dice.py` → `app.dictionary`, `random` and stdlib only. render.py and
  turn.py → `dice` (divination-internal). The existing
  `DIVINATION_FORBIDDEN_RE` fence and `test_divination_keeps_no_state`
  cover dice.py unchanged. dice.py writes nothing.
- `models.py` → `.dictionary` (new, Tier B, import-free).
- ❌ No other divination file imports `random`. ❌ No `random.seed`,
  `random.Random(` or module-level `random.choice/randint/randrange/shuffle`
  anywhere in divination. SystemRandom is the only source. Pinned in
  `test_divination_dice.py` (source scan plus self-check), not in
  `test_boundaries.py`, to keep the wave's shared surface small.
- **Determinism in tests without weakening production**: tests
  `monkeypatch.setattr(dice, "_RNG", Stub(...))`, a stub whose `choice`
  returns scripted faces. The pin test asserts that the unpatched
  `dice._RNG` is a `random.SystemRandom` and that `roll` names only `_RNG`.
  No seed or env switch exists.
- ❌ main.py is unchanged. It still names one `turn_events(`, so
  `test_main_names_the_synchronous_exceptions` holds.
  `test_delivery_never_generates_on_the_request_path` is unaffected.
- ❌ Web: no `Math.random` in `web-divination/src`. Colours only via
  `var(--…)`. `chat/` imports core only through the `/divination` and
  `/chart-view` barrels, with type-only `/chart`. G5 holds, because
  `SIGNS` is used in core, not in the web.

### Amendments (same commit as the code)

- **CLAUDE.md rule 10**, divination paragraph, one sentence appended: "A
  cast (dw-5-astro-dice, `action:"cast"`) is a turn whose server-rolled
  planet · sign · house (`divination/dice.py`, `random.SystemRandom` over
  the dictionary's PLANETS/SIGNS/HOUSES, never seeded) opens the stream as
  a `dice` event; the roll is never stored."
- **Guards**: none changed. `test_boundaries.py` and the jest guards stay
  byte-identical.
- **Epic file**: nothing now; docs-sync records dice.py and the recall fold.

## Acceptance Criteria

Server tests use fakes only: a monkeypatched `llm.stream_turn`,
`llm.generate_sections` and `dice._RNG`. The chart is REAL (dw-3's fixture).
Run `npm run server:test`, `npm test` and `npm run typecheck`. `PLUTO_SCO_8` =
a stub `_RNG` scripted to Pluto, Scorpio, 8.

**Server**
- **D1 (first frame)**: A cast with `PLUTO_SCO_8` and the fixture birth gives
  an SSE body whose first frame (comments included) is `event: dice` with data
  exactly `{"planet":"Pluto","sign":"Scorpio","house":8}`. That is followed
  by ≥1 `delta` and one `done`, and exactly one `dice` frame overall. With
  a fake stream that sleeps 1.5 s before its first chunk, the `dice` frame
  still comes before the first `: keepalive`.
- **D2 (chat unchanged)**: The same request with `action` absent, and with
  `"chat"`, has no `dice` frame, and the scripted `_RNG` records zero calls.
  The two bodies are byte-equal to each other. dw-3's existing
  `test_divination_turn.py` expectations (the dw-2 S1 frame sequence and
  the dw-3 S1–S9 tests) pass unedited, with no `action` in their bodies.
- **D3 (roll only after validation)**: `action:"dice"`, and a cast with an
  empty message, each answer 422, and `_RNG` records zero calls.
- **D4 (grounded prompt)**: For D1's cast the fake `stream_turn`'s system
  prompt contains, in order: `venus.txt`, `chart.read`, the chart marker, the
  `venus-dice.txt` text, `dice.marker`, the dice JSON, and the lang line. The
  dice JSON parses to:
  - `planet {name:"Pluto", means: PLANETS["Pluto"]}`,
    `sign {name:"Scorpio", means: SIGNS["Scorpio"]}`,
    `house {number:8, means: HOUSES[8]}`;
  - `inYourChart.planet` equal to the fixture chart's Pluto `{sign, house}`;
  - `inYourChart.inHouse` containing `"Moon"` (the fixture's Moon is in
    house 8);
  - `inYourChart.inSign` equal to the fixture planets whose sign is Scorpio,
    in chart order.
  A chat turn's prompt contains neither the dice brief nor `dice.marker`.
- **D5 (no chart / time unknown)**: A cast without `birthData` has dice JSON
  with no `inYourChart` key, and the prompt contains `chart.none`. A cast of
  the fixture with `time:null` has `inYourChart.inHouse` null, and
  `inYourChart.planet.house` null.
- **D6 (failure after the roll)**: A cast whose fake stream raises
  `AnalysisUnavailable` gives exactly `dice`, `error{unavailable}`. One that
  runs past `DIVINATION_TURN_TIMEOUT_S` gives `dice`, …, `error{timeout}`. A
  natal-context failure gives `dice`, `error{unavailable}`.
- **D7 (recall)**: A chat turn whose transcript is `[user "Will it last?",
  persona "…" with dice {Venus, Libra, 7}]` sends `stream_turn` a first user
  message ending with the formatted `dice.recall` line naming Venus, Libra
  and 7. The assistant message is the persona text unchanged. The prompt has
  no dice brief.
- **D8 (wire validation)**: Transcript dice `{planet:"Chiron",…}`,
  `{sign:"Ophiuchus",…}`, `{house:13,…}`, `{house:0,…}`, `{house:"8",…}`
  (strict int: no coercion), or dice on a `user`
  entry each answer 422 before any call. Valid persona dice are accepted.
- **D9 (real randomness)**: The unpatched `dice._RNG` is an instance of
  `random.SystemRandom`. 3,600 real `roll()` calls cover all 10 planets, 12
  signs and 12 houses, and every roll's faces are keys of the dictionary
  tables. A source scan finds `import random` only in `divination/dice.py`,
  and no `random.seed`, `random.Random(` or `random.(choice|randint|randrange|shuffle)(`
  in any divination file. Its self-check bites on each planted string.
- **D10 (fingerprint and footprint)**: `PROMPTS.fragments()` has
  `dice.venus` (equal to `venus-dice.txt`), `dice.marker`, `side.dice` and
  `dice.recall`. There is no hash comparison with dw-3: the fingerprint
  hashes every fragment, so these assertions are the check. `test_boundaries.py` passes unchanged, including
  `test_divination_borrows_only_the_restate_helper`,
  `test_divination_keeps_no_state`, `test_no_tier_imports_divination` and
  `test_main_names_the_synchronous_exceptions`.
  `git diff feature/divination_web...HEAD -- server/app/main.py
  server/tests/test_boundaries.py` (from the merge base) is empty.
- **D11 (dice are not refs, whenever dice are in view)**: With the fixture
  birth, the fake `generate_sections` receives a system text containing
  `side.refs` and then `side.dice` for:
  - (a) D1's cast;
  - (b) a CHAT turn whose transcript has a persona entry with dice (D7's
    transcript), for example asking "What did the planet die mean for me?".
  For (c), a chat turn with a dice-free transcript, the fake receives a
  system text exactly equal to `side.role + " " + side.refs`, with no
  `side.dice`. Its user JSON is also equal to
  `render.side_prompt(message, reply, lang, catalogue)` called with its
  default, which is dw-3's output unchanged.
  A cast without birth data gets the mood-only side prompt, with no
  `side.dice`.

**Core (vitest, fake StreamPost)**
- **C1**: Frames `dice {Pluto,Scorpio,8}`, `delta`, `done` yield events
  `dice`, `delta` and `done`, in order. A second `dice` frame, a `dice` after
  a delta, and malformed dice (`planet:"Chiron"`, `house:13`, `house:"8"`)
  are dropped. The request body carries the `action` it was given.
- **C2**: The transcript round-trips a persona entry with `dice` and a user
  entry with `cast:true` through a fresh KV read. A stored `dice:{house:0}`
  reads back without `dice`. `toWire` gives `{role,text,dice}` for that
  persona entry and `{role,text}` (no `cast`) for the user entry.
- **C3**: Root `npm test` and `npm run typecheck` pass, including all jest
  guards unchanged and en/zh parity with the new `chat` keys.
  `git diff feature/divination_web...HEAD --stat` (merge base) lists no
  `app-native/` path, and not
  `web-divination/src/app/App.tsx` or `theme/tokens.ts`.
  `grep -rn "Math.random" web-divination/src` finds nothing.

**Web (vitest, fake StreamPost, fake timers)**
- **W1**: Typing a question and clicking "Cast the dice" sends a body with
  `action:"cast"`. The user line shows the text and the cast mark. Enter and
  Send still send `action:"chat"`. Cast is `disabled` with an empty
  composer and while a turn is pending.
- **W2**: After the `dice` event and before any delta, a `figure` with
  `aria-label` "The dice: Pluto, Scorpio, 8th house" is in the log, marked
  rolling (`data-rolling`). After 1,100ms of fake time it is settled
  (`data-rolling` absent) and shows `♇`, `♏` and `8` and the captions. In
  zh the label is "星骰：冥王星、天蝎座、第八宫".
- **W3**: After `done`, the stored reply renders the card settled above its
  prose. A remount from KV renders it settled (no `data-rolling` at any time).
  A chat reply renders no card.
- **W4**: With `matchMedia('(prefers-reduced-motion: reduce)')` true, the live
  card is settled on the first render.
- **W5**: A cast that fails after its `dice` event shows the settled card and
  the error with Retry. Retry sends `action:"cast"` again. A follow-up chat
  turn after a finished cast sends the persona wire entry with its `dice`.
- **W6**: The card's colours come from `var(--…)` only (the colour guard
  passes). The dice glyphs are `aria-hidden`.

**Real app** (Chrome; backend and Vite as in Local runs; fixture birth
entered; `ANALYSIS_LLM=claude-cli`)
- **A1**: Typing "Should I tell her how I feel?" and pressing Cast: the network
  panel's turn request has `action:"cast"`. The dice card appears and rolls
  before any reply text. Its three faces settle within about 1.2 s while the
  text types out under it. A screenshot shows the settled card.
- **A2**: The response's first SSE frame is `dice` (the EventStream or
  response tab). The card's faces equal that frame's planet, sign and house.
- **A3**: The finished reply names all three faces. It relates them to the
  question, and links at least one of them to a real placement of the
  fixture chart. The checker lists each chart claim beside the Placements
  panel value, and none is invented. Each chip under the reply names a
  placement the reply speaks of as the user's OWN. A planet named only as
  a die gets no chip.
- **A4**: Three more casts show varied faces (not all three rolls identical).
  Reload shows every cast card settled with the same faces.
- **A5**: A follow-up chat "What did the planet die mean for me?" gets a reply
  that names the earlier planet face. Its request body's persona entry
  carries that `dice`. Its chips follow A3's rule.
- **A6**: In 中, a cast gets a Chinese reading, the card's captions are in
  Chinese, and the button reads 掷星骰.
- **A7**: With birth data cleared, a cast still shows dice and a reading that
  names no natal placement.
- **A8**: With DevTools reduced motion emulated, the card appears settled with
  no tumble.
