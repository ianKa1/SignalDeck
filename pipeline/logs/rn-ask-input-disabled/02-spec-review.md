# 02 · spec-review (round 1)

**Verdict: PASS**

Inputs: QUEUE.md `rn-ask-input-disabled` (user notes), `pipeline/specs/rn-ask-input-disabled.md` (with Architecture), CLAUDE.md Architecture Contract, PIPELINE.md "Spec requirements" + "Pipeline-mode overrides". No epic file applies.

## 1. Serves the notes, right-sized — OK
Every note is covered, and nothing beyond them:
- "not editable": `editable={false}`, graded by AC-2 and AC-4.
- "visibly disabled": inert wrapper opacity, disabled ASK, `waiting` tone (AC-2, AC-10).
- "no submit path fires a request": the widget gate plus the `AskScreen.submit` early return. AC-5 proves it with a real core and a spied fetch, including a direct `onSubmit` call.
- "keep the rest visible": AC-6 and AC-10.
- "coming soon, en + zh via i18n": `ask.comingSoon`, graded by AC-2 and AC-3.
- "don't delete code/tests": a non-goal, graded by AC-7.
- "one flag in one place, one-line re-enable": `ask-gate.ts`, graded by AC-1 and AC-7.
- "loop closed": AC-10.

The only edits beyond the gate are consequences the guards force: the note floor 12 → 13, the import allowlist gaining one entry, and a flag-ON mock in the three suites that type into the field. None of that is invented scope.

## 2. Criteria checkable — OK
AC-1 to AC-9 are jest or typecheck assertions with named testIDs, values and files. AC-10 is a simulator run with a backend access-log check.

RNTL 13.3.3 behaves as the spec says. `isEventEnabled` in `build/fire-event.js:39-42` blocks every TextInput event except contentSizeChange, layout and scroll when `editable` is false, so AC-4's `focus`/`changeText` expectations are real and not vacuous.

## 3. Architecture Contract — OK
- Rule 5: there is no `fetch(`/`apiUrl(` in `src/ask`. The new suite is told to avoid the literal token, and the network stays core's.
- Rule 8: the new string is a dictionary leaf, and the parity test covers it.
- Rule 13: no colour literal is added.
- Rule 15: the note is `<Txt variant="note">` with layout-only style keys, and the inert look reuses the existing `PAINT.actionOutlined.waiting` and the `waiting` tone.
- No boundary moves. The guard amendments widen nothing: one named sibling joins an allowlist, and one floor goes up.

## 4. Non-goals and decided defaults — OK
Non-goals are explicit: no server change, no runtime toggle, `DEV_ENTRY` untouched, no new token or variant. All 10 decided defaults are settled, and there is no Open Questions section.

## Fact check (code read, all confirmed)
- `QuestionField.tsx`:
  - `:70` is the `ask-field` wrapper and `:81` is `editable={!checking}`.
  - `:84` has `returnKeyType="default"`, and there is no `onSubmitEditing`.
  - `:94`, `:101` and `:105` are the disabled prop, the inert style and the tone.
  - `:129-133` is opacity 0.5, and `:149-151` is `submitInert` = `PAINT.actionOutlined.waiting`.
- `AskScreen.tsx`: `submit` starts at `:146`, the only `checkFitness` caller is at `:152`, and the `QuestionField` mount is at `:271-280`.
- `ask.test.tsx`:
  - `:261-266` pins `cards.comingSoon` as gone, which does not collide with `ask.comingSoon`.
  - `:795-814` is the AskScreen import allowlist and `:833-839` is the QuestionField pin.
  - `:841-847` is the `fetch(` scan over every file in `src/ask`.
- `fitness-seam.test.ts:61-71` is the `jest.spyOn(globalThis,'fetch')` idiom.
- `theme/text-variants.test.tsx:246` is `note: 12`, and `text-variants.ts:59` binds `note` to caption/textFaint.
- `text-variant-guard.test.ts:257` pins 48 raw tags and 55 markers. The spec is right here; CLAUDE.md rule 15's "50/57" is stale and outside this feature.
- `draw-ring-scroll` and `ring-band` exist at `DrawRing.tsx:299` and `:315`, and `shell/AppShell.tsx:67` mounts `<AskScreen />`.
- The only suites that type into or press the field are `ask.test.tsx`, `ask-flow.test.tsx` and `text-variant-rulings.test.tsx`. `surface-paint-rulings.test.tsx` only reads source, so it needs no mock.
- `QuestionField` is rendered only by `AskScreen`, so making `disabled` a required prop breaks no other caller.

## Non-blocking notes for the implementer
- The mock specifier differs by suite location: `./ask-gate` in `src/ask/*`, and `./ask/ask-gate` in `src/text-variant-rulings.test.tsx`.
- Earlier floor bumps were mirrored in `docs/text-variant-census.md` §D member counts. Add the coming-soon note there too, for provenance parity (docs-sync may do it).

Transition: spec-review → spec-approved
