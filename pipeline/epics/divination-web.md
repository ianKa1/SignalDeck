# Epic architecture — divination web (dw-1 … dw-6)

The shared architecture for every `dw-*` queue entry. Each feature's spec
CITES this file and writes an architecture section only for the modules
that feature changes (PIPELINE.md, Skills per stage). Surveyed 2026-09-28;
updated at each dw feature's docs-sync. If code and this file disagree,
the code and CLAUDE.md win: fix this file.

## Product

A local browser app. The user enters birth data and sees a natal wheel.
They chat with planet characters (Venus first) whose replies are grounded
in their chart. The wheel lights up the placements a reply relies on. A
character can cast Astro Dice. Every session is logged as a card.

## User rulings (DECISIONS.md, 2026-09-28)

- **Streamed turns.** `POST /api/divination/turn` answers
  `text/event-stream` and sends the reply text as it is generated. This is
  the SECOND rule-14 synchronous exception; it gets a timeout and a pinning
  test. Structured side fields (mood, handoff, the dice roll) ride their
  own events or the side read and are never parsed out of the prose.
  The earlier absolute reading — "nothing is ever parsed from the prose" —
  was a LOOP derivation, not part of the user ruling (DECISIONS
  2026-09-29, decision precedence). User ruling B (2026-09-29) makes the
  ONE exception: closed-vocabulary PHENOMENON tags (`⟦placement:…⟧`,
  `⟦aspect:…⟧`, `⟦transit:…⟧`, `⟦dice:…⟧`) are scanned out of the reply by
  the pure `divination/tags.py`, checked against the turn's chart, sky
  packet or rolls, and streamed as `pill` events (dw-10); a failing tag is
  plain text plus a server WARNING, never an unchecked pill.
- **Local only.** Vite dev server against the local backend. No hosting,
  no Render change.
- **Parallel waves.** dw-4, dw-5 and dw-6 all depend only on dw-3.

## Built so far

**dw-1 (`f02e88b`)** added the `web-divination/` workspace, Vite + React
19.2.3, with vitest tests:

- `src/platform/boot.ts` is the composition root. It calls
  `configureApiBase` with `VITE_API_BASE` (default `http://localhost:8000`)
  and is the only folder allowed to name network APIs.
- `src/session.ts` pins one local profile, `traveler`, because core's
  birth-data store is profile-namespaced. This is a namespace key, not an
  identity.
- `src/birth-input/` is the form over `core/birth-data`: validation codes
  and the lazy city index.
- `src/chart/` holds the SVG wheel over `core/chart-view`. Wheel elements
  are addressable by `data-planet` and `data-aspect-key`, which dw-4 uses.
- `src/theme/tokens.ts` is the web's sole colour home.
- `src/i18n/` is a namespaced en/zh dictionary with a parity test.
- Root scripts: `npm run web` starts Vite on :5173; `npm run web:server`
  starts the backend with CORS open for :5173.
- `core/chart-view` gained `midLongitude` and `SIGN_SECTORS`.
- CLAUDE.md now lists the web tree in rules 1, 2, 5, 8 and 13. The guards in
  app-native's jest suites walk `web-divination/src` as a third tree, and
  the web and native apps may never import each other.

**dw-2 (branch `feature/dw-2-venus-chat`, landing pending)** added the Venus
chat:

- `server/app/llm.py`: `stream_turn(system, messages)`, the one multi-turn
  streaming entry (concrete `Provider.stream` for Anthropic, OpenAI-compat
  and claude-cli). The CLI branch runs `claude -p --output-format
  stream-json --verbose --include-partial-messages --tools ""
  --system-prompt <persona>` in a neutral cwd, with the conversation on
  stdin.
- `server/app/planet_chat/`: `render.py` (topic `planet_chat`: `persona.venus`,
  `lang.en`, `lang.zh`, `side.role`; `MOODS`, `MOOD_SCHEMA`,
  `turn_messages`, `side_prompt`) and `turn.py` (`turn_available`,
  `turn_timeout_s`, `turn_events`, `shutdown`). Stateless, pinned by
  `test_planet_chat_keeps_no_state`.
- `POST /api/planet_chat/turn` in main.py (`planet_chat_turn_stream`), rule
  14's second synchronous exception, pinned with the ask judge by
  `test_boundaries.py::test_main_names_the_synchronous_exceptions`.
- core: `platform/stream.ts` (the StreamPost port), `platform/sse.ts`
  (`parseSse`), and `planet_chat/` (types, `streamTurn`, the KV transcript
  at `astrology.planet_chat.transcript.v1.venus`, `toWire`). Core names no
  Web stream API (a jest guard with no allowlist).
- web: `src/platform/stream.ts` (`webStreamPost`, installed by boot),
  `src/chat/` (`useChat`, `ChatPanel`, `chat.css`) mounted in the side
  slot, tokens `venus`/`venusGhost`, and the `chat` i18n namespace.

**dw-3 (`2f45dfb`)** grounded
Venus in the chart:

- `PlanetChatTurnRequest.birthData: BirthData | None` (the `/api/chart`
  body, 422 on a bad value); main.py passes `_person(birthData)` to
  `turn_events(request, person)`. The chart is recomputed per turn and
  dropped — no cache, no state.
- `planet_chat/render.py`: fragments `chart.none` (the not-read line, moved
  out of `venus.txt`), `chart.read`, `chart.marker`, `side.refs`
  (retired by dw-10) (FINGERPRINT moved); `natal_context(person)` → `NatalContext {chart,
  restated, meanings, catalogue}` via `natal_report` + the borrowed
  `interpretation.prompt._restate` + `relevant_meanings`;
  `ref_catalogue(chart)` (the chip-able refs: `planet:<Body>` for the ten
  `PLANET_NAMES`, then `aspect:<bodyA>|<type>|<bodyB>` for chart aspects
  between those or `Ascendant`, chart order); `side_schema(catalogue)`
  (catalogue ids as an advisory enum — dw-10 dropped the catalogue from the
  side read: `side_schema(handoff)`); `to_wire_refs` (the one ref shaper:
  catalogue-only, dedup, cap 6; since dw-10 fed by `pill_ref_ids`).
- The ONE pinned borrow `from app.interpretation.prompt import _restate`
  (render.py only), enforced by
  `test_planet_chat_borrows_only_the_restate_helper` (the fence regex
  unchanged; the old `…imports_only_llm_prompts_chart_dictionary` test
  folded in). CLAUDE.md rule 10 records it.
- core `planet_chat`: `ChartRef`, `isChartRef`, `TurnRequest.birthData`,
  `done.chartRefs`, `TranscriptEntry.chartRefs?` (kept on reload when
  non-empty; never on the wire).
- web `chat/`: `useChat` sends `getBirthData()` each turn and stores refs;
  `ChatPanel`'s `ChartRefChips` — a static `ul` of engraved seals
  ("read in your chart" / "星盘所见") under a finished reply; i18n
  `chat.refsLabel`, `chat.aspects`.

**dw-4 (`71bab4b`)** lit the
wheel from replies:

- `web-divination/src/chart/wheel-activation.ts`: a page-session store
  (`showRefs(refs, chip?)`, `clearActivation`, `getActivation`,
  `subscribeActivation`, `useActivation`; never KV) plus the pure
  `activationFor(chart, refs) → {lit, echo} | null` (set membership over
  core `aspectKey`/`planetFamily`; misses ignored; no match → null).
- `ChartWheel` gains an optional `activation` prop: `data-active` on the
  svg, `data-lit`/`data-echo` on planets, chords, conjunction dots and hub
  nodes; hub nodes always carry `data-planet-node`. `ChartStage` wires the
  store to the shown chart. Glow/dim in wheel.css via existing tokens;
  reduced motion → `transition: none !important`.
- `useChat` clears the activation at every turn start, calls `showRefs` on
  a finished reply with refs, and clears when the transcript shrinks.
  `ChartRefChips` items are `li > button[aria-pressed]`, id
  `"<entry>:<ref>"`. New edge: `chat → chart/wheel-activation`.

**dw-5 (`edd9d0f`)** added Astro Dice:

- `planet_chat/dice.py`: `_RNG = random.SystemRandom()`, never seeded;
  `roll`/`faces`/`chart_links`/`to_wire` over the dictionary's
  PLANETS/SIGNS/HOUSES (ten planets, no nodes).
- `personas/venus-dice.txt` plus fragments `dice.marker`, `side.dice`,
  `dice.recall` (FINGERPRINT moved). `side_prompt(dice_in_view)` told the
  side read die faces are not chart refs (retired by dw-10: `side.dice` is
  gone; dice in view add `tags.dice` to the system prompt instead); a dice-free chat turn is byte-identical to dw-3.
- `PlanetChatTurnRequest.action: "chat"|"cast"` (absent = chat); persona
  entries may carry `dice` on the wire (StrictInt house; 422 on a user
  entry); the recall note folds into the last user message before the
  persona entry. The roll happens after validation, before
  `natal_context`; `dice` is the first frame.
- core: `Dice`/`isDice`/`TurnAction`, the `dice` event, entry `dice`/`cast`;
  `SIGNS` exported from the chart barrel.
- web: `chat/DiceCard.tsx` (rolling pentagon card, fixed face order, no
  `Math.random`), the Cast button, i18n `cast`/`diceLabel`/`diceAria`/
  `castMark`/`houses`. Retry of a failed cast re-rolls.

**dw-6 (`b308a92`)** recorded every session:

- `planet_chat/summary.py` (topic `planet_chat_summary`, VERSION 1, six
  tones) and `planet_chat/store.py` (SQLite `data/planet_chat.db` / Postgres
  `planet_chat_summary`, migration 011; the only planet chat module that
  imports `db`); `generation.ensure_planet_chat_summary` (priority 1);
  `POST /api/planet_chat/summary` (200 hit / 202 ensure / 502 failed / 503
  keyless). Content key = topic+version, persona, language, entries; the
  FINGERPRINT is stored as provenance (`doctrine`), never key material.
- core `summary.ts` (poll client; failure cause `network`/`server`) and
  `session-log.ts` (KV `astrology.planet_chat.sessions.v1`, cap 50; resume
  on load re-POSTs `pending` and network-failed records).
- web `log/` (SessionBar, SummaryCard, SessionsScreen, SessionTranscript);
  dice appear on the card when entries carry them; End clears the
  transcript (which clears the dw-4 activation).

**dw-7 (`d2aaf12`)** persona mirror: `planet_chat/persona.py` (pure sheet
over the ten planets: sign, house, dignity + confidence, retrograde, ≤5
aspects marked ally/conflict/fused; `SHEET_POINTS`, `render._REF_POINTS` is
its alias); `voice.py` + `voice_role.txt` (topic `planet_chat_voice` v1,
keyed by topic/VERSION/planet/lang/sheet facts, FINGERPRINT as `doctrine`);
`store.py` second table `planet_chat_voice` (migration 012);
`generation.ensure_planet_chat_voice`; `POST /api/planet_chat/persona` (200 /
202 with sheet / 502 / 503); the turn route reads the voice with
`cached_for` (never enqueues) and render adds `self.read`, `self.marker`,
`self.voice` (all three retired by dw-13; the voice topic became the
character card, `{intro, bias, style}` → `{card, greeting}` v2); the chart-less system prompt is pinned by golden fixtures
`server/tests/fixtures/planet_chat_chartless_{en,zh}.txt`; core `persona.ts`
(`fetchPersona`); web `usePersona`, `PersonaHeader`, `persona.css`, i18n
`persona` namespace.

**dw-9 (`c4342d6`)** spoke instead of writing: `planet_chat/bubbles.py`
pure Segmenter (CHAT 4×3, DEEPER 6×4, provider cancelled at the cap —
restated by dw-13 as a TOTAL sentence ceiling, CHAT 12 / DEEPER 20, no
per-bubble cap);
`shape.*`/`depth.*` fragments after the persona (the only question is one
closing question in the last slip; every slip carries a chart fact or a
detail of the question — retired by dw-13, superseded by the user's
rulings), persona length lines removed; `action:"deeper"`;
core `bubble` guard + device-only `deeper` flag; web `chat/pacer.ts`
(450–1100 ms pauses), Slips, GhostSlip, DeeperChip. One persona entry per
turn; bubbles joined by a blank line.

**dw-8 (`fc38893`)** six characters: `persona.PERSONA_PLANETS` is the one
list (venus, moon, mars, jupiter, saturn, mercury), mirrored by
`models.PlanetChatPersona`, `render.PERSONAS` and core `PERSONA_IDS`
(pinned by `test_persona_lists_agree`); `personas/<id>.txt` ×6 plus
`focus.<id>`; `roster.rules` / `roster.list` / `roster.timing` after
`depth.*` (focus.* and roster.* retired by dw-13: the six and their domains
are one line of `ground.rules`); `personas/dice.txt` = `dice.brief`; `done.handoff` via
`to_wire_handoff`; a pure `POST /api/planet_chat/sheets`; core `roster.ts`
(active character KV `astrology.planet_chat.active.v1`, `fetchSheets`,
`PERSONA_BODIES`); web `roster/` (RosterPicker, useRoster, `roster.css`
`--char` scope), per-character ChatPanel, cards and transcripts,
HandoffSlip. Hand-off to dw-11: `roster.timing` is always emitted; dw-11
owns suppressing it wherever a sky section is present (sky slot after the
chart section, before dice).

**dw-11 (`e81006d`)** read the current sky: `planet_chat/sky.py`
(`SKY_PERSONAS` moon/saturn/jupiter, pure `sky_view` over the memoized
`compute_transits`, `sky_context`); `sky.read`/`sky.marker`/`side.sky`
(`side.sky` retired by dw-10); a
prompt carries exactly one of `roster.timing` and the sky section (slot
chart < sky < dice; the exclusivity went with `roster.timing` at dw-13 —
ground rule 2 covers a prompt without a sky); `main._utcnow` + `transit_instant` resolve the instant
at the route; `test_planet_chat_reads_no_clock`,
`test_sky_personas_are_personas`. The request gains optional
`currentTimezone` (IANA, 422 otherwise; core fills the device zone); no new
event.

**dw-10 (branch `feature/dw-10-phenomenon-pills`, landing pending)** made
every astrological claim a checked pill (user ruling B):

- `planet_chat/tags.py` (pure: stdlib, `app.chart.points`, `.persona`):
  `KINDS` (placement, aspect, transit, dice), `PILL_ASPECT_TYPES` (the
  five — a quincunx transit has no pill), `Ground(chart, sky, rolls)`,
  `check` (equality against the ground, canonical spelling, chart a/b
  order) and `Scanner` (`feed`/`boundary`/`close`, `failures`; malformed
  tags become their inner text; no bracket ever leaves).
- `turn.py`: segmenter deltas → scanner → `_Framer` (`delta` / `pill`
  frames; a `bubble` frame held until its bubble's first item, so an
  emptied bubble collapses); one WARNING per failed tag (kind + reason
  only); `done.chartRefs = to_wire_refs(pill_ref_ids(pills), catalogue)`;
  the side read is mood (+ handoff) only.
- `render.py`: `side.refs`, `side.dice`, `side.sky` deleted;
  `tags.rules`/`tags.natal`/`tags.sky`/`tags.dice` via `tags_section`
  after the dice section (empty with no ground, so the chart-less goldens
  hold); `dice_in_view` on `system_prompt`/`turn_messages`; tag-form
  examples in `chart.read`, `self.read`, `sky.read` (retired by dw-13:
  placeholder syntax only, no sample); `pill_ref_ids`.
- Boundary tests `test_tags_is_pure`,
  `test_only_phenomenon_tags_are_read_from_the_reply`.
- core: `planet_chat/pills.ts` (`Pill`, `isPill`, `pillToken`,
  `splitPills`, `hasPills`, `pillRef`, `pillSource`), the `pill`
  `TurnEvent`, `chart-view` `ASPECT_TONES` (one-definition guard).
- web: `chat/Pill.tsx` (`PillText`, static span / pressable
  `button[aria-pressed]`, id `"<entry>:p<n>"`), `chat/pill-meaning.ts`,
  pills pushed into the pacer as their canonical tokens (stored text, wire
  and session log carry them), `PillNote` meaning line, chip row for
  legacy entries only, `showRefs([], chip)` kept, static pills in
  `SessionTranscript` and `SummaryCard`; i18n `pills` and `lore`
  namespaces (en lore copied from Tier B).

**Hooks dw-1 left for later entries:**

- `App.tsx` has a side-column slot where the chat panel mounts (dw-2).
- The dictionary namespaces let dw-2 add a `chat` namespace without
  touching the others.
- The KV port is shared, so the transcript (dw-2) and the session log
  (dw-6) use the same store.

**Hooks dw-2 leaves for later entries:**

- `turn.turn_events` emits `delta` then `done {mood, chartRefs}` (dw-3);
  dw-5 ✔ sends `dice` first. Core's `streamTurn` ignores unknown events, so
  that is additive; the client's `TurnEvent` union is where new events
  become typed.
- `planet_chat.render.FINGERPRINT` keys nothing; dw-6's summary is its own
  `planet_chat_summary` topic.
- The chat panel lives in `web-divination/src/chat/`; the dice card (dw-5)
  attaches there. `useChat` is the one place that consumes turn events.

**Hooks dw-3 leaves for later entries:**

- dw-4: each stored persona entry carries `chartRefs: ChartRef[]`. A planet
  ref maps to `[data-planet="<body>"]`; an aspect ref's
  `bodyA|type|bodyB` equals `aspectKey` of the matching `chart.aspects`
  entry → `[data-aspect-key]` (the wheel's chart is `POST /api/chart` of
  the same birth data, so the order matches; verified on the real app).
  The chips (`ChartRefChips` in `ChatPanel.tsx`) are press buttons
  (dw-4 ✔).
- dw-5/dw-6: `render.natal_context` is the per-turn chart context; a dice
  brief or summary can reuse it. `FINGERPRINT` now covers the chart
  fragments.

## Reuse map (verified file:line, 2026-09-28)

**Server**

| Need | Existing | Use |
|---|---|---|
| LLM transport | `app/llm.py`: `generate_sections(system, user, schema, lang)` at :668, one-shot, forced JSON. Providers: Anthropic :461, OpenAI-compat :500, LocalClaudeProvider (claude-cli) :605. Resolution at :415; `_backup_mode_active` at :393. | EXTEND. Add multi-turn streaming here only, because rule 3 makes llm.py the single SDK importer. Today no caller is multi-turn and nothing streams outward. |
| Prompt assets | `app/prompts.py`: `register_topic` :129, `.asset` :93, `.fingerprint` :118 | Use as-is. Persona text is a registered asset. |
| Synchronous exception precedent | `/api/ask/fitness` at main.py:385; `ask/fitness.check_bounded` :254 (ThreadPoolExecutor, timeout, `FitnessTimeout` → 503); pinned by `test_main_names_the_one_synchronous_judge` | Copy the shape. The pinning test must name both exceptions. |
| Natal context | `chart/natal/report.py` `natal_report` :12 (chart plus 16-key structure); `dictionary/natal.py` `relevant_meanings` :146; `interpretation/prompt.py` `_restate` :46 | Used by dw-3 through `planet_chat/render.natal_context` (the `_restate` import is the one pinned borrow). |
| Persona and dice seed material | `dictionary/symbols.py` `PLANETS` :14, SIGNS, HOUSES; `dictionary/transit.py` `TRANSIT_PLANETS` :15; `cards/transit/event/visual_dictionary.py` `PLANET_VISUALS` :173 | These give keywords, not persona prose; the persona text is new. Dice faces come from PLANETS/SIGNS/HOUSES (dw-5). |
| Jobs | `app/jobs` `enqueue`, and the `ensure_*` pattern in generation.py: store hit → 200, miss → enqueue + 202; `JOBS_SYNC=1` in tests | Use for the dw-6 summary. |
| Content-keyed store | `interpretation/store.py`: SQLite, or Postgres when `DATABASE_URL` is set; no identity column | Mirror it for the summary store (dw-6), migration 011 (dw-6 ✔). |

**Core** (`@astrace/core`, ships raw TypeScript, browser-ready)

- `platform`:
  - `apiUrl`/`apiFetch` and the poll helpers (`pollDelay`, `isGenerating`,
    `POLL_INTERVAL_MS`).
  - The KV port; web-kv (localStorage) is the default.
  - The stream port `configureStreamPost`/`getStreamPost` and `parseSse`
    (dw-2); the browser adapter is `web-divination/src/platform/stream.ts`.
- `chart`: `subscribeChart` fetches `POST /api/chart` inside core. The app
  never touches the network.
- `chart-view`:
  - `planetFamily(aspects, body)` and `aspectKey`, the activation
    primitive for dw-4.
  - The glyphs and `PLANET_MARKS`.

## Target modules (new, by entry)

```
server/app/
├── llm.py                   dw-2  ✔ stream_turn, all providers
│                                    (claude-cli: stream-json + --system-prompt)
├── planet_chat/              dw-2  a Tier C package parallel to interpretation/cards
│   ├── personas/            dw-2  ✔ venus.txt; dw-8 ✔ six <id>.txt + shared dice.txt;
│   │                                    dw-13 ✔ rewritten as character descriptions
│   ├── render.py            dw-2  ✔ messages + mood side read; dw-3 ✔ natal_context,
│   │                                    ref_catalogue, side_schema, to_wire_refs;
│   │                                    dw-13 ✔ identity/ground.rules/rhythm.*, card=
│   ├── turn.py              dw-2  ✔ bounded streaming turn (the SSE event grammar);
│   │                                    dw-3 ✔ turn_events(request, person), done {mood, chartRefs};
│   │                                    dw-10 ✔ scanner → pill frames, refs from natal pills
│   ├── dice.py              dw-5  ✔ random.SystemRandom roll over the dictionary tables
│   ├── summary.py           dw-6  ✔ summary prompt + schema
│   ├── persona.py           dw-7  ✔ pure persona sheet; dw-8 ✔ PERSONA_PLANETS, sheets_for
│   ├── voice.py             dw-7  ✔ planet_chat_voice topic; dw-13 ✔ character card v2, astro_terms
│   ├── sky.py               dw-11 ✔ SKY_PERSONAS, sky_view, sky_context
│   ├── tags.py              dw-10 ✔ pure phenomenon-tag checker + stream scanner
│   ├── bubbles.py           dw-9  ✔ pure segmenter; dw-13 ✔ total sentence ceiling (12/20)
│   └── store.py             dw-6  ✔ content-keyed summary store; dw-7 ✔ + planet_chat_voice
├── generation.py            dw-6  ✔ + ensure_planet_chat_summary; dw-7 ✔ + ensure_planet_chat_voice
├── models.py                dw-3  ✔ PlanetChatTurnRequest.birthData
├── db/                      dw-16 ✔ the web door (web_is_configured, connect_web, web_health,
│                                    apply_web_migrations, web_config_warning); web_migrations/
│                                    001_web_accounts.sql (five web_ tables, ledger web_schema_migrations)
├── accounts/web/            dw-16 ✔ service.py (Google sign-in + web bearer pair), data.py (profile +
│                                    sessions, always WHERE user_id = caller), routes.py (/api/web/*)
└── main.py                  dw-2  ✔ POST /api/planet_chat/turn (SSE); dw-6 ✔ POST /api/planet_chat/summary; dw-7 ✔ POST /api/planet_chat/persona;
                                     dw-16 ✔ web_router, web migrations at startup, /api/health webDb
packages/core/src/
├── platform/                dw-2  ✔ stream.ts (StreamPost port) + sse.ts (parseSse);
│                                    web adapter in web-divination/src/platform/stream.ts
├── chart-view/spotlight.ts  dw-15 ✔ + spotlightUniformArray, spotlightChord (SPOTLIGHT_SKSL unchanged, sha-pinned)
├── account/google-session.ts dw-16 ✔ /api/web/auth/*, accountId, deleteGoogleAccount
├── web-account/             dw-16 ✔ cloud.ts (/api/web/* client, sessionWire), cache.ts (owner, dirty,
│                                    wipe), sync.ts (AccountData channel, pull, import-once, save scheduler)
└── planet_chat/              dw-2  ✔ types (wire contract), streamTurn, transcript on KV;
                                    dw-3 ✔ ChartRef/isChartRef, birthData, stored refs;
                                    dw-6 ✔ summary + session log on KV;
                                    dw-10 ✔ pills.ts (Pill, splitPills, pillToken, pillRef);
                                    dw-14 ✔ session-log open records: recordEntry,
                                    adoptTranscripts, seal-in-place End (OpenSession | SealedSession);
                                    dw-16 ✔ no cap; parseSessionRecord, replaceSessions, deleteSession,
                                    clearSessions; transcript replaceTranscript
web-divination/src/
├── auth/                    dw-16 ✔ AuthGate waits for account data; ImportCard; useAccountData;
│                                   AccountChip Delete account (session.ts installs web-account)
├── nav/                     dw-14 ✔ the router: routes.ts (pure Route/parseRoute/pathFor/
│                                   canonicalPath), history.ts (THE history/location/popstate
│                                   file, G16), useRoute.ts, Link.tsx
├── app/                     dw-14 ✔ route switch; MainNav, HomeScreen, ChatScreen, NotFound
├── chat/                    dw-2  ✔ panel in the App side slot; dw-3 ✔ ChartRefChips (legacy-only since dw-10); dice card ✔ (dw-5, DiceCard);
│                                   dw-10 ✔ Pill.tsx + pill-meaning.ts (inline pills, meaning note)
├── chart/                   dw-4  ✔ wheel-activation.ts (store + activationFor), data-lit/data-echo/data-active tiers;
│                                   dw-15 ✔ focus.ts (focusFor), data-focus/data-focus-out, the full-chart toggle,
│   └── spotlight/           dw-15 ✔ beams.ts (pure beamsFor/toBoxPx/inkOf), engine.ts (THE canvaskit-wasm
│                                   importer: initCanvasKit, loadEngine, drawBeams, rAF loop), SpotlightLayer.tsx
├── theme/                   dw-15 ✔ rgb.ts (rgb01), motion.ts (useReducedMotion) — leaves (G7)
├── app/ (dw-17)             dw-17 ✔ ChatScreen two panes (#chart-pane | #chat-pane), shell--chat 100dvh column, jump buttons
├── birth-input/             dw-17 ✔ BirthChip + BirthCard popover (BirthSummary deleted); chart/Placements deleted
└── log/                     dw-6  ✔ summary card + history screen; dw-14 ✔ open "In progress"
                                    cards, route-driven reader, "Continue with <name> →";
                                    dw-16 ✔ reader Delete + confirm → deleteSessionEverywhere
```

**Turn event grammar** (dw-2 fixes the exact shapes; later entries only
add events):

| Event | Carries | Added in |
|---|---|---|
| `dice` | `{planet, sign, house}` | dw-5 ✔ first frame, once, only on `action:"cast"` |
| `delta` | `{text}` (non-empty) | dw-2; repeated as the reply is written; dw-10 ✔ never contains `⟦` or `⟧` |
| `pill` | `{kind:"placement", body, sign, house}` \| `{kind:"aspect", bodyA, type, bodyB}` \| `{kind:"transit", transiting, type, target}` \| `{kind:"dice", face, value}` | dw-10 ✔ only ever a PASSED tag check (chart, sky packet or rolls in view); anywhere a `delta` may go, after `dice` and before `done`; a `bubble` may immediately precede it; `transit`/`aspect` types are the five Ptolemaic ones |
| `bubble` | `{index}` (integer ≥ 1) | dw-9 ✔ sent just before the first `delta` (dw-10: or `pill`) of bubble `index`; never first, never after `done`/`error`; `delta` never contains a newline; dw-10: a bubble emptied by the tag filter is collapsed, indices stay consecutive |
| `done` | `{mood, chartRefs}` | dw-2 (`mood`: tender/playful/candid/wistful/radiant or `null`); dw-3 ✔ `chartRefs`: always present, 0–6 unique items, each `{kind:"planet", body}` or `{kind:"aspect", bodyA, type, bodyB}` (chart order), each in the chart of the request's `birthData`; `[]` without birth data or on a failed side read. dw-10 ✔ built from the turn's checked NATAL pills (planet placements, aspects) in order, deduped, cap 6 — no longer from the side read, so a failed side read keeps them |
|  | dw-8 ✔ `done` = `{mood, chartRefs, handoff}`: `handoff` is one of the six ids other than the request's persona, or `null`; always `null` on cast and deeper |
| `error` | `{code}` | dw-2 (`timeout` \| `unavailable`; never after `done`) |

**dw-13 (branch `feature/dw-13-character-chat`, landing pending)** the
planet characters talk like a friend who knows your chart (user rulings
2026-09-29):

- `planet_chat/voice.py` is the CHARACTER CARD job: topic
  `planet_chat_voice` VERSION 2 (same key recipe, table, job kind and
  route), `{card, greeting}`; the card (English, second person,
  about 2,800–3,800 chars — a prompt TARGET since the 2026-09-29 rework,
  never a rejection) is a person drawn from the placement with NO astro
  vocabulary (`ASTRO_TERMS`/`astro_terms`, zh list in code for greetings;
  own name allowed in the greeting); ≤3 attempts with the rejected terms
  fed back; `base.<id>` registers each persona file on the voice topic.
  The card is server-only; the persona wire is `schemaVersion 2`,
  `voice: {greeting}`.
- `render.system_prompt(…, card=…)`: `identity` → card (else the
  `personas/<id>.txt` base, rewritten as character descriptions) →
  `ground.rules` (five lines) → `rhythm.chat`/`rhythm.deeper` → chart / sky
  / dice data → tag block → lang. Retired: `shape.*`, `depth.*`, `self.*`,
  `roster.*`, `focus.*`, `chart.none`; the sheet JSON left the turn. Every
  planet chat prompt is CJK-free and sample-free (tests P1/P2); the card is
  at least as long as the shared instruction text (P5 tiers
  1,900/2,300/2,800).
- `bubbles.Budget(sentences)`: a TOTAL sentence ceiling, CHAT 12 / DEEPER
  20; a line break ends a bubble; no per-bubble cap.
- core `PersonaVoice {greeting}`; web opening letter = greeting prose;
  `VoiceAside` and `persona.biasLabel` removed.
- Lab: `server/tests/prompt_lab/planet_chat_lab.py` (live, not
  collected) + `planet_chat_metrics.py` (unit-tested); transcripts in
  `pipeline/logs/dw-13-character-chat/transcripts/` (baseline, run-01…04;
  final run-03).

**dw-15 (branch `feature/dw-15-wheel-spotlight`, landing pending)** the
web wheel glows with native's shader and focuses on the picked character:

- core `chart-view/spotlight.ts` gains `spotlightUniformArray` (the
  positional order CanvasKit binds) and `spotlightChord(aspect, chart,
  rHub)` (wheel-unit endpoints + bow; conjunction at `midLongitude`).
  Native `spotlightLineFor` delegates to it (the 0° Aries conjunction
  midpoint is fixed there too). `SPOTLIGHT_SKSL` is byte-identical,
  sha256-pinned.
- web `chart/spotlight/engine.ts` compiles `SPOTLIGHT_SKSL` in
  CanvasKit-WASM (`canvaskit-wasm` 0.41.0, lazy, host probe first) and
  draws per-beam shaders over bbox rects in its own rAF loop;
  `SpotlightLayer` lays one `aria-hidden`, `pointer-events:none` canvas
  over the SVG disc, never mounted (nor CanvasKit loaded) under reduced
  motion or with no beams; `.chart-stage[data-spotlight]` reads
  `static`/`loading`/`live`, and `live` drops dw-4's SVG drop-shadow on lit
  chords.
- `beamsFor`: voice beams (glow 1) for a lit activation, else focus beams
  (glow 0.6) for the character's planet family, none on the full chart at
  rest; ≤ 12 by orb.
- Focus: `<ChartStage persona={active}>`; `focusFor` hides out-of-family
  chords/dots and ghosts planets/nodes (`data-focus-out`), a pill outside
  the family still shows; `button[data-focus-toggle]` "Show full chart" /
  "Focus on {name}" (page-session state, reset on a different character).
- Guards: one-definition enumeration + G14 (one shader text) + G15 (one
  `canvaskit-wasm` importer, no exemption); CLAUDE.md rule 1 amended.

**dw-14 (branch `feature/dw-14-web-navigation`, landing pending)** real
URLs, a way home, and a session log that records as you talk:

- Routes `/` (Home: the six plates as a page + the birth card, no wheel),
  `/chat/<id>` (the wheel, spotlight on that character, and its chat),
  `/sessions`, `/sessions/<id>`; anything else is not found in the shell
  (never a redirect). In-house router in `web-divination/src/nav/` (no
  dependency); Vite's SPA fallback serves every path.
- Masthead on every signed-in route: wordmark → `/`, a running head "The
  six" · "Sessions · n" (`aria-current`), the account chip. Titles per
  screen; heading focus after a push only (`history.lastChange()`, SG1).
- The stored active character means only "last spoken with" (a "last"
  mark on Home); the chat's character comes from the URL; hand-offs and
  examples seed then push.
- Core session log: `OpenSession` headers whose entries are the live
  transcript; `recordEntry` (the chat's only write, G17), `adoptTranscripts`,
  End seals the SAME record in place; open records never evicted.
- Guards G16 (navigation globals only in `nav/history.ts`) and G17 (no
  `appendEntry(` in web code); CLAUDE.md routing sentence.

**dw-17 (branch `feature/dw-17-web-two-pane-layout`, landing pending)** the
chat route as two equal panes (web only):

- `/chat/<id>`: `main.layout--chat[data-birth]` > `section#chart-pane`
  (`data-slot="stage"`: the birth chip over `ChartStage`, or the birth form
  alone while nothing is saved) + `aside#chat-pane` (`data-slot="side"`:
  `SessionBar`, then `ChatPanel` filling the height). The shell is
  `shell--chat`, a `100dvh` flex column: the page never scrolls, the
  transcript does (`.chat__log` flex-filled; the 60vh cap is gone). ≥ 960 px:
  two `minmax(0, 1fr)` columns, a `--line-soft` divider, the disc sized by
  container units. < 960 px: the layout is one scrolling column, chat first
  (form first while nothing is saved), `button[data-jump]` jumps via
  `scrollIntoView` (no hash, no history entry).
- `chart/Placements.tsx` (Big Three + placement rows) and
  `birth-input/BirthSummary.tsx` deleted with their CSS and Placements-only
  i18n keys; `chart/format.ts` kept.
- `birth-input/BirthChip.tsx` (new): `button[data-birth-chip]` ☉ date · place;
  `BirthCard` opens `BirthForm` in a non-modal `role="dialog"` popover
  (focus in/out, Escape, Cancel, mousedown-outside) — on Home's colophon too.
  New i18n `form.birthChipLabel`, `form.birthDialog`, `layout.toChart`,
  `layout.toChat`. No new dependency, core import, guard or edge beyond
  `app/ChatScreen → birth-input/useBirthData` and `→ theme/motion`.

**dw-16 (branch `feature/dw-16-web-account-db`, landing pending)** the web
app's data belongs to the account, in its own database (user rulings
2026-09-29):

- `WEB_DATABASE_URL`: a separate Postgres behind `app/db`'s second door
  (`web_is_configured` — set AND ≠ `DATABASE_URL` —, `connect_web`,
  `web_health`, `apply_web_migrations`, `web_config_warning`), its own
  folder `db/web_migrations/` and ledger `web_schema_migrations`; five
  `web_` tables (`web_users`, `web_access_tokens`, `web_refresh_tokens`,
  `web_birth_profiles`, `web_sessions` keyed `(user_id, id)`). `/api/health`
  adds `webDb`.
- `server/app/accounts/web/` (the ONLY per-user web data): the Google
  sign-in moved here from the main db (`/api/auth/google` and
  `service.sign_in_google` removed), `/api/web/auth/{google,token/refresh,
  whoami,logout}`, `DELETE /api/web/account` (cascade),
  `/api/web/profile`, `/api/web/sessions[/{id}]`. 503 without the web db.
- core `web-account` (new barrel): the browser copy is a cache owned by
  one account (`astrology.web.owner.v1`); on sign-in flush the dirty set →
  pull (other owner: wipe first; old unowned data: ask once — Import /
  Discard); saves every changed record (300 ms coalesce, one in flight per
  record, dirty set `astrology.web.dirty.v1` persisted, tombstones for
  deletes); an owned cache is wiped at sign-out. The session log lost its
  50-record cap.
- web: `AuthGate` waits for `ready` ("Opening your sky…", error + Try
  again, `ImportCard`); Sessions reader Delete; account chip Delete account.
- Guards B1–B4 in `test_boundaries.py`; `web-account` in the jest
  deep-import alternation. CLAUDE.md rules 3, 6, 11, 12 amended.

**dw-18 (branch `feature/dw-18-divination-auth`, landing pending)** the
web's planet chat routes need a signed-in web account (user request
2026-09-29, before deploy; closes the public LLM-spend hole):

- Server: `accounts/web/routes.py` `require_web_account` (the `_caller`
  check as a dependency returning None) on the four `/api/planet_chat/*`
  decorators in main.py. It gives 503 when the web db is dormant and 401 for
  a missing, bad, expired, unknown or native token, before any chart, store
  read, enqueue or LLM call (a cached hit too). Malformed JSON is the
  framework's 422, with no work done.
- Core: `postJson(…, timeoutMs?, {auth: true})` goes through `apiFetch`
  (bearer and one refresh) and reports a final 401. `streamTurn` sends the
  bearer, drains a refused body, refreshes once and retries. A final 401
  gives `error {unauthorized}` plus a report. `onUnauthorized` and
  `reportUnauthorized` live in `platform/auth.ts`, and
  `account/google-session.ts` subscribes to them (clear tokens → signed-out
  → the gate and the owned-cache wipe).
- Web: `useChat` shows no error and no Retry for `unauthorized`.
- Tests: `test_planet_chat_auth.py` (no override; live on
  `TEST_WEB_DATABASE_URL`) and S5 in `test_boundaries.py` (flattened route
  walk). Existing planet chat route tests run under a conftest stub limited
  to their module list.

**dw-19 (branch `feature/dw-19-rename-planet-chat`, landing pending)** the
feature is renamed `planet_chat` / "Planet Chat" everywhere in live code
(tier-1 user ruling 2026-09-29); the epic's display name is now the PLANET
CHAT WEB EPIC (this file keeps its path). No behaviour changed:

- Names: server `app/planet_chat/`, routes `/api/planet_chat/{turn,summary,
  persona,sheets}` (the old prefix is a 404, no alias), models
  `PlanetChat*Request`/`PlanetChatPersona`, core `@astrace/core/planet_chat`,
  env `PLANET_CHAT_TURN_TIMEOUT_S`, tests `test_planet_chat_*.py` and web
  `core-planet-chat*.test.ts`. The `web-divination/` folder and package keep
  their name (recorded exception).
- Data bridges: the content keys keep the pre-rename topic strings as frozen
  key material (`summary.SUMMARY_KEY_TOPIC`, `voice.VOICE_KEY_TOPIC`; golden
  hex from bd158b2 pinned), so every cached summary and character card is
  still a hit; migration 013 renames the two Postgres tables and every
  constraint named after them; the SQLite store adopts the pre-rename file and
  tables on first use (`store._adopt_legacy_file`, locked, once per path);
  core `planet_chat/legacy-keys.ts` moves the three browser keys on the first
  KV touch and the account wipe clears any left; the old env name is a
  one-release fallback with one WARNING.
- Guards: every guard naming the feature was renamed with its assertion
  intact; the new rename guard (`server/tests/test_rename_guard.py` +
  `app-native/src/rename-guard.test.ts`) scans every live file against ONE
  allowlist, the repo-root `rename-allowlist.json`, and fails on an unused
  entry.

The request gained `birthData: BirthData | null` (dw-3; absent = null).
The request gained `action` (dw-5; absent = chat); dw-9 ✔ adds `action:"deeper"` (422 unless the transcript ends on a persona reply). Order: `dice`? → (`delta` | `pill` | `bubble`)* → `done` | `error` (dw-10: a `bubble` only before a `delta` or `pill` of its bubble).
Between frames the server may send `: keepalive` SSE comments (one per idle
second); the core parser ignores them. Non-stream answers: 422 on any request
limit and a JSON 503 `planet chat unavailable` with no provider. The client adds
three codes of its own: `invalid` (422), `network` and `interrupted`.

## Dependency rules for this epic

- `planet_chat` may import chart, dictionary, llm and prompts, like
  interpretation does.
- ❌ `planet_chat` must not import `interpretation` or `cards`. The one
  exception (dw-3): `from app.interpretation.prompt import _restate` in
  `planet_chat/render.py` only, pinned by
  `test_planet_chat_borrows_only_the_restate_helper`.
- ❌ `interpretation` and `cards` must not import `planet_chat`.
- ❌ No conversation state in `planet_chat/` (dw-16 narrowed this from "on
  the server": the signed-in web account's chats are saved by
  `accounts/web/` in the separate web db — B3 keeps `planet_chat/` off
  accounts and `accounts/web/` off planet_chat):
  - no session table and nothing keyed by user in `planet_chat/`;
  - the client owns the transcript and sends it with every turn;
  - the dw-6 summary store is content-keyed, with no identity;
  - the journal is untouched (rules 6 and 9).
- dw-18 ✔ The web's planet chat routes require a signed-in web account:
  main.py attaches `accounts/web`'s `require_web_account` to every
  `/api/planet_chat/*` route as a decorator-level dependency (503 dormant web
  db, 401 not signed in — before any chart, store read or LLM work); no
  identity enters `planet_chat/`, a job, a store or a cache key, and no
  handler takes a user parameter. Pinned by
  `test_s5_every_planet_chat_route_requires_a_web_account` (flattened route
  walk, planted-route self-checks). This narrows dw-12's "`planet_chat/`,
  `chart/` and main.py's non-auth routes never read `Authorization`":
  `planet_chat/` and `chart/` still never do; main.py's planet chat routes do,
  through the dependency. Client side, core `planet_chat` sends the bearer
  (postJson `{auth:true}` / streamTurn's header) and signals a final 401
  through `platform`'s `reportUnauthorized` — ❌ core `planet_chat` never
  imports `account`; `account/google-session.ts` hears `onUnauthorized` and
  signs out.
- dw-19 ✔ No new edges. The name is `planet_chat` in live code; the old
  word survives only where `rename-allowlist.json` records it (a new
  exception is an allowlist entry with its reason, never a looser pattern).
- The web tree keeps dw-1's guards: core through barrels only, no network
  outside `src/platform/`, no astrological arithmetic, colours only in
  `theme/tokens.ts`, no imports between the web and native apps.
- New prompt text is fingerprinted as provenance: the FINGERPRINT is
  recorded beside each row (`doctrine`) and is never key material;
  rewriting stored summaries is a deliberate VERSION bump.

- The character card (dw-13; the dw-7 voice store, reused) is keyed by the
  sheet's facts, never by identity or birth data, and never leaves the
  server. `turn.py`/`render.py` never import summary, store or voice (the
  route hands the card string in); `persona.py` is pure.
- The bubble budget is a total sentence ceiling per action (chat 12,
  deeper 20); a line break ends a bubble (dw-13).

- dw-8 ✔ core `roster.ts` and web `roster/` hold the character roster; theme keeps its own id copy (guard G7), bound by a test.
- dw-15 ✔ `web-divination/src/chart/spotlight/engine.ts` is the ONLY
  `canvaskit-wasm` importer in the walked trees (G15; native's jest
  environment `app-native/jest/skia-env.js` is outside the walk), and the
  spotlight shader text exists only in core (G14). New edges:
  `chart/ChartStage → @astrace/core/planet_chat` (PERSONA_BODIES),
  `chart/spotlight/* → theme` (tokens, rgb, motion), `chart/spotlight/engine
  → canvaskit-wasm`. `theme/rgb.ts` and `theme/motion.ts` import only
  `react` and siblings. The persona reaches `chart/` as a prop — chart/
  still imports neither chat/ nor roster/.
- dw-14 ✔ `nav/` is a leaf: it imports only `react`, the
  `@astrace/core/planet_chat` barrel and its siblings (no feature folder, no
  `i18n/`). `roster/`, `chat/` and `log/` import only `Link` and `pathFor`
  from it. No feature folder, and not `nav/`, imports `app/` — except the
  existing `auth/AuthGate.tsx` → `app/Header` edge (review rules, no guard).
  Only `nav/history.ts` uses the `history`/`location` globals or names
  `popstate` (G16); no web production file calls `appendEntry(` (G17).
