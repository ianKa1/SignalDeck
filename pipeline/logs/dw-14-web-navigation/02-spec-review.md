# dw-14-web-navigation — auto spec review (fresh context)

Reviewer inputs: QUEUE.md entry `dw-14-web-navigation` (plus the tier-1 user
confirmation 2026-09-29 that HOME is the six-planet picker), the spec with its
Architecture section, `pipeline/epics/divination-web.md`, CLAUDE.md, and
PIPELINE.md (Spec requirements, pipeline-mode overrides, Decision precedence,
the `depends:` rule). I checked factual claims with targeted reads at `8da99b2`:
`web-divination/src/{main.tsx, app/App.tsx, app/Header.tsx, auth/AuthGate.tsx,
log/SessionsScreen.tsx, roster/RosterPicker.tsx, chat/useChat.ts}`,
`web-divination/{package.json, vite.config.ts, index.html}`, core
`divination/{session-log.ts, transcript.ts, roster.ts, index.ts}`, the guard ids
in `app-native/src/architecture.test.ts`, and root and workspace
`node_modules` (no router package is installed).

## 1. Serves the notes, right-sized, no invented scope: PASS

The spec covers every clause in the notes:
- Home is the picker (D3), matching the tier-1 confirmation.
- `/`, `/chat/<planet>`, `/sessions` and `/sessions/<id>` are defined (D2).
- Back, Forward and reload are covered by N3, R2 and R3.
- There is a visible way home on every screen (D5, W5, R4).
- The gate wraps every route and the URL survives it (D6, W11, R5).
- Sign-out is reachable on every screen (W5, R4).
- Chats are logged as they happen, and End only seals the session and adds the summary (D8, W7, W8, C1–C3).
- A failed summary stays listed with its transcript (W8, C4).
- The router is chosen by reuse and size (D1). The in-house choice is justified, and no router is installed anywhere, so the claim is true.
- The "loop closed" line maps to R3.

The additions are small and follow from the notes: the not-found screens (D10), `document.title` and heading focus (D7), the "last" mark (D3) and adoption of legacy transcripts (D8). Adopting legacy transcripts is needed so that "a chat you walked away from is in Sessions" also holds for chats begun before the upgrade. Nothing is invented beyond that.

The `depends:` line (dw-12, dw-13) names functional dependencies only. The dw-15 overlap is correctly treated as a landing concern, not a dependency.

## 2. Acceptance criteria are concrete and checkable: PASS, except C5

N1–N4, W1–W12, C1–C4, C6, G1–G3 and R1–R5 are each observable in vitest/jsdom or in a real browser. The flake risks are handled:
- N3 awaits `popstate`.
- N4 compares `history.length` relatively.
- W8 stubs the summary to 503.
- The R-tier setup reuses dw-12 R2's bearer-minting method against a throwaway Postgres, never the root `.env` database.

C5 is not coherent as written (see required change 2).

## 3. Architecture Contract and consistency with the epic: FAIL on one point

Correct:
- Core stays platform-agnostic. `session-log.ts` gains transcript subscriptions and adds no Web global.
- The only History-API code is web-side, in `nav/history.ts`.
- The barrels are respected: `recordEntry` and `adoptTranscripts` are added to `core/divination/index.ts`.
- G3–G7 and rule 13 are unchanged.
- The i18n leaf is untouched as a module, and the new namespaces are under the existing parity test.
- No server change is made, so rules 6, 9 and 14 are untouched. The log stays device-local and identity-free.
- No new package is added.
- G16 and G17 are pure tightenings, and their ids do not collide with dw-15's G14 and G15.
- The dw-15 overlap note is accurate: `<ChartStage />` is at `App.tsx:76`.
- D13 names the three superseded decisions. All are tier-3 loop decisions: dw-6 choice f, dw-6 D11, and dw-8's modal picker. The Supersedes journaling is stated.
- The spec is consistent with the epic's dependency rules ("No conversation state on the server"; "the client owns the transcript").

**Problem.** G16, as specified, and the proposed CLAUDE.md sentence are false against the current tree.
- The spec defines G16 as "the only web source that names `history.`, `location.` or `popstate`". The CLAUDE.md sentence says "only `nav/history.ts` names `history`/`location`/`popstate`".
- `location.` already appears in web production code as the birth-data field, not the browser global:
  - `birth-input/BirthSummary.tsx:28` (`data.location.name`)
  - `birth-input/BirthForm.tsx:51,61,140` (`initial.location`, `pick?.location`, `pick.location.name`)
  - `birth-input/CityPicker.tsx:86,94,181` (`value.location.name`, …)
- So a G16 written as the spec words it fails on existing code, and G1 ("G16 passes") cannot be met. The implementer would have to invent the real pattern at build time, and the CLAUDE.md sentence would be a false statement in the normative contract.
- The rule should be about the browser GLOBALS `history`/`location` (and `popstate`), not any property named `location`. The spec must say so, and must give the pattern or its rule, for example: not preceded by `.` or an identifier character, optionally `window.`/`globalThis.`-prefixed. It must also include a does-not-bite self-check on `data.location.name`.

## 4. Non-goals, decided defaults, pipeline-mode shape: PASS

- Non-goals are explicit (no server, no deploy, no dependency, no native, no in-screen URL state, no continuing a sealed session, no delete or search, seeds not durable).
- Every open point is decided, in D1–D13, with no open-questions section.
- The Goal is 3 lines and cites the queue entry.
- Word counts are about 1,535 for Goal through Decided defaults (header included), about 1,449 for Architecture, and about 1,468 for the criteria, so the budgets are respected.
- The Architecture section cites the epic, writes only the delta, and has no Migration Steps.

## Required changes

1. **Define G16 on the browser globals, and correct the CLAUDE.md sentence to match.**
   - In Architecture (`nav/history.ts` contract, the forbidden-edges bullet, and §Guard and CLAUDE.md amendments), state that G16 matches the global `history`/`location` references (bare or `window.`/`globalThis.`-prefixed) and `popstate`. Property accesses such as `data.location.name` are explicitly NOT matches.
   - Add to G1 a does-not-bite synthetic case (for example `data.location.name` in `web-divination/src/birth-input/x.tsx`) next to the existing bites case.
   - Reword the CLAUDE.md sentence (and G3's reference to it) so it claims only the global form. For example: "only `nav/history.ts` touches the browser's `history`/`location` globals or `popstate`".

2. **Make C5's setup coherent.** "One open header and 50 sealed records stored" is 51 records, which is already over the cap D8 defines (50 in total). "Sealing another session" is also ambiguous:
   - If it means sealing the open header, the open header cannot be "kept".
   - If it means a header-less transcript, two sealed records are evicted, not "the oldest".

   Restate it concretely. For example: a stored open Moon header plus 49 sealed records, and a Mars transcript that ends on a persona reply; `endSession('mars','en')` leaves exactly 50 records, the Moon open header is still present, the new Mars record is sealed, and the previously oldest sealed record is gone. Alternatively, pin eviction by a direct `recordEntry` into a full log. Either works, as long as the start state is reachable or explicitly seeded and the expected survivors are named.

## Optional notes (non-blocking)

- Some Architecture reuse-table line references are stale for `roster.ts`: `PERSONA_IDS` is at `:17` (not `:19`), `isPersonaId` at `:19` (not `:21`) and `ACTIVE_KEY` at `:35` (not `:40`). The `session-log.ts` and `transcript.ts` references check out.
- D7's `scrollTo(0, 0)` in `history.ts`: jsdom's `window.scrollTo` is "not implemented" and logs a virtual-console error. The plan should stub it in `test-setup.ts` so the router tests stay quiet.
- R setup says "Vite: `--port <free>`", but `vite.config.ts` pins 5173 with `strictPort`. A CLI `--port` overrides that, so this works, but the backend's `CORS_ALLOW_ORIGINS` must name that same port. The spec says "naming the Vite origin", which is fine; just be explicit in the validating log.
- If a stored open header's transcript is emptied outside End (for example, storage cleared by hand), `recordEntry` would later reuse the stale header's id and position, because "that persona has none" is false. Consider having `recordEntry` treat an open header over an empty transcript as absent, or have `write()` prune such headers. This is an edge case and not required.
- `listSessions` currently holds a snapshot keyed only by the sessions raw value (`session-log.ts:147`). The spec's widened snapshot rule, which also depends on open personas' transcript snapshots, is the right contract. C2 pins it.

VERDICT: FAIL
