# Implementation Plan: dw-14-web-navigation

Spec: `pipeline/specs/dw-14-web-navigation.md` (WHAT + Architecture; PASS in
`logs/dw-14-web-navigation/04-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Parallel wave with dw-15-wheel-spotlight
(implementing in `../astrology-wt/dw-15-wheel-spotlight`, which uses :8001/:5174
and guard ids G14/G15).

Every command runs from the dw-14 WORKTREE root the coordinator assigns
(branch `feature/dw-14-web-navigation`); pipeline files by absolute path under
`/Users/kaimao/Projects/astrology/pipeline/`. Steps 0–13 are `implementing`,
14–15 `validating`, 16 `docs-sync`. Tick a box only after its done-when passed
and its `/git-commit` landed (`(<type>): dw-14-web-navigation — <summary>`).
Load `/frontend-design` before step 7. Web: `npx vitest run <file>` from
`web-divination/`. Root: `npm test`, `npm run typecheck`.

## Settled review notes

- **S1 — W1 counts distinct hrefs.** Name, seal and examples all link to
  `/chat/<id>`, so W1 collects every `a[href^="/chat/"]` on Home, dedupes in
  first-occurrence order, and asserts that list equals the six roster paths.
  It separately asserts the six NAME links (by accessible name) exist.
- **S2 — C1's two entries are user, then persona.** C1 records a `user`
  entry, then a `persona` entry; C3 builds on that state (persona last, so
  `canEndSession` passes).
- **S3 — N2's "no remount" probe is named.** `nav/Link.test.tsx` renders a
  `RouteHarness` (reads `useRoute`, renders the route name and a Link) whose
  mount-only effect increments a module counter `harnessMounts`; after the
  click `harnessMounts === 1` and the new route name shows. The App-level
  twin in `App.test.tsx` asserts the `banner` element is the SAME node
  (`toBe`) before and after a push.
- **S4 — the forbidden-edge wording.** "No feature folder imports `app/`"
  reads "…except the existing `auth/AuthGate.tsx` → `app/Header` edge"
  wherever it is restated (ARCHITECTURE.md, feature doc, epic). No guard
  enforces this edge rule; none is added.
- **S5 — the gate's wordmark link** pushes while signed out. W11 asserts
  paths only, never `history.length` on the gate, so it is harmless.

## Steps

- [x] **0. Baseline.** Confirm the branch and that
  `node_modules/@astrace/core` resolves; record `web-divination/package.json`
  dependency keys (G2 compares against them).
  Done when: root `npm test`, `npm run typecheck` and
  `cd server && DATABASE_URL= conda run -n astrology pytest -q` are green
  BEFORE any edit; results noted in the implementing log.

- [x] **1. Core session log: open records.**
  Files: `packages/core/src/divination/session-log.ts`, `…/divination/index.ts`,
  `web-divination/src/log/core-session-log.test.ts`.
  Add open headers, `recordEntry`, `adoptTranscripts`, seal-in-place
  `endSession`, the open-kept eviction rule, empty-transcript-is-absent, and
  a snapshot keyed on the raw log plus each open persona's transcript
  snapshot; `subscribeSessions` also relays transcript changes. Export
  `recordEntry`, `adoptTranscripts`, `OpenSession`, `SealedSession`.
  Done when: C1–C6 pass in `npx vitest run src/log/core-session-log.test.ts`
  (existing dw-6 cases still green); `npm run typecheck` exits 0.

- [x] **2. The web chat records through core.**
  Files: `web-divination/src/chat/useChat.ts`, `web-divination/src/log/useSessions.ts`,
  `chat/ChatPanel.test.tsx`, `log/SessionBar.test.tsx`.
  Replace the three `appendEntry` calls with `recordEntry(persona, entry, lang)`
  (the stopped-on-unmount path included); `useSessions` runs
  `adoptTranscripts(lang)` then `resumeSummaries()` on mount.
  Done when: `grep -rn "appendEntry(" web-divination/src --include=*.ts --include=*.tsx | grep -v test`
  is empty; a ChatPanel case shows one sent message yields one open
  record; the chat and log suites pass.

- [x] **3. The router (`nav/`).**
  Files (new): `web-divination/src/nav/routes.ts`, `history.ts`, `useRoute.ts`,
  `Link.tsx`, `routes.test.ts`, `Link.test.tsx`; changed:
  `web-divination/src/test-setup.ts` (stub `window.scrollTo`; `afterEach`
  resets the path to `/` with `replaceState`).
  Per the Contracts. `history.ts` additionally reports whether the last path
  change was a push (see spec gap SG1). `useRoute` canonicalizes by replace.
  Done when: N1, N2 (probe S3) and N4 pass in
  `npx vitest run src/nav`; typecheck green.

- [x] **4. Guards G16/G17 + CLAUDE.md sentence (ONE commit).**
  Files: `app-native/src/architecture.test.ts` (web-divination block: G16 and
  G17 tests, a `G16/G17 self-check` test with the four biting offenders and
  the three non-biting birth-input shapes; header comment lists G16/G17),
  `CLAUDE.md` (the spec's verbatim sentence in the web-divination paragraph).
  Never use ids G14/G15 (dw-15's).
  Done when: `cd app-native && npx jest src/architecture.test.ts` passes;
  temporarily adding `history.back()` to `web-divination/src/log/SessionBar.tsx`
  turns G16 red (reverted, noted in the log); `grep -n "dw-14" CLAUDE.md`
  shows the sentence (G1, G3).

- [x] **5. i18n copy.**
  Files: `web-divination/src/i18n/en.ts`, `zh.ts`.
  Add `nav` and `notFound` namespaces, `log.inProgress`, `log.continueWith`,
  `log.sessionMissing`, `log.startedOn`, `roster.last`, screen titles; drop
  `log.backToChart` and `roster.close` once their last reader goes (step 10/11).
  Done when: `npx vitest run src/i18n.test.ts` passes (parity).

- [x] **6. Masthead: Header, MainNav, NotFound.**
  Files: `web-divination/src/app/Header.tsx` (wordmark `Link` to `/`,
  optional `nav` slot), `app/MainNav.tsx` (new), `app/NotFound.tsx` (new),
  CSS beside them.
  MainNav: "The six" · "Sessions · n", `aria-current`, mounts `useSessions`.
  AuthGate keeps rendering `Header` with no nav.
  Done when: `npx vitest run src/auth` stays green (gate masthead has no nav);
  a MainNav case asserts the count and `aria-current`.

- [x] **7. BirthCard extraction.** Load `/frontend-design` first.
  Files: `web-divination/src/birth-input/BirthCard.tsx` (new), `app/App.tsx`
  (uses it in place of the inline toggle).
  The summary ⇄ form toggle moves out verbatim.
  Done when: `npx vitest run src/app src/birth-input` green with no
  behaviour change.

- [x] **8. Home: RosterPicker as a page.**
  Files: `web-divination/src/roster/RosterPicker.tsx`, its CSS,
  `roster/RosterPicker.test.tsx`, `app/HomeScreen.tsx` (new).
  Drop the dialog chrome, Esc and close; name, seal and examples become
  `Link`s (example sets the seed via `onNavigate`); add the "last" mark.
  Home = heading "The six", lede, BirthCard, plates; no wheel.
  Done when: RosterPicker tests updated and green; no `role="dialog"` in
  `roster/`.

- [x] **9. ChatScreen and the route switch.**
  Files: `web-divination/src/app/ChatScreen.tsx` (new, today's stage + side,
  `setActive(persona)` on mount/change, `ChatPanel` keyed by persona),
  `app/App.tsx` (useRoute switch, `Header nav={<MainNav/>}`, seed state,
  `onHandoff` → seed + navigate, title on every route change, heading focus
  on push only).
  Done when: N3, W1–W4, W9 pass in `npx vitest run src/app`; the dw-8 view
  state and `setView` are gone from App.

- [x] **10. Chat header and session bar.**
  Files: `web-divination/src/chat/PersonaHeader.tsx`, `chat/ChatPanel.tsx`,
  `log/SessionBar.tsx`, their tests.
  "The six" becomes a `Link` to `/` (`onOpenRoster` removed); SessionBar
  keeps End + sealed card only.
  Done when: W10 passes; `grep -rn "← The chart\|onOpenSessions\|onOpenRoster" web-divination/src`
  is empty.

- [x] **11. Sessions screens.**
  Files: `web-divination/src/log/SessionsScreen.tsx`, `log/SummaryCard.tsx`,
  their CSS and tests.
  `selectedId` from the route; list cards are `Link`s to `/sessions/<id>`;
  open variant (character ink, "In progress", opening user line, start date,
  no Retry/stars); reader "Continue with <name> →"; missing-id reader with
  "← All sessions". Drop `onBack`.
  Done when: SessionsScreen and SummaryCard suites green, covering the
  open card and missing-id reader.

- [x] **12. App-level flows and legacy test migration.**
  Files: `web-divination/src/app/App.test.tsx` (existing cases that expect the
  stage start at `/chat/venus` via `replaceState`), `auth/AuthGate.test.tsx`.
  Add W5, W6, W7, W8, W11, W12 and the S3 banner-identity probe.
  Done when: `npx vitest run src/app src/auth` green; all W criteria pass.

- [x] **13. Full workspace green.**
  Done when: root `npm test` and `npm run typecheck` exit 0;
  `npm --workspace web-divination run build` exits 0; `git diff 416c3dd --
  web-divination/package.json` shows no dependency change (G2).

- [x] **14. Validating: automated.** Fresh run of root `npm test`,
  `npm run typecheck`, the web build and
  `cd server && DATABASE_URL= conda run -n astrology pytest -q`.
  Done when: all exit 0; the counts go in `logs/dw-14-web-navigation/`
  validating log.

- [x] **15. Validating: real app R1–R5.** Leave :8000/:5173 (and dw-15's
  :8001/:5174) alone. NEVER use the root `.env`'s `DATABASE_URL`.
  - DB: `initdb` + `pg_ctl` a throwaway cluster under the scratchpad on
    127.0.0.1 (a free port), `createdb`.
  - Backend: `DATABASE_URL=<throwaway> GOOGLE_CLIENT_ID=dw14-placeholder.apps.googleusercontent.com
    ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5175 conda run
    --no-capture-output -n astrology uvicorn app.main:app --app-dir server --port 8002`
    (no `--env-file`); `curl localhost:8002/api/health` shows the db.
  - Web: `cd web-divination && VITE_API_BASE=http://localhost:8002
    GOOGLE_CLIENT_ID=dw14-placeholder.apps.googleusercontent.com npx vite --port 5175`.
  - Sign-in: a scratchpad script asserting the 127.0.0.1 host, calling
    `accounts/service._upsert_user` + `_mint_bearer`; write
    `astrace.auth.access/refresh/expiresAt` and a birth record into
    localStorage, reload (dw-12 R2 method). Script text goes in the log.
  - Drive R1–R5 in the browser (claude-in-chrome); screenshot each.
  Done when: R1–R5 each recorded PASS with evidence; servers and the
  cluster stopped.

- [x] **16. Docs-sync.** `/update-architecture-doc` on `docs/ARCHITECTURE.md`
  (nav/ module, open sessions, the S4 edge wording); write
  `docs/features/dw-14-web-navigation.md` (frozen snapshot); epic file:
  a "dw-14" entry in Built so far and `nav/` in Target modules; journal
  D13's three **Supersedes** plus SG1 in `pipeline/DECISIONS.md`.
  Done when: the docs commit lands and `grep -n "nav/" docs/ARCHITECTURE.md
  pipeline/epics/divination-web.md` shows both.

## Acceptance map

| Criterion | Step |
|---|---|
| N1 | 3 (`nav/routes.test.ts`) |
| N2 | 3 (`nav/Link.test.tsx`, probe S3); App twin in 12 |
| N3 | 9 |
| N4 | 3 |
| W1 | 8 + 9 (S1 distinct hrefs) |
| W2 | 7 + 9 |
| W3 | 9 |
| W4 | 8 + 9 |
| W5 | 6 + 12 |
| W6 | 6 + 11 + 12 |
| W7 | 1 + 2 + 11 + 12 |
| W8 | 1 + 11 + 12 |
| W9 | 9 |
| W10 | 10 |
| W11 | 12 |
| W12 | 5 + 12 |
| C1 | 1 (S2: user, then persona) |
| C2–C6 | 1 |
| G1 | 4 |
| G2 | 13 (+ 14 re-run) |
| G3 | 4 |
| R1–R5 | 15 |

## Risks for the implementer

- **The raw log must never store open entries.** `update()` and `write()`
  today serialize what `listSessions()` returns; once open records are
  filled from the transcript, strip `entries` from open records on every
  write or C1's raw-KV check fails and the text is duplicated.
- **Snapshot stability.** `listSessions` must return the same array while
  neither the raw log nor any open persona's `getTranscript` snapshot
  changed; comparing transcript arrays by identity is enough (they are
  stable per raw value). A new array per call loops `useSyncExternalStore`.
- **URL leaks between tests.** jsdom keeps `location` across tests in a
  file and `vi.resetModules` gives each test a fresh `history.ts` listener
  set; reset the path in `test-setup.ts` and add/remove the `popstate`
  listener per subscription, not at module load. N4 compares
  `history.length` relatively.
- **Existing App tests start at `/`**, which is now Home: every case that
  expects the stage needs `/chat/venus` set before mount.
- **Stop on navigate.** Leaving a chat mid-turn stores the stopped reply
  through `recordEntry` on unmount; that path must still work after the
  swap (it is one of the three call sites).
- **Seed before navigate.** Set the seed, then push, so ChatScreen mounts
  with the prefill; a seed for another persona is ignored as today.
- **dw-15 merge.** Both edit `App.tsx` and `App.test.tsx`. The second to
  land moves `<ChartStage persona={…}/>` into `app/ChatScreen.tsx` (persona
  from the route) and sets `/chat/venus` in dw-15's Venus-active App cases.
  Do not edit `chart/ChartStage.tsx`; do not use G14/G15.
- **G16 on your own code.** Never write `location.` / `history.` as a bare
  global outside `nav/history.ts` (e.g. `location.reload()` in a
  not-found page); prose in comments is stripped, strings are not.

## Spec gaps (also in the planning log)

- **SG1 — push vs pop is not observable through the stated `history.ts`
  contract.** App must focus the heading after a push only (D7, W3), but
  `getPath`/`subscribePath`/`navigate` do not say which kind the last
  change was. Plan: `history.ts` also exports a read of the last change's
  kind (`push` | `pop` | `initial`), still inside `nav/`; journal it as a
  deviation at implementing. It adds no global use and no dependency edge.
