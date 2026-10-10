# dw-14-web-navigation — real URLs, a way home, and a session log that records as you talk

Epic: `pipeline/epics/divination-web.md` (cited, not re-surveyed).
Depends: dw-12-google-sign-in, dw-13-character-chat (both done).
Overlaps dw-15-wheel-spotlight (`App.tsx`); resolved at landing, see
Architecture §Overlap.

## Goal

Serve QUEUE.md `dw-14-web-navigation`. Give web-divination real URLs: `/` is the six-planet picker (user-confirmed, tier 1, 2026-09-29), plus `/chat/<planet>`, `/sessions` and `/sessions/<id>`. Back, Forward and reload land where the URL says, every screen has a way home and Sign out, and every conversation goes into the device session log as it happens.

## Non-goals

- No server change of any kind: no route, no model, no migration, no prompt,
  and no server-side session or history. The session log stays device-local
  and identity-free (epic dependency rules; CLAUDE.md rules 6 and 9).
- No deploy and no production static-host rewrite. The app stays local-only
  (epic user ruling "Local only").
- No new npm dependency (see D1).
- No change to app-native.
- No change to chat turns, pills, dice, persona cards or the summary.
- No URL for state inside a screen (form edit mode, pressed pill, lit
  wheel, draft, dw-15's focus toggle).
- No continuing a sealed session. A closed session is still read-only
  (dw-6). An OPEN session is continued by going to its character's chat.
- No deleting or renaming sessions, and no search.
- Seeds do not survive a reload. A picked example question or a hand-off
  prefill is a draft, never a message, so a reload or Back may drop it.

## Decided defaults

**D1. An in-house router, not a library.** No router is installed in any
workspace, and the app has four flat route shapes. A History-API router
(pure parser, `popstate` store, `navigate`, anchor `Link`) is about 150
lines, adds nothing to the lockfile, and its parser can be pinned by a
table test. Rejected:
- react-router v7: too large and churn-prone for four routes.
- wouter: a new dependency to replace code this small.

**D2. The URL scheme.** Paths are exact and lower-case, and query and hash
are ignored:

| Path | Screen |
|---|---|
| `/` | Home: the six-planet picker (dw-8's "The six") as a page, plus the birth card |
| `/chat/<id>` | `<id>` ∈ core `PERSONA_IDS`. The wheel stage, the birth card, Placements, the session bar and that character's chat |
| `/sessions` | The session list (open and sealed) |
| `/sessions/<id>` | The list and the reader for that record. On a narrow screen it shows the reader alone |
| anything else | Not found |

A single trailing slash is canonicalized with `replaceState`, so
`/sessions/` becomes `/sessions`. `/chat`, `/chat/pluto` and `/Chat/moon`
are not found. Session ids stay `s-<digits>` (dw-6's `newId`), so they are
URL-safe and never contain a dot.

**D3. Home is the picker, and the stored character never redirects.**
`/` always shows the six plates, even when `astrology.divination.active.v1`
holds a character. The plates are page content, not a modal dialog: there
is no `role="dialog"`, no Esc handler and no "← Back to …" button. The KV
key is still written whenever a chat route opens, and it now means only
"last spoken with". Home marks that plate with a quiet "last" mark, next
to dw-8's "resume" mark. The name, the seal and each example are anchors
to `/chat/<id>`. An example also sets the seed, and nothing is sent.

**D4. Birth entry lives on Home and on every chat route.** Both screens
render the same `BirthSummary`/`BirthForm` pair over the one core
birth-data store. Home needs it because the plates' personal placement
lines come from birth data. The chat route needs it because the wheel
lives there. The wheel is drawn only on chat routes. Home shows no wheel.

**D5. A way home and Sign out on every screen.** The masthead is rendered
on every signed-in route, including not-found:

- the wordmark becomes a link to `/`;
- a small-caps running-head nav holds "The six" (`/`) and "Sessions · n"
  (`/sessions`, with n counting open and sealed records), and the current
  one carries `aria-current="page"`;
- dw-12's `AccountChip` sits beside the nav.

The session bar keeps only End session and the just-sealed card; its
"Sessions · n" button moves to the masthead. dw-6's "← The chart" button
is removed, because the masthead link replaces it. PersonaHeader's "The
six" control stays, and it becomes a link to `/`. The signed-out
gate's masthead shows no nav, because nothing behind the gate may mount or
fetch (dw-12 W1).

**D6. The gate wraps every route, and the URL survives it.** A signed-out
visit to any path shows the gate at that path. After sign-in, that path's
screen renders. Sign-out shows the gate without changing the URL.

**D7. Navigation semantics.**

- A link click, a plate pick or a hand-off pushes a history entry. Hand-off
  moves to `/chat/<target>` with the prefill, and Back returns to the
  source character.
- A modified click (Ctrl, Meta, Shift, Alt or a non-primary button) is
  left to the browser, so "open in new tab" works.
- A push scrolls to the top and focuses the new screen's heading. A
  pop leaves scrolling to the browser.
- `document.title` names the screen: "The six · Astrace", "Moon · Astrace",
  "Sessions · Astrace". Not-found pages use a title of their own.
- Switching characters still remounts the chat panel (dw-8). A turn in
  flight when you navigate away is stopped and stored on its own
  character, exactly as dw-8 does today.

**D8. Every conversation is logged as it happens.** This supersedes dw-6's
"a session is logged only on End session".

- A character's live transcript IS its **open session**. The first entry
  recorded into an empty transcript creates an open record in the session
  log: `state: "open"`, a fresh `s-<digits>` id, the persona, the UI
  language and `startedAtUtc`. The record stores no entries of its own.
  Its entries are read from the live transcript, so the log holds one copy
  of the text, never two.
- Every later entry shows up in Sessions immediately, and after a reload.
- **End session** seals that SAME record: `state: "sealed"`, the entries
  are copied from the transcript, `endedAtUtc` is set, the summary goes to
  `pending`, and the transcript is cleared. So `/sessions/<id>` stays valid
  across sealing.
- A sealed record whose summary fails stays listed, with its transcript and
  Retry (dw-6).
- Only core writes the transcript, through `recordEntry`. The web chat
  never calls `appendEntry` (guard).
- Transcripts left non-empty by earlier builds, which have no open record,
  are adopted on load as open records.
- An open header whose transcript is empty (for example, storage was
  cleared by hand) is treated as absent: it is not listed, and the next
  entry gets a fresh header and id.
- Records dw-6 stored without a `state` field read as sealed and are
  unchanged. The KV key stays `astrology.divination.sessions.v1`, because
  the change only adds fields.
- The 50-record cap evicts only the oldest sealed records. There are at
  most six open records, and they are never evicted.

**D9. How open sessions look.** The Sessions list shows an open record as
a card in its character's ink. It carries the opening user line where the
question would be, an "In progress" eyebrow in place of the tone row, and
the start date. It has no Retry and no summary stars. The reader shows the
transcript read-only and a "Continue with <name> →" link to
`/chat/<persona>`. The list is in creation order, newest first: a new open
record is added at the top, and sealing keeps its place.

**D10. Unknown things.**

- An unknown path, or an unknown planet under `/chat/`, renders a
  not-found screen in the shell. It shows the masthead, a short line ("No
  page by that name in this sky" / "No character by that name") and a
  "← The six" link. It never redirects, so the URL still shows what was
  wrong.
- `/sessions/<unknown id>` renders the Sessions screen with the reader
  saying "That session isn't on this device", plus an "← All sessions"
  link.

**D11. Dev-server history fallback.** Vite's default `appType: 'spa'`
already serves `index.html` for extension-less paths in `vite` dev and
`vite preview`. The config gains no middleware. The one requirement is
that every asset URL is root-absolute (`/src/main.tsx`, which is true
today) and `base` stays `/`. A real-browser reload on each route shape
proves this (R4).

**D12. Visual register.** The existing almanac is kept:
- Nav: a running head in Fraunces small caps, the current item
  underscored by a hairline in the active ink.
- Home: title, lede, the birth card as a narrow colophon, then the six
  plates with dw-8's rise stagger (static under reduced motion).
- Not-found: one engraved line under an empty zodiac ring glyph.

Colour comes only from web tokens (rule 13). All new copy goes in the web
i18n with en↔zh parity (rule 8).

**D13. Superseded loop decisions** (tier 3; revised here and named under
**Supersedes** in the journal):

- dw-6 (spec-review 2026-09-28, choice f): a session is archived into the
  log only on End session. It is superseded by D8.
- dw-6 D11: Sessions is "a view swap in App, no router — a reload opens on
  the chart". It is superseded by D2.
- dw-8: with no character stored, the picker opens as a modal over
  everything, and it is otherwise an overlay closed by Esc or "← Back to
  …". It is superseded by D3.

## Architecture

The epic file holds the survey. This section records only this feature's
delta, and it was confirmed by targeted reads of the files it names (at
`8da99b2`). No server file changes.

### Reused as-is (file:line)

| Need | Existing | Use |
|---|---|---|
| Gate over everything | `web-divination/src/main.tsx:25` `<AuthGate><App/></AuthGate>`; `auth/AuthGate.tsx:29` renders children only when `signed-in` | Unchanged. The router lives inside `App`, so the gate never reads the URL and the path survives sign-in and sign-out (D6). |
| Sign out | `auth/AccountChip.tsx:10` in `app/Header.tsx:17` | Unchanged. Every route renders `Header` (D5). |
| Live transcript | core `divination/transcript.ts:65` `getTranscript`, `:75` `appendEntry`, `:86` `subscribeTranscript`, `:111` `clearTranscript` | Stays the body of an open session. `appendEntry` stays exported; only core calls it from production code (G17). |
| Session log | core `divination/session-log.ts:147` `listSessions`, `:155` `getSession`, `:178` `startLoop`, `:204` `newId`, `:214` `endSession`, `:237` `resumeSummaries` | Extended (below). Summary loop, retry and `sessionFacts` unchanged. |
| Persona ids | core `divination/roster.ts:17` `PERSONA_IDS`, `:19` `isPersonaId`, `:35` `ACTIVE_KEY` | The route parser validates `/chat/<id>` with `isPersonaId`. `setActivePersona` is still called on entering a chat route. |
| Chat layout | `app/App.tsx:74-103` (stage + side) | Moves verbatim into `ChatScreen`, with `persona` taken from the route. |
| Birth card | `app/App.tsx:79-88` (summary ⇄ form toggle) | Extracted once and rendered on Home and on chat routes (D4). |
| Picker plates | `roster/RosterPicker.tsx:80-128` | The plate markup is kept. The dialog chrome goes (`:43-78`, D3), and the name, seal and examples become `Link`s. |
| Sessions screen | `log/SessionsScreen.tsx:14-80` | `selectedId` state becomes a prop from the route, and its buttons become `Link`s. |

### Module map (new ● / changed ◐)

```
packages/core/src/divination/
├── session-log.ts   ◐ open records; recordEntry; adoptTranscripts; seal-in-place End; eviction rule
└── index.ts         ◐ + recordEntry, adoptTranscripts; types OpenSession, SealedSession
web-divination/src/
├── nav/             ● the router (a leaf: imports react, @astrace/core/divination, siblings)
│   ├── routes.ts    ● pure: Route, parseRoute, pathFor, canonicalPath
│   ├── history.ts   ● the ONE web file naming the history / location GLOBALS or popstate (G16)
│   ├── useRoute.ts  ● useSyncExternalStore over history.ts → Route; canonicalizes via replace
│   └── Link.tsx     ● <a href> that pushes on an unmodified primary click
├── app/
│   ├── App.tsx      ◐ shell + route switch, seed state, title + heading focus on push
│   ├── Header.tsx   ◐ wordmark is a Link to "/"; optional `nav` slot (App fills it, AuthGate does not)
│   ├── MainNav.tsx  ● "The six" · "Sessions · n", aria-current; mounts useSessions
│   ├── HomeScreen.tsx ● title, lede, BirthCard, RosterPicker
│   ├── ChatScreen.tsx ● today's stage + side for one persona
│   └── NotFound.tsx ● path and persona variants
├── birth-input/BirthCard.tsx ● the extracted summary ⇄ form toggle
├── roster/RosterPicker.tsx   ◐ page section, Links, "last" mark; no dialog, Esc or close
├── chat/useChat.ts           ◐ appendEntry → recordEntry(persona, entry, lang)
├── chat/PersonaHeader.tsx, ChatPanel.tsx ◐ onOpenRoster → Link to "/"
├── log/SessionBar.tsx        ◐ End + sealed card only (count moves to MainNav)
├── log/SessionsScreen.tsx    ◐ selectedId from the route; missing-id reader; Links
├── log/SummaryCard.tsx       ◐ open variant; the list card is a Link to /sessions/<id>
├── log/useSessions.ts        ◐ on mount: adoptTranscripts(lang), then resumeSummaries()
├── test-setup.ts             ◐ stubs `window.scrollTo` (jsdom does not implement it) for the router tests
└── i18n/en.ts, zh.ts         ◐ `nav` + `notFound` namespaces; log.inProgress/continueWith/
                                sessionMissing/startedOn; roster.last; drop log.backToChart, roster.close
```

### Contracts

**`nav/routes.ts`** (pure, no DOM)
- `Route` is one of `{name:'home'}`, `{name:'chat', persona}`,
  `{name:'sessions'}`, `{name:'session', id}` or
  `{name:'notFound', reason:'path'|'persona'}`.
- `parseRoute(pathname) → Route`.
- `pathFor(route) → string` (for every non-notFound route).
- `canonicalPath(pathname) → string | null`: null when the path is
  already canonical; otherwise the path with the trailing slash stripped.
- It owns the D2 table and nothing else.

**`nav/history.ts`**
- `getPath() → string` returns `location.pathname`.
- `subscribePath(cb) → unsubscribe` listens for `popstate` plus this
  module's own push and replace notifications.
- `navigate(path, {replace?}) → void`:
  - with `replace`, it calls `replaceState` and nothing else;
  - otherwise it calls `pushState`, notifies, and then
    `scrollTo(0, 0)`.
- It is the only web source that uses the browser globals `history` or
  `location`, or names `popstate` (G16, defined below).

**`nav/Link.tsx`**
- Props: `href`, `onNavigate?` (runs before the push, used by the seed),
  plus anchor props.
- Only an unmodified primary click is intercepted; any other click stays
  native.
- A `Link` whose `href` equals the current path does not push a duplicate
  entry.

**`App`**
- Reads `useRoute()`, renders `Header nav={<MainNav/>}` and then the route's
  screen.
- Owns the seed state (`{persona, text, nonce}`, dw-8's shape).
  `onHandoff(target, q)` sets the seed and calls `navigate(pathFor(chat target))`.
- After each push, an effect sets `document.title` and focuses the
  screen's `h1`/`h2`, which carries `tabIndex={-1}`. There is no focus
  move on the first render or on `popstate`.

**`ChatScreen`**
- `{persona, seed, onHandoff}`.
- On mount and on a persona change, it calls `setActive(persona)`, which
  writes the "last" KV key and clears the wheel activation.
- It keys `ChatPanel` by persona, as dw-8 does.

**core `session-log.ts`**
- `type OpenSession = {state:'open'; id; persona; lang; startedAtUtc; entries}`.
  The stored header omits `entries`; `listSessions` fills them from
  `getTranscript(persona)`.
- `type SealedSession = {state:'sealed'; id; persona; lang; startedAtUtc?;
  endedAtUtc; entries; summary}`.
- `SessionRecord = OpenSession | SealedSession`. A stored record without
  `state` parses as sealed. An open header whose persona is not an id, or
  a second open header for the same persona, is dropped at parse time.
- `recordEntry(persona, entry, lang) → void`: calls `appendEntry`, then
  prepends an open header when that persona has none.
- `adoptTranscripts(lang) → void`: gives every non-empty transcript that
  has no open header a header (idempotent).
- `endSession(persona, lang)`: the `canEndSession` gate is unchanged. It
  turns that persona's open header into a sealed record in place (same id,
  same position; `startedAtUtc` kept) and sets `lang` to the End language
  (dw-6). With no header it prepends a sealed record with `newId`. It then
  clears the transcript and starts the loop.
- **An open header whose live transcript is empty is treated as ABSENT
  everywhere** (decided default):
  - `listSessions` omits it and `getSession` returns undefined;
  - `recordEntry` drops it and prepends a fresh header with a new id;
  - `adoptTranscripts` ignores it;
  - the next `write()` drops it.
- `listSessions()`: stored order. The same array comes back while neither the sessions
  raw value nor any open persona's transcript snapshot has changed (a
  valid `useSyncExternalStore` snapshot).
- `subscribeSessions(cb)`: fires on log writes AND on any persona's
  transcript change. While it has listeners, the log holds one
  `subscribeTranscript` per id.
- `write()`: keeps every open header and the newest sealed records, up to
  50 records in total.
- `resumeSummaries` and `retrySummary` touch sealed records only.

### Dependency rules and forbidden edges

```
app/ ──▶ nav/, roster/, chat/, log/, birth-input/, chart/, auth/, i18n/, theme/
roster/, chat/, log/ ──▶ nav/ (Link, pathFor only)
nav/ ──▶ react, @astrace/core/divination (barrel), siblings
```

- ❌ No feature folder, and not `nav/`, imports `app/`. `App` is the root.
- ❌ `nav/` imports no feature folder and no `i18n/`: routes carry ids,
  and screens translate them.
- ❌ Only `nav/history.ts` uses the `history`/`location` globals or names
  `popstate` in web production code (G16). Property accesses such as
  `data.location.name` (birth data) are not the global and stay legal. Core names none of them (the existing
  Web-global guard over `packages/core/src` already bans `window`, and
  core gains no navigation).
- ❌ No web production file calls `appendEntry(` (G17). The chat records
  only through `recordEntry`, so no conversation can skip the log.
- ✅ The existing guards are unchanged:
  - network only in `src/platform/` (G3);
  - no arithmetic (G4);
  - one chart value-importer (G5);
  - the i18n and theme leaves (G6, G7);
  - colour only in `theme/tokens.ts` (rule 13);
  - no new package in `web-divination/package.json`.

### Wire shapes

None change on the network. Two device-local shapes change:

- **KV `astrology.divination.sessions.v1`** is an array. It may now hold
  `{"state":"open","id":"s-…","persona":"moon","lang":"en","startedAtUtc":"…"}`
  headers, with no `entries` key. Sealed records gain `"state":"sealed"`
  and, when sealed from an open header, `startedAtUtc`. Old records read
  unchanged.
- **The URL** (D2) is a new client contract, and `routes.ts` is its only
  definition.

### Guard and CLAUDE.md amendments

- **`app-native/src/architecture.test.ts`** gains two tests in its
  web-divination block, each with a synthetic self-check:
  - **G16**: in non-test `web-divination/src` files, with comments
    stripped (as the existing guards do), the browser GLOBALS appear only
    in `nav/history.ts`. The pattern is
    `(?<![\w.$])(?:(?:window|globalThis)\.)?(?:history|location)\s*\.`
    (the bare identifier, or after `window.`/`globalThis.`, followed by a
    member access) or `\bpopstate\b`. A property access like
    `data.location.name` or `value.location.name` does not match: the
    identifier is preceded by `.`. An object key `location:` does not
    match either. At `8da99b2` it has zero hits in web production code;
  - **G17**: no non-test web file matches `\bappendEntry\(`.
- **CLAUDE.md**: the `web-divination/` paragraph gains one sentence: "Routes
  (dw-14): `/`, `/chat/<id>`, `/sessions`, `/sessions/<id>` through an
  in-house History-API router in `web-divination/src/nav/` — only
  `nav/history.ts` uses the browser `history`/`location` globals (bare or
  via `window.`/`globalThis.`) or names `popstate`, and the Vite
  dev server's SPA fallback serves every route; the chat records through
  core `recordEntry`, so every conversation is an open session in the
  device log until End seals it (both test-enforced)."
- **Epic file**: at docs-sync, add a "dw-14" entry to Built so far and
  `nav/` to Target modules.

### Overlap with dw-15-wheel-spotlight

dw-15 adds one prop, `<ChartStage persona={active} />`, at `App.tsx:76`.
After dw-14 that JSX lives in `app/ChatScreen.tsx`, and the persona comes
from the route. Whichever feature lands second moves the prop into
`ChatScreen`. The persona value is the same: the character whose chat is
shown. dw-14 does not edit `ChartStage.tsx`. In `App.test.tsx`, dw-15's
cases that mount `App` with Venus active need an initial path of
`/chat/venus` after dw-14 lands.

## Acceptance Criteria

Test-level criteria run in `web-divination` vitest (jsdom) unless marked.
The core criteria run there too, through the barrels, as dw-6 did.
"Signed-in" means core's Google session is stubbed to `signed-in`, as in
dw-12's W2. A test sets its starting URL with `history.replaceState` before
it mounts. `window.scrollTo` is stubbed in `src/test-setup.ts`.

**Router (N)**
- **N1**: `parseRoute` maps each input to the route shown:
  - `/` → home;
  - each of the six ids under `/chat/<id>` → that chat;
  - `/sessions` → sessions;
  - `/sessions/s-1700000000000` → session with that id;
  - `/chat/pluto` → notFound(persona);
  - `/chat`, `/Chat/moon`, `/foo`, `/sessions/a/b` → notFound(path).

  `pathFor(parseRoute(p)) === p` holds for every canonical p above.
  `canonicalPath('/sessions/')` is `'/sessions'` and
  `canonicalPath('/sessions')` is null.
- **N2**: A rendered `Link href="/sessions"`:
  - a plain click calls `pushState` once, `event.defaultPrevented` is
    true, and the route re-renders without a remount of `App`;
  - a click with Ctrl, Meta, Shift or `button: 1` is not prevented and
    does not push;
  - a click on a Link whose href is the current path pushes nothing.
- **N3**: Signed in, at `/`: click the Moon plate, and the path is
  `/chat/moon`. Then call `history.back()` and await `popstate`: Home
  renders. Then call `history.forward()`: Moon's chat renders.
- **N4**: Mounting at `/sessions/` leaves the path at `/sessions`, and
  `history.length` is unchanged (replace, not push).

**Screens (W)**
- **W1**: Signed in at `/` with `astrology.divination.active.v1 = "saturn"`,
  Home renders:
  - an `h1` or `h2` reading "The six", and six links whose `href`s are
    `/chat/venus` … `/chat/mercury`, in roster order;
  - Saturn's plate carries the "last" mark;
  - there is no `[role="dialog"]`, no chat panel and no `svg.wheel`, and
    the path is still `/`.
- **W2**: At `/` with no birth data, the birth form is present. At `/`
  with birth data, the birth summary is present, and its Edit opens the
  form in place.
- **W3**: Clicking the Moon name on Home:
  - the path is `/chat/moon`, and `[data-slot="stage"]` and Moon's chat
    panel render;
  - the active KV key is `"moon"`, and `document.title` contains "Moon";
  - focus is on the chat screen's heading.
- **W4**: Clicking a plate's example question moves to that plate's
  `/chat/<id>`, and the composer holds the question. No turn request
  (`streamPost`) is made.
- **W5**: For each of `/`, `/chat/venus`, `/sessions`,
  `/sessions/<existing id>`, `/sessions/s-0`, `/nowhere` and `/chat/pluto`,
  the page shows:
  - a masthead link with `href="/"`;
  - a "Sessions · n" link with `href="/sessions"`;
  - a "Sign out" button.

  `aria-current="page"` is on the Home link only at `/`, and on the
  Sessions link only at `/sessions` and `/sessions/<id>`.
- **W6**: `/nowhere` shows the not-found line and a "← The six" link to
  `/`. `/chat/pluto` shows the no-such-character line. `/sessions/s-0`
  shows the Sessions list and a reader saying the session isn't on this
  device, with a link to `/sessions`. None of them throws or redirects:
  the path is unchanged.
- **W7 (walk away)**: At `/chat/moon`, the turn stream is stubbed to reply.
  Send "Will this pass?" and let the reply finish. Then click the masthead
  home link, and then "Sessions · 1":
  - the list holds one card, in Moon's ink, marked "In progress", with
    "Will this pass?" as its line;
  - clicking it moves to `/sessions/<id>`, where the reader shows both
    entries and a "Continue with Moon →" link to `/chat/moon`;
  - End session was never pressed.
- **W8**: Continuing W7 at `/chat/moon`, press End session. The record at
  `/sessions/<same id>` is now sealed (pending). Stub the summary POST to
  answer 503: the card turns failed and stays in the list, its reader
  still shows both entries and Retry, and "Sessions · 1" still counts it.
  A new message to Moon creates a second, open record with a different
  id, and the count becomes 2.
- **W9 (hand-off)**: At `/chat/venus`, a stored Venus reply carries
  `handoff:"saturn"`. Pressing its hand-off control:
  - moves to `/chat/saturn` with the question prefilled, and nothing is
    sent;
  - `history.back()` then returns to `/chat/venus` with Venus's
    transcript.
- **W10**: The chat header's "The six" control is a link with `href="/"`.
  The session bar has no "Sessions" button. The string "← The chart"
  appears nowhere.
- **W11 (gate)**: Signed out at `/sessions/<existing id>`, the gate shows,
  and every recorded fetch URL is under `/api/auth/`. Completing sign-in
  (dw-12's stubbed credential) renders that session's reader, with the
  path unchanged. At `/chat/moon`, pressing "Sign out" shows the gate and
  leaves the path at `/chat/moon`.
- **W12**: Switching to zh renders the new copy in Chinese: the nav,
  not-found, "In progress", "Continue with…" and the missing-session line.
  The existing i18n parity test passes with the new `nav` and `notFound`
  namespaces.

**Core session log (C)**
- **C1**: With empty KV, `recordEntry('moon', user entry, 'en')` makes
  `listSessions()` hold exactly one record:
  - `state:'open'`, an id matching `/^s-\d+$/`, `persona:'moon'`,
    `lang:'en'`;
  - an ISO `startedAtUtc`;
  - `entries` equal to `getTranscript('moon')`.

  A second `recordEntry` adds no record, and the record's entries grow to
  two. The raw KV value holds no `entries` key for that record.
- **C2**: `listSessions()` called twice with no change returns the same
  array (`===`). After a `recordEntry` it returns a new array, and a
  `subscribeSessions` listener was called at least once.
- **C3**: `endSession('moon','en')` on C1's state (a persona reply last)
  gives a record with:
  - the same id, `state:'sealed'`, the same entries, `endedAtUtc` set,
    `summary.status:'pending'`;
  - an empty `getTranscript('moon')`.

  No open Moon record remains. The next `recordEntry('moon', …)` creates
  an open record with a different id at index 0.
- **C4**: A dw-6-shaped stored record with no `state` parses as
  `state:'sealed'`, with its fields unchanged. A summary loop ending in
  502 or 503 leaves the record listed, with `summary.status:'failed'` and
  its entries intact.
- **C5**: Seed KV with a Moon open header at index 0 (Moon transcript: one
  user and one persona entry) followed by 49 sealed records `s-1` … `s-49`,
  where `s-49` is the oldest (last). Seed a Mars transcript whose last entry
  is a persona reply, with no Mars header. `endSession('mars','en')` then
  leaves exactly 50 records:
  - the new sealed Mars record is at index 0;
  - the Moon open header is still present, with its id unchanged;
  - `s-1` … `s-48` are still present;
  - `s-49` is gone.
- **C6**: With `astrology.divination.transcript.v1.mars` holding two
  entries and no header, `adoptTranscripts('en')` creates exactly one open
  Mars record. Calling it again creates none. An empty or corrupt
  transcript is not adopted.

**Guards and build (G)**
- **G1**: The new G16 and G17 tests in `app-native/src/architecture.test.ts`
  pass, and each bites on a synthetic offender:
  - `history.pushState(null, '', '/')` in `web-divination/src/log/x.tsx`;
  - `window.location.pathname` in `web-divination/src/app/x.tsx`;
  - `addEventListener('popstate', f)` in `web-divination/src/chat/x.ts`;
  - `appendEntry(` in `web-divination/src/chat/x.ts`.

  G16 also must NOT bite on `data.location.name`,
  `value?.location.name` or `{ location: initial.location }` placed in
  `web-divination/src/birth-input/x.tsx`. The unchanged `birth-input/`
  sources pass G16.
- **G2**: `web-divination/package.json` `dependencies` and
  `devDependencies` have the same keys as at `8da99b2`. The root
  `npm test`, `npm run typecheck` and
  `npm --workspace web-divination run build` all exit 0. The colour,
  text-variant and existing web guards (G1–G13) pass.
- **G3**: CLAUDE.md's web-divination paragraph carries the dw-14 routing
  sentence given in Architecture §Guard and CLAUDE.md amendments. That
  sentence claims only the GLOBAL form (`history` or `location`, bare or
  via `window.`/`globalThis.`, plus `popstate`), never every `location.`
  text.

**Real app (R)**, driven in a real browser.

Setup, recorded in the validating log:
- **Database**: a throwaway Postgres cluster started with `initdb` under
  the scratchpad on 127.0.0.1. The root `.env` `DATABASE_URL` is never
  used: the backend is started WITHOUT `--env-file .env`, with that
  throwaway URL.
- **Backend**: port 8002, a placeholder `GOOGLE_CLIENT_ID`,
  `CORS_ALLOW_ORIGINS=http://localhost:5175`, and a working chat path
  (`ANALYSIS_LLM=claude-cli`, or one provider key exported by hand).
- **Vite**: `--port 5175` (the SAME port that `CORS_ALLOW_ORIGINS` names),
  with `VITE_API_BASE=http://localhost:8002`.
- **Sign-in**: a bearer pair minted by a log-recorded script,
  `accounts/service._upsert_user` + `_mint_bearer` on the throwaway
  database (the script asserts the 127.0.0.1 host). It is written to
  `astrace.auth.access`, `astrace.auth.refresh` and `astrace.auth.expiresAt`
  in localStorage, together with a birth record, and the page is then
  reloaded. This is dw-12 R2's method.

The criteria:
- **R1**: Open `/`, with the active character KV set to `venus`. The six
  plates show, and there is no wheel or chat. A reload stays on `/` with
  the plates.
- **R2**: Click Moon: the URL is `/chat/moon`, and the wheel and Moon's
  chat show. Send a message, and a reply arrives. Then:
  - click the masthead's home link: the URL is `/`;
  - browser Back: `/chat/moon`, with the exchange shown;
  - Forward: `/`;
  - Back again, then reload: `/chat/moon`, with the exchange and the wheel
    shown (not Home, not another character).
- **R3 (loop closed)**: Without pressing End, go home and then to
  Sessions. The URL is `/sessions`, and a Moon card marked "In progress"
  shows the message. Open it: the URL is `/sessions/s-…` and the exchange
  shows. Reload that URL: the same session shows. Back: `/sessions`.
- **R4**: Type each URL into the address bar and load it cold: `/sessions`,
  the R3 session URL, `/chat/saturn`, `/nowhere`, `/chat/pluto` and
  `/sessions/s-0`. The dev server answers every one with the app, never a
  404 page. The last three show their not-found screens. On each of these
  six screens and on Home:
  - one click on a masthead link reaches `/`;
  - "Sign out" is visible.
- **R5**: At `/chat/moon`, press End session. The card seals.
  `/sessions` lists it with the SAME id as R3's URL, which still resolves.
  From that session URL, press Sign out: the gate shows and the URL is
  unchanged. Mint and write a new pair (the R2 method), then reload: that
  session's screen renders.
