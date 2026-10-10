# 06 — implementing (dw-14-web-navigation)

Worker in worktree `/Users/kaimao/Projects/astrology-wt/dw-14-web-navigation`
(branch `feature/dw-14-web-navigation` from `feature/divination_web` @ 416c3dd).
Parallel sibling: dw-15-wheel-spotlight (G14/G15 are its ids; this feature uses G16/G17).

## Step 0 — baseline (before any edit)

- `node_modules/@astrace/core` → symlink to `../../packages/core` (resolves).
- `web-divination/package.json` dependency keys at 416c3dd (G2 reference):
  dependencies `@astrace/core, @fontsource-variable/fraunces, @fontsource/source-serif-4, react, react-dom`;
  devDependencies `@testing-library/dom, @testing-library/react, @testing-library/user-event, @types/react, @types/react-dom, @vitejs/plugin-react, jsdom, typescript, vite, vitest`.
- `npm test` (root): jest `Tests: 1072 passed, 1072 total`; vitest `Test Files 30 passed (30)`, `Tests 308 passed (308)`; exit 0.
- `npm run typecheck`: exit 0.
- `cd server && DATABASE_URL= conda run -n astrology pytest -q`: `1380 passed, 55 skipped, 1 warning in 118.06s`; exit 0.

## Step 1 — core session log: open records

Files: `packages/core/src/divination/session-log.ts`, `index.ts`,
`web-divination/src/log/core-session-log.test.ts`, plus the type fallout
(`SessionRecord` is now `OpenSession | SealedSession`):
`web-divination/src/log/SummaryCard.tsx` (narrowing: `recordDate`, status
`open`), `log/SummaryCard.test.tsx` (fixture typed `SealedSession`).

- Stored form: open headers (no `entries`) + sealed records; `listSessions`
  fills open entries from `getTranscript`, snapshot keyed on raw + each open
  persona's transcript array identity.
- `recordEntry`, `adoptTranscripts`, seal-in-place `endSession`, write() keeps
  open headers + newest sealed up to 50, absent-if-empty headers.
- `subscribeSessions` holds one `subscribeTranscript` per persona id while it has listeners.

`npx vitest run src/log/core-session-log.test.ts` → `Tests 36 passed (36)` (dw-6 cases + C1–C6 + 2 absent/duplicate-header cases).
`npm run typecheck` → exit 0.

## Step 2 — the web chat records through core

`chat/useChat.ts`: the three `appendEntry` calls (user send, finished reply,
stopped-on-abort/unmount reply) → `recordEntry(persona, entry, lang)`.
`log/useSessions.ts`: mount runs `adoptTranscripts(lang)` then `resumeSummaries()`.
New case in `chat/ChatPanel.test.tsx` ("one sent message opens exactly one open
record; its reply and a stopped reply join it").
One fallout: `chat/Pill.test.tsx` W6 fixture lacked `state` (cast `as SessionRecord`)
and rendered as an open card → given `state: 'sealed'`.

`grep -rn "appendEntry(" web-divination/src | grep -v "\.test\."` → empty.
`npx vitest run src/chat src/log` → `Test Files 12 passed (12)`, `Tests 189 passed (189)`; `tsc --noEmit` clean.

## Step 3 — the router (`web-divination/src/nav/`)

New: `nav/routes.ts` (Route, KnownRoute, parseRoute, pathFor, canonicalPath),
`nav/history.ts` (getPath, subscribePath, navigate, lastChange — the SG1
push/pop/initial read), `nav/useRoute.ts` (useSyncExternalStore + canonicalize by
replace), `nav/Link.tsx`; tests `nav/routes.test.ts` (N1), `nav/Link.test.tsx`
(N2 with the `RouteHarness`/`harnessMounts` probe S3, N4, Back re-render).
`test-setup.ts`: stubs `window.scrollTo`; afterEach `replaceState(null,'','/')`.

Design notes: `navigate(path)` never pushes the current path (the Link's
"no duplicate entry" rule lives in navigate, so a same-path hand-off is safe
too); `navigate(path, {replace:true})` only calls replaceState. The popstate
listener exists only while there are subscribers.

First run: 1 failure in my own N2 modified-click test (a guard listener I added
inside the loop prevented the NEXT click, so `fireEvent.click` returned false):
`AssertionError: expected false to be true`. Rewrote it to record
`defaultPrevented` from a document-level listener that runs after React.
`npx vitest run src/nav` → `Test Files 2 passed (2)`, `Tests 8 passed (8)`;
full web vitest `Test Files 32 passed (32)`, `Tests 325 passed (325)`; tsc clean.

## Step 4 — guards G16/G17 + CLAUDE.md sentence

`app-native/src/architecture.test.ts`: G16 (`WEB_NAV_GLOBAL_RE =
/(?<![\w.$])(?:(?:window|globalThis)\.)?(?:history|location)\s*\.|\bpopstate\b/`
over comment-stripped, string-KEPT web production text, `nav/history.ts`
exempt), G17 (`/\bappendEntry\(/`), and a G16/G17 self-check (bites: the spec's
four offenders + `globalThis.history.back()` + `location.reload()`; does not
bite: `data.location.name`, `value?.location.name`, `{ location: initial.location }`
in `birth-input/x.tsx`, a comment, the sanctioned file; real `birth-input/`
sources pass). Header comment lists G12/G13/G16/G17. G14/G15 unused (dw-15's).

`cd app-native && npx jest src/architecture.test.ts` → `Tests: 44 passed, 44 total`.
Bite proof: appended `export const _probe = () => history.back()` to
`web-divination/src/log/SessionBar.tsx` →
`✕ only web-divination/src/nav/history.ts uses the history/location globals or names popstate (G16)`
with `+   "web-divination/src/log/SessionBar.tsx",`; reverted with `git checkout`.
`grep -n "dw-14" CLAUDE.md` → line 27, the spec's verbatim routing sentence in the web-divination paragraph.

## Step 5 — i18n copy

`i18n/en.ts`, `zh.ts`: new `nav` (label, home, sessions, homeLink, four
titles) and `notFound` (eyebrow, path, persona, home) namespaces; `log.inProgress`,
`log.continueWith`, `log.sessionMissing`, `log.startedOn`; `roster.last`,
`roster.lastHint`. (`log.backToChart`, `roster.close` dropped at steps 10/11
when their readers go.)
`npx vitest run src/i18n.test.ts` → `Tests 11 passed (11)` (en↔zh parity); tsc clean.

## Step 6 — masthead: Header, MainNav, NotFound

(`/frontend-design` loaded before this step.) `app/Header.tsx`: wordmark is a
`Link` to `/` (aria-label `nav.homeLink`), optional `nav` slot before the
account chip. `app/MainNav.tsx` (new): running head "The six" · "Sessions · n",
`aria-current="page"`, mounts `useSessions`. `app/NotFound.tsx` (new): an empty
zodiac ring (SVG, the outer circle dashed into 12 ticks — no arithmetic), eyebrow,
the engraved line as the focusable `screen-heading` h2, "← The six" link.
`app/app.css`: wordmark hairline, running head (small caps, current item
underscored in `var(--char, var(--voice))`), `.lost*` not-found styles,
reduced-motion block. `auth/AuthGate.test.tsx` `gateIsUp` now also asserts no
`.running-head`. New `app/MainNav.test.tsx` (count incl. an adopted transcript; aria-current).
`npx vitest run src/app/MainNav.test.tsx src/auth` → `Test Files 4 passed`, `Tests 30 passed`; tsc clean.

## Step 7 — BirthCard extraction

`birth-input/BirthCard.tsx` (new): the summary ⇄ form toggle moved verbatim out
of `app/App.tsx`, which now renders `<BirthCard />`.
`npx vitest run src/app src/birth-input` → `Test Files 3 passed`, `Tests 14 passed` (no behaviour change); tsc clean.

## Steps 8–12 — Home, ChatScreen + the route switch, chat header/session bar, Sessions screens, App flows (ONE commit)

These landed together: the App's route switch changes every prop the four
screens take (SessionsScreen `selectedId`, SessionBar without `onOpenSessions`,
ChatPanel without `onOpenRoster`), so no step compiles alone.

- Step 8: `roster/RosterPicker.tsx` is the plates grid only (no dialog, Esc,
  close, focus trap); seal, name and examples are `Link`s to `/chat/<id>`, an
  example calls `onSeed` via `onNavigate`; "last" mark (`roster__plate--last`,
  `.roster__last`). `roster/useRoster.ts` exports `activate(id)` (clearActivation +
  setActivePersona). `roster/roster.css`: overlay/close rules removed, `.home*`
  page layout (title + lede, BirthCard colophon at ≥960 px, plates below).
  `app/HomeScreen.tsx` (new). `grep role=\"dialog\" roster/` → none.
- Step 9: `app/ChatScreen.tsx` (new; `activate(persona)` on mount/change;
  ChatPanel keyed by persona). `app/App.tsx`: `useRoute` switch, `Header
  nav={<MainNav current=…/>}`, seed `{persona,text,nonce}` (nonce from a ref;
  dropped when its character's chat is not shown), `onHandoff` = seed then
  `navigate`, `document.title` per route, heading focus only when
  `lastChange()==='push'` (SG1). The dw-8 `view`/`setView`/`picking` state is gone;
  the shell carries `persona-scope`+`data-persona` on chat routes only.
- Step 10: `chat/PersonaHeader.tsx` "The six" is a `Link` to `/` (always shown),
  title h2 is `.screen-heading` tabIndex -1; `chat/ChatPanel.tsx` drops
  `onOpenRoster`; `log/SessionBar.tsx` keeps End + sealed card only. i18n
  `log.sessionsCount`, `log.backToChart`, `roster.close` removed.
  `grep -rn "← The chart\|onOpenSessions\|onOpenRoster" web-divination/src` → empty.
- Step 11: `log/SessionsScreen.tsx` (`selectedId` prop from the route; cards
  link to `/sessions/<id>`; reader "← All sessions" link; open reader has
  "Continue with <name> →"; missing-id reader), `log/SummaryCard.tsx` (`href`
  replaces `onOpen`; open variant: opening line as the hero, "begun <date>"
  eyebrow, "In progress" row with a pulse, no stars/Retry/tone), `log/log.css`.
- Step 12: legacy suites start at `/chat/venus` (`App.test.tsx` both describes,
  `ChartStage.test.tsx`, `SessionBar.test.tsx`, `AuthGate.test.tsx` beforeEach);
  SessionBar/RosterPicker/SessionsScreen/SummaryCard queries moved from buttons
  to links; RosterPicker's dw-8 "opening the picker does not stop a turn" is
  replaced by "going Home mid-turn stops it and stores the partial" (D7) and
  its "same character example without a remount" by a nonce re-prefill case;
  ChatPanel W4 tab order now starts on the header's "The six" link.
  New `App routes (dw-14)` describe in `app/App.test.tsx` (real AuthGate + App,
  signed in via stored pair + whoami 200): N3, S3 (masthead node identity),
  W1–W12.

Failures met on the way (verbatim):
- after the route switch, before migrating tests: `Tests 37 failed | 290 passed (327)` (all "starts at `/`" or button→link).
- `ChartStage.test.tsx`: `Unable to find an element with the text: The sky is out of reach.` → mount at `/chat/venus`.
- `ChatPanel W4`: `expected <a class="chat__roster" …> to be <button …>` → tab order note above.
- SessionsScreen missing-id: `Unable to find an accessible element with the role "list" and name "Past sessions"` (the list pane is display:none beside a reader in jsdom, which applies no min-width media query) → counted the cards by selector.
- `RosterPicker.test.tsx`: `Transform failed … , or ) expected` (my apostrophe in a single-quoted test name) → double quotes.
- `App.test.tsx` S3/W5: `Found multiple elements with the role "banner"` (testing-library counts every `<header>`) → `.masthead`.

Result: web vitest `Test Files 33 passed (33)`, `Tests 343 passed (343)`; tsc clean;
`npx jest src/architecture.test.ts src/color-guard.test.ts` → `Tests: 47 passed`.

## Step 13 — full workspace green

- `npm test` (root) → exit 0: jest `Tests: 1075 passed, 1075 total` (+3: G16, G17, self-check); vitest `Test Files 33 passed (33)`, `Tests 343 passed (343)`.
- `npm run typecheck` → exit 0.
- `npm --workspace web-divination run build` → exit 0 (`✓ built in 341ms`; the ">500 kB chunk" warning is `cities.generated` 1,843 kB, the city table — not this feature).
- `git diff 416c3dd -- web-divination/package.json` → 0 lines (G2: no dependency change).
No file changed at this step, so no commit.

Status: implementing complete → validating.
