# dw-6-session-log — every session ends as a card

Epic: `pipeline/epics/divination-web.md` (cited throughout; this spec
writes only dw-6's delta). Wave: parallel with dw-4 and dw-5, built on the
dw-3 base (`2f45dfb`), landed LAST of the three.

## Goal

The user ends a conversation with Venus and gets a summary card (the
question, persona, chart refs, dice, emotional tone). The session lives in
a device-local log whose history screen reopens any past transcript
(QUEUE.md `dw-6-session-log`).

## Non-goals

- The generated emotional card IMAGE (`cards/emotion/`, a completion hook,
  `GET /api/analysis/card/{key}`). It is a later entry.
- Continuing a closed session. A reopened transcript is read-only.
- Deleting, renaming, searching, exporting or syncing sessions. There is
  no server-side session list and no account link.
- Any change to the turn: its route, `turn.py`, `render.py`, the event
  grammar and the chat panel (`chat/*`) stay byte-identical.
- Re-summarising in another language. A card keeps the language it was
  sealed in.
- Dice behaviour. dw-6 reads dice if an entry carries them. It never
  rolls, types or renders dw-5's dice card.
- Hosting, CORS or deploy work (epic: local only).

## Decided defaults

**D1 Session.** A session is the persona's live transcript
(`astrology.divination.transcript.v1.venus`), from the first message after
the last End. Ending it archives a copy into the log, then clears the live
transcript, and the chat shows only the greeting.

**D2 When End is enabled.** When the transcript holds at least one persona
entry AND its last entry is a persona entry. A turn in flight or an
unanswered user line leaves the last stored entry a `user` entry (useChat
appends the persona entry only on `done` or on a stop with text). That is
how End stays disabled mid-turn without reading chat state, and why a
failed turn must be retried before ending.

**D3 What the server writes, what the device knows.** The server
generates three fields: `question` (the session's central question, one
line, in the session language), `tone` (one of the closed six below) and
`toneNote` (one sentence on the session's emotional arc). The card's
`persona`, `chartRefs` and `dice` are facts the device already stores on
the entries. They are derived on the device from the archived entries:
- refs: the union of the persona entries' `chartRefs`, first-seen order,
  capped at 8;
- dice: every persona entry's well-formed `dice`, in order.

The server is never asked to echo them.

**D4 Tones.** `hopeful`, `uneasy`, `tender`, `torn`, `resolved`,
`wistful`. They are a closed enum on both sides and translated at the
render edge. Any other value is a failed summary.

**D5 Language.** The summary language is the UI language at End. It is
stored on the record and never regenerated.

**D6 What is sent.** The record's entries go through core's existing
`toWire`, so the per-entry wire shape is the turn's own. At most 40
entries are sent (the turn's cap). A longer session sends its first 2
entries (the opening exchange) and its last 38. No birth data, no id, no
timestamps.

**D7 Dice before and after dw-5.** The request model REUSES
`DivinationTranscriptEntry`, and the key and prompt serialise each entry
with `model_dump(exclude_none=True)`. Before dw-5 an entry is `{role,
text}`. Once dw-5 lands, `toWire` emits `dice` on persona entries and
dw-5's model accepts them. The dice then reach the summary prompt and
key with no dw-6 edit, and a dice-free entry hashes as before. On the
device, `sessionFacts` reads `dice` structurally as `{planet ∈ BODIES,
sign ∈ SIGNS, house integer 1–12}`, so it compiles and works against
either `TranscriptEntry`. Before dw-5 the card's dice row never renders.
The seeded-record tests cover it.

**D8 The content key follows the 2026-08-13 doctrine.** The key is
sha256 over the topic name and `VERSION` plus the persona, language and
entries. The prompt FINGERPRINT is recorded beside the row (`doctrine`)
and is NOT key material. The code states this as law (`prompts.py:21`,
`interpretation/service.py:88`, `ask/store.py`), and the epic's "a
persona edit changes the cache key" contradicts it. The code wins (epic
header), and the epic line gets fixed at docs-sync. Rewriting summaries
is a deliberate VERSION bump. The epic's FINGERPRINT hook
(`render.FINGERPRINT`) goes unused: the summary is its own prompt topic.

**D9 Delivery.** A store hit answers 200. A miss enqueues the job and
answers 202. A failed job answers 502. With no provider configured, a
miss answers 503 and enqueues nothing, while a stored hit is still
served. The device polls with core's `postJson`/`pollDelay`/`MAX_POLLS`.
- 200 with a valid body: the card becomes `ready`.
- 202: poll again after `POLL_INTERVAL_MS`.
- Anything else (including an invalid 200 body and an exhausted budget):
  the card becomes `failed`.

A failed card shows Retry. A `pending` record left by a reload or a
server restart resumes polling when the log first mounts (poll = ensure).

**D10 The log.**
- One KV key, `astrology.divination.sessions.v1`. It is not
  profile-namespaced, like the transcript.
- It holds up to 50 records, newest first; the 51st evicts the oldest.
- A corrupt value reads as empty and never throws.
- The server keeps no list and no identity. The journal is untouched.

**D11 The history screen.** A view swap in `App`, with no router.
- "Sessions · n", above the chat, replaces the chart layout with the
  Sessions screen; "← The chart" returns.
- A reload always opens on the chart.
- On a wide screen (≥ 900 px) the screen shows the card list and a
  reader side by side. On a narrow one the reader replaces the list and
  offers "← All sessions".

**D12 Visual design ("the sealed plate").** Every colour comes from the
existing tokens; no token is added.
- **Card.** A panel with a hairline border.
  - A ♀ wax seal (a `venus` ring) sits top-left. It presses in once
    (scale 1.15 → 1, 420 ms) when the summary lands.
  - Above the question: an eyebrow with the persona name and the local
    end date, in small caps.
  - The question is the hero: the display serif, italic, about 1.35 rem,
    in curly quotes.
  - Under a hairline come the rows. Chart seals are glyphs only (planet
    glyph, or glyph · aspect glyph · glyph), labelled for screen readers.
    Dice are planet glyph · sign glyph · house number, shown only when
    there are dice.
  - A footer carries the tone word in `venus` small caps, then the
    `toneNote` in dim italic.
- **Pending card.** It shows the opening user line (faint italic) where
  the question will be, and the three-star "Venus is sealing this
  session" motif.
- **Failed card.** It shows the opening user line, "Venus could not seal
  this one" and Retry.
- **List.** Each card is one button whose accessible name is its
  question (or opening line) and date. It has a gold focus ring.
- **Reader.** The card, then the transcript as letters: persona prose
  under a ♀ eyebrow with its mood and seals, and user lines in right-set
  italic.
- **Motion.** A reduced-motion setting removes the press and the shimmer.
- **Empty screen.** "No sessions yet — end a conversation with Venus to
  keep it here."

**D13 Wave footprint.** See Architecture → Shared files. dw-6 touches no
file in `chat/`, `chart/` or `theme/`, and not `turn.py`, `render.py` or
core `types.ts`.

## Architecture

### Reuse (verified 2026-09-28)

| Need | Existing | Use |
|---|---|---|
| Store shape | `interpretation/store.py:37-175`: `DB_PATH`, `_connect`, `put`/`get` with a `db_path` that forces SQLite, `db.is_configured()` choosing Postgres, and the `doctrine` column | Mirror it, with one table |
| Migration runner | `db/migrations.py:19` (lexical `NNN_*.sql`); highest is `010_analysis_doctrine.sql` | Add `011_divination_summary.sql` |
| Job kind | `generation.py:153-181` `ensure_transit_reading` (a key known before generating, enqueue, return the key); `job_status` :147 | Copy the shape |
| 200/202 route | `main.py:197-226` `analysis` (hit, ensure, re-read, failed → 502, 202) | Copy the shape |
| Keyless gate | `divination/turn.turn_available` :56 | main.py already imports `divination_turn` |
| One-shot LLM | `llm.generate_sections` :857 | The summary call |
| Prompt topic | `prompts.register_topic` :129, `.asset`, `.fingerprint` | A new topic `divination_summary` |
| Entry model | `models.py:332` `DivinationTranscriptEntry` | Reused as is (D7) |
| Wire entries | core `divination/transcript.ts` `toWire` | Reused as is (D6) |
| Poll mechanics | core `platform/poll.ts` `postJson`, `pollDelay`, `isGenerating`, `POLL_INTERVAL_MS`, `MAX_POLLS`; loop shape in `analysis/service.ts:93-120` | Copy the shape |
| Device-log shape | `core/cards/shown-store.ts` (KV JSON array, cap + evict, corrupt → [], listeners) | Mirror it |
| Ref and mood guards | core `divination/types.ts` `isChartRef`, `chartRefsOf`, `isMood`; `chart/types.ts:17` `SIGNS` (core-internal import, precedent `chart-view/frame.ts:18`) | Reuse |
| Glyphs | `@astrace/core/chart-view` `PLANET_GLYPHS`, `SIGN_GLYPHS`, `ASPECT_GLYPHS`, `ASCENDANT_GLYPH` | Reuse |

### Module map (created or changed only)

```
server/app/
├── divination/summary.py         NEW  topic divination_summary; key, prompt, generate, cached, to_wire
├── divination/summary_role.txt   NEW  the summary role (asset)
├── divination/store.py           NEW  the content-keyed summary store (the ONE stateful divination module)
├── divination/__init__.py        docstring: two modules; "stateless except store.py"
├── generation.py                 + DIVINATION_SUMMARY_PRIORITY = 1, ensure_divination_summary
├── models.py                     + DivinationSummaryRequest (appended at EOF)
├── main.py                       + POST /api/divination/summary
└── db/migrations/011_divination_summary.sql   NEW
server/tests/
├── test_divination_summary.py    NEW
├── test_boundaries.py            fence, no-state and importer pins evolve (below)
└── conftest.py                   + redirect divination store DB_PATH
packages/core/src/divination/
├── summary.ts                    NEW  wire types, TONES/isTone, summaryWire, fetchSummary
├── session-log.ts                NEW  the device log + sessionFacts + canEndSession
├── transcript.ts                 + clearTranscript (appended at EOF)
└── index.ts                      + one appended export block
web-divination/src/
├── log/useSessions.ts            NEW  the hook; resumes pending summaries once on mount
├── log/SessionBar.tsx            NEW  End session + "Sessions · n" + the just-sealed card
├── log/SummaryCard.tsx           NEW  pure presentation
├── log/SessionsScreen.tsx        NEW  list + reader
├── log/SessionTranscript.tsx     NEW  read-only letters
├── log/log.css                   NEW
├── log/*.test.ts(x)              NEW  incl. core-session-log.test.ts
├── app/App.tsx                   view state; SessionBar above ChatPanel; the screen swap
└── i18n/{en,zh}.ts               + `log` namespace inserted BEFORE `chat`
CLAUDE.md                         rules 9, 10, 11 (below)
```

### Module contracts

**`divination/summary.py`** imports `app.llm`, `app.prompts` and `.store`.
- `NAME = "divination_summary"`, `VERSION = 1`, `PROMPTS` holding
  `role` (the asset), `lang.en` and `lang.zh`, and `FINGERPRINT`.
- `TONES` (D4). `SUMMARY_SCHEMA` has `question`, `tone` (an enum of
  TONES) and `toneNote`, all required, with no additional properties.
- `summary_key(req) -> str`: 64-hex sha256 of `json.dumps({"topic":
  NAME, "version": VERSION, "persona", "lang", "transcript":
  [e.model_dump(exclude_none=True) …]}, sort_keys=True,
  ensure_ascii=False, separators=(",", ":"))`. It uses no identity, no
  birth data and no FINGERPRINT.
- `summary_prompt(req) -> (system, user)`. The system text is the role
  plus the lang line. The user text is the JSON of `{persona,
  transcript}`, in the same dump as the key.
- `generate_summary(req, *, db_path=None) -> dict`, the generator (the
  job's body). It calls `generate_sections` and validates the result:
  - `question` and `toneNote` are stripped and must be non-empty; they
    are cut to 200 and 240 characters;
  - `tone` must be in TONES;
  - any breach raises `AnalysisUnavailable`.

  On success it calls `store.put(key, result, doctrine=FINGERPRINT)`.
- `cached_summary(req) -> dict | None` and `to_wire(result) -> dict`
  (which drops `model` and `promptVersion`).

**`divination/store.py`** imports `json`, `sqlite3`, `pathlib` and
`from .. import db`.
- `DB_PATH = server/data/divination.db`.
- SQLite and Postgres both use table `divination_summary`
  (`summary_key` PK, `summary` JSON text of the three generated fields,
  `persona`, `lang`, `model`, `prompt_version`, `created_at`,
  `doctrine`). There is NO identity column, ever.
- `put(key, result, *, doctrine, db_path=None)` overwrites.
  `get(key, *, db_path=None) -> dict | None`.
- The backend choice is exactly `interpretation/store.py`'s. It never
  reads clocks; the caller sets `generatedAtUtc`.

**`generation.ensure_divination_summary(req, *, db_path=None) -> str`**
enqueues `Job(kind="divination_summary",
key=f"divination_summary:{summary_key(req)}", priority=1,
run=lambda: generate_summary(req, db_path=db_path))` and returns the key.

**`models.DivinationSummaryRequest`** has `persona: Literal["venus"]`,
`lang: Literal["en","zh"]` and `transcript:
list[DivinationTranscriptEntry]` (1–40 items). A model validator
requires at least one `user` and one `persona` entry. Each violation is a
422.

**Route `POST /api/divination/summary`** (`divination_summary` in
main.py):
1. `cached_summary` hit → 200 `to_wire`.
2. `not turn_available()` → 503.
3. Otherwise `ensure_divination_summary`, then re-read (hit → 200).
4. A failed job → 502; else 202.

main.py names neither `generate_summary` nor `generate_sections`.

**core `summary.ts`**
- `TONES`, `Tone`, `isTone`.
- `SummaryRequest = {persona, lang, transcript: WireEntry[]}`.
- `SummaryWire` (the 200 below).
- `summaryWire(entries)`: D6's selection, then `toWire`.
- `fetchSummary(req, signal) -> Promise<SummaryWire | null>` runs the
  poll loop. It returns null on any failure and never throws.

**core `session-log.ts`**
- Types:
  - `SessionRecord = {id, persona, lang, endedAtUtc, entries:
    TranscriptEntry[], summary}`;
  - `summary = {status:'pending'} | {status:'failed'} |
    {status:'ready', question, tone, toneNote, generatedAtUtc}`.
- Functions:
  - `canEndSession(entries)` (D2);
  - `endSession(persona, lang) -> SessionRecord | null`: it writes the
    record (`pending`), calls `clearTranscript`, then starts the loop;
  - `listSessions()`: a stable snapshot, newest first;
  - `getSession(id)` and `subscribeSessions(cb)`;
  - `resumeSummaries()`, idempotent: it keeps one in-flight loop per id;
  - `retrySummary(id)`;
  - `sessionFacts(entries) -> {chartRefs, dice}` (D3, D7).
- Constants: `SESSION_LIMITS = {sessions: 50, refs: 8}`.
- `id` is `s-<epoch ms>`, bumped by 1 ms if it is taken. It uses no
  Web global and no randomness.
- Parse keeps each entry that has a valid role and text verbatim, so
  dw-5's `dice` survives in the log.

**`transcript.clearTranscript(persona)`** removes the key and notifies
the transcript's listeners.

**web `log/`** reads only through the `@astrace/core/divination` and
`chart-view` barrels and the i18n. It owns no network and no colour
literal. `SummaryCard` is pure; state comes from `useSessions` and
`useSyncExternalStore` over the transcript (for D2). `App.tsx` holds
`view: 'chart' | 'sessions'` in React state.

### Wire

```
POST /api/divination/summary
{"persona":"venus","lang":"en","transcript":[{"role":"user","text":"…"},
 {"role":"persona","text":"…"} …]}            ← +"dice" on persona entries once dw-5 lands
200 {"schemaVersion":1,"persona":"venus","lang":"en","question":"…",
     "tone":"torn","toneNote":"…","generatedAtUtc":"2026-09-28T…Z"}
202 {"status":"generating"}
422 (FastAPI detail) | 502 {"detail":"summary unavailable"} | 503 {"detail":"divination unavailable"}
```

### Dependency rules and forbidden edges

- `divination/store.py` → `app.db` is the ONE stateful divination edge.
  The fence (`DIVINATION_FORBIDDEN_RE`) stays unchanged. The
  `_divination_fence_offenders` strips `from .. import db` from
  `divination/store.py` only, the same mechanism as the restate borrow,
  and a self-check plants that line in `turn.py` and expects it caught.
- `test_divination_keeps_no_state` evolves without weakening:
  - every divination file EXCEPT `store.py` still matches nothing;
  - `store.py`'s SQL names the table `divination_summary` only, and its
    CREATE TABLE column list equals the pinned list above, so no identity
    column can appear;
  - migration 011 is pinned to the same column list.
- ❌ `turn.py` and `render.py` never import `summary` or `store`. The
  streamed turn stays stateless (a new pin).
- `test_no_tier_imports_divination`: the importers are exactly
  `{main.py, generation.py}`, like the ask package's sanctioned pair.
- `GENERATE_ON_REQUEST_RE` gains `generate_summary`; main.py names only
  `cached_summary`, `to_wire` and `generation.ensure_divination_summary`.
  `test_main_names_the_synchronous_exceptions` is unchanged: this route
  is ordinary rule 14, not an exception.
- ❌ No identity anywhere: no user, profile, session or IP column; no
  birth data on the request; the journal is untouched.
- Core: `session-log` → `summary`, `transcript` and `../platform` (KV,
  poll); `summary` → `../platform`. Neither names `fetch`, `window` or
  `localStorage`. Web `log/` ↛ `chat/` and `chat/` ↛ `log/`.

### Amendments (same commit)

- CLAUDE.md rule 9: one sentence. The divination summary store
  (`divination/store.py`, `data/divination.db` / `divination_summary`)
  is a second content-keyed, identity-free cache, keyed by topic
  (name, VERSION), persona, language and entries, never by identity.
- Rule 10: divination is stateless except `store.py`; generation.py may
  import divination for the summary job.
- Rule 11: the importers list adds `divination/store`.
- Rule 14 needs no edit.

### Shared files (landing-conflict surface)

- **With dw-5:** `models.py` (appended at EOF after dw-5's edits),
  `divination/__init__.py` (docstring bullets), core `divination/index.ts`
  (an appended block), `i18n/{en,zh}.ts` (the `log` block inserted before
  `chat`; dw-5 appends inside `chat`), and CLAUDE.md rule 10 (one
  sentence each).
- **With dw-4:** none. It touches `app/App.test.tsx`; dw-6 puts its
  integration tests in `log/`.
- **Nobody else touches:** `App.tsx`, `main.py`, `generation.py`,
  `test_boundaries.py`, `conftest.py` and `transcript.ts` (dw-5 edits
  `sanitize`/`toWire`; dw-6 appends at EOF).

## Acceptance Criteria

Server tests use a monkeypatched `llm.generate_sections` only.
`JOBS_SYNC=1` applies except where stated. Run `npm run server:test`,
`npm test` and `npm run typecheck`. `T` is a valid four-entry request
(user, persona, user, persona; lang `en`).

**Server**
- **S1 (key)**: `summary_key(T)` is 64 lowercase hex characters and is
  stable across calls. Changing any entry's text, the order of entries,
  `lang`, or `summary.VERSION` (monkeypatched) changes it. Monkeypatching
  `summary.FINGERPRINT` does not. Every
  `e.model_dump(exclude_none=True)` of T's entries has exactly the keys
  `role` and `text`. `DivinationSummaryRequest` has no `birthData` field,
  and a body carrying `birthData` gives the same key as one without it.
- **S2 (hit and miss)**: The first POST of T answers 200 with exactly
  the keys `schemaVersion`, `persona`, `lang`, `question`, `tone`,
  `toneNote` and `generatedAtUtc`, and the fake is called once. A second
  identical POST answers 200 with an equal body and the fake is not
  called again.
- **S3 (202)**: With `JOBS_SYNC` removed and a fake that blocks on an
  event, the first POST answers 202 `{"status":"generating"}` and a
  second answers 202 with no second job enqueued. After the event is
  released and the job finishes, the POST answers 200.
- **S4 (prompt)**: The fake gets a system text containing
  `summary_role.txt` and then the `lang.en` fragment (`lang.zh` for a zh
  request) and the schema `SUMMARY_SCHEMA`, whose `tone.enum` equals
  `TONES`. Its user text parses as JSON: `{persona, transcript}`, whose
  transcript equals T's entries in order.
- **S5 (bad output)**: A fake returning `tone:"ecstatic"`, or a blank
  `question`, makes the POST answer 502 `{"detail":"summary
  unavailable"}` and stores no row. A 300-character question is stored
  and served as its first 200 characters.
- **S6 (422)**: These each answer 422 and call no fake: persona `mars`;
  lang `fr`; an empty transcript; 41 entries; only `user` entries; only
  `persona` entries; an entry of 8,001 characters.
- **S7 (no provider)**: With no key and no `ANALYSIS_LLM`, a miss
  answers 503 `{"detail":"divination unavailable"}` and the scheduler
  holds no `divination_summary:` job. A request whose row is already
  stored still answers 200.
- **S8 (store)**:
  - The SQLite table `divination_summary` has exactly the columns
    `summary_key, summary, persona, lang, model, prompt_version,
    created_at, doctrine`.
  - The stored row's `doctrine` equals `summary.FINGERPRINT`.
  - `011_divination_summary.sql` exists, sorts last, and creates a table
    with the same columns.
  - With `DATABASE_URL` set and a fake `db.connect` recording SQL, `put`
    issues `INSERT INTO divination_summary … ON CONFLICT (summary_key)`
    and `get` issues `SELECT … FROM divination_summary WHERE
    summary_key`.
  - The conftest redirect keeps `server/data/divination.db` untouched by
    the suite.
- **S9 (boundaries)**: `test_boundaries.py` passes with the evolved
  pins, and each new self-check bites:
  - the db line planted in `turn.py`;
  - an `INSERT INTO turns` planted in `render.py`;
  - `from .store import get` planted in `turn.py`;
  - an `email` column planted into the pinned column list;
  - a third divination importer;
  - `summary.generate_summary(` in main.py text.

  `test_main_names_the_synchronous_exceptions`,
  `test_delivery_never_generates_on_the_request_path` and
  `test_jobs_package_imports_no_tier` pass.
- **S10 (turn untouched)**: `git diff 2f45dfb -- server/app/divination/turn.py
  server/app/divination/render.py server/app/llm.py` is empty. The dw-2
  and dw-3 turn and render tests pass unmodified.

**Core** (vitest in `web-divination`, in-memory KV, stubbed `fetch`, fake
timers)
- **C1**: `canEndSession` is false for `[]`, for `[user]` and for
  `[user, persona, user]`. It is true for `[user, persona]` and for
  `[user, persona(stopped)]`.
- **C2**: `endSession('venus','zh')` on a two-exchange transcript
  returns a record with `persona`, `lang:'zh'`, an ISO `endedAtUtc`, the
  entries deep-equal to the transcript, and `summary.status:'pending'`.
  It is first in `listSessions()`. `getTranscript('venus')` is then `[]`
  and a transcript subscriber was notified. The one POST goes to
  `/api/divination/summary` with the body `{persona:'venus', lang:'zh',
  transcript: toWire(entries)}`. Called when `canEndSession` is false, it
  returns null and writes nothing.
- **C3**: A 45-entry session posts 40 entries: entries 1–2 and 8–45, in
  order.
- **C4**: Responses 202, 202, 200 give 3 identical POSTs, spaced
  `POLL_INTERVAL_MS` apart. The record becomes `ready` with the 200's
  `question`, `tone`, `toneNote` and `generatedAtUtc`. Subscribers are
  notified.
- **C5**: Each of these leaves the record `failed`: a 502, a 503, a
  rejected fetch, a 200 with `tone:'ecstatic'`, and `MAX_POLLS` + 1
  consecutive 202s. `retrySummary(id)` sets `pending`, re-POSTs, and a
  200 makes it `ready`.
- **C6**: A KV pre-seeded with one `pending` record makes
  `resumeSummaries()` issue one POST. Calling it again while that POST is
  in flight issues none.
- **C7**: `sessionFacts` gives:
  - a union of refs in first-seen order, deduplicated and capped at 8;
  - `dice` for persona entries whose `dice` is `{planet:'Pluto',
    sign:'Scorpio', house:8}`;
  - no dice for `house: 13`, `sign: 'Ophiuchus'` or dice on a user entry.

  A record written with dice-bearing entries still carries them after a
  reload (the parse keeps them verbatim).
- **C8**: The 51st `endSession` leaves 50 records and drops the oldest.
  A corrupt KV value (`"{"`) lists `[]` without throwing.

**Web** (vitest + Testing Library)
- **W1**: The End button is disabled with an empty transcript and while
  the last stored entry is a user line. It is enabled after a stored
  persona reply.
- **W2**: Clicking End:
  - the chat log shows only the greeting;
  - a pending card shows the opening user line and "Venus is sealing
    this session";
  - after a mocked 200 the card shows the question in quotes, the
    translated tone, `toneNote`, the ♀ seal, and one chart seal per union
    ref (its accessible name as in the chat chips);
  - there is no dice row.
- **W3**: A seeded ready record whose entry has Pluto/Scorpio/8 dice
  renders `PLANET_GLYPHS.Pluto`, `SIGN_GLYPHS.Scorpio` and `8`, with the
  accessible name "Pluto · Scorpio · house 8" (in zh: the zh body and sign names
  joined by the `log` house template).
- **W4**: A failed card shows "Venus could not seal this one" and Retry.
  Retry re-POSTs.
- **W5**: "Sessions · 2" (with two records) opens the Sessions screen:
  the wheel is unmounted and the cards are listed newest first. With no
  records it shows the empty text. "← The chart" restores the chart
  layout.
- **W6**: Opening a card shows the card and every entry of its
  transcript, in order, with the persona moods and seals. The reader has
  no textarea and no Send button. On narrow widths "← All sessions"
  returns to the list.
- **W7**: Every `log` key exists in en and zh (the parity test). The six
  tones have zh labels. Switching to 中 relabels the chrome, not the
  stored question.
- **W8**: `log.css` has a `prefers-reduced-motion: reduce` block that
  sets `animation: none` on the seal press and the sealing shimmer.
- **W9**: The colour guard, G1–G9 and the barrel-consumer guard pass.
  `log/` names no `fetch`, `apiUrl` or colour literal. `git diff 2f45dfb
  --stat` lists no file under `web-divination/src/chat/`, `chart/` or
  `theme/`, and no `packages/core/src/divination/types.ts`.

**Real app** (backend with `ANALYSIS_LLM=claude-cli` and CORS for the
Vite origin, Vite with `VITE_API_BASE` set to that backend; the dw-3
fixture birth entered; any free ports)
- **A1**: After two exchanges with Venus, End is enabled. Clicking it
  empties the chat to the greeting, and the network panel shows `POST
  /api/divination/summary` with 4 entries, no `birthData` and no id. The
  answer is a 202 (then a 200), or a 200 directly. Within the poll budget
  the card shows:
  - a question that restates what was asked, in English;
  - a tone from the six;
  - a `toneNote`.
- **A2**: The card's chart seals are exactly the union of the chips that
  were shown under the two replies.
- **A3**: After a reload, "Sessions · 1" opens the screen with that card
  unchanged. Opening it shows both exchanges verbatim, and the chat still
  shows only the greeting.
- **A4**: Stopping the backend right after End, restarting it and
  reloading the page turns the pending card `ready` with no user action.
- **A5**: With the language set to 中, a new session ends in a card
  whose question and tone note are Chinese. The earlier English card
  keeps its English text.
- **A6**: `sqlite3 server/data/divination.db '.schema divination_summary'`
  shows only the pinned columns. The row count equals the number of
  distinct sessions sealed.
