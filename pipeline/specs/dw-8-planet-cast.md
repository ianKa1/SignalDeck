# dw-8-planet-cast — six planet characters, a picker and a handoff

## Goal

The person picks one of six characters (Venus, Moon, Mars, Jupiter, Saturn, Mercury). Each one is that planet as placed in their own chart, speaks inside its own domain, keeps its own transcript, and hands an off-domain question to the right character with a one-tap switch. QUEUE.md `dw-8-planet-cast`; epic `pipeline/epics/divination-web.md`.

## Non-goals

- Current transits and timing (dw-11). dw-8 adds one `roster.timing` fragment saying the character reads the pattern, not the timing. dw-11 owns any change to it.
- Inline pills (dw-10), and bubbles or "go deeper" (dw-9). dw-8 composes with dw-9's reply shape and changes none of it.
- The Sun and the outer planets as characters. The sheet stays generic over ten planets, but only six are personas.
- A Mercury paste field, attachment or message parser. Mercury asks in prose, and the pasted text is an ordinary chat message.
- Auto-sending the question after a handoff, server-side memory of the active character, or cross-character context. Each transcript is sent only to its own character.
- New stores, migrations, jobs or prompt topics, or a VERSION bump of `divination_voice` or `divination_summary`.
- Any change to the dw-12 gate, or to `app-native/`.

## Decided defaults

1. **One list of personas.** The ids are `venus`, `moon`, `mars`, `jupiter`, `saturn`, `mercury`, always in that order. The one definition is `divination/persona.py` `PERSONA_PLANETS` (id → planet). The server's request literal and core's `PERSONA_IDS` mirror it, and tests pin both copies. Any other `persona` value is a 422 on the turn, summary and persona routes.
2. **Persona assets.** There are five new base texts, `personas/<id>.txt`. Each is built the way post-dw-9 `venus.txt` is: who it is, the one domain it meets every question from, how it answers (no length lines, because dw-9's `shape.*` fragments own length), and what it never does. Each is registered as `persona.<id>`, so the FINGERPRINT covers it. The domains:
   - **Moon**: needs and moods.
   - **Mars**: action and conflict.
   - **Jupiter**: opportunity. It must name the concrete risk or cost of what it encourages, in the same reply.
   - **Saturn**: limits, commitments and endings.
   - **Mercury**: messages and words. When a question turns on what someone wrote or said and the person has not given the exact words, Mercury asks them to paste the actual message before it reads it. It reads only words the person gave.
3. **Each reads its own ground.** `chart.read` keeps its text, but its Venus-only sentence ("For love and friendship these are usually…") becomes a `{focus}` slot, filled from a per-persona `focus.<id>` fragment. `focus.venus` is that exact sentence, so Venus's chart section stays byte-identical. The other five name their own planet with its sign, house and aspects, plus their houses:
   - Moon: the 4th house;
   - Mars: the 1st and 7th;
   - Jupiter: the 9th and 11th, plus Saturn for the cost;
   - Saturn: the 10th;
   - Mercury: the 3rd.

   The mirror (`self.read`) is templated on the planet name, and its examples no longer name Venus.
4. **D, for everyone.** A shared fragment, `roster.rules`, goes into EVERY character's system prompt, with or without birth data. It says to read the person's pattern, the dynamic and the actual words, and never to claim to know what another person feels, thinks or intends; asked, the character says so, then reads what it can. The D bullet moves out of `self.read` into this fragment, so the rule has one home. `roster.list` names the six characters and their domains. It tells the character that when a question belongs mainly to another's domain, it gives its own angle briefly and names who reads it better. `roster.timing` says the character has not been given the current sky, so it names no dates, transits or durations and says plainly that it can read the pattern but not the timing. The chart-less Venus prompt changes by exactly these three fragments, and the golden fixtures are re-recorded.
5. **Dice for all six.** The dice brief is already character-neutral, so it becomes one shared asset: `personas/venus-dice.txt` is renamed to `personas/dice.txt` and registered as `dice.brief`. Every character can cast.
6. **Handoff is a structured side field, never parsed from prose.** On `action:"chat"` turns the existing side read also returns `handoff`, an enum of the other five ids or `"none"`. It is told to name a character only when the question falls mainly in that character's domain, and to agree with the reply when the reply names one. The server validates it through one shaper, `to_wire_handoff`: a known id other than the request's persona passes through, and anything else becomes null. `done` carries it as `handoff: <id> | null`, always present. A cast (or dw-9 deeper) turn, and a failed or late side read, give null. The client keeps the handoff on the stored persona entry when `isPersonaId` accepts it. It is device-only, survives a reload and is never sent on the wire.
7. **Per-character transcripts.** They reuse dw-2's KV key per persona (`astrology.divination.transcript.v1.<id>`), and nothing is migrated. The active character is device state, stored in KV at `astrology.divination.active.v1`. When none is stored, the picker opens.
8. **Personalised line without generating.** A new PURE read, `POST /api/divination/sheets {birthData}`, answers 200 with the six sheets' facts. It makes no LLM call, enqueues nothing, has no provider gate and stores nothing. Without birth data the web app does not call it. The picker's line is the dw-7 placement line (`placementText`) over that sheet. The voice job is still ensured only for the active character (dw-7's persona request, unchanged).
9. **Summaries, chips and activation per character.** The summary route takes any persona. Its role text is generalised to "one of six planet characters", with the persona id already in the data and the key unchanged. End and the session record use the active persona. `parseRecord` accepts any persona id, and the session card shows that character's glyph, name and colour. Chips and wheel activation work unchanged for every character, because the catalogue is chart-wide. Switching character clears the activation. Switching to another character during a turn stops it, and the partial reply is stored as a stopped entry on the old character. Merely opening the picker does not stop it: the picker overlays the chat panel, which stays mounted.
10. **What the person sees** (the frontend-design bar: the almanac letter-and-seal register, gold on ink).
    - **Picker, "The six" (zh 六位星辰).** A 2×3 grid of almanac plates, one column on narrow widths. Each plate has:
      - the planet's glyph as a wax seal in its own ink;
      - the name in small caps;
      - the one-line domain in italic;
      - two example questions set as quoted marginalia (the queue's examples; Jupiter's are "Is it worth grabbing?" / 这个机会值得抓住吗？ and "Will the next step open things up?" / 下一步会打开局面吗？). Each is a button that picks the character and PREFILLS its composer without sending;
      - once birth data exists, the engraved placement line at the foot, with the sign glyph;
      - a faint "resume" mark when that character has a transcript.

      The plates reveal in a 60 ms stagger, and reduced motion shows them static. The picker opens on first use, and from a quiet "The six" button in the chat header. Esc or Back returns to the active character.
    - **Per-character chrome.** Each character has one colour pair in `theme/tokens.ts`: `persona.<id>` (ink) and `personaGhost.<id>` (35% glow). Venus keeps her rose-copper. The others are Moon pearl-blue, Mars ember, Jupiter orchid, Saturn lead-brass and Mercury quicksilver-sage. The old `venus` and `venusGhost` tokens fold into `persona.venus` and `personaGhost.venus`. The shell carries `data-persona`, and one stylesheet maps it to the scoped `--char` and `--char-ghost`, which every former `var(--venus…)` reads: the header sigil, the caret, the seals and the wheel's lit glow. A session card carries its own `data-persona`. The header sigil is the planet's glyph, the title is "{Name}" or "Your {Name}", the subtitle is the domain, and the greeting is the character's own.
    - **Handoff slip.** Under the finished reply, beside the chart seals, a small slip bordered in the TARGET's ink shows the target's seal, "Saturn reads this better" and a button "Ask Saturn →". One tap switches to Saturn and prefills Saturn's composer with the question that reply answered. Saturn's transcript is untouched until the person sends.
11. **Strings.** A new `roster` i18n namespace holds each character's name, domain, greeting and two examples, plus the picker, resume and handoff strings. The zh names are 金星, 月亮, 火星, 木星, 土星 and 水星. Every Venus-named string in `chat`, `log` and `persona` becomes a `{name}` template. After dw-8, "Venus" appears in `en.ts` only under `bodies` and `roster.venus`, and "金星" appears in `zh.ts` the same way.

## Architecture

This section cites `pipeline/epics/divination-web.md` (reuse map, event grammar, dependency rules) and writes only dw-8's delta. The base is d2aaf12, and dw-9 and dw-12 land first.

### Reuse (verified 2026-09-28)

| Need | Existing | Use |
|---|---|---|
| Persona list, sheet | `divination/persona.py:34` `PERSONA_PLANETS`, `:72` `persona_sheet`, `:110` `sheet_for`, `:116` `sheet_facts` | Widen the dict to six; the rest is unchanged |
| Prompt composition | `render.py:52` `PERSONAS`, `:59` asset, `:72` `side.role`, `:89` `chart.read`, `:116` dice asset, `:136` `self.read`, `:214` `natal_context`, `:247` `system_prompt`, `:282` `dice.{persona}`, `:351` `side_prompt`, `:372` `side_schema` | Change in place |
| Side read and `done` | `turn.py:167` `_side_read`, `:247` `done` frame | Add the third field |
| Voice job | `voice.py:103` `voice_prompt`, `voice_role.txt` (Venus-flavoured lines) | Generalise the role text only, VERSION stays 1 |
| Summary | `summary_role.txt` (names Venus) | Generalise the text, key unchanged |
| Request models | `models.py:388`, `:423`, `:451` `Literal["venus"]` | One `DivinationPersona` alias |
| Sheet-ish route shape | `main.py:482` persona route, `:148` `_person` | The new pure route mirrors its validation |
| Core persona typing | `core divination/types.ts:10` `PersonaId`, `:63` `TurnEvent` done; `turn.ts:78` done parse; `transcript.ts:24` `sanitize`; `session-log.ts:89` `v.persona !== 'venus'`; `persona.ts` `fetchPersona` | Widen and add fields |
| Placement words | `web chat/PersonaHeader.tsx:23` `placementText` | Reused by the picker |
| Hard-coded Venus | `ChatPanel.tsx:200-201` `useChat('venus')`/`usePersona('venus')`; `log/SessionBar.tsx:19` `PERSONA`; `SummaryCard.tsx:122` ♀; `PersonaHeader.tsx:40` ♀ | Take the persona from props |
| Colour flattening | `theme/apply.ts:23` `tokenVars` (one nesting level → `--persona-moon`, `--persona-ghost-moon`) | As-is |

### Module map (created or changed only)

```
server/app/divination/
├── persona.py            CHG  PERSONA_PLANETS: six entries (order fixed)
├── personas/{moon,mars,jupiter,saturn,mercury}.txt   NEW  base texts
├── personas/venus-dice.txt → personas/dice.txt       MV   asset `dice.brief`
├── render.py             CHG  PERSONAS = tuple(PERSONA_PLANETS); five assets; focus.<id>;
│                              roster.rules/list/timing; chart.read {focus}; self.read {planet};
│                              side.role {name}; side.handoff; side_schema(catalogue, handoff);
│                              to_wire_handoff
├── turn.py               CHG  _side_read returns (mood, refs, handoff); done gains handoff
├── voice_role.txt        CHG  planet-neutral wording
└── summary_role.txt      CHG  planet-neutral wording
server/app/models.py      CHG  DivinationPersona alias ×3; + DivinationSheetsRequest (EOF)
server/app/main.py        CHG  + POST /api/divination/sheets (after the persona route)
server/tests/             CHG  test_divination_{render,turn,persona,summary}.py; fixtures re-recorded;
                               + test_divination_roster.py; test_boundaries.py pins
packages/core/src/divination/
├── roster.ts             NEW  PERSONA_IDS, isPersonaId, active persona on KV, fetchSheets
├── types.ts              CHG  PersonaId = (typeof PERSONA_IDS)[number]; done.handoff; entry.handoff?
├── turn.ts               CHG  parse done.handoff
├── transcript.ts         CHG  sanitize keeps a valid handoff
├── session-log.ts        CHG  parseRecord: isPersonaId
└── index.ts              CHG  one appended export block
web-divination/src/
├── roster/RosterPicker.tsx, roster.css, useRoster.ts   NEW  picker, --char mapping, sheets hook
├── app/App.tsx           CHG  active persona, picker view, data-persona, seed + handoff wiring
├── chat/ChatPanel.tsx    CHG  props {persona, seed, onHandoff, onOpenRoster}; HandoffSlip
├── chat/PersonaHeader.tsx CHG glyph/name/domain per persona; "The six" button
├── chat/useChat.ts       CHG  store done.handoff on the entry
├── chat/*.css, log/log.css, chart/wheel.css   CHG  var(--venus…) → var(--char…)
├── log/SessionBar.tsx, SummaryCard.tsx, SessionsScreen.tsx  CHG  persona from props/record
├── theme/tokens.ts       CHG  venus/venusGhost → persona/personaGhost Record<PersonaId,…>
└── i18n/en.ts, zh.ts     CHG  + roster namespace; {name} templates
```

### Contracts

**`render.py`**
- `system_prompt(persona, lang, ctx, cast, voice, action)` (dw-9's `action` kept) builds, in order:
  1. `persona.<id>`;
  2. [dw-9 `shape.*`, `depth.*`];
  3. `roster.rules`, `roster.list`, `roster.timing`;
  4. the self section (`self.read` formatted with the planet);
  5. `chart.read` formatted with `focus.<id>`, or `chart.none`;
  6. `dice.brief` on a cast;
  7. `lang.<lang>`.
- `side_prompt(message, reply, lang, catalogue, dice_in_view, persona, handoff)`: `side.role` is formatted with the persona's name. `handoff=True` appends `side.handoff`, with the current persona named.
- `side_schema(catalogue, handoff_ids | None)` adds `handoff: {"type":"string","enum":[…others, "none"]}` as a required field when `handoff_ids` is given. It does this on BOTH branches: with an empty catalogue it returns `{mood, handoff}` in place of `MOOD_SCHEMA`.
- `to_wire_handoff(value, persona) -> str | None`: the ONE handoff shaper.

**`turn.py`** asks for a handoff only when `action == "chat"`. `_side_read` returns a triple and never raises; a failure gives `(None, [], None)`. `done` is `{mood, chartRefs, handoff}`.

**main.py `divination_sheets`**:
- It runs `_person(birthData)` and computes ONE `natal_report(person)`. It then returns `{schemaVersion:1, sheets:{id: sheet_facts(persona_sheet(PERSONA_PLANETS[id], report)) for id in PERSONA_PLANETS}}`.
- It names no generator, no `ensure_`, no store and no voice.
- A chart failure is a 500, as on `/api/chart`.

**core `roster.ts`**:
- `PERSONA_IDS` (the six, in order) and `isPersonaId`.
- `ACTIVE_KEY = 'astrology.divination.active.v1'`, with `getActivePersona(): PersonaId | null`, `setActivePersona(id)` and `subscribeActivePersona(cb)`. An invalid stored value reads as null.
- `fetchSheets(birthData, signal) -> Promise<Record<PersonaId, PersonaSheet> | null>` makes one POST through `postJson`. It never throws, and it returns null if any sheet fails `isPersonaSheet`.

**web**:
- `useRoster()` returns `{active, setActive, sheets}`. `sheets` is fetched when birth data exists and aborted when it changes.
- `setActive` calls `clearActivation()`.
- `ChatPanel` is keyed by persona ONLY, and stays mounted under the picker overlay.
  - Switching character remounts it. The unmount abort then stores a stopped entry through the existing stop path, which after dw-9 is the pacer's `flush()` followed by the stopped append.
- `seed` is `{text, nonce}`. ChatPanel writes `text` into the draft whenever `nonce` changes, so a same-character example or handoff reapplies without a remount, and the turn in flight survives.
- The `HandoffSlip` button calls `onHandoff(target, question)`, where `question` is the user entry just before that persona entry.

### Wire (exact delta)

- `persona` ∈ `venus|moon|mars|jupiter|saturn|mercury` on `/api/divination/turn`, `/summary` and `/persona`. Anything else is a 422.
- `done`: `{mood, chartRefs, handoff}`, where `handoff` is one of the six ids and ≠ the request persona, or `null`, and is always present. `dice`, `delta`, `error` and dw-9's `bubble` are unchanged.
- NEW `POST /api/divination/sheets`:
  - request `{birthData: BirthData}` (required, validated as `/api/chart`);
  - 200 `{schemaVersion:1, sheets:{venus,moon,mars,jupiter,saturn,mercury: PersonaSheet facts}}`;
  - 422 on any breach.
- The transcript wire is unchanged: `handoff` never leaves the device.

### Dependency rules and forbidden edges

- The epic's fence is unchanged. No new edge enters or leaves `divination`, and `persona.py` stays pure (`test_persona_sheet_is_pure` unchanged).
- ❌ The sheets route never names `generate_`, `ensure_`, `store`, `cached_` or `voice` in its function body (new pin). It is not a rule-14 generative endpoint, and `test_main_names_the_synchronous_exceptions` stays unchanged.
- ❌ The handoff is never derived from the reply text by the server's own code. `to_wire_handoff` reads only the side read's JSON field (a pin: `turn.py` and `render.py` contain no regex over the reply).
- ❌ The web never reads another character's transcript into a turn. Only `roster.ts` names the active key.
- Colour stays in `theme/tokens.ts`. `roster.css` maps variables only, with no literal (the colour guard).

### Guard and CLAUDE.md amendments (same commit)

- `test_boundaries.py`:
  - `test_persona_lists_agree`: `get_args(models.DivinationPersona) == tuple(PERSONA_PLANETS) == render.PERSONAS`;
  - `test_sheets_route_is_pure`, with a self-check that bites on a planted `ensure_`.
- Core vitest: `PERSONA_IDS` equals the server's order (a golden string copied in the test, with a comment naming `persona.py`).
- CLAUDE.md rule 10 (the divination paragraph) gains one sentence: `persona.PERSONA_PLANETS` is the one list of the six personas, which models and core mirror under pinning tests; `POST /api/divination/sheets` is a pure facts read (no LLM, no enqueue, no store); and the handoff is a structured side-read field validated against that list, never parsed from prose.
- Epic file: at docs-sync.

### Composition with dw-9, dw-12 and dw-11; shared files

- **dw-9 lands first.**
  - dw-8's `roster.*` fragments go after dw-9's `depth.*`, so the with-chart order is persona < shape < depth < roster < `self.read` < chart < dice < lang.
  - The chart-less goldens are re-recorded from the merged render, and the fixture diff is exactly the three `roster.*` fragments.
  - `deeper` turns get `handoff: null`.
  - `HandoffSlip` sits after dw-9's slips, beside the chips, and is rendered only for stored entries (after the pacer's end).
  - Shared files: `render.py` (append-only fragment declarations, plus the one return expression), `turn.py` (only `_side_read` and the `done` line), `ChatPanel.tsx` (hooks line, props, `Entry` footer), `chat.css` (a mechanical variable rename), `models.py` (in-place alias; dw-9's `action` edit is a separate line), and the `dice.txt` rename (dw-9 edited line 11; the rename carries it).
- **dw-12's gate wraps `<App/>` in `main.tsx`.** dw-8 changes only what renders inside App, so nothing new renders before sign-in: the sheets request and the active-persona read happen inside App. Shared files: `i18n` (dw-12 appends `auth` last, and dw-8 adds `roster` before it) and `test_boundaries.py` (both append).
- **Composition with dw-11 (a coordinator hand-off contract).**
  - **Order:** acceptance and landing are serial in queue order (PIPELINE.md, Parallel waves 6), and dw-8 sits above dw-11 in QUEUE.md. So dw-8 always lands first, and dw-11 merges dw-8 in.
  - **Timing line:** dw-8 emits `roster.timing` unconditionally. dw-11 OWNS replacing or suppressing it wherever a sky section is present, and must add the test that `roster.timing` and a sky section never appear in the same prompt.
  - **Slot:** a sky section sits after the chart section and before the dice, i.e. persona < shape < depth < roster < self < chart < **sky** < dice < lang.
  - **Files dw-11 is expected to share:** `render.py` (the `system_prompt` order and return expression), `turn.py`, `main.py`, `test_boundaries.py`, CLAUDE.md rule 10, and the golden fixtures.
  - **Goldens:** dw-8 re-records the chart-less goldens at its own landing, and dw-11 re-records them at its landing.
- No migration is added.

## Acceptance Criteria

Server tests use monkeypatched `llm.generate_sections`/`llm.stream_turn` only, with REAL charts. Run `npm run server:test`, `npm test`, `npm run typecheck`. Chart A = the dw-3/dw-7 fixture (1990-06-15 08:30, 39.9042/116.4074, Asia/Shanghai, placidus).

**Server**
- **S1 (list)**: `PERSONA_PLANETS` keys are exactly `venus, moon, mars, jupiter, saturn, mercury` in that order, mapping to the capitalised planet; `test_persona_lists_agree` passes and fails when a seventh literal is planted in `models.py`.
- **S2 (422)**: `persona: "pluto"`, `"sun"` and `"Venus"` each answer 422 on `/turn`, `/summary` and `/persona` and call no fake; `persona: "saturn"` is accepted by all three (turn streams `done`; summary and persona answer 200 with a fake).
- **S3 (sheets)**: `POST /api/divination/sheets` with chart A answers 200 with exactly `{schemaVersion, sheets}`; `sheets` has exactly the six keys in order; moon = Pisces/8/null/steady/direct, mars = Aries/9/domicile, jupiter = Cancer/12/exaltation, saturn = Capricorn/6/domicile/retrograde with aspects `[Ascendant opposition conflict, Venus trine ally]`, mercury = Gemini/11/domicile, venus equals dw-7 P1's facts. It succeeds with no provider key and no `ANALYSIS_LLM`, calls no LLM fake, enqueues no job and writes no store row; a bad date and a missing `birthData` answer 422.
- **S4 (prompts per character)**: for each of the six ids, chart-less and with chart A, the system text starts with that id's `persona.<id>` text and contains `roster.rules`, `roster.list` and `roster.timing` exactly once each; with chart A it contains `focus.<id>` and `self.read` formatted with that planet, and the sheet JSON's `"planet"` equals that planet; Moon's contains "Pisces", Saturn's "Capricorn". `jupiter.txt` contains a risk instruction and `mercury.txt` a paste instruction (asserted by key phrases "risk" and "paste").
- **S5 (Venus stability)**: with chart A, Venus's chart section (from `chart.read` through the chart JSON) is byte-identical to d2aaf12's. The re-recorded chart-less Venus fixtures differ from the pre-dw-8 fixtures only by the inserted `roster.rules`, `roster.list`, `roster.timing` block (test compares with the three fragments removed). `self.read` no longer contains the other-person-feelings sentence, and `roster.rules` does ("never claim to know what another person feels").
- **S6 (dice for all)**: a cast with persona `mars` streams `dice` first and its system text contains `dice.brief`; `personas/venus-dice.txt` no longer exists and `dice.txt` does; a Venus cast's dice section is byte-identical to before the rename.
- **S7 (handoff)**: on a `chat` turn the side-read fake receives a schema whose required fields include `handoff` with enum = the five other ids plus `"none"`, and a system text containing `side.handoff`. Fake answers map to `done.handoff` as: `"saturn"` (persona venus) → `"saturn"`; `"none"` → null; `"venus"` (persona venus) → null; `"pluto"` → null; field missing → null; side read raising → `{mood:null, chartRefs:[], handoff:null}`. A chart-less `chat` turn (no `birthData`, empty catalogue) gets the schema `{mood, handoff}`, both required, and a fake `"moon"` maps to `done.handoff:"moon"`. A `cast` turn's side schema has no `handoff` and `done.handoff` is null. Every `done` frame has exactly the keys `mood, chartRefs, handoff`.
- **S8 (summary per character)**: a summary for persona `moon` answers 200 with `persona:"moon"`; its key differs from the same entries under `venus`; `summary_role.txt` no longer contains "Venus".
- **S9 (voice per character)**: `POST /api/divination/persona` for `saturn` with chart A answers 202 with Saturn's sheet, then 200 once the fake voice is stored; the voice prompt's user JSON has `"planet":"Saturn"`; `voice_role.txt` contains none of the ten planet names (it says `<planet>`) and no "love, friendship or self-worth"; `voice.VERSION == 1`.
- **S10 (boundaries)**: `test_boundaries.py` passes; `test_sheets_route_is_pure` bites on a planted `generation.ensure_divination_voice(` inside the sheets route; `test_main_names_the_synchronous_exceptions` passes unchanged; every pre-existing divination suite passes with only mechanical updates (the `"mars"` 422 cases become `"pluto"`, `done` shape gains `handoff`, re-recorded fixtures).

**Core and web** (vitest, stubbed fetch)
- **C1**: `isPersonaId` accepts exactly the six ids; `PERSONA_IDS` joined equals `"venus,moon,mars,jupiter,saturn,mercury"`. `streamTurn` yields `done.handoff` for `"saturn"`, and null for `null`, a missing field, `"pluto"` and `42`.
- **C2**: `getActivePersona()` is null on empty KV and on a stored `"pluto"`; `setActivePersona("moon")` persists under `astrology.divination.active.v1` and notifies subscribers. Transcripts for `venus` and `moon` live under their own keys and appending to one leaves the other unchanged.
- **C3**: `sanitize` keeps `handoff:"saturn"` on a persona entry and drops `"pluto"`; `toWire` never emits `handoff`. `parseRecord` accepts a `moon` record and rejects `pluto`. `fetchSheets` resolves the six sheets from a 200, and null on 422, a rejected fetch or a sheet with house 13, without throwing.
- **W1 (picker)**: with no active persona the picker renders six plates in order, each with the planet glyph, name, domain and two example buttons; with no birth data no plate has a placement line and no `/api/divination/sheets` request is made; with chart A's birth data and a mocked sheets 200, the Moon plate reads "in Pisces · 8th house" with the Pisces glyph and Saturn's ends "· ℞ retrograde".
- **W2 (pick and prefill)**: clicking Saturn's second example sets the active persona to `saturn`, shows the chat with title "Saturn" (or "Your Saturn" with a sheet) and the ♄ sigil, and the composer holds that example text; nothing is POSTed to `/api/divination/turn`.
- **W3 (own transcripts)**: after a mocked Venus turn, switching to Moon shows the Moon greeting and no Venus entry; switching back shows the Venus entry; each character's turn body carries `persona` equal to that id and only that character's transcript. Switching during a streaming turn stores the partial as a stopped entry on the old character. Opening the picker during a streaming turn does not abort it, and closing the picker shows the reply still arriving. Picking an example of the ALREADY-active character replaces the composer text without remounting the panel.
- **W4 (handoff slip)**: a mocked Venus `done` with `handoff:"saturn"` renders a slip "Saturn reads this better" with button "Ask Saturn →" after the reply; clicking it makes Saturn active and prefills the question the reply answered; no turn is sent. `handoff:null` renders no slip. After reload the slip is still shown under that entry.
- **W5 (chrome)**: the shell's `data-persona` equals the active id; `roster.css` maps each `[data-persona="<id>"]` to `--char`/`--char-ghost` from `--persona-<id>`/`--persona-ghost-<id>`; no file in `web-divination/src` contains `--venus`; `tokens.ts` has `persona` and `personaGhost` with exactly the six keys and no `venus`/`venusGhost`; a Moon session card carries `data-persona="moon"` and the ☽ seal; End with Mars active archives a `mars` record.
- **W6 (strings and guards)**: i18n parity passes with the `roster` namespace; `en.ts` contains "Venus" only under `bodies` and `roster.venus` and `zh.ts` "金星" likewise (a test walks the leaves); zh names are 金星/月亮/火星/木星/土星/水星; `roster.css` has a `prefers-reduced-motion: reduce` block disabling the plate stagger; the colour, barrel, network and arithmetic guards pass.

**Real app** (dw-12's gate is on the base: a throwaway local Postgres cluster on a free port with `DATABASE_URL` pointing at it — never the `.env` remote; backend started without `--env-file`, with `ANALYSIS_LLM=claude-cli`, `CORS_ALLOW_ORIGINS` for the Vite origin and a placeholder `GOOGLE_CLIENT_ID`; a bearer pair minted on that cluster with dw-12's validation recipe (`logs/dw-12-google-sign-in/05-validating.md`, `_upsert_user` + `_mint_bearer`) and written to the three auth KV keys; Vite with `VITE_API_BASE` set to that backend; any free ports; cluster deleted afterwards)
- **A1 (pick any of six)**: with chart A saved, the picker shows six plates with placement lines matching S3; picking each of the six in turn and asking "Why do you see things the way you do?" gets a reply from that character naming its own sign from S3 (Moon Pisces, Mars Aries, Jupiter Cancer, Saturn Capricorn, Mercury Gemini, Venus Taurus); the log quotes all six replies.
- **A2 (domains)**: Jupiter asked "A friend offered me a partnership in her business — is it worth grabbing?" names a concrete risk or cost in the same reply; Mercury asked "What did he mean by his last text?" (no text given) asks for the actual message; after pasting a message, Mercury's next reply quotes or refers to its words. Log quotes all three.
- **A3 (handoff)**: Venus asked "Should I quit my job and start over?" ends with a Mars, Saturn or Jupiter handoff slip (`done.handoff` in the network panel non-null, not venus); tapping it opens that character with the question prefilled; sending it gets an in-domain reply. Because the handoff depends on the LLM, one rephrase or retry of the off-domain question is allowed; the log quotes both attempts and their `done.handoff`. Venus asked "Does he like me?" shows no slip. Saturn asked "When will this hard stretch end?" says it can read the pattern but not the timing and names no date.
- **A4 (D)**: Venus asked "Does he secretly love me?" and Moon asked "Is she angry with me?" each say they cannot know the other person's feelings and read the person's pattern, dynamic or words instead.
- **A5 (persistence and log)**: after turns with Venus and Moon, a reload returns to the last active character with its transcript; Venus's transcript is intact on switching; ending the Moon session yields a Sessions card with the ☽ seal and Moon's colour and name; the wheel's lit glow after a Mars reply with refs is in Mars's ember.
