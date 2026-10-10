# 04 · spec-review (round 2)

**Verdict: PASS**

## Round-1 defect

- **D1 (AC-12 stale residue totals): fixed.** AC-12 now cites `RAW_TAG_TOTAL` (53), `MARKER_TOTAL` (61) and `RESIDUE_FLOORS` unedited at `text-variant-guard.test.ts:220-222`. Re-verified: `RESIDUE_FLOORS` is at :220, `MARKER_TOTAL = 61` at :221 and `RAW_TAG_TOTAL = 53` at :222. The CLAUDE.md rule 15 figure (50/57) and the test title's figure (48/55) are correctly recorded as pre-existing drift outside this feature's scope. The revision (03-designing.md) touched nothing else.

## Checklist

1. **Serves the user's notes and is right-sized: PASS.** Every clause of the queue note maps to a default or an AC: paper and plaster removed, ink→dark and exhibition→light in code and in the en/zh labels, colour values unchanged, migration on first read (paper/plaster/exhibition→light, ink→dark), rules 13 and 15 intact, and guards and rulings amended rather than weakened. The loop-closed sentence is covered by AC-6, AC-13 and AC-14. The two additions (the removed-grounds literal pin, and LIGHT.planet sharing PLANET_PERSONALITY) are small and directly serve the note's intent. Nothing is invented.
2. **Every AC is concretely checkable and factually correct: PASS.** AC-1 to AC-12 are jest or tsc facts, and AC-13 and AC-14 are simulator drives with numeric tolerances and a before/after procedure. Spot-checks against the code:
   - Every current quoted `'ink'|'paper'|'plaster'|'exhibition'` under `app-native/src` outside ground-store is in a file that default 11 re-keys: App.tsx, App.test, settings.test, SettingsScreen, draw-ring.test, card-back.test, shell.test, AppShell, tokens.ts and tokens.test. The one exception, tokens.ts:205, is a comment and gets stripped. So the AC-11 pin is achievable.
   - Only SettingsScreen.tsx and en/zh reference the i18n ground keys.
   - `brand.test.ts` reads `tokens.ground` at runtime, not the `INK` identifier, so the rename does not break it.
   - For AC-13's margin sample: the plaster tile (mean alpha about 8/255) is composited at opacity 0.5 over `#f9f9f7`. That gives a mean of about (247, 247, 245), which is inside the stated tolerance of 3.
3. **Architecture Contract: PASS.**
   - Rule 13: `tokens.ts` stays the sole native home, and removing tables only removes literals.
   - Rule 15: PAINT and TEXT_VARIANTS name no ground.
   - Rule 2 leaf discipline: ground-store still imports only `./tokens`.
   - There is no core, server or web-divination edit.
   - The guard suites are unedited, and one pin is added.
   - The CLAUDE.md rule 13 edit ("copied from native INK" → DARK) is a rename-only wording change.
4. **Non-goals stated, and every open point has a decided default: PASS.** There are eight non-goals and fourteen decided defaults, covering unknown values, read and write failures, a fresh device, the status bar, the texture and the superseded DECISIONS entry. There are no open questions.

## Non-blocking notes (for the implementer)

- AC-3's `withAlpha(LIGHT.panel, 0.82)` should be read as `GROUND_TOKENS.light.panel`, because `LIGHT` is module-private. This was already noted in round 1.
- `.claude/skills/verify/SKILL.md:65` hard-codes appearance-row tap coordinates for four segments (Ink/Paper/Plaster). Docs-sync (default 13) should re-derive the two-segment coordinates, not just rename them.

Transition: spec-review → spec-approved
