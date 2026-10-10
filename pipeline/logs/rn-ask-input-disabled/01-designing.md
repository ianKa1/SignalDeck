# rn-ask-input-disabled — 01 designing (2026-09-30)

## Inputs read
- CLAUDE.md (rules 5, 8, 13, 15 especially), pipeline/PIPELINE.md (Skills per stage, pipeline-mode
  overrides, Spec requirements, Decision precedence), QUEUE.md entry `rn-ask-input-disabled`
  (user-requested 2026-09-30; no epic file).

## Skills invoked (Skill tool, pipeline-mode overrides)
1. `frontend-design`: the feature is frontend-facing. Its visual bar here is restraint: the
   disabled look reuses the field's existing inert figures (0.5 inert layer, `actionOutlined.waiting`,
   `actionLabel` waiting tone) plus one quiet `note` line. No new token, PAINT entry or variant.
2. `feature-spec`: wrote Goal / Non-goals / Decided defaults / Acceptance Criteria. It asked no
   questions.
3. `architecture-designer`: wrote the Architecture section of the same file (reuse table with
   file:line, module map delta, contracts, forbidden edges, guard/test amendments). It has no
   migration steps.

## Survey (targeted reads)
- `app-native/src/ask/AskScreen.tsx`: `submit` (146-186) is the ONLY caller of core `checkFitness`
  in the app. The field is mounted at 269-282. The chips only set the placeholder (261).
- `app-native/src/ask/QuestionField.tsx`: multiline input, `returnKeyType="default"`, no
  `onSubmitEditing`, so there is no keyboard submit path. The ASK button is the only submit. The
  existing inert figures are at 70/81/101/105/129-133/149-151.
- `packages/core/src/ask/fitness.ts:90`: the one `/api/ask/*` request (`postJson('/api/ask/fitness')`).
  No other `/api/ask` caller exists in core or the app.
- `app-native/src/ask/dev-entry.ts`: the sibling-constant precedent for the flag's home.
- Tests that drive the field: `ask/ask.test.tsx`, `ask/ask-flow.test.tsx`,
  `text-variant-rulings.test.tsx` (345-357). Source pins: the `ask.test.tsx` import allowlist
  (791-823) and the "no `fetch(`/`apiUrl(` under src/ask" scan (841-847). The census floors are in
  `theme/text-variants.test.tsx:239-254` (floors, so raising `note` is allowed). The guard residue
  is 48 raw tags / 55 markers (`text-variant-guard.test.ts:257`), unaffected.
- `ask.test.tsx:261-266` pins `cards.comingSoon` as gone. The new key is `ask.comingSoon` (a
  different namespace and string), so it does not conflict and that test stays.
- RNTL 13.3.3 `fire-event.js`: `fireEvent` skips focus/changeText on a non-editable TextInput and
  press on a disabled Pressable, so jest reproduces the user-visible lock.
- `.claude/skills/verify/SKILL.md`: the simulator recipe for AC-10.
- No conflicting tier-1 or tier-3 decision was found. Nothing to supersede.

## Output
- Spec: `pipeline/specs/rn-ask-input-disabled.md` (10 decided defaults, 10 acceptance criteria).

## Transition
designing → spec-review
