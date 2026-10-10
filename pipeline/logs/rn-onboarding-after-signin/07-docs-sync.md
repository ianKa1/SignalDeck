# 07 — docs-sync (worker, worktree ../astrology-wt/rn-onboarding-after-signin)

Commit: `6eb517a` (docs): rn-onboarding-after-signin — sync architecture doc and censuses
for the threshold page and first-sign-in setup. `git status --short` clean after.

## docs/ARCHITECTURE.md (/update-architecture-doc, diff dev..HEAD)
Triage: structural — new `setup/` folder, new `BirthForm.tsx`, a core public channel
(sync phase), App composition changed; gate/opening contracts changed. Sections edited
in place:
- repo tree: `opening/` line rewritten (the threshold, `children` slot); `setup/` line added.
- app-native overview paragraph: "after the opening, App renders the gate" → the opening
  is the threshold + first-sign-in setup.
- `index.ts`/`App.tsx` bullet: the composer's three-way render rule, the threshold, the
  stale-key clear; the opening's `still`/`children`. Removed the false "one `opened` state",
  "renders INSTEAD of the shell until played once", "visual prototype, removed by deleting
  that branch".
- `src/birth-input/`: `BirthForm.tsx` (form body, props, push-on-save) + `BirthSheet.tsx`
  (modal around it).
- `src/account/`: `SignInGate.tsx` rewritten (controls only, `revealed`, no wordmark;
  checking → nothing beneath the words); `useAccountSync.ts` added; NEW `src/setup/`
  bullet.
- core account sync paragraph: the `AccountSync` phase channel.
- birth data-flow diagram label: `BirthSheet` → `BirthForm` (topology unchanged).
- feature index: rn-forced-signin's "(the gate after the opening; …)" made true; an
  opening-animation-prototype pointer; NEW rn-onboarding-after-signin entry.
Confirmed still accurate: server sections (no server change), platform/boot, theme,
TOP-level rules. Spot-checked every path/symbol written (all exist).

## Other docs checked
- `docs/text-variant-census.md`: §T row 165 (the gate wordmark `title`) is now false →
  appended §U (census convention: dated append, rows are history): 165 retired; rows
  31–38, 40–42 moved to `BirthForm.tsx`; rows 174–178 added; residue 47/53/37 unchanged.
- `docs/surface-paint-census.md`: appended §N (field rows + submit moved to BirthForm;
  setup's chip / indicator / divider consumers; the `GROUND_TOKENS[g]` plate as a ruled
  direct binding). FLOORS unchanged.
- `CLAUDE.md`: grep for wordmark / opening / gate / setup — no false prose (line 143's
  "sign-in gate" is the server route gate). Not edited.
- `docs/DESIGN.md`, `docs/feature_natal.md`: no mention.

## Feature doc
`/Users/kaimao/Projects/astrology/docs/features/rn-onboarding-after-signin.md` (primary
checkout; `docs/features/` is gitignored local-only, so not committed): what the user
sees, core/app changes, guards and counts, the AC13 deviation, the device evidence from
06-validating.md, known limitations.

## Tests
Doc-only edits (no test-walked file touched) → `npm test` not re-run (last run at
`bf355b6`: jest 97/1186, vitest 48/447).

Transition: docs-sync → accepting (coordinator).
