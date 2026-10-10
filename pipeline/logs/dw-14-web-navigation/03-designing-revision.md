# dw-14-web-navigation — 03 designing (revision after spec-review round 1 FAIL)

- Date: 2026-09-29. Input: logs/dw-14-web-navigation/02-spec-review.md, as relayed by the coordinator. The spec was revised in place; no code was touched.
- Status: spec-review round 2 is pending. The coordinator writes QUEUE.md.

## Required fixes
1. **G16 would have tripped on existing code.** Web code already uses `location.` as a birth-data field (`data.location.name` and similar), so G16 now names only the browser GLOBALS. Its pattern is `(?<![\w.$])(?:(?:window|globalThis)\.)?(?:history|location)\s*\.` or `\bpopstate\b`, matched on non-test files with comments stripped.
   - A property access such as `data.location.name` does not match, because the identifier is preceded by `.`.
   - An object key `location:` does not match either.
   - Checked against the web tree at 8da99b2 with perl, test files excluded: 0 hits (birth-input/CityPicker.tsx:86/94/181, BirthSummary.tsx:28 and BirthForm.tsx do not match).
   - G1 gains two more biting offenders (`window.location.pathname` and `popstate`), plus a does-NOT-bite self-check: `data.location.name`, `value?.location.name` and `{ location: initial.location }` in birth-input.
   - The CLAUDE.md sentence now claims only the global form, and G3 checks for exactly that.
2. **C5 is restated from a reachable start state.** Moon open header + 49 sealed (`s-1` … `s-49`), with a Mars transcript ending on a persona reply and no Mars header. `endSession('mars','en')` leaves 50 records: Mars sealed at index 0, the Moon header kept, `s-1` … `s-48` kept, and `s-49` gone.

## Optional notes applied
- Stale roster.ts refs fixed: `PERSONA_IDS` :17, `isPersonaId` :19, `ACTIVE_KEY` :35.
- `src/test-setup.ts` now stubs `window.scrollTo`. It is in the module map and in the criteria preamble.
- Real-app setup uses backend 8002 and Vite `--port 5175`, with `CORS_ALLOW_ORIGINS=http://localhost:5175` (the same port) and `VITE_API_BASE=http://localhost:8002`.
- New decided default (D8 and the session-log contract): an open header whose live transcript is empty is treated as ABSENT everywhere.
  - It is not listed, and `getSession` returns undefined.
  - `recordEntry` replaces it with a fresh header and id.
  - `adoptTranscripts` ignores it, and `write()` drops it.
