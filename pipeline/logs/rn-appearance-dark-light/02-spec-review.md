# 02 · spec-review (round 1)

**Verdict: FAIL** (one factual defect in an acceptance criterion; everything else passes)

## Checklist

1. **Serves the user's notes, right-sized: PASS.** Every clause of the queue note maps to a default or AC: paper/plaster removed (defaults 2, 11, 13), ink→dark and exhibition→light in code and in the en/zh labels (defaults 2, 3), colour values unchanged (non-goal 1, AC-2), legacy migration on first read (default 5, AC-3 to AC-5, AC-14), rules 13 and 15 intact (default 10), guards and rulings amended, not weakened (defaults 11 to 13). Two small additions go beyond the note: the removed-grounds literal pin (default 12) and folding LIGHT.planet into PLANET_PERSONALITY (default 9). Both are justified in the spec and directly serve "no user lands on a missing ground" and "values unchanged", so they are not invented scope. The non-goals cleanly exclude web-divination, OS-appearance following, live restyle and onboarding.
2. **Every AC checkable: PASS, apart from defect D1.** AC-1 to AC-11 are jest or tsc facts. AC-13 and AC-14 are device drives with numeric pixel tolerances and a stated before/after procedure.
3. **Architecture Contract: PASS.** Rule 13: tokens.ts stays the sole native home, and the only change is removing literals. Rule 15: PAINT and TEXT_VARIANTS name no ground. Rule 2 leaf discipline: ground-store still imports only `./tokens`. No core, server or web-divination edit. No guard is weakened. The one CLAUDE.md edit (rule 13's "copied from native INK") is a rename-only wording change.
4. **Non-goals stated, every open point decided: PASS.** There are 14 decided defaults, no open questions, and the unrecognised-value, write-failure and fresh-device cases are all decided.

## Facts verified against code

- `theme/tokens.ts`: `Ground` union at :39. INK starts at :156, PAPER at :207, PLASTER at :259, EXHIBITION at :311. `GROUND_TOKENS` is at :377 and `activeGround = 'ink'` at :393. The spec's line ranges hold.
- `theme/ground-store.ts`: key at :20, `isGround` at :35-37, `configureGroundPersistence` at :43-51, `setGround` at :55-65. All exact.
- `SettingsScreen.tsx`: :43 GROUNDS, :47-55 GROUND_LABEL, :191 testID template. `AppShell.tsx:48` holds the plaster||exhibition disjunction. `App.tsx:45` holds the 'ink' status-bar comparison. `boot.ts:104` calls `configureGroundPersistence`. `en.ts:141-146` and `zh.ts:114-117` hold the ground keys. All exact.
- Contrast figures, recomputed with WCAG relative luminance: light text/textDim/theme against #f9f9f7 = 15.6 / 9.5 / 19.9. Dark against #08090e = 16.4 / 9.4 / 9.1. These match the spec.
- The exhibition planet block equals PLANET_PERSONALITY value for value, so default 9 is safe.
- On exhibition, accent #26231f ≠ theme #000000, and artBed = wheelRim = #f3f2ee. Default 11's seed-pin split is correct.
- The literal pin (default 12): outside ground-store.ts and its test, every current quoted 'ink'/'paper'/'plaster'/'exhibition' under app-native/src is a ground usage that the spec already lists for re-keying. The one non-ground-looking hit (tokens.ts:205 `data-theme='paper'`) is in a comment, which the pin strips. The pin is achievable.
- `ask-wheel.test.tsx:98` iterates `Object.keys(GROUND_TOKENS)`, as the spec states.
- DECISIONS.md has no heading for native-paper-mode or the exhibition sandbox. The museum-white-mode spec-review heading is at :368, as quoted.

## Defects

**D1: wrong fact in AC-12 (and in the Non-goals echo).** AC-12 says `text-variant-guard.test.ts` passes with "residue totals unchanged: 50 raw tags, 57 markers". The pinned constants today are `MARKER_TOTAL = 61` and `RAW_TAG_TOTAL = 53` (`app-native/src/text-variant-guard.test.ts:221-222`). The 50/57 figure was copied from CLAUDE.md rule 15's prose, which is stale; the test's own title, "48 raw tags, 55 markers", is stale too. An acceptor checking AC-12 literally would either FAIL a correct build or be unable to decide what "unchanged" means.
**Fix:** reword AC-12 to "`text-variant-guard.test.ts` passes with `RAW_TAG_TOTAL` (53), `MARKER_TOTAL` (61) and `RESIDUE_FLOORS` unedited (text-variant-guard.test.ts:220-222)". Non-goal 6's "census residue totals are unchanged" can stay as worded. Optionally, note the stale CLAUDE.md rule 15 figure as pre-existing drift for docs-sync; it is not in this feature's scope to fix.

## Non-blocking notes

- AC-3 writes `withAlpha(LIGHT.panel, 0.82)`. `LIGHT` is module-private, so the test will read `GROUND_TOKENS.light.panel`. The intent is clear either way.
- AC-9's "(or reads the StatusBar element)" leaves the method open, but either route is a concrete jest check.

Transition: spec-review → spec-review (revise)
